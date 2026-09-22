import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/hajj_dua/data/hajj_dua_repository.dart';
import 'package:hajicare/features/hajj_dua/presentation/screens/hajj_dua_category_screen.dart';
import 'package:hajicare/features/hajj_dua/presentation/screens/hajj_dua_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repository = HajjDuaRepository();

  tearDown(Get.reset);

  Widget testApp(Widget home) {
    return GetMaterialApp(theme: AppTheme.lightTheme, home: home);
  }

  testWidgets('renders categories and opens a category with prayer content', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const HajjDuaScreen()));
    await tester.pump();

    expect(find.byKey(const Key('hajj_dua_screen')), findsOneWidget);
    expect(find.byKey(const Key('category_ihram')), findsOneWidget);
    expect(find.byKey(const Key('category_general')), findsOneWidget);

    await tester.tap(find.byKey(const Key('category_ihram')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('category_screen_ihram')), findsOneWidget);
    expect(find.text('Bacaan Talbiyah'), findsOneWidget);

    await tester.tap(find.text('Bacaan Talbiyah'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('arabic_talbiyah_existing')), findsOneWidget);
    expect(
      find.byKey(const Key('transliteration_talbiyah_existing')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('translation_talbiyah_existing')),
      findsOneWidget,
    );
  });

  testWidgets('local search returns prayer results and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const HajjDuaScreen()));
    await tester.pump();

    final searchField = find.byKey(const Key('hajj_dua_search_field'));
    await tester.enterText(searchField, 'talbiyah');
    await tester.pump();

    expect(
      find.byKey(const Key('search_dua_talbiyah_existing')),
      findsOneWidget,
    );

    await tester.enterText(searchField, 'hasil-yang-tidak-ada');
    await tester.pump();

    expect(find.byKey(const Key('hajj_dua_empty_search')), findsOneWidget);
  });

  testWidgets('every category screen renders without crashing', (tester) async {
    for (final category in repository.getCategories()) {
      await tester.pumpWidget(
        testApp(
          HajjDuaCategoryScreen(category: category, repository: repository),
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

  testWidgets('small phone layout does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(testApp(const HajjDuaScreen()));
    await tester.pump();

    expect(find.byKey(const Key('hajj_dua_screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
