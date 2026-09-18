import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotificationModel {
  final String id;
  final String recipientId;
  final String type; // 'room_invitation', 'system', 'sos_alert', etc.
  final String title;
  final String message;
  final String? relatedId; // e.g. invitationId, roomId, or sosEventId
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  const AppNotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.isRead = false,
    this.createdAt,
    this.metadata,
  });

  factory AppNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    return AppNotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      relatedId: data['relatedId'] as String?,
      isRead: (data['isRead'] as bool?) ?? false,
      createdAt: createdAt,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'type': type,
      'title': title,
      'message': message,
      if (relatedId != null) 'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
