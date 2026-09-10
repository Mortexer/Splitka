import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

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

class LocalStore {
  static const _roomCodeKey = 'splitka.roomCode';
  static const _clientIdKey = 'splitka.clientId';
  static const _cloudRoomIdKey = 'splitka.cloudRoomId';
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
