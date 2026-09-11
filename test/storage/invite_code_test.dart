import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/storage/firebase_store.dart';

void main() {
  test('accepts a four-digit invitation', () {
    expect(normalizeInviteCode(' 12-34\n'), '1234');
  });

  test('keeps accepting legacy invitations', () {
    expect(
      normalizeInviteCode(' 01234567-89ABCDEF-01234567-89abcdef\n'),
      '0123456789abcdef0123456789abcdef',
    );
  });

  test('rejects room names, wrong lengths and path injection', () {
    for (final value in ['', '123', '12345', 'stancja', '../households/room']) {
      expect(() => normalizeInviteCode(value), throwsFormatException);
    }
  });

  test('creates valid four-digit invitation codes', () {
    final codes = List.generate(10, (_) => createInviteCode());
    expect(codes.every((code) => RegExp(r'^[0-9]{4}$').hasMatch(code)), isTrue);
    expect(codes.every((code) => normalizeInviteCode(code) == code), isTrue);
  });
}
