import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_model.dart';

/// Data model representing a member inside `rooms/{roomId}/members/{uid}`.
class RoomMemberModel {
  final String uid;
  final String name;
  final String role;
  final DateTime? joinedAt;
  final GeoPoint? currentLocation;
  final DateTime? locationUpdatedAt;
  final bool isSmartbandConnected;
  final int? heartRate;
  final double? temperature;
  final int? spo2;
  final bool fallDetected;
  final String? fallStatus;
  final int? batteryLevel;
  final String? braceletId;
  final DateTime? smartbandUpdatedAt;

  const RoomMemberModel({
    required this.uid,
    required this.name,
    required this.role,
    this.joinedAt,
    this.currentLocation,
    this.locationUpdatedAt,
    this.isSmartbandConnected = false,
    this.sosActive = false,
    this.heartRate,
    this.temperature,
    this.spo2,
    this.fallDetected = false,
    this.fallStatus,
    this.batteryLevel,
    this.braceletId,
    this.smartbandUpdatedAt,
  });

  final bool sosActive;

  bool get isPendamping => role.toLowerCase() == 'pendamping';
  bool get isJamaah => role.toLowerCase() == 'jamaah';
  bool get isAdmin => role.toLowerCase() == 'admin';

  bool isPrimaryOwner(RoomModel? room) => room != null && uid == room.createdBy;

  bool isCoOwner(RoomModel? room) =>
      room != null &&
      room.coOwnerId != null &&
      room.coOwnerId!.isNotEmpty &&
      uid == room.coOwnerId;

  bool isOwnerOrCoOwner(RoomModel? room) =>
      isPrimaryOwner(room) || isCoOwner(room);

  double? get latitude => currentLocation?.latitude;
  double? get longitude => currentLocation?.longitude;
  bool get hasLocation => currentLocation != null;

  RoomMemberModel copyWith({
    String? uid,
    String? name,
    String? role,
    DateTime? joinedAt,
    GeoPoint? currentLocation,
    DateTime? locationUpdatedAt,
    bool? isSmartbandConnected,
    bool? sosActive,
  }) {
    return RoomMemberModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      currentLocation: currentLocation ?? this.currentLocation,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      isSmartbandConnected: isSmartbandConnected ?? this.isSmartbandConnected,
      sosActive: sosActive ?? this.sosActive,
    );
  }

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

    int? hr;
    double? temp;
    int? oxygen;
    bool fall = false;
    String? fStatus;
    int? battery;
    String? bId;
    DateTime? bandTime;

    final smartbandMap = data['smartband'] as Map<String, dynamic>?;
    if (smartbandMap != null) {
      hr = (smartbandMap['heartRate'] as num?)?.toInt() ??
          (smartbandMap['bpm'] as num?)?.toInt();
      temp = (smartbandMap['temperature'] as num?)?.toDouble();
      oxygen = (smartbandMap['spo2'] as num?)?.toInt();
      fall = (smartbandMap['fallDetected'] as bool?) ?? false;
      fStatus = smartbandMap['fallStatus'] as String?;
      battery = (smartbandMap['batteryLevel'] as num?)?.toInt();
      bId = smartbandMap['braceletId'] as String?;
      if (smartbandMap['updatedAt'] is Timestamp) {
        bandTime = (smartbandMap['updatedAt'] as Timestamp).toDate();
      }
    } else {
      hr = (data['heartRate'] as num?)?.toInt() ?? (data['bpm'] as num?)?.toInt();
      temp = (data['temperature'] as num?)?.toDouble();
      oxygen = (data['spo2'] as num?)?.toInt();
      fall = (data['fallDetected'] as bool?) ?? false;
      fStatus = data['fallStatus'] as String?;
      battery = (data['batteryLevel'] as num?)?.toInt();
      bId = data['braceletId'] as String?;
      if (data['smartbandUpdatedAt'] is Timestamp) {
        bandTime = (data['smartbandUpdatedAt'] as Timestamp).toDate();
      }
    }

    final isSmartband = (data['isSmartbandConnected'] as bool?) ??
        (data['smartbandConnected'] as bool?) ??
        (data['isSmartbandActive'] as bool?) ??
        (smartbandMap?['connected'] as bool?) ??
        (hr != null || temp != null);

    return RoomMemberModel(
      uid: doc.id,
      name: (data['name'] as String?)?.trim() ?? 'Pengguna',
      role: (data['role'] as String?)?.trim().toLowerCase() ?? 'jamaah',
      joinedAt: joinedAt,
      currentLocation: currentLocation,
      locationUpdatedAt: locationUpdatedAt,
      isSmartbandConnected: isSmartband,
      sosActive: (data['sosActive'] as bool?) ?? false,
      heartRate: hr,
      temperature: temp,
      spo2: oxygen,
      fallDetected: fall,
      fallStatus: fStatus,
      batteryLevel: battery,
      braceletId: bId,
      smartbandUpdatedAt: bandTime,
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'uid': uid,
      'name': name.trim(),
      'role': role.trim().toLowerCase(),
      'sosActive': sosActive,
      'isSmartbandConnected': isSmartbandConnected,
      'joinedAt': joinedAt != null
          ? Timestamp.fromDate(joinedAt!)
          : FieldValue.serverTimestamp(),
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
