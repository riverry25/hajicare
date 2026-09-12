import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/jamaah_data.dart';
export '../models/jamaah_data.dart';

class HajiCareController extends ChangeNotifier {
  UserRole _role = UserRole.jamaah;
  UserRole get role => _role;

  List<JamaahData> _jamaahList = [];
  List<JamaahData> get jamaahList => _jamaahList;

  String pendampingName = 'Pendamping Anda';
  JamaahData? _self;

  StreamSubscription? _authSub;
  StreamSubscription? _pairingsSub;
  final Map<String, StreamSubscription> _jamaahSubs = {};
  Timer? _simTimer;
  final Random _rng = Random();

  HajiCareController() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadUserData(user.uid);
      } else {
        _clearData();
      }
    });
  }

  void _clearData() {
    _simTimer?.cancel();
    _pairingsSub?.cancel();
    for (var sub in _jamaahSubs.values) {
      sub.cancel();
    }
    _jamaahSubs.clear();
    _jamaahList.clear();
    _self = null;
    notifyListeners();
  }

  Future<void> _loadUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return;
    
    final data = doc.data()!;
    final roleStr = data['role'] as String? ?? 'jamaah';
    _role = roleStr == 'pendamping' ? UserRole.pendamping : UserRole.jamaah;
    
    if (_role == UserRole.pendamping) {
      pendampingName = data['name'] as String? ?? 'Pendamping';
      _listenToPairings(uid);
    } else {
      // If Jamaah, just listen to self doc
      _self = JamaahData.fromFirestore(doc);
      _jamaahList = [_self!];
      _listenToSelf(uid);
      _startSimulation(uid); // For simulation updates to Firestore
    }
    notifyListeners();
  }

  void _listenToPairings(String pendampingId) {
    _pairingsSub?.cancel();
    _pairingsSub = FirebaseFirestore.instance
        .collection('pairings')
        .where('pendampingId', isEqualTo: pendampingId)
        .snapshots()
        .listen((snap) {
      final jamaahIds = snap.docs.map((d) => d['jamaahId'] as String).toList();
      _syncJamaahListeners(jamaahIds);
    });
  }

  void _syncJamaahListeners(List<String> jamaahIds) {
    // Remove old
    final toRemove = _jamaahSubs.keys.where((id) => !jamaahIds.contains(id)).toList();
    for (final id in toRemove) {
      _jamaahSubs[id]?.cancel();
      _jamaahSubs.remove(id);
      _jamaahList.removeWhere((j) => j.id == id);
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
            final index = _jamaahList.indexWhere((j) => j.id == id);
            if (index >= 0) {
              _jamaahList[index] = jData;
            } else {
              _jamaahList.add(jData);
            }
            notifyListeners();
          }
        });
      }
    }
    notifyListeners();
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
        _jamaahList = [_self!];
        notifyListeners();
      }
    });
  }

  JamaahData get self {
    if (_self != null) return _self!;
    if (_jamaahList.isNotEmpty) return _jamaahList.first;
    // Fallback
    return JamaahData(id: 'dummy', name: 'Loading', shortLabel: 'Load', distance: 0);
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
      
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'distance': newDistance,
        'currentLocation': const GeoPoint(21.4225, 39.8262), // dummy coords Mecca
      });
    });
  }

  // Deprecated manual setRole since it's driven by Auth now.
  void setRole(UserRole role) {}

  @override
  void dispose() {
    _authSub?.cancel();
    _clearData();
    super.dispose();
  }
}
