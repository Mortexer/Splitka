import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/domain/money.dart';

void main() {
  group('money helpers', () {
    test('formats grosze as Polish money', () {
      expect(formatMoney(1234), '12,34 zł');
      expect(formatMoney(-99), '-0,99 zł');
    });

    test('parses editable money input', () {
      expect(parseMoneyInput('12,34'), 1234);
      expect(parseMoneyInput('12.3'), 1230);
      expect(parseMoneyInput(' 1 234,56 '), 123456);
      expect(parseMoneyInput('abc'), isNull);
      expect(parseMoneyInput('12,345'), isNull);
    });

    test('splits remainders deterministically', () {
      expect(splitCents(100, ['danus', 'kubus', 'damian']), {
        'danus': 34,
        'kubus': 33,
        'damian': 33,
      });
    });
  });
}
