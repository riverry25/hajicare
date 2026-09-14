import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/models/jamaah_data.dart';
import '../models/activity_model.dart';
import '../models/room_model.dart';
import '../models/room_member_model.dart';

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

  /// Validates and joins a user into a room via atomic batch write.
  Future<RoomModel> joinRoom({
    required String roomName,
    required String roomCode,
    required String uid,
    required String userName,
    required String role,
  }) async {
    final normalizedCode = roomCode.trim().toUpperCase();
    final normalizedName = roomName.trim();

    if (normalizedCode.isEmpty || normalizedName.isEmpty) {
      throw const RoomException('Nama room dan Kode room wajib diisi');
    }

    // 1. Query by room code
    final querySnap = await _firestore
        .collection('rooms')
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (querySnap.docs.isEmpty) {
      throw const RoomNotFoundException('Kode room tidak ditemukan. Silakan periksa kembali.');
    }

    final roomDoc = querySnap.docs.first;
    final roomData = roomDoc.data();
    final realName = (roomData['name'] as String?)?.trim() ?? '';
    final isActive = (roomData['isActive'] as bool?) ?? true;

    // 2. Validate room name (case-insensitive)
    if (realName.toLowerCase() != normalizedName.toLowerCase()) {
      throw const InvalidRoomNameException(
        'Nama room tidak cocok dengan kode yang dimasukkan.',
      );
    }

    // 3. Validate active status
    if (!isActive) {
      throw const RoomInactiveException(
        'Room ini sedang nonaktif dan tidak dapat menerima anggota baru.',
      );
    }

    final roomId = roomDoc.id;
    final memberRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(uid);

    final userRef = _firestore.collection('users').doc(uid);

    // 4. Atomic WriteBatch: set membership + update user.activeRoomId
    final batch = _firestore.batch();

    final memberPayload = {
      'uid': uid,
      'name': userName.trim(),
      'role': role.trim().toLowerCase(),
      'joinedAt': FieldValue.serverTimestamp(),
    };

    batch.set(memberRef, memberPayload, SetOptions(merge: true));
    batch.update(userRef, {'activeRoomId': roomId});

    await batch.commit();
    debugPrint('[RoomService] User $uid successfully joined room $roomId');

    // Log Activity
    final isPendamping = role.trim().toLowerCase() == 'pendamping';
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

  /// Allows a Pendamping of an active room to add a Jamaah by their registered email.
  Future<void> addJamaahByEmail({
    required String roomId,
    required String email,
    required String currentPendampingUid,
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
      throw RoomException('Email "$normalizedEmail" tidak ditemukan terdaftar di sistem HajiCare.');
    }

    final targetDoc = querySnap.docs.first;
    final targetUid = targetDoc.id;
    final data = targetDoc.data();

    // 3. Validation: Pendamping adding self
    if (targetUid == currentPendampingUid) {
      throw const RoomException('Anda tidak dapat menambahkan diri sendiri sebagai Jamaah.');
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

    final rawName = data['name'] as String? ?? data['displayName'] as String? ?? normalizedEmail.split('@').first;
    final jamaahName = rawName.trim().isNotEmpty ? rawName.trim() : 'Jamaah';

    // 7. Atomic batch write: add to members & update activeRoomId
    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(targetUid);
    final userRef = _firestore.collection('users').doc(targetUid);

    batch.set(memberRef, {
      'uid': targetUid,
      'name': jamaahName,
      'role': 'jamaah',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.update(userRef, {'activeRoomId': roomId});

    await batch.commit();
    debugPrint('[RoomService] Jamaah $targetUid ($normalizedEmail) added to room $roomId');

    // 8. Log activity
    await logActivity(
      type: ActivityType.memberJoined,
      title: 'Jamaah Ditambahkan',
      description: '$jamaahName ($normalizedEmail) ditambahkan ke room "$roomName" oleh pendamping.',
      roomId: roomId,
      roomName: roomName,
      userId: targetUid,
      userName: jamaahName,
      role: 'jamaah',
    );
  }

  /// Resolves an active SOS event in Firestore
  Future<void> resolveSos({
    required String userId,
    String? roomId,
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

    // Also update active sos_events for this user
    final activeSosQuery = await _firestore
        .collection('sos_events')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in activeSosQuery.docs) {
      batch.update(doc.reference, {
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
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
