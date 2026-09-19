import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/utils/user_feedback_message.dart';

void main() {
  group('UserFeedbackMessage', () {
    test('mengubah gangguan jaringan menjadi petunjuk sederhana', () {
      final message = UserFeedbackMessage.from(
        Exception('SocketException: Failed host lookup'),
      );

      expect(message, contains('Periksa internet'));
      expect(message, isNot(contains('SocketException')));
    });

    test('mengubah timeout menjadi pesan yang dapat ditindaklanjuti', () {
      final message = UserFeedbackMessage.from(Exception('request timeout'));

      expect(message, contains('terlalu lama'));
      expect(message, contains('coba lagi'));
    });

    test('mengubah error gelang tanpa membocorkan detail BLE', () {
      final message = UserFeedbackMessage.from(
        Exception('BLE GATT characteristic missing on device'),
      );

      expect(message, contains('Gelang belum dapat dihubungkan'));
      expect(message, isNot(contains('GATT')));
    });

    test('memakai fallback dan tidak menampilkan exception mentah', () {
      const fallback = 'Data belum dapat disimpan. Silakan coba lagi.';
      final message = UserFeedbackMessage.from(
        StateError('internal implementation detail'),
        fallback: fallback,
      );

      expect(message, fallback);
      expect(message, isNot(contains('internal implementation detail')));
    });
  });
}
