import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_breakpoints.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/core/widgets/bottom_nav_bar.dart';
import 'package:hajicare/features/auth/bindings/login_binding.dart';
import 'package:hajicare/features/auth/screens/login_screen.dart';
import 'package:hajicare/features/notification/controllers/notification_controller.dart';
import 'package:hajicare/features/notification/screens/notification_screen.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:hajicare/features/prayer/screens/prayer_times_screen.dart';
import 'package:hajicare/features/profile/bindings/profile_binding.dart';
import 'package:hajicare/features/profile/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestHost(Widget child, {Size size = const Size(390, 844)}) {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      locale: const Locale('id', 'ID'),
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
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('Multi-Device Responsive Breakpoint Unit Tests', () {
    test(
      '1. AppBreakpoints classifies compact, medium, and expanded sizes correctly',
      () {
        expect(AppBreakpoints.of(390), WindowSize.compact);
        expect(AppBreakpoints.of(599), WindowSize.compact);
        expect(AppBreakpoints.of(600), WindowSize.medium);
        expect(AppBreakpoints.of(839), WindowSize.medium);
        expect(AppBreakpoints.of(840), WindowSize.expanded);
        expect(AppBreakpoints.of(1280), WindowSize.expanded);
      },
    );

    test('2. AppBreakpoints semantic max width constants are valid', () {
      expect(AppBreakpoints.maxFormWidth, 520.0);
      expect(AppBreakpoints.maxSheetWidth, 560.0);
      expect(AppBreakpoints.maxNavDockWidth, 580.0);
      expect(AppBreakpoints.maxTabletContentWidth, 840.0);
    });
  });

  group('Multi-Device Screen Layout & Overflow Tests', () {
    testWidgets(
      '3. HajiCareBottomNavBar clamps to maxNavDockWidth on BlueStacks landscape (1280x720)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildTestHost(
            Scaffold(
              bottomNavigationBar: HajiCareBottomNavBar(
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
            size: const Size(1280, 720),
          ),
        );
        await tester.pump();

        final navBarFinder = find.byType(HajiCareBottomNavBar);
        expect(navBarFinder, findsOneWidget);
        expect(tester.takeException(), isNull);

        final renderBox = tester.renderObject(navBarFinder) as RenderBox;
        expect(renderBox.size.width, 1280.0);

        // The inner ConstrainedBox inside HajiCareBottomNavBar clamps to maxNavDockWidth (580)
        final constrainedBoxFinder = find.descendant(
          of: navBarFinder,
          matching: find.byType(ConstrainedBox),
        );
        expect(constrainedBoxFinder, findsWidgets);
      },
    );

    testWidgets(
      '4. LoginScreen renders adaptively on Phone, Tablet, and BlueStacks landscape without overflow',
      (tester) async {
        LoginBinding().dependencies();

        final testSizes = [
          const Size(390, 844), // Phone
          const Size(768, 1024), // Tablet Portrait
          const Size(1280, 720), // BlueStacks Landscape
        ];

        for (final size in testSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildTestHost(const LoginScreen(), size: size),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(LoginScreen), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Failed on screen size $size',
          );
        }
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      '5. ProfileScreen renders adaptively on Tablet and BlueStacks landscape without overflow',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);
        Get.put(HajiCareController(), permanent: true);
        ProfileBinding().dependencies();

        final testSizes = [
          const Size(390, 844),
          const Size(768, 1024),
          const Size(1280, 720),
        ];

        for (final size in testSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildTestHost(
              const ProfileScreen(showBottomNav: false),
              size: size,
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(ProfileScreen), findsOneWidget);
        }
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      '6. PrayerTimesScreen renders adaptively on Tablet and BlueStacks landscape without overflow',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);
        Get.put(PrayerTimesController(), permanent: true);

        final testSizes = [
          const Size(390, 844),
          const Size(768, 1024),
          const Size(1280, 720),
        ];

        for (final size in testSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildTestHost(
              const PrayerTimesScreen(showBottomNav: false),
              size: size,
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(PrayerTimesScreen), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Failed on size $size',
          );
        }
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      '7. NotificationScreen renders adaptively on Tablet and BlueStacks landscape without overflow',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);
        Get.put(NotificationController(), permanent: true);

        final testSizes = [
          const Size(390, 844),
          const Size(768, 1024),
          const Size(1280, 720),
        ];

        for (final size in testSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildTestHost(const NotificationScreen(), size: size),
          );
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(NotificationScreen), findsOneWidget);
          expect(
            tester.takeException(),
            isNull,
            reason: 'Failed on size $size',
          );
        }
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
