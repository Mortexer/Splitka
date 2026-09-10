import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../storage/firebase_store.dart';
import '../storage/local_store.dart';

enum SyncState { loading, local, connecting, saving, online, offline, error }

class HouseholdController extends ChangeNotifier {
  HouseholdController({LocalStore? localStore, FirebaseStore? firebaseStore})
    : _localStore = localStore ?? LocalStore(),
      _firebaseStore = firebaseStore ?? FirebaseStore();

  final LocalStore _localStore;
  final FirebaseStore _firebaseStore;

  Household household = createDefaultHousehold();
  String roomCode = defaultRoomCode;
  SyncState syncState = SyncState.loading;
  String? error;
  String? inviteCode;
  bool loaded = false;
  bool connectingRoom = false;

  String? _cloudRoomId;
  String _localRoomCode = defaultRoomCode;
  int _revision = 0;
  int _generation = 0;
  int _pendingChanges = 0;
  bool _disposed = false;
  Future<void> _changes = Future.value();
  StreamSubscription<RemoteHouseholdChange?>? _remoteSubscription;

  bool get isCloudRoom => _cloudRoomId != null;
  bool get canUseCloud => _firebaseStore.isConfigured;
  bool get busy => connectingRoom || _pendingChanges > 0;

  Future<void> boot() async {
    final generation = ++_generation;
    try {
      _localRoomCode = await _localStore.loadPersistedRoomCode();
      final cloudRoom = await _localStore.loadCloudRoomId();
      final snapshot = await _localStore.loadHouseholdSnapshot(
        cloudRoom ?? _localRoomCode,
      );
      if (!_isCurrent(generation)) return;
      _cloudRoomId = cloudRoom;
      roomCode = cloudRoom ?? _localRoomCode;
      household = snapshot.household.copyWith(id: roomCode);
      _revision = snapshot.revision;
      inviteCode = snapshot.inviteCode;
      loaded = true;
      syncState = isCloudRoom ? SyncState.connecting : SyncState.local;
      _notify();
      if (isCloudRoom) await _connectRemote(generation);
    } catch (bootError) {
      if (_isCurrent(generation)) {
        loaded = true;
        _markError(bootError);
      }
    }
  }

  Future<bool> createCloudRoom() {
    return _changeRoom(() => _firebaseStore.createHousehold(household));
  }

  Future<bool> joinCloudRoom(String code) {
    return _changeRoom(() => _firebaseStore.joinHousehold(code));
  }

  Future<bool> _changeRoom(
    Future<RemoteHouseholdChange> Function() connect,
  ) async {
    if (busy || !loaded) return false;
    connectingRoom = true;
    error = null;
    _notify();
    final generation = _generation;
    try {
      final room = await connect();
      if (!_isCurrent(generation)) return false;
      await _localStore.saveHousehold(
        room.household,
        revision: room.revision,
        inviteCode: room.inviteCode,
      );
      await _localStore.saveCloudRoomId(room.household.id);
      if (!_isCurrent(generation)) return false;
      final nextGeneration = ++_generation;
      await _remoteSubscription?.cancel();
      if (!_isCurrent(nextGeneration)) return false;
      _cloudRoomId = room.household.id;
      roomCode = room.household.id;
      household = room.household;
      _revision = room.revision;
      inviteCode = room.inviteCode;
      syncState = SyncState.online;
      _notify();
      await _connectRemote(nextGeneration);
      return true;
    } catch (connectionError) {
      if (!_disposed) _markError(connectionError);
      return false;
    } finally {
      connectingRoom = false;
      _notify();
    }
  }

  Future<bool> useLocalMode() async {
    if (busy) return false;
    connectingRoom = true;
    final generation = _generation;
    try {
      final snapshot = await _localStore.loadHouseholdSnapshot(_localRoomCode);
      await _localStore.saveCloudRoomId(null);
      if (!_isCurrent(generation)) return false;
      final nextGeneration = ++_generation;
      await _remoteSubscription?.cancel();
      if (!_isCurrent(nextGeneration)) return false;
      _cloudRoomId = null;
      roomCode = _localRoomCode;
      household = snapshot.household;
      _revision = 0;
      inviteCode = null;
      error = null;
      syncState = SyncState.local;
      return true;
    } catch (localError) {
      if (!_disposed) _markError(localError);
      return false;
    } finally {
      connectingRoom = false;
      _notify();
    }
  }

