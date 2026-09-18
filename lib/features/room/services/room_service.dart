import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/jamaah_data.dart';
import '../models/activity_model.dart';
import '../models/room_model.dart';
import '../models/room_member_model.dart';
import '../models/room_invitation_model.dart';
import '../../notification/models/notification_model.dart';

/// Exceptions for granular join room error handling
class RoomException implements Exception {
  final String message;
  const RoomException(this.message);
  @override
  String toString() => message;
}

class RoomNotFoundException extends RoomException {
  const RoomNotFoundException(super.message);
}

class InvalidRoomNameException extends RoomException {
  const InvalidRoomNameException(super.message);
}

class RoomInactiveException extends RoomException {
  const RoomInactiveException(super.message);
}

class RoomAlreadyJoinedException extends RoomException {
  const RoomAlreadyJoinedException(super.message);
}

class StaleInvitationException extends RoomException {
  const StaleInvitationException([
    super.message = 'Room yang mengirim undangan ini sudah tidak tersedia.',
  ]);
}

enum _AcceptInvitationStatus {
  success,
  staleRoom,
}

/// Service handling all Room CRUD, Membership, and Join operations
class RoomService {
  final FirebaseFirestore _firestore;

  RoomService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Code Generation ────────────────────────────────────────────────────────
  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Generates a random uppercase alphanumeric 6-character room code.
  String generateCodeCandidate([int length = 6]) {
    final rand = Random();
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_codeChars[rand.nextInt(_codeChars.length)]);
    }
    return buffer.toString();
  }

  /// Generates a guaranteed-unique room code against Firestore.
  Future<String> generateUniqueRoomCode([int maxRetries = 10]) async {
    for (int i = 0; i < maxRetries; i++) {
      final code = generateCodeCandidate();
      final existing = await _firestore
          .collection('rooms')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        return code;
      }
    }
    // Fallback: 8 characters candidate
    return generateCodeCandidate(8);
  }

  // ── Room CRUD (Admin) ──────────────────────────────────────────────────────

  /// Creates a new room in `rooms/{roomId}` with an auto-generated unique code.
  Future<RoomModel> createRoom({
    required String name,
    required String adminUid,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const RoomException('Nama room tidak boleh kosong');
    }

    final code = await generateUniqueRoomCode();
    final docRef = _firestore.collection('rooms').doc();

    final room = RoomModel(
      id: docRef.id,
      name: trimmedName,
      code: code,
      createdBy: adminUid,
      createdAt: DateTime.now(),
      isActive: true,
      memberCount: 0,
    );

    await docRef.set(room.toFirestore());
    debugPrint('[RoomService] Created room: ${room.name} (${room.code}) id: ${room.id}');

    // Log Activity
    await logActivity(
      type: ActivityType.roomCreated,
      title: 'Room Dibuat',
      description: 'Room "${room.name}" (${room.code}) berhasil dibuat.',
      roomId: room.id,
      roomName: room.name,
      userId: adminUid,
    );

    return room;
  }

  /// Creates a new room by a Pendamping with auto-generated unique code,
  /// sets pendamping as owner, sets membership, and updates user activeRoomId.
  Future<RoomModel> createRoomByPendamping({
    required String name,
    required String pendampingUid,
    required String pendampingName,
    String? maktab,
    String? kloter,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const RoomException('Nama room tidak boleh kosong');
    }

    // Constraint: 1 active room per user
    final userDoc = await _firestore.collection('users').doc(pendampingUid).get();
    final currentActiveRoom = userDoc.data()?['activeRoomId'] as String?;
    if (currentActiveRoom != null && currentActiveRoom.trim().isNotEmpty) {
      throw const RoomException('Anda sudah memiliki Room aktif. Tidak dapat membuat room kedua.');
    }

    final code = await generateUniqueRoomCode();
    final docRef = _firestore.collection('rooms').doc();

    final room = RoomModel(
      id: docRef.id,
      name: trimmedName,
      code: code,
      createdBy: pendampingUid,
      createdByRole: 'pendamping',
      pendampingId: pendampingUid,
      maktab: maktab?.trim(),
      kloter: kloter?.trim(),
      safeRadius: 200.0,
      createdAt: DateTime.now(),
      isActive: true,
      memberCount: 1,
    );

    final batch = _firestore.batch();
    batch.set(docRef, room.toFirestore());

    // Add pendamping to members subcollection
    final memberRef = docRef.collection('members').doc(pendampingUid);
    batch.set(memberRef, {
      'uid': pendampingUid,
      'name': pendampingName.trim(),
      'role': 'pendamping',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // Update user activeRoomId and sync maktab/kloter if present
    final userUpdate = <String, dynamic>{
      'activeRoomId': docRef.id,
    };
    if (maktab != null && maktab.trim().isNotEmpty) {
      userUpdate['maktab'] = maktab.trim();
    }
    if (kloter != null && kloter.trim().isNotEmpty) {
      userUpdate['kloter'] = kloter.trim();
    }
    batch.update(_firestore.collection('users').doc(pendampingUid), userUpdate);

    await batch.commit();
    debugPrint('[RoomService] Pendamping created room: ${room.name} (${room.code}) id: ${room.id}');

    await logActivity(
      type: ActivityType.roomCreated,
      title: 'Room Dibuat oleh Pendamping',
      description: 'Pendamping $pendampingName membuat room "${room.name}" (${room.code}).',
      roomId: room.id,
      roomName: room.name,
      userId: pendampingUid,
      userName: pendampingName,
      role: 'pendamping',
    );

    return room;
  }

  /// Updates room settings (name, maktab, kloter, safeRadius).
  /// Validates ownership: only creator (or admin) can update.
  Future<void> updateRoomSettings({
    required String roomId,
    required String currentUserId,
    String? userRole,
    String? name,
    String? maktab,
    String? kloter,
    double? safeRadius,
  }) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      throw const RoomException('Room tidak ditemukan.');
    }

    final roomData = roomDoc.data()!;
    final createdBy = roomData['createdBy'] as String?;
    final isAdmin = userRole?.toLowerCase() == 'admin';

    // Enforce creator ownership
    if (!isAdmin && (createdBy == null || createdBy != currentUserId)) {
      throw const RoomException(
        'Anda bukan pembuat room ini. Hanya pembuat room yang berhak mengubah pengaturan.',
      );
    }

    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if (maktab != null) {
      updates['maktab'] = maktab.trim().isNotEmpty ? maktab.trim() : FieldValue.delete();
    }
    if (kloter != null) {
      updates['kloter'] = kloter.trim().isNotEmpty ? kloter.trim() : FieldValue.delete();
    }
    if (safeRadius != null) {
      if (safeRadius <= 0) {
        throw const RoomException('Radius aman harus bernilai positif lebih dari 0 meter.');
      }
      updates['safeRadius'] = safeRadius;
    }

    if (updates.isEmpty) return;

    final batch = _firestore.batch();
    batch.update(roomDoc.reference, updates);

    // Sync maktab & kloter to pendamping user profile if provided
    final userUpdates = <String, dynamic>{};
    if (maktab != null && maktab.trim().isNotEmpty) {
      userUpdates['maktab'] = maktab.trim();
    }
    if (kloter != null && kloter.trim().isNotEmpty) {
      userUpdates['kloter'] = kloter.trim();
    }
    if (userUpdates.isNotEmpty) {
      batch.update(_firestore.collection('users').doc(currentUserId), userUpdates);
    }

    await batch.commit();

    await logActivity(
      type: ActivityType.roomUpdated,
      title: 'Pengaturan Room Diperbarui',
      description: 'Pengaturan room "${updates['name'] ?? roomData['name']}" berhasil diperbarui.',
      roomId: roomId,
      roomName: updates['name'] as String? ?? roomData['name'] as String?,
      userId: currentUserId,
      role: userRole ?? 'pendamping',
    );
  }

  /// Updates an existing room's name and/or active status.
  Future<void> updateRoom({
    required String roomId,
    String? name,
    bool? isActive,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) {
      updates['name'] = name.trim();
    }
    if (isActive != null) {
      updates['isActive'] = isActive;
    }
    if (updates.isEmpty) return;

    await _firestore.collection('rooms').doc(roomId).update(updates);
  }

  /// Toggles active status of a room.
  Future<void> toggleRoomStatus(String roomId, bool currentStatus) async {
    final nextStatus = !currentStatus;
    await updateRoom(roomId: roomId, isActive: nextStatus);

    await logActivity(
      type: nextStatus ? ActivityType.roomActivated : ActivityType.roomDeactivated,
      title: nextStatus ? 'Room Diaktifkan' : 'Room Dinonaktifkan',
      description: nextStatus
          ? 'Room telah diaktifkan kembali untuk operasional.'
          : 'Room dinonaktifkan sementara oleh admin.',
      roomId: roomId,
    );
  }

  /// Deletes a room by its creator (or admin) atomically:
  /// 1. Verifies ownership (`createdBy == currentUserId`).
  /// 2. Fetches all room members.
  /// 3. Resets `users/{uid}.activeRoomId = null` and `sosActive = false` for all members.
  /// 4. Dispatches `room_deleted` notifications to all Jamaah members.
  /// 5. Deletes all member subcollection documents and the room document.
  Future<void> deleteRoomByCreator({
    required String roomId,
    required String currentUserId,
    required String senderName,
    String? userRole,
  }) async {
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      throw const RoomException('Room tidak ditemukan atau sudah dihapus.');
    }

    final roomData = roomDoc.data()!;
    final createdBy = roomData['createdBy'] as String?;
    final roomName = (roomData['name'] as String?)?.trim() ?? 'Room Pemantauan';
    final roomCode = (roomData['code'] as String?)?.trim().toUpperCase() ?? '';
    final isAdmin = userRole?.toLowerCase() == 'admin';

    // Enforce creator ownership
    if (!isAdmin && (createdBy == null || createdBy != currentUserId)) {
      throw const RoomException('Anda bukan pembuat room ini. Hanya pembuat room yang berhak menghapus.');
    }

    final membersSnap = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .get();

    final batch = _firestore.batch();

    // 1. Delete all member subcollection documents and unbind users
    for (final doc in membersSnap.docs) {
      final memberUid = doc.id;
      final memberData = doc.data();
      final memberRole = (memberData['role'] as String?)?.toLowerCase() ?? 'jamaah';

      // Remove member doc
      batch.delete(doc.reference);

      // Reset user activeRoomId and sosActive
      final userRef = _firestore.collection('users').doc(memberUid);
      batch.update(userRef, {
        'activeRoomId': FieldValue.delete(),
        'sosActive': false,
      });

      // Send room_deleted notification to Jamaah members
      if (memberRole == 'jamaah' && memberUid != currentUserId) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'title': 'Room Dihapus',
          'message': 'Room "$roomName" ($roomCode) telah dihapus oleh Pendamping $senderName. Akses ke pemantauan room dinonaktifkan.',
          'type': 'room_deleted',
          'recipientId': memberUid,
          'senderId': currentUserId,
          'senderRole': userRole ?? 'pendamping',
          'senderName': senderName,
          'targetUserId': memberUid,
          'targetRoomId': roomId,
          'relatedId': roomId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 2. Ensure creator user doc also resets activeRoomId
    final creatorUserRef = _firestore.collection('users').doc(currentUserId);
    batch.update(creatorUserRef, {
      'activeRoomId': FieldValue.delete(),
    });

    // 3. Invalidate any pending invitations for this room
    final pendingInvitations = await _firestore
        .collection('invitations')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final invDoc in pendingInvitations.docs) {
      batch.update(invDoc.reference, {
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
        'expiredReason': 'room_deleted',
      });
    }

    // 4. Delete room document
    batch.delete(roomDoc.reference);

    await batch.commit();

    await logActivity(
      type: ActivityType.roomDeactivated,
      title: 'Room Dihapus oleh Pendamping',
      description: 'Room "$roomName" ($roomCode) telah dihapus oleh $senderName beserta seluruh anggotanya.',
      roomId: roomId,
      roomName: roomName,
      userId: currentUserId,
      userName: senderName,
      role: userRole ?? 'pendamping',
    );
  }

  /// Deletes a room doc and its members subcollection.
  Future<void> deleteRoom(String roomId, {String? roomName}) async {
    final membersSnap = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .get();

    final batch = _firestore.batch();
    for (final doc in membersSnap.docs) {
      batch.delete(doc.reference);
      // Also unbind member user doc
      batch.update(_firestore.collection('users').doc(doc.id), {
        'activeRoomId': FieldValue.delete(),
        'sosActive': false,
      });
    }
    final pendingInvitations = await _firestore
        .collection('invitations')
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final invDoc in pendingInvitations.docs) {
      batch.update(invDoc.reference, {
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
        'expiredReason': 'room_deleted',
      });
    }

    batch.delete(_firestore.collection('rooms').doc(roomId));
    await batch.commit();

    await logActivity(
      type: ActivityType.roomDeactivated,
      title: 'Room Dihapus',
      description: 'Room ${roomName != null ? '"$roomName"' : roomId} telah dihapus beserta anggotanya.',
      roomId: roomId,
      roomName: roomName,
    );
  }

  /// Streams all rooms (for Admin Dashboard / Management).
  Stream<List<RoomModel>> getRoomsStream() {
    return _firestore
        .collection('rooms')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => RoomModel.fromFirestore(doc)).toList());
  }

  /// Fetches a single room by ID.
  Future<RoomModel?> getRoom(String roomId) async {
    final doc = await _firestore.collection('rooms').doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromFirestore(doc);
  }

  // ── Members Subcollection ──────────────────────────────────────────────────

  /// Streams members of a room `rooms/{roomId}/members`.
  Stream<List<RoomMemberModel>> getRoomMembersStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => RoomMemberModel.fromFirestore(doc)).toList());
  }

  /// Realtime stream alias for room members.
  Stream<List<RoomMemberModel>> watchRoomMembers(String roomId) {
    return getRoomMembersStream(roomId);
  }

  /// Updates current user's realtime location snapshot in their room member document.
  Future<void> updateMemberLocation({
    required String roomId,
    required String uid,
    required double latitude,
    required double longitude,
  }) async {
    final memberDoc = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(uid);

    await memberDoc.set({
      'currentLocation': GeoPoint(latitude, longitude),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Fetches members list once.
  Future<List<RoomMemberModel>> getRoomMembers(String roomId) async {
    final snap = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .get();
    return snap.docs.map((doc) => RoomMemberModel.fromFirestore(doc)).toList();
  }

  // ── Join Room (Pendamping & Jamaah) ─────────────────────────────────────────

  /// Joins a room using only its 6-character unique code.
  /// Enforces:
  /// 1. User cannot join if they already have an active room (1-room-per-user).
  /// 2. If user is Pendamping, room cannot already have an active pendamping.
  Future<RoomModel> joinRoomByCode({
    required String roomCode,
    required String uid,
    required String userName,
    required String role,
  }) async {
    final normalizedCode = roomCode.trim().toUpperCase();
    if (normalizedCode.isEmpty) {
      throw const RoomException('Kode room wajib diisi');
    }

    // 1. Verify user doesn't already have an active room
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final existingRoomId = userDoc.data()?['activeRoomId'] as String?;
    if (existingRoomId != null && existingRoomId.trim().isNotEmpty) {
      throw const RoomException('Anda sudah terdaftar dalam room lain. Setiap pengguna hanya boleh memiliki 1 room aktif.');
    }

    // 2. Query by room code
    final querySnap = await _firestore
        .collection('rooms')
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (querySnap.docs.isEmpty) {
      throw const RoomNotFoundException('Kode room tidak ditemukan. Silakan periksa kembali kode Anda.');
    }

    final roomDoc = querySnap.docs.first;
    final roomData = roomDoc.data();
    final realName = (roomData['name'] as String?)?.trim() ?? '';
    final isActive = (roomData['isActive'] as bool?) ?? true;

    if (!isActive) {
      throw const RoomInactiveException('Room ini sedang nonaktif dan tidak dapat menerima anggota baru.');
    }

    final roomId = roomDoc.id;
    final normalizedRole = role.trim().toLowerCase();

    // 3. For Pendamping: verify room does not already have an active pendamping
    if (normalizedRole == 'pendamping') {
      final existingPendampingId = roomData['pendampingId'] as String?;
      if (existingPendampingId != null && existingPendampingId.isNotEmpty && existingPendampingId != uid) {
        throw const RoomException('Room ini sudah memiliki Pendamping aktif. Tidak dapat bergabung sebagai pendamping kedua.');
      }
      final membersSnap = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .where('role', isEqualTo: 'pendamping')
          .limit(1)
          .get();
      if (membersSnap.docs.isNotEmpty && membersSnap.docs.first.id != uid) {
        throw const RoomException('Room ini sudah memiliki Pendamping aktif.');
      }
    }

    final memberRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(uid);
    final userRef = _firestore.collection('users').doc(uid);

    final batch = _firestore.batch();
    batch.set(memberRef, {
      'uid': uid,
      'name': userName.trim(),
      'role': normalizedRole,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.update(userRef, {'activeRoomId': roomId});

    if (normalizedRole == 'pendamping') {
      batch.update(_firestore.collection('rooms').doc(roomId), {
        'pendampingId': uid,
      });
    }

    await batch.commit();

    final isPendamping = normalizedRole == 'pendamping';
    await logActivity(
      type: ActivityType.memberJoined,
      title: isPendamping ? 'Pendamping Bergabung' : 'Jamaah Bergabung',
      description: '$userName bergabung ke $realName ($normalizedCode) sebagai ${isPendamping ? 'Pendamping' : 'Jamaah'}.',
      roomId: roomId,
      roomName: realName,
      userId: uid,
      userName: userName,
      role: role,
    );

    return RoomModel.fromFirestore(roomDoc);
  }

  /// Validates and joins a user into a room via atomic batch write (backwards compatible).
  Future<RoomModel> joinRoom({
    String? roomName,
    required String roomCode,
    required String uid,
    required String userName,
    required String role,
  }) async {
    return joinRoomByCode(
      roomCode: roomCode,
      uid: uid,
      userName: userName,
      role: role,
    );
  }

  // ── Keluar Room (Leave Room) ───────────────────────────────────────────────

  /// Allows a member (Jamaah or Pendamping) to leave their active room.
  Future<void> leaveRoom({
    required String roomId,
    required String uid,
    required String userName,
    required String role,
    String? roomName,
  }) async {
    final memberRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(uid);
    final userRef = _firestore.collection('users').doc(uid);

    final batch = _firestore.batch();
    batch.delete(memberRef);
    batch.update(userRef, {
      'activeRoomId': FieldValue.delete(),
      'sosActive': false,
    });

    await batch.commit();
    debugPrint('[RoomService] User $uid successfully left room $roomId');

    // Log Activity
    final isPendamping = role.trim().toLowerCase() == 'pendamping';
    await logActivity(
      type: ActivityType.memberLeft,
      title: isPendamping ? 'Pendamping Keluar' : 'Jamaah Keluar',
      description: '$userName telah keluar dari room ${roomName != null ? '"$roomName"' : roomId}.',
      roomId: roomId,
      roomName: roomName,
      userId: uid,
      userName: userName,
      role: role,
    );
  }

  // ── Keluarkan Jamaah (Remove Member by Pendamping / Admin) ─────────────────

  /// Removes a Jamaah from a room by Pendamping (managing that room) or Admin.
  Future<void> removeJamaahFromRoom({
    required String roomId,
    required String jamaahUid,
    required String actorUid,
    required String actorName,
    required String actorRole,
  }) async {
    // 1. Verify Room exists
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      throw const RoomException('Room tidak ditemukan.');
    }
    final roomData = roomDoc.data()!;
    final roomName = (roomData['name'] as String?)?.trim() ?? 'Room';
    final roomCode = (roomData['code'] as String?)?.trim().toUpperCase() ?? '';
    final pendampingId = roomData['pendampingId'] as String?;

    // 2. Validate actor authority (Admin or Pendamping of this room)
    final normalizedActorRole = actorRole.trim().toLowerCase();
    final isAdmin = normalizedActorRole == 'admin';
    final isAuthorizedPendamping = normalizedActorRole == 'pendamping' && pendampingId == actorUid;

    if (!isAdmin && !isAuthorizedPendamping) {
      throw const RoomException('Anda tidak memiliki kewenangan untuk mengeluarkan jamaah dari room ini.');
    }

    // 3. Verify target Jamaah is member of this room
    final memberRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(jamaahUid);
    final memberDoc = await memberRef.get();
    if (!memberDoc.exists) {
      throw const RoomException('Jamaah ini bukan merupakan anggota aktif dari room ini.');
    }
    final memberData = memberDoc.data()!;
    final jamaahName = (memberData['name'] as String?)?.trim() ?? 'Jamaah';

    // 4. Atomic batch write: remove member, reset user activeRoomId & sosActive, send notification
    final batch = _firestore.batch();
    batch.delete(memberRef);

    final userRef = _firestore.collection('users').doc(jamaahUid);
    batch.update(userRef, {
      'activeRoomId': FieldValue.delete(),
      'sosActive': false,
    });

    final notifDocRef = _firestore.collection('notifications').doc();
    final rolePrefix = isAdmin ? 'Admin' : 'Pendamping';
    final notif = AppNotificationModel(
      id: notifDocRef.id,
      recipientId: jamaahUid,
      type: 'room_removed',
      title: 'Anda dikeluarkan dari Room',
      message: 'Anda telah dikeluarkan dari Room "$roomName" ($roomCode) oleh $rolePrefix $actorName.',
      senderId: actorUid,
      senderRole: normalizedActorRole,
      senderName: actorName,
      scope: 'user',
      targetUserId: jamaahUid,
      targetRoomId: roomId,
      relatedId: roomId,
      isRead: false,
      createdAt: DateTime.now(),
      metadata: {
        'roomId': roomId,
        'roomName': roomName,
        'roomCode': roomCode,
        'jamaahUid': jamaahUid,
        'removedBy': actorUid,
        'removedByName': actorName,
        'removedByRole': normalizedActorRole,
        'removedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(notifDocRef, notif.toFirestore());

    await batch.commit();
    debugPrint('[RoomService] Jamaah $jamaahUid removed from room $roomId by $actorName ($actorRole)');

    // 5. Log Activity
    await logActivity(
      type: ActivityType.memberLeft,
      title: 'Jamaah Dikeluarkan dari Room',
      description: '$jamaahName telah dikeluarkan dari room "$roomName" ($roomCode) oleh $rolePrefix $actorName.',
      roomId: roomId,
      roomName: roomName,
      userId: jamaahUid,
      userName: jamaahName,
      role: 'jamaah',
    );
  }

  // ── Tambah Jamaah (By Pendamping) ──────────────────────────────────────────

  /// Allows a Pendamping of an active room to add an unassigned Jamaah.
  Future<void> addJamaahToRoom({
    required String roomId,
    required String jamaahUid,
    required String jamaahName,
  }) async {
    // 1. Verify target user
    final targetDoc = await _firestore.collection('users').doc(jamaahUid).get();
    if (!targetDoc.exists) {
      throw const RoomException('Data jamaah tidak ditemukan.');
    }

    final data = targetDoc.data()!;
    final role = (data['role'] as String?) ?? 'jamaah';
    if (role != 'jamaah') {
      throw const RoomException('User ini bukan merupakan Jamaah.');
    }

    final existingRoomId = data['activeRoomId'] as String?;
    if (existingRoomId != null && existingRoomId.isNotEmpty && existingRoomId != roomId) {
      throw const RoomException('Jamaah ini sudah terdaftar di room lain.');
    }

    // 2. Atomic batch: add to members & update activeRoomId
    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(jamaahUid);
    final userRef = _firestore.collection('users').doc(jamaahUid);

    batch.set(memberRef, {
      'uid': jamaahUid,
      'name': jamaahName.trim(),
      'role': 'jamaah',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {'activeRoomId': roomId});

    await batch.commit();
    debugPrint('[RoomService] Jamaah $jamaahUid added to room $roomId');

    await logActivity(
      type: ActivityType.memberJoined,
      title: 'Jamaah Ditambahkan',
      description: '$jamaahName ditambahkan ke room oleh pendamping.',
      roomId: roomId,
      userId: jamaahUid,
      userName: jamaahName,
      role: 'jamaah',
    );
  }

  /// Sends an invitation to a Jamaah by registered email.
  /// Generates a pending invitation in `invitations` and creates a notification in `notifications`.
  Future<RoomInvitationModel> inviteJamaahByEmail({
    required String roomId,
    required String email,
    required String currentPendampingUid,
    required String currentPendampingName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw const RoomException('Format email tidak valid. Masukkan email yang benar.');
    }

    // 1. Verify active room exists and is active
    final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
    if (!roomDoc.exists) {
      throw const RoomException('Room tidak ditemukan atau telah dihapus.');
    }
    final roomData = roomDoc.data()!;
    final roomName = (roomData['name'] as String?)?.trim() ?? 'Room';
    final roomCode = (roomData['code'] as String?)?.trim().toUpperCase() ?? '';
    final isActive = (roomData['isActive'] as bool?) ?? true;
    if (!isActive) {
      throw const RoomException('Room ini sedang nonaktif dan tidak dapat menerima anggota baru.');
    }

    // 2. Query user by email
    final querySnap = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (querySnap.docs.isEmpty) {
      throw RoomException('Email "$normalizedEmail" belum terdaftar di sistem HajiCare.');
    }

    final targetDoc = querySnap.docs.first;
    final targetUid = targetDoc.id;
    final data = targetDoc.data();

    // 3. Validation: Pendamping adding self
    if (targetUid == currentPendampingUid) {
      throw const RoomException('Anda tidak dapat mengundang diri sendiri sebagai Jamaah.');
    }

    // 4. Validation: User role must be jamaah
    final role = (data['role'] as String?)?.toLowerCase() ?? 'jamaah';
    if (role != 'jamaah') {
      throw RoomException('Akun ini terdaftar sebagai ${role.toUpperCase()}, bukan sebagai Jamaah.');
    }

    // 5. Validation: User already in this room
    final existingMemberDoc = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(targetUid)
        .get();

    if (existingMemberDoc.exists) {
      throw const RoomException('Jamaah ini sudah berada di dalam room ini.');
    }

    // 6. Validation: User already in another room
    final existingRoomId = data['activeRoomId'] as String?;
    if (existingRoomId != null && existingRoomId.isNotEmpty && existingRoomId != roomId) {
      throw const RoomException('Jamaah ini sudah terdaftar di room lain.');
    }

    // 7. Validation: Check for existing pending invitation
    final pendingInvSnap = await _firestore
        .collection('invitations')
        .where('roomId', isEqualTo: roomId)
        .where('toUserId', isEqualTo: targetUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (pendingInvSnap.docs.isNotEmpty) {
      throw const RoomException('Undangan sudah pernah dikirimkan ke Jamaah ini dan sedang menunggu respons.');
    }

    final invDocRef = _firestore.collection('invitations').doc();
    final invitation = RoomInvitationModel(
      id: invDocRef.id,
      roomId: roomId,
      roomName: roomName,
      roomCode: roomCode,
      fromUserId: currentPendampingUid,
      fromUserName: currentPendampingName,
      toUserId: targetUid,
      toUserEmail: normalizedEmail,
      status: InvitationStatus.pending,
      createdAt: DateTime.now(),
    );

    final notifDocRef = _firestore.collection('notifications').doc();
    final notif = AppNotificationModel(
      id: notifDocRef.id,
      recipientId: targetUid,
      type: 'room_invitation',
      title: 'Undangan Masuk Room',
      message: '$currentPendampingName mengundang Anda bergabung ke "$roomName" ($roomCode).',
      relatedId: invDocRef.id,
      isRead: false,
      createdAt: DateTime.now(),
      metadata: {
        'roomId': roomId,
        'roomName': roomName,
        'roomCode': roomCode,
        'pendampingName': currentPendampingName,
      },
    );

    final batch = _firestore.batch();
    batch.set(invDocRef, invitation.toFirestore());
    batch.set(notifDocRef, notif.toFirestore());
    await batch.commit();

    debugPrint('[RoomService] Invitation sent to $normalizedEmail for room $roomId');

    await logActivity(
      type: ActivityType.memberJoined,
      title: 'Undangan Room Dikirim',
      description: 'Undangan dikirim ke $normalizedEmail untuk bergabung ke "$roomName".',
      roomId: roomId,
      roomName: roomName,
      userId: targetUid,
      userName: currentPendampingName,
      role: 'pendamping',
    );

    return invitation;
  }

  /// Backward compatible wrapper for legacy calls.
  Future<void> addJamaahByEmail({
    required String roomId,
    required String email,
    required String currentPendampingUid,
    String? currentPendampingName,
  }) async {
    await inviteJamaahByEmail(
      roomId: roomId,
      email: email,
      currentPendampingUid: currentPendampingUid,
      currentPendampingName: currentPendampingName ?? 'Pendamping',
    );
  }

  /// Accepts an invitation atomically using a Firestore transaction:
  /// 1. Verifies caller does not already have an active room.
  /// 2. Reads invitation, user, and target room documents.
  /// 3. Validates invitation is pending and belongs to this user.
  /// 4. Validates target room exists, is active (`isActive == true`), and not deleted.
  /// 5. If target room is missing or inactive/deleted, marks invitation as 'expired' and aborts join.
  /// 6. If valid, adds user to room members, sets activeRoomId, and marks invitation as 'accepted'.
  Future<String> acceptInvitation({
    required String invitationId,
    required String uid,
    required String userName,
  }) async {
    final invRef = _firestore.collection('invitations').doc(invitationId);
    final userRef = _firestore.collection('users').doc(uid);

    String resolvedRoomId = '';
    String resolvedRoomName = 'Room';

    final result = await _firestore.runTransaction<_AcceptInvitationStatus>((transaction) async {
      // ── READS (Must precede all writes in Firestore transactions) ───────────
      final invSnap = await transaction.get(invRef);
      if (!invSnap.exists) {
        throw const RoomException('Undangan tidak ditemukan.');
      }
      final invData = invSnap.data()!;
      final status = (invData['status'] as String?)?.toLowerCase();
      if (status != 'pending') {
        throw RoomException('Undangan ini sudah tidak aktif ($status).');
      }
      if (invData['toUserId'] != uid) {
        throw const RoomException('Undangan ini bukan ditujukan untuk akun Anda.');
      }

      final roomId = (invData['roomId'] as String?)?.trim() ?? '';
      resolvedRoomId = roomId;
      resolvedRoomName = (invData['roomName'] as String?)?.trim() ?? 'Room';

      if (roomId.isEmpty) {
        transaction.update(invRef, {
          'status': 'expired',
          'expiredAt': FieldValue.serverTimestamp(),
          'expiredReason': 'invalid_room_id',
        });
        return _AcceptInvitationStatus.staleRoom;
      }

      // 2. Read User Doc (ensure user has no active room)
      final userSnap = await transaction.get(userRef);
      final currentRoom = (userSnap.data()?['activeRoomId'] as String?)?.trim();
      if (currentRoom != null && currentRoom.isNotEmpty) {
        throw const RoomException(
          'Anda sudah memiliki Room aktif. Setiap jamaah hanya boleh memiliki 1 room. Silakan keluar dari room lama Anda terlebih dahulu.',
        );
      }

      // 3. Read Room Doc
      final roomRef = _firestore.collection('rooms').doc(roomId);
      final roomSnap = await transaction.get(roomRef);

      // ── VALIDATE ROOM EXISTENCE AND ACTIVE STATUS ──────────────────────────
      final roomExists = roomSnap.exists;
      final roomData = roomExists ? roomSnap.data() : null;
      final isRoomActive = roomExists && (roomData?['isActive'] as bool? ?? true);
      final isDeleted = roomExists && (roomData?['status'] as String?)?.toLowerCase() == 'deleted';

      if (!roomExists || !isRoomActive || isDeleted) {
        // Mark invitation as expired within transaction
        transaction.update(invRef, {
          'status': 'expired',
          'expiredAt': FieldValue.serverTimestamp(),
          'expiredReason': 'room_deleted',
        });
        return _AcceptInvitationStatus.staleRoom;
      }

      resolvedRoomName = (roomData?['name'] as String?)?.trim() ?? resolvedRoomName;

      // ── WRITES (Only executed when room is active & valid) ──────────────────
      // 1. Update invitation status to accepted
      transaction.update(invRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // 2. Add to room members subcollection
      final memberRef = roomRef.collection('members').doc(uid);
      transaction.set(memberRef, {
        'uid': uid,
        'name': userName,
        'role': 'jamaah',
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update user activeRoomId
      transaction.update(userRef, {
        'activeRoomId': roomId,
      });

      return _AcceptInvitationStatus.success;
    });

    // Check transaction result
    if (result == _AcceptInvitationStatus.staleRoom) {
      throw const StaleInvitationException('Room yang mengirim undangan ini sudah tidak tersedia.');
    }

    // ── POST-TRANSACTION CLEANUP & LOGGING ────────────────────────────────────
    try {
      final notifs = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('relatedId', isEqualTo: invitationId)
          .get();
      final batch = _firestore.batch();
      for (final doc in notifs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[RoomService] Non-critical notification cleanup error: $e');
    }

    try {
      await logActivity(
        type: ActivityType.memberJoined,
        title: 'Undangan Diterima',
        description: '$userName menerima undangan dan bergabung ke room "$resolvedRoomName".',
        roomId: resolvedRoomId,
        roomName: resolvedRoomName,
        userId: uid,
        userName: userName,
        role: 'jamaah',
      );
    } catch (e) {
      debugPrint('[RoomService] Non-critical activity log error: $e');
    }

    return resolvedRoomId;
  }

  /// Rejects an invitation and marks notification as read.
  Future<void> rejectInvitation({
    required String invitationId,
    required String uid,
  }) async {
    final invDoc = await _firestore.collection('invitations').doc(invitationId).get();
    if (!invDoc.exists) return;

    final batch = _firestore.batch();
    batch.update(invDoc.reference, {
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    final notifs = await _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .where('relatedId', isEqualTo: invitationId)
        .get();
    for (final doc in notifs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// Updates safe radius in `rooms/{roomId}` document.
  Future<void> updateSafeRadius({
    required String roomId,
    required double radius,
  }) async {
    if (radius <= 0 || radius > 10000) {
      throw const RoomException('Radius harus berupa angka positif hingga maksimal 10.000 meter.');
    }
    await _firestore.collection('rooms').doc(roomId).update({
      'safeRadius': radius,
    });
  }

  /// Streams pending invitations for a specific user.
  Stream<List<RoomInvitationModel>> getPendingInvitationsStream(String uid) {
    return _firestore
        .collection('invitations')
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => RoomInvitationModel.fromFirestore(d)).toList());
  }

  /// Streams notifications for a user, sorted newest first.
  Stream<List<AppNotificationModel>> getUserNotificationsStream(String uid) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map((d) => AppNotificationModel.fromFirestore(d)).toList();
          items.sort((a, b) {
            final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tB.compareTo(tA);
          });
          return items;
        });
  }

  /// Marks a notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Responds to an SOS event as Pendamping.
  Future<void> respondToSos({
    required String eventId,
    required String pendampingUid,
    required String pendampingName,
  }) async {
    await _firestore.collection('sos_events').doc(eventId).update({
      'status': 'direspons',
      'respondedBy': pendampingUid,
      'respondedByName': pendampingName,
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Resolves an active SOS event in Firestore with status 'selesai'.
  Future<void> resolveSos({
    required String userId,
    String? roomId,
    String? eventId,
    String? resolvedByUid,
  }) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('users').doc(userId), {'sosActive': false});

    if (roomId != null && roomId.isNotEmpty) {
      final memberRef = _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(userId);
      batch.set(memberRef, {'sosActive': false}, SetOptions(merge: true));
    }

    final updateData = <String, dynamic>{
      'status': 'selesai',
      'resolvedAt': FieldValue.serverTimestamp(),
    };
    if (resolvedByUid != null) {
      updateData['resolvedBy'] = resolvedByUid;
    }

    if (eventId != null && eventId.isNotEmpty) {
      batch.update(_firestore.collection('sos_events').doc(eventId), updateData);
    } else {
      final activeSosQuery = await _firestore
          .collection('sos_events')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in activeSosQuery.docs) {
        batch.update(doc.reference, updateData);
      }

      final baruSosQuery = await _firestore
          .collection('sos_events')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'baru')
          .get();

      for (final doc in baruSosQuery.docs) {
        batch.update(doc.reference, updateData);
      }
    }

    await batch.commit();
  }

  /// Fetches Jamaah accounts that currently do not have an activeRoomId.
  Future<List<JamaahData>> getAvailableJamaahList() async {
    final query = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'jamaah')
        .get();

    final unassigned = <JamaahData>[];
    for (final doc in query.docs) {
      final activeRoom = doc.data()['activeRoomId'] as String?;
      if (activeRoom == null || activeRoom.isEmpty) {
        unassigned.add(JamaahData.fromFirestore(doc));
      }
    }
    return unassigned;
  }

  // ── Command Center Realtime Data Streams ───────────────────────────────────

  /// Streams recent operational activities for Admin Command Center.
  Stream<List<ActivityModel>> getRecentActivitiesStream({int limit = 15}) {
    return _firestore
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ActivityModel.fromFirestore(doc)).toList());
  }

  /// Logs an activity entry to `activities` collection.
  Future<void> logActivity({
    required ActivityType type,
    required String title,
    required String description,
    String? roomId,
    String? roomName,
    String? userId,
    String? userName,
    String? role,
  }) async {
    try {
      final act = ActivityModel(
        id: '',
        type: type,
        title: title,
        description: description,
        roomId: roomId,
        roomName: roomName,
        userId: userId,
        userName: userName,
        role: role,
        timestamp: DateTime.now(),
      );
      await _firestore.collection('activities').add(act.toFirestore());
    } catch (e) {
      debugPrint('[RoomService] Error logging activity: $e');
    }
  }

  /// Streams active SOS events from `sos_events`.
  Stream<List<Map<String, dynamic>>> getActiveSosEventsStream() {
    return _firestore
        .collection('sos_events')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Streams global member breakdown (total jamaah and pendamping).
  Stream<Map<String, int>> getGlobalMemberCountsStream() {
    return _firestore.collection('users').snapshots().map((snap) {
      int jamaah = 0;
      int pendamping = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final role = (data['role'] as String?)?.toLowerCase();
        if (role == 'jamaah') {
          jamaah++;
        } else if (role == 'pendamping') {
          pendamping++;
        }
      }
      return {'jamaah': jamaah, 'pendamping': pendamping};
    });
  }

  /// Streams breakdown of member counts (jamaah, pendamping, SOS) per room.
  Stream<Map<String, Map<String, int>>> getAllRoomMemberBreakdownStream() {
    return _firestore.collection('users').snapshots().map((snap) {
      final breakdown = <String, Map<String, int>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final activeRoomId = data['activeRoomId'] as String?;
        final role = (data['role'] as String?)?.toLowerCase();
        if (activeRoomId != null && activeRoomId.isNotEmpty) {
          breakdown.putIfAbsent(activeRoomId, () => {'jamaah': 0, 'pendamping': 0, 'sos': 0});
          if (role == 'jamaah') {
            breakdown[activeRoomId]!['jamaah'] = (breakdown[activeRoomId]!['jamaah'] ?? 0) + 1;
          } else if (role == 'pendamping') {
            breakdown[activeRoomId]!['pendamping'] = (breakdown[activeRoomId]!['pendamping'] ?? 0) + 1;
          }
          if (data['sosActive'] == true) {
            breakdown[activeRoomId]!['sos'] = (breakdown[activeRoomId]!['sos'] ?? 0) + 1;
          }
        }
      }
      return breakdown;
    });
  }
}
