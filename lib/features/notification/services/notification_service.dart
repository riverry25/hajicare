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
}
