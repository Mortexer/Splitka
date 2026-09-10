import 'dart:math';

import 'models.dart';

const commonShoppingListId = 'common';

List<String> shoppingListIds(Household household) {
  return [
    commonShoppingListId,
    ...household.members
        .where(
          (member) =>
              member.active ||
              (household.shoppingLists[member.id] ?? const []).isNotEmpty,
        )
        .map((member) => member.id),
  ];
}

List<ShoppingItem> shoppingItems(Household household, String listId) {
  _checkList(household, listId);
  return household.shoppingLists[listId] ?? const [];
}

Household addShoppingItem(
  Household household,
  String listId,
  String name, {
  DateTime? now,
  String? id,
}) {
  _checkList(household, listId);
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Wpisz nazwę produktu.');
  }
  final timestamp = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final item = ShoppingItem(
    id: id ?? 'shopping-$timestamp-${_randomSuffix()}',
    name: trimmed,
    completed: false,
    createdAt: timestamp,
  );
  return household.copyWith(
    shoppingLists: {
      ...household.shoppingLists,
      listId: [...shoppingItems(household, listId), item],
    },
  );
}

Household toggleShoppingItem(
  Household household,
  String listId,
  String itemId,
) {
  final items = shoppingItems(household, listId);
  if (!items.any((item) => item.id == itemId)) {
    throw const FormatException('Ta pozycja została już usunięta.');
  }
  return household.copyWith(
    shoppingLists: {
      ...household.shoppingLists,
      listId: items
          .map(
            (item) => item.id == itemId
                ? item.copyWith(completed: !item.completed)
                : item,
          )
          .toList(),
    },
  );
}

Household removeShoppingItem(
  Household household,
  String listId,
  String itemId,
) {
  final items = shoppingItems(household, listId);
  if (!items.any((item) => item.id == itemId)) {
    throw const FormatException('Ta pozycja została już usunięta.');
  }
  return household.copyWith(
    shoppingLists: {
      ...household.shoppingLists,
      listId: items.where((item) => item.id != itemId).toList(),
    },
  );
}

Household clearCompletedShoppingItems(Household household, String listId) {
  final items = shoppingItems(household, listId);
  return household.copyWith(
    shoppingLists: {
      ...household.shoppingLists,
      listId: items.where((item) => !item.completed).toList(),
    },
  );
}

String shoppingListName(Household household, String listId) {
  if (listId == commonShoppingListId) return 'Wspólna';
  for (final member in household.members) {
    if (member.id == listId) return member.name;
  }
  throw const FormatException('Nie znaleziono tej listy zakupów.');
}

void _checkList(Household household, String listId) {
  if (!shoppingListIds(household).contains(listId)) {
    throw const FormatException('Nie znaleziono tej listy zakupów.');
  }
}

String _randomSuffix() {
  return Random.secure().nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
}
