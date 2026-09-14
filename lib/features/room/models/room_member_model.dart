import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a member inside `rooms/{roomId}/members/{uid}`.
class RoomMemberModel {
  final String uid;
  final String name;
  final String role;
  final DateTime? joinedAt;

  const RoomMemberModel({
    required this.uid,
    required this.name,
    required this.role,
    this.joinedAt,
  });

  bool get isPendamping => role.toLowerCase() == 'pendamping';
  bool get isJamaah => role.toLowerCase() == 'jamaah';
  bool get isAdmin => role.toLowerCase() == 'admin';

  factory RoomMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawTimestamp = data['joinedAt'];
    DateTime? joinedAt;
    if (rawTimestamp is Timestamp) {
      joinedAt = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      joinedAt = rawTimestamp;
    }

    return RoomMemberModel(
      uid: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Pengguna',
      role: (data['role'] as String?)?.trim().toLowerCase() ?? 'jamaah',
      joinedAt: joinedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name.trim(),
      'role': role.trim().toLowerCase(),
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomMemberModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
