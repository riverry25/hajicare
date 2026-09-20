// ignore_for_file: use_null_aware_elements

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/trusted_backend_service.dart';

/// Coordinates SOS writes so an emergency is either recorded completely or
/// not recorded at all.
class SosService {
  SosService({FirebaseFirestore? firestore, TrustedBackendService? backend})
    : _providedBackend = backend;

  final TrustedBackendService? _providedBackend;
  TrustedBackendService get _backend =>
      _providedBackend ?? TrustedBackendService();

  /// Creates the event and updates both realtime status records atomically.
  Future<String> trigger({
    required String userId,
    required String userName,
    required String roomId,
    required String roomName,
    GeoPoint? location,
  }) async {
    final result = await _backend.call('triggerSos', {
      if (location != null)
        'location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
    });
    return result['eventId'] as String;
  }

  Future<String> transition({
    required String action,
    String? eventId,
    String? userId,
  }) async {
    final result = await _backend.call('transitionSos', {
      'action': action,
      if (eventId != null) 'eventId': eventId,
      if (userId != null) 'userId': userId,
    });
    return result['status'] as String;
  }
}
