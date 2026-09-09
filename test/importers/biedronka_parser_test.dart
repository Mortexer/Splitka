import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/importers/biedronka_parser.dart';

void main() {
  group('parseBiedronkaReceipt', () {
    test('reads final discounted totals from the signed Biedronka payload', () {
      final payload = {
        'dokument': {
          'paragon': {
            'nrParag': 153,
            'zakSprzed': '2026-09-07T17:06:41.000Z',
            'pozycja': [
              {
                'towar': {
                  'nazwa': 'SerGoudaŚwiat 500g       C',
                  'ilosc': '2',
                  'cena': 1489,
                  'brutto': 1598,
                  'idStPTU': 'C',
                  'rabat': {'opis': '1', 'wart': -1380},
                },
              },
              {
                'towar': {
                  'nazwa': 'MakaronPennePa500g       C',
                  'ilosc': '1',
                  'cena': 339,
                  'brutto': 100,
                  'idStPTU': 'C',
                  'rabat': {'opis': '1', 'wart': -239},
                },
              },
            ],
            'podsum': {'sumaBrutto': 1698, 'sumaOpust': -1619},
            'opak': {'wart': 300},
            'platnosc': [
              {'nazwa': '- zwrot opak', 'wart': 4800},
            ],
          },
        },
      };
      final token = 'header.${base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '')}.signature';
      final raw = jsonEncode({'data': token});

      final result = parseBiedronkaReceipt(raw, defaultMembers);

      expect(result.warnings, isEmpty);
      expect(result.receipt.receiptNumber, '153');
      expect(result.receipt.depositCents, 300);
      expect(result.receipt.depositReturnCents, 4800);
      expect(result.receipt.discountCents, 1619);
      expect(result.receipt.items.map((item) => item.name), [
        'SerGoudaŚwiat 500g',
        'MakaronPennePa500g',
        'Zwrot opakowań',
      ]);
      expect(result.receipt.items.map((item) => item.totalCents), [1598, 100, -4800]);
      expect(result.receipt.assignments['item-1']?.participantIds, isEmpty);
      expect(result.receipt.assignments['deposit-return']?.participantIds, ['danus', 'kubus', 'damian']);
    });
  });
}
