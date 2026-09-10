import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/domain/receipts.dart';
import 'package:splitka_flutter/state/household_controller.dart';
import 'package:splitka_flutter/storage/firebase_store.dart';
import 'package:splitka_flutter/storage/local_store.dart';

const code = '0123456789abcdef0123456789abcdef';

Receipt receipt(String name) => createManualReceipt(
  defaultMembers,
  ManualReceiptInput(title: name, payerId: 'danus'),
);

class TestFirebaseStore extends FirebaseStore {
  final events = StreamController<RemoteHouseholdChange?>.broadcast(sync: true);
  late RemoteHouseholdChange current;
  Object? saveError;
  Completer<void>? saveGate;
  int connections = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<bool> initializeIfConfigured() async {
    connections += 1;
    return true;
  }

  @override
  Future<RemoteHouseholdChange> createHousehold(Household seed) async {
    current = RemoteHouseholdChange(
      household: seed.copyWith(id: 'cloud-room'),
      inviteCode: code,
      revision: 1,
    );
    return current;
  }

  @override
  Future<RemoteHouseholdChange> joinHousehold(String input) async {
    normalizeInviteCode(input);
    return current;
  }

  @override
  Stream<RemoteHouseholdChange?> watchHousehold(String roomId) => events.stream;

  @override
  Future<RemoteHouseholdChange> updateHousehold(
    String roomId,
    Household Function(Household) updater,
  ) async {
    await saveGate?.future;
    if (saveError != null) throw saveError!;
    current = RemoteHouseholdChange(
      household: updater(current.household),
      inviteCode: code,
      revision: current.revision + 1,
    );
    events.add(current);
    return current;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestFirebaseStore remote;
  late HouseholdController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    remote = TestFirebaseStore();
    controller = HouseholdController(firebaseStore: remote);
  });

  tearDown(() async {
    controller.dispose();
    await remote.events.close();
  });

  test(
    'legacy local data opens without signing in or uploading stancja',
    () async {
      final original = createDefaultHousehold().copyWith(
        receipts: [receipt('Local')],
      );
      SharedPreferences.setMockInitialValues({
        'splitka.household.stancja': jsonEncode(original.toJson()),
      });
      await controller.boot();
      expect(controller.household.receipts.single.title, 'Local');
      expect(controller.syncState, SyncState.local);
      expect(remote.connections, 0);
    },
  );

  test(
    'creating a room persists membership selection and keeps local data',
    () async {
      await controller.boot();
      await controller.commit((h) => h.copyWith(receipts: [receipt('Local')]));
      expect(await controller.createCloudRoom(), isTrue);
      expect(controller.isCloudRoom, isTrue);
      expect(controller.inviteCode, code);
      expect(await LocalStore().loadCloudRoomId(), 'cloud-room');

      expect(await controller.useLocalMode(), isTrue);
      expect(controller.household.receipts.single.title, 'Local');
      expect(await LocalStore().loadCloudRoomId(), isNull);
    },
  );

  test('invalid invitation does not change the selected room', () async {
    await controller.boot();
    expect(await controller.joinCloudRoom('stancja'), isFalse);
    expect(controller.isCloudRoom, isFalse);
    expect(controller.roomCode, 'stancja');
    expect(controller.error, contains('kod zaproszenia'));
    expect(await LocalStore().loadCloudRoomId(), isNull);
  });

  test(
    'failed cloud save is explicit and does not change visible data',
    () async {
      await controller.boot();
      await controller.createCloudRoom();
      remote.saveError = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
      );
      final saved = await controller.commit(
        (h) => h.copyWith(receipts: [receipt('Lost')]),
      );
      expect(saved, isFalse);
      expect(controller.household.receipts, isEmpty);
      expect(controller.error, contains('nie została zapisana'));
      expect(controller.busy, isFalse);
    },
  );

  test(
    'an edit applies to latest remote data, preserving another roommate receipt',
    () async {
      await controller.boot();
      await controller.createCloudRoom();
      remote.current = RemoteHouseholdChange(
        household: controller.household.copyWith(receipts: [receipt('Other')]),
        inviteCode: code,
        revision: 2,
      );
      final own = receipt('Own');
      expect(
        await controller.commit(
          (h) => h.copyWith(receipts: [...h.receipts, own]),
        ),
        isTrue,
      );
      expect(controller.household.receipts.map((r) => r.title), [
        'Other',
        'Own',
      ]);
    },
  );

  test(
    'old revisions and events from a previous room cannot restore cleared receipts',
    () async {
      await controller.boot();
      await controller.createCloudRoom();
      final newer = RemoteHouseholdChange(
        household: controller.household,
        inviteCode: code,
        revision: 3,
      );
      remote.events.add(newer);
      remote.events.add(
        RemoteHouseholdChange(
          household: controller.household.copyWith(receipts: [receipt('Old')]),
          inviteCode: code,
          revision: 2,
        ),
      );
      expect(controller.household.receipts, isEmpty);
      await controller.useLocalMode();
      remote.events.add(newer);
      expect(controller.roomCode, 'stancja');
      expect(controller.syncState, SyncState.local);
    },
  );

  test(
    'rapid saves are serialized and switching rooms waits for saves',
    () async {
      await controller.boot();
      await controller.createCloudRoom();
      remote.saveGate = Completer<void>();
      final first = controller.commit(
        (h) => h.copyWith(receipts: [...h.receipts, receipt('First')]),
      );
      final second = controller.commit(
        (h) => h.copyWith(receipts: [...h.receipts, receipt('Second')]),
      );
      expect(await controller.useLocalMode(), isFalse);
      remote.saveGate!.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(controller.household.receipts.map((r) => r.title), [
        'First',
        'Second',
      ]);
    },
  );

  test('cache snapshot is labelled offline, not synchronized', () async {
    await controller.boot();
    await controller.createCloudRoom();
    remote.events.add(
      RemoteHouseholdChange(
        household: controller.household,
        inviteCode: code,
        revision: 1,
        fromCache: true,
      ),
    );
    expect(controller.syncState, SyncState.offline);
  });

  test(
    'resumes the saved cloud room and revision without overwriting it',
    () async {
      await controller.boot();
      await controller.createCloudRoom();
      await controller.commit((h) => h.copyWith(receipts: [receipt('Shared')]));
      // Wait for the serialized local snapshot writes triggered by the listener.
      await Future<void>.delayed(Duration.zero);
      final resumed = HouseholdController(firebaseStore: remote);
      addTearDown(resumed.dispose);
      await resumed.boot();
      expect(resumed.isCloudRoom, isTrue);
      expect(resumed.inviteCode, code);
      expect(resumed.household.receipts.single.title, 'Shared');
      remote.events.add(
        RemoteHouseholdChange(
          household: createDefaultHousehold('cloud-room'),
          inviteCode: code,
          revision: 1,
        ),
      );
      expect(resumed.household.receipts.single.title, 'Shared');
    },
  );
}
