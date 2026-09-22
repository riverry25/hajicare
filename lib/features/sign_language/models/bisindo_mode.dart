/// Mode pengenalan BISINDO: Unified (1 input gabungan), Kata (word), atau Huruf (alfabet).
enum BisindoMode {
  unified,
  word,
  alphabet;

  bool get isUnified => this == BisindoMode.unified;
  bool get isWord => this == BisindoMode.word;
  bool get isAlphabet => this == BisindoMode.alphabet;

  String get label {
    switch (this) {
      case BisindoMode.unified:
        return 'BISINDO';
      case BisindoMode.word:
        return 'KATA';
      case BisindoMode.alphabet:
        return 'HURUF';
    }
  }
}
