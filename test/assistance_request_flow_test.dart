import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/dashboard/models/assistance_request_model.dart';
import 'package:hajicare/features/dashboard/services/assistance_request_service.dart';
import 'package:hajicare/features/dashboard/widgets/assistance_tracking_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AssistanceRequestService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    Get.put(HajiCareController());
    service = Get.put(AssistanceRequestService());
  });

  tearDown(() {
    service.reset();
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
        child: Scaffold(body: child),
      ),
    );
  }

  group('AssistanceRequestService Unit Tests', () {
    test(
      'Scenario A Lifecycle: Submit -> Acknowledge -> On The Way -> Complete',
      () async {
        expect(service.hasActiveRequest, isFalse);

        final req = await service.submitRequest(
          roomId: 'room-101',
          roomName: 'Kloter 12',
          jamaahId: 'j-01',
          jamaahName: 'Ahmad Dahlan',
          type: AssistanceType.lostWay,
          message: 'Saya tidak tahu jalan pulang ke hotel',
          targetHotel: 'Hotel Al Madinah',
          targetRoom: '304',
          currentPosition: Position(
            longitude: 39.8262,
            latitude: 21.4225,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
        );

        expect(service.hasActiveRequest, isTrue);
        expect(req.status, AssistanceStatus.sent);
        expect(req.type, AssistanceType.lostWay);
        expect(req.targetHotel, 'Hotel Al Madinah');
        expect(req.targetRoom, '304');
        expect(req.humanLocation.isNotEmpty, isTrue);

        // Simulasi pendamping menerima
        final ackReq = service.acknowledgeRequest(
          companionUid: 'p-01',
          companionName: 'Pak Budi',
        );
        expect(ackReq, isNotNull);
        expect(ackReq!.status, AssistanceStatus.acknowledged);
        expect(ackReq.assignedCompanionName, 'Pak Budi');

        // Simulasi pendamping menuju lokasi
        final otwReq = service.dispatchCompanionToLocation(
          companionUid: 'p-01',
          companionName: 'Pak Budi',
        );
        expect(otwReq, isNotNull);
        expect(otwReq!.status, AssistanceStatus.onTheWay);
        expect(service.hasActiveRequest, isTrue);

        // Jamaah menekan "Saya sudah ditemukan"
        final completedReq = service.completeRequest();
        expect(completedReq, isNotNull);
        expect(completedReq!.status, AssistanceStatus.completed);
        expect(service.hasActiveRequest, isFalse);
        expect(service.requestHistory.length, 1);
      },
    );

    test('Scenario B: Terpisah dari rombongan', () async {
      final req = await service.submitRequest(
        roomId: 'room-101',
        jamaahId: 'j-02',
        jamaahName: 'Siti Aminah',
        type: AssistanceType.separated,
        message: 'Saya terpisah di area sai',
        targetHotel: 'Hotel Dar Al Eiman',
      );

      expect(req.type, AssistanceType.separated);
      expect(req.type.ctaLabel, 'Minta Bantuan');
      expect(service.hasActiveRequest, isTrue);
    });

    test('Scenario C: Penjemputan', () async {
      final req = await service.submitRequest(
        roomId: 'room-101',
        jamaahId: 'j-03',
        jamaahName: 'Umar',
        type: AssistanceType.pickup,
        message: 'Kaki kram butuh kursi roda dan jemput',
        targetHotel: 'Hotel Madinah',
      );

      expect(req.type, AssistanceType.pickup);
      expect(req.type.ctaLabel, 'Minta Penjemputan');
      expect(req.status, AssistanceStatus.sent);
    });

    test('Scenario D: Pesan Biasa', () async {
      final req = await service.submitRequest(
        roomId: 'room-101',
        jamaahId: 'j-04',
        jamaahName: 'Fatimah',
        type: AssistanceType.message,
        message: 'Obat saya tertinggal di lobi',
        targetHotel: 'Hotel Al Madinah',
        sendToAll: true,
      );

      expect(req.type, AssistanceType.message);
      expect(req.type.ctaLabel, 'Kirim Pesan');
      expect(req.sendToAll, isTrue);
    });
  });

  group('AssistanceTrackingSheet Widget Tests', () {
    testWidgets('menampilkan timeline status lifecycle dan tujuan hotel', (
      tester,
    ) async {
      final req = await service.submitRequest(
        roomId: 'room-101',
        jamaahId: 'j-01',
        jamaahName: 'Ahmad',
        type: AssistanceType.lostWay,
        message: 'Saya tidak tahu jalan pulang',
        targetHotel: 'Hotel Al Madinah',
        targetRoom: '304',
        customHumanLocation: '350 m dari Hotel Al Madinah',
      );

      await tester.pumpWidget(
        wrapWidget(AssistanceTrackingSheet(request: req)),
      );
      await tester.pumpAndSettle();

      // Memastikan header & info inti tampil
      expect(find.text('Permintaan Bantuan Terkirim'), findsOneWidget);
      expect(
        find.text('Saya tidak tahu jalan pulang'),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('350 m dari Hotel Al Madinah'), findsOneWidget);
      expect(find.text('Hotel Al Madinah • 304'), findsOneWidget);

      // Memastikan tombol "Saya Sudah Ditemukan" tersedia
      expect(find.text('Ya, Saya Sudah Ditemukan'), findsOneWidget);

      // Memastikan timeline status tampil
      expect(find.text('Permintaan terkirim'), findsOneWidget);
      expect(find.text('Diterima pendamping'), findsOneWidget);
      expect(find.text('Pendamping menuju lokasi'), findsOneWidget);
      expect(find.text('Bantuan selesai'), findsOneWidget);

      // Menguji aksi "Ya, Saya Sudah Ditemukan"
      await tester.scrollUntilVisible(
        find.text('Ya, Saya Sudah Ditemukan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ya, Saya Sudah Ditemukan'));
      await tester.pumpAndSettle();

      expect(service.hasActiveRequest, isFalse);
    });
  });
}
