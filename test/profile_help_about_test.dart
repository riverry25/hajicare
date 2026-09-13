import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/routes/app_routes.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/features/profile/controllers/help_center_controller.dart';
import 'package:hajicare/features/profile/screens/about_screen.dart';
import 'package:hajicare/features/profile/screens/help_center_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(AppSettingsController(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('HelpCenterController Tests', () {
    test('search query updates and clears properly', () {
      final controller = HelpCenterController();

      expect(controller.searchQuery.value, isEmpty);

      controller.updateSearch('  PETA  ');
      expect(controller.searchQuery.value, equals('peta'));

      controller.clearSearch();
      expect(controller.searchQuery.value, isEmpty);
    });

    test('FAQ expansion allows only one open item at a time', () {
      final controller = HelpCenterController();

      expect(controller.expandedIndex.value, equals(-1));
      expect(controller.isExpanded(0), isFalse);

      // Open item 0
      controller.toggleFaq(0);
      expect(controller.expandedIndex.value, equals(0));
      expect(controller.isExpanded(0), isTrue);
      expect(controller.isExpanded(1), isFalse);

      // Open item 2 (item 0 should close)
      controller.toggleFaq(2);
      expect(controller.expandedIndex.value, equals(2));
      expect(controller.isExpanded(0), isFalse);
      expect(controller.isExpanded(2), isTrue);

      // Tap item 2 again (should close it)
      controller.toggleFaq(2);
      expect(controller.expandedIndex.value, equals(-1));
      expect(controller.isExpanded(2), isFalse);
    });
  });

  group('AppRoutes Help Center & About Routes Tests', () {
    test('AppRoutes contains helpCenter and about routes', () {
      final helpPage = AppRoutes.pages.firstWhereOrNull(
        (page) => page.name == AppRoutes.helpCenter,
      );
      expect(helpPage, isNotNull);
      expect(helpPage!.page(), isA<HelpCenterScreen>());

      final aboutPage = AppRoutes.pages.firstWhereOrNull(
        (page) => page.name == AppRoutes.about,
      );
      expect(aboutPage, isNotNull);
      expect(aboutPage!.page(), isA<AboutScreen>());
    });
  });

  group('Widget Rendering Tests for About & HelpCenter', () {
    Widget buildTestApp(Widget home) {
      return GetMaterialApp(
        locale: const Locale('id'),
        translations: AppTranslations(),
        supportedLocales: AppTranslations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FallbackMaterialLocalizationsDelegate(),
          FallbackCupertinoLocalizationsDelegate(),
          FallbackWidgetsLocalizationsDelegate(),
        ],
        home: home,
      );
    }

    testWidgets('HelpCenterScreen renders search and categories', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const HelpCenterScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(HelpCenterScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('AboutScreen renders app identity and sections', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('HajiCare'), findsOneWidget);
    });
  });
}
