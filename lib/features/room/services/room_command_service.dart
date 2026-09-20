import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
/// Membership, invitation, room administration, and SOS changes attempt
/// callable Functions first. If backend functions are unreachable or not deployed,
/// operations fall back gracefully to direct authenticated Firestore transactions.
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
    return createRoomByPendamping(name: name);
  }

  Future<RoomModel> createRoomByPendamping({
    required String name,
    String? maktab,
    String? kloter,
  }) async {
    try {
      final result = await _backend.call('createRoom', {
        'name': name,
        'maktab': ?maktab,
        'kloter': ?kloter,
      });
      return await _loadCreatedRoom(result);
    } catch (error) {
      debugPrint(
        '[RoomCommandService] Backend createRoom failed ($error), using direct Firestore fallback',
      );
      return _createRoomDirect(name: name, maktab: maktab, kloter: kloter);
    }
  }

  Future<RoomModel> _createRoomDirect({
    required String name,
    String? maktab,
    String? kloter,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const RoomCommandException('Pengguna belum masuk.');
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const RoomCommandException('Nama rombongan tidak boleh kosong.');
    }

    // Generate unique 6-character room code (without confusing chars 0, 1, I, O)
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = math.Random();
    String code = '';
    for (int attempt = 0; attempt < 10; attempt++) {
      final buffer = StringBuffer();
      final len = attempt >= 8 ? 8 : 6;
      for (int i = 0; i < len; i++) {
        buffer.write(chars[random.nextInt(chars.length)]);
      }
      final candidate = buffer.toString();
      try {
        final existingCode =
            await _firestore.collection('roomCodes').doc(candidate).get();
        if (!existingCode.exists) {
          code = candidate;
          break;
        }
      } catch (_) {
        code = candidate;
        break;
      }
    }
    if (code.isEmpty) {
      code =
          'HJ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }

    final newRoomRef = _firestore.collection('rooms').doc();
    final creatorName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email?.trim().isNotEmpty == true
              ? user.email!.split('@').first
              : 'Pendamping');

    final batch = _firestore.batch();

    batch.set(newRoomRef, {
      'name': trimmedName,
      'code': code,
      'createdBy': user.uid,
      'createdByRole': 'pendamping',
      'pendampingId': user.uid,
      'pendampingIds': [user.uid],
      'safeRadius': 200.0,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'status': 'active',
      'memberCount': 1,
      if (maktab != null && maktab.trim().isNotEmpty) 'maktab': maktab.trim(),
      if (kloter != null && kloter.trim().isNotEmpty) 'kloter': kloter.trim(),
    });

    batch.set(_firestore.collection('roomCodes').doc(code), {
      'roomId': newRoomRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(newRoomRef.collection('members').doc(user.uid), {
      'uid': user.uid,
      'name': creatorName,
      'role': 'pendamping',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.set(_firestore.collection('users').doc(user.uid), {
      'activeRoomId': newRoomRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    return RoomModel(
      id: newRoomRef.id,
      name: trimmedName,
      code: code,
      createdBy: user.uid,
      createdByRole: 'pendamping',
      pendampingId: user.uid,
      pendampingIds: [user.uid],
      maktab: maktab,
      kloter: kloter,
      safeRadius: 200.0,
      createdAt: DateTime.now(),
      isActive: true,
      memberCount: 1,
    );
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
  }) async {
    try {
      await _backend.call('updateRoomSettings', {
        'roomId': roomId,
        'name': ?name,
        'maktab': ?maktab,
        'kloter': ?kloter,
        'safeRadius': ?safeRadius,
        'isActive': ?isActive,
      });
      return;
    } catch (backendError) {
      debugPrint(
        '[RoomCommandService] Backend updateRoomSettings failed ($backendError), using direct Firestore fallback',
      );
    }

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'name': ?name?.trim(),
      'maktab': ?maktab?.trim(),
      'kloter': ?kloter?.trim(),
      'safeRadius': ?safeRadius,
      'isActive': ?isActive,
    };
    await _firestore.collection('rooms').doc(roomId).update(updates);
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _backend.call('deleteRoom', {'roomId': roomId});
      return;
    } catch (backendError) {
      debugPrint(
        '[RoomCommandService] Backend deleteRoom failed ($backendError), using direct Firestore fallback',
      );
    }

    await _firestore.collection('rooms').doc(roomId).update({
      'isActive': false,
      'status': 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<RoomModel> joinRoomByCode(String roomCode) async {
    final cleanCode = roomCode.trim().toUpperCase();
    try {
      final result = await _backend.call('joinRoomByCode', {
        'roomCode': cleanCode,
      });
      final roomId = result['roomId'] as String?;
      if (roomId != null && roomId.isNotEmpty) {
        final room = await queries.getRoomById(roomId);
        if (room != null) return room;
      }
    } catch (backendError) {
      debugPrint(
        '[RoomCommandService] Backend joinRoomByCode failed ($backendError), using direct Firestore fallback',
      );
    }

    return _joinRoomDirect(cleanCode);
  }

  Future<RoomModel> _joinRoomDirect(String cleanCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const RoomCommandException('Pengguna belum masuk.');
    }

    // Step 1: Resolve roomId from roomCodes collection or rooms query
    String? targetRoomId;
    try {
      final codeDoc =
          await _firestore.collection('roomCodes').doc(cleanCode).get();
      if (codeDoc.exists) {
        targetRoomId = codeDoc.data()?['roomId'] as String?;
      }
    } catch (_) {}

    if (targetRoomId == null || targetRoomId.isEmpty) {
      final querySnap = await _firestore
          .collection('rooms')
          .where('code', isEqualTo: cleanCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (querySnap.docs.isNotEmpty) {
        targetRoomId = querySnap.docs.first.id;
      }
    }

    if (targetRoomId == null || targetRoomId.isEmpty) {
      throw const RoomCommandException(
        'Kode rombongan tidak ditemukan. Periksa kembali kode atau QR yang dipindai.',
      );
    }

    // Step 2: Fetch and validate Room
    final roomDoc =
        await _firestore.collection('rooms').doc(targetRoomId).get();
    if (!roomDoc.exists) {
      throw const RoomCommandException('Rombongan tidak ditemukan.');
    }
    final roomData = roomDoc.data() ?? {};
    if (roomData['isActive'] == false || roomData['status'] == 'deleting') {
      throw const RoomCommandException('Rombongan ini sudah tidak aktif.');
    }

    // Step 3: Get user profile details
    String memberName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : (user.email?.trim().isNotEmpty == true
              ? user.email!.split('@').first
              : 'Pengguna');
    String memberRole = 'jamaah';

    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final uData = userDoc.data() ?? {};
        final dbRole = (uData['role'] as String?)?.toLowerCase();
        if (dbRole == 'pendamping' || dbRole == 'petugas') {
          memberRole = 'pendamping';
        }
        final dbName = (uData['displayName'] ?? uData['name']) as String?;
        if (dbName != null && dbName.trim().isNotEmpty) {
          memberName = dbName.trim();
        }
      }
    } catch (_) {}

    // Step 4: Write membership, increment room memberCount, and update user activeRoomId
    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('rooms')
        .doc(targetRoomId)
        .collection('members')
        .doc(user.uid);

    batch.set(memberRef, {
      'uid': user.uid,
      'name': memberName,
      'role': memberRole,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final roomUpdate = <String, dynamic>{
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (memberRole == 'pendamping') {
      roomUpdate['pendampingIds'] = FieldValue.arrayUnion([user.uid]);
    }
    batch.update(_firestore.collection('rooms').doc(targetRoomId), roomUpdate);

    batch.set(_firestore.collection('users').doc(user.uid), {
      'activeRoomId': targetRoomId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    return RoomModel.fromFirestore(
      roomDoc,
      memberCount:
          ((roomData['memberCount'] as num?)?.toInt() ?? 0) + 1,
    );
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      await _backend.call('leaveRoom', {'roomId': roomId});
      return;
    } catch (backendError) {
      debugPrint(
        '[RoomCommandService] Backend leaveRoom failed ($backendError), using direct Firestore fallback',
      );
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();
    batch.delete(
      _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(user.uid),
    );
    batch.update(_firestore.collection('rooms').doc(roomId), {
      'memberCount': FieldValue.increment(-1),
      'pendampingIds': FieldValue.arrayRemove([user.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('users').doc(user.uid), {
      'activeRoomId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> removeJamaah({
    required String roomId,
    required String jamaahUid,
  }) async {
    try {
      await _backend.call('removeJamaah', {
        'roomId': roomId,
        'jamaahUid': jamaahUid,
      });
      return;
    } catch (backendError) {
      debugPrint(
        '[RoomCommandService] Backend removeJamaah failed ($backendError), using direct Firestore fallback',
      );
    }

    final batch = _firestore.batch();
    batch.delete(
      _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(jamaahUid),
    );
    batch.update(_firestore.collection('rooms').doc(roomId), {
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_firestore.collection('users').doc(jamaahUid), {
      'activeRoomId': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
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
    return _backend.call('transitionSos', {
      'action': action,
      'userId': userId,
      if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
    }).then((_) {});
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
