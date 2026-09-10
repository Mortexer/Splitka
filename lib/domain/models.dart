enum ReceiptItemKind {
  product,
  depositReturn;

  static ReceiptItemKind fromJson(Object? value) {
    return value == 'depositReturn'
        ? ReceiptItemKind.depositReturn
        : ReceiptItemKind.product;
  }

  String toJson() {
    return switch (this) {
      ReceiptItemKind.product => 'product',
      ReceiptItemKind.depositReturn => 'depositReturn',
    };
  }
}

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.color,
    this.active = true,
  });

  final String id;
  final String name;
  final int color;
  final bool active;

  Person copyWith({String? id, String? name, int? color, bool? active}) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      active: active ?? this.active,
    );
  }

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      color: _colorFromJson(json['color']),
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': _colorToJson(color),
      'active': active,
    };
  }
}

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.completed,
    required this.createdAt,
  });

  final String id;
  final String name;
  final bool completed;
  final int createdAt;

  ShoppingItem copyWith({
    String? id,
    String? name,
    bool? completed,
    int? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      createdAt: _intFromJson(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
      'createdAt': createdAt,
    };
  }
}

class ReceiptItem {
  const ReceiptItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.totalCents,
    required this.kind,
    this.unitPriceCents,
    this.vatId,
  });

  final String id;
  final String name;
  final String quantity;
  final int totalCents;
  final int? unitPriceCents;
  final String? vatId;
  final ReceiptItemKind kind;

  ReceiptItem copyWith({
    String? id,
    String? name,
    String? quantity,
    int? totalCents,
    int? unitPriceCents,
    String? vatId,
    ReceiptItemKind? kind,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      totalCents: totalCents ?? this.totalCents,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      vatId: vatId ?? this.vatId,
      kind: kind ?? this.kind,
    );
  }

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '1',
      totalCents: _intFromJson(json['totalCents']),
      unitPriceCents: _nullableIntFromJson(json['unitPriceCents']),
      vatId: json['vatId'] as String?,
      kind: ReceiptItemKind.fromJson(json['kind']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'totalCents': totalCents,
      if (unitPriceCents != null) 'unitPriceCents': unitPriceCents,
      if (vatId != null) 'vatId': vatId,
      'kind': kind.toJson(),
    };
  }
}

class ItemAssignment {
  const ItemAssignment({
    required this.itemId,
    required this.participantIds,
    required this.skipped,
  });

  final String itemId;
  final List<String> participantIds;
  final bool skipped;

  ItemAssignment copyWith({
    String? itemId,
    List<String>? participantIds,
    bool? skipped,
  }) {
    return ItemAssignment(
      itemId: itemId ?? this.itemId,
      participantIds: participantIds ?? this.participantIds,
      skipped: skipped ?? this.skipped,
    );
  }

  factory ItemAssignment.fromJson(Map<String, dynamic> json) {
    return ItemAssignment(
      itemId: json['itemId'] as String? ?? '',
      participantIds: _stringListFromJson(json['participantIds']),
      skipped: json['skipped'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'participantIds': participantIds,
      'skipped': skipped,
    };
  }
}

class Receipt {
  const Receipt({
    required this.id,
    required this.title,
    required this.storeName,
    required this.importedAt,
    required this.payerId,
    required this.items,
    required this.assignments,
    required this.grossCents,
    required this.depositCents,
    required this.depositReturnCents,
    required this.discountCents,
    this.receiptNumber,
    this.boughtAt,
  });

  final String id;
  final String title;
  final String storeName;
  final String? receiptNumber;
  final String? boughtAt;
  final String importedAt;
  final String payerId;
  final List<ReceiptItem> items;
  final Map<String, ItemAssignment> assignments;
  final int grossCents;
  final int depositCents;
  final int depositReturnCents;
  final int discountCents;