  Future<bool> commit(Household Function(Household current) updater) {
    if (_disposed || connectingRoom || !loaded) return Future.value(false);
    final generation = _generation;
    final roomId = _cloudRoomId;
    _pendingChanges += 1;
    _notify();
    final operation = _changes.then((_) async {
      if (!_isCurrent(generation)) return false;
      error = null;
      syncState = roomId == null ? SyncState.local : SyncState.saving;
      _notify();
      try {
        if (roomId == null) {
          final next = updater(household).copyWith(
            id: roomCode,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await _localStore.saveHousehold(next);
          if (!_isCurrent(generation)) return false;
          household = next;
          syncState = SyncState.local;
        } else {
          final change = await _firebaseStore.updateHousehold(roomId, updater);
          if (!_isCurrent(generation)) return false;
          _acceptRemote(change, generation);
        }
        error = null;
        _notify();
        return true;
      } catch (saveError) {
        if (_isCurrent(generation)) _markError(saveError);
        return false;
      }
    });
    _changes = operation.then((_) {});
    return operation.whenComplete(() {
      _pendingChanges -= 1;
      _notify();
    });
  }

  Future<void> retryConnection() async {
    if (!isCloudRoom || busy) return;
    error = null;
    syncState = SyncState.connecting;
    final generation = ++_generation;
    _notify();
    try {
      await _connectRemote(generation);
    } catch (connectionError) {
      if (_isCurrent(generation)) _markError(connectionError);
    }
  }

  Future<void> _connectRemote(int generation) async {
    await _remoteSubscription?.cancel();
    if (!await _firebaseStore.initializeIfConfigured()) {
      throw StateError('Połączenie z mieszkaniem jest niedostępne.');
    }
    if (!_isCurrent(generation)) return;
    _remoteSubscription = _firebaseStore
        .watchHousehold(roomCode)
        .listen(
          (change) {
            if (!_isCurrent(generation)) return;
            if (change == null) {
              _markError(
                const FormatException('To mieszkanie już nie istnieje.'),
              );
              return;
            }
            _acceptRemote(change, generation);
          },
          onError: (Object nextError) {
            if (_isCurrent(generation)) _markError(nextError);
          },
        );
  }

  void _acceptRemote(RemoteHouseholdChange change, int generation) {
    if (!_isCurrent(generation) ||
        change.household.id != roomCode ||
        change.revision < _revision) {
      return;
    }
    household = change.household;
    _revision = change.revision;
    inviteCode = change.inviteCode;
    syncState = change.hasPendingWrites
        ? SyncState.saving
        : change.fromCache
        ? SyncState.offline
        : SyncState.online;
    error = null;
    _notify();
    unawaited(
      _localStore
          .saveHousehold(
            change.household,
            revision: change.revision,
            inviteCode: change.inviteCode,
          )
          .catchError((Object saveError) {
            if (_isCurrent(generation)) _markError(saveError);
          }),
    );
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _markError(Object nextError) {
    error = describeConnectionError(nextError);
    syncState = SyncState.error;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    unawaited(_remoteSubscription?.cancel());
    super.dispose();
  }
}

String describeConnectionError(Object error) {
  if (error is TimeoutException) {
    return 'Połączenie trwa zbyt długo. Spróbuj ponownie.';
  }
  if (error is FormatException) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Brak dostępu do mieszkania. Sprawdź kod zaproszenia.',
      'unavailable' || 'network-request-failed' || 'deadline-exceeded' =>
        'Brak połączenia. Zmiana nie została zapisana. Spróbuj ponownie.',
      'operation-not-allowed' => 'Nie można teraz połączyć z mieszkaniem.',
      'aborted' => 'Rachunek właśnie się zmienił. Spróbuj ponownie.',
      _ => 'Nie udało się zapisać zmiany. Spróbuj ponownie.',
    };
  }
  return 'Nie udało się wykonać operacji. Spróbuj ponownie.';
}
