import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/state/app_startup_controller.dart';
import 'package:hajicare/core/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  group('AppStartupController Tests', () {
    test('Initial onboarding state is false on fresh install', () async {
      final controller = Get.put(AppStartupController());
      final isDone = await controller.isOnboardingDone();
      expect(isDone, isFalse);
    });

    test('setOnboardingDone marks onboarding as completed persistently', () async {
      final controller = Get.put(AppStartupController());
      await controller.setOnboardingDone();
      final isDone = await controller.isOnboardingDone();
      expect(isDone, isTrue);
    });

    test('isRememberMe defaults to true and setRememberMe persists value', () async {
      final controller = Get.put(AppStartupController());
      expect(await controller.isRememberMe(), isTrue);

      await controller.setRememberMe(false);
      expect(await controller.isRememberMe(), isFalse);
    });

    test('handleSuccessfulLogin sets onboarding_done and rememberMe', () async {
      final controller = Get.put(AppStartupController());
      await controller.handleSuccessfulLogin(rememberMe: true);

      expect(await controller.isOnboardingDone(), isTrue);
      expect(await controller.isRememberMe(), isTrue);
      expect(controller.startupState.value, equals(StartupState.authenticated));
    });

    test('determineInitialRoute returns onboarding when onboarding_done is false', () async {
      final controller = Get.put(AppStartupController());
      final route = await controller.determineInitialRoute();
      expect(route, equals(AppRoutes.onboarding));
    });

    test('determineInitialRoute returns login when onboarding_done is true and no user', () async {
      SharedPreferences.setMockInitialValues({
        AppStartupController.keyOnboardingDone: true,
      });

      final controller = Get.put(AppStartupController());
      final route = await controller.determineInitialRoute();
      expect(route, equals(AppRoutes.login));
    });
  });
}
