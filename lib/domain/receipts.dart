import 'dart:math';

import 'models.dart';

class ManualReceiptInput {
  const ManualReceiptInput({required this.title, this.payerId, this.now});

  final String title;
  final String? payerId;
  final DateTime? now;
}

class ManualProductItemInput {
  const ManualProductItemInput({
    this.id,
    required this.name,
    this.quantity,
    required this.totalCents,
  });

  final String? id;
  final String name;
  final String? quantity;
  final int totalCents;
}

class ProductItemUpdate {
  const ProductItemUpdate({
    required this.name,
    required this.quantity,
    required this.totalCents,
  });

  final String name;
  final String quantity;
  final int totalCents;
}

Receipt createManualReceipt(List<Person> members, ManualReceiptInput input) {
  final now = input.now ?? DateTime.now();
  final title = input.title.trim().isEmpty
      ? 'Rachunek ręczny'
      : input.title.trim();

  return Receipt(
    id: 'manual-${now.millisecondsSinceEpoch}-${_randomSuffix()}',
    title: title,
    storeName: title,
    boughtAt: now.toIso8601String(),
    importedAt: now.toIso8601String(),
    payerId:
        input.payerId ??
        (members.isNotEmpty ? members.first.id : defaultMembers.first.id),
    items: const [],
    assignments: const {},
    grossCents: 0,
    depositCents: 0,
    depositReturnCents: 0,
    discountCents: 0,
  );
}

ReceiptItem createManualProductItem(ManualProductItemInput input) {
  return ReceiptItem(
    id:
        input.id ??
        'manual-item-${DateTime.now().millisecondsSinceEpoch}-${_randomSuffix()}',
    name: input.name.trim().isEmpty ? 'Pozycja' : input.name.trim(),
    quantity: input.quantity?.trim().isEmpty ?? true
        ? '1'
        : input.quantity!.trim(),
    totalCents: input.totalCents,
    kind: ReceiptItemKind.product,
  );
}

Receipt addReceiptItem(
  Receipt receipt,
  ReceiptItem item, [
  ItemAssignment? assignment,
]) {
  return recalculateReceiptAmounts(
    receipt.copyWith(
      items: [...receipt.items, item],
      assignments: {
        ...receipt.assignments,
        item.id: assignment ?? createAssignment(item.id),
      },
    ),
  );
}

Receipt updateReceiptItem(
  Receipt receipt,
  String itemId,
  ProductItemUpdate update,
) {
  if (!receipt.items.any((item) => item.id == itemId)) {
    throw const FormatException('Ta pozycja zostala juz usunieta.');
  }
  return recalculateReceiptAmounts(
    receipt.copyWith(
      items: receipt.items.map((item) {
        if (item.id != itemId || item.kind != ReceiptItemKind.product) {
          return item;
        }

        return item.copyWith(
          name: update.name.trim().isEmpty ? item.name : update.name.trim(),
          quantity: update.quantity.trim().isEmpty
              ? '1'
              : update.quantity.trim(),
          totalCents: update.totalCents,
        );
      }).toList(),
    ),
  );
}

Receipt removeReceiptItem(Receipt receipt, String itemId) {
  final assignments = {...receipt.assignments}..remove(itemId);

  return recalculateReceiptAmounts(
    receipt.copyWith(
      items: receipt.items.where((item) => item.id != itemId).toList(),
      assignments: assignments,
    ),
  );
}

Receipt recalculateReceiptAmounts(Receipt receipt) {
  final productCents = receipt.items
      .where((item) => item.kind == ReceiptItemKind.product)
      .fold(0, (sum, item) => sum + item.totalCents);
  final returnedDepositCents = receipt.items
      .where((item) => item.kind == ReceiptItemKind.depositReturn)
      .fold(0, (sum, item) => sum + item.totalCents);

  return receipt.copyWith(
    grossCents: productCents,
    depositReturnCents: returnedDepositCents.abs(),
  );
}

String _randomSuffix() {
  return Random().nextInt(0xFFFFFF).toRadixString(36).padLeft(5, '0');
}
