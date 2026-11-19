enum SignTokenType { word, letter, space }

class SignToken {
  final SignTokenType type;
  final String value;
  final String? sourceModel;
  final double? confidence;

  const SignToken({
    required this.type,
    required this.value,
    this.sourceModel,
    this.confidence,
  });

  const SignToken.word(
    String value, {
    String? sourceModel,
    double? confidence,
  }) : this(
         type: SignTokenType.word,
         value: value,
         sourceModel: sourceModel,
         confidence: confidence,
       );

  const SignToken.letter(
    String value, {
    String? sourceModel,
    double? confidence,
  }) : this(
         type: SignTokenType.letter,
         value: value,
         sourceModel: sourceModel,
         confidence: confidence,
       );

  const SignToken.space() : this(type: SignTokenType.space, value: ' ');

  Map<String, String> toJson() => {
    't': type.name,
    'v': value,
    if (sourceModel != null && sourceModel!.isNotEmpty) 'm': sourceModel!,
    if (confidence != null) 'c': confidence!.toStringAsFixed(3),
  };

  /// Returns null for malformed entries so corrupt storage never crashes.
  static SignToken? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final typeName = json['t'];
    final value = json['v'];
    if (typeName is! String || value is! String) return null;
    final rawModel = json['m'];
    final sourceModel =
        (rawModel is String && rawModel.trim().isNotEmpty) ? rawModel.trim() : null;
    final rawConf = json['c'];
    double? confidence;
    if (rawConf is num) {
      confidence = rawConf.toDouble();
    } else if (rawConf is String) {
      confidence = double.tryParse(rawConf);
    }

    for (final type in SignTokenType.values) {
      if (type.name == typeName) {
        if (type == SignTokenType.space) return const SignToken.space();
        if (value.trim().isEmpty) return null;
        return SignToken(
          type: type,
          value: value,
          sourceModel: sourceModel,
          confidence: confidence,
        );
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is SignToken &&
      other.type == type &&
      other.value == value &&
      other.sourceModel == sourceModel;

  @override
  int get hashCode => Object.hash(type, value, sourceModel);
}

class ParsedSignLabel {
  final SignTokenType type;
  final String value;

  const ParsedSignLabel({required this.type, required this.value});

  SignToken toToken({String? sourceModel, double? confidence}) => SignToken(
    type: type,
    value: value,
    sourceModel: sourceModel,
    confidence: confidence,
  );
}

/// Converts model metadata into transcript tokens. Existing unprefixed model
/// labels remain words, while future models can use WORD_* and LETTER_*.
class SignLabelParser {
  const SignLabelParser();

  ParsedSignLabel parse(String modelLabel) {
    final label = modelLabel.trim();
    if (label.isEmpty) {
      throw const FormatException('BISINDO label cannot be empty');
    }

    final upper = label.toUpperCase();
    if (upper.startsWith('LETTER_')) {
      final value = upper.substring('LETTER_'.length).trim();
      if (value.length != 1 || !RegExp(r'^[A-Z]$').hasMatch(value)) {
        throw FormatException('Invalid alphabet label: $modelLabel');
      }
      return ParsedSignLabel(type: SignTokenType.letter, value: value);
    }

    if (upper.startsWith('WORD_')) {
      final value = label
          .substring('WORD_'.length)
          .replaceAll('_', ' ')
          .trim()
          .toLowerCase();
      if (value.isEmpty) {
        throw FormatException('Invalid word label: $modelLabel');
      }
      return ParsedSignLabel(type: SignTokenType.word, value: value);
    }

    // A future alphabet model may expose plain A-Z labels.
    if (upper.length == 1 && RegExp(r'^[A-Z]$').hasMatch(upper)) {
      return ParsedSignLabel(type: SignTokenType.letter, value: upper);
    }

    return ParsedSignLabel(
      type: SignTokenType.word,
      value: label.replaceAll('_', ' ').toLowerCase(),
    );
  }
}

class SignTokenComposer {
  const SignTokenComposer();

  String compose(Iterable<SignToken> tokens) {
    final parts = <String>[];
    final letters = StringBuffer();

    void flushLetters() {
      if (letters.isEmpty) return;
      parts.add(letters.toString());
      letters.clear();
    }

    for (final token in tokens) {
      switch (token.type) {
        case SignTokenType.letter:
          letters.write(token.value.toUpperCase());
        case SignTokenType.word:
          flushLetters();
          final word = token.value.trim();
          if (word.isNotEmpty) parts.add(word);
        case SignTokenType.space:
          flushLetters();
      }
    }
    flushLetters();
    return parts.join(' ').trim();
  }
}
