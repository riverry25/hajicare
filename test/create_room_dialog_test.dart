import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/features/room/controllers/admin_room_controller.dart';
import 'package:hajicare/features/room/widgets/create_room_dialog.dart';

class _FakeAdminRoomController extends AdminRoomController {
  String? lastCreatedRoomName;
  int createCallCount = 0;

  @override
  void subscribeToAllStreams() {
    // Avoid real Firebase stream subscriptions in unit/widget test
  }

  @override
  Future<void> createRoom(BuildContext context, String name) async {
    createCallCount++;
    lastCreatedRoomName = name;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAdminRoomController fakeController;

  setUp(() {
    Get.reset();
    fakeController = _FakeAdminRoomController();
    Get.put<AdminRoomController>(fakeController);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp() {
    return GetMaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => CreateRoomDialog.show(ctx, fakeController),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'CreateRoomDialog renders hero badge, title, underline field, and buttons',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify Floating Hero Card
      expect(find.text('ROOM PEMANTAUAN'), findsOneWidget);
      expect(find.byIcon(Icons.meeting_room_rounded), findsOneWidget);

      // Verify Title and Description
      expect(find.text('Buat Room Pantau Baru'), findsOneWidget);
      expect(
        find.text(
          'Masukkan nama kelompok atau maktab. Kode unik 6-karakter akan dibuat otomatis untuk jamaah & pendamping.',
        ),
        findsOneWidget,
      );

      // Verify Buttons
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('BUAT ROOM'), findsOneWidget);

      // Verify Presets are present
      expect(find.text('Maktab 48 Kloter 12'), findsOneWidget);
      expect(find.text('Kloter 05 JKS'), findsOneWidget);
    },
  );

  testWidgets('CreateRoomDialog validates empty input and shows error', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Tap submit without typing anything
    await tester.tap(find.text('BUAT ROOM'));
    await tester.pumpAndSettle();

    expect(find.text('Nama rombongan tidak boleh kosong'), findsOneWidget);
    expect(fakeController.createCallCount, 0);
  });

  testWidgets('CreateRoomDialog preset chip populates text field and submits', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Tap a preset chip
    await tester.tap(find.text('Maktab 48 Kloter 12'));
    await tester.pumpAndSettle();

    // Verify text field has preset text
    expect(find.text('Maktab 48 Kloter 12'), findsWidgets);

    // Tap submit
    await tester.tap(find.text('BUAT ROOM'));
    await tester.pumpAndSettle();

    expect(fakeController.createCallCount, 1);
    expect(fakeController.lastCreatedRoomName, 'Maktab 48 Kloter 12');
  });

  testWidgets('CreateRoomDialog cancel button dismisses dialog', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Room Pantau Baru'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Buat Room Pantau Baru'), findsNothing);
  });
}
