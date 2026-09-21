import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/dashboard/widgets/companion_contact_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HajiCareController state;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
    state = Get.put(HajiCareController());
  });

  tearDown(Get.reset);

  Widget buildApp({Size size = const Size(390, 844), double textScale = 1}) {
    return MaterialApp(
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

  testWidgets('menawarkan pesan ke satu atau semua pendamping', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Hubungi Pendamping'), findsOneWidget);
    expect(find.text('Kirim Pesan'), findsAtLeastNWidgets(1));
    expect(find.text('Satu Pendamping'), findsOneWidget);
    expect(find.text('Semua Pendamping'), findsOneWidget);
    expect(
      find.byKey(const Key('companion_recipient_dropdown')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('recipient_all')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion_recipient_dropdown')), findsNothing);
    expect(find.text('Kirim ke Semua Pendamping'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('informasi selalu ditujukan ke semua pendamping', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('companion_kind_info')));
    await tester.pumpAndSettle();

    expect(find.text('Penerima: Semua Pendamping'), findsOneWidget);
    expect(find.text('2 pendamping dalam rombongan'), findsOneWidget);
    expect(find.text('Kirim ke Semua Pendamping'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tombol lokasi menjelaskan status dan tindakan dengan jelas', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('companion_location_button')), findsOneWidget);
    expect(find.text('Tekan untuk Kirim Lokasi'), findsOneWidget);
    expect(find.text('MATI'), findsOneWidget);
    expect(
      find.text('Lokasi hanya dikirim jika status tombol menunjukkan AKTIF.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
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
}
