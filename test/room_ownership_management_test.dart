import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/features/room/models/room_member_model.dart';
import 'package:hajicare/features/room/models/room_model.dart';

void main() {
  group('Room Ownership Model & Role Evaluation Tests (Bagian A)', () {
    final baseRoom = RoomModel(
      id: 'room_abc',
      name: 'Rombongan Mina',
      code: 'MINA01',
      createdBy: 'fadli_primary',
      coOwnerId: 'apiw_co_owner',
      pendampingIds: const ['fadli_primary', 'apiw_co_owner', 'companion_3'],
      memberCount: 3,
    );

    test('1. Owner Utama identity and rights detection', () {
      expect(baseRoom.isPrimaryOwner('fadli_primary'), isTrue);
      expect(baseRoom.isPrimaryOwner('apiw_co_owner'), isFalse);
      expect(baseRoom.isPrimaryOwner('random_user'), isFalse);

      expect(baseRoom.isOwnerOrCoOwner('fadli_primary'), isTrue);
    });

    test('2. Owner Kedua identity and rights detection', () {
      expect(baseRoom.isCoOwner('apiw_co_owner'), isTrue);
      expect(baseRoom.isCoOwner('fadli_primary'), isFalse);
      expect(baseRoom.isCoOwner('companion_3'), isFalse);

      expect(baseRoom.isOwnerOrCoOwner('apiw_co_owner'), isTrue);
      expect(baseRoom.isOwnerOrCoOwner('companion_3'), isFalse);
    });

    test('3. RoomMemberModel helper methods respect room roles', () {
      final fadliMember = RoomMemberModel(
        uid: 'fadli_primary',
        name: 'Fadli',
        role: 'pendamping',
      );
      final apiwMember = RoomMemberModel(
        uid: 'apiw_co_owner',
        name: 'Apiw',
        role: 'pendamping',
      );
      final regularCompanion = RoomMemberModel(
        uid: 'companion_3',
        name: 'Pendamping Biasa',
        role: 'pendamping',
      );
      final jamaahMember = RoomMemberModel(
        uid: 'jihad_jamaah',
        name: 'Jihad',
        role: 'jamaah',
      );

      // Fadli
      expect(fadliMember.isPrimaryOwner(baseRoom), isTrue);
      expect(fadliMember.isCoOwner(baseRoom), isFalse);
      expect(fadliMember.isOwnerOrCoOwner(baseRoom), isTrue);

      // Apiw
      expect(apiwMember.isPrimaryOwner(baseRoom), isFalse);
      expect(apiwMember.isCoOwner(baseRoom), isTrue);
      expect(apiwMember.isOwnerOrCoOwner(baseRoom), isTrue);

      // Regular companion
      expect(regularCompanion.isPrimaryOwner(baseRoom), isFalse);
      expect(regularCompanion.isCoOwner(baseRoom), isFalse);
      expect(regularCompanion.isOwnerOrCoOwner(baseRoom), isFalse);

      // Jamaah
      expect(jamaahMember.isPrimaryOwner(baseRoom), isFalse);
      expect(jamaahMember.isCoOwner(baseRoom), isFalse);
      expect(jamaahMember.isOwnerOrCoOwner(baseRoom), isFalse);
    });

    test(
      '4. Appointing / replacing Co-Owner with copyWith maintains single Co-Owner',
      () {
        // Replace Apiw with Companion 3
        final updatedRoom = baseRoom.copyWith(coOwnerId: 'companion_3');

        expect(updatedRoom.isCoOwner('companion_3'), isTrue);
        expect(updatedRoom.isCoOwner('apiw_co_owner'), isFalse);
        expect(updatedRoom.isPrimaryOwner('fadli_primary'), isTrue);
      },
    );

    test(
      '5. Demoting / removing Co-Owner with clearCoOwner clears coOwnerId',
      () {
        final demotedRoom = baseRoom.copyWith(clearCoOwner: true);

        expect(demotedRoom.coOwnerId, isNull);
        expect(demotedRoom.isCoOwner('apiw_co_owner'), isFalse);
        expect(demotedRoom.isOwnerOrCoOwner('apiw_co_owner'), isFalse);
        // Owner Utama remains unchanged
        expect(demotedRoom.isPrimaryOwner('fadli_primary'), isTrue);
      },
    );

    test('6. Bequeathing / transferring ownership to Co-Owner', () {
      // Transfer to Apiw: createdBy becomes apiw_co_owner, coOwnerId is cleared
      final transferredRoom = baseRoom.copyWith(
        createdBy: 'apiw_co_owner',
        clearCoOwner: true,
      );

      expect(transferredRoom.isPrimaryOwner('apiw_co_owner'), isTrue);
      expect(transferredRoom.isPrimaryOwner('fadli_primary'), isFalse);
      expect(transferredRoom.coOwnerId, isNull);
    });

    test('7. Firestore serialization preserves coOwnerId', () {
      final map = baseRoom.toFirestore();
      expect(map['createdBy'], equals('fadli_primary'));
      expect(map['coOwnerId'], equals('apiw_co_owner'));

      final updated = baseRoom.copyWith(coOwnerId: 'new_co_owner');
      expect(updated.toFirestore()['coOwnerId'], equals('new_co_owner'));

      final cleared = baseRoom.copyWith(clearCoOwner: true);
      expect(cleared.toFirestore()['coOwnerId'], isNull);
    });
  });
}
