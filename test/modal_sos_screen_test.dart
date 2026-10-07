import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/hajicare_state.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/sos/screens/modal_sos_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  Widget buildTestModalSosScreen({required UserRole role}) {
    final state = Get.put(HajiCareController(), permanent: true);
    state.setRole(role);

    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: const ModalSosScreen(),
    );
  }

  group('ModalSosScreen Responder View (Reference Design) Tests', () {
    testWidgets(
      'Renders Officer Hero Command Card, Ribbon, Wait Time, and Timeline Actions',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final state = Get.put(HajiCareController(), permanent: true);
        state.setRole(UserRole.pendamping);
        // Inject an active SOS event
        state.activeSosEvents.assignAll([
          {
            'id': 'sos-event-1',
            'userId': 'jamaah-1',
            'userName': 'Humai Latifah',
            'roomName': 'Rombongan Kloter 42',
            'status': 'active',
            'timestamp': DateTime.now().subtract(const Duration(minutes: 8)),
            'location': const GeoPoint(-21.4225, 39.8262),
          },
        ]);

        await tester.pumpWidget(
          buildTestModalSosScreen(role: UserRole.pendamping),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // 1. Verify Top Navigation Title & Subtitle
        expect(find.text('Pusat Darurat SOS'), findsOneWidget);
        expect(find.text('Pusat Respon Darurat Jamaah'), findsOneWidget);

        // 2. Verify Top Command Card
        expect(find.text('POSKO PENDAMPING'), findsOneWidget);
        expect(find.text('STATUS DARURAT JAMAAH'), findsOneWidget);

        // 3. Verify Ribbon Bookmark "SOS"
        expect(find.text('SOS'), findsOneWidget);

        // 4. Verify Wait time typography header
        expect(find.text('WAKTU TUNGGU'), findsOneWidget);

        // 5. Verify Timeline content
        expect(find.text('Humai Latifah'), findsOneWidget);
        expect(find.text('Rombongan Kloter 42'), findsOneWidget);
        expect(find.textContaining('Lokasi GPS terdeteksi'), findsOneWidget);

        // 6. Verify Action Buttons
        expect(find.text('Lihat Detail'), findsOneWidget);
        expect(find.text('Selesai'), findsOneWidget);

        // 7. Verify Hotline Darurat Footer
        expect(find.text('Hotline Darurat Haji Indonesia'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders Safe Condition Empty State when no active SOS exists',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final state = Get.put(HajiCareController(), permanent: true);
        state.setRole(UserRole.pendamping);
        state.activeSosEvents.clear();
        state.jamaahList.clear();

        await tester.pumpWidget(
          buildTestModalSosScreen(role: UserRole.pendamping),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Pusat Darurat SOS'), findsOneWidget);
        expect(find.text('Kondisi Aman'), findsOneWidget);
      },
    );
  });
}
