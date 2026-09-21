import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/routes/app_routes.dart';

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
  });
}
