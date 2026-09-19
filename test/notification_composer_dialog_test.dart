import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/notification/widgets/notification_composer_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();

    final controller = Get.put(HajiCareController());
    controller.setRole(UserRole.pendamping);
    controller.activeRoomId.value = 'room-1';
    controller.activeRoom.value = const RoomModel(
      id: 'room-1',
      name: 'Rombongan Al Ikhlas',
      code: 'AIK123',
      createdBy: 'pendamping-1',
    );
    controller.jamaahList.assignAll([
      JamaahData(
        id: 'jamaah-1',
        name: 'Siti Aminah',
        shortLabel: 'Siti',
        distance: 20,
      ),
    ]);
  });

  tearDown(Get.reset);

  Widget buildApp({
    Size size = const Size(360, 640),
    double textScale = 1,
    String? initialScope,
    String? initialTargetUserId,
    String? initialTargetUserName,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: NotificationComposerDialog(
            initialScope: initialScope,
            initialTargetUserId: initialTargetUserId,
            initialTargetUserName: initialTargetUserName,
            initialRoomId: 'room-1',
            initialRoomName: 'Rombongan Al Ikhlas',
          ),
        ),
      ),
    );
  }

  testWidgets('menampilkan dialog bergaya kartu dengan field utama', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('notification_composer_dialog')),
      findsOneWidget,
    );
    expect(find.text('PESAN UNTUK JAMAAH'), findsOneWidget);
    expect(find.text('Pilih Penerima'), findsOneWidget);
    expect(find.text('Rombongan tujuan: Rombongan Al Ikhlas'), findsOneWidget);
    expect(find.byKey(const Key('notification_title_field')), findsOneWidget);
    expect(find.byKey(const Key('notification_message_field')), findsOneWidget);
    expect(find.byKey(const Key('notification_send_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('penerima awal tampil sebagai nama jamaah, bukan UID', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        initialScope: 'user',
        initialTargetUserId: 'jamaah-1',
        initialTargetUserName: 'Siti Aminah',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Siti Aminah'), findsOneWidget);
    expect(find.text('Pesan hanya dikirim kepada jamaah ini.'), findsOneWidget);
    expect(find.textContaining('UID'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tombol tetap muat pada layar sempit dan teks besar', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(size: const Size(300, 520), textScale: 1.6),
    );
    await tester.pumpAndSettle();

    final sendRect = tester.getRect(
      find.byKey(const Key('notification_send_button')),
    );
    final cancelRect = tester.getRect(
      find.byKey(const Key('notification_cancel_button')),
    );

    expect(sendRect.center.dx, closeTo(cancelRect.center.dx, 1));
    expect(sendRect.bottom, lessThan(cancelRect.top));
    expect(tester.takeException(), isNull);
  });
}
