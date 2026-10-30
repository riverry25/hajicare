import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/theme/haji_colors.dart';
import 'package:hajicare/features/money/models/currency_code.dart';
import 'package:hajicare/features/money/services/currency_rate_service.dart';
import 'package:hajicare/features/money/widgets/exchange_rate_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hosts a button that opens the sheet and records the returned value.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  double? result;
  bool closed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('open'),
          onPressed: () async {
            final value = await showExchangeRateSheet(
              context,
              initialRate: 4750,
            );
            setState(() {
              result = value;
              closed = true;
            });
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Widget _app({required bool dark}) => MaterialApp(
  theme: ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    extensions: [dark ? HajiColors.dark : HajiColors.light],
  ),
  home: const _Host(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CurrencyRateService manual rate', () {
    test('isValidManualRate enforces the sane SAR->IDR range', () {
      expect(CurrencyRateService.isValidManualRate(null), isFalse);
      expect(CurrencyRateService.isValidManualRate(0), isFalse);
      expect(CurrencyRateService.isValidManualRate(500), isFalse);
      expect(CurrencyRateService.isValidManualRate(20000), isFalse);
      expect(CurrencyRateService.isValidManualRate(4750), isTrue);
    });

    test('setCustomRate updates rate, notifier and keeps cross-rates consistent', () async {
      final service = CurrencyRateService.instance;
      await service.setCustomRate(4800);

      expect(service.currentRate, closeTo(4800, 0.001));
      expect(service.rateNotifier.value, closeTo(4800, 0.001));
      // USD -> IDR must follow the SAR peg (3.75) * new SAR rate.
      expect(
        service.getRate(CurrencyCode.usd, CurrencyCode.idr),
        closeTo(3.75 * 4800, 0.01),
      );
      // Manual override clears the "Live API" timestamp.
      expect(service.lastApiUtcTime, isNull);
    });

    test('setCustomRate ignores out-of-range values', () async {
      final service = CurrencyRateService.instance;
      await service.setCustomRate(4700);
      await service.setCustomRate(99999);
      expect(service.currentRate, closeTo(4700, 0.001));
    });
  });

  group('ExchangeRateSheet', () {
    for (final dark in [false, true]) {
      final mode = dark ? 'dark' : 'light';

      testWidgets('[$mode] applying a preset returns the rate and closes cleanly', (
        tester,
      ) async {
        await tester.pumpWidget(_app(dark: dark));
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();

        expect(find.byType(ExchangeRateSheet), findsOneWidget);

        await tester.tap(find.text('Rp 4.800').first);
        await tester.pump();
        await tester.tap(find.byType(FilledButton));
        await tester.pumpAndSettle();

        final state = tester.state<_HostState>(find.byType(_Host));
        expect(state.closed, isTrue);
        expect(state.result, 4800);
        expect(find.byType(ExchangeRateSheet), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('[$mode] dismissing while the field is focused does not crash', (
        tester,
      ) async {
        await tester.pumpWidget(_app(dark: dark));
        await tester.tap(find.byKey(const Key('open')));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '4650');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        final state = tester.state<_HostState>(find.byType(_Host));
        expect(state.closed, isTrue);
        expect(state.result, isNull);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('invalid manual rate shows inline error and keeps sheet open', (
      tester,
    ) async {
      await tester.pumpWidget(_app(dark: true));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(ExchangeRateSheet), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration?.errorText, isNotNull);
    });

    testWidgets('dark mode uses dark surface and readable text colors', (
      tester,
    ) async {
      await tester.pumpWidget(_app(dark: true));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(ExchangeRateSheet),
              matching: find.byType(Material),
            )
            .first,
      );
      expect(material.color, HajiColors.dark.surface);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.style?.color, HajiColors.dark.textPrimary);
      expect(field.decoration?.fillColor, HajiColors.dark.surfaceSubtle);
    });
  });
}