  Receipt copyWith({
    String? id,
    String? title,
    String? storeName,
    String? receiptNumber,
    String? boughtAt,
    String? importedAt,
    String? payerId,
    List<ReceiptItem>? items,
    Map<String, ItemAssignment>? assignments,
    int? grossCents,
    int? depositCents,
    int? depositReturnCents,
    int? discountCents,
  }) {
    return Receipt(
      id: id ?? this.id,
      title: title ?? this.title,
      storeName: storeName ?? this.storeName,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      boughtAt: boughtAt ?? this.boughtAt,
      importedAt: importedAt ?? this.importedAt,
      payerId: payerId ?? this.payerId,
      items: items ?? this.items,
      assignments: assignments ?? this.assignments,
      grossCents: grossCents ?? this.grossCents,
      depositCents: depositCents ?? this.depositCents,
      depositReturnCents: depositReturnCents ?? this.depositReturnCents,
      discountCents: discountCents ?? this.discountCents,
    );
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final rawAssignments = json['assignments'] as Map<String, dynamic>? ?? {};

    return Receipt(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      receiptNumber: json['receiptNumber'] as String?,
      boughtAt: json['boughtAt'] as String?,
      importedAt: json['importedAt'] as String? ?? '',
      payerId: json['payerId'] as String? ?? '',
      items: _mapList(json['items'], ReceiptItem.fromJson),
      assignments: rawAssignments.map(
        (key, value) => MapEntry(
          key,
          ItemAssignment.fromJson(value as Map<String, dynamic>),
        ),
      ),
      grossCents: _intFromJson(json['grossCents']),
      depositCents: _intFromJson(json['depositCents']),
      depositReturnCents: _intFromJson(json['depositReturnCents']),
      discountCents: _intFromJson(json['discountCents']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'storeName': storeName,
      if (receiptNumber != null) 'receiptNumber': receiptNumber,
      if (boughtAt != null) 'boughtAt': boughtAt,
      'importedAt': importedAt,
      'payerId': payerId,
      'items': items.map((item) => item.toJson()).toList(),
      'assignments': assignments.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'grossCents': grossCents,
      'depositCents': depositCents,
      'depositReturnCents': depositReturnCents,
      'discountCents': discountCents,
    };
  }
}

class Household {
  const Household({
    required this.id,
    required this.members,
    required this.receipts,
    required this.updatedAt,
    this.shoppingLists = const {},
  });

  final String id;
  final List<Person> members;
  final List<Receipt> receipts;
  final int updatedAt;
  final Map<String, List<ShoppingItem>> shoppingLists;

  List<Person> get activeMembers =>
      members.where((person) => person.active).toList(growable: false);

  Household copyWith({
    String? id,
    List<Person>? members,
    List<Receipt>? receipts,
    int? updatedAt,
    Map<String, List<ShoppingItem>>? shoppingLists,
  }) {
    return Household(
      id: id ?? this.id,
      members: members ?? this.members,
      receipts: receipts ?? this.receipts,
      updatedAt: updatedAt ?? this.updatedAt,
      shoppingLists: shoppingLists ?? this.shoppingLists,
    );
  }

  factory Household.fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    return Household(
      id: json['id'] as String? ?? fallbackId ?? defaultRoomCode,
      members: _mapList(
        json['members'],
        Person.fromJson,
      ).ifEmpty(defaultMembers),
      receipts: _mapList(json['receipts'], Receipt.fromJson),
      updatedAt: _intFromJson(
        json['updatedAt'],
        fallback: DateTime.now().millisecondsSinceEpoch,
      ),
      shoppingLists: _shoppingListsFromJson(json['shoppingLists']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'members': members.map((person) => person.toJson()).toList(),
      'receipts': receipts.map((receipt) => receipt.toJson()).toList(),
      'updatedAt': updatedAt,
      'shoppingLists': shoppingLists.map(
        (key, items) =>
            MapEntry(key, items.map((item) => item.toJson()).toList()),
      ),
    };
  }
}

const defaultRoomCode = 'stancja';
const maxHouseholdMembers = 20;

const defaultMembers = [
  Person(id: 'danus', name: 'Danuś', color: 0xFF45B164),
  Person(id: 'kubus', name: 'Kubuś', color: 0xFF499FE3),
  Person(id: 'damian', name: 'Damian', color: 0xFFF59740),
];

Household createDefaultHousehold([String id = defaultRoomCode]) {
  return Household(
    id: id,
    members: defaultMembers,
    receipts: const [],
    updatedAt: DateTime.now().millisecondsSinceEpoch,
    shoppingLists: const {},
  );
}

ItemAssignment createAssignment(
  String itemId, [
  List<String> participantIds = const [],
  bool skipped = false,
]) {
  return ItemAssignment(
    itemId: itemId,
    participantIds: participantIds,
    skipped: skipped,
  );
}

extension _ListFallback<T> on List<T> {
  List<T> ifEmpty(List<T> fallback) {
    return isEmpty ? fallback : this;
  }
}

List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) mapper) {
  if (value is! List) {
    return [];
  }

  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList();
}

List<String> _stringListFromJson(Object? value) {
  if (value is! List) {
    return [];
  }

  return value.whereType<String>().toList();
}

Map<String, List<ShoppingItem>> _shoppingListsFromJson(Object? value) {
  if (value is! Map) return {};
  return Map<String, dynamic>.from(
    value,
  ).map((key, items) => MapEntry(key, _mapList(items, ShoppingItem.fromJson)));
}

int _colorFromJson(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is String) {
    final hex = value.replaceFirst('#', '');
    final withAlpha = hex.length == 6 ? 'FF$hex' : hex;
    return int.tryParse(withAlpha, radix: 16) ?? 0xFF64D487;
  }

  return 0xFF64D487;
}

String _colorToJson(int color) {
  return '#${color.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}

int _intFromJson(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.round();
  }

  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }

  return fallback;
}

int? _nullableIntFromJson(Object? value) {
  if (value == null) {
    return null;
  }

  return _intFromJson(value);
}
