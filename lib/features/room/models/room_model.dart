import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a monitoring Room in HajiCare.
/// Corresponds to Firestore document in `rooms/{roomId}`.
class RoomModel {
  final String id;
  final String name;
  final String code;
  final String createdBy;
  final DateTime? createdAt;
  final bool isActive;
  final int memberCount;

  const RoomModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    this.createdAt,
    this.isActive = true,
    this.memberCount = 0,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc, {int memberCount = 0}) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawTimestamp = data['createdAt'];
    DateTime? createdAt;
    if (rawTimestamp is Timestamp) {
      createdAt = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      createdAt = rawTimestamp;
    }

    return RoomModel(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      code: (data['code'] as String?)?.trim().toUpperCase() ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      createdAt: createdAt,
      isActive: (data['isActive'] as bool?) ?? true,
      memberCount: memberCount > 0 ? memberCount : ((data['memberCount'] as num?)?.toInt() ?? 0),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name.trim(),
      'code': code.trim().toUpperCase(),
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? code,
    String? createdBy,
    DateTime? createdAt,
    bool? isActive,
    int? memberCount,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code;

  @override
  int get hashCode => id.hashCode ^ code.hashCode;
}
