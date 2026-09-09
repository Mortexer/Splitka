import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class LocalHouseholdSnapshot {
  const LocalHouseholdSnapshot({
    required this.household,
    required this.exists,
  });

  final Household household;
  final bool exists;
}

class LocalStore {
  static const _roomCodeKey = 'splitka.roomCode';
  static const _clientIdKey = 'splitka.clientId';

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
    final normalized = normalizeRoomCode(roomCode);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_householdKey(normalized));

    if (saved == null) {
      return LocalHouseholdSnapshot(
        household: createDefaultHousehold(normalized),
        exists: false,
      );
    }

    try {
      return LocalHouseholdSnapshot(
        household: Household.fromJson(jsonDecode(saved) as Map<String, dynamic>, fallbackId: normalized),
        exists: true,
      );
    } catch (_) {
      return LocalHouseholdSnapshot(
        household: createDefaultHousehold(normalized),
        exists: false,
      );
    }
  }

  Future<void> saveHousehold(Household household) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_householdKey(household.id), jsonEncode(household.toJson()));
  }

  Future<String> loadOrCreateClientId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_clientIdKey);

    if (saved != null) {
      return saved;
    }

    final clientId = 'client-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    await prefs.setString(_clientIdKey, clientId);
    return clientId;
  }

  String _householdKey(String roomCode) {
    return 'splitka.household.${normalizeRoomCode(roomCode)}';
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
