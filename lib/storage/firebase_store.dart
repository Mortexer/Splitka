import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../domain/models.dart';
import 'firebase_config.dart';

class RemoteHouseholdChange {
  const RemoteHouseholdChange({
    required this.household,
    required this.inviteCode,
    required this.revision,
    this.fromCache = false,
    this.hasPendingWrites = false,
  });

  final Household household;
  final String inviteCode;
  final int revision;
  final bool fromCache;
  final bool hasPendingWrites;
}

class FirebaseStore {
  static const collection = 'households';
  static const schemaVersion = 2;

  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  Future<bool>? _initializing;

  bool get isConfigured => SplitkaFirebaseConfig.isConfigured;

  Future<bool> initializeIfConfigured() {
    if (!isConfigured) return Future.value(false);
    return _initializing ??= _initialize().catchError((Object error) {
      _initializing = null;
      throw error;
    });
  }

  Future<bool> _initialize() async {
    final app = Firebase.apps.isEmpty
        ? await Firebase.initializeApp(options: SplitkaFirebaseConfig.options)
        : Firebase.app();
    _auth = FirebaseAuth.instanceFor(app: app);
    if (_auth!.currentUser == null) {
      await _auth!.signInAnonymously().timeout(const Duration(seconds: 15));
    }
    _firestore = FirebaseFirestore.instanceFor(app: app);
    return true;
  }

  Future<void> _ensureReady() async {
    if (!await initializeIfConfigured()) {
      throw StateError('Firebase is unavailable on this platform.');
    }
  }

  Future<RemoteHouseholdChange> createHousehold(Household seed) async {
    await _ensureReady();
    final firestore = _firestore!;
    final uid = _auth!.currentUser!.uid;
    final room = firestore.collection(collection).doc();
    final household = seed.copyWith(id: room.id);

    // Transactions require the server and cannot queue a surprise room creation
    // for later when a phone is offline.
    String? code;
    for (var attempt = 0; attempt < 10 && code == null; attempt++) {
      final candidate = createInviteCode();
      final invite = firestore.collection('invites').doc(candidate);
      try {
        await firestore.runTransaction<void>((transaction) async {
          if ((await transaction.get(invite)).exists) {
            throw const _InviteCodeCollision();
          }
          final data = _encode(household, uid, 1)
            ..addAll({'createdBy': uid, 'inviteCode': candidate});
          transaction.set(room, data);
          transaction.set(room.collection('members').doc(uid), {
            'uid': uid,
            'inviteCode': candidate,
            'joinedAt': FieldValue.serverTimestamp(),
          });
          transaction.set(invite, {
            'roomId': room.id,
            'createdBy': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }, timeout: const Duration(seconds: 15));
        code = candidate;
      } on _InviteCodeCollision {
        continue;
      }
    }
    if (code == null) {
      throw const FormatException(
        'Nie udało się znaleźć wolnego kodu. Spróbuj ponownie.',
      );
    }

    return RemoteHouseholdChange(
      household: household,
      inviteCode: code,
      revision: 1,
    );
  }

  Future<RemoteHouseholdChange> joinHousehold(String input) async {
    final code = normalizeInviteCode(input);
    await _ensureReady();
    final firestore = _firestore!;
    final uid = _auth!.currentUser!.uid;

    final roomId = await firestore.runTransaction<String>((transaction) async {
      final invitation = await transaction.get(
        firestore.collection('invites').doc(code),
      );
      final roomId = invitation.data()?['roomId'];
      if (roomId is! String) {
        throw const FormatException('Nie znaleziono tego kodu zaproszenia.');
      }
      final membership = firestore
          .collection(collection)
          .doc(roomId)
          .collection('members')
          .doc(uid);
      if (!(await transaction.get(membership)).exists) {
        transaction.set(membership, {
          'uid': uid,
          'inviteCode': code,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
      return roomId;
    }, timeout: const Duration(seconds: 15));

    final snapshot = await firestore
        .collection(collection)
        .doc(roomId)
        .get(const GetOptions(source: Source.server));
    return _decode(snapshot);
  }

  Stream<RemoteHouseholdChange?> watchHousehold(String roomId) {
    return _firestore!
        .collection(collection)
        .doc(roomId)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => snapshot.exists || !snapshot.metadata.isFromCache)
        .map((snapshot) => snapshot.exists ? _decode(snapshot) : null);
  }

  Future<RemoteHouseholdChange> updateHousehold(
    String roomId,
    Household Function(Household current) updater,
  ) async {
    await _ensureReady();
    final room = _firestore!.collection(collection).doc(roomId);
    return _firestore!.runTransaction<RemoteHouseholdChange>((
      transaction,
    ) async {
      final current = _decode(await transaction.get(room));
      // Reapply the user's operation to the latest server data on every retry.
      final next = updater(
        current.household,
      ).copyWith(id: roomId, updatedAt: DateTime.now().millisecondsSinceEpoch);
      final revision = current.revision + 1;
      transaction.update(
        room,
        _encode(next, _auth!.currentUser!.uid, revision)
          // The server transform lets a stale transaction reach its conflict
          // retry instead of failing revision validation in security rules.
          ..['revision'] = FieldValue.increment(1),
      );
      return RemoteHouseholdChange(
        household: next,
        inviteCode: current.inviteCode,
        revision: revision,
      );
    }, timeout: const Duration(seconds: 15));
  }

  Map<String, dynamic> _encode(Household household, String uid, int revision) {
    return {
      'schemaVersion': schemaVersion,
      'roomCode': household.id,
      'revision': revision,
      'updatedBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'household': household.toJson(),
    };
  }

  RemoteHouseholdChange _decode(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final raw = data?['household'];
    final revision = data?['revision'];
    final code = data?['inviteCode'];
    if (data?['schemaVersion'] != schemaVersion ||
        raw is! Map ||
        revision is! int ||
        revision < 1 ||
        code is! String ||
        raw['id'] != snapshot.id) {
      throw const FormatException('Nieprawidłowe dane grupy.');
    }
    return RemoteHouseholdChange(
      household: Household.fromJson(Map<String, dynamic>.from(raw)),
      inviteCode: code,
      revision: revision,
      fromCache: snapshot.metadata.isFromCache,
      hasPendingWrites: snapshot.metadata.hasPendingWrites,
    );
  }
}

String createInviteCode() {
  return Random.secure().nextInt(10000).toString().padLeft(4, '0');
}

String normalizeInviteCode(String input) {
  final code = input.trim().toLowerCase().replaceAll(RegExp(r'[\s-]'), '');
  final isCurrent = RegExp(r'^[0-9]{4}$').hasMatch(code);
  final isLegacy = RegExp(r'^[a-f0-9]{32}$').hasMatch(code);
  if (!isCurrent && !isLegacy) {
    throw const FormatException('Wpisz 4-cyfrowy kod zaproszenia.');
  }
  return code;
}

class _InviteCodeCollision implements Exception {
  const _InviteCodeCollision();
}
