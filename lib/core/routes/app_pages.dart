import 'package:get/get.dart';
import 'app_routes.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_jamaah_screen.dart';
import '../../features/dashboard/screens/dashboard_pendamping_screen.dart';
import '../../features/map/screens/interactive_map_screen.dart';
import '../../features/sos/screens/modal_sos_screen.dart';
import '../../features/sos/screens/distance_alert_screen.dart';
import '../../features/prayer/screens/prayer_times_screen.dart';
import '../../features/money/screens/money_recognition_screen.dart';
import '../../features/communication/screens/communication_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notification/screens/notification_screen.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.dashboardJamaah,
      page: () => const DashboardJamaahScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.dashboardPendamping,
      page: () => const DashboardPendampingScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.interactiveMap,
      page: () => const InteractiveMapScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.map,
      page: () => const InteractiveMapScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.modalSos,
      page: () => const ModalSosScreen(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
    GetPage(
      name: AppRoutes.sosModal,
      page: () => const ModalSosScreen(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
    GetPage(
      name: AppRoutes.distanceAlert,
      page: () => const DistanceAlertScreen(),
      transition: Transition.downToUp,
      fullscreenDialog: true,
    ),
    GetPage(
      name: AppRoutes.prayerTimes,
      page: () => const PrayerTimesScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.prayer,
      page: () => const PrayerTimesScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.moneyRecognition,
      page: () => const MoneyRecognitionScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.money,
      page: () => const MoneyRecognitionScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.communication,
      page: () => const CommunicationScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.notification,
      page: () => const NotificationScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
