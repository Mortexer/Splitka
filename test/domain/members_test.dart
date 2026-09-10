import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/domain/models.dart';

void main() {
  test('legacy members stay active and keep their stable IDs', () {
    final household = Household.fromJson({
      'id': 'legacy',
      'members': [
        {'id': 'danus', 'name': 'Danuś', 'color': '#45B164'},
        {'id': 'friend-7', 'name': 'Ola', 'color': '#499FE3'},
      ],
      'receipts': [],
      'updatedAt': 1,
    });

    expect(household.members.map((person) => person.id), ['danus', 'friend-7']);
    expect(household.activeMembers, hasLength(2));
    expect(household.members.every((person) => person.active), isTrue);
  });

  test('member activity round-trips without changing identity', () {
    const person = Person(
      id: 'member-stable-id',
      name: 'Ola',
      color: 0xFF499FE3,
      active: false,
    );

    final decoded = Person.fromJson(person.toJson());

    expect(decoded.id, person.id);
    expect(decoded.name, person.name);
    expect(decoded.color, person.color);
    expect(decoded.active, isFalse);
  });
}
