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
import '../../features/room/services/room_service.dart';
import '../../features/sos/services/sos_service.dart';

export '../models/jamaah_data.dart';
export '../../features/room/models/room_model.dart';
export '../../features/room/models/room_member_model.dart';
export '../../features/room/models/room_invitation_model.dart';

class HajiCareController extends GetxController {
  HajiCareController({
    LocationService? locationService,
    RoomService? roomService,
    SosService? sosService,
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _locationService = locationService ?? LocationService(),
       _roomService = roomService ?? RoomService(),
       _sosService = sosService ?? SosService(),
       _providedFirebaseAuth = firebaseAuth,
       _providedFirestore = firestore;

  static const String keyActiveRoomId = 'hajicare_active_room_id';
  static const String keyUserRole = 'hajicare_user_role';

  final _role = UserRole.jamaah.obs;
  UserRole get role => _role.value;

  final jamaahList = <JamaahData>[].obs;

  // Room Reactive State
  final activeRoomId = RxnString();
  final activeRoom = Rxn<RoomModel>();
  final activeRoomMembers = <RoomMemberModel>[].obs;
  final FirebaseAuth? _providedFirebaseAuth;
  final FirebaseFirestore? _providedFirestore;

  FirebaseAuth get _firebaseAuth =>
      _providedFirebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  String? get currentUid {
    try {
      return _firebaseAuth.currentUser?.uid;
    } catch (_) {
      // Firebase is intentionally unavailable in isolated widget/unit tests.
      return null;
    }
  }

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
  final LocationService _locationService;
  final RoomService _roomService;
  final SosService _sosService;
  final myCurrentPosition = Rxn<Position>();
  final isMyGpsActive = false.obs;
  final calculatedDistance = RxnDouble();
  final safeRadiusMeters = 200.0.obs;
  StreamSubscription<Position>? _gpsStreamSub;
  int _sessionGeneration = 0;
  String? _locationTrackingRoomId;
  DateTime? _lastLocationBroadcastTime;
  Position? _lastBroadcastPosition;

  // Realtime SOS Events from Firestore
  final activeSosEvents = <Map<String, dynamic>>[].obs;
  final activeSosCount = 0.obs;
  bool _isSosMutationInFlight = false;
  StreamSubscription? _sosEventsSub;
  String? _sosSubscriptionScope;

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

      if (savedRoomId != null && savedRoomId.trim().isNotEmpty) {
        _cachedRoomId = savedRoomId.trim();
        if (activeRoomId.value == null || activeRoomId.value!.isEmpty) {
          activeRoomId.value = _cachedRoomId;
        }
      }

      // A local preference is never authoritative for privileged access.
      _role.value = UserRole.jamaah;
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
    } else if (normalizedRole == 'pendamping' || normalizedRole == 'petugas') {
      _role.value = UserRole.pendamping;
    } else {
      _role.value = UserRole.jamaah;
    }

    final trimmedRoomId = (roomId != null && roomId.trim().isNotEmpty)
        ? roomId.trim()
        : null;
    _cachedRoomId = trimmedRoomId;
    activeRoomId.value = trimmedRoomId;

    if (name != null &&
        name.trim().isNotEmpty &&
        _role.value == UserRole.pendamping) {
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
  Future<void> syncUserData(
    String uid, {
    Map<String, dynamic>? preloadedData,
  }) async {
    try {
      Map<String, dynamic>? data = preloadedData;
      if (data == null) {
        final doc = await _firestore
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 4));
        if (doc.exists) {
          data = doc.data();
        }
      }

      if (data != null) {
        IdTokenResult? token;
        try {
          token = await _firebaseAuth.currentUser
              ?.getIdTokenResult(true)
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          token = null;
        }
        final claim = token?.claims?['role']?.toString().toLowerCase();
        // 'petugas' is treated as an alias for 'pendamping'.
        final normalizedClaim = claim == 'petugas' ? 'pendamping' : claim;

        // Custom claim takes precedence; fall back to Firestore field.
        final rawFirestoreRole = (data['role'] as String?)
            ?.trim()
            .toLowerCase();
        final firestoreRole = rawFirestoreRole == 'petugas'
            ? 'pendamping'
            : rawFirestoreRole;
        final roleStr =
            (normalizedClaim == 'admin' || normalizedClaim == 'pendamping')
            ? normalizedClaim!
            : (firestoreRole == 'admin' || firestoreRole == 'pendamping'
                  ? firestoreRole!
                  : 'jamaah');

        final roomId = data['activeRoomId'] as String?;
        final rawName =
            data['name'] as String? ?? data['displayName'] as String?;

        await applyUserData(roleStr: roleStr, roomId: roomId, name: rawName);
      }
    } catch (e) {
      debugPrint('[HajiCareController] Error in syncUserData: $e');
    }
  }

