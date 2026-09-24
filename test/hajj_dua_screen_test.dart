import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/hajj_dua/data/hajj_dua_repository.dart';
import 'package:hajicare/features/hajj_dua/models/hajj_dua_category.dart';
import 'package:hajicare/features/hajj_dua/presentation/hajj_dua_typography.dart';
import 'package:hajicare/features/hajj_dua/presentation/screens/hajj_dua_category_screen.dart';
import 'package:hajicare/features/hajj_dua/presentation/screens/hajj_dua_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repository = HajjDuaRepository();

  tearDown(Get.reset);

  Widget testApp({
    Widget home = const HajjDuaScreen(),
    Locale locale = const Locale('id'),
  }) {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      locale: locale,
      fallbackLocale: AppTranslations.fallbackLocale,
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

  testWidgets('shows only categories with usable content and opens one', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pump();

    expect(find.byKey(const Key('hajj_dua_screen')), findsOneWidget);
    expect(find.byKey(const Key('category_ihram')), findsOneWidget);
    expect(find.byKey(const Key('category_masjidAlHaram')), findsOneWidget);
    expect(find.byKey(const Key('category_tawaf')), findsOneWidget);
    expect(find.byKey(const Key('category_sai')), findsOneWidget);
    expect(find.byKey(const Key('category_general')), findsNothing);

    await tester.tap(find.byKey(const Key('category_ihram')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('category_screen_ihram')), findsOneWidget);
    expect(find.text('Bacaan Talbiyah'), findsOneWidget);
  });

  testWidgets('renders Arabic, transliteration, meaning, and offline fonts', (
    tester,
  ) async {
    final category = repository.categoryFor(HajjDuaStage.ihram)!;
    await tester.pumpWidget(
      testApp(
        home: HajjDuaCategoryScreen(category: category, repository: repository),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Bacaan Talbiyah'));
    await tester.pumpAndSettle();

    final arabicSection = find.byKey(const Key('arabic_talbiyah_existing'));
    final arabicText = tester.widget<SelectableText>(
      find.descendant(of: arabicSection, matching: find.byType(SelectableText)),
    );
    final arabicDirection = tester.widget<Directionality>(
      find.descendant(of: arabicSection, matching: find.byType(Directionality)),
    );

    expect(arabicText.style?.fontFamily, 'NotoNaskhArabic');
    expect(arabicDirection.textDirection, TextDirection.rtl);
    expect(
      find.byKey(const Key('transliteration_talbiyah_existing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('translation_talbiyah_existing')),
      findsOneWidget,
    );

    final title = tester.widget<Text>(find.text('Bacaan Talbiyah'));
    expect(title.style?.fontFamily, HajjDuaTypography.headingFontFamily);
    final meaningLabel = tester.widget<Text>(find.text('ARTI'));
    expect(meaningLabel.style?.fontFamily, HajjDuaTypography.bodyFontFamily);
  });

  testWidgets(
    'search supports title, transliteration, meaning, and empty state',
    (tester) async {
      await tester.pumpWidget(testApp());
      await tester.pump();

      final searchField = find.byKey(const Key('hajj_dua_search_field'));

      await tester.enterText(searchField, 'talbiyah');
      await tester.pump();
      expect(
        find.byKey(const Key('search_dua_talbiyah_existing')),
        findsOneWidget,
      );

      await tester.enterText(searchField, 'labbaik');
      await tester.pump();
      expect(
        find.byKey(const Key('search_dua_talbiyah_existing')),
        findsOneWidget,
      );

      await tester.enterText(searchField, 'kebaikan di dunia');
      await tester.pump();
      expect(
        find.byKey(const Key('search_dua_rukun_yamani_existing')),
        findsOneWidget,
      );

      await tester.enterText(searchField, 'hasil-yang-tidak-ada');
      await tester.pump();
      expect(find.byKey(const Key('hajj_dua_empty_search')), findsOneWidget);
    },
  );

  testWidgets('runtime language switching updates all visible UI text', (
    tester,
  ) async {
    await tester.pumpWidget(testApp());
    await tester.pump();

    expect(find.text('Doa & Dzikir Ibadah Haji'), findsWidgets);
    expect(find.text('Tahapan Ibadah'), findsOneWidget);

    Get.updateLocale(const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Hajj Dua & Dhikr'), findsOneWidget);
    expect(find.text('Hajj Stages'), findsOneWidget);
    expect(find.text('Ihram & Talbiyah'), findsOneWidget);
    expect(
      find.text('Choose a stage to open its reading guide.'),
      findsOneWidget,
    );
  });

  testWidgets('all supported locales render without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in AppTranslations.supportedLocales) {
      await tester.pumpWidget(
        KeyedSubtree(
          key: ValueKey(locale.languageCode),
          child: testApp(locale: locale),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('hajj_dua_screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('copy preserves Arabic, transliteration, and meaning', (
    tester,
  ) async {
    String? copiedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    final category = repository.categoryFor(HajjDuaStage.ihram)!;
    await tester.pumpWidget(
      testApp(
        home: HajjDuaCategoryScreen(category: category, repository: repository),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Bacaan Talbiyah'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salin bacaan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salin bacaan'));
    await tester.pump();

    expect(copiedText, contains('لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ'));
    expect(copiedText, contains('Labbaikallaahumma labbaik'));
    expect(copiedText, contains('Aku penuhi panggilan-Mu'));
  });

  testWidgets('every category model renders safely when opened directly', (
    tester,
  ) async {
    for (final category in repository.getCategories()) {
      await tester.pumpWidget(
        testApp(
          home: HajjDuaCategoryScreen(
            category: category,
            repository: repository,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(Key('category_screen_${category.stage.name}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('small phone, tablet, and large text layouts do not overflow', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(1024, 768)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: const TextScaler.linear(1.8),
          ),
          child: testApp(),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('hajj_dua_screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Tawaf screen displays 1-7 circuit switcher and fiqh disclaimer', (
    tester,
  ) async {
    final category = repository.categoryFor(HajjDuaStage.tawaf)!;
    await tester.pumpWidget(
      testApp(
        home: HajjDuaCategoryScreen(category: category, repository: repository),
      ),
    );
    await tester.pump();

    expect(find.text('Panduan Putaran Thawaf (1 - 7)'), findsOneWidget);
    expect(find.text('Putaran 1'), findsOneWidget);
    expect(find.text('Putaran 7'), findsOneWidget);
    expect(
      find.text(
        'Pada bagian ini tidak ada doa khusus yang diwajibkan. Jamaah dapat berdoa dan berdzikir sesuai kebutuhan.',
      ),
      findsOneWidget,
    );

    // Switch circuit
    await tester.tap(find.text('Putaran 4'));
    await tester.pump();
    expect(find.text('Ketentuan Doa Putaran ke-4'), findsOneWidget);
  });

  testWidgets('Sai screen displays 1-7 lap tracker with route descriptions', (
    tester,
  ) async {
    final category = repository.categoryFor(HajjDuaStage.sai)!;
    await tester.pumpWidget(
      testApp(
        home: HajjDuaCategoryScreen(category: category, repository: repository),
      ),
    );
    await tester.pump();

    expect(find.text('Perjalanan Sa\'i (1 - 7)'), findsOneWidget);
    expect(find.text('Trip 1/7'), findsOneWidget);
    expect(find.text('Trip 7/7'), findsOneWidget);
    expect(
      find.text('Perjalanan 1 dari 7: Bukit Shafa → Bukit Marwah'),
      findsOneWidget,
    );

    // Switch lap
    await tester.tap(find.text('Trip 2/7'));
    await tester.pump();
    expect(
      find.text('Perjalanan 2 dari 7: Bukit Marwah → Bukit Shafa'),
      findsOneWidget,
    );
  });

  testWidgets('Dua card displays "Kapan dibaca?" context and audio unavailable state', (
    tester,
  ) async {
    final category = repository.categoryFor(HajjDuaStage.zamzam)!;
    await tester.pumpWidget(
      testApp(
        home: HajjDuaCategoryScreen(category: category, repository: repository),
      ),
    );
    await tester.pump();

    // Expand the dua card
    await tester.tap(find.text('Doa Minum Air Zamzam'));
    await tester.pumpAndSettle();

    expect(find.text('Kapan dibaca?'), findsOneWidget);
    expect(
      find.text(
        'Dibaca ketika hendak meminum air Zamzam menghadap kiblat dengan tangan kanan dan membaca bismillah.',
      ),
      findsOneWidget,
    );
    expect(find.text('Audio belum tersedia'), findsOneWidget);
    expect(find.text('Kementerian Agama Republik Indonesia'), findsOneWidget);
  });
}

