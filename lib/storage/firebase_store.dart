import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../domain/models.dart';
import 'firebase_config.dart';

class RemoteHouseholdChange {
  const RemoteHouseholdChange({
    required this.household,
    required this.fromCache,
    required this.hasPendingWrites,
  });

  final Household household;
  final bool fromCache;
  final bool hasPendingWrites;
}

class FirebaseStore {
  static const collection = 'households';
  static const schemaVersion = 1;

  FirebaseFirestore? _firestore;

  bool get isConfigured => SplitkaFirebaseConfig.isConfigured;
  bool get isReady => _firestore != null;

  Future<bool> initializeIfConfigured() async {
    if (!isConfigured) {
      return false;
    }

    if (_firestore != null) {
      return true;
    }

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: SplitkaFirebaseConfig.options);
    }

    _firestore = FirebaseFirestore.instance;
    return true;
  }

  Stream<RemoteHouseholdChange?> watchHousehold(String roomCode) {
    final firestore = _requireFirestore();

    return firestore
        .collection(collection)
        .doc(roomCode)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.data();
      final householdData = data?['household'];

      if (householdData is! Map) {
        throw const FormatException('Nieprawidłowe dane pokoju w Firestore.');
      }

      return RemoteHouseholdChange(
        household: Household.fromJson(Map<String, dynamic>.from(householdData), fallbackId: roomCode),
        fromCache: snapshot.metadata.isFromCache,
        hasPendingWrites: snapshot.metadata.hasPendingWrites,
      );
    });
  }

  Future<void> saveHousehold(Household household, String clientId) async {
    final firestore = _requireFirestore();

    await firestore.collection(collection).doc(household.id).set({
      'schemaVersion': schemaVersion,
      'roomCode': household.id,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': clientId,
      'household': household.toJson(),
    }, SetOptions(merge: true));
  }

  FirebaseFirestore _requireFirestore() {
    final firestore = _firestore;

    if (firestore == null) {
      throw StateError('Firebase nie jest skonfigurowany.');
    }

    return firestore;
  }
}
