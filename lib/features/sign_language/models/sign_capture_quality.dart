import 'landmark_frame.dart';

/// Quality metrics evaluated across an isolated sign gesture recording session.
class SignCaptureQuality {
  final int totalFrames;
  final int handFrames;
  final int poseFrames;
  final int faceFrames;

  const SignCaptureQuality({
    required this.totalFrames,
    required this.handFrames,
    required this.poseFrames,
    required this.faceFrames,
  });

  double get anyHandRatio => totalFrames > 0 ? (handFrames / totalFrames) : 0.0;

  double get poseRatio => totalFrames > 0 ? (poseFrames / totalFrames) : 0.0;

  double get faceRatio => totalFrames > 0 ? (faceFrames / totalFrames) : 0.0;

  /// Aggregates quality from a list of collected frames.
  factory SignCaptureQuality.fromFrames(List<LandmarkFrame> frames) {
    if (frames.isEmpty) {
      return const SignCaptureQuality(
        totalFrames: 0,
        handFrames: 0,
        poseFrames: 0,
        faceFrames: 0,
      );
    }

    int handCount = 0;
    int poseCount = 0;
    int faceCount = 0;

    for (final f in frames) {
      if (f.hasAnyHand) handCount++;
      if (f.hasPose) poseCount++;
      if (f.hasFaceBlendshapes) faceCount++;
    }

    return SignCaptureQuality(
      totalFrames: frames.length,
      handFrames: handCount,
      poseFrames: poseCount,
      faceFrames: faceCount,
    );
  }

  /// Evaluates whether the capture meets minimum quality gating standards.
  QualityValidationResult validate() {
    if (totalFrames < 2) {
      return const QualityValidationResult(
        isValid: false,
        userErrorMessage: 'Gerakan belum cukup terdeteksi. Silakan coba lagi.',
      );
    }

    if (anyHandRatio < 0.35) {
      return const QualityValidationResult(
        isValid: false,
        userErrorMessage:
            'Tangan kurang terlihat. Pastikan tangan berada di dalam kamera.',
      );
    }

    if (poseRatio < 0.20) {
      return const QualityValidationResult(
        isValid: false,
        userErrorMessage:
            'Tubuh bagian atas belum terlihat jelas. Posisikan dada dan bahu dalam kamera.',
      );
    }

    return const QualityValidationResult(isValid: true);
  }

  @override
  String toString() =>
      'SignCaptureQuality(frames: $totalFrames, handRatio: ${(anyHandRatio * 100).toStringAsFixed(1)}%, poseRatio: ${(poseRatio * 100).toStringAsFixed(1)}%, faceRatio: ${(faceRatio * 100).toStringAsFixed(1)}%)';
}

class QualityValidationResult {
  final bool isValid;
  final String? userErrorMessage;

  const QualityValidationResult({required this.isValid, this.userErrorMessage});
}
