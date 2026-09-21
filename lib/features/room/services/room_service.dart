import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/trusted_backend_service.dart';
import '../models/activity_model.dart';
import '../models/room_invitation_model.dart';
import '../models/room_member_model.dart';
import '../models/room_model.dart';
import 'room_command_service.dart';
import 'room_query_service.dart';

class RoomException implements Exception {
  final String message;
  const RoomException(this.message);

  @override
  String toString() => message;
}

class RoomNotFoundException extends RoomException {
  const RoomNotFoundException(super.message);
}

class StaleInvitationException extends RoomException {
  const StaleInvitationException([
    super.message = 'Rombongan yang mengirim undangan sudah tidak tersedia.',
  ]);
}

/// Compatibility facade for existing room-domain callers.
///
/// Reads are isolated in [RoomQueryService]. Security-sensitive mutations are
/// isolated in [RoomCommandService] and remain backed by callable Functions.
class RoomService {
  late final RoomQueryService _queries;
  late final RoomCommandService _commands;

  RoomService({FirebaseFirestore? firestore, TrustedBackendService? backend}) {
    _queries = RoomQueryService(firestore: firestore);
    _commands = RoomCommandService(
      firestore: firestore,
      backend: backend,
      queries: _queries,
    );
  }

  Future<RoomModel> createRoom({
    required String name,
    required String adminUid,
  }) => _commands.createRoom(name: name);

  Future<RoomModel> createRoomByPendamping({
    required String name,
    required String pendampingUid,
    required String pendampingName,
    String? maktab,
    String? kloter,
  }) => _commands.createRoomByPendamping(
    name: name,
    maktab: maktab,
    kloter: kloter,
  );

  Future<RoomModel?> getRoomById(String roomId) => _queries.getRoomById(roomId);

  Stream<RoomModel?> getRoomStream(String roomId) =>
      _queries.getRoomStream(roomId);

  Stream<List<RoomModel>> getRoomsStream() => _queries.getRoomsStream();

  Stream<List<RoomMemberModel>> getRoomMembersStream(String roomId) =>
      _queries.getRoomMembersStream(roomId);

  Stream<List<RoomMemberModel>> watchRoomMembers(String roomId) =>
      _queries.watchRoomMembers(roomId);

  Stream<List<RoomInvitationModel>> getPendingInvitationsStream(String uid) =>
      _queries.getPendingInvitationsStream(uid);

  Future<void> updateRoomSettings({
    required String roomId,
    required String currentUserId,
    String? userRole,
    String? name,
    String? maktab,
    String? kloter,
    double? safeRadius,
  }) => _commands.updateRoomSettings(
    roomId: roomId,
    name: name,
    maktab: maktab,
    kloter: kloter,
    safeRadius: safeRadius,
  );

  Future<void> updateRoom({
    required String roomId,
    String? name,
    bool? isActive,
  }) => _commands.updateRoomSettings(
    roomId: roomId,
    name: name,
    isActive: isActive,
  );

  Future<void> toggleRoomStatus(String roomId, bool currentStatus) =>
      updateRoom(roomId: roomId, isActive: !currentStatus);

  Future<void> deleteRoomByCreator({
    required String roomId,
    required String currentUserId,
    required String senderName,
    String? userRole,
  }) => _commands.deleteRoom(roomId);

  Future<void> deleteRoom(String roomId, {String? roomName}) =>
      _commands.deleteRoom(roomId);

  Future<RoomModel> joinRoomByCode({
    required String roomCode,
    required String uid,
    required String userName,
    required String role,
  }) async {
    try {
      return await _commands.joinRoomByCode(roomCode);
    } on RoomCommandException catch (error) {
      throw RoomNotFoundException(error.message);
    }
  }

  Future<void> leaveRoom({
    required String roomId,
    required String uid,
    required String userName,
    required String role,
    String? roomName,
  }) => _commands.leaveRoom(roomId);

  Future<void> removeJamaahFromRoom({
    required String roomId,
    required String jamaahUid,
    required String actorUid,
    required String actorName,
    required String actorRole,
  }) => _commands.removeJamaah(roomId: roomId, jamaahUid: jamaahUid);

  Future<RoomInvitationModel> inviteJamaahByEmail({
    required String roomId,
    required String email,
    required String currentPendampingUid,
    required String currentPendampingName,
  }) async {
    try {
      return await _commands.inviteJamaah(roomId: roomId, email: email);
    } on RoomCommandException catch (error) {
      throw RoomException(error.message);
    }
  }

  Future<String> acceptInvitation({
    required String invitationId,
    required String uid,
    required String userName,
  }) async {
    final result = await _commands.respondInvitation(
      invitationId: invitationId,
      action: 'accept',
    );
    if (result['status'] == 'expired') throw const StaleInvitationException();
    final roomId = result['roomId'] as String?;
    if (roomId == null || roomId.isEmpty) {
      throw const RoomException(
        'Undangan diterima tetapi rombongan belum dapat dimuat.',
      );
    }
    return roomId;
  }

  Future<void> rejectInvitation({
    required String invitationId,
    required String uid,
  }) async {
    await _commands.respondInvitation(
      invitationId: invitationId,
      action: 'reject',
    );
  }

  Future<void> updateSafeRadius({
    required String roomId,
    required double radius,
  }) => _commands.updateRoomSettings(roomId: roomId, safeRadius: radius);

  Future<void> updateMemberLocation({
    required String roomId,
    required String uid,
    required double latitude,
    required double longitude,
  }) => _commands.updateMemberLocation(
    roomId: roomId,
    uid: uid,
    latitude: latitude,
    longitude: longitude,
  );

  Future<void> resolveSos({
    required String userId,
    String? roomId,
    String? eventId,
    String? resolvedByUid,
  }) => _commands.transitionSos(
    action: userId == resolvedByUid ? 'cancel' : 'resolve',
    userId: userId,
    roomId: roomId,
    eventId: eventId,
  );

  Stream<List<ActivityModel>> getRecentActivitiesStream({int limit = 10}) =>
      _queries.getRecentActivitiesStream(limit: limit);

  Future<ActivityPage> getActivitiesPaginated({
    int limit = 10,
    DocumentSnapshot? startAfterDoc,
    String? categoryFilter,
  }) => _queries.getActivitiesPaginated(
    limit: limit,
    startAfterDoc: startAfterDoc,
    categoryFilter: categoryFilter,
  );

  Stream<List<Map<String, dynamic>>> getActiveSosEventsStream({
    String? roomId,
  }) => _queries.getActiveSosEventsStream(roomId: roomId);

  Stream<List<Map<String, dynamic>>> getResolvedSosEventsStream({
    int limit = 5,
  }) => _queries.getResolvedSosEventsStream(limit: limit);

  Stream<List<Map<String, dynamic>>> getAllUsersStream() =>
      _queries.getAllUsersStream();

  Stream<Map<String, int>> getGlobalMemberCountsStream() =>
      _queries.getGlobalMemberCountsStream();

  Stream<Map<String, Map<String, int>>> getAllRoomMemberBreakdownStream() =>
      _queries.getAllRoomMemberBreakdownStream();
}
