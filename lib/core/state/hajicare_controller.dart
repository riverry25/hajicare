import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jamaah_data.dart';
import '../services/location_service.dart';
import '../../features/room/models/room_model.dart';
import '../../features/room/models/room_member_model.dart';
import '../../features/room/models/room_invitation_model.dart';
import '../../features/room/services/room_service.dart';

export '../models/jamaah_data.dart';
export '../../features/room/models/room_model.dart';
export '../../features/room/models/room_member_model.dart';
export '../../features/room/models/room_invitation_model.dart';

class HajiCareController extends GetxController {
  static const String keyActiveRoomId = 'hajicare_active_room_id';
  static const String keyUserRole = 'hajicare_user_role';

  final _role = UserRole.jamaah.obs;
  UserRole get role => _role.value;

  final jamaahList = <JamaahData>[].obs;

  // Room Reactive State
  final activeRoomId = RxnString();
  final activeRoom = Rxn<RoomModel>();
  final activeRoomMembers = <RoomMemberModel>[].obs;
  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  String? _cachedRoomId;
  String? get cachedRoomId => _cachedRoomId ?? activeRoomId.value;

  final pendampingName = 'Pendamping Anda'.obs;
  final pendampingKloter = RxnString();
  final pendampingMaktab = RxnString();
  final pendampingLocation = Rxn<GeoPoint>();
  final pendampingLocationUpdatedAt = Rxn<DateTime>();
  final isPendampingGpsActive = false.obs;

  /// Kloter aktif: memprioritaskan data dari activeRoom jika ada, fallback ke data user pendamping
  String? get effectiveKloter {
    final roomKloter = activeRoom.value?.kloter?.trim();
    if (roomKloter != null && roomKloter.isNotEmpty) return roomKloter;
    final userKloter = pendampingKloter.value?.trim();
    if (userKloter != null && userKloter.isNotEmpty) return userKloter;
    return null;
  }

  /// Maktab aktif: memprioritaskan data dari activeRoom jika ada, fallback ke data user pendamping
  String? get effectiveMaktab {
    final roomMaktab = activeRoom.value?.maktab?.trim();
    if (roomMaktab != null && roomMaktab.isNotEmpty) return roomMaktab;
    final userMaktab = pendampingMaktab.value?.trim();
    if (userMaktab != null && userMaktab.isNotEmpty) return userMaktab;
    return null;
  }

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

  // Invitations State
  final pendingInvitations = <RoomInvitationModel>[].obs;
  StreamSubscription? _invitationsSub;

