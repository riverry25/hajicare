import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/trusted_backend_service.dart';
import '../models/room_invitation_model.dart';
import '../models/room_model.dart';
import 'room_query_service.dart';

class RoomCommandException implements Exception {
  final String message;
  const RoomCommandException(this.message);

  @override
  String toString() => message;
}

/// Mutations for the room domain.
///
/// Membership, invitation, room administration, and SOS changes are always
/// delegated to callable Functions. The only direct client write here is the
/// allow-listed member telemetry document used for live location tracking.
class RoomCommandService {
  final FirebaseFirestore? _providedFirestore;
  final TrustedBackendService? _providedBackend;
  final RoomQueryService queries;

  RoomCommandService({
    FirebaseFirestore? firestore,
    TrustedBackendService? backend,
    required this.queries,
  }) : _providedFirestore = firestore,
       _providedBackend = backend;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  TrustedBackendService get _backend =>
      _providedBackend ?? TrustedBackendService();

  Future<RoomModel> createRoom({required String name}) async {
    final result = await _backend.call('createRoom', {'name': name});
    return _loadCreatedRoom(result);
  }

  Future<RoomModel> createRoomByPendamping({
    required String name,
    String? maktab,
    String? kloter,
  }) async {
    final result = await _backend.call('createRoom', {
      'name': name,
      'maktab': ?maktab,
      'kloter': ?kloter,
    });
    return _loadCreatedRoom(result);
  }

  Future<RoomModel> _loadCreatedRoom(Map<String, dynamic> result) async {
    final roomId = result['roomId'] as String?;
    if (roomId == null || roomId.isEmpty) {
      throw const RoomCommandException(
        'Rombongan berhasil diproses tetapi ID tidak tersedia.',
      );
    }
    final room = await queries.getRoomById(roomId);
    if (room == null) {
      throw const RoomCommandException(
        'Rombongan berhasil diproses tetapi belum dapat dimuat.',
      );
    }
    return room;
  }

  Future<void> updateRoomSettings({
    required String roomId,
    String? name,
    String? maktab,
    String? kloter,
    double? safeRadius,
    bool? isActive,
  }) {
    return _backend
        .call('updateRoomSettings', {
          'roomId': roomId,
          'name': ?name,
          'maktab': ?maktab,
          'kloter': ?kloter,
          'safeRadius': ?safeRadius,
          'isActive': ?isActive,
        })
        .then((_) {});
  }

  Future<void> deleteRoom(String roomId) {
    return _backend.call('deleteRoom', {'roomId': roomId}).then((_) {});
  }

  Future<RoomModel> joinRoomByCode(String roomCode) async {
    final result = await _backend.call('joinRoomByCode', {
      'roomCode': roomCode.trim().toUpperCase(),
    });
    final roomId = result['roomId'] as String?;
    if (roomId == null || roomId.isEmpty) {
      throw const RoomCommandException(
        'Rombongan tidak ditemukan setelah bergabung.',
      );
    }
    final room = await queries.getRoomById(roomId);
    if (room == null) {
      throw const RoomCommandException(
        'Rombongan tidak ditemukan setelah bergabung.',
      );
    }
    return room;
  }

  Future<void> leaveRoom(String roomId) {
    return _backend.call('leaveRoom', {'roomId': roomId}).then((_) {});
  }

  Future<void> removeJamaah({
    required String roomId,
    required String jamaahUid,
  }) {
    return _backend
        .call('removeJamaah', {'roomId': roomId, 'jamaahUid': jamaahUid})
        .then((_) {});
  }

  Future<RoomInvitationModel> inviteJamaah({
    required String roomId,
    required String email,
  }) async {
    final result = await _backend.call('inviteJamaah', {
      'roomId': roomId,
      'email': email.trim().toLowerCase(),
    });
    final invitationId = result['invitationId'] as String?;
    if (invitationId == null || invitationId.isEmpty) {
      throw const RoomCommandException(
        'Undangan berhasil dibuat tetapi ID tidak tersedia.',
      );
    }
    final snapshot = await _firestore
        .collection('invitations')
        .doc(invitationId)
        .get();
    if (!snapshot.exists) {
      throw const RoomCommandException(
        'Undangan berhasil dibuat tetapi belum dapat dimuat.',
      );
    }
    return RoomInvitationModel.fromFirestore(snapshot);
  }

  Future<Map<String, dynamic>> respondInvitation({
    required String invitationId,
    required String action,
  }) {
    return _backend.call('respondInvitation', {
      'invitationId': invitationId,
      'action': action,
    });
  }

  Future<void> transitionSos({
    required String action,
    required String userId,
    String? eventId,
  }) {
    return _backend
        .call('transitionSos', {
          'action': action,
          'userId': userId,
          if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
        })
        .then((_) {});
  }

  Future<void> updateMemberLocation({
    required String roomId,
    required String uid,
    required double latitude,
    required double longitude,
  }) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(uid)
        .set({
          'currentLocation': GeoPoint(latitude, longitude),
          'locationUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }
}
