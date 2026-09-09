import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/domain/receipts.dart';

void main() {
  group('manual receipt helpers', () {
    test('creates an empty manual receipt for a selected payer', () {
      final receipt = createManualReceipt(
        defaultMembers,
        ManualReceiptInput(
          title: 'Obiad',
          payerId: 'kubus',
          now: DateTime.utc(2026, 9, 9, 12),
        ),
      );

      expect(receipt.id, startsWith('manual-1788955200000-'));
      expect(receipt.title, 'Obiad');
      expect(receipt.storeName, 'Obiad');
      expect(receipt.payerId, 'kubus');
      expect(receipt.items, isEmpty);
      expect(receipt.assignments, isEmpty);
      expect(receipt.grossCents, 0);
    });

    test('adds, edits and removes product items with recalculated totals', () {
      final receipt = createManualReceipt(
        defaultMembers,
        ManualReceiptInput(
          title: 'Zakupy',
          payerId: 'danus',
          now: DateTime.utc(2026, 9, 9, 12),
        ),
      );
      const bread = ReceiptItem(
        id: 'bread',
        name: 'Chleb',
        quantity: '1',
        totalCents: 599,
        kind: ReceiptItemKind.product,
      );
      const cheese = ReceiptItem(
        id: 'cheese',
        name: 'Ser',
        quantity: '2',
        totalCents: 1298,
        kind: ReceiptItemKind.product,
      );

      final withItems = addReceiptItem(
        addReceiptItem(
          receipt,
          bread,
          createAssignment('bread', ['danus', 'kubus']),
        ),
        cheese,
        createAssignment('cheese', ['danus', 'kubus', 'damian']),
      );
      final edited = updateReceiptItem(
        withItems,
        'bread',
        const ProductItemUpdate(
          name: 'Chleb tostowy',
          quantity: '1',
          totalCents: 699,
        ),
      );
      final withoutCheese = removeReceiptItem(edited, 'cheese');

      expect(withItems.grossCents, 1897);
      expect(edited.items.first.name, 'Chleb tostowy');
      expect(edited.grossCents, 1997);
      expect(withoutCheese.items, hasLength(1));
      expect(withoutCheese.assignments['cheese'], isNull);
      expect(withoutCheese.grossCents, 699);
    });
  });
}
