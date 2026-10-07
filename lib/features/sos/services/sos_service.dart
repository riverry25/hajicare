// ignore_for_file: use_null_aware_elements

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/trusted_backend_service.dart';

/// Coordinates SOS writes so an emergency is either recorded completely or
/// not recorded at all.
class SosService {
  SosService({FirebaseFirestore? firestore, TrustedBackendService? backend})
    : _providedFirestore = firestore;

  final FirebaseFirestore? _providedFirestore;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  /// Creates the event and updates both realtime status records atomically.
  /// Returns the new sos_event document ID.
  Future<String> trigger({
    required String userId,
    required String userName,
    String? roomId,
    String? roomName,
    GeoPoint? location,
    String? kloter,
    String? maktab,
  }) async {
    final eventRef = _firestore.collection('sos_events').doc();
    final userRef = _firestore.collection('users').doc(userId);

    final normalizedRoomId = (roomId != null && roomId.trim().isNotEmpty)
        ? roomId.trim()
        : null;
    if (normalizedRoomId == null) {
      debugPrint(
        '[SosService] Rejected SOS trigger: missing roomId. User must join a room first.',
      );
      return '';
    }
    final normalizedRoomName = (roomName != null && roomName.trim().isNotEmpty)
        ? roomName.trim()
        : 'Rombongan';

    final batch = _firestore.batch();
    final eventData = <String, dynamic>{
      'userId': userId,
      'jamaahId': userId,
      'userName': userName.trim().isNotEmpty ? userName.trim() : 'Jamaah',
      'roomName': normalizedRoomName,
      'roomId': normalizedRoomId,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    };
    if (location != null) {
      eventData['location'] = location;
      eventData['locationUpdatedAt'] = FieldValue.serverTimestamp();
    }
    if (kloter != null && kloter.trim().isNotEmpty) {
      eventData['kloter'] = kloter.trim();
    }
    if (maktab != null && maktab.trim().isNotEmpty) {
      eventData['maktab'] = maktab.trim();
    }

    batch.set(eventRef, eventData);
    batch.set(userRef, {
      'sosActive': true,
      'sosTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final memberRef = _firestore
        .collection('rooms')
        .doc(normalizedRoomId)
        .collection('members')
        .doc(userId);
    batch.set(memberRef, {'sosActive': true}, SetOptions(merge: true));

    await batch.commit();

    // Dispatch real-time emergency notifications to pendampings & admins
    // unawaited so that slow network queries do not delay returning eventRef.id.
    _dispatchSosNotifications(
      eventId: eventRef.id,
      senderUid: userId,
      senderName: userName.trim().isNotEmpty ? userName.trim() : 'Jamaah',
      roomId: normalizedRoomId,
      roomName: normalizedRoomName,
      location: location,
      kloter: kloter,
      maktab: maktab,
    );

    return eventRef.id;
  }

  /// Dispatches high-priority 'sos_alert' notifications to the room's pendampings
  /// and all admins so they receive alerts and see the badge on their dashboard.
  Future<void> _dispatchSosNotifications({
    required String eventId,
    required String senderUid,
    required String senderName,
    required String? roomId,
    required String roomName,
    GeoPoint? location,
    String? kloter,
    String? maktab,
  }) async {
    try {
      final recipientUids = <String>{};

      // 1. Resolve room pendamping UIDs
      if (roomId != null && roomId.isNotEmpty) {
        try {
          final roomDoc = await _firestore
              .collection('rooms')
              .doc(roomId)
              .get();
          if (roomDoc.exists) {
            final data = roomDoc.data() ?? {};
            final pIds = data['pendampingIds'];
            if (pIds is List) {
              for (final id in pIds) {
                final s = id?.toString().trim();
                if (s != null && s.isNotEmpty && s != senderUid) {
                  recipientUids.add(s);
                }
              }
            }
            final singlePId = (data['pendampingId'] as String?)?.trim();
            if (singlePId != null &&
                singlePId.isNotEmpty &&
                singlePId != senderUid) {
              recipientUids.add(singlePId);
            }
          }
        } catch (_) {}

        try {
          final membersSnap = await _firestore
              .collection('rooms')
              .doc(roomId)
              .collection('members')
              .where('role', isEqualTo: 'pendamping')
              .get();
          for (final doc in membersSnap.docs) {
            final uid = doc.id.trim();
            if (uid.isNotEmpty && uid != senderUid) {
              recipientUids.add(uid);
            }
          }
        } catch (_) {}
      }

      // 2. Resolve admin UIDs
      try {
        final adminSnap = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .limit(50)
            .get();
        for (final doc in adminSnap.docs) {
          final uid = doc.id.trim();
          if (uid.isNotEmpty && uid != senderUid) {
            recipientUids.add(uid);
          }
        }
      } catch (_) {}

      if (recipientUids.isEmpty) return;

      // 3. Write notification documents for all resolved recipients
      final batch = _firestore.batch();
      for (final recipientId in recipientUids) {
        final notifRef = _firestore.collection('notifications').doc();
        batch.set(notifRef, {
          'recipientId': recipientId,
          'type': 'sos_alert',
          'title': '🚨 Panggilan Darurat SOS!',
          'message':
              '$senderName membutuhkan bantuan darurat segera! ($roomName)',
          'scope': roomId != null ? 'room' : 'global',
          if (roomId != null) 'targetRoomId': roomId,
          'targetUserId': senderUid,
          'senderId': senderUid,
          'senderName': senderName,
          'senderRole': 'jamaah',
          'relatedId': eventId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'metadata': {
            'eventId': eventId,
            if (roomId != null) 'roomId': roomId,
            'roomName': roomName,
            'userName': senderName,
            if (location != null) 'latitude': location.latitude,
            if (location != null) 'longitude': location.longitude,
            if (kloter != null && kloter.isNotEmpty) 'kloter': kloter,
            if (maktab != null && maktab.isNotEmpty) 'maktab': maktab,
          },
        });
      }
      await batch.commit();
    } catch (_) {
      // Non-fatal: notification dispatch failure should never crash the core SOS trigger
    }
  }

  /// Updates the live GPS location on an active SOS event document.
  /// Called periodically as the jamaah's GPS updates while SOS is active.
  Future<void> updateSosLocation({
    required String eventId,
    required GeoPoint location,
  }) async {
    try {
      await _firestore.collection('sos_events').doc(eventId).update({
        'location': location,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal: location update failure should never crash the SOS flow.
    }
  }

  /// Returns a realtime stream of a single SOS event document.
  /// Used by SosAlertDetailScreen to observe live location changes.
  Stream<Map<String, dynamic>?> watchSosEvent(String eventId) {
    return _firestore.collection('sos_events').doc(eventId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    });
  }
}
