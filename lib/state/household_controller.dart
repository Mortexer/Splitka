import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../domain/groups.dart';
import '../domain/models.dart';
import '../services/notification_service.dart';
import '../storage/firebase_store.dart';
import '../storage/local_store.dart';

enum SyncState { loading, local, connecting, saving, online, offline, error }

class HouseholdController extends ChangeNotifier {
  HouseholdController({
    LocalStore? localStore,
    FirebaseStore? firebaseStore,
    NotificationService? notificationService,
  }) : _localStore = localStore ?? LocalStore(),
       _firebaseStore = firebaseStore ?? FirebaseStore(),
       _notificationService = notificationService ?? NotificationService();

  final LocalStore _localStore;
  final FirebaseStore _firebaseStore;
  final NotificationService _notificationService;

  Household household = createDefaultHousehold();
  List<StoredGroup> groups = const [
    StoredGroup(id: defaultRoomCode, name: defaultGroupName, isCloud: false),
  ];
  String roomCode = defaultRoomCode;
  SyncState syncState = SyncState.loading;
  String? error;
  String? inviteCode;
  bool loaded = false;
  bool connectingRoom = false;
  String? notificationMemberId;

  String? _cloudRoomId;
  int _revision = 0;
  int _generation = 0;
  int _pendingChanges = 0;
  bool _disposed = false;
  Future<void> _changes = Future.value();
  StreamSubscription<RemoteHouseholdChange?>? _remoteSubscription;

  bool get isCloudRoom => _cloudRoomId != null;
  StoredGroup get currentGroup => groups.firstWhere(
    (group) => group.id == roomCode,
    orElse: () => groups.first,
  );
  bool get canUseCloud => _firebaseStore.isConfigured;
  bool get busy => connectingRoom || _pendingChanges > 0;

  Future<void> boot() async {
    final generation = ++_generation;
    try {
      final directory = await _localStore.loadGroupDirectory();
      final selected = directory.groups.firstWhere(
        (group) => group.id == directory.activeGroupId,
      );
      final snapshot = await _localStore.loadHouseholdSnapshot(selected.id);
      if (!_isCurrent(generation)) return;
      groups = directory.groups;
      _cloudRoomId = selected.isCloud ? selected.id : null;
      roomCode = selected.id;
      household = snapshot.household.copyWith(id: roomCode);
      _revision = snapshot.revision;
      inviteCode = snapshot.inviteCode;
      notificationMemberId = await _localStore.loadNotificationMember(
        selected.id,
      );
      loaded = true;
      syncState = isCloudRoom ? SyncState.connecting : SyncState.local;
      _notify();
      if (isCloudRoom) {
        await _connectRemote(generation);
        await _restoreNotifications();
      }
    } catch (bootError) {
      if (_isCurrent(generation)) {
        loaded = true;
        _markError(bootError);
      }
    }
  }

  Future<bool> createCloudRoom() {
    if (isCloudRoom) return Future.value(true);
    final localGroupId = roomCode;
    return _changeRoom(
      () => _firebaseStore.createHousehold(household),
      replaceGroupId: localGroupId,
    );
  }

  Future<bool> joinCloudRoom(String code) {
    return _changeRoom(() => _firebaseStore.joinHousehold(code));
  }

  Future<bool> createGroup(String name, GroupAccessMode accessMode) async {
    if (accessMode == GroupAccessMode.private) {
      return createLocalGroup(name);
    }
    try {
      final seed = renameGroup(createDefaultHousehold(), name);
      return _changeRoom(() => _firebaseStore.createHousehold(seed));
    } catch (createError) {
      _markError(createError);
      return false;
    }
  }

  Future<bool> createLocalGroup(String name, {String? groupId}) async {
    if (busy || !loaded) return false;
    connectingRoom = true;
    error = null;
    _notify();
    var generation = _generation;
    try {
      final id = groupId ?? _newLocalGroupId();
      if (groups.any((group) => group.id == id)) {
        throw const FormatException('Taka grupa już istnieje.');
      }
      final next = renameGroup(createDefaultHousehold(id), name);
      final entry = StoredGroup(id: id, name: next.name, isCloud: false);
      final nextGroups = [...groups, entry];
      generation = ++_generation;
      await _remoteSubscription?.cancel();
      await _localStore.saveHousehold(next);
      await _localStore.saveGroupDirectory(nextGroups, id);
      if (!_isCurrent(generation)) return false;
      groups = nextGroups;
      _cloudRoomId = null;
      roomCode = id;
      household = next;
      _revision = 0;
      inviteCode = null;
      notificationMemberId = null;
      syncState = SyncState.local;
      return true;
    } catch (createError) {
      if (_isCurrent(generation)) _markError(createError);
      return false;
    } finally {
      connectingRoom = false;
      _notify();
    }
  }

