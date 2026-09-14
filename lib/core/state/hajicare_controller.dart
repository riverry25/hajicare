import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/jamaah_data.dart';
import '../../features/room/models/room_model.dart';
import '../../features/room/models/room_member_model.dart';

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

  final pendampingName = 'Pendamping Anda'.obs;
  JamaahData? _self;

  StreamSubscription? _authSub;
  StreamSubscription? _userDocSub;
  StreamSubscription? _roomDocSub;
  StreamSubscription? _roomMembersSub;
  StreamSubscription? _pairingsSub;
  StreamSubscription? _jamaahPairingSub;
  final Map<String, StreamSubscription> _jamaahSubs = {};
  Timer? _simTimer;
  final Random _rng = Random();

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
        } else {
          _clearData();
        }
      });
    } catch (e) {
      debugPrint('[HajiCareController] Firebase not initialized or error: $e');
    }
  }

  void _clearData() {
    _simTimer?.cancel();
    _userDocSub?.cancel();
    _roomDocSub?.cancel();
    _roomMembersSub?.cancel();
    _pairingsSub?.cancel();
    _jamaahPairingSub?.cancel();
    for (var sub in _jamaahSubs.values) {
      sub.cancel();
    }
    _jamaahSubs.clear();
    jamaahList.clear();
    activeRoomMembers.clear();
    activeRoomId.value = null;
    activeRoom.value = null;
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
          _startSimulation(uid);
        }
      });
    } catch (e) {
      debugPrint('[HajiCareController] Error loading user doc: $e');
    }
  }

  void _clearRoomListeners() {
    _roomDocSub?.cancel();
    _roomMembersSub?.cancel();
    activeRoom.value = null;
    activeRoomMembers.clear();
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
        final jamaahUids = members
            .where((m) => m.isJamaah)
            .map((m) => m.uid)
            .toList();
        _syncJamaahListeners(jamaahUids);
      } else if (_role.value == UserRole.jamaah) {
        // Resolve pendamping name from room members
        final pendampingMember = members.firstWhereOrNull((m) => m.isPendamping);
        if (pendampingMember != null) {
          pendampingName.value = pendampingMember.name;
        }
      }
    });
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
              jamaahList[index] = jData;
            } else {
              jamaahList.add(jData);
            }
            jamaahList.refresh();
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
          jamaahList.refresh();
        }
      }
    });
  }

  JamaahData get self {
    if (_self != null) return _self!;
    if (jamaahList.isNotEmpty) return jamaahList.first;
    // Safe dynamic fallback from authenticated Firebase user
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
      distance: 20,
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

  void triggerSos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Create SOS event
    await FirebaseFirestore.instance.collection('sos_events').add({
      'userId': user.uid,
      'roomId': activeRoomId.value,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    });

    // Update user doc
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'sosActive': true,
    });
  }

  void dismissSos(String id) async {
    await FirebaseFirestore.instance.collection('users').doc(id).update({
      'sosActive': false,
    });
  }

  void _startSimulation(String uid) {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_self == null) return;
      double delta = (_rng.nextDouble() * 30) - 15;
      if (_self!.distance > 250) delta -= 10;
      if (_self!.distance < 20) delta += 10;
      
      final newDistance = (_self!.distance + delta).clamp(0.0, 400.0);
      _self!.distance = newDistance;
      _self!.refresh();
      jamaahList.refresh();
      
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'distance': newDistance,
        'currentLocation': const GeoPoint(21.4225, 39.8262), // dummy coords Mecca
      });
    });
  }

  void setRole(UserRole newRole) {
    _role.value = newRole;
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _clearData();
    super.onClose();
  }
}