  void _initAuthListener() {
    try {
      // Claims drive privileged roles, so listen for token refresh as well as
      // sign-in/sign-out changes.
      _authSub = _firebaseAuth.idTokenChanges().listen((user) {
        _sessionGeneration++;
        if (user != null) {
          _loadUserData(user.uid);
        } else {
          _clearData();
        }
      });
    } catch (e) {
      debugPrint('[HajiCareController] Firebase auth listener error: $e');
    }
  }

  void _clearData() {
    _sessionGeneration++;
    _gpsStreamSub?.cancel();
    _gpsStreamSub = null;
    _locationTrackingRoomId = null;
    _userDocSub?.cancel();
    _roomDocSub?.cancel();
    _roomMembersSub?.cancel();
    _pendampingDocSub?.cancel();
    _sosEventsSub?.cancel();
    for (var sub in _jamaahSubs.values) {
      sub.cancel();
    }
    _jamaahSubs.clear();
    jamaahList.clear();
    activeSosEvents.clear();
    activeSosCount.value = 0;
    activeRoomMembers.clear();
    activeRoomId.value = null;
    activeRoom.value = null;
    _cachedRoomId = null;
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.remove(keyActiveRoomId);
          prefs.remove(keyUserRole);
        })
        .catchError((_) {});
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
    _sosEventsSub?.cancel();

    try {
      final token = await _firebaseAuth.currentUser?.getIdTokenResult();
      final claim = token?.claims?['role']?.toString().toLowerCase();
      // 'petugas' is treated as an alias for 'pendamping'.
      final normalizedClaim = claim == 'petugas' ? 'pendamping' : claim;
      final claimRole =
          (normalizedClaim == 'admin' || normalizedClaim == 'pendamping')
          ? normalizedClaim
          : null; // null means "defer to Firestore field"

      _userDocSub = _firestore.collection('users').doc(uid).snapshots().listen((
        doc,
      ) {
        if (!doc.exists) return;
        final data = doc.data()!;

        // Custom claim takes precedence; fall back to Firestore `role` field.
        final rawFirestoreRole = (data['role'] as String?)
            ?.trim()
            .toLowerCase();
        final firestoreRole = rawFirestoreRole == 'petugas'
            ? 'pendamping'
            : rawFirestoreRole;
        final roleStr =
            claimRole ??
            (firestoreRole == 'admin' || firestoreRole == 'pendamping'
                ? firestoreRole!
                : 'jamaah');

        if (roleStr == 'admin') {
          _role.value = UserRole.admin;
        } else if (roleStr == 'pendamping') {
          _role.value = UserRole.pendamping;
        } else {
          _role.value = UserRole.jamaah;
        }

        final currentRoomId = (data['activeRoomId'] as String?)?.trim();
        final effectiveRoomId =
            (currentRoomId != null && currentRoomId.isNotEmpty)
            ? currentRoomId
            : null;
        _syncLocationRequirement(uid, effectiveRoomId);
        _cachedRoomId = effectiveRoomId;
        _listenToSosEvents(
          uid: uid,
          roomId: effectiveRoomId,
          isAdmin: _role.value == UserRole.admin,
        );

        final userKloter = (data['kloter'] as String?)?.trim();
        final userMaktab = (data['maktab'] as String?)?.trim();
        pendampingKloter.value = (userKloter != null && userKloter.isNotEmpty)
            ? userKloter
            : null;
        pendampingMaktab.value = (userMaktab != null && userMaktab.isNotEmpty)
            ? userMaktab
            : null;

        // Persist snapshot update to SharedPreferences
        SharedPreferences.getInstance()
            .then((prefs) {
              prefs.setString(keyUserRole, roleStr);
              if (effectiveRoomId != null) {
                prefs.setString(keyActiveRoomId, effectiveRoomId);
              } else {
                prefs.remove(keyActiveRoomId);
              }
            })
            .catchError((e) {
              debugPrint(
                '[HajiCareController] Error persisting snapshot to cache: $e',
              );
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
          final currentUser = _firebaseAuth.currentUser;
          final rawName =
              data['name'] as String? ?? data['displayName'] as String?;
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

  void _listenToSosEvents({
    required String uid,
    required String? roomId,
    required bool isAdmin,
  }) {
    final scope = isAdmin
        ? 'admin'
        : roomId == null
        ? 'user:$uid'
        : 'room:$roomId';
    if (_sosSubscriptionScope == scope && _sosEventsSub != null) return;

    _sosEventsSub?.cancel();
    _sosSubscriptionScope = scope;

    final stream = isAdmin
        ? _roomService.getActiveSosEventsStream()
        : roomId == null
        ? Stream<List<Map<String, dynamic>>>.value(const [])
        : _roomService.getActiveSosEventsStream(roomId: roomId);

    _sosEventsSub = stream.listen(
      (sosList) {
        activeSosEvents.value = sosList;
        activeSosCount.value = sosList.length;

        for (final jamaah in jamaahList) {
          final isActive = sosList.any(
            (event) =>
                event['userId'] == jamaah.id || event['jamaahId'] == jamaah.id,
          );
          if (jamaah.sosActive != isActive) {
            jamaah.sosActive = isActive;
            jamaah.refresh();
          }
        }

        if (_self != null) {
          final isSelfActive = sosList.any(
            (event) => event['userId'] == uid || event['jamaahId'] == uid,
          );
          if (_self!.sosActive != isSelfActive) {
            _self!.sosActive = isSelfActive;
            _self!.refresh();
          }
        }
      },
      onError: (Object error) {
        debugPrint(
          '[HajiCareController] Error listening to active SOS events: $error',
        );
      },
    );
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
    _roomDocSub = _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .listen(
          (doc) {
            if (doc.exists) {
              final r = RoomModel.fromFirestore(doc);
              activeRoom.value = r;
              activeRoom.refresh();
              safeRadiusMeters.value = r.safeRadius;
              if (r.maktab != null && r.maktab!.isNotEmpty) {
                pendampingMaktab.value = r.maktab;
              }
              if (r.kloter != null && r.kloter!.isNotEmpty) {
                pendampingKloter.value = r.kloter;
              }
            }
          },
          onError: (e) {
            debugPrint('[HajiCareController] Error in _roomDocSub: $e');
          },
        );

    _roomMembersSub?.cancel();
    _roomMembersSub = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .limit(500)
        .snapshots()
        .listen((snap) {
          final members = snap.docs
              .map((d) => RoomMemberModel.fromFirestore(d))
              .toList();
          activeRoomMembers.value = members;

          if (_role.value == UserRole.pendamping) {
            final jamaahMembers = members.where((m) => m.isJamaah).toList();
            _syncJamaahFromRoomMembers(jamaahMembers);
          } else if (_role.value == UserRole.jamaah) {
            // Resolve pendamping name and real coordinates from room members
            final pendampingMember = members.firstWhereOrNull(
              (m) => m.isPendamping,
            );
            if (pendampingMember != null) {
              pendampingName.value = pendampingMember.name;
              _listenToPendampingLocation(
                pendampingMember.uid,
                pendampingMember,
              );
            } else {
              pendampingLocation.value = null;
              isPendampingGpsActive.value = false;
            }
          }
          _recalculateRealDistance();
        });
  }

  void _listenToPendampingLocation(String _, RoomMemberModel memberFallback) {
    _pendampingDocSub?.cancel();
    _pendampingDocSub = null;
    pendampingLocation.value = memberFallback.currentLocation;
    pendampingLocationUpdatedAt.value = memberFallback.locationUpdatedAt;
    isPendampingGpsActive.value = memberFallback.hasLocation;
  }

  void _syncJamaahFromRoomMembers(List<RoomMemberModel> members) {
    final activeIds = members.map((member) => member.uid).toSet();
    jamaahList.removeWhere((jamaah) => !activeIds.contains(jamaah.id));
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

  void _listenToSelf(String uid) {
    _jamaahSubs[uid]?.cancel();
    _jamaahSubs[uid] = _firestore
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
    final generation = _sessionGeneration;
    _gpsStreamSub?.cancel();

    // 1. Initial Position check
    try {
      final result = await _locationService.getCurrentPosition();
      if (isClosed || generation != _sessionGeneration || currentUid != uid) {
        return;
      }
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
      if (isClosed || generation != _sessionGeneration || currentUid != uid) {
        return;
      }
      _gpsStreamSub = _locationService
          .getPositionStream(
            distanceFilter: 10,
            accuracy: LocationAccuracy.high,
          )
          .listen(
            (position) {
              myCurrentPosition.value = position;
              isMyGpsActive.value = true;
              _broadcastLocationToFirestore(uid, position);
              _recalculateRealDistance();
            },
            onError: (e) {
              debugPrint('[HajiCareController] GPS stream error: $e');
              isMyGpsActive.value = false;
            },
          );
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
      if (elapsed < 15 || distanceMoved < 10) {
        return; // Throttle
      }
    }

    _lastLocationBroadcastTime = now;
    _lastBroadcastPosition = pos;

    final geoPoint = GeoPoint(pos.latitude, pos.longitude);

    try {
      // 1. Update user doc
      await _firestore.collection('users').doc(uid).set({
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
                        member.locationUpdatedAt!.isAfter(
                          j.locationUpdatedAt!,
                        )))) {
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

  Future<bool> setSafeRadius(double radius) async {
    final previousRadius = safeRadiusMeters.value;
    safeRadiusMeters.value = radius;
    _recalculateRealDistance();
    final roomId = activeRoomId.value;
    if (roomId != null && roomId.isNotEmpty) {
      try {
        await _roomService.updateSafeRadius(roomId: roomId, radius: radius);
        return true;
      } catch (e) {
        debugPrint(
          '[HajiCareController] Error updating safe radius in Firestore: $e',
        );
        safeRadiusMeters.value = previousRadius;
        _recalculateRealDistance();
        return false;
      }
    }
    return false;
  }

  /// Leaves the current active room for this user.
  Future<bool> leaveRoom() async {
    final uid = currentUid;
    final roomId = activeRoomId.value;
    if (uid == null || roomId == null || roomId.isEmpty) return false;

    try {
      final roleStr = _role.value == UserRole.pendamping
          ? 'pendamping'
          : 'jamaah';
      final uName =
          _self?.name ?? _firebaseAuth.currentUser?.displayName ?? 'Jamaah';
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
      throw const RoomException('Belum ada rombongan yang dapat diedit.');
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
      activeRoom.refresh();
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
      throw const RoomException('Belum ada rombongan yang dapat dihapus.');
    }

    final roleStr = _role.value == UserRole.admin ? 'admin' : 'pendamping';
    final sName = pendampingName.value.isNotEmpty
        ? pendampingName.value
        : (_firebaseAuth.currentUser?.displayName ?? 'Pendamping');

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
  /// Works reliably for Jamaah both within a room and in standalone emergency mode.
  Future<bool> triggerSos() async {
    if (_isSosMutationInFlight) return false;
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    _isSosMutationInFlight = true;
    try {
      final myPos = myCurrentPosition.value;
      var roomId = activeRoomId.value?.trim();
      if (roomId == null || roomId.isEmpty) {
        roomId = _cachedRoomId?.trim();
      }
      if (roomId == null || roomId.isEmpty) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get(const GetOptions(source: Source.serverAndCache));
          final docRoomId = (userDoc.data()?['activeRoomId'] as String?)
              ?.trim();
          if (docRoomId != null && docRoomId.isNotEmpty) {
            roomId = docRoomId;
            activeRoomId.value = docRoomId;
            _cachedRoomId = docRoomId;
          }
        } catch (_) {}
      }

      final roomName =
          activeRoom.value?.name ??
          (roomId != null && roomId.isNotEmpty
              ? 'Rombongan'
              : 'Di luar rombongan');
      final userName = _self?.name ?? user.displayName ?? 'Jamaah';

      await _sosService.trigger(
        userId: user.uid,
        userName: userName,
        roomId: roomId,
        roomName: roomName,
        location: myPos == null
            ? null
            : GeoPoint(myPos.latitude, myPos.longitude),
      );

      if (_self != null) {
        _self!.sosActive = true;
        _self!.refresh();
      }
      jamaahList.refresh();
      return true;
    } catch (e) {
      debugPrint('[HajiCareController] Error triggering SOS: $e');
      return false;
    } finally {
      _isSosMutationInFlight = false;
    }
  }

  void _syncLocationRequirement(String uid, String? roomId) {
    if (roomId == null || roomId.isEmpty) {
      _gpsStreamSub?.cancel();
      _gpsStreamSub = null;
      _locationTrackingRoomId = null;
      isMyGpsActive.value = false;
      return;
    }
    if (_locationTrackingRoomId == roomId && _gpsStreamSub != null) return;
    _locationTrackingRoomId = roomId;
    startLocationTracking(uid);
  }

  /// Resolves an active SOS event in Firestore.
  Future<bool> dismissSos(String id, {String? eventId}) async {
    if (_isSosMutationInFlight) return false;
    _isSosMutationInFlight = true;
    try {
      var roomId = activeRoomId.value?.trim();
      if (roomId == null || roomId.isEmpty) {
        roomId = _cachedRoomId?.trim();
      }

      // If eventId wasn't explicitly supplied, find it from current active SOS events
      String? resolvedEventId = eventId;
      if (resolvedEventId == null || resolvedEventId.isEmpty) {
        final match = activeSosEvents.firstWhereOrNull(
          (e) => e['userId'] == id || e['jamaahId'] == id,
        );
        resolvedEventId = match?['id'] as String?;
      }

      await _roomService.resolveSos(
        userId: id,
        roomId: roomId,
        eventId: resolvedEventId,
        resolvedByUid: currentUid,
      );

      final index = jamaahList.indexWhere((j) => j.id == id);
      if (index >= 0) {
        jamaahList[index].sosActive = false;
        jamaahList[index].refresh();
      }
      if (_self?.id == id || currentUid == id) {
        _self?.sosActive = false;
        _self?.refresh();
      }

      // Immediately purge from active list locally for instant UI response
      activeSosEvents.removeWhere(
        (e) =>
            e['userId'] == id ||
            e['jamaahId'] == id ||
            (resolvedEventId != null && e['id'] == resolvedEventId),
      );
      activeSosCount.value = activeSosEvents.length;
      jamaahList.refresh();
      return true;
    } catch (e) {
      debugPrint('[HajiCareController] Error dismissing SOS: $e');
      return false;
    } finally {
      _isSosMutationInFlight = false;
    }
  }

  JamaahData get self {
    if (_self != null) return _self!;
    if (jamaahList.isNotEmpty) return jamaahList.first;
    User? currentUser;
    try {
      currentUser = _firebaseAuth.currentUser;
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

  bool get anySosActive =>
      activeSosCount.value > 0 || jamaahList.any((j) => j.sosActive);

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

  @visibleForTesting
  void setRole(UserRole newRole) {
    _role.value = newRole;
  }

  /// Re-triggers GPS location tracking (e.g. after user enables GPS from settings).
  Future<bool> refreshLocation() async {
    final uid = currentUid;
    if (uid != null) {
      await startLocationTracking(uid);
      return isMyGpsActive.value;
    }
    return false;
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _clearData();
    super.onClose();
  }
}
