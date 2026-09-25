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

  /// SIBI Model: YOLO object detection model (`assets/models/sibi/sibi.tflite`)
  /// Output: 53 classes from `assets/models/sibi/labels_sibi.txt`.
  static const SignLanguageModelConfig sibi = SignLanguageModelConfig(
    model: SignLanguageModel.sibi,
    modelAsset: 'assets/models/sibi/sibi.tflite',
    labelAsset: 'assets/models/sibi/labels_sibi.txt',
    defaultConfidenceThreshold: 0.30,
    windowSize: 12,
    minimumFrames: 1,
    inferenceStride: 1,
    throttleDuration: Duration(milliseconds: 50),
    expectedInputFeatures: 0,
  );

  /// BISINDO Model: Sequence GRU model (48 frames x 135 features)
  /// Output: 23 kelas kosakata BISINDO.
  static const SignLanguageModelConfig bisindo = SignLanguageModelConfig(
    model: SignLanguageModel.bisindo,
    modelAsset: 'assets/models/bisindo/hajicare_bisindo_gru_float32.tflite',
    labelAsset: 'assets/models/bisindo/labels.json',
    configAsset: 'assets/models/bisindo/model_config.json',
    defaultConfidenceThreshold: 0.78,
    windowSize: 48,
    minimumFrames: 24,
    inferenceStride: 2,
    throttleDuration: Duration(milliseconds: 70),
    expectedInputFeatures: 135,
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
