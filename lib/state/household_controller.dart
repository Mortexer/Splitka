import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../storage/firebase_store.dart';
import '../storage/local_store.dart';

enum SyncState {
  loading,
  local,
  connecting,
  saving,
  online,
  error,
}

class HouseholdController extends ChangeNotifier {
  HouseholdController({
    LocalStore? localStore,
    FirebaseStore? firebaseStore,
  })  : _localStore = localStore ?? LocalStore(),
        _firebaseStore = firebaseStore ?? FirebaseStore();

  final LocalStore _localStore;
  final FirebaseStore _firebaseStore;

  Household household = createDefaultHousehold();
  String roomCode = defaultRoomCode;
  SyncState syncState = SyncState.loading;
  String? error;
  bool loaded = false;

  String? _clientId;
  bool _localSnapshotExists = false;
  StreamSubscription<RemoteHouseholdChange?>? _remoteSubscription;

  Future<void> boot() async {
    try {
      final savedRoomCode = await _localStore.loadPersistedRoomCode();
      final snapshot = await _localStore.loadHouseholdSnapshot(savedRoomCode);
      final clientId = await _localStore.loadOrCreateClientId();

      roomCode = savedRoomCode;
      household = snapshot.household;
      _localSnapshotExists = snapshot.exists;
      _clientId = clientId;
      loaded = true;
      syncState = _firebaseStore.isConfigured ? SyncState.connecting : SyncState.local;
      error = null;
      notifyListeners();

      await _connectRemote();
    } catch (bootError) {
      _markError(bootError);
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> switchRoomCode(String nextRoomCode) async {
    final normalized = normalizeRoomCode(nextRoomCode);
    final snapshot = await _localStore.loadHouseholdSnapshot(normalized);

    await _remoteSubscription?.cancel();
    await _localStore.savePersistedRoomCode(normalized);

    roomCode = normalized;
    household = snapshot.household;
    _localSnapshotExists = snapshot.exists;
    syncState = _firebaseStore.isConfigured ? SyncState.connecting : SyncState.local;
    error = null;
    notifyListeners();

    await _connectRemote();
  }

  Future<void> commit(Household Function(Household current) updater) async {
    final next = updater(household).copyWith(
      id: roomCode,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    household = next;
    _localSnapshotExists = true;
    syncState = _firebaseStore.isConfigured ? SyncState.saving : SyncState.local;
    error = null;
    notifyListeners();

    try {
      await _localStore.saveHousehold(next);

      if (await _firebaseStore.initializeIfConfigured()) {
        await _firebaseStore.saveHousehold(next, _clientId ?? 'unknown-client');
        syncState = SyncState.online;
      } else {
        syncState = SyncState.local;
      }

      error = null;
      notifyListeners();
    } catch (commitError) {
      _markError(commitError);
    }
  }

  Future<void> _connectRemote() async {
    await _remoteSubscription?.cancel();

    if (!await _firebaseStore.initializeIfConfigured()) {
      syncState = SyncState.local;
      notifyListeners();
      return;
    }

    syncState = SyncState.connecting;
    notifyListeners();

    _remoteSubscription = _firebaseStore.watchHousehold(roomCode).listen(
      (change) {
        if (change == null) {
          _createRemoteFromLocal();
          return;
        }

        if (_localSnapshotExists && change.household.updatedAt < household.updatedAt) {
          _pushLocalToRemote();
          return;
        }

        household = change.household;
        _localSnapshotExists = true;
        syncState = change.hasPendingWrites ? SyncState.saving : SyncState.online;
        error = null;
        notifyListeners();
        unawaited(_localStore.saveHousehold(change.household));
      },
      onError: _markError,
    );
  }

  Future<void> _createRemoteFromLocal() async {
    _localSnapshotExists = true;
    syncState = SyncState.saving;
    notifyListeners();

    try {
      await _localStore.saveHousehold(household);
      await _firebaseStore.saveHousehold(household.copyWith(id: roomCode), _clientId ?? 'unknown-client');
      syncState = SyncState.online;
      error = null;
      notifyListeners();
    } catch (remoteError) {
      _markError(remoteError);
    }
  }

  Future<void> _pushLocalToRemote() async {
    syncState = SyncState.saving;
    notifyListeners();

    try {
      await _firebaseStore.saveHousehold(household, _clientId ?? 'unknown-client');
      syncState = SyncState.online;
      error = null;
      notifyListeners();
    } catch (remoteError) {
      _markError(remoteError);
    }
  }

  void _markError(Object nextError) {
    error = nextError.toString();
    syncState = SyncState.error;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_remoteSubscription?.cancel());
    super.dispose();
  }
}
