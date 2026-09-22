import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/models/jamaah_data.dart';
import 'package:hajicare/features/profile/controllers/profile_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile NIK and Nomor Porsi Validation Tests', () {
    final nikRegex = RegExp(r'^\d{16}$');
    final porsiRegex = RegExp(r'^\d{10}$');

    test('NIK validation logic: 16 digits numeric only', () {
      // Valid inputs
      expect(nikRegex.hasMatch('3201234567890001'), isTrue);
      expect(nikRegex.hasMatch('1234567890123456'), isTrue);

      // Invalid inputs
      expect(nikRegex.hasMatch('12345'), isFalse, reason: 'Too short');
      expect(
        nikRegex.hasMatch('12345678901234567'),
        isFalse,
        reason: 'Too long (17 digits)',
      );
      expect(
        nikRegex.hasMatch('320123456789000a'),
        isFalse,
        reason: 'Contains alphabetic chars',
      );
      expect(
        nikRegex.hasMatch('32012345 6789000'),
        isFalse,
        reason: 'Contains space',
      );
      expect(
        nikRegex.hasMatch('-32012345678900'),
        isFalse,
        reason: 'Contains hyphen',
      );
    });

    test('Nomor Porsi validation logic: 10 digits numeric only', () {
      // Valid inputs
      expect(porsiRegex.hasMatch('1001234567'), isTrue);
      expect(porsiRegex.hasMatch('1234567890'), isTrue);

      // Invalid inputs
      expect(
        porsiRegex.hasMatch('12345'),
        isFalse,
        reason: 'Too short (5 digits)',
      );
      expect(
        porsiRegex.hasMatch('12345678901'),
        isFalse,
        reason: 'Too long (11 digits)',
      );
      expect(
        porsiRegex.hasMatch('100123456A'),
        isFalse,
        reason: 'Contains alphabetic chars',
      );
      expect(
        porsiRegex.hasMatch('100123 456'),
        isFalse,
        reason: 'Contains space',
      );
    });
  });

  group('JamaahData Model NIK & Nomor Porsi Compatibility Tests', () {
    test('JamaahData supports nik field and handles null gracefully', () {
      final jamaah = JamaahData(
        id: 'user_123',
        name: 'Apisudin',
        shortLabel: 'Apisudin',
        distance: 15.0,
        nik: '3201234567890001',
        porsi: '1001234567',
      );

      expect(jamaah.nik, equals('3201234567890001'));
      expect(jamaah.porsi, equals('1001234567'));

      final firestoreMap = jamaah.toFirestore();
      expect(firestoreMap['nik'], equals('3201234567890001'));
      expect(firestoreMap['porsi'], equals('1001234567'));
      expect(firestoreMap['nomorPorsi'], equals('1001234567'));
    });

    test(
      'JamaahData works seamlessly when nik and porsi are null or absent',
      () {
        final jamaahOldUser = JamaahData(
          id: 'user_old',
          name: 'Jamaah Lama',
          shortLabel: 'Jamaah',
          distance: 0.0,
        );

        expect(jamaahOldUser.nik, isNull);
        expect(jamaahOldUser.porsi, isNull);

        final firestoreMap = jamaahOldUser.toFirestore();
        expect(firestoreMap.containsKey('nik'), isFalse);
        expect(firestoreMap.containsKey('porsi'), isFalse);
      },
    );
  });

  group('ProfileController NIK & Nomor Porsi State Tests', () {
    test(
      'ProfileController initializes nik and nomorPorsi as empty string and hasMedicalData reacts',
      () {
        final controller = ProfileController();

        expect(controller.nik.value, isEmpty);
        expect(controller.nomorPorsi.value, isEmpty);
        expect(controller.hasMedicalData, isFalse);

        // Filling only NIK should make hasMedicalData true
        controller.nik.value = '3201234567890001';
        expect(controller.hasMedicalData, isTrue);

        controller.nik.value = '';
        expect(controller.hasMedicalData, isFalse);

        // Filling only nomorPorsi should make hasMedicalData true
        controller.nomorPorsi.value = '1001234567';
        expect(controller.hasMedicalData, isTrue);

        controller.dispose();
      },
    );
  });
}
