import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/dashboard/bindings/dashboard_binding.dart';
import 'package:hajicare/features/dashboard/screens/dashboard_jamaah_screen.dart';
import 'package:hajicare/features/dashboard/screens/dashboard_pendamping_screen.dart';
import 'package:hajicare/features/room/widgets/active_room_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildApp(Widget home) {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
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
      home: home,
    );
  }

  testWidgets(
    'DashboardPendampingScreen renders without crash when room is newly created',
    (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      final hajiCtrl = Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      // Set role to pendamping
      await hajiCtrl.applyUserData(
        roleStr: 'pendamping',
        roomId: 'new_room_01',
      );
      hajiCtrl.activeRoom.value = RoomModel(
        id: 'new_room_01',
        name: 'Rombongan Baru',
        code: 'ABC123',
        createdBy: 'test_pendamping_uid',
        createdAt: DateTime.now(),
        memberCount: 1,
        safeRadius: 500,
      );
      // Members still empty / syncing
      hajiCtrl.activeRoomMembers.clear();
      hajiCtrl.jamaahList.clear();

      await tester.pumpWidget(buildApp(const DashboardPendampingScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DashboardPendampingScreen), findsOneWidget);
    },
  );

  testWidgets(
    'DashboardJamaahScreen renders without crash when room is newly joined',
    (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      final hajiCtrl = Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      // Set role to jamaah
      await hajiCtrl.applyUserData(roleStr: 'jamaah', roomId: 'new_room_01');
      hajiCtrl.activeRoom.value = RoomModel(
        id: 'new_room_01',
        name: 'Rombongan Baru',
        code: 'ABC123',
        createdBy: 'pendamping_uid',
        createdAt: DateTime.now(),
        memberCount: 1,
        safeRadius: 500,
      );
      hajiCtrl.activeRoomMembers.clear();
      hajiCtrl.jamaahList.clear();

      await tester.pumpWidget(buildApp(const DashboardJamaahScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(DashboardJamaahScreen), findsOneWidget);
    },
  );

  testWidgets(
    'ActiveRoomCard renders ActiveRoomSkeletonCard when roomId is set but activeRoom.value is null (syncing)',
    (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      final hajiCtrl = Get.put(HajiCareController(), permanent: true);

      await hajiCtrl.applyUserData(
        roleStr: 'pendamping',
        roomId: 'syncing_room_id',
      );
      // Simulate room document not arrived yet from Firestore
      hajiCtrl.activeRoom.value = null;

      await tester.pumpWidget(
        buildApp(const Scaffold(body: ActiveRoomCard(isPendamping: true))),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ActiveRoomSkeletonCard), findsOneWidget);
    },
  );

  testWidgets('ActiveRoomCard renders unconnected state when roomId is null', (
    tester,
  ) async {
    Get.put(AppSettingsController(), permanent: true);
    final hajiCtrl = Get.put(HajiCareController(), permanent: true);

    await hajiCtrl.applyUserData(roleStr: 'jamaah', roomId: null);
    hajiCtrl.activeRoom.value = null;

    await tester.pumpWidget(
      buildApp(const Scaffold(body: ActiveRoomCard(isPendamping: false))),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ActiveRoomSkeletonCard), findsNothing);
  });

  testWidgets(
    'DashboardJamaahScreen hides Status & Peringatan when jamaah has no room',
    (tester) async {
      Get.put(AppSettingsController(), permanent: true);
      final hajiCtrl = Get.put(HajiCareController(), permanent: true);
      DashboardBinding().dependencies();

      await hajiCtrl.applyUserData(roleStr: 'jamaah', roomId: null);
      hajiCtrl.activeRoom.value = null;

      await tester.pumpWidget(buildApp(const DashboardJamaahScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      // Should NOT show "Status & Peringatan" section or false "Kondisi Terkoneksi & Aman"
      expect(find.text('Status & Peringatan'), findsNothing);
      expect(find.text('Kondisi Terkoneksi & Aman'), findsNothing);
      // Should show unconnected room state
      expect(find.text('Belum Terhubung ke Room'), findsWidgets);
      expect(find.text('Gabung Room Monitoring'), findsOneWidget);
    },
  );
}
