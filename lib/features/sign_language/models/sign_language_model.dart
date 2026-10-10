/// Pilihan model bahasa isyarat yang didukung HajiCare.
enum SignLanguageModel {
  sibi,
  bisindo;

  String get displayName {
    switch (this) {
      case SignLanguageModel.sibi:
        return 'SIBI';
      case SignLanguageModel.bisindo:
        return 'BISINDO';
    }
  }

  String get fullTitle {
    switch (this) {
      case SignLanguageModel.sibi:
        return 'SIBI (Sistem Isyarat Bahasa Indonesia)';
      case SignLanguageModel.bisindo:
        return 'BISINDO (Bahasa Isyarat Indonesia)';
    }
  }

  String get description {
    switch (this) {
      case SignLanguageModel.sibi:
        return 'Penerjemah huruf alfabet SIBI statis & dinamis.';
      case SignLanguageModel.bisindo:
        return 'Penerjemah gerakan kosakata BISINDO.';
    }
  }

  SignLanguageModelConfig get config => SignLanguageModelConfig.forModel(this);
}

/// Konfigurasi terpusat untuk setiap model bahasa isyarat.
/// Menjadi Single Source of Truth untuk model path, label, input tensor,
/// buffer requirement, dan threshold.
class SignLanguageModelConfig {
  final SignLanguageModel model;
  final String modelAsset;
  final String labelAsset;
  final String? configAsset;
  final double defaultConfidenceThreshold;
  final int windowSize;
  final int minimumFrames;
  final int inferenceStride;
  final Duration throttleDuration;
  final int expectedInputFeatures;

  const SignLanguageModelConfig({
    required this.model,
    required this.modelAsset,
    required this.labelAsset,
    this.configAsset,
    required this.defaultConfidenceThreshold,
    required this.windowSize,
    required this.minimumFrames,
    this.inferenceStride = 2,
    this.throttleDuration = const Duration(milliseconds: 70),
    required this.expectedInputFeatures,
  });

  /// SIBI Model: MotionGRU model (48 frames x 706 features: 353 base + 353 motion)
  /// Output: 72 kelas kosakata & alfabet SIBI.
  static const SignLanguageModelConfig sibi = SignLanguageModelConfig(
    model: SignLanguageModel.sibi,
    modelAsset: 'assets/models/sibi/sibi_motion_gru_float16.tflite',
    labelAsset: 'assets/models/sibi/labels.txt',
    configAsset: 'assets/models/sibi/model_metadata.json',
    defaultConfidenceThreshold: 0.70,
    windowSize: 48,
    minimumFrames: 24,
    inferenceStride: 2,
    throttleDuration: Duration(milliseconds: 70),
    expectedInputFeatures: 706,
  );

  /// BISINDO Model: MotionGRU model (48 frames x 706 features: 353 base + 353 motion)
  /// Output: 47 kelas kosakata BISINDO.
  static const SignLanguageModelConfig bisindo = SignLanguageModelConfig(
    model: SignLanguageModel.bisindo,
    modelAsset: 'assets/models/bisindo/bisindo_motion_gru_float16.tflite',
    labelAsset: 'assets/models/bisindo/labels.txt',
    configAsset: 'assets/models/bisindo/model_metadata.json',
    defaultConfidenceThreshold: 0.70,
    windowSize: 48,
    minimumFrames: 24,
    inferenceStride: 2,
    throttleDuration: Duration(milliseconds: 70),
    expectedInputFeatures: 706,
  );

  static SignLanguageModelConfig forModel(SignLanguageModel model) {
    switch (model) {
      case SignLanguageModel.sibi:
        return sibi;
      case SignLanguageModel.bisindo:
        return bisindo;
    }
  }

  @override
  String toString() =>
      'SignLanguageModelConfig(model: ${model.displayName}, asset: $modelAsset, window: $windowSize, minFrames: $minimumFrames)';
}
