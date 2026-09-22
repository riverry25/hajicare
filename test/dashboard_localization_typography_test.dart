import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/locales/dashboard_translations.dart';
import 'package:hajicare/core/locales/en.dart';
import 'package:hajicare/core/locales/id.dart';
import 'package:hajicare/core/locales/jv.dart';
import 'package:hajicare/core/locales/su.dart';
import 'package:hajicare/features/dashboard/presentation/dashboard_typography.dart';

void main() {
  group('dashboard localization', () {
    test(
      'every dashboard dictionary contains the complete dashboard key set',
      () {
        final requiredKeys = <String>{
          ...dashboardIdTranslations.keys,
          ...adminDashboardIdTranslations.keys,
        };
        final dictionaries = <String, Map<String, String>>{
          'id': idTranslations,
          'en': enTranslations,
          'jv': jvTranslations,
          'su': suTranslations,
        };

        for (final entry in dictionaries.entries) {
          for (final key in requiredKeys) {
            expect(
              entry.value[key],
              isNotNull,
              reason: '$key is missing from ${entry.key}',
            );
            expect(entry.value[key], isNotEmpty);
          }
        }
      },
    );

    test('English dashboard copy and parameters are localized', () {
      expect(
        AppTranslations.translate('dashboard.trackOfficer', 'en'),
        'Track Companion',
      );
      expect(
        AppTranslations.translate('adminDashboard.activeRoomsCount', 'en', {
          'count': 3,
        }),
        '3 active rooms operating',
      );
      expect(
        AppTranslations.translate('dashboard.requestSentDesc', 'id', {
          'name': 'Ahmad',
        }),
        contains('Ahmad'),
      );
    });

    testWidgets('dashboard text refreshes when locale changes at runtime', (
      tester,
    ) async {
      Widget buildApp(Locale locale) => MaterialApp(
        locale: locale,
        supportedLocales: AppTranslations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FallbackMaterialLocalizationsDelegate(),
          FallbackWidgetsLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
        ],
        home: Builder(
          builder: (context) => Text(context.tr('dashboard.trackOfficer')),
        ),
      );

      await tester.pumpWidget(buildApp(const Locale('id')));
      expect(find.text('Lacak Petugas'), findsOneWidget);

      await tester.pumpWidget(buildApp(const Locale('en')));
      await tester.pump();
      expect(find.text('Track Companion'), findsOneWidget);
    });
  });

  group('dashboard typography', () {
    test('uses bundled Poppins headings and Montserrat body text', () {
      expect(DashboardTypography.titleLarge.fontFamily, 'Poppins');
      expect(DashboardTypography.labelLarge.fontFamily, 'Poppins');
      expect(DashboardTypography.bodyMedium.fontFamily, 'Montserrat');
      expect(DashboardTypography.caption.fontFamily, 'Montserrat');
    });

    test('dashboard theme maps semantic text roles consistently', () {
      final themed = DashboardTypography.applyTo(ThemeData.light());
      expect(themed.textTheme.titleLarge?.fontFamily, 'Poppins');
      expect(themed.textTheme.labelLarge?.fontFamily, 'Poppins');
      expect(themed.textTheme.bodyMedium?.fontFamily, 'Montserrat');
      expect(themed.textTheme.bodySmall?.height, greaterThanOrEqualTo(1.4));
    });
  });
}
