/// Data models representing BISINDO sign language classification output.
class BisindoCandidate {
  final int classId;
  final String label;
  final double distance;
  final double confidence;

  const BisindoCandidate({
    required this.classId,
    required this.label,
    required this.distance,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'classId': classId,
    'label': label,
    'distance': distance,
    'confidence': confidence,
  };

  @override
  String toString() =>
      'BisindoCandidate(classId: $classId, label: "$label", confidence: ${(confidence * 100).toStringAsFixed(1)}%, distance: ${distance.toStringAsFixed(3)})';
}

enum BisindoMatchQuality { strong, possible, unknown }

class BisindoPrediction {
  /// Runtime index of the winning prototype class.
  final int classId;

  /// The Indonesian sign label (e.g. 'Air', 'Saya', 'Terima kasih', etc.).
  final String label;

  /// Confidence score between 0.0 and 1.0 (e.g. 0.93 = 93%).
  final double confidence;

  /// Raw Euclidean / L2 distance to the winning prototype vector.
  final double distance;

  /// Whether the result passed distance, separation, and temporal checks.
  /// Unrecognized results must be shown as guidance, not as a translated word.
  final bool isRecognized;

  /// Plain-language guidance when the result is not safe to display.
  final String? guidance;

  /// Relative separation between the best and second-best candidates.
  final double margin;

  /// Strong matches can be shown immediately. Possible matches require
  /// temporal confirmation; unknown matches are never presented as words.
  final BisindoMatchQuality matchQuality;

  /// Ranked prototype candidates, sorted by smallest distance first.
  final List<BisindoCandidate> candidates;

  const BisindoPrediction({
    required this.classId,
    required this.label,
    required this.confidence,
    required this.distance,
    required this.candidates,
    this.isRecognized = true,
    this.guidance,
    this.margin = 0,
    this.matchQuality = BisindoMatchQuality.possible,
  });

  BisindoPrediction copyWith({
    int? classId,
    String? label,
    double? confidence,
    double? distance,
    List<BisindoCandidate>? candidates,
    bool? isRecognized,
    String? guidance,
    double? margin,
    BisindoMatchQuality? matchQuality,
  }) {
    return BisindoPrediction(
      classId: classId ?? this.classId,
      label: label ?? this.label,
      confidence: confidence ?? this.confidence,
      distance: distance ?? this.distance,
      candidates: candidates ?? this.candidates,
      isRecognized: isRecognized ?? this.isRecognized,
      guidance: guidance ?? this.guidance,
      margin: margin ?? this.margin,
      matchQuality: matchQuality ?? this.matchQuality,
    );
  }

  /// Classes currently bundled with HajiCare. Runtime loading is dynamic, so a
  /// complete prototype asset can add classes without changing application code.
  /// index 0: Air
  /// index 1: Saya
  /// index 2: Terima kasih
  /// index 3: Tuli
  /// index 4: Apa
  /// index 5: Siapa
  /// index 6: Di mana
  /// index 7: Keluarga
  static const List<String> kClassLabels = [
    'Air',
    'Saya',
    'Terima kasih',
    'Tuli',
    'Apa',
    'Siapa',
    'Di mana',
    'Keluarga',
  ];

  /// JSON keys corresponding to the 8 classes in `hajicare_prototypes.json`
  static const List<String> kPrototypeJsonKeys = [
    '0',
    '9',
    '10',
    '11',
    '12',
    '13',
    '15',
    '26',
  ];

  Map<String, dynamic> toJson() => {
    'classId': classId,
    'label': label,
    'confidence': confidence,
    'distance': distance,
    'isRecognized': isRecognized,
    'guidance': guidance,
    'margin': margin,
    'matchQuality': matchQuality.name,
    'candidates': candidates.map((c) => c.toJson()).toList(),
  };

  @override
  String toString() =>
      'BisindoPrediction(label: "$label", confidence: ${(confidence * 100).toStringAsFixed(1)}%, distance: ${distance.toStringAsFixed(3)})';
}
