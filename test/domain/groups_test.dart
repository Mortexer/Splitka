import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/domain/groups.dart';
import 'package:splitka_flutter/domain/models.dart';

void main() {
  test('legacy household gets a group name and active members', () {
    final household = Household.fromJson({
      'id': 'legacy',
      'members': [
        {'id': 'one', 'name': 'Ola', 'color': '#45B164'},
      ],
      'receipts': <Object>[],
      'updatedAt': 1,
    });

    expect(household.name, defaultGroupName);
    expect(household.activeMembers.single.active, isTrue);
  });

  test('group can be renamed and participants keep stable ids', () {
    var household = renameGroup(createDefaultHousehold(), '  Wyjazd  ');
    final ola = createGroupMember(
      household,
      'Ola',
      id: 'guest-ola',
      color: memberColorPalette[1],
    );
    household = addGroupMember(household, ola);
    household = updateGroupMember(
      household,
      ola.id,
      name: 'Aleksandra',
      color: memberColorPalette[2],
    );

    expect(household.name, 'Wyjazd');
    expect(household.members.last.id, 'guest-ola');
    expect(household.members.last.name, 'Aleksandra');
  });

  test('participant names are unique regardless of case', () {
    final household = createDefaultHousehold();
    expect(
      () => createGroupMember(household, 'dAnUś'),
      throwsA(isA<FormatException>()),
    );
  });

  test('used participant can be deactivated but cannot be removed', () {
    final receipt = _receiptFor('danus');
    final household = createDefaultHousehold().copyWith(receipts: [receipt]);
    final inactive = setGroupMemberActive(household, 'danus', false);

    expect(inactive.members.first.active, isFalse);
    expect(
      () => removeGroupMember(inactive, 'danus'),
      throwsA(isA<FormatException>()),
    );
    expect(
      receiptParticipants(inactive, receipt).map((person) => person.id),
      contains('danus'),
    );
    expect(
      settlementParticipants(inactive).map((person) => person.id),
      contains('danus'),
    );
  });

  test('unused participant is removed with the personal shopping list key', () {
    final ola = const Person(id: 'ola', name: 'Ola', color: 0xFF499FE3);
    final household = addGroupMember(
      createDefaultHousehold(),
      ola,
    ).copyWith(shoppingLists: const {'ola': []});

    final removed = removeGroupMember(household, 'ola');

    expect(removed.members.map((person) => person.id), isNot(contains('ola')));
    expect(removed.shoppingLists, isNot(contains('ola')));
  });

  test('last active participant cannot be deactivated', () {
    final household = Household(
      id: 'solo',
      members: const [Person(id: 'solo', name: 'Solo', color: 0xFF45B164)],
      receipts: const [],
      updatedAt: 1,
    );

    expect(
      () => setGroupMemberActive(household, 'solo', false),
      throwsA(isA<FormatException>()),
    );
  });
}

Receipt _receiptFor(String memberId) {
  const item = ReceiptItem(
    id: 'bread',
    name: 'Chleb',
    quantity: '1',
    totalCents: 500,
    kind: ReceiptItemKind.product,
  );
  return Receipt(
    id: 'receipt',
    title: 'Zakupy',
    storeName: 'Sklep',
    importedAt: '2026-09-11',
    payerId: memberId,
    items: const [item],
    assignments: {
      item.id: ItemAssignment(
        itemId: item.id,
        participantIds: [memberId],
        skipped: false,
      ),
    },
    grossCents: 500,
    depositCents: 0,
    depositReturnCents: 0,
    discountCents: 0,
  );
}
