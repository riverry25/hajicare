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

class BisindoPrediction {
  /// The index of the prototype class (0 to 7).
  final int classId;

  /// The Indonesian sign label (e.g. 'Air', 'Saya', 'Terima kasih', etc.).
  final String label;

  /// Confidence score between 0.0 and 1.0 (e.g. 0.93 = 93%).
  final double confidence;

  /// Raw Euclidean / L2 distance to the winning prototype vector.
  final double distance;

  /// Ranked list of all 8 prototype candidate predictions, sorted by smallest distance first.
  final List<BisindoCandidate> candidates;

  const BisindoPrediction({
    required this.classId,
    required this.label,
    required this.confidence,
    required this.distance,
    required this.candidates,
  });

  /// Canonical 8 HajiCare BISINDO classes in exact prototype order:
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
    'candidates': candidates.map((c) => c.toJson()).toList(),
  };

  @override
  String toString() =>
      'BisindoPrediction(label: "$label", confidence: ${(confidence * 100).toStringAsFixed(1)}%, distance: ${distance.toStringAsFixed(3)})';
}
