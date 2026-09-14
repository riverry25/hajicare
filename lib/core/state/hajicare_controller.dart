import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../models/jamaah_data.dart';
import '../services/location_service.dart';
import '../../features/room/models/room_model.dart';
import '../../features/room/models/room_member_model.dart';
import '../../features/room/services/room_service.dart';

export '../models/jamaah_data.dart';
export '../../features/room/models/room_model.dart';
export '../../features/room/models/room_member_model.dart';

class HajiCareController extends GetxController {
  final _role = UserRole.jamaah.obs;
  UserRole get role => _role.value;

  final jamaahList = <JamaahData>[].obs;

  // Room Reactive State
  final activeRoomId = RxnString();
  final activeRoom = Rxn<RoomModel>();
  final activeRoomMembers = <RoomMemberModel>[].obs;
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  final pendampingName = 'Pendamping Anda'.obs;
  final pendampingLocation = Rxn<GeoPoint>();
  final pendampingLocationUpdatedAt = Rxn<DateTime>();
  final isPendampingGpsActive = false.obs;

  // Real GPS & Realtime Distance State
  final LocationService _locationService = LocationService();
  final RoomService _roomService = RoomService();
  final myCurrentPosition = Rxn<Position>();
  final isMyGpsActive = false.obs;
  final calculatedDistance = RxnDouble();
  final safeRadiusMeters = 200.0.obs;
  StreamSubscription<Position>? _gpsStreamSub;
  DateTime? _lastLocationBroadcastTime;
  Position? _lastBroadcastPosition;

  JamaahData? _self;

