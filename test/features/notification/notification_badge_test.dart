import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/features/notification/controllers/notification_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Badge Visibility & Unread Logic Tests', () {
    late NotificationController notifCtrl;
    late HajiCareController hajiCareCtrl;

    setUp(() {
      Get.reset();
      hajiCareCtrl = HajiCareController();
      Get.put<HajiCareController>(hajiCareCtrl);

      notifCtrl = NotificationController();
      Get.put<NotificationController>(notifCtrl);
    });

    tearDown(() {
      Get.reset();
    });

    test('Initial state: 0 unread notifications and 0 pending invitations', () {
      expect(notifCtrl.unreadCount.value, 0);
      expect(notifCtrl.pendingInvitations.length, 0);

      final totalUnread =
          notifCtrl.unreadCount.value + notifCtrl.pendingInvitations.length;
      expect(totalUnread, 0);
    });

    test('SeparatedMode true does not affect totalUnread (badge must remain hidden)', () {
      // Simulate jamaah separatedMode due to safe radius distance
      final jamaah = JamaahData(
        id: 'jamaah_test',
        name: 'Jamaah-001',
        shortLabel: 'Jamaah-001',
        distance: 500,
        separatedMode: true,
      );
      hajiCareCtrl.jamaahList.add(jamaah);
      expect(hajiCareCtrl.self.separatedMode, isTrue);

      final totalUnread =
          notifCtrl.unreadCount.value + notifCtrl.pendingInvitations.length;

      // Badge visibility condition: totalUnread > 0
      final shouldShowBadge = totalUnread > 0;
      expect(shouldShowBadge, isFalse,
          reason: 'Notification badge dot must not show when there are 0 unread notifications, even if separatedMode is true');
    });

    test('Badge becomes visible when unread notifications arrive', () {
      notifCtrl.unreadCount.value = 2;

      final totalUnread =
          notifCtrl.unreadCount.value + notifCtrl.pendingInvitations.length;
      final shouldShowBadge = totalUnread > 0;

      expect(shouldShowBadge, isTrue);
      expect(totalUnread, 2);
    });

    test('Badge becomes visible when pending room invitations exist', () {
      notifCtrl.unreadCount.value = 0;
      notifCtrl.pendingInvitations.add(
        RoomInvitationModel(
          id: 'inv_1',
          roomId: 'room_1',
          roomName: 'Kloter 12',
          fromUserId: 'pendamping_1',
          fromUserName: 'Ustadz Ahmad',
          toUserId: 'jamaah_1',
          toUserEmail: 'jamaah1@example.com',
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      final totalUnread =
          notifCtrl.unreadCount.value + notifCtrl.pendingInvitations.length;
      final shouldShowBadge = totalUnread > 0;

      expect(shouldShowBadge, isTrue);
      expect(totalUnread, 1);
    });

    test('Badge hides immediately when all notifications are read or cleared', () {
      notifCtrl.unreadCount.value = 3;
      expect(notifCtrl.unreadCount.value > 0, isTrue);

      // User marks all as read or clears notifications
      notifCtrl.unreadCount.value = 0;
      notifCtrl.pendingInvitations.clear();

      final totalUnread =
          notifCtrl.unreadCount.value + notifCtrl.pendingInvitations.length;
      expect(totalUnread > 0, isFalse);
    });
  });
}
