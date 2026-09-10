import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/storage/firebase_store.dart';

void main() {
  test('accepts a pasted invitation with whitespace and separators', () {
    expect(
      normalizeInviteCode(' 01234567-89ABCDEF-01234567-89abcdef\n'),
      '0123456789abcdef0123456789abcdef',
    );
  });

  test('rejects room names, incomplete codes and path injection', () {
    for (final value in ['', 'stancja', 'abc123', '../households/room']) {
      expect(() => normalizeInviteCode(value), throwsFormatException);
    }
  });

  test('creates valid, distinct invitation codes', () {
    final codes = List.generate(10, (_) => createInviteCode());
    expect(codes.toSet().length, codes.length);
    expect(codes.every((code) => normalizeInviteCode(code) == code), isTrue);
  });
}