  StreamSubscription? _authSub;
  StreamSubscription? _userDocSub;
  StreamSubscription? _roomDocSub;
  StreamSubscription? _roomMembersSub;
  StreamSubscription? _pendampingDocSub;
  final Map<String, StreamSubscription> _jamaahSubs = {};

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
  }

  void _initAuthListener() {
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _loadUserData(user.uid);
          startLocationTracking(user.uid);
        } else {
          _clearData();
        }
      });
    } catch (e) {
      debugPrint('[HajiCareController] Firebase auth listener error: $e');
    }
  }

  void _clearData() {
    _gpsStreamSub?.cancel();
    _userDocSub?.cancel();
    _roomDocSub?.cancel();
    _roomMembersSub?.cancel();
    _pendampingDocSub?.cancel();
    for (var sub in _jamaahSubs.values) {
      sub.cancel();
    }
    _jamaahSubs.clear();
    jamaahList.clear();
    activeRoomMembers.clear();
    activeRoomId.value = null;
    activeRoom.value = null;
    myCurrentPosition.value = null;
    isMyGpsActive.value = false;
    calculatedDistance.value = null;
    pendampingLocation.value = null;
    pendampingLocationUpdatedAt.value = null;
    isPendampingGpsActive.value = false;
    _self = null;
  }

  Future<void> _loadUserData(String uid) async {
    _userDocSub?.cancel();
    try {
      _userDocSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((doc) {
        if (!doc.exists) return;
        final data = doc.data()!;
        final roleStr = (data['role'] as String?)?.toLowerCase() ?? 'jamaah';

        if (roleStr == 'admin') {
          _role.value = UserRole.admin;
        } else if (roleStr == 'pendamping') {
          _role.value = UserRole.pendamping;
        } else {
          _role.value = UserRole.jamaah;
        }

        final currentRoomId = data['activeRoomId'] as String?;
        if (currentRoomId != activeRoomId.value) {
          activeRoomId.value = currentRoomId;
          if (currentRoomId != null && currentRoomId.isNotEmpty) {
            _listenToActiveRoom(currentRoomId, uid);
          } else {
            _clearRoomListeners();
          }
        }

        if (_role.value == UserRole.pendamping) {
          final currentUser = FirebaseAuth.instance.currentUser;
          final rawName = data['name'] as String? ?? data['displayName'] as String?;
          pendampingName.value = (rawName != null && rawName.trim().isNotEmpty)
              ? rawName.trim()
              : (currentUser?.displayName?.trim().isNotEmpty == true
                  ? currentUser!.displayName!.trim()
                  : 'Pendamping');
        } else if (_role.value == UserRole.jamaah) {
          _self = JamaahData.fromFirestore(doc);
          if (jamaahList.isEmpty || !jamaahList.any((j) => j.id == uid)) {
            jamaahList.value = [_self!];
          }
          _listenToSelf(uid);
        }
        _recalculateRealDistance();
      });
    } catch (e) {
      debugPrint('[HajiCareController] Error loading user doc: $e');
    }
  }

  void _clearRoomListeners() {
    _roomDocSub?.cancel();
    _roomMembersSub?.cancel();
    _pendampingDocSub?.cancel();
    activeRoom.value = null;
    activeRoomMembers.clear();
    pendampingLocation.value = null;
    pendampingLocationUpdatedAt.value = null;
    isPendampingGpsActive.value = false;
    calculatedDistance.value = null;
    if (_role.value == UserRole.pendamping) {
      for (var sub in _jamaahSubs.values) {
        sub.cancel();
      }
      _jamaahSubs.clear();
      jamaahList.clear();
    }
  }

  void _listenToActiveRoom(String roomId, String currentUid) {
    _roomDocSub?.cancel();
    _roomDocSub = FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        activeRoom.value = RoomModel.fromFirestore(doc);
      }
    });

    _roomMembersSub?.cancel();
    _roomMembersSub = FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .snapshots()
        .listen((snap) {
      final members = snap.docs.map((d) => RoomMemberModel.fromFirestore(d)).toList();
      activeRoomMembers.value = members;

      if (_role.value == UserRole.pendamping) {
        // Find only jamaah member UIDs for monitoring
        final jamaahMembers = members.where((m) => m.isJamaah).toList();
        final jamaahUids = jamaahMembers.map((m) => m.uid).toList();
        _syncJamaahFromRoomMembers(jamaahMembers);
        _syncJamaahListeners(jamaahUids);
      } else if (_role.value == UserRole.jamaah) {
        // Resolve pendamping name and real coordinates from room members
        final pendampingMember = members.firstWhereOrNull((m) => m.isPendamping);
        if (pendampingMember != null) {
          pendampingName.value = pendampingMember.name;
          _listenToPendampingLocation(pendampingMember.uid, pendampingMember);
        } else {
          pendampingLocation.value = null;
          isPendampingGpsActive.value = false;
        }
      }
      _recalculateRealDistance();
    });
  }

  void _listenToPendampingLocation(String pendampingUid, RoomMemberModel memberFallback) {
    if (memberFallback.currentLocation != null) {
      pendampingLocation.value = memberFallback.currentLocation;
      pendampingLocationUpdatedAt.value = memberFallback.locationUpdatedAt;
      isPendampingGpsActive.value = true;
    }

    _pendampingDocSub?.cancel();
    _pendampingDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(pendampingUid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      final loc = data['currentLocation'] as GeoPoint?;
      final isGps = (data['isGpsActive'] as bool?) ?? (loc != null);

      DateTime? locTime;
      if (data['locationUpdatedAt'] is Timestamp) {
        locTime = (data['locationUpdatedAt'] as Timestamp).toDate();
      }

      pendampingLocation.value = loc;
      pendampingLocationUpdatedAt.value = locTime;
      isPendampingGpsActive.value = isGps && loc != null;
      _recalculateRealDistance();
    });
  }

  void _syncJamaahFromRoomMembers(List<RoomMemberModel> members) {
    for (final member in members) {
      final index = jamaahList.indexWhere((j) => j.id == member.uid);
      if (index >= 0) {
        final j = jamaahList[index];
        if (member.currentLocation != null) {
          j.currentLocation = member.currentLocation;
          j.locationUpdatedAt = member.locationUpdatedAt ?? DateTime.now();
          j.isGpsActive = true;
        }
      } else {
        final newJ = JamaahData(
          id: member.uid,
          name: member.name,
          shortLabel: member.name.split(' ').first,
          distance: 0.0,
          currentLocation: member.currentLocation,
          locationUpdatedAt: member.locationUpdatedAt,
          isGpsActive: member.hasLocation,
          onlineStatus: true,
          activeRoomId: activeRoomId.value,
        );
        jamaahList.add(newJ);
      }
    }
    _recalculateRealDistance();
  }

  void _syncJamaahListeners(List<String> jamaahIds) {
    // Remove old
    final toRemove = _jamaahSubs.keys.where((id) => !jamaahIds.contains(id)).toList();
    for (final id in toRemove) {
      _jamaahSubs[id]?.cancel();
      _jamaahSubs.remove(id);
      jamaahList.removeWhere((j) => j.id == id);
    }

    // Add new
    for (final id in jamaahIds) {
      if (!_jamaahSubs.containsKey(id)) {
        _jamaahSubs[id] = FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .snapshots()
            .listen((doc) {
          if (doc.exists) {
            final jData = JamaahData.fromFirestore(doc);
            final index = jamaahList.indexWhere((j) => j.id == id);
            if (index >= 0) {
              final existing = jamaahList[index];
              if (jData.currentLocation == null && existing.currentLocation != null) {
                jData.currentLocation = existing.currentLocation;
                jData.locationUpdatedAt = existing.locationUpdatedAt;
                jData.isGpsActive = existing.isGpsActive;
              }
              jamaahList[index] = jData;
            } else {
              jamaahList.add(jData);
            }
            _recalculateRealDistance();
          }
        });
      }
    }
  }

  void _listenToSelf(String uid) {
    _jamaahSubs[uid]?.cancel();
    _jamaahSubs[uid] = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _self = JamaahData.fromFirestore(doc);
        if (_role.value == UserRole.jamaah) {
          final index = jamaahList.indexWhere((j) => j.id == uid);
          if (index >= 0) {
            jamaahList[index] = _self!;
          } else {
            jamaahList.add(_self!);
          }
          _recalculateRealDistance();
        }
      }
    });
  }

  // ── REAL GPS LOCATION TRACKING (NO DUMMY DATA) ─────────────────────────────

  /// Starts real device GPS tracking and broadcasts position to Firestore.
  Future<void> startLocationTracking(String uid) async {
    _gpsStreamSub?.cancel();

    // 1. Initial Position check
    try {
      final result = await _locationService.getCurrentPosition();
      if (result.isSuccess && result.position != null) {
        myCurrentPosition.value = result.position;
        isMyGpsActive.value = true;
        _broadcastLocationToFirestore(uid, result.position!);
      } else {
        isMyGpsActive.value = false;
      }
    } catch (e) {
      debugPrint('[HajiCareController] Initial GPS fetch error: $e');
      isMyGpsActive.value = false;
    }

    // 2. Realtime continuous stream
    try {
      _gpsStreamSub = _locationService
          .getPositionStream(distanceFilter: 5, accuracy: LocationAccuracy.high)
          .listen((position) {
        myCurrentPosition.value = position;
        isMyGpsActive.value = true;
        _broadcastLocationToFirestore(uid, position);
        _recalculateRealDistance();
      }, onError: (e) {
        debugPrint('[HajiCareController] GPS stream error: $e');
        isMyGpsActive.value = false;
      });
    } catch (e) {
      debugPrint('[HajiCareController] Failed to listen to GPS stream: $e');
      isMyGpsActive.value = false;
    }
  }

  /// Broadcasts device location to Firestore (throttled).
  Future<void> _broadcastLocationToFirestore(String uid, Position pos) async {
    final now = DateTime.now();
    if (_lastLocationBroadcastTime != null && _lastBroadcastPosition != null) {
      final elapsed = now.difference(_lastLocationBroadcastTime!).inSeconds;
      final distanceMoved = _locationService.calculateDistanceMeters(
        _lastBroadcastPosition!.latitude,
        _lastBroadcastPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (elapsed < 5 && distanceMoved < 5) {
        return; // Throttle
      }
    }

    _lastLocationBroadcastTime = now;
    _lastBroadcastPosition = pos;

    final geoPoint = GeoPoint(pos.latitude, pos.longitude);

    try {
      // 1. Update user doc
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'currentLocation': geoPoint,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'isGpsActive': true,
      }, SetOptions(merge: true));

      // 2. Update room member doc if in a room
      final roomId = activeRoomId.value;
      if (roomId != null && roomId.isNotEmpty) {
        await _roomService.updateMemberLocation(
          roomId: roomId,
          uid: uid,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
      }
    } catch (e) {
      debugPrint('[HajiCareController] Error broadcasting location: $e');
    }
  }

  /// Recalculates real mathematical distance between users using GPS coordinates.
  void _recalculateRealDistance() {
    if (_role.value == UserRole.jamaah) {
      final myPos = myCurrentPosition.value;
      final pLoc = pendampingLocation.value;

      if (myPos != null && pLoc != null) {
        final d = _locationService.calculateDistanceMeters(
          myPos.latitude,
          myPos.longitude,
          pLoc.latitude,
          pLoc.longitude,
        );
        calculatedDistance.value = d;
        if (_self != null) {
          _self!.distance = d;
          _self!.currentLocation = GeoPoint(myPos.latitude, myPos.longitude);
          _self!.isGpsActive = true;
          _self!.refresh(safeRadius: safeRadiusMeters.value);
        }
      } else {
        calculatedDistance.value = null;
      }
      jamaahList.refresh();
    } else if (_role.value == UserRole.pendamping) {
      final myPos = myCurrentPosition.value;
      for (final j in jamaahList) {
        final member = activeRoomMembers.firstWhereOrNull((m) => m.uid == j.id);
        if (member != null && member.currentLocation != null) {
          if (j.currentLocation == null ||
              (member.locationUpdatedAt != null &&
                  (j.locationUpdatedAt == null || member.locationUpdatedAt!.isAfter(j.locationUpdatedAt!)))) {
            j.currentLocation = member.currentLocation;
            j.locationUpdatedAt = member.locationUpdatedAt;
            j.isGpsActive = true;
          }
        }

        if (myPos != null && j.currentLocation != null) {
          final d = _locationService.calculateDistanceMeters(
            myPos.latitude,
            myPos.longitude,
            j.currentLocation!.latitude,
            j.currentLocation!.longitude,
          );
          j.distance = d;
        }
        j.refresh(safeRadius: safeRadiusMeters.value);
      }
      jamaahList.refresh();
    }
  }

  void setSafeRadius(double radius) {
    safeRadiusMeters.value = radius;
    _recalculateRealDistance();
  }

  // ── SOS SYSTEM (TRUE FIRESTORE & REALTIME) ──────────────────────────────────

  /// Triggers a real SOS event with current location to Firestore.
  Future<bool> triggerSos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final myPos = myCurrentPosition.value;
      final roomId = activeRoomId.value;
      final roomName = activeRoom.value?.name ?? '';
      final userName = _self?.name ?? user.displayName ?? 'Jamaah';

      // 1. Create real SOS event document
      await FirebaseFirestore.instance.collection('sos_events').add({
        'userId': user.uid,
        'userName': userName,
        'roomId': roomId,
        'roomName': roomName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'active',
        if (myPos != null) 'location': GeoPoint(myPos.latitude, myPos.longitude),
      });

      // 2. Update user doc
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'sosActive': true,
        'sosTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update room member doc
      if (roomId != null && roomId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('members')
            .doc(user.uid)
            .set({'sosActive': true}, SetOptions(merge: true));
      }

      if (_self != null) {
        _self!.sosActive = true;
        _self!.refresh();
      }
      jamaahList.refresh();
      return true;
    } catch (e) {
      debugPrint('[HajiCareController] Error triggering SOS: $e');
      return false;
    }
  }

  /// Resolves an active SOS event in Firestore.
  Future<bool> dismissSos(String id) async {
    try {
      await _roomService.resolveSos(userId: id, roomId: activeRoomId.value);
      final index = jamaahList.indexWhere((j) => j.id == id);
      if (index >= 0) {
        jamaahList[index].sosActive = false;
        jamaahList[index].refresh();
      }
      if (_self?.id == id) {
        _self?.sosActive = false;
        _self?.refresh();
      }
      jamaahList.refresh();
      return true;
    } catch (e) {
      debugPrint('[HajiCareController] Error dismissing SOS: $e');
      return false;
    }
  }

  JamaahData get self {
    if (_self != null) return _self!;
    if (jamaahList.isNotEmpty) return jamaahList.first;
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      currentUser = null;
    }
    final fallbackName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!.trim()
        : (currentUser?.email?.trim().isNotEmpty == true
            ? currentUser!.email!.split('@').first
            : 'Jamaah');
    return JamaahData(
      id: currentUser?.uid ?? 'self',
      name: fallbackName,
      shortLabel: fallbackName.split(' ').first,
      distance: 0,
      isGpsActive: isMyGpsActive.value,
    );
  }

  bool get anySosActive => jamaahList.any((j) => j.sosActive);

  bool get anyJamaahSeparated => jamaahList.any((j) => j.separatedMode);

  String get separatedJamaahName {
    final j = jamaahList.firstWhere(
      (j) => j.separatedMode,
      orElse: () => jamaahList.isEmpty ? self : jamaahList.first,
    );
    return j.name;
  }

  String get sosJamaahName {
    final j = jamaahList.firstWhere(
      (j) => j.sosActive,
      orElse: () => jamaahList.isEmpty ? self : jamaahList.first,
    );
    return j.name;
  }

  void setRole(UserRole newRole) {
    _role.value = newRole;
  }

  /// Re-triggers GPS location tracking (e.g. after user enables GPS from settings).
  Future<void> refreshLocation() async {
    final uid = currentUid;
    if (uid != null) {
      await startLocationTracking(uid);
    }
  }


  @override
  void onClose() {
    _authSub?.cancel();
    _clearData();
    super.onClose();
  }
}
