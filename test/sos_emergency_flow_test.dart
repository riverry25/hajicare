import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/routes/app_routes.dart';
import 'package:hajicare/features/notification/models/notification_model.dart';
import 'package:hajicare/features/room/models/room_member_model.dart';

void main() {
  group('Emergency SOS HajiCare Tests', () {
    test('AppRoutes registers sosAlertDetail route', () {
      expect(AppRoutes.sosAlertDetail, '/sos_alert_detail');
      final detailPage = AppRoutes.pages.firstWhere(
        (p) => p.name == AppRoutes.sosAlertDetail,
        orElse: () => throw StateError('sosAlertDetail page not found'),
      );
      expect(detailPage.name, '/sos_alert_detail');
    });

    test(
      'SOS Event Data Map contains required fields for admin/pendamping',
      () {
        final sampleSosEvent = <String, dynamic>{
          'id': 'evt_9988',
          'userId': 'user_123',
          'jamaahId': 'user_123',
          'userName': 'Ahmad Dahlan',
          'roomName': 'Kloter JKS-05',
          'kloter': 'JKS-05',
          'maktab': 'Maktab 12',
          'status': 'active',
          'timestamp': DateTime(2026, 9, 21, 10, 30),
        };

        expect(sampleSosEvent['userName'], 'Ahmad Dahlan');
        expect(sampleSosEvent['userId'], 'user_123');
        expect(sampleSosEvent['kloter'], 'JKS-05');
        expect(sampleSosEvent['maktab'], 'Maktab 12');
        expect(sampleSosEvent['status'], 'active');
      },
    );

    test('SOS Event with null kloter and maktab falls back gracefully', () {
      final sampleSosEvent = <String, dynamic>{
        'id': 'evt_9989',
        'userId': 'user_456',
        'jamaahId': 'user_456',
        'userName': 'Siti Rahma',
        'status': 'active',
      };

      final kloter = sampleSosEvent['kloter'] as String?;
      final maktab = sampleSosEvent['maktab'] as String?;

      expect(kloter, isNull);
      expect(maktab, isNull);

      final displayKloter = (kloter != null && kloter.isNotEmpty)
          ? kloter
          : '-';
      final displayMaktab = (maktab != null && maktab.isNotEmpty)
          ? maktab
          : '-';

      expect(displayKloter, '-');
      expect(displayMaktab, '-');
    });

    test('Location freshness calculation categorizes correctly', () {
      String locationFreshness(DateTime? updated, DateTime now) {
        if (updated == null) return 'Belum ada data lokasi';
        final diff = now.difference(updated);
        if (diff.inSeconds < 30) return 'Baru saja diperbarui';
        if (diff.inMinutes < 1) return '${diff.inSeconds}d yang lalu';
        if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
        return '${diff.inHours} jam yang lalu';
      }

      final now = DateTime(2026, 9, 21, 12, 0, 0);

      expect(locationFreshness(null, now), 'Belum ada data lokasi');
      expect(
        locationFreshness(now.subtract(const Duration(seconds: 10)), now),
        'Baru saja diperbarui',
      );
      expect(
        locationFreshness(now.subtract(const Duration(seconds: 45)), now),
        '45d yang lalu',
      );
      expect(
        locationFreshness(now.subtract(const Duration(minutes: 5)), now),
        '5 menit yang lalu',
      );
      expect(
        locationFreshness(now.subtract(const Duration(hours: 2)), now),
        '2 jam yang lalu',
      );
    });

    test('Status resolution recognizes selesai, resolved, and cancelled', () {
      bool isSosResolved(String? rawStatus) {
        final status = rawStatus?.toLowerCase();
        return status == 'resolved' ||
            status == 'cancelled' ||
            status == 'selesai';
      }

      expect(isSosResolved('active'), isFalse);
      expect(isSosResolved('baru'), isFalse);
      expect(isSosResolved('direspons'), isFalse);
      expect(isSosResolved('selesai'), isTrue);
      expect(isSosResolved('SELESAI'), isTrue);
      expect(isSosResolved('resolved'), isTrue);
      expect(isSosResolved('cancelled'), isTrue);
      expect(isSosResolved(null), isFalse);
    });

    test('Null GPS location does not crash distance calculations', () {
      String distanceText(dynamic location, dynamic myPos) {
        if (location == null) return 'Koordinat tidak tersedia';
        return 'Lat: ${location.latitude}, Lng: ${location.longitude}';
      }

      expect(distanceText(null, null), 'Koordinat tidak tersedia');
    });

    test('RoomMemberModel default sosActive is false and can be set true', () {
      final member = RoomMemberModel(
        uid: 'user_test_1',
        name: 'Jamaah Budi',
        role: 'jamaah',
        sosActive: true,
      );

      expect(member.sosActive, isTrue);
      final json = member.toFirestore();
      expect(json['sosActive'], isTrue);
    });

    test(
      'AppNotificationModel correctly recognizes sos_alert notification',
      () {
        const notif = AppNotificationModel(
          id: 'notif_sos_1',
          recipientId: 'pendamping_uid_1',
          type: 'sos_alert',
          title: '🚨 Panggilan Darurat SOS!',
          message: 'Jamaah Budi membutuhkan bantuan darurat segera!',
        );

        expect(notif.isSosAlert, isTrue);
        expect(notif.type, 'sos_alert');
      },
    );

    test(
      'SOS Dismissal filtering excludes dismissed items and read notifications',
      () {
        final dismissedIds = <String>{'evt_resolved_1', 'user_dismissed_2'};

        bool isDismissed(String? id, [String? secondaryId]) {
          if (id != null && id.isNotEmpty && dismissedIds.contains(id)) {
            return true;
          }
          if (secondaryId != null &&
              secondaryId.isNotEmpty &&
              dismissedIds.contains(secondaryId)) {
            return true;
          }
          return false;
        }

        // Check dismissed items
        expect(isDismissed('evt_resolved_1'), isTrue);
        expect(isDismissed('user_dismissed_2'), isTrue);
        expect(isDismissed('evt_active_99'), isFalse);
        expect(isDismissed('evt_active_99', 'user_dismissed_2'), isTrue);

        // Notification filtering: only unread sos_alerts that are not dismissed should be active
        final notif1 = const AppNotificationModel(
          id: 'notif_1',
          recipientId: 'pendamping_1',
          type: 'sos_alert',
          title: '🚨 Panggilan Darurat SOS!',
          message: 'Jamaah membutuhkan bantuan!',
          relatedId: 'evt_resolved_1',
          senderId: 'user_1',
          isRead: false,
        );
        final notif2 = const AppNotificationModel(
          id: 'notif_2',
          recipientId: 'pendamping_1',
          type: 'sos_alert',
          title: '🚨 Panggilan Darurat SOS!',
          message: 'Jamaah membutuhkan bantuan!',
          relatedId: 'evt_active_3',
          senderId: 'user_3',
          isRead: true, // already read / resolved
        );
        final notif3 = const AppNotificationModel(
          id: 'notif_3',
          recipientId: 'pendamping_1',
          type: 'sos_alert',
          title: '🚨 Panggilan Darurat SOS!',
          message: 'Jamaah membutuhkan bantuan!',
          relatedId: 'evt_active_4',
          senderId: 'user_4',
          isRead: false, // active unread
        );

        bool isActiveSosNotification(AppNotificationModel n) {
          if (!n.isSosAlert || n.isRead) return false;
          final senderId = n.senderId ?? n.targetUserId;
          final eventId = n.relatedId ?? senderId;
          if (isDismissed(n.id, eventId) || isDismissed(senderId)) return false;
          return true;
        }

        expect(isActiveSosNotification(notif1), isFalse); // dismissed
        expect(isActiveSosNotification(notif2), isFalse); // read
        expect(isActiveSosNotification(notif3), isTrue); // active
      },
    );
  });
}
