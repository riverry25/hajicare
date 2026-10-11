import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_translations.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/notification/models/notification_model.dart';
import 'package:hajicare/features/room/screens/room_detail_screen.dart';
import 'package:hajicare/features/room/services/room_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRoomService extends RoomService {
  bool leaveRoomCalled = false;
  String? leftRoomId;
  String? leftUid;

  bool deleteRoomCalled = false;
  String? deletedRoomId;

  String? leftSuccessorUid;

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String uid,
    required String userName,
    required String role,
    String? roomName,
    String? successorUid,
  }) async {
    leaveRoomCalled = true;
    leftRoomId = roomId;
    leftUid = uid;
    leftSuccessorUid = successorUid;
  }

  @override
  Future<void> deleteRoomByCreator({
    required String roomId,
    required String currentUserId,
    required String senderName,
    String? userRole,
  }) async {
    deleteRoomCalled = true;
    deletedRoomId = roomId;
  }

  @override
  Stream<RoomModel?> getRoomStream(String roomId) {
    return Stream.value(
      RoomModel(
        id: roomId,
        name: 'Rombongan Uji',
        code: 'XYZ123',
        createdBy: 'creator_uid',
        pendampingId: 'creator_uid',
        pendampingIds: const ['creator_uid', 'companion_2'],
        isActive: true,
        memberCount: 2,
      ),
    );
  }

  @override
  Stream<List<RoomMemberModel>> getRoomMembersStream(String roomId) {
    return Stream.value([
      RoomMemberModel(
        uid: 'creator_uid',
        name: 'Pemilik Pertama',
        role: 'pendamping',
        joinedAt: DateTime.now(),
      ),
      RoomMemberModel(
        uid: 'companion_2',
        name: 'Pendamping Kedua',
        role: 'pendamping',
        joinedAt: DateTime.now(),
      ),
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({
      HajiCareController.keyActiveRoomId: 'test_room_1',
      HajiCareController.keyUserRole: 'pendamping',
    });
  });

  tearDown(() {
    Get.reset();
  });

  group('Room Lifecycle Management Tests', () {
    test(
      'clearActiveRoomSession purges in-memory and SharedPreferences cache',
      () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          HajiCareController.keyActiveRoomId,
          'test_room_1',
        );

        final controller = Get.put(HajiCareController());
        await controller.applyUserData(
          roleStr: 'jamaah',
          roomId: 'test_room_1',
        );

        expect(controller.activeRoomId.value, equals('test_room_1'));

        await controller.clearActiveRoomSession();

        expect(controller.activeRoomId.value, isNull);
        expect(controller.cachedRoomId, isNull);
        expect(controller.activeRoom.value, isNull);
        expect(prefs.getString(HajiCareController.keyActiveRoomId), isNull);
      },
    );

    testWidgets(
      'RoomDetailScreen renders both QR Code and Keluar Room buttons in responsive row',
      (tester) async {
        final room = RoomModel(
          id: 'test_room_1',
          name: 'Rombongan Uji',
          code: 'XYZ123',
          createdBy: 'creator_uid',
          pendampingId: 'creator_uid',
          pendampingIds: const ['creator_uid', 'companion_2'],
          isActive: true,
          memberCount: 2,
        );

        final controller = Get.put(HajiCareController());
        controller.activeRoom.value = room;
        controller.activeRoomId.value = room.id;

        final fakeRoomService = _FakeRoomService();
        Get.put<RoomService>(fakeRoomService);

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('id', 'ID'),
            initialRoute: '/detail',
            getPages: [
              GetPage(
                name: '/detail',
                page: () => RoomDetailScreen(
                  key: const Key('detail_screen'),
                  roomService: fakeRoomService,
                ),
                arguments: room,
              ),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify QR Code button
        expect(find.byIcon(Icons.qr_code_2_rounded), findsWidgets);

        // Verify Keluar Room button
        expect(find.byIcon(Icons.logout_rounded), findsWidgets);
      },
    );

    testWidgets(
      'RoomDetailScreen renders adaptively on narrow screen without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final room = RoomModel(
          id: 'test_room_narrow',
          name: 'Rombongan Layar Sempit',
          code: 'NAR123',
          createdBy: 'creator_uid',
          pendampingId: 'creator_uid',
          pendampingIds: const ['creator_uid'],
          isActive: true,
          memberCount: 1,
        );

        final controller = Get.put(HajiCareController());
        controller.activeRoom.value = room;
        controller.activeRoomId.value = room.id;

        final fakeRoomService = _FakeRoomService();
        Get.put<RoomService>(fakeRoomService);

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('id', 'ID'),
            initialRoute: '/detail',
            getPages: [
              GetPage(
                name: '/detail',
                page: () => RoomDetailScreen(
                  key: const Key('detail_screen_narrow'),
                  roomService: fakeRoomService,
                ),
                arguments: room,
              ),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byIcon(Icons.qr_code_2_rounded), findsWidgets);
        expect(find.byIcon(Icons.logout_rounded), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'Notification model correctly identifies room_deleted and member_left',
      () {
        const deletedNotif = AppNotificationModel(
          id: 'notif_1',
          recipientId: 'user_1',
          type: 'room_deleted',
          title: 'Rombongan Dihapus',
          message: 'Rombongan Uji telah dihapus.',
        );
        expect(deletedNotif.isRoomDeleted, isTrue);
        expect(deletedNotif.isMemberLeft, isFalse);

        const memberLeftNotif = AppNotificationModel(
          id: 'notif_2',
          recipientId: 'pendamping_1',
          type: 'member_left',
          title: 'Jamaah Keluar Rombongan',
          message: 'Ahmad telah keluar dari rombongan.',
        );
        expect(memberLeftNotif.isMemberLeft, isTrue);
        expect(memberLeftNotif.isRoomDeleted, isFalse);
      },
    );
  });
}
