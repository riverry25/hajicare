/// Mode pengenalan BISINDO: Huruf (alphabet) atau Kata (word).
enum BisindoMode {
  alphabet,
  word;

  bool get isAlphabet => this == BisindoMode.alphabet;
  bool get isWord => this == BisindoMode.word;
  bool get isUnified => false;

  String get label {
    switch (this) {
      case BisindoMode.alphabet:
        return 'HURUF';
      case BisindoMode.word:
        return 'KATA';
    }
  }
}
