import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/dashboard/controllers/dashboard_controller.dart';
import 'package:hajicare/features/dashboard/models/assistance_request_model.dart';
import 'package:hajicare/features/dashboard/services/assistance_request_service.dart';
import 'package:hajicare/features/dashboard/widgets/pendamping_assistance_card.dart';
import 'package:hajicare/features/map/controllers/map_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssistanceRequestService assistanceService;
  late DashboardController dashboardCtrl;
  late MapController mapCtrl;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(HajiCareController());
    dashboardCtrl = Get.put(DashboardController());
    assistanceService = Get.put(AssistanceRequestService());
    mapCtrl = Get.put(MapController());
  });

  tearDown(() {
    assistanceService.reset();
    Get.reset();
  });

  Widget wrapWidget(Widget child, {Size size = const Size(390, 844)}) {
    return GetMaterialApp(
      locale: const Locale('id'),
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  group('PendampingAssistanceCard Widget Tests', () {
    testWidgets('renders card info with jamaah name and status', (
      tester,
    ) async {
      final req = AssistanceRequestModel(
        id: 'req-001',
        roomId: 'room-1',
        jamaahId: 'j-01',
        jamaahName: 'Jihad Ardiansyah',
        type: AssistanceType.lostWay,
        status: AssistanceStatus.sent,
        message: 'Saya terpisah dari rombongan di dekat masjid.',
        latitude: 21.4225,
        longitude: 39.8262,
        humanReadableLocation: '3.5 km dari Maktab 20',
        targetHotel: 'Maktab 20',
        targetRoom: 'KZFRCJ',
        createdAt: DateTime.now(),
      );

      assistanceService.activeRequest.value = req;

      await tester.pumpWidget(
        wrapWidget(PendampingAssistanceCard(request: req, isDark: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jihad Ardiansyah'), findsOneWidget);
      expect(find.text('3.5 km dari Maktab 20'), findsOneWidget);
      expect(find.text('Baru Masuk'), findsOneWidget);
      expect(find.text('Lihat Lokasi'), findsOneWidget);
      expect(find.text('Saya Menuju Lokasi'), findsOneWidget);
    });

    testWidgets(
      'tapping "Lihat Lokasi" switches tab to Map and focuses on coordinate',
      (tester) async {
        final req = AssistanceRequestModel(
          id: 'req-002',
          roomId: 'room-1',
          jamaahId: 'j-02',
          jamaahName: 'Ahmad Dahlan',
          type: AssistanceType.pickup,
          status: AssistanceStatus.sent,
          message: 'Kaki kram butuh penjemputan',
          latitude: 21.4225,
          longitude: 39.8262,
          humanReadableLocation: 'Dekat Masjidil Haram',
          targetHotel: 'Hotel Zamzam',
          createdAt: DateTime.now(),
        );

        assistanceService.activeRequest.value = req;
        dashboardCtrl.currentIndex.value = 0;

        await tester.pumpWidget(
          wrapWidget(PendampingAssistanceCard(request: req, isDark: false)),
        );
        await tester.pumpAndSettle();

        final lihatLokasiBtn = find.text('Lihat Lokasi');
        expect(lihatLokasiBtn, findsOneWidget);
        await tester.tap(lihatLokasiBtn);
        await tester.pumpAndSettle();

        // Verifikasi tab berpindah ke Tab 1 (Peta Interaktif)
        expect(dashboardCtrl.currentIndex.value, 1);

        // Verifikasi mapCtrl menyimpan pendingFocusCoordinate jamaah
        expect(mapCtrl.pendingFocusCoordinate, isNotNull);
        expect(mapCtrl.pendingFocusCoordinate!.latitude, 21.4225);
        expect(mapCtrl.pendingFocusCoordinate!.longitude, 39.8262);
        expect(mapCtrl.activeAssistanceRequest.value?.id, req.id);
      },
    );

    testWidgets(
      'tapping "Saya Menuju Lokasi" dispatches companion, switches to map, and updates to "Selesaikan"',
      (tester) async {
        final req = AssistanceRequestModel(
          id: 'req-003',
          roomId: 'room-1',
          jamaahId: 'j-03',
          jamaahName: 'Siti Aminah',
          type: AssistanceType.separated,
          status: AssistanceStatus.sent,
          message: 'Terpisah di area Sai',
          latitude: 21.4230,
          longitude: 39.8270,
          humanReadableLocation: 'Bukit Marwah',
          targetHotel: 'Hotel Misfalah',
          createdAt: DateTime.now(),
        );

        assistanceService.activeRequest.value = req;
        dashboardCtrl.currentIndex.value = 0;

        await tester.pumpWidget(
          wrapWidget(PendampingAssistanceCard(request: req, isDark: false)),
        );
        await tester.pumpAndSettle();

        final menujuLokasiBtn = find.text('Saya Menuju Lokasi');
        expect(menujuLokasiBtn, findsOneWidget);
        await tester.tap(menujuLokasiBtn);
        await tester.pumpAndSettle();

        // Verifikasi status diperbarui ke onTheWay
        expect(
          assistanceService.activeRequest.value?.status,
          AssistanceStatus.onTheWay,
        );

        // Verifikasi tab otomatis beralih ke peta
        expect(dashboardCtrl.currentIndex.value, 1);
        expect(mapCtrl.pendingFocusCoordinate?.latitude, 21.4230);

        // Verifikasi label tombol kini berubah ke "Selesaikan"
        expect(find.text('Selesaikan'), findsOneWidget);
        expect(find.text('Menuju Lokasi'), findsAtLeastNWidgets(1));

        // Tapping "Selesaikan" memunculkan dialog konfirmasi
        await tester.tap(find.text('Selesaikan'));
        await tester.pumpAndSettle();

        expect(find.text('Selesaikan Bantuan?'), findsOneWidget);
        expect(find.text('Ya, Selesai'), findsOneWidget);

        // Konfirmasi selesai
        await tester.tap(find.text('Ya, Selesai'));
        await tester.pumpAndSettle();

        expect(
          assistanceService.activeRequest.value?.status,
          AssistanceStatus.completed,
        );
      },
    );
  });
}
