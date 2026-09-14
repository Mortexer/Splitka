import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

enum GroupAccessMode { private, shared }

class LocalHouseholdSnapshot {
  const LocalHouseholdSnapshot({
    required this.household,
    required this.exists,
    this.revision = 0,
    this.inviteCode,
  });

  final Household household;
  final bool exists;
  final int revision;
  final String? inviteCode;
}

class StoredGroup {
  const StoredGroup({
    required this.id,
    required this.name,
    required this.isCloud,
  });

  final String id;
  final String name;
  final bool isCloud;

  GroupAccessMode get accessMode =>
      isCloud ? GroupAccessMode.shared : GroupAccessMode.private;

  StoredGroup copyWith({String? id, String? name, bool? isCloud}) {
    return StoredGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      isCloud: isCloud ?? this.isCloud,
    );
  }

  factory StoredGroup.fromJson(Map<String, dynamic> json) {
    return StoredGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? defaultGroupName,
      isCloud: json['isCloud'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isCloud': isCloud};
}

class GroupDirectory {
  const GroupDirectory({required this.groups, required this.activeGroupId});

  final List<StoredGroup> groups;
  final String activeGroupId;
}

class LocalStore {
  static const _roomCodeKey = 'splitka.roomCode';
  static const _clientIdKey = 'splitka.clientId';
  static const _cloudRoomIdKey = 'splitka.cloudRoomId';
  static const _groupsKey = 'splitka.groups.v1';
  static const _activeGroupIdKey = 'splitka.activeGroupId';
  static const _notificationMemberPrefix = 'splitka.notificationMember.';
  Future<void> _writes = Future.value();

  Future<String?> loadCloudRoomId() async {
    return (await SharedPreferences.getInstance()).getString(_cloudRoomIdKey);
  }

  Future<void> saveCloudRoomId(String? roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = roomId == null
        ? await prefs.remove(_cloudRoomIdKey)
        : await prefs.setString(_cloudRoomIdKey, roomId);
    if (!saved) throw StateError('Nie udało się zapisać wyboru mieszkania.');
  }

  Future<GroupDirectory> loadGroupDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_groupsKey);
    if (encoded != null) {
      try {
        final raw = jsonDecode(encoded) as List<dynamic>;
        final groups = raw
            .whereType<Map>()
            .map(
              (item) => StoredGroup.fromJson(Map<String, dynamic>.from(item)),
            )
            .where((group) => group.id.isNotEmpty)
            .fold<List<StoredGroup>>([], (unique, group) {
              if (!unique.any((item) => item.id == group.id)) unique.add(group);
              return unique;
            });
        if (groups.isNotEmpty) {
          final savedActive = prefs.getString(_activeGroupIdKey);
          final active = groups.any((group) => group.id == savedActive)
              ? savedActive!
              : groups.first.id;
          return GroupDirectory(groups: groups, activeGroupId: active);
        }
      } catch (_) {
        // Fall through to the legacy keys and rebuild the directory.
      }
    }

    final localId = await loadPersistedRoomCode();
    final cloudId = await loadCloudRoomId();
    final localSnapshot = await loadHouseholdSnapshot(localId);
    final groups = <StoredGroup>[
      StoredGroup(
        id: localId,
        name: localSnapshot.household.name,
        isCloud: false,
      ),
    ];
    if (cloudId != null && cloudId != localId) {
      final cloudSnapshot = await loadHouseholdSnapshot(cloudId);
      groups.add(
        StoredGroup(
          id: cloudId,
          name: cloudSnapshot.household.name,
          isCloud: true,
        ),
      );
    }
    final directory = GroupDirectory(
      groups: groups,
      activeGroupId: cloudId ?? localId,
    );
    await saveGroupDirectory(directory.groups, directory.activeGroupId);
    return directory;
  }

  Future<void> saveGroupDirectory(
    List<StoredGroup> groups,
    String activeGroupId,
  ) async {
    if (groups.isEmpty || !groups.any((group) => group.id == activeGroupId)) {
      throw const FormatException('Nieprawidłowa lista grup.');
    }
    final prefs = await SharedPreferences.getInstance();
    final active = groups.firstWhere((group) => group.id == activeGroupId);
    final results = await Future.wait([
      prefs.setString(
        _groupsKey,
        jsonEncode(groups.map((group) => group.toJson()).toList()),
      ),
      prefs.setString(_activeGroupIdKey, activeGroupId),
      prefs.setString(
        _roomCodeKey,
        active.isCloud ? defaultRoomCode : active.id,
      ),
      active.isCloud
          ? prefs.setString(_cloudRoomIdKey, active.id)
          : prefs.remove(_cloudRoomIdKey),
    ]);
    if (results.any((saved) => !saved)) {
      throw StateError('Nie udało się zapisać listy grup.');
    }
  }

  Future<String> loadPersistedRoomCode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_roomCodeKey);
    return saved == null ? defaultRoomCode : normalizeRoomCode(saved);
  }

  Future<void> savePersistedRoomCode(String roomCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roomCodeKey, normalizeRoomCode(roomCode));
  }

  Future<LocalHouseholdSnapshot> loadHouseholdSnapshot(String roomCode) async {
    final normalized = roomCode;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_householdKey(normalized));

    if (saved == null) {
      return LocalHouseholdSnapshot(
        household: createDefaultHousehold(normalized),
        exists: false,
      );
    }

    try {
      final data = jsonDecode(saved) as Map<String, dynamic>;
      return LocalHouseholdSnapshot(
        household: Household.fromJson(data, fallbackId: normalized),
        exists: true,
        revision: data['cloudRevision'] as int? ?? 0,
        inviteCode: data['inviteCode'] as String?,
      );
    } catch (_) {
      return LocalHouseholdSnapshot(
        household: createDefaultHousehold(normalized),
        exists: false,
      );
    }
  }

  Future<void> saveHousehold(
    Household household, {
    int revision = 0,
    String? inviteCode,
  }) {
    final next = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(
        _householdKey(household.id),
        jsonEncode({
          ...household.toJson(),
          'cloudRevision': revision,
          'inviteCode': inviteCode,
        }),
      );
      if (!saved) {
        throw StateError('Nie udało się zapisać danych na telefonie.');
      }
    });
    _writes = next.catchError((Object _) {});
    return next;
  }

  Future<void> deleteHousehold(String roomCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_householdKey(roomCode));
  }

  Future<String> loadOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_clientIdKey);

    if (saved != null) {
      return saved;
    }

    final clientId =
        'client-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    await prefs.setString(_clientIdKey, clientId);
    return clientId;
  }

  Future<String?> loadNotificationMember(String roomId) async {
    return (await SharedPreferences.getInstance()).getString(
      '$_notificationMemberPrefix$roomId',
    );
  }

  Future<void> saveNotificationMember(String roomId, String? memberId) async {
    final prefs = await SharedPreferences.getInstance();
    if (memberId == null) {
      await prefs.remove('$_notificationMemberPrefix$roomId');
    } else {
      await prefs.setString('$_notificationMemberPrefix$roomId', memberId);
    }
  }

  String _householdKey(String roomCode) {
    return 'splitka.household.$roomCode';
  }
}

String normalizeRoomCode(String roomCode) {
  final lower = roomCode.trim().toLowerCase();
  final withoutPolish = lower
      .replaceAll('ą', 'a')
      .replaceAll('ć', 'c')
      .replaceAll('ę', 'e')
      .replaceAll('ł', 'l')
      .replaceAll('ń', 'n')
      .replaceAll('ó', 'o')
      .replaceAll('ś', 's')
      .replaceAll('ż', 'z')
      .replaceAll('ź', 'z');
  final normalized = withoutPolish
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  return normalized.isEmpty ? defaultRoomCode : normalized;
}
