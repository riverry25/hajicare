import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/trusted_backend_service.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({
    FirebaseFirestore? firestore,
    TrustedBackendService? backend,
  }) : _providedFirestore = firestore,
       _providedBackend = backend;

  static const int historyWindow = 100;

  final FirebaseFirestore? _providedFirestore;
  final TrustedBackendService? _providedBackend;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;
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
  Stream<List<AppNotificationModel>> getUserNotificationsStream(String uid) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(historyWindow)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(AppNotificationModel.fromFirestore)
              .toList(growable: false),
        );
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
