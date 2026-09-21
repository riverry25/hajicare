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
  Future<String> trigger({
    required String userId,
    required String userName,
    String? roomId,
    String? roomName,
    GeoPoint? location,
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
}
