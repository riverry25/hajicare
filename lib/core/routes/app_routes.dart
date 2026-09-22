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
import '../../features/sos/screens/sos_alert_detail_screen.dart';
import '../../features/sos/screens/sos_companion_scanning_screen.dart';
import '../../features/prayer/screens/prayer_times_screen.dart';
import '../../features/prayer/bindings/prayer_binding.dart';
import '../../features/money/screens/money_recognition_screen.dart';
import '../../features/communication/screens/communication_screen.dart';
import '../../features/communication/bindings/communication_binding.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/help_center_screen.dart';
import '../../features/profile/bindings/help_center_binding.dart';
import '../../features/profile/bindings/profile_binding.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/notification/screens/notification_screen.dart';
import '../../features/onboarding/bindings/onboarding_binding.dart';
import '../../features/room/screens/join_room_screen.dart';
import '../../features/room/screens/admin_dashboard_screen.dart';
import '../../features/room/screens/admin_room_management_screen.dart';
import '../../features/room/screens/room_detail_screen.dart';
import '../../features/room/screens/edit_room_screen.dart';
import '../../features/room/bindings/admin_room_binding.dart';
import '../../features/room/bindings/join_room_binding.dart';
import '../../features/smartband/screens/smartband_ldr_page.dart';
import '../../features/smartband/bindings/smartband_ldr_binding.dart';
import '../../features/sign_language/screens/bisindo_screen.dart';
import '../../features/sign_language/bindings/bisindo_binding.dart';
import '../../features/hajj_dua/presentation/screens/hajj_dua_screen.dart';
import 'role_and_room_guard.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String dashboardJamaah = '/dashboard_jamaah';
  static const String dashboardPendamping = '/dashboard_pendamping';
  static const String joinRoom = '/join_room';
  static const String adminDashboard = '/admin_dashboard';
  static const String adminRooms = '/admin_rooms';
  static const String roomDetail = '/room_detail';
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
  static const String bisindo = '/bisindo';
  static const String hajjDua = '/hajj_dua';
  static const String profile = '/profile';
  static const String notification = '/notification';
  static const String helpCenter = '/help';
  static const String about = '/about';
  static const String smartbandLdr = '/smartband_ldr';
  static const String editRoom = '/edit_room';
  static const String sosAlertDetail = '/sos_alert_detail';
  static const String sosScanning = '/sos_scanning';

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
    // Room Management & Join Pages
    GetPage(
      name: joinRoom,
      page: () => const JoinRoomScreen(),
      binding: JoinRoomBinding(),
      middlewares: [
        RoleAndRoomGuard(
          allowedRoles: ['pendamping', 'jamaah'],
          redirectIfHasRoom: true,
        ),
      ],
    ),
    GetPage(
      name: adminDashboard,
      page: () => const AdminDashboardScreen(),
      bindings: [DashboardBinding(), AdminRoomBinding()],
      middlewares: [
        RoleAndRoomGuard(allowedRoles: ['admin']),
      ],
    ),
    GetPage(
      name: adminRooms,
      page: () => const AdminRoomManagementScreen(),
      binding: AdminRoomBinding(),
      middlewares: [
        RoleAndRoomGuard(allowedRoles: ['admin']),
      ],
    ),
    GetPage(
      name: roomDetail,
      page: () => const RoomDetailScreen(),
      middlewares: [
        RoleAndRoomGuard(allowedRoles: ['admin', 'pendamping', 'jamaah']),
      ],
    ),
    // Role Dashboards with Active Room Protection
    GetPage(
      name: home,
      page: () => const DashboardJamaahScreen(),
      binding: DashboardBinding(),
      middlewares: [
        RoleAndRoomGuard(allowedRoles: ['jamaah'], requiresActiveRoom: false),
      ],
    ),
    GetPage(
      name: dashboardJamaah,
      page: () => const DashboardJamaahScreen(),
      binding: DashboardBinding(),
      middlewares: [
        RoleAndRoomGuard(allowedRoles: ['jamaah'], requiresActiveRoom: false),
      ],
    ),
    GetPage(
      name: dashboardPendamping,
      page: () => const DashboardPendampingScreen(),
      binding: DashboardBinding(),
      middlewares: [
        RoleAndRoomGuard(
          allowedRoles: ['pendamping'],
          requiresActiveRoom: false,
        ),
      ],
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
    GetPage(name: moneyRecognition, page: () => const MoneyRecognitionScreen()),
    GetPage(name: money, page: () => const MoneyRecognitionScreen()),
    GetPage(
      name: communication,
      page: () => const CommunicationScreen(),
      binding: CommunicationBinding(),
    ),
    GetPage(
      name: bisindo,
      page: () => const BisindoScreen(),
      binding: BisindoBinding(),
    ),
    GetPage(name: hajjDua, page: () => const HajjDuaScreen()),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
    ),
    GetPage(name: notification, page: () => const NotificationScreen()),
    GetPage(
      name: helpCenter,
      page: () => const HelpCenterScreen(),
      binding: HelpCenterBinding(),
    ),
    GetPage(name: about, page: () => const AboutScreen()),
    GetPage(
      name: smartbandLdr,
      page: () => const SmartbandLdrPage(),
      binding: SmartbandLdrBinding(),
    ),
    GetPage(
      name: editRoom,
      page: () => const EditRoomScreen(),
      middlewares: [
        RoleAndRoomGuard(allowedRoles: ['pendamping']),
      ],
    ),
    GetPage(name: sosAlertDetail, page: () => const SosAlertDetailScreen()),
    GetPage(name: sosScanning, page: () => const SosCompanionScanningScreen()),
  ];
}
