enum SignTokenType { word, letter, space }

class SignToken {
  final SignTokenType type;
  final String value;

  const SignToken({required this.type, required this.value});

  const SignToken.word(String value)
    : this(type: SignTokenType.word, value: value);

  const SignToken.letter(String value)
    : this(type: SignTokenType.letter, value: value);

  const SignToken.space() : this(type: SignTokenType.space, value: ' ');

  @override
  bool operator ==(Object other) =>
      other is SignToken && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);
}

class ParsedSignLabel {
  final SignTokenType type;
  final String value;

  const ParsedSignLabel({required this.type, required this.value});

  SignToken toToken() => SignToken(type: type, value: value);
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