  Future<bool> switchGroup(String groupId) async {
    if (busy || !loaded) return false;
    final target = groups.where((group) => group.id == groupId).firstOrNull;
    if (target == null) return false;
    if (target.id == roomCode) return true;
    connectingRoom = true;
    error = null;
    final generation = ++_generation;
    _notify();
    try {
      await _remoteSubscription?.cancel();
      final snapshot = await _localStore.loadHouseholdSnapshot(target.id);
      await _localStore.saveGroupDirectory(groups, target.id);
      if (!_isCurrent(generation)) return false;
      _cloudRoomId = target.isCloud ? target.id : null;
      roomCode = target.id;
      household = snapshot.household.copyWith(id: target.id);
      _revision = snapshot.revision;
      inviteCode = snapshot.inviteCode;
      notificationMemberId = await _localStore.loadNotificationMember(
        target.id,
      );
      syncState = target.isCloud ? SyncState.connecting : SyncState.local;
      _notify();
      if (target.isCloud) {
        await _connectRemote(generation);
        await _restoreNotifications();
      }
      return true;
    } catch (switchError) {
      if (_isCurrent(generation)) _markError(switchError);
      return false;
    } finally {
      connectingRoom = false;
      _notify();
    }
  }

  Future<bool> removeGroup(String groupId) async {
    if (busy || !loaded) return false;
    if (groups.length <= 1) {
      _markError(const FormatException('Musi zostać co najmniej jedna grupa.'));
      return false;
    }
    if (groupId == roomCode) {
      _markError(const FormatException('Najpierw przełącz się na inną grupę.'));
      return false;
    }
    connectingRoom = true;
    error = null;
    _notify();
    try {
      final nextGroups = groups
          .where((group) => group.id != groupId)
          .toList(growable: false);
      await _localStore.saveGroupDirectory(nextGroups, roomCode);
      await _localStore.deleteHousehold(groupId);
      groups = nextGroups;
      error = null;
      _notify();
      return true;
    } catch (removeError) {
      _markError(removeError);
      return false;
    } finally {
      connectingRoom = false;
      _notify();
    }
  }

  Future<bool> renameCurrentGroup(String name) {
    return commit((current) => renameGroup(current, name));
  }

  Future<bool> addMember(String name, int color) {
    return commit(
      (current) => addGroupMember(
        current,
        createGroupMember(current, name, color: color),
      ),
    );
  }

  Future<bool> updateMember(String memberId, String name, int color) {
    return commit(
      (current) =>
          updateGroupMember(current, memberId, name: name, color: color),
    );
  }

  Future<bool> setMemberActive(String memberId, bool active) {
    return commit((current) => setGroupMemberActive(current, memberId, active));
  }

  Future<bool> removeMember(String memberId) {
    return commit((current) => removeGroupMember(current, memberId));
  }

