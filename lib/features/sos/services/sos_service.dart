import 'package:cloud_firestore/cloud_firestore.dart';

/// Coordinates SOS writes so an emergency is either recorded completely or
/// not recorded at all.
class SosService {
  SosService({FirebaseFirestore? firestore}) : _providedFirestore = firestore;

  final FirebaseFirestore? _providedFirestore;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  /// Creates the event and updates both realtime status records atomically.
  Future<String> trigger({
    required String userId,
    required String userName,
    required String roomId,
    required String roomName,
    GeoPoint? location,
  }) async {
    final eventRef = _firestore.collection('sos_events').doc();
    final userRef = _firestore.collection('users').doc(userId);
    final memberRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(userId);

    final batch = _firestore.batch();
    batch.set(eventRef, {
      'userId': userId,
      'jamaahId': userId,
      'userName': userName,
      'roomId': roomId,
      'roomName': roomName,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'location': ?location,
    });
    batch.set(userRef, {
      'sosActive': true,
      'sosTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(memberRef, {'sosActive': true}, SetOptions(merge: true));

    await batch.commit();
    return eventRef.id;
  }
}
