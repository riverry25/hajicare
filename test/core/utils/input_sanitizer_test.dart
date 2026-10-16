import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer Security & Boundary Tests', () {
    test('sanitizeText removes null bytes and control characters', () {
      const malicious = 'Test\x00Name\x08With\x1FControl';
      final cleaned = InputSanitizer.sanitizeText(malicious);
      expect(cleaned, equals('TestNameWithControl'));
    });

    test('sanitizeText strips HTML and script tags to prevent XSS', () {
      const xssPayload =
          '<script>alert("XSS")</script>Halo <b>Jamaah</b><img src=x onerror=alert(1)>';
      final cleaned = InputSanitizer.sanitizeText(xssPayload);
      expect(cleaned, equals('alert("XSS")Halo Jamaah'));
      expect(cleaned.contains('<script>'), isFalse);
      expect(cleaned.contains('<img'), isFalse);
    });

    test('sanitizeText clamps string length to prevent DoS', () {
      final longString = 'A' * 300;
      final clamped = InputSanitizer.sanitizeText(longString, maxLength: 50);
      expect(clamped.length, equals(50));
    });

    test('isValidEmail validates according to standards', () {
      expect(InputSanitizer.isValidEmail('ferdiahyana123@gmail.com'), isTrue);
      expect(InputSanitizer.isValidEmail('user.name+tag@domain.co.id'), isTrue);
      expect(InputSanitizer.isValidEmail('invalid-email'), isFalse);
      expect(InputSanitizer.isValidEmail('test@'), isFalse);
      expect(InputSanitizer.isValidEmail('@domain.com'), isFalse);
      expect(InputSanitizer.isValidEmail(''), isFalse);
      expect(InputSanitizer.isValidEmail(null), isFalse);
    });

    test('isValidPassword enforces minimum length', () {
      expect(InputSanitizer.isValidPassword('123456'), isTrue);
      expect(InputSanitizer.isValidPassword('12345'), isFalse);
      expect(InputSanitizer.isValidPassword(''), isFalse);
      expect(InputSanitizer.isValidPassword(null), isFalse);
    });

    test('isValidRoomCode validates 4-12 alphanumeric uppercase codes', () {
      expect(InputSanitizer.isValidRoomCode('ABCD'), isTrue);
      expect(InputSanitizer.isValidRoomCode('ABCDEF123456'), isTrue);
      expect(InputSanitizer.isValidRoomCode('ABC'), isFalse); // < 4
      expect(InputSanitizer.isValidRoomCode('ABCDEF1234567'), isFalse); // > 12
      expect(
        InputSanitizer.isValidRoomCode('ABC-DEF'),
        isFalse,
      ); // Special char
      expect(InputSanitizer.isValidRoomCode(''), isFalse);
      expect(InputSanitizer.isValidRoomCode(null), isFalse);
    });

    test('isValidNik validates 8-20 numeric digits', () {
      expect(InputSanitizer.isValidNik('3201012345670001'), isTrue);
      expect(InputSanitizer.isValidNik('1234567'), isFalse); // Too short
      expect(
        InputSanitizer.isValidNik('320101234567000199999'),
        isFalse,
      ); // Too long
      expect(
        InputSanitizer.isValidNik('320101234567ABCD'),
        isFalse,
      ); // Non-numeric
      expect(InputSanitizer.isValidNik(null), isFalse);
    });
  });
}
