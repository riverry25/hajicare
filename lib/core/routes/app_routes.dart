import 'package:flutter/material.dart';

// Import all screens
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

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboardJamaah = '/dashboard_jamaah';
  static const String dashboardPendamping = '/dashboard_pendamping';
  static const String interactiveMap = '/interactive_map';
  static const String modalSos = '/modal_sos';
  static const String distanceAlert = '/distance_alert';
  static const String prayerTimes = '/prayer_times';
  static const String moneyRecognition = '/money_recognition';
  static const String communication = '/communication';
  static const String profile = '/profile';
  static const String notification = '/notification';

  static const String map = '/map';
  static const String sosModal = '/sos-modal';
  static const String prayer = '/prayer';
  static const String money = '/money';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        onboarding: (context) => const OnboardingScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        dashboardJamaah: (context) => const DashboardJamaahScreen(),
        dashboardPendamping: (context) => const DashboardPendampingScreen(),
        interactiveMap: (context) => const InteractiveMapScreen(),
        map: (context) => const InteractiveMapScreen(),
        modalSos: (context) => const ModalSosScreen(),
        sosModal: (context) => const ModalSosScreen(),
        distanceAlert: (context) => const DistanceAlertScreen(),
        prayerTimes: (context) => const PrayerTimesScreen(),
        prayer: (context) => const PrayerTimesScreen(),
        moneyRecognition: (context) => const MoneyRecognitionScreen(),
        money: (context) => const MoneyRecognitionScreen(),
        communication: (context) => const CommunicationScreen(),
        profile: (context) => const ProfileScreen(),
        notification: (context) => const NotificationScreen(),
      };
}
