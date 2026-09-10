import 'dart:math';

import 'models.dart';

const memberColorPalette = [
  0xFF45B164,
  0xFF499FE3,
  0xFFF59740,
  0xFFE05C74,
  0xFF9B7DE3,
  0xFF35A7A0,
  0xFFD0A72F,
  0xFF7D9A48,
];

Household renameGroup(Household household, String name) {
  final normalized = _validateName(name, label: 'nazwę grupy', maxLength: 40);
  return household.copyWith(name: normalized);
}

Person createGroupMember(
  Household household,
  String name, {
  String? id,
  int? color,
  DateTime? now,
}) {
  final normalized = _validateMemberName(household, name);
  final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
  return Person(
    id: id ?? 'member-${timestamp.toRadixString(36)}-${_randomSuffix()}',
    name: normalized,
    color:
        color ??
        memberColorPalette[household.members.length %
            memberColorPalette.length],
  );
}

Household addGroupMember(Household household, Person member) {
  if (household.members.length >= maxHouseholdMembers) {
    throw const FormatException('Grupa może mieć maksymalnie 20 osób.');
  }
  if (member.id.trim().isEmpty ||
      household.members.any((person) => person.id == member.id)) {
    throw const FormatException(
      'Nie udało się utworzyć unikalnego uczestnika.',
    );
  }
  _validateMemberName(household, member.name);
  return household.copyWith(members: [...household.members, member]);
}

Household updateGroupMember(
  Household household,
  String memberId, {
  required String name,
  required int color,
}) {
  final current = _member(household, memberId);
  final normalized = _validateMemberName(
    household,
    name,
    exceptMemberId: memberId,
  );
  return household.copyWith(
    members: household.members
        .map(
          (person) => person.id == memberId
              ? current.copyWith(name: normalized, color: color)
              : person,
        )
        .toList(),
  );
}

Household setGroupMemberActive(
  Household household,
  String memberId,
  bool active,
) {
  final current = _member(household, memberId);
  if (!active && current.active && household.activeMembers.length <= 1) {
    throw const FormatException(
      'W grupie musi zostać co najmniej jedna aktywna osoba.',
    );
  }
  return household.copyWith(
    members: household.members
        .map(
          (person) =>
              person.id == memberId ? person.copyWith(active: active) : person,
        )
        .toList(),
  );
}

bool memberHasData(Household household, String memberId) {
  if ((household.shoppingLists[memberId] ?? const []).isNotEmpty) return true;
  for (final receipt in household.receipts) {
    if (receipt.payerId == memberId) return true;
    if (receipt.assignments.values.any(
      (assignment) => assignment.participantIds.contains(memberId),
    )) {
      return true;
    }
  }
  return false;
}

Household removeGroupMember(Household household, String memberId) {
  final current = _member(household, memberId);
  if (household.members.length <= 1 ||
      (current.active && household.activeMembers.length <= 1)) {
    throw const FormatException(
      'W grupie musi zostać co najmniej jedna osoba.',
    );
  }
  if (memberHasData(household, memberId)) {
    throw const FormatException(
      'Ta osoba występuje w rachunkach lub na liście. Możesz ją dezaktywować.',
    );
  }
  final shoppingLists = {...household.shoppingLists}..remove(memberId);
  return household.copyWith(
    members: household.members
        .where((person) => person.id != memberId)
        .toList(),
    shoppingLists: shoppingLists,
  );
}

List<Person> receiptParticipants(Household household, Receipt receipt) {
  final referencedIds = <String>{receipt.payerId};
  for (final assignment in receipt.assignments.values) {
    referencedIds.addAll(assignment.participantIds);
  }
  return household.members
      .where((person) => person.active || referencedIds.contains(person.id))
      .toList(growable: false);
}

List<Person> settlementParticipants(Household household) {
  final referencedIds = <String>{};
  for (final receipt in household.receipts) {
    referencedIds.add(receipt.payerId);
    for (final assignment in receipt.assignments.values) {
      referencedIds.addAll(assignment.participantIds);
    }
  }
  return household.members
      .where((person) => person.active || referencedIds.contains(person.id))
      .toList(growable: false);
}

Person _member(Household household, String memberId) {
  for (final person in household.members) {
    if (person.id == memberId) return person;
  }
  throw const FormatException('Nie znaleziono tej osoby.');
}

String _validateMemberName(
  Household household,
  String name, {
  String? exceptMemberId,
}) {
  final normalized = _validateName(name, label: 'imię', maxLength: 30);
  final duplicate = household.members.any(
    (person) =>
        person.id != exceptMemberId &&
        person.name.trim().toLowerCase() == normalized.toLowerCase(),
  );
  if (duplicate) {
    throw const FormatException('W grupie jest już osoba o takim imieniu.');
  }
  return normalized;
}

String _validateName(
  String value, {
  required String label,
  required int maxLength,
}) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw FormatException('Wpisz $label.');
  if (normalized.length > maxLength) {
    throw FormatException('Maksymalna długość to $maxLength znaków.');
  }
  return normalized;
}

String _randomSuffix() {
  return Random.secure().nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
}
