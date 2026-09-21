// ignore_for_file: use_null_aware_elements

import 'package:cloud_firestore/cloud_firestore.dart';
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
    final normalizedRoomName = (roomName != null && roomName.trim().isNotEmpty)
        ? roomName.trim()
        : (normalizedRoomId != null ? 'Rombongan' : 'Di luar rombongan');

    final batch = _firestore.batch();
    final eventData = <String, dynamic>{
      'userId': userId,
      'jamaahId': userId,
      'userName': userName.trim().isNotEmpty ? userName.trim() : 'Jamaah',
      'roomName': normalizedRoomName,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    };
    if (normalizedRoomId != null) {
      eventData['roomId'] = normalizedRoomId;
    }
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

    if (normalizedRoomId != null) {
      final memberRef = _firestore
          .collection('rooms')
          .doc(normalizedRoomId)
          .collection('members')
          .doc(userId);
      batch.set(memberRef, {'sosActive': true}, SetOptions(merge: true));
    }

    await batch.commit();
    return eventRef.id;
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
