// ignore_for_file: use_null_aware_elements
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/jamaah_data.dart';
import '../services/location_service.dart';
import '../services/secure_storage_service.dart';
import '../utils/app_logger.dart';
import '../../features/room/models/room_model.dart';
import '../../features/room/models/room_member_model.dart';
import '../../features/room/services/room_service.dart';
import '../../features/sos/services/sos_service.dart';
import '../../features/sos/services/sos_validation_tracker_service.dart';
import '../../features/notification/controllers/notification_controller.dart';

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

  String? _testUid;

  @visibleForTesting
  void setTestUid(String? uid) {
    _testUid = uid;
  }

  String? get currentUid {
    if (_testUid != null) return _testUid;
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
  final nearestPendamping = Rxn<RoomMemberModel>();

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
  DateTime? _lastLocationBroadcastTime;
  Position? _lastBroadcastPosition;

  // Realtime SOS Events from Firestore
  final activeSosEvents = <Map<String, dynamic>>[].obs;
  final activeSosCount = 0.obs;
  final dismissedSosIds = <String>{}.obs;

  bool isSosDismissed(String? id) =>
      id != null && id.isNotEmpty && dismissedSosIds.contains(id);

  bool _isSosMutationInFlight = false;
  StreamSubscription? _sosEventsSub;
  String? _sosSubscriptionScope;

  /// ID of the sos_events doc created when this device triggered an SOS.
  /// Used to push live GPS updates into the SOS event while active.
  String? _activeSosEventId;
  String? _confirmedRoomId;

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

    // Automatically update SOS stream whenever active room or role changes
    ever(activeRoomId, (String? newRoomId) {
      final uid = currentUid;
      if (uid != null) {
        _sosSubscriptionScope = null;
        _listenToSosEvents(
          uid: uid,
          roomId: newRoomId,
          isAdmin: _role.value == UserRole.admin,
        );
      }
    });

    ever(_role, (UserRole newRole) {
      final uid = currentUid;
      if (uid != null) {
        _sosSubscriptionScope = null;
        _listenToSosEvents(
          uid: uid,
          roomId: activeRoomId.value,
          isAdmin: newRole == UserRole.admin,
        );
      }
    });
  }

  /// Forces an immediate reconnection of the active SOS realtime stream.
  /// Called when emergency screens like ModalSosScreen are opened.
  void refreshSosEvents() {
    final uid = currentUid;
    if (uid != null) {
      _sosSubscriptionScope = null;
      _listenToSosEvents(
        uid: uid,
        roomId: activeRoomId.value ?? _cachedRoomId,
        isAdmin: _role.value == UserRole.admin,
      );
    }
  }

  Future<void> _loadCachedUserData() async {
    try {
      final savedRoomId = await SecureStorageService.instance.getActiveRoomId();

      if (savedRoomId != null && savedRoomId.trim().isNotEmpty) {
        _cachedRoomId = savedRoomId.trim();
        if (activeRoomId.value == null || activeRoomId.value!.isEmpty) {
          activeRoomId.value = _cachedRoomId;
        }
      }

      // A local preference is never authoritative for privileged access.
      _role.value = UserRole.jamaah;
    } catch (e) {
      AppLogger.warn(
        'Error loading cached room/role: $e',
        tag: 'HajiCareController',
      );
    }
  }

  /// Immediately applies user role and active room to reactive state
  /// and updates encrypted SecureStorageService cache.
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

    // Persist to encrypted SecureStorageService
    try {
      await SecureStorageService.instance.setUserRole(normalizedRole);
      await SecureStorageService.instance.setActiveRoomId(trimmedRoomId);
    } catch (e) {
      AppLogger.error(
        'Error saving user data to secure storage: $e',
        tag: 'HajiCareController',
      );
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
      AppLogger.error('Error in syncUserData: $e', tag: 'HajiCareController');
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
      AppLogger.error(
        'Firebase auth listener error: $e',
        tag: 'HajiCareController',
      );
    }
  }

  void _clearData() {
    _sessionGeneration++;
    _gpsStreamSub?.cancel();
    _gpsStreamSub = null;
    _userDocSub?.cancel();
    _userDocSub = null;
    _roomDocSub?.cancel();
    _roomDocSub = null;
    _roomMembersSub?.cancel();
    _roomMembersSub = null;
    _pendampingDocSub?.cancel();
    _pendampingDocSub = null;
    _sosEventsSub?.cancel();
    _sosEventsSub = null;
    _sosSubscriptionScope = null;
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
    nearestPendamping.value = null;
    pendampingLocation.value = null;
    pendampingLocationUpdatedAt.value = null;
    pendampingKloter.value = null;
    pendampingMaktab.value = null;
    isPendampingGpsActive.value = false;
    _self = null;
  }

  Future<void> _loadUserData(String uid) async {
    _userDocSub?.cancel();
    _userDocSub = null;
    _sosEventsSub?.cancel();
    _sosEventsSub = null;
    _sosSubscriptionScope = null;

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
              AppLogger.warn(
                'Error persisting snapshot to cache: $e',
                tag: 'HajiCareController',
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
          if (effectiveRoomId == null || effectiveRoomId.isEmpty) {
            _self!.distance = 0.0;
          }
          if (jamaahList.isEmpty || !jamaahList.any((j) => j.id == uid)) {
            jamaahList.value = [_self!];
          }
          _listenToSelf(uid);
        }
        _recalculateRealDistance();
      });
    } catch (e) {
      AppLogger.error('Error loading user doc: $e', tag: 'HajiCareController');
    }
  }

  void _listenToSosEvents({
    required String uid,
    required String? roomId,
    required bool isAdmin,
  }) {
    final effectiveRoomId = roomId ?? _cachedRoomId ?? activeRoomId.value;
    final isOfficer =
        isAdmin ||
        _role.value == UserRole.pendamping ||
        _role.value == UserRole.admin;
    final scope = isOfficer
        ? ((effectiveRoomId != null && effectiveRoomId.isNotEmpty)
              ? 'room:$effectiveRoomId'
              : 'officer:global')
        : ((effectiveRoomId != null && effectiveRoomId.isNotEmpty)
              ? 'room:$effectiveRoomId'
              : 'user:$uid');
    if (_sosSubscriptionScope == scope && _sosEventsSub != null) return;

    _sosEventsSub?.cancel();
    _sosEventsSub = null;
    _sosSubscriptionScope = scope;

    final stream = isOfficer
        ? ((effectiveRoomId != null && effectiveRoomId.isNotEmpty)
              ? _roomService.getActiveSosEventsStream(roomId: effectiveRoomId)
              : _roomService.getActiveSosEventsStream())
        : ((effectiveRoomId != null && effectiveRoomId.isNotEmpty)
              ? _roomService.getActiveSosEventsStream(roomId: effectiveRoomId)
              : _roomService.getUserActiveSosEventsStream(uid));

    _sosEventsSub = stream.listen(
      (sosList) {
        final activeDocIds = sosList
            .map((e) => e['id']?.toString())
            .whereType<String>()
            .toSet();
        // Self-healing prune: If an event document is no longer active in Firestore,
        // prune it from dismissed IDs so memory never retains stale IDs.
        dismissedSosIds.removeWhere((id) => !activeDocIds.contains(id));

        // Filter strictly by the unique event document ID (never by person UID).
        final filteredList = sosList
            .where((event) => !isSosDismissed(event['id']?.toString()))
            .toList();
        activeSosEvents.value = filteredList;
        activeSosCount.value = filteredList.length;

        for (final jamaah in jamaahList) {
          final isActive = filteredList.any(
            (event) =>
                event['userId'] == jamaah.id || event['jamaahId'] == jamaah.id,
          );
          if (jamaah.sosActive != isActive) {
            jamaah.sosActive = isActive;
            jamaah.refresh();
          }
        }

        if (_self != null) {
          final isSelfActive = filteredList.any(
            (event) => event['userId'] == uid || event['jamaahId'] == uid,
          );
          if (_self!.sosActive != isSelfActive) {
            _self!.sosActive = isSelfActive;
            _self!.refresh();
          }
          if (!isSelfActive) {
            _activeSosEventId = null;
          }
        }

        if (filteredList.isEmpty && uid.isNotEmpty && uid != 'local_user') {
          _selfHealStaleSosStatus(uid, effectiveRoomId);
        }
      },
      onError: (Object error) {
        AppLogger.warn(
          'Error listening to active SOS events: $error',
          tag: 'HajiCareController',
        );
        _sosEventsSub?.cancel();
        _sosEventsSub = null;
        _sosSubscriptionScope = null;
        Future.delayed(const Duration(seconds: 3), () {
          if (!isClosed && (currentUid == uid || uid == 'local_user')) {
            _listenToSosEvents(uid: uid, roomId: roomId, isAdmin: isAdmin);
          }
        });
      },
      onDone: () {
        _sosEventsSub = null;
        _sosSubscriptionScope = null;
      },
    );
  }

  void _selfHealStaleSosStatus(String uid, String? roomId) {
    try {
      if (_self?.sosActive == true) {
        _self!.sosActive = false;
        _self!.refresh();
      }
      _activeSosEventId = null;

      // Clean Firestore users/{uid} sosActive flag if orphaned
      _firestore
          .collection('users')
          .doc(uid)
          .set({'sosActive': false}, SetOptions(merge: true))
          .catchError((_) {});

      // Clean rooms/{roomId}/members/{uid} sosActive flag if orphaned
      if (roomId != null && roomId.isNotEmpty) {
        _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('members')
            .doc(uid)
            .set({'sosActive': false}, SetOptions(merge: true))
            .catchError((_) {});
      }
    } catch (_) {}
  }

  void _clearRoomListeners() {
    _confirmedRoomId = null;
    _roomDocSub?.cancel();
    _roomMembersSub?.cancel();
    _pendampingDocSub?.cancel();
    activeRoom.value = null;
    activeRoomMembers.clear();
    nearestPendamping.value = null;
    pendampingLocation.value = null;
    pendampingLocationUpdatedAt.value = null;
    isPendampingGpsActive.value = false;
    calculatedDistance.value = null;
    if (_self != null) {
      _self!.distance = 0.0;
    }
    if (_role.value == UserRole.pendamping) {
      for (var sub in _jamaahSubs.values) {
        sub.cancel();
      }
      _jamaahSubs.clear();
      jamaahList.clear();
    }
    jamaahList.refresh();
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
              final status = (doc.data()?['status'] as String?)?.toLowerCase();
              if (!r.isActive || status == 'deleting' || status == 'inactive') {
                clearActiveRoomSession();
                return;
              }
              activeRoom.value = r;
              activeRoom.refresh();
              safeRadiusMeters.value = r.safeRadius;
              if (r.maktab != null && r.maktab!.isNotEmpty) {
                pendampingMaktab.value = r.maktab;
              }
              if (r.kloter != null && r.kloter!.isNotEmpty) {
                pendampingKloter.value = r.kloter;
              }
            } else {
              clearActiveRoomSession();
            }
          },
          onError: (e) {
            AppLogger.warn(
              'Error in _roomDocSub: $e',
              tag: 'HajiCareController',
            );
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

          // If current user is not admin, track and verify presence in members.
          // Only evict if this user was already confirmed to be in this room,
          // preventing premature eviction while the initial membership write syncs.
          if (_role.value != UserRole.admin && snap.docs.isNotEmpty) {
            final isStillInRoom = snap.docs.any((d) => d.id == currentUid);
            if (isStillInRoom) {
              _confirmedRoomId = roomId;
            } else if (_confirmedRoomId == roomId) {
              _verifyAndHandleEviction(roomId, currentUid);
              return;
            }
          }

          if (_role.value == UserRole.pendamping) {
            final jamaahMembers = members.where((m) => m.isJamaah).toList();
            _syncJamaahFromRoomMembers(jamaahMembers);
          } else if (_role.value == UserRole.jamaah) {
            // If pendampingName still has placeholder default, populate from any active companion
            if (pendampingName.value == 'Pendamping Anda') {
              final anyPendamping = members.firstWhereOrNull(
                (m) => m.isPendamping,
              );
              if (anyPendamping != null) {
                pendampingName.value = anyPendamping.name;
              }
            }
          }
          _recalculateRealDistance();
        });
  }

  Future<void> _verifyAndHandleEviction(String roomId, String? uid) async {
    if (uid == null || activeRoomId.value != roomId) return;
    try {
      final doc = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .doc(uid)
          .get();
      if (!doc.exists && activeRoomId.value == roomId) {
        AppLogger.info(
          'User $uid was removed from room $roomId by creator/admin',
          tag: 'HajiCareController',
        );
        _confirmedRoomId = null;
        clearActiveRoomSession();
      }
    } catch (e) {
      AppLogger.warn(
        'Error verifying membership eviction: $e',
        tag: 'HajiCareController',
      );
    }
  }

  void _syncJamaahFromRoomMembers(List<RoomMemberModel> members) {
    final activeIds = members.map((member) => member.uid).toSet();
    jamaahList.removeWhere((jamaah) => !activeIds.contains(jamaah.id));
    for (final member in members) {
      final isMemberActiveInSos = activeSosEvents.any(
        (e) => e['userId'] == member.uid || e['jamaahId'] == member.uid,
      );
      final index = jamaahList.indexWhere((j) => j.id == member.uid);
      if (index >= 0) {
        final j = jamaahList[index];
        if (member.currentLocation != null) {
          j.currentLocation = member.currentLocation;
          j.locationUpdatedAt = member.locationUpdatedAt ?? DateTime.now();
          j.isGpsActive = true;
        }
        final effectiveSosActive = isMemberActiveInSos && member.sosActive;
        if (j.sosActive != effectiveSosActive) {
          j.sosActive = effectiveSosActive;
          j.refresh();
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
          sosActive: isMemberActiveInSos && member.sosActive,
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
            final isSelfActiveInSosEvents = activeSosEvents.any(
              (e) => e['userId'] == uid || e['jamaahId'] == uid,
            );
            if (!isSelfActiveInSosEvents) {
              _self!.sosActive = false;
              _activeSosEventId = null;
            }
            if (activeRoomId.value == null ||
                activeRoomId.value!.trim().isEmpty) {
              _self!.distance = 0.0;
            }
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
  Future<void> startLocationTracking([String? uid]) async {
    final effectiveUid = uid ?? currentUid;
    final generation = _sessionGeneration;
    _gpsStreamSub?.cancel();

    // 1. Fast Initial Position: Check OS last known position first (instant 0ms response)
    try {
      final lastKnown = await _locationService.getLastKnownPosition();
      if (!isClosed && generation == _sessionGeneration && lastKnown != null) {
        myCurrentPosition.value = lastKnown;
        isMyGpsActive.value = true;
        if (effectiveUid != null) {
          _broadcastLocationToFirestore(effectiveUid, lastKnown);
        }
        _recalculateRealDistance();
      }
    } catch (e) {
      debugPrint('[HajiCareController] Fast lastKnown check: $e');
    }

    // 2. Start continuous GPS stream immediately (distanceFilter: 0 for instant stationary & movement updates)
    try {
      if (isClosed || generation != _sessionGeneration) return;
      _gpsStreamSub = _locationService
          .getPositionStream(distanceFilter: 0, accuracy: LocationAccuracy.high)
          .listen(
            (position) {
              myCurrentPosition.value = position;
              isMyGpsActive.value = true;
              if (effectiveUid != null) {
                _broadcastLocationToFirestore(effectiveUid, position);
              }
              _recalculateRealDistance();
            },
            onError: (e) {
              AppLogger.warn('GPS stream error: $e', tag: 'HajiCareController');
              isMyGpsActive.value = false;
            },
          );
    } catch (e) {
      AppLogger.warn(
        'Failed to listen to GPS stream: $e',
        tag: 'HajiCareController',
      );
      isMyGpsActive.value = false;
    }

    // 3. Concurrently fetch fresh initial position in background (timeout 5s)
    try {
      final result = await _locationService.getCurrentPosition(
        timeout: const Duration(seconds: 5),
      );
      if (isClosed || generation != _sessionGeneration) return;
      if (result.isSuccess && result.position != null) {
        myCurrentPosition.value = result.position;
        isMyGpsActive.value = true;
        if (effectiveUid != null) {
          _broadcastLocationToFirestore(effectiveUid, result.position!);
        }
        _recalculateRealDistance();
      }
    } catch (e) {
      AppLogger.warn('Initial GPS fetch error: $e', tag: 'HajiCareController');
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

    // Update live SOS event location only if SOS is currently active on self
    final sosEventId = _activeSosEventId;
    if (sosEventId != null &&
        sosEventId.isNotEmpty &&
        (_self?.sosActive ?? false)) {
      _sosService.updateSosLocation(eventId: sosEventId, location: geoPoint);
    } else if (_self?.sosActive == false) {
      _activeSosEventId = null;
    }

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
      AppLogger.warn(
        'Error broadcasting location: $e',
        tag: 'HajiCareController',
      );
    }
  }

  /// Recalculates real mathematical distance between users using GPS coordinates.
  @visibleForTesting
  void recalculateRealDistance() => _recalculateRealDistance();

  void _recalculateRealDistance() {
    if (_role.value == UserRole.jamaah) {
      final currentRoom = activeRoomId.value?.trim();
      if (currentRoom == null || currentRoom.isEmpty) {
        calculatedDistance.value = null;
        nearestPendamping.value = null;
        if (_self != null) {
          _self!.distance = 0.0;
        }
        jamaahList.refresh();
        return;
      }

      final myPos = myCurrentPosition.value;
      if (myPos == null) {
        calculatedDistance.value = null;
        nearestPendamping.value = null;
        if (_self != null) {
          _self!.distance = 0.0;
        }
        jamaahList.refresh();
        return;
      }

      // Step 2: Ambil semua Pendamping dalam room yang sama dengan lokasi GPS valid
      final allCompanionsWithLocation = activeRoomMembers.where((m) {
        if (!m.isPendamping || !m.hasLocation) return false;
        final lat = m.latitude!;
        final lng = m.longitude!;
        return lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0;
      }).toList();

      if (allCompanionsWithLocation.isEmpty) {
        calculatedDistance.value = null;
        nearestPendamping.value = null;
        pendampingLocation.value = null;
        pendampingLocationUpdatedAt.value = null;
        isPendampingGpsActive.value = false;
        if (_self != null) {
          _self!.distance = 0.0;
        }
        jamaahList.refresh();
        return;
      }

      // Step 3 & 4: Hitung jarak geospasial ke setiap Pendamping dan pilih jarak terkecil (argmin).
      // Evaluasi kesegaran: utamakan lokasi yang diperbarui dalam 30 menit terakhir.
      final now = DateTime.now();
      const freshnessThreshold = Duration(minutes: 30);
      final freshCompanions = allCompanionsWithLocation.where((m) {
        if (m.locationUpdatedAt == null) return false;
        return now.difference(m.locationUpdatedAt!) <= freshnessThreshold;
      }).toList();

      final candidateCompanions = freshCompanions.isNotEmpty
          ? freshCompanions
          : allCompanionsWithLocation;

      RoomMemberModel? closest;
      double minDistance = double.infinity;

      for (final comp in candidateCompanions) {
        final d = _locationService.calculateDistanceMeters(
          myPos.latitude,
          myPos.longitude,
          comp.latitude!,
          comp.longitude!,
        );
        if (d < minDistance) {
          minDistance = d;
          closest = comp;
        }
      }

      // Step 5: Tampilkan hasil yang benar
      if (closest != null && !minDistance.isInfinite) {
        nearestPendamping.value = closest;
        pendampingName.value = closest.name;
        pendampingLocation.value = closest.currentLocation;
        pendampingLocationUpdatedAt.value = closest.locationUpdatedAt;
        isPendampingGpsActive.value = true;
        calculatedDistance.value = minDistance;

        if (_self != null) {
          _self!.distance = minDistance;
          _self!.currentLocation = GeoPoint(myPos.latitude, myPos.longitude);
          _self!.isGpsActive = true;
          _self!.refresh(safeRadius: safeRadiusMeters.value);
        }
      } else {
        calculatedDistance.value = null;
        nearestPendamping.value = null;
        pendampingLocation.value = null;
        pendampingLocationUpdatedAt.value = null;
        isPendampingGpsActive.value = false;
        if (_self != null) {
          _self!.distance = 0.0;
        }
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
        AppLogger.error(
          'Error updating safe radius in Firestore: $e',
          tag: 'HajiCareController',
        );
        safeRadiusMeters.value = previousRadius;
        _recalculateRealDistance();
        return false;
      }
    }
    return false;
  }

  /// Safely clears all local active room state, streams, and SharedPreferences cache.
  Future<void> clearActiveRoomSession() async {
    _clearRoomListeners();
    activeRoomId.value = null;
    activeRoom.value = null;
    _cachedRoomId = null;
    try {
      await SecureStorageService.instance.setActiveRoomId(null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyActiveRoomId);
    } catch (e) {
      AppLogger.warn(
        'Error removing cached roomId: $e',
        tag: 'HajiCareController',
      );
    }
  }

  /// Leaves the current active room for this user.
  Future<bool> leaveRoom() async {
    final uid = currentUid;
    final roomId = activeRoomId.value ?? _cachedRoomId;
    if (uid == null || roomId == null || roomId.isEmpty) return false;

    try {
      final roleStr = _role.value == UserRole.pendamping
          ? 'pendamping'
          : 'jamaah';
      final uName =
          _self?.name ?? _firebaseAuth.currentUser?.displayName ?? 'Jamaah';
      final rName = activeRoom.value?.name;

      // Cancel own active SOS before leaving room so it never lingers or gets orphaned
      if (_self?.sosActive == true || _activeSosEventId != null) {
        try {
          await _roomService.resolveSos(
            userId: uid,
            roomId: roomId,
            eventId: _activeSosEventId,
            resolvedByUid: uid,
          );
        } catch (_) {}
        _activeSosEventId = null;
        if (_self != null) {
          _self!.sosActive = false;
          _self!.refresh();
        }
        activeSosEvents.removeWhere(
          (e) => e['userId'] == uid || e['jamaahId'] == uid,
        );
        activeSosCount.value = activeSosEvents.length;
      }

      await _roomService.leaveRoom(
        roomId: roomId,
        uid: uid,
        userName: uName,
        role: roleStr,
        roomName: rName,
      );

      await clearActiveRoomSession();
      return true;
    } catch (e) {
      AppLogger.error('Error leaving room: $e', tag: 'HajiCareController');
      rethrow;
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
    final stopwatch = Stopwatch()..start();
    String? currentRoomName;
    String? currentUserName;
    GeoPoint? currentGeoPoint;

    try {
      final myPos = myCurrentPosition.value;
      if (myPos != null) {
        currentGeoPoint = GeoPoint(myPos.latitude, myPos.longitude);
      }
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

      // CRITICAL GUARD: User MUST belong to an active monitoring room to trigger SOS
      if (roomId == null || roomId.trim().isEmpty) {
        AppLogger.warn(
          'Cannot trigger SOS: user has not joined any room',
          tag: 'HajiCareController',
        );
        if (_self != null && _self!.sosActive) {
          _self!.sosActive = false;
          _self!.refresh();
        }
        stopwatch.stop();
        await SosValidationTrackerService.instance.logTrial(
          userName: _self?.name ?? user.displayName ?? 'Jamaah',
          roomName: 'Belum Gabung Room',
          latitude: myPos?.latitude,
          longitude: myPos?.longitude,
          durationSeconds: stopwatch.elapsedMilliseconds / 1000.0,
          isSuccess: false,
          errorMessage: 'User belum terdaftar di rombongan manapun',
        );
        return false;
      }

      // Verify that the room document exists and is active
      try {
        final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
        if (!roomDoc.exists ||
            roomDoc.data()?['isActive'] == false ||
            roomDoc.data()?['status'] == 'deleting') {
          AppLogger.warn(
            'Cannot trigger SOS: room $roomId is not active or deleted',
            tag: 'HajiCareController',
          );
          await clearActiveRoomSession();
          return false;
        }

        // Verify user is an active member in this room
        final memberDoc = await _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('members')
            .doc(user.uid)
            .get();
        if (!memberDoc.exists) {
          AppLogger.warn(
            'Cannot trigger SOS: user ${user.uid} is not an active member of room $roomId',
            tag: 'HajiCareController',
          );
          await clearActiveRoomSession();
          return false;
        }
      } catch (e) {
        AppLogger.warn(
          'Error checking room membership during triggerSos: $e',
          tag: 'HajiCareController',
        );
      }

      final roomName = activeRoom.value?.name ?? 'Rombongan';
      final userName = _self?.name ?? user.displayName ?? 'Jamaah';
      currentRoomName = roomName;
      currentUserName = userName;

      final eventId = await _sosService.trigger(
        userId: user.uid,
        userName: userName,
        roomId: roomId,
        roomName: roomName,
        location: currentGeoPoint,
        kloter: effectiveKloter,
        maktab: effectiveMaktab,
      );
      _activeSosEventId = eventId;
      dismissedSosIds.remove(eventId);
      dismissedSosIds.remove(user.uid);

      if (_self != null) {
        _self!.sosActive = true;
        _self!.refresh();
      }
      if (!activeSosEvents.any((e) => e['userId'] == user.uid)) {
        activeSosEvents.add({
          'id': eventId,
          'userId': user.uid,
          'userName': userName,
          'roomId': roomId,
          'roomName': roomName,
          'status': 'active',
          'createdAt': DateTime.now().toIso8601String(),
          if (currentGeoPoint != null) 'location': currentGeoPoint,
        });
        activeSosCount.value = activeSosEvents.length;
      }
      jamaahList.refresh();

      stopwatch.stop();
      final durationSec = stopwatch.elapsedMilliseconds / 1000.0;
      await SosValidationTrackerService.instance.logTrial(
        userName: userName,
        roomName: roomName,
        latitude: myPos?.latitude,
        longitude: myPos?.longitude,
        durationSeconds: durationSec,
        isSuccess: true,
        eventId: eventId,
      );

      return true;
    } catch (e) {
      stopwatch.stop();
      AppLogger.error('Error triggering SOS: $e', tag: 'HajiCareController');
      await SosValidationTrackerService.instance.logTrial(
        userName:
            currentUserName ?? (_self?.name ?? user.displayName ?? 'Jamaah'),
        roomName: currentRoomName ?? (activeRoom.value?.name ?? 'Rombongan'),
        latitude: myCurrentPosition.value?.latitude,
        longitude: myCurrentPosition.value?.longitude,
        durationSeconds: stopwatch.elapsedMilliseconds / 1000.0,
        isSuccess: false,
        errorMessage: e.toString(),
      );
      return false;
    } finally {
      _isSosMutationInFlight = false;
    }
  }

  void _syncLocationRequirement(String uid, String? roomId) {
    // Always maintain real GPS stream so Map, Dashboard, and Prayer Times
    // remain immediately synchronized with live device GPS.
    if (_gpsStreamSub == null) {
      startLocationTracking(uid);
    }
  }

  /// Resolves an active SOS event in Firestore.
  Future<bool> dismissSos(String id, {String? eventId}) async {
    if (_isSosMutationInFlight) return false;
    _isSosMutationInFlight = true;

    // Immediately mark eventId in dismissed set for instant UI responsiveness
    if (eventId != null && eventId.isNotEmpty) dismissedSosIds.add(eventId);

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
      if (resolvedEventId != null && resolvedEventId.isNotEmpty) {
        dismissedSosIds.add(resolvedEventId);
      }

      try {
        await _roomService.resolveSos(
          userId: id,
          roomId: roomId,
          eventId: resolvedEventId,
          resolvedByUid: currentUid,
        );
      } catch (backendError) {
        AppLogger.warn(
          'RoomService resolveSos error (will continue local purge): $backendError',
          tag: 'HajiCareController',
        );
      }

      final index = jamaahList.indexWhere((j) => j.id == id);
      if (index >= 0) {
        jamaahList[index].sosActive = false;
        jamaahList[index].refresh();
      }
      if (_self?.id == id || currentUid == id) {
        _self?.sosActive = false;
        _self?.refresh();
      }

      // Clear local SOS event ID if we just cancelled our own SOS
      if (id == currentUid) {
        _activeSosEventId = null;
      }

      // Automatically purge matching sos_alert notifications if NotificationController is registered
      if (Get.isRegistered<NotificationController>()) {
        try {
          final notifCtrl = Get.find<NotificationController>();
          final toDelete = notifCtrl.notifications
              .where(
                (n) =>
                    n.isSosAlert &&
                    (n.id == id ||
                        n.id == eventId ||
                        n.id == resolvedEventId ||
                        n.relatedId == id ||
                        n.relatedId == eventId ||
                        n.relatedId == resolvedEventId ||
                        n.senderId == id ||
                        n.targetUserId == id),
              )
              .map((n) => n.id)
              .toList();
          for (final notifId in toDelete) {
            notifCtrl.deleteNotification(notifId);
          }
        } catch (e) {
          AppLogger.warn(
            'Error cleaning up notifications on dismissSos: $e',
            tag: 'HajiCareController',
          );
        }
      }

      // Clean up Firestore notification docs matching this user/event so pendampings' devices receive real-time updates
      if (currentUid != null &&
          currentUid!.isNotEmpty &&
          currentUid != 'local_user') {
        try {
          final notifs = await _firestore
              .collection('notifications')
              .where('type', isEqualTo: 'sos_alert')
              .where('senderId', isEqualTo: id)
              .limit(10)
              .get();
          if (notifs.docs.isNotEmpty) {
            final batch = _firestore.batch();
            for (final doc in notifs.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
          }
        } catch (_) {}
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
      AppLogger.error('Error dismissing SOS: $e', tag: 'HajiCareController');
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
      activeSosCount.value > 0 ||
      activeSosEvents.isNotEmpty ||
      ((_self?.sosActive ?? false) &&
          (activeSosEvents.isNotEmpty || currentUid == null)) ||
      jamaahList.any(
        (j) =>
            j.sosActive && (activeSosEvents.isNotEmpty || currentUid == null),
      );

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

  /// Exposes the SOS service for stream access by SosAlertDetailScreen.
  SosService get sosService => _sosService;

  @visibleForTesting
  void setRole(UserRole newRole) {
    _role.value = newRole;
  }

  /// Re-triggers GPS location tracking (e.g. after user enables GPS from settings).
  Future<bool> refreshLocation() async {
    await startLocationTracking(currentUid);
    return isMyGpsActive.value;
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _clearData();
    super.onClose();
  }
}
