/// Mode pengenalan BISINDO: Unified (Gabungan Kata & Huruf), Huruf (alphabet), atau Kata (word).
enum BisindoMode {
  unified,
  alphabet,
  word;

  bool get isUnified => this == BisindoMode.unified;
  bool get isAlphabet => this == BisindoMode.alphabet;
  bool get isWord => this == BisindoMode.word;

  String get label {
    switch (this) {
      case BisindoMode.unified:
        return 'GABUNGAN';
      case BisindoMode.alphabet:
        return 'HURUF';
      case BisindoMode.word:
        return 'KATA';
    }
  }
}
