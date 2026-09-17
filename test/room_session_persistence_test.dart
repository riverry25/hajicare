import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/state/app_startup_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/routes/app_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    Get.reset();
  });

  group('Room Session & Role Persistence Tests', () {
    test('resolveUserRoleDestination falls back to cached room & role for Jamaah when offline', () async {
      SharedPreferences.setMockInitialValues({
        AppStartupController.keyOnboardingDone: true,
        HajiCareController.keyActiveRoomId: 'room_mina_48',
        HajiCareController.keyUserRole: 'jamaah',
      });

      final controller = Get.put(AppStartupController());
      final destination = await controller.resolveUserRoleDestination('test_uid_123');

      expect(destination, equals(AppRoutes.dashboardJamaah));
    });

    test('resolveUserRoleDestination falls back to cached room & role for Pendamping when offline', () async {
      SharedPreferences.setMockInitialValues({
        AppStartupController.keyOnboardingDone: true,
        HajiCareController.keyActiveRoomId: 'room_mina_48',
        HajiCareController.keyUserRole: 'pendamping',
      });

      final controller = Get.put(AppStartupController());
      final destination = await controller.resolveUserRoleDestination('test_uid_456');

      expect(destination, equals(AppRoutes.dashboardPendamping));
    });

    test('resolveUserRoleDestination returns joinRoom when no cached room exists for Jamaah', () async {
      SharedPreferences.setMockInitialValues({
        AppStartupController.keyOnboardingDone: true,
        HajiCareController.keyUserRole: 'jamaah',
      });

      final controller = Get.put(AppStartupController());
      final destination = await controller.resolveUserRoleDestination('test_uid_789');

      expect(destination, equals(AppRoutes.joinRoom));
    });

    test('resolveUserRoleDestination returns adminDashboard for admin role in cache', () async {
      SharedPreferences.setMockInitialValues({
        AppStartupController.keyOnboardingDone: true,
        HajiCareController.keyUserRole: 'admin',
      });

      final controller = Get.put(AppStartupController());
      final destination = await controller.resolveUserRoleDestination('admin_uid');

      expect(destination, equals(AppRoutes.adminDashboard));
    });

    test('signOut clears cached room ID and user role from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppStartupController.keyOnboardingDone: true,
        HajiCareController.keyActiveRoomId: 'room_mina_48',
        HajiCareController.keyUserRole: 'jamaah',
      });

      final controller = Get.put(AppStartupController());
      await controller.signOut();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(HajiCareController.keyActiveRoomId), isNull);
      expect(prefs.getString(HajiCareController.keyUserRole), isNull);
      // Onboarding must remain true
      expect(prefs.getBool(AppStartupController.keyOnboardingDone), isTrue);
    });
  });
}
