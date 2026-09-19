import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a monitoring Room in HajiCare.
/// Corresponds to Firestore document in `rooms/{roomId}`.
class RoomModel {
  final String id;
  final String name;
  final String code;
  final String createdBy;
  final String? createdByRole;
  final String? pendampingId;
  final String? maktab;
  final String? kloter;
  final double safeRadius;
  final DateTime? createdAt;
  final bool isActive;
  final int memberCount;

  const RoomModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    this.createdByRole,
    this.pendampingId,
    this.maktab,
    this.kloter,
    this.safeRadius = 200.0,
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

    final rawRadius = data['safeRadius'];
    double safeRadius = 200.0;
    if (rawRadius is num) {
      safeRadius = rawRadius.toDouble();
    }

    return RoomModel(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      code: (data['code'] as String?)?.trim().toUpperCase() ?? '',
      createdBy: (data['createdBy'] as String?) ?? '',
      createdByRole: data['createdByRole'] as String?,
      pendampingId: data['pendampingId'] as String?,
      maktab: data['maktab'] as String?,
      kloter: data['kloter'] as String?,
      safeRadius: safeRadius,
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
      if (createdByRole != null) 'createdByRole': createdByRole,
      if (pendampingId != null) 'pendampingId': pendampingId,
      if (maktab != null) 'maktab': maktab,
      if (kloter != null) 'kloter': kloter,
      'safeRadius': safeRadius,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? code,
    String? createdBy,
    String? createdByRole,
    String? pendampingId,
    String? maktab,
    String? kloter,
    double? safeRadius,
    DateTime? createdAt,
    bool? isActive,
    int? memberCount,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      createdByRole: createdByRole ?? this.createdByRole,
      pendampingId: pendampingId ?? this.pendampingId,
      maktab: maktab ?? this.maktab,
      kloter: kloter ?? this.kloter,
      safeRadius: safeRadius ?? this.safeRadius,
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
          code == other.code &&
          name == other.name &&
          maktab == other.maktab &&
          kloter == other.kloter &&
          safeRadius == other.safeRadius &&
          isActive == other.isActive &&
          memberCount == other.memberCount;

  @override
  int get hashCode => Object.hash(
        id,
        code,
        name,
        maktab,
        kloter,
        safeRadius,
        isActive,
        memberCount,
      );
}
