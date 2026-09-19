import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending,
  accepted,
  rejected,
  expired;

  String get value => name;

  static InvitationStatus fromString(String? str) {
    switch (str?.toLowerCase()) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      case 'expired':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
    }
  }
}

class RoomInvitationModel {
  final String id;
  final String roomId;
  final String roomName;
  final String? roomCode;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserEmail;
  final InvitationStatus status;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final DateTime? expiredAt;
  final String? expiredReason;

  const RoomInvitationModel({
    required this.id,
    required this.roomId,
    required this.roomName,
    this.roomCode,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserEmail,
    this.status = InvitationStatus.pending,
    this.createdAt,
    this.respondedAt,
    this.expiredAt,
    this.expiredReason,
  });

  factory RoomInvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? createdAt;
    if (data['createdAt'] is Timestamp) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    DateTime? respondedAt;
    if (data['respondedAt'] is Timestamp) {
      respondedAt = (data['respondedAt'] as Timestamp).toDate();
    }

    DateTime? expiredAt;
    if (data['expiredAt'] is Timestamp) {
      expiredAt = (data['expiredAt'] as Timestamp).toDate();
    }

    return RoomInvitationModel(
      id: doc.id,
      roomId: data['roomId'] as String? ?? '',
      roomName: data['roomName'] as String? ?? 'Room',
      roomCode: data['roomCode'] as String?,
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUserName: data['fromUserName'] as String? ?? 'Pendamping',
      toUserId: data['toUserId'] as String? ?? '',
      toUserEmail: data['toUserEmail'] as String? ?? '',
      status: InvitationStatus.fromString(data['status'] as String?),
      createdAt: createdAt,
      respondedAt: respondedAt,
      expiredAt: expiredAt,
      expiredReason: data['expiredReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      if (roomCode != null) 'roomCode': roomCode,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserEmail': toUserEmail,
      'status': status.value,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (respondedAt != null) 'respondedAt': Timestamp.fromDate(respondedAt!),
      if (expiredAt != null) 'expiredAt': Timestamp.fromDate(expiredAt!),
      if (expiredReason != null) 'expiredReason': expiredReason,
    };
  }
}
