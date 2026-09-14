import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing a member inside `rooms/{roomId}/members/{uid}`.
class RoomMemberModel {
  final String uid;
  final String name;
  final String role;
  final DateTime? joinedAt;
  final GeoPoint? currentLocation;
  final DateTime? locationUpdatedAt;

  const RoomMemberModel({
    required this.uid,
    required this.name,
    required this.role,
    this.joinedAt,
    this.currentLocation,
    this.locationUpdatedAt,
  });

  bool get isPendamping => role.toLowerCase() == 'pendamping';
  bool get isJamaah => role.toLowerCase() == 'jamaah';
  bool get isAdmin => role.toLowerCase() == 'admin';

  double? get latitude => currentLocation?.latitude;
  double? get longitude => currentLocation?.longitude;
  bool get hasLocation => currentLocation != null;

  String getLocationStatus([DateTime? now]) {
    if (!hasLocation || locationUpdatedAt == null) {
      return 'Lokasi belum tersedia';
    }
    final currentTime = now ?? DateTime.now();
    final diff = currentTime.difference(locationUpdatedAt!);
    final seconds = diff.inSeconds;

    if (seconds <= 30) {
      return 'Online';
    } else if (seconds <= 120) {
      return 'Terakhir terlihat $seconds dtk lalu';
    } else {
      return 'Lokasi tidak diperbarui';
    }
  }

  factory RoomMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawTimestamp = data['joinedAt'];
    DateTime? joinedAt;
    if (rawTimestamp is Timestamp) {
      joinedAt = rawTimestamp.toDate();
    } else if (rawTimestamp is DateTime) {
      joinedAt = rawTimestamp;
    }

    // Parse locationUpdatedAt
    final rawLocTime = data['locationUpdatedAt'];
    DateTime? locationUpdatedAt;
    if (rawLocTime is Timestamp) {
      locationUpdatedAt = rawLocTime.toDate();
    } else if (rawLocTime is DateTime) {
      locationUpdatedAt = rawLocTime;
    }

    // Parse currentLocation (GeoPoint or backward-compatible Map)
    GeoPoint? currentLocation;
    final rawLoc = data['currentLocation'];
    if (rawLoc is GeoPoint) {
      currentLocation = rawLoc;
    } else if (rawLoc is Map<String, dynamic>) {
      final lat = (rawLoc['latitude'] as num?)?.toDouble();
      final lng = (rawLoc['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        currentLocation = GeoPoint(lat, lng);
      }
    }

    return RoomMemberModel(
      uid: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Pengguna',
      role: (data['role'] as String?)?.trim().toLowerCase() ?? 'jamaah',
      joinedAt: joinedAt,
      currentLocation: currentLocation,
      locationUpdatedAt: locationUpdatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'uid': uid,
      'name': name.trim(),
      'role': role.trim().toLowerCase(),
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    };
    if (currentLocation != null) {
      map['currentLocation'] = currentLocation;
    }
    if (locationUpdatedAt != null) {
      map['locationUpdatedAt'] = Timestamp.fromDate(locationUpdatedAt!);
    }
    return map;
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