  Future<bool> _changeRoom(
    Future<RemoteHouseholdChange> Function() connect, {
    String? replaceGroupId,
  }) async {
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
      final baseGroups = replaceGroupId == null
          ? groups
          : groups.where((group) => group.id != replaceGroupId).toList();
      final nextGroups = _upsertGroup(
        StoredGroup(
          id: room.household.id,
          name: room.household.name,
          isCloud: true,
        ),
        source: baseGroups,
      );
      await _localStore.saveGroupDirectory(nextGroups, room.household.id);
      if (!_isCurrent(generation)) return false;
      final nextGeneration = ++_generation;
      await _remoteSubscription?.cancel();
      if (!_isCurrent(nextGeneration)) return false;
      _cloudRoomId = room.household.id;
      groups = nextGroups;
      roomCode = room.household.id;
      household = room.household;
      _revision = room.revision;
      inviteCode = room.inviteCode;
      notificationMemberId = await _localStore.loadNotificationMember(
        room.household.id,
      );
      syncState = SyncState.online;
      _notify();
      await _connectRemote(nextGeneration);
      await _restoreNotifications();
      if (replaceGroupId != null) {
        await _localStore.deleteHousehold(replaceGroupId);
      }
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
    final local = groups.where((group) => !group.isCloud).firstOrNull;
    if (local == null) {
      return createLocalGroup(defaultGroupName, groupId: defaultRoomCode);
    }
    return switchGroup(local.id);
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
          final nextGroups = _groupsWithCurrentName(next.name);
          await _localStore.saveGroupDirectory(nextGroups, roomCode);
          if (!_isCurrent(generation)) return false;
          groups = nextGroups;
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

  Future<bool> enableNotifications(String memberId) async {
    if (!isCloudRoom || busy) return false;
    if (!household.activeMembers.any((member) => member.id == memberId)) {
      return false;
    }
    try {
      final enabled = await _notificationService.enable(roomCode, memberId);
      if (!enabled) return false;
      await _localStore.saveNotificationMember(roomCode, memberId);
      notificationMemberId = memberId;
      _notify();
      return true;
    } catch (notificationError) {
      _markError(notificationError);
      return false;
    }
  }

  Future<bool> disableNotifications() async {
    if (!isCloudRoom) return false;
    try {
      await _notificationService.disable(roomCode);
      await _localStore.saveNotificationMember(roomCode, null);
      notificationMemberId = null;
      _notify();
      return true;
    } catch (notificationError) {
      _markError(notificationError);
      return false;
    }
  }

  Future<void> _restoreNotifications() async {
    final memberId = notificationMemberId;
    if (memberId == null ||
        !household.activeMembers.any((member) => member.id == memberId)) {
      return;
    }
    await _notificationService.restore(roomCode, memberId);
  }

  Future<void> _connectRemote(int generation) async {
    await _remoteSubscription?.cancel();
    if (!await _firebaseStore.initializeIfConfigured()) {
      throw StateError('Połączenie z grupą jest niedostępne.');
    }
    if (!_isCurrent(generation)) return;
    _remoteSubscription = _firebaseStore
        .watchHousehold(roomCode)
        .listen(
          (change) {
            if (!_isCurrent(generation)) return;
            if (change == null) {
              _markError(const FormatException('Ta grupa już nie istnieje.'));
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
    groups = _groupsWithCurrentName(change.household.name);
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
      Future.wait<void>([
        _localStore.saveHousehold(
          change.household,
          revision: change.revision,
          inviteCode: change.inviteCode,
        ),
        _localStore.saveGroupDirectory(groups, roomCode),
      ]).then<void>((_) {}).catchError((Object saveError) {
        if (_isCurrent(generation)) _markError(saveError);
      }),
    );
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  List<StoredGroup> _upsertGroup(
    StoredGroup next, {
    Iterable<StoredGroup>? source,
  }) {
    final without = (source ?? groups).where((group) => group.id != next.id);
    return [...without, next];
  }

  List<StoredGroup> _groupsWithCurrentName(String name) {
    return groups
        .map(
          (group) => group.id == roomCode ? group.copyWith(name: name) : group,
        )
        .toList(growable: false);
  }

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
    unawaited(_notificationService.dispose());
    super.dispose();
  }
}

String _newLocalGroupId() {
  return 'local-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
}

String describeConnectionError(Object error) {
  if (error is TimeoutException) {
    return 'Połączenie trwa zbyt długo. Spróbuj ponownie.';
  }
  if (error is FormatException) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' => 'Brak dostępu do grupy. Sprawdź kod zaproszenia.',
      'unavailable' || 'network-request-failed' || 'deadline-exceeded' =>
        'Brak połączenia. Zmiana nie została zapisana. Spróbuj ponownie.',
      'operation-not-allowed' => 'Nie można teraz połączyć z grupą.',
      'aborted' => 'Rachunek właśnie się zmienił. Spróbuj ponownie.',
      _ => 'Nie udało się zapisać zmiany. Spróbuj ponownie.',
    };
  }
  return 'Nie udało się wykonać operacji. Spróbuj ponownie.';
}
