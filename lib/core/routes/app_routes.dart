import 'package:get/get.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/bindings/login_binding.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/bindings/register_binding.dart';
import '../../features/dashboard/screens/dashboard_jamaah_screen.dart';
import '../../features/dashboard/screens/dashboard_pendamping_screen.dart';
import '../../features/dashboard/bindings/dashboard_binding.dart';
import '../../features/map/screens/interactive_map_screen.dart';
import '../../features/map/bindings/map_binding.dart';
import '../../features/sos/screens/modal_sos_screen.dart';
import '../../features/sos/screens/distance_alert_screen.dart';
import '../../features/prayer/screens/prayer_times_screen.dart';
import '../../features/prayer/bindings/prayer_binding.dart';
import '../../features/money/screens/money_recognition_screen.dart';
import '../../features/communication/screens/communication_screen.dart';
import '../../features/communication/bindings/communication_binding.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/help_center_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/notification/screens/notification_screen.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String dashboardJamaah = '/dashboard_jamaah';
  static const String dashboardPendamping = '/dashboard_pendamping';
  static const String interactiveMap = '/interactive_map';
  static const String map = '/map';
  static const String modalSos = '/modal_sos';
  static const String sosModal = '/sos-modal';
  static const String distanceAlert = '/distance_alert';
  static const String prayerTimes = '/prayer_times';
  static const String prayer = '/prayer';
  static const String moneyRecognition = '/money_recognition';
  static const String money = '/money';
  static const String communication = '/communication';
  static const String profile = '/profile';
  static const String notification = '/notification';
  static const String helpCenter = '/help';
  static const String about = '/about';

  static List<GetPage> get pages => [
        GetPage(name: splash, page: () => const SplashScreen()),
        GetPage(
          name: onboarding,
          page: () => const OnboardingScreen(),
          binding: OnboardingBinding(),
        ),
        GetPage(
          name: login,
          page: () => const LoginScreen(),
          binding: LoginBinding(),
        ),
        GetPage(
          name: register,
          page: () => const RegisterScreen(),
          binding: RegisterBinding(),
        ),
        GetPage(
          name: home,
          page: () => const DashboardJamaahScreen(),
          binding: DashboardBinding(),
        ),
        GetPage(
          name: dashboardJamaah,
          page: () => const DashboardJamaahScreen(),
          binding: DashboardBinding(),
        ),
        GetPage(
          name: dashboardPendamping,
          page: () => const DashboardPendampingScreen(),
          binding: DashboardBinding(),
        ),
        GetPage(
          name: interactiveMap,
          page: () => const InteractiveMapScreen(),
          binding: MapBinding(),
        ),
        GetPage(
          name: map,
          page: () => const InteractiveMapScreen(),
          binding: MapBinding(),
        ),
        GetPage(name: modalSos, page: () => const ModalSosScreen()),
        GetPage(name: sosModal, page: () => const ModalSosScreen()),
        GetPage(name: distanceAlert, page: () => const DistanceAlertScreen()),
        GetPage(
          name: prayerTimes,
          page: () => const PrayerTimesScreen(),
          binding: PrayerBinding(),
        ),
        GetPage(
          name: prayer,
          page: () => const PrayerTimesScreen(),
          binding: PrayerBinding(),
        ),
        GetPage(
          name: moneyRecognition,
          page: () => const MoneyRecognitionScreen(),
        ),
        GetPage(name: money, page: () => const MoneyRecognitionScreen()),
        GetPage(
          name: communication,
          page: () => const CommunicationScreen(),
          binding: CommunicationBinding(),
        ),
        GetPage(name: profile, page: () => const ProfileScreen()),
        GetPage(name: notification, page: () => const NotificationScreen()),
        GetPage(name: helpCenter, page: () => const HelpCenterScreen()),
        GetPage(name: about, page: () => const AboutScreen()),
      ];
}