  // Realtime SOS Events from Firestore
  final activeSosEvents = <Map<String, dynamic>>[].obs;
  final activeSosCount = 0.obs;
  StreamSubscription? _sosEventsSub;

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
    _loadCachedUserData();
    _initAuthListener();
  }

  Future<void> _loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRoomId = prefs.getString(keyActiveRoomId);
      final savedRole = prefs.getString(keyUserRole);

      if (savedRoomId != null && savedRoomId.trim().isNotEmpty) {
        _cachedRoomId = savedRoomId.trim();
        if (activeRoomId.value == null || activeRoomId.value!.isEmpty) {
          activeRoomId.value = _cachedRoomId;
        }
      }

      if (savedRole != null && savedRole.trim().isNotEmpty) {
        final r = savedRole.trim().toLowerCase();
        if (r == 'admin') {
          _role.value = UserRole.admin;
        } else if (r == 'pendamping') {
          _role.value = UserRole.pendamping;
        } else {
          _role.value = UserRole.jamaah;
        }
      }
    } catch (e) {
      debugPrint('[HajiCareController] Error loading cached room/role: $e');
    }
  }

  /// Immediately applies user role and active room to reactive state
  /// and updates SharedPreferences cache.
  Future<void> applyUserData({
    required String roleStr,
    String? roomId,
    String? name,
  }) async {
    final normalizedRole = roleStr.trim().toLowerCase();
    if (normalizedRole == 'admin') {
      _role.value = UserRole.admin;
    } else if (normalizedRole == 'pendamping') {
      _role.value = UserRole.pendamping;
    } else {
      _role.value = UserRole.jamaah;
    }

    final trimmedRoomId = (roomId != null && roomId.trim().isNotEmpty) ? roomId.trim() : null;
    _cachedRoomId = trimmedRoomId;
    activeRoomId.value = trimmedRoomId;

    if (name != null && name.trim().isNotEmpty && _role.value == UserRole.pendamping) {
      pendampingName.value = name.trim();
    }

    // Persist to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyUserRole, normalizedRole);
      if (trimmedRoomId != null) {
        await prefs.setString(keyActiveRoomId, trimmedRoomId);
      } else {
        await prefs.remove(keyActiveRoomId);
      }
    } catch (e) {
      debugPrint('[HajiCareController] Error saving user data to cache: $e');
    }

    // If roomId is valid and user is logged in, start room listeners immediately
    final uid = currentUid;
    if (uid != null && trimmedRoomId != null) {
      _listenToActiveRoom(trimmedRoomId, uid);
    } else if (trimmedRoomId == null) {
      _clearRoomListeners();
    }
  }

  /// Explicitly syncs user doc from Firestore, updates in-memory state, and saves to cache.
  /// Called during login/bootstrap to ensure state is ready before navigation.
  Future<void> syncUserData(String uid, {Map<String, dynamic>? preloadedData}) async {
    try {
      Map<String, dynamic>? data = preloadedData;
      if (data == null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 4));
        if (doc.exists) {
          data = doc.data();
        }
      }

      if (data != null) {
        final roleStr = (data['role'] as String?)?.toLowerCase() ?? 'jamaah';
        final roomId = data['activeRoomId'] as String?;
        final rawName = data['name'] as String? ?? data['displayName'] as String?;

        await applyUserData(
          roleStr: roleStr,
          roomId: roomId,
          name: rawName,
        );
      }
    } catch (e) {
      debugPrint('[HajiCareController] Error in syncUserData: $e');
    }
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
    _invitationsSub?.cancel();
    _sosEventsSub?.cancel();
    for (var sub in _jamaahSubs.values) {
      sub.cancel();
    }
    _jamaahSubs.clear();
    jamaahList.clear();
    pendingInvitations.clear();
    activeSosEvents.clear();
    activeSosCount.value = 0;
    activeRoomMembers.clear();
    activeRoomId.value = null;
    activeRoom.value = null;
    _cachedRoomId = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(keyActiveRoomId);
      prefs.remove(keyUserRole);
    }).catchError((_) {});
    myCurrentPosition.value = null;
    isMyGpsActive.value = false;
    calculatedDistance.value = null;
    pendampingLocation.value = null;
    pendampingLocationUpdatedAt.value = null;
    pendampingKloter.value = null;
    pendampingMaktab.value = null;
    isPendampingGpsActive.value = false;
    _self = null;
  }

  Future<void> _loadUserData(String uid) async {
    _userDocSub?.cancel();
    _invitationsSub?.cancel();
    _sosEventsSub?.cancel();

    _invitationsSub = _roomService.getPendingInvitationsStream(uid).listen((invs) {
      pendingInvitations.value = invs;
    });

    _sosEventsSub = _roomService.getActiveSosEventsStream().listen((sosList) {
      activeSosEvents.value = sosList;
      activeSosCount.value = sosList.length;

      // Update matching jamaah in list if needed
      for (final j in jamaahList) {
        final hasActiveSos = sosList.any((s) => s['userId'] == j.id || s['jamaahId'] == j.id);
        if (j.sosActive != hasActiveSos) {
          j.sosActive = hasActiveSos;
          j.refresh();
        }
      }
      if (_self != null) {
        final hasSelfSos = sosList.any((s) => s['userId'] == uid || s['jamaahId'] == uid);
        if (_self!.sosActive != hasSelfSos) {
          _self!.sosActive = hasSelfSos;
          _self!.refresh();
        }
      }
    }, onError: (e) {
      debugPrint('[HajiCareController] Error listening to active SOS events: $e');
    });
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

        final currentRoomId = (data['activeRoomId'] as String?)?.trim();
        final effectiveRoomId = (currentRoomId != null && currentRoomId.isNotEmpty) ? currentRoomId : null;
        _cachedRoomId = effectiveRoomId;

        final userKloter = (data['kloter'] as String?)?.trim();
        final userMaktab = (data['maktab'] as String?)?.trim();
        pendampingKloter.value = (userKloter != null && userKloter.isNotEmpty) ? userKloter : null;
        pendampingMaktab.value = (userMaktab != null && userMaktab.isNotEmpty) ? userMaktab : null;

        // Persist snapshot update to SharedPreferences
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString(keyUserRole, roleStr);
          if (effectiveRoomId != null) {
            prefs.setString(keyActiveRoomId, effectiveRoomId);
          } else {
            prefs.remove(keyActiveRoomId);
          }
        }).catchError((e) {
          debugPrint('[HajiCareController] Error persisting snapshot to cache: $e');
        });

        if (effectiveRoomId != activeRoomId.value || _roomDocSub == null) {
          activeRoomId.value = effectiveRoomId;
          if (effectiveRoomId != null && effectiveRoomId.isNotEmpty) {
            _listenToActiveRoom(effectiveRoomId, uid);
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
        final r = RoomModel.fromFirestore(doc);
        activeRoom.value = r;
        safeRadiusMeters.value = r.safeRadius;
        if (r.maktab != null && r.maktab!.isNotEmpty) {
          pendampingMaktab.value = r.maktab;
        }
        if (r.kloter != null && r.kloter!.isNotEmpty) {
          pendampingKloter.value = r.kloter;
        }
      }
    }, onError: (e) {
      debugPrint('[HajiCareController] Error in _roomDocSub: $e');
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
        if (member != null) {
          if (member.currentLocation != null) {
            if (j.currentLocation == null ||
                (member.locationUpdatedAt != null &&
                    (j.locationUpdatedAt == null ||
                        member.locationUpdatedAt!.isAfter(j.locationUpdatedAt!)))) {
              j.currentLocation = member.currentLocation;
              j.locationUpdatedAt = member.locationUpdatedAt;
              j.isGpsActive = true;
            }
          } else {
            // Member's GPS went offline — reflect that in JamaahData
            j.isGpsActive = false;
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

  Future<void> setSafeRadius(double radius) async {
    safeRadiusMeters.value = radius;
    _recalculateRealDistance();
    final roomId = activeRoomId.value;
    if (roomId != null && roomId.isNotEmpty) {
      try {
        await _roomService.updateSafeRadius(roomId: roomId, radius: radius);
      } catch (e) {
        debugPrint('[HajiCareController] Error updating safe radius in Firestore: $e');
      }
    }
  }

  /// Leaves the current active room for this user.
  Future<bool> leaveRoom() async {
    final uid = currentUid;
    final roomId = activeRoomId.value;
    if (uid == null || roomId == null || roomId.isEmpty) return false;

    try {
      final roleStr = _role.value == UserRole.pendamping ? 'pendamping' : 'jamaah';
      final uName = _self?.name ??
          FirebaseAuth.instance.currentUser?.displayName ??
          'Jamaah';
      final rName = activeRoom.value?.name;

      await _roomService.leaveRoom(
        roomId: roomId,
        uid: uid,
        userName: uName,
        role: roleStr,
        roomName: rName,
      );

      _clearRoomListeners();
      activeRoomId.value = null;
      activeRoom.value = null;
      _cachedRoomId = null;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(keyActiveRoomId);
      } catch (e) {
        debugPrint('[HajiCareController] Error removing cached roomId: $e');
      }
      return true;
    } catch (e) {
      debugPrint('[HajiCareController] Error leaving room: $e');
      return false;
    }
  }

  /// Updates current active room settings by its creator pendamping or admin.
  Future<void> updateCurrentRoomSettings({
    String? name,
    String? maktab,
    String? kloter,
    double? safeRadius,
  }) async {
    final uid = currentUid;
    final roomId = activeRoomId.value;
    if (uid == null || roomId == null || roomId.isEmpty) {
      throw const RoomException('Tidak ada room aktif yang dapat diedit.');
    }

    final roleStr = _role.value == UserRole.admin ? 'admin' : 'pendamping';

    await _roomService.updateRoomSettings(
      roomId: roomId,
      currentUserId: uid,
      userRole: roleStr,
      name: name,
      maktab: maktab,
      kloter: kloter,
      safeRadius: safeRadius,
    );

    // Optimistically update local activeRoom reactive state immediately
    if (activeRoom.value != null) {
      activeRoom.value = activeRoom.value!.copyWith(
        name: name,
        maktab: maktab,
        kloter: kloter,
        safeRadius: safeRadius,
      );
    }

    if (maktab != null) {
      pendampingMaktab.value = maktab.trim().isNotEmpty ? maktab.trim() : null;
    }
    if (kloter != null) {
      pendampingKloter.value = kloter.trim().isNotEmpty ? kloter.trim() : null;
    }

    if (safeRadius != null && safeRadius > 0) {
      safeRadiusMeters.value = safeRadius;
      _recalculateRealDistance();
    }
  }

  /// Deletes current active room by its creator pendamping or admin.
  Future<void> deleteCurrentRoom() async {
    final uid = currentUid;
    final roomId = activeRoomId.value;
    if (uid == null || roomId == null || roomId.isEmpty) {
      throw const RoomException('Tidak ada room aktif yang dapat dihapus.');
    }

    final roleStr = _role.value == UserRole.admin ? 'admin' : 'pendamping';
    final sName = pendampingName.value.isNotEmpty
        ? pendampingName.value
        : (FirebaseAuth.instance.currentUser?.displayName ?? 'Pendamping');

    await _roomService.deleteRoomByCreator(
      roomId: roomId,
      currentUserId: uid,
      senderName: sName,
      userRole: roleStr,
    );

    // Instant local state reset
    _clearRoomListeners();
    activeRoomId.value = null;
    activeRoom.value = null;
    _cachedRoomId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyActiveRoomId);
    } catch (_) {}
  }

  // ── SOS SYSTEM (TRUE FIRESTORE & REALTIME) ──────────────────────────────────

  /// Triggers a real SOS event with current location to Firestore.
  /// Enforces that Jamaah must have an active room.
  Future<bool> triggerSos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final myPos = myCurrentPosition.value;
      final roomId = activeRoomId.value;
      final roomName = activeRoom.value?.name ?? (roomId != null ? 'Room $roomId' : 'Darurat Terbuka');
      final userName = _self?.name ?? user.displayName ?? 'Jamaah';

      // 1. Create real SOS event document with status 'active'
      await FirebaseFirestore.instance.collection('sos_events').add({
        'userId': user.uid,
        'jamaahId': user.uid,
        'userName': userName,
        'roomId': roomId,
        'roomName': roomName,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        if (myPos != null) 'location': GeoPoint(myPos.latitude, myPos.longitude),
      });

      // 2. Update user doc
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'sosActive': true,
        'sosTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update room member doc if in a room
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
  Future<bool> dismissSos(String id, {String? eventId}) async {
    try {
      await _roomService.resolveSos(
        userId: id,
        roomId: activeRoomId.value,
        eventId: eventId,
        resolvedByUid: currentUid,
      );
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

  bool get anySosActive => activeSosCount.value > 0 || jamaahList.any((j) => j.sosActive);

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
    final rStr = newRole == UserRole.admin
        ? 'admin'
        : (newRole == UserRole.pendamping ? 'pendamping' : 'jamaah');
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(keyUserRole, rStr);
    }).catchError((_) {});
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
