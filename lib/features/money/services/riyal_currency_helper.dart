import 'money_class_parser.dart';
import 'money_currency_helper.dart';

/// Legacy Denomination Info preserved for backward compatibility.
class RiyalDenominationInfo {
  final double amount;
  final String displayName;
  final String spokenName;
  final bool isCoin;

  const RiyalDenominationInfo({
    required this.amount,
    required this.displayName,
    required this.spokenName,
    this.isCoin = false,
  });
}

/// Legacy Riyal Currency Helper preserved for backward compatibility.
/// Internal logic now delegates to [MoneyClassParser] and [MoneyCurrencyHelper].
class RiyalCurrencyHelper {
  RiyalCurrencyHelper._();

  /// Retrieves denomination info for a raw class label.
  static RiyalDenominationInfo? getInfo(String rawLabel) {
    final parsed = MoneyClassParser.parse(rawLabel);
    if (parsed == null) return null;
    return RiyalDenominationInfo(
      amount: parsed.amount,
      displayName: parsed.displayName,
      spokenName: parsed.spokenName,
      isCoin: parsed.isCoin,
    );
  }

  /// Formats total amount into Riyal text.
  /// E.g. 75.0 -> "75 Riyal", 75.5 -> "75.50 Riyal"
  static String formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} Riyal';
    }
    return '${amount.toStringAsFixed(2)} Riyal';
  }

  /// Converts an integer number to Indonesian spoken words.
  static String numberToIndonesianWords(int number) {
    return MoneySpeechFormatter.numberToIndonesianWords(number);
  }

  /// Converts a total Riyal amount to natural Indonesian spoken sentence.
  /// E.g. 125.0 -> "seratus dua puluh lima Riyal"
  /// E.g. 0.50 -> "lima puluh halala"
  static String totalToSpokenIndonesian(double amount) {
    if (amount <= 0) return 'nol Riyal';

    final whole = amount.floor();
    final halala = ((amount - whole) * 100).round();

    if (whole == 0 && halala > 0) {
      return '${MoneySpeechFormatter.numberToIndonesianWords(halala)} halala';
    }

    final wholeWords =
        '${MoneySpeechFormatter.numberToIndonesianWords(whole)} Riyal';
    if (halala > 0) {
      return '$wholeWords dan ${MoneySpeechFormatter.numberToIndonesianWords(halala)} halala';
    }
    return wholeWords;
  }

  /// Formats an IDR amount into clean standard currency string with dots.
  /// E.g. 43000 -> "Rp 43.000", 2150000 -> "Rp 2.150.000"
  static String formatRupiah(double rupiah) {
    return CurrencyFormatter.formatRupiah(rupiah);
  }

  /// Converts an IDR amount to natural Indonesian spoken sentence.
  /// E.g. 43000 -> "empat puluh tiga ribu rupiah"
  /// E.g. 2150000 -> "dua juta seratus lima puluh ribu rupiah"
  static String rupiahToSpokenIndonesian(double rupiah) {
    final int rounded = rupiah.round();
    if (rounded <= 0) return 'nol rupiah';
    return '${MoneySpeechFormatter.numberToIndonesianWords(rounded)} rupiah';
  }

  /// Combines Riyal and converted Rupiah into a natural spoken announcement.
  /// E.g. 10 Riyal (rate 4300) -> "sepuluh Riyal, setara sekitar empat puluh tiga ribu rupiah"
  static String totalWithRupiahSpoken(double riyalAmount, double rupiahAmount) {
    final riyalText = totalToSpokenIndonesian(riyalAmount);
    if (rupiahAmount.round() <= 0) return riyalText;
    final rupiahText = rupiahToSpokenIndonesian(rupiahAmount);
    return '$riyalText, setara sekitar $rupiahText';
  }
}
