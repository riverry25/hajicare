import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/routes/app_routes.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/constants/app_constants.dart';
import 'package:hajicare/features/profile/controllers/help_center_controller.dart';
import 'package:hajicare/features/profile/screens/about_screen.dart';
import 'package:hajicare/features/profile/screens/help_center_screen.dart';
import 'package:hajicare/features/profile/screens/legal_document_screen.dart';
import 'package:hajicare/features/profile/services/profile_support_service.dart';
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

    test('category selection resets search and can be cleared', () {
      final controller = HelpCenterController();
      controller.searchTextController.text = 'peta';
      controller.updateSearch('peta');

      controller.selectCategory('features');
      expect(controller.searchQuery.value, isEmpty);
      expect(controller.searchTextController.text, isEmpty);
      expect(controller.selectedCategory.value, 'features');

      controller.clearCategory();
      expect(controller.selectedCategory.value, isNull);
    });
  });

  group('ProfileSupportService Tests', () {
    test('builds a readable problem report email', () async {
      Uri? launchedUri;
      final service = ProfileSupportService(
        launcher: (uri) async {
          launchedUri = uri;
          return true;
        },
      );

      final opened = await service.openEmail(
        reportProblem: true,
        platformLabel: 'Android',
      );

      expect(opened, isTrue);
      expect(launchedUri?.scheme, 'mailto');
      expect(launchedUri?.path, AppConstants.supportEmail);
      expect(
        launchedUri?.queryParameters['subject'],
        'Laporan Masalah HajiCare',
      );
      expect(
        launchedUri?.queryParameters['body'],
        contains('Versi aplikasi: ${AppConstants.appVersion}'),
      );
    });

    test('does not expose placeholder WhatsApp number', () {
      final service = ProfileSupportService();

      expect(service.hasSupportWhatsApp, isFalse);
      expect(service.whatsAppUri, isNull);
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
    Widget buildTestApp(Widget home, {double textScale = 1}) {
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
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
      expect(find.text('Akun & Profil'), findsOneWidget);
    });

    testWidgets('help categories filter FAQ and search can be cleared', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const HelpCenterScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Akun & Profil'));
      await tester.pumpAndSettle();
      final controller = Get.find<HelpCenterController>();
      expect(controller.selectedCategory.value, 'account');

      await tester.enterText(find.byType(TextField), 'data medis');
      await tester.pumpAndSettle();
      expect(controller.searchQuery.value, 'data medis');
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();
      expect(controller.searchTextController.text, isEmpty);
      expect(controller.searchQuery.value, isEmpty);
    });

    testWidgets('AboutScreen renders app identity and sections', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('HajiCare'), findsOneWidget);
      expect(
        find.text('Versi Aplikasi ${AppConstants.appVersion}'),
        findsOneWidget,
      );
    });

    testWidgets('privacy policy opens a real local document', (tester) async {
      await tester.pumpWidget(buildTestApp(const AboutScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Kebijakan Privasi'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Kebijakan Privasi'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      expect(find.text('Data yang digunakan'), findsOneWidget);
    });

    testWidgets('help center remains usable with large text', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const HelpCenterScreen(), textScale: 1.6),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
