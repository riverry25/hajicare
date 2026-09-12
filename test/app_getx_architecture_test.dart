import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/routes/app_routes.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/auth/bindings/login_binding.dart';
import 'package:hajicare/features/auth/bindings/register_binding.dart';
import 'package:hajicare/features/auth/controllers/login_controller.dart';
import 'package:hajicare/features/auth/controllers/register_controller.dart';
import 'package:hajicare/features/dashboard/bindings/dashboard_binding.dart';
import 'package:hajicare/features/dashboard/controllers/dashboard_controller.dart';
import 'package:hajicare/features/map/bindings/map_binding.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:hajicare/features/onboarding/bindings/onboarding_binding.dart';
import 'package:hajicare/features/onboarding/controllers/onboarding_controller.dart';
import 'package:hajicare/features/prayer/bindings/prayer_binding.dart';
import 'package:hajicare/features/prayer/controllers/prayer_times_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Get.reset();

    // Register application-level permanent controllers
    Get.put(AppSettingsController(), permanent: true);
    Get.put(HajiCareController(), permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  group('GetX Core Architecture Tests', () {
    test('AppSettingsController is a reactive GetxController', () async {
      final settings = Get.find<AppSettingsController>();
      expect(settings, isA<GetxController>());
      expect(settings.currentLocale.languageCode, equals('id'));

      await settings.setLocale(const Locale('en'));
      expect(settings.currentLocale.languageCode, equals('en'));

      await settings.setTextScale(AppTextScale.large);
      expect(settings.currentTextScale, equals(AppTextScale.large));
      expect(settings.textScaleFactor, equals(1.15));
    });

    test('HajiCareController is a reactive GetxController', () {
      final hajicare = Get.find<HajiCareController>();
      expect(hajicare, isA<GetxController>());
      expect(hajicare.role, equals(UserRole.jamaah));

      hajicare.setRole(UserRole.pendamping);
      expect(hajicare.role, equals(UserRole.pendamping));
    });
  });

  group('Onboarding Flow Tests', () {
    test('OnboardingBinding injects OnboardingController', () {
      OnboardingBinding().dependencies();
      final ctrl = Get.find<OnboardingController>();
      expect(ctrl, isNotNull);
      expect(ctrl.currentPage.value, equals(0));

      ctrl.changePage(2);
      expect(ctrl.currentPage.value, equals(2));
    });
  });

  group('Authentication Flow Tests', () {
    test(
      'LoginBinding and LoginController resolve and perform login',
      () async {
        LoginBinding().dependencies();
        final loginCtrl = Get.find<LoginController>();
        expect(loginCtrl, isNotNull);
        expect(loginCtrl.selectedRole.value, equals('jamaah'));
        expect(loginCtrl.obscurePassword.value, isTrue);

        loginCtrl.togglePasswordVisibility();
        expect(loginCtrl.obscurePassword.value, isFalse);

        loginCtrl.setRole('pendamping');
        expect(loginCtrl.selectedRole.value, equals('pendamping'));

        await loginCtrl.login();
        expect(loginCtrl.isLoading.value, isFalse);

        final hajicare = Get.find<HajiCareController>();
        expect(hajicare.role, equals(UserRole.pendamping));
      },
    );

    test(
      'RegisterBinding and RegisterController resolve and toggle visibility',
      () {
        RegisterBinding().dependencies();
        final regCtrl = Get.find<RegisterController>();
        expect(regCtrl, isNotNull);
        expect(regCtrl.obscurePassword.value, isTrue);

        regCtrl.togglePasswordVisibility();
        expect(regCtrl.obscurePassword.value, isFalse);
      },
    );
  });

  group('Dashboard and Home Compatibility Tests', () {
    test(
      'DashboardBinding injects DashboardController and PrayerTimesController',
      () {
        DashboardBinding().dependencies();
        final dashCtrl = Get.find<DashboardController>();
        expect(dashCtrl, isNotNull);
        expect(dashCtrl.currentIndex.value, equals(0));

        dashCtrl.changeTab(2);
        expect(dashCtrl.currentIndex.value, equals(2));

        // Check HomeController alias
        final homeCtrl = Get.find<HomeController>();
        expect(homeCtrl, isNotNull);
        expect(identical(dashCtrl, homeCtrl), isTrue);

        // Embedded prayer times controller is accessible
        final prayerCtrl = Get.find<PrayerTimesController>();
        expect(prayerCtrl, isNotNull);
      },
    );
  });

  group('Map Flow Tests', () {
    test('MapBinding injects MapController', () {
      MapBinding().dependencies();
      final mapCtrl = Get.find<MapController>();
      expect(mapCtrl, isNotNull);
      expect(mapCtrl.selectedFilter.value, equals(0));

      mapCtrl.selectFilter(3);
      expect(mapCtrl.selectedFilter.value, equals(3));
    });
  });

  group('Prayer Flow Tests', () {
    test(
      'PrayerBinding injects PrayerTimesController with dynamic services',
      () {
        PrayerBinding().dependencies();
        final prayerCtrl = Get.find<PrayerTimesController>();
        expect(prayerCtrl, isNotNull);
        expect(prayerCtrl.locationName, isNotNull);
        expect(prayerCtrl.timezoneName, isNotNull);
        expect(prayerCtrl.qiblaBearing, isNotNull);
      },
    );
  });

  group('AppRoutes Completeness Test', () {
    test('All registered GetPage routes have valid bindings and builders', () {
      final pages = AppRoutes.pages;
      expect(pages.isNotEmpty, isTrue);

      final routeNames = pages.map((p) => p.name).toSet();
      expect(routeNames.contains(AppRoutes.splash), isTrue);
      expect(routeNames.contains(AppRoutes.onboarding), isTrue);
      expect(routeNames.contains(AppRoutes.login), isTrue);
      expect(routeNames.contains(AppRoutes.register), isTrue);
      expect(routeNames.contains(AppRoutes.home), isTrue);
      expect(routeNames.contains(AppRoutes.dashboardJamaah), isTrue);
      expect(routeNames.contains(AppRoutes.dashboardPendamping), isTrue);
      expect(routeNames.contains(AppRoutes.prayer), isTrue);
      expect(routeNames.contains(AppRoutes.prayerTimes), isTrue);
      expect(routeNames.contains(AppRoutes.map), isTrue);
      expect(routeNames.contains(AppRoutes.interactiveMap), isTrue);
    });
  });
}
