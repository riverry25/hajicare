import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/room/models/room_model.dart';

void main() {
  group('RoomModel Multi-Pendamping Tests', () {
    test(
      'RoomModel supports up to 5 pendampingIds and preserves pendampingId',
      () {
        const room = RoomModel(
          id: 'room_123',
          name: 'Kamar Makkah 101',
          code: 'MKH101',
          createdBy: 'pendamping_1',
          pendampingId: 'pendamping_1',
          pendampingIds: [
            'pendamping_1',
            'pendamping_2',
            'pendamping_3',
            'pendamping_4',
            'pendamping_5',
          ],
        );

        expect(room.pendampingId, 'pendamping_1');
        expect(room.pendampingIds.length, 5);
        expect(room.pendampingIds, contains('pendamping_5'));

        final firestoreData = room.toFirestore();
        expect(firestoreData['pendampingId'], 'pendamping_1');
        expect(firestoreData['pendampingIds'], hasLength(5));
        expect(firestoreData['pendampingIds'], contains('pendamping_3'));
      },
    );

    test('RoomModel copyWith correctly updates pendampingIds', () {
      const room = RoomModel(
        id: 'room_123',
        name: 'Kamar Makkah 101',
        code: 'MKH101',
        createdBy: 'pendamping_1',
        pendampingId: 'pendamping_1',
        pendampingIds: ['pendamping_1'],
      );

      final updated = room.copyWith(
        pendampingIds: ['pendamping_1', 'pendamping_2'],
      );

      expect(updated.pendampingIds.length, 2);
      expect(updated.pendampingIds, ['pendamping_1', 'pendamping_2']);
      expect(updated.pendampingId, 'pendamping_1');
    });

    test('RoomModel capitalizedName auto-capitalizes lowercase names', () {
      const room = RoomModel(
        id: 'room_jihad',
        name: 'jihad gang',
        code: 'KZFRCJ',
        createdBy: 'pendamping_1',
      );

      expect(room.capitalizedName, 'Jihad Gang');
    });
  });
}
