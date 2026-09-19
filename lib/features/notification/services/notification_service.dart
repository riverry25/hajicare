import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({FirebaseFirestore? firestore})
    : _providedFirestore = firestore;

  final FirebaseFirestore? _providedFirestore;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  /// Sends notifications according to the specified scope and role authority.
  /// Uses a fan-out delivery pattern to ensure single-document recipient reads.
  Future<int> sendNotification({
    required String title,
    required String message,
    required String senderUid,
    required String senderRole,
    required String senderName,
    required String scope, // 'global', 'maktab', 'kloter', 'room', 'user'
    String? targetUserId,
    String? targetRoomId,
    String? targetMaktab,
    String? targetKloter,
    String type = 'announcement',
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    final normalizedRole = senderRole.trim().toLowerCase();
    final normalizedScope = scope.trim().toLowerCase();
    final cleanTitle = title.trim();
    final cleanMessage = message.trim();

    if (cleanTitle.isEmpty) {
      throw Exception('Isi judul pesan terlebih dahulu.');
    }
    if (cleanMessage.isEmpty) {
      throw Exception('Isi pesan terlebih dahulu.');
    }

    // ── Security validation for Pendamping ──────────────────────────────────
    if (normalizedRole == 'pendamping') {
      if (normalizedScope != 'room' && normalizedScope != 'user') {
        throw Exception(
          'Pendamping hanya dapat mengirim pesan ke rombongan yang dikelola.',
        );
      }
      if (targetRoomId == null || targetRoomId.isEmpty) {
        throw Exception('Pilih rombongan tujuan terlebih dahulu.');
      }

      // Verify that this pendamping owns/manages targetRoomId
      final roomDoc = await _firestore
          .collection('rooms')
          .doc(targetRoomId)
          .get();
      if (!roomDoc.exists) {
        throw Exception('Rombongan tujuan tidak ditemukan.');
      }
      final roomData = roomDoc.data()!;
      final roomPendampingId = roomData['pendampingId'] as String?;
      final roomPendampingIds =
          (roomData['pendampingIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final isManagingPendamping =
          roomPendampingId == senderUid ||
          roomPendampingIds.contains(senderUid);
      if (!isManagingPendamping) {
        throw Exception(
          'Anda hanya dapat mengirim pesan ke rombongan yang Anda kelola.',
        );
      }

      // If user scope, verify target user is member of this room
      if (normalizedScope == 'user') {
        if (targetUserId == null || targetUserId.isEmpty) {
          throw Exception('Pilih jamaah target terlebih dahulu.');
        }
        final memberDoc = await _firestore
            .collection('rooms')
            .doc(targetRoomId)
            .collection('members')
            .doc(targetUserId)
            .get();
        if (!memberDoc.exists) {
          throw Exception(
            'Jamaah tersebut tidak lagi berada dalam rombongan Anda.',
          );
        }
      }
    }

    // ── Recipient Resolution ────────────────────────────────────────────────
    final Set<String> recipientUids = {};

    switch (normalizedScope) {
      case 'user':
        if (targetUserId != null && targetUserId.isNotEmpty) {
          recipientUids.add(targetUserId);
        }
        break;

      case 'room':
        if (targetRoomId == null || targetRoomId.isEmpty) {
          throw Exception('Pilih rombongan tujuan terlebih dahulu.');
        }
        final membersSnap = await _firestore
            .collection('rooms')
            .doc(targetRoomId)
            .collection('members')
            .get();
        for (final doc in membersSnap.docs) {
          // Do not send to self
          if (doc.id != senderUid) {
            recipientUids.add(doc.id);
          }
        }
        break;

      case 'maktab':
        if (targetMaktab == null || targetMaktab.trim().isEmpty) {
          throw Exception('Pilih maktab tujuan terlebih dahulu.');
        }
        final maktabSnap = await _firestore
            .collection('users')
            .where('maktab', isEqualTo: targetMaktab.trim())
            .get();
        for (final doc in maktabSnap.docs) {
          if (doc.id != senderUid) {
            recipientUids.add(doc.id);
          }
        }
        break;

      case 'kloter':
        if (targetKloter == null || targetKloter.trim().isEmpty) {
          throw Exception('Pilih kloter tujuan terlebih dahulu.');
        }
        final kloterSnap = await _firestore
            .collection('users')
            .where('kloter', isEqualTo: targetKloter.trim())
            .get();
        for (final doc in kloterSnap.docs) {
          if (doc.id != senderUid) {
            recipientUids.add(doc.id);
          }
        }
        break;

      case 'global':
        if (normalizedRole != 'admin') {
          throw Exception(
            'Pesan untuk semua jamaah hanya dapat dikirim oleh pengelola utama.',
          );
        }
        final allUsersSnap = await _firestore.collection('users').get();
        for (final doc in allUsersSnap.docs) {
          if (doc.id != senderUid) {
            recipientUids.add(doc.id);
          }
        }
        break;

      default:
        throw Exception('Pilihan penerima tidak dikenali. Pilih kembali.');
    }

    if (recipientUids.isEmpty) {
      throw Exception('Belum ada penerima yang dapat menerima pesan ini.');
    }

    // ── Batched Fan-out Writes ──────────────────────────────────────────────
    final recipientList = recipientUids.toList();
    const batchChunkSize = 400; // Safe margin below 500 writes/batch

    for (int i = 0; i < recipientList.length; i += batchChunkSize) {
      final chunk = recipientList.sublist(
        i,
        (i + batchChunkSize > recipientList.length)
            ? recipientList.length
            : i + batchChunkSize,
      );

      final batch = _firestore.batch();
      for (final recipientId in chunk) {
        final docRef = _firestore.collection('notifications').doc();
        final notif = AppNotificationModel(
          id: docRef.id,
          recipientId: recipientId,
          type: type,
          title: cleanTitle,
          message: cleanMessage,
          senderId: senderUid,
          senderRole: normalizedRole,
          senderName: senderName,
          scope: normalizedScope,
          targetUserId: targetUserId,
          targetRoomId: targetRoomId,
          targetMaktab: targetMaktab,
          targetKloter: targetKloter,
          relatedId: relatedId,
          isRead: false,
          createdAt: DateTime.now(),
          metadata: metadata,
        );
        batch.set(docRef, notif.toFirestore());
      }
      await batch.commit();
    }

    debugPrint(
      '[NotificationService] Sent $type notification to ${recipientList.length} recipients (scope: $scope)',
    );
    return recipientList.length;
  }

  /// Streams notifications for a given user ordered by createdAt descending.
  Stream<List<AppNotificationModel>> getUserNotificationsStream(String uid) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((d) => AppNotificationModel.fromFirestore(d))
              .toList();
          items.sort((a, b) {
            final tA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tB.compareTo(tA);
          });
          return items;
        });
  }

  /// Marks a specific notification document as read.
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification read: $e');
    }
  }

  /// Marks all notifications for a user as read.
  Future<void> markAllAsRead(String uid) async {
    try {
      final snap = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (snap.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint(
        '[NotificationService] Error marking all notifications read: $e',
      );
    }
  }
}
