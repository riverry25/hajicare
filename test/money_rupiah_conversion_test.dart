import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/money/services/currency_rate_service.dart';
import 'package:hajicare/features/money/services/riyal_currency_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Riyal to Rupiah Conversion & Formatting Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'formatRupiah formats whole numbers with Indonesian dot separator',
      () {
        expect(RiyalCurrencyHelper.formatRupiah(0), equals('Rp 0'));
        expect(RiyalCurrencyHelper.formatRupiah(4300), equals('Rp 4.300'));
        expect(RiyalCurrencyHelper.formatRupiah(43000), equals('Rp 43.000'));
        expect(RiyalCurrencyHelper.formatRupiah(215000), equals('Rp 215.000'));
        expect(
          RiyalCurrencyHelper.formatRupiah(2150000),
          equals('Rp 2.150.000'),
        );
      },
    );

    test(
      'rupiahToSpokenIndonesian produces accurate natural Indonesian words',
      () {
        expect(
          RiyalCurrencyHelper.rupiahToSpokenIndonesian(4300),
          equals('empat ribu tiga ratus rupiah'),
        );
        expect(
          RiyalCurrencyHelper.rupiahToSpokenIndonesian(43000),
          equals('empat puluh tiga ribu rupiah'),
        );
        expect(
          RiyalCurrencyHelper.rupiahToSpokenIndonesian(215000),
          equals('dua ratus lima belas ribu rupiah'),
        );
        expect(
          RiyalCurrencyHelper.rupiahToSpokenIndonesian(2150000),
          equals('dua juta seratus lima puluh ribu rupiah'),
        );
      },
    );

    test(
      'totalWithRupiahSpoken smoothly connects Riyal and Rupiah sentences',
      () {
        final spoken = RiyalCurrencyHelper.totalWithRupiahSpoken(10.0, 43000.0);
        expect(
          spoken,
          equals('sepuluh Riyal, setara sekitar empat puluh tiga ribu rupiah'),
        );

        final spokenLarge = RiyalCurrencyHelper.totalWithRupiahSpoken(
          500.0,
          2150000.0,
        );
        expect(
          spokenLarge,
          equals(
            'lima ratus Riyal, setara sekitar dua juta seratus lima puluh ribu rupiah',
          ),
        );
      },
    );

    test('CurrencyRateService default and custom rate management', () async {
      final service = CurrencyRateService.instance;
      await service.init();

      expect(service.currentRate, equals(CurrencyRateService.defaultRate));
      expect(
        service.convertToRupiah(10.0),
        equals(CurrencyRateService.defaultRate * 10),
      );

      // Test custom rate change
      await service.setCustomRate(4700.0);
      expect(service.currentRate, equals(4700.0));
      expect(service.convertToRupiah(10.0), equals(47000.0));

      // Reset
      await service.resetToDefault();
      expect(service.currentRate, equals(CurrencyRateService.defaultRate));
    });
  });
}
