import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/trusted_backend_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    TrustedBackendService? backend,
  }) : _providedFirestore = firestore,
       _providedFirebaseAuth = firebaseAuth,
       _providedBackend = backend;

  static const int historyWindow = 100;

  final FirebaseFirestore? _providedFirestore;
  final FirebaseAuth? _providedFirebaseAuth;
  final TrustedBackendService? _providedBackend;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _firebaseAuth =>
      _providedFirebaseAuth ?? FirebaseAuth.instance;
  TrustedBackendService get _backend =>
      _providedBackend ?? TrustedBackendService();

  Future<String> sendPickupRequest({
    required String roomId,
    required String pendampingUid,
    required String notes,
    double? latitude,
    double? longitude,
  }) async {
    final result = await _backend.call('sendPickupRequest', {
      'roomId': roomId,
      'pendampingUid': pendampingUid,
      'notes': notes,
      'latitude': ?latitude,
      'longitude': ?longitude,
    });
    return (result['pendampingName'] as String?)?.trim().isNotEmpty == true
        ? (result['pendampingName'] as String).trim()
        : 'Pendamping';
  }

  /// Sends a chat-like message from a jamaah to one or every pendamping in
  /// their active room. Membership and recipient roles are verified by the
  /// trusted backend before any notification is created.
  Future<int> sendCompanionMessage({
    required String roomId,
    required String message,
    required bool sendToAll,
    required String kind,
    String? pendampingUid,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await _backend.call('sendCompanionMessage', {
        'roomId': roomId,
        'message': message,
        'sendToAll': sendToAll,
        'kind': kind,
        'pendampingUid': ?pendampingUid,
        'latitude': ?latitude,
        'longitude': ?longitude,
      });
      return (result['recipientCount'] as num?)?.toInt() ?? 0;
    } catch (error, stackTrace) {
      // Some deployments do not have the callable yet. The Firestore fallback
      // is protected by membership-aware Security Rules and creates the same
      // realtime notification documents consumed by pendamping devices.
      debugPrint(
        '[NotificationService] sendCompanionMessage callable failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return _sendCompanionMessageDirect(
        roomId: roomId,
        message: message,
        sendToAll: sendToAll,
        kind: kind,
        pendampingUid: pendampingUid,
        latitude: latitude,
        longitude: longitude,
      );
    }
  }

  Future<int> _sendCompanionMessageDirect({
    required String roomId,
    required String message,
    required bool sendToAll,
    required String kind,
    String? pendampingUid,
    double? latitude,
    double? longitude,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('Sesi masuk sudah berakhir. Silakan masuk kembali.');
    }

    final cleanRoomId = roomId.trim();
    final cleanMessage = message.trim();
    if (cleanRoomId.isEmpty || cleanMessage.isEmpty) {
      throw Exception('Rombongan dan pesan wajib diisi.');
    }
    if (cleanMessage.length > 500) {
      throw Exception('Pesan terlalu panjang. Maksimal 500 karakter.');
    }
    if (kind != 'info' && kind != 'message') {
      throw Exception('Jenis pesan tidak valid.');
    }

    final roomRef = _firestore.collection('rooms').doc(cleanRoomId);
    final roomSnapshot = await roomRef.get();
    final roomData = roomSnapshot.data();
    if (!roomSnapshot.exists ||
        roomData?['isActive'] != true ||
        roomData?['status'] == 'deleting') {
      throw Exception('Rombongan sudah tidak aktif.');
    }

    final senderSnapshot = await roomRef
        .collection('members')
        .doc(user.uid)
        .get();
    final senderData = senderSnapshot.data();
    if (!senderSnapshot.exists ||
        senderData?['role']?.toString().toLowerCase() != 'jamaah') {
      throw Exception('Anda bukan jamaah aktif dalam rombongan ini.');
    }
    final senderName = senderData?['name']?.toString().trim().isNotEmpty == true
        ? senderData!['name'].toString().trim()
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : 'Jamaah');

    final effectiveSendToAll = sendToAll || kind == 'info';
    final targets = <({String uid, String name})>[];
    if (effectiveSendToAll) {
      final membersSnapshot = await roomRef.collection('members').get();
      for (final doc in membersSnapshot.docs) {
        final data = doc.data();
        if (data['role']?.toString().toLowerCase() == 'pendamping' &&
            doc.id != user.uid) {
          final name = data['name']?.toString().trim();
          targets.add((
            uid: doc.id,
            name: name == null || name.isEmpty ? 'Pendamping' : name,
          ));
        }
      }
    } else {
      final targetUid = pendampingUid?.trim();
      if (targetUid == null || targetUid.isEmpty || targetUid == user.uid) {
        throw Exception('Pilih pendamping tujuan terlebih dahulu.');
      }
      final targetSnapshot = await roomRef
          .collection('members')
          .doc(targetUid)
          .get();
      final targetData = targetSnapshot.data();
      if (!targetSnapshot.exists ||
          targetData?['role']?.toString().toLowerCase() != 'pendamping') {
        throw Exception('Pendamping tidak ditemukan dalam rombongan ini.');
      }
      final targetName = targetData?['name']?.toString().trim();
      targets.add((
        uid: targetUid,
        name: targetName == null || targetName.isEmpty
            ? 'Pendamping'
            : targetName,
      ));
    }

    if (targets.isEmpty) {
      throw Exception('Belum ada pendamping aktif dalam rombongan ini.');
    }

    final notificationGroupId = _firestore.collection('notifications').doc().id;
    const chunkSize = 15;
    for (var start = 0; start < targets.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, targets.length);
      final batch = _firestore.batch();
      for (final target in targets.sublist(start, end)) {
        batch.set(_firestore.collection('notifications').doc(), {
          'notificationId': notificationGroupId,
          'recipientId': target.uid,
          'title': kind == 'info'
              ? 'Informasi dari $senderName'
              : 'Pesan dari $senderName',
          'message': cleanMessage,
          'type': kind == 'info' ? 'companion_info' : 'companion_message',
          'scope': effectiveSendToAll ? 'all_companions' : 'user',
          'targetUserId': target.uid,
          'targetRoomId': cleanRoomId,
          'senderId': user.uid,
          'senderName': senderName,
          'senderRole': 'jamaah',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            if (latitude != null && longitude != null) ...{
              'latitude': latitude,
              'longitude': longitude,
            },
            'includesLocation': latitude != null && longitude != null,
            'sendToAll': effectiveSendToAll,
          },
        });
      }
      await batch.commit();
    }

    return targets.length;
  }

  Future<int> sendNotification({
    required String title,
    required String message,
    required String senderUid,
    required String senderRole,
    required String senderName,
    required String scope,
    String? targetUserId,
    String? targetRoomId,
    String? targetMaktab,
    String? targetKloter,
    String type = 'announcement',
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    final scopeValue = targetMaktab ?? targetKloter;
    try {
      final result = await _backend.call('sendNotification', {
        'title': title,
        'message': message,
        'scope': scope,
        'type': type,
        'userId': ?targetUserId,
        'roomId': ?targetRoomId,
        'scopeValue': ?scopeValue,
      });
      return (result['recipientCount'] as num).toInt();
    } catch (error) {
      debugPrint(
        '[NotificationService] Backend sendNotification failed ($error), using direct Firestore fallback',
      );
      return _sendNotificationDirect(
        title: title,
        message: message,
        senderUid: senderUid,
        senderRole: senderRole,
        senderName: senderName,
        scope: scope,
        targetUserId: targetUserId,
        targetRoomId: targetRoomId,
        targetMaktab: targetMaktab,
        targetKloter: targetKloter,
        type: type,
        relatedId: relatedId,
        metadata: metadata,
      );
    }
  }

  Future<int> _sendNotificationDirect({
    required String title,
    required String message,
    required String senderUid,
    required String senderRole,
    required String senderName,
    required String scope,
    String? targetUserId,
    String? targetRoomId,
    String? targetMaktab,
    String? targetKloter,
    String type = 'announcement',
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    final List<String> targetIds = [];

    if (scope == 'user') {
      if (targetUserId == null || targetUserId.trim().isEmpty) {
        throw Exception('Penerima belum dipilih.');
      }
      targetIds.add(targetUserId.trim());
    } else if (scope == 'room') {
      if (targetRoomId == null || targetRoomId.trim().isEmpty) {
        throw Exception('Rombongan belum dipilih.');
      }
      final membersSnap = await _firestore
          .collection('rooms')
          .doc(targetRoomId.trim())
          .collection('members')
          .get();
      for (final doc in membersSnap.docs) {
        final uid = doc.id.trim();
        if (uid.isNotEmpty && uid != senderUid) {
          targetIds.add(uid);
        }
      }
    } else if (scope == 'maktab') {
      if (targetMaktab == null || targetMaktab.trim().isEmpty) {
        throw Exception('Maktab tujuan belum dipilih.');
      }
      final usersSnap = await _firestore
          .collection('users')
          .where('maktab', isEqualTo: targetMaktab.trim())
          .get();
      for (final doc in usersSnap.docs) {
        final uid = doc.id.trim();
        if (uid.isNotEmpty && uid != senderUid) {
          targetIds.add(uid);
        }
      }
    } else if (scope == 'kloter') {
      if (targetKloter == null || targetKloter.trim().isEmpty) {
        throw Exception('Kloter tujuan belum dipilih.');
      }
      final usersSnap = await _firestore
          .collection('users')
          .where('kloter', isEqualTo: targetKloter.trim())
          .get();
      for (final doc in usersSnap.docs) {
        final uid = doc.id.trim();
        if (uid.isNotEmpty && uid != senderUid) {
          targetIds.add(uid);
        }
      }
    } else {
      // Global scope: broadcast to all active users
      final usersSnap = await _firestore.collection('users').limit(500).get();
      for (final doc in usersSnap.docs) {
        final uid = doc.id.trim();
        if (uid.isNotEmpty && uid != senderUid) {
          targetIds.add(uid);
        }
      }
    }

    final uniqueTargets = targetIds.toSet().toList();
    if (uniqueTargets.isEmpty) {
      return 0;
    }

    const chunkSize = 400;
    for (int i = 0; i < uniqueTargets.length; i += chunkSize) {
      final end = (i + chunkSize > uniqueTargets.length)
          ? uniqueTargets.length
          : i + chunkSize;
      final chunk = uniqueTargets.sublist(i, end);
      final batch = _firestore.batch();
      for (final uid in chunk) {
        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, {
          'recipientId': uid,
          'title': title,
          'message': message,
          'type': type,
          'scope': scope,
          if (targetUserId != null && targetUserId.trim().isNotEmpty)
            'targetUserId': targetUserId.trim(),
          if (targetRoomId != null && targetRoomId.trim().isNotEmpty)
            'targetRoomId': targetRoomId.trim(),
          if (targetMaktab != null && targetMaktab.trim().isNotEmpty)
            'targetMaktab': targetMaktab.trim(),
          if (targetKloter != null && targetKloter.trim().isNotEmpty)
            'targetKloter': targetKloter.trim(),
          if (senderUid.isNotEmpty) 'senderId': senderUid,
          if (senderName.isNotEmpty) 'senderName': senderName,
          if (senderRole.isNotEmpty) 'senderRole': senderRole,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          if (relatedId != null && relatedId.trim().isNotEmpty)
            'relatedId': relatedId.trim(),
          'metadata': ?metadata,
        });
      }
      await batch.commit();
    }

    return uniqueTargets.length;
  }

  /// Bounded realtime window. Older history is intentionally not loaded until
  /// the product exposes an explicit pagination affordance.
  ///
  /// Documents soft-deleted by this user (uid appears in the `deletedBy`
  /// array field) are excluded from the stream so that other users who have
  /// not deleted the notification still see it.
  Stream<List<AppNotificationModel>> getUserNotificationsStream(String uid) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          // Sorting on-device keeps realtime delivery working even when the
          // optional composite index has not been deployed yet.
          final items =
              snapshot.docs
                  .where((doc) {
                    // Soft-delete filter: skip docs where this uid has been added
                    // to the `deletedBy` list by a previous clearAll call.
                    final data = doc.data();
                    final deletedBy = data['deletedBy'];
                    if (deletedBy is List && deletedBy.contains(uid)) {
                      return false;
                    }
                    return true;
                  })
                  .map(AppNotificationModel.fromFirestore)
                  .toList(growable: true)
                ..sort((a, b) {
                  final aTime =
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bTime =
                      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bTime.compareTo(aTime);
                });
          return items.length <= historyWindow
              ? List<AppNotificationModel>.unmodifiable(items)
              : List<AppNotificationModel>.unmodifiable(
                  items.take(historyWindow),
                );
        });
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (error) {
      debugPrint('[NotificationService] mark read failed: $error');
    }
  }

  Future<void> markAllAsRead(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .limit(historyWindow)
          .get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (error) {
      debugPrint('[NotificationService] mark all read failed: $error');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (error) {
      debugPrint('[NotificationService] delete notification failed: $error');
    }
  }

  /// Soft-deletes all notifications visible to [uid] by appending [uid] to
  /// the `deletedBy` array of every matching Firestore document.
  ///
  /// This is the correct multi-user pattern: the document remains intact for
  /// any other recipient who has not yet dismissed it. The stream listener
  /// already filters out docs whose `deletedBy` list contains the current uid.
  Future<void> clearAllNotificationsForUser(String uid) async {
    try {
      // Fetch the same bounded window the stream uses.
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .limit(historyWindow)
          .get();
      if (snapshot.docs.isEmpty) return;

      // Filter out docs already soft-deleted by this user to avoid
      // redundant writes.
      final toUpdate = snapshot.docs.where((doc) {
        final deletedBy = doc.data()['deletedBy'];
        return !(deletedBy is List && deletedBy.contains(uid));
      }).toList();
      if (toUpdate.isEmpty) return;

      const chunkSize = 400; // Firestore batch limit
      for (var i = 0; i < toUpdate.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, toUpdate.length);
        final batch = _firestore.batch();
        for (final doc in toUpdate.sublist(i, end)) {
          batch.update(doc.reference, {
            'deletedBy': FieldValue.arrayUnion([uid]),
          });
        }
        await batch.commit();
      }
    } catch (error) {
      debugPrint('[NotificationService] clearAll failed: $error');
    }
  }

  Future<void> deleteNotificationsForInvitation({
    required String invitationId,
    required String uid,
    String? roomId,
  }) async {
    try {
      await _firestore
          .collection('notifications')
          .doc('invitation_$invitationId')
          .delete();
    } catch (_) {}

    try {
      final query = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('relatedId', isEqualTo: invitationId)
          .limit(20)
          .get();
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    } catch (error) {
      debugPrint(
        '[NotificationService] deleteNotificationsForInvitation error: $error',
      );
    }

    if (roomId != null && roomId.isNotEmpty) {
      try {
        final query = await _firestore
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .where('targetRoomId', isEqualTo: roomId)
            .where('type', isEqualTo: 'room_invitation')
            .limit(20)
            .get();
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }
  }
}
