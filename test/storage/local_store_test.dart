import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud room IDs remain case-sensitive in the local cache', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore();
    await store.saveHousehold(createDefaultHousehold('ABC'), revision: 4);
    await store.saveHousehold(createDefaultHousehold('abc'), revision: 2);
    expect((await store.loadHouseholdSnapshot('ABC')).revision, 4);
    expect((await store.loadHouseholdSnapshot('abc')).revision, 2);
  });

  test('migrates legacy room selection into the group directory', () async {
    SharedPreferences.setMockInitialValues({
      'splitka.roomCode': 'stancja',
      'splitka.cloudRoomId': 'CloudRoom',
    });
    final store = LocalStore();
    await store.saveHousehold(
      createDefaultHousehold('CloudRoom').copyWith(name: 'Wspólna'),
      revision: 3,
      inviteCode: '1234',
    );

    final directory = await store.loadGroupDirectory();

    expect(directory.activeGroupId, 'CloudRoom');
    expect(directory.groups.map((group) => group.id), [
      defaultRoomCode,
      'CloudRoom',
    ]);
    expect(directory.groups.last.name, 'Wspólna');
    expect(directory.groups.last.isCloud, isTrue);
  });

  test('persists several groups and the active selection', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore();
    const groups = [
      StoredGroup(id: 'stancja', name: 'Stancja', isCloud: false),
      StoredGroup(id: 'local-trip', name: 'Wyjazd', isCloud: false),
      StoredGroup(id: 'CloudRoom', name: 'Ekipa', isCloud: true),
    ];

    await store.saveGroupDirectory(groups, 'local-trip');
    final directory = await store.loadGroupDirectory();

    expect(directory.activeGroupId, 'local-trip');
    expect(directory.groups.map((group) => group.name), [
      'Stancja',
      'Wyjazd',
      'Ekipa',
    ]);
    expect(await store.loadCloudRoomId(), isNull);
  });
}
