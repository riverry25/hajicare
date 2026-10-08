import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/models/jamaah_data.dart';

void main() {
  group('JamaahData Medical & Hajj Document Fields Test', () {
    test('Correctly populates medical, contact, and identity fields', () {
      final jamaah = JamaahData(
        id: 'user_123',
        name: 'Hafisudin',
        shortLabel: 'Hafis',
        distance: 250.0,
        kloter: 'SOC-12',
        maktab: 'Maktab 10',
        bloodType: 'O',
        allergies: 'udang',
        conditions: 'Diabates',
        emergencyContact: '087827303344',
        porsi: '1111111111',
        passportNumber: 'A 123445',
        nik: '1111111111111111',
        email: 'apiw@gmail.com',
        role: 'pendamping',
        sosActive: false,
        isGpsActive: true,
      );

      expect(jamaah.id, 'user_123');
      expect(jamaah.name, 'Hafisudin');
      expect(jamaah.kloter, 'SOC-12');
      expect(jamaah.maktab, 'Maktab 10');
      expect(jamaah.bloodType, 'O');
      expect(jamaah.allergies, 'udang');
      expect(jamaah.conditions, 'Diabates');
      expect(jamaah.emergencyContact, '087827303344');
      expect(jamaah.porsi, '1111111111');
      expect(jamaah.passportNumber, 'A 123445');
      expect(jamaah.nik, '1111111111111111');
      expect(jamaah.email, 'apiw@gmail.com');
      expect(jamaah.role, 'pendamping');
      expect(jamaah.hasMedicalData, isTrue);
      expect(jamaah.hasHajjDocs, isTrue);
    });

    test('Helper getters handle empty and null data gracefully', () {
      final minimalJamaah = JamaahData(
        id: 'user_min',
        name: 'Ahmad',
        shortLabel: 'Ahmad',
        distance: 50.0,
      );

      expect(minimalJamaah.bloodType, isNull);
      expect(minimalJamaah.allergies, isNull);
      expect(minimalJamaah.conditions, isNull);
      expect(minimalJamaah.emergencyContact, isNull);
      expect(minimalJamaah.hasMedicalData, isFalse);
      expect(minimalJamaah.hasHajjDocs, isFalse);
    });

    test('hasMedicalData returns true if any medical field is present', () {
      final withBloodOnly = JamaahData(
        id: 'u1',
        name: 'User Blood',
        shortLabel: 'User',
        distance: 0,
        bloodType: 'B+',
      );
      expect(withBloodOnly.hasMedicalData, isTrue);

      final withEmergencyOnly = JamaahData(
        id: 'u2',
        name: 'User Contact',
        shortLabel: 'User',
        distance: 0,
        emergencyContact: '08123456789',
      );
      expect(withEmergencyOnly.hasMedicalData, isTrue);
    });

    test('hasHajjDocs returns true if any official document is present', () {
      final withPorsi = JamaahData(
        id: 'u3',
        name: 'User Porsi',
        shortLabel: 'User',
        distance: 0,
        porsi: '999888',
      );
      expect(withPorsi.hasHajjDocs, isTrue);

      final withPassport = JamaahData(
        id: 'u4',
        name: 'User Passport',
        shortLabel: 'User',
        distance: 0,
        passportNumber: 'B 987654',
      );
      expect(withPassport.hasHajjDocs, isTrue);

      final withNik = JamaahData(
        id: 'u5',
        name: 'User NIK',
        shortLabel: 'User',
        distance: 0,
        nik: '3201012345670001',
      );
      expect(withNik.hasHajjDocs, isTrue);
    });
  });
}
