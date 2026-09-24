import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/dashboard/services/assistance_request_service.dart';
import 'package:hajicare/features/dashboard/widgets/companion_contact_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HajiCareController state;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    state = Get.put(HajiCareController());
    Get.put(AssistanceRequestService());
  });

  tearDown(() {
    AssistanceRequestService.instance.reset();
    Get.reset();
  });

  Widget buildApp({Size size = const Size(390, 844), double textScale = 1}) {
    return MaterialApp(
      locale: const Locale('id'),
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: CompanionContactSheet(
            roomId: 'room-1',
            state: state,
            pendampings: const [
              RoomMemberModel(
                uid: 'pendamping-1',
                name: 'Pak Ahmad',
                role: 'pendamping',
              ),
              RoomMemberModel(
                uid: 'pendamping-2',
                name: 'Bu Siti',
                role: 'pendamping',
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('menampilkan header dan 4 jenis bantuan yang accessible', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Hubungi Pendamping'), findsOneWidget);
    expect(find.text('Dapatkan bantuan dari pendamping Anda'), findsOneWidget);
    expect(find.text('Apa yang terjadi?'), findsOneWidget);

    // 4 pilihan jenis bantuan
    expect(find.text('Saya tidak tahu jalan pulang'), findsWidgets);
    expect(find.text('Saya terpisah dari rombongan'), findsWidgets);
    expect(find.text('Saya membutuhkan penjemputan'), findsWidgets);
    expect(find.text('Saya ingin mengirim pesan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'menawarkan pilihan penerima satu atau semua pendamping dengan dropdown',
    (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('Satu Pendamping'), findsOneWidget);
      expect(find.text('Semua Pendamping'), findsOneWidget);
      expect(
        find.byKey(const Key('companion_recipient_dropdown')),
        findsOneWidget,
      );

      // Beralih ke semua pendamping
      await tester.scrollUntilVisible(
        find.byKey(const Key('recipient_all')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('recipient_all')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('companion_recipient_dropdown')),
        findsNothing,
      );
      expect(find.text('Kirim ke Semua Pendamping'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tombol dan status lokasi menjelaskan masalah dan tindakan jelas', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion_location_button')), findsOneWidget);
    expect(find.text('⚠️ Lokasi belum tersedia'), findsOneWidget);
    expect(
      find.text(
        'Aktifkan GPS dan izin akses lokasi agar pendamping dapat menemukan Anda.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aktifkan Lokasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mengubah jenis bantuan mengubah teks CTA secara kontekstual', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Default: 'Saya tidak tahu jalan pulang' -> CTA: 'Minta Bantuan'
    expect(find.text('Minta Bantuan'), findsOneWidget);

    // Pilih Penjemputan
    await tester.tap(find.byKey(const Key('companion_kind_pickup')));
    await tester.pumpAndSettle();
    expect(find.text('Minta Penjemputan'), findsOneWidget);

    // Pilih Kirim Pesan
    await tester.tap(find.byKey(const Key('companion_kind_message')));
    await tester.pumpAndSettle();
    expect(find.text('Kirim Pesan'), findsWidgets);
  });

  testWidgets('tetap dapat digulir pada layar sempit dengan teks besar', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(size: const Size(320, 620), textScale: 1.6),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('companion_send_button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('companion_send_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tinggi sheet ringkas dan isi tetap dapat digulir', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(size: const Size(390, 800)));
    await tester.pumpAndSettle();

    final sheetHeight = tester
        .getSize(find.byKey(const Key('companion_contact_sheet')))
        .height;
    expect(sheetHeight, lessThanOrEqualTo(640));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
