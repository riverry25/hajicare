import 'package:cloud_functions/cloud_functions.dart';

/// The only client entry point for privileged domain mutations.
///
/// Identity, role, membership and lifecycle checks are deliberately performed
/// by Cloud Functions. Callers only submit intent and non-authoritative input.
class TrustedBackendService {
  TrustedBackendService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> call(
    String name, [
    Map<String, dynamic> data = const {},
  ]) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      if (result.data == null) return const {};
      if (result.data is! Map) {
        throw const TrustedBackendException(
          'Respons server tidak dapat diproses.',
        );
      }
      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (error) {
      throw TrustedBackendException(
        error.message ?? 'Permintaan belum dapat diproses oleh server.',
        code: error.code,
      );
    }
  }
}

class TrustedBackendException implements Exception {
  const TrustedBackendException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}
