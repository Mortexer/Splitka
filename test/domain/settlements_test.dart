import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/domain/settlements.dart';

void main() {
  group('calculateSettlement', () {
    test('settles one payer and ignores unassigned items', () {
      final household = Household(
        id: 'stancja',
        members: defaultMembers,
        updatedAt: 1,
        receipts: [
          Receipt(
            id: 'receipt-1',
            title: 'Biedronka',
            storeName: 'Biedronka',
            importedAt: '2026-09-09T00:00:00.000Z',
            payerId: 'danus',
            grossCents: 1200,
            depositCents: 0,
            depositReturnCents: 300,
            discountCents: 0,
            items: [
              const ReceiptItem(
                id: 'bread',
                name: 'Chleb',
                quantity: '1',
                totalCents: 900,
                kind: ReceiptItemKind.product,
              ),
              const ReceiptItem(
                id: 'snack',
                name: 'Snack',
                quantity: '1',
                totalCents: 300,
                kind: ReceiptItemKind.product,
              ),
              const ReceiptItem(
                id: 'return',
                name: 'Zwrot opakowań',
                quantity: '1',
                totalCents: -300,
                kind: ReceiptItemKind.depositReturn,
              ),
            ],
            assignments: {
              'bread': createAssignment('bread', ['danus', 'kubus', 'damian']),
              'snack': createAssignment('snack'),
              'return': createAssignment('return', [
                'danus',
                'kubus',
                'damian',
              ]),
            },
          ),
        ],
      );

      final settlement = calculateSettlement(household);

      expect(settlement.includedCents, 600);
      expect(settlement.unassignedCount, 1);
      expect(settlement.transfers.map((transfer) => transfer.amountCents), [
        200,
        200,
      ]);
      expect(settlement.transfers.map((transfer) => transfer.fromPersonId), [
        'kubus',
        'damian',
      ]);
      expect(settlement.transfers.map((transfer) => transfer.toPersonId), [
        'danus',
        'danus',
      ]);
    });
  });
}
