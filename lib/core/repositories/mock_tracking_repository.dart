import '../models/jamaah_data.dart';

abstract class TrackingRepository {
  Future<List<JamaahData>> fetchJamaahList();
  Future<void> updateDistance(String jamaahId, double newDistance);
}

class MockTrackingRepository implements TrackingRepository {
  @override
  Future<List<JamaahData>> fetchJamaahList() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      JamaahData(
        id: 'j1',
        name: 'H. Ahmad Dahlan (Ayah)',
        shortLabel: 'Ayah',
        distance: 80,
      ),
      JamaahData(
        id: 'j2',
        name: 'Hj. Siti Fatimah (Ibu)',
        shortLabel: 'Ibu',
        distance: 55,
      ),
    ];
  }

  @override
  Future<void> updateDistance(String jamaahId, double newDistance) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
