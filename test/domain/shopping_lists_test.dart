import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/domain/shopping_lists.dart';

void main() {
  test('provides one shared list and one list per household member', () {
    final household = createDefaultHousehold();
    expect(shoppingListIds(household), ['common', 'danus', 'kubus', 'damian']);
    expect(shoppingListName(household, 'common'), 'Wspólna');
    expect(shoppingListName(household, 'kubus'), 'Kubuś');
  });

  test(
    'adds, completes and removes shopping items without touching other lists',
    () {
      final initial = createDefaultHousehold();
      final added = addShoppingItem(
        initial,
        'common',
        '  Mleko  ',
        id: 'milk',
        now: DateTime.fromMillisecondsSinceEpoch(10),
      );
      final personal = addShoppingItem(added, 'danus', 'Kawa', id: 'coffee');
      final completed = toggleShoppingItem(personal, 'common', 'milk');
      final cleared = clearCompletedShoppingItems(completed, 'common');

      expect(shoppingItems(added, 'common').single.name, 'Mleko');
      expect(shoppingItems(completed, 'common').single.completed, isTrue);
      expect(shoppingItems(cleared, 'common'), isEmpty);
      expect(shoppingItems(cleared, 'danus').single.id, 'coffee');
    },
  );

  test('rejects unknown lists, empty names and stale item edits', () {
    final household = createDefaultHousehold();
    expect(() => shoppingItems(household, 'stranger'), throwsFormatException);
    expect(
      () => addShoppingItem(household, 'common', '  '),
      throwsFormatException,
    );
    expect(
      () => toggleShoppingItem(household, 'common', 'missing'),
      throwsFormatException,
    );
    expect(
      () => removeShoppingItem(household, 'common', 'missing'),
      throwsFormatException,
    );
  });

  test('round-trips shopping lists through household JSON', () {
    final household = addShoppingItem(
      createDefaultHousehold(),
      'damian',
      'Ryż',
      id: 'rice',
    );
    final decoded = Household.fromJson(household.toJson());
    expect(shoppingItems(decoded, 'damian').single.name, 'Ryż');
    expect(Household.fromJson({'id': 'legacy'}).shoppingLists, isEmpty);
  });
}
