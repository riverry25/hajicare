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

class RiyalCurrencyHelper {
  RiyalCurrencyHelper._();

  static const Map<String, RiyalDenominationInfo> _denominationMap = {
    'fifty halalas': RiyalDenominationInfo(
      amount: 0.50,
      displayName: '0.50 Riyal',
      spokenName: 'Lima Puluh Halala',
      isCoin: true,
    ),
    'fifty riyal': RiyalDenominationInfo(
      amount: 50.0,
      displayName: '50 Riyal',
      spokenName: 'Lima Puluh Riyal',
      isCoin: false,
    ),
    'five halalas': RiyalDenominationInfo(
      amount: 0.05,
      displayName: '0.05 Riyal',
      spokenName: 'Lima Halala',
      isCoin: true,
    ),
    'five hundred riyal': RiyalDenominationInfo(
      amount: 500.0,
      displayName: '500 Riyal',
      spokenName: 'Lima Ratus Riyal',
      isCoin: false,
    ),
    'five riyal': RiyalDenominationInfo(
      amount: 5.0,
      displayName: '5 Riyal',
      spokenName: 'Lima Riyal',
      isCoin: false,
    ),
    'one halalas': RiyalDenominationInfo(
      amount: 0.01,
      displayName: '0.01 Riyal',
      spokenName: 'Satu Halala',
      isCoin: true,
    ),
    'one hundred riyal': RiyalDenominationInfo(
      amount: 100.0,
      displayName: '100 Riyal',
      spokenName: 'Seratus Riyal',
      isCoin: false,
    ),
    'one riyal': RiyalDenominationInfo(
      amount: 1.0,
      displayName: '1 Riyal',
      spokenName: 'Satu Riyal',
      isCoin: false,
    ),
    'ten halalas': RiyalDenominationInfo(
      amount: 0.10,
      displayName: '0.10 Riyal',
      spokenName: 'Sepuluh Halala',
      isCoin: true,
    ),
    'ten riyal': RiyalDenominationInfo(
      amount: 10.0,
      displayName: '10 Riyal',
      spokenName: 'Sepuluh Riyal',
      isCoin: false,
    ),
    'twenty five halalas': RiyalDenominationInfo(
      amount: 0.25,
      displayName: '0.25 Riyal',
      spokenName: 'Dua Puluh Lima Halala',
      isCoin: true,
    ),
    'twenty riyal': RiyalDenominationInfo(
      amount: 20.0,
      displayName: '20 Riyal',
      spokenName: 'Dua Puluh Riyal',
      isCoin: false,
    ),
    'two hundred riyal': RiyalDenominationInfo(
      amount: 200.0,
      displayName: '200 Riyal',
      spokenName: 'Dua Ratus Riyal',
      isCoin: false,
    ),
    'two riyal': RiyalDenominationInfo(
      amount: 2.0,
      displayName: '2 Riyal',
      spokenName: 'Dua Riyal',
      isCoin: false,
    ),
  };

  /// Retrieves denomination info for a raw class label.
  static RiyalDenominationInfo? getInfo(String rawLabel) {
    final key = rawLabel.trim().toLowerCase();
    return _denominationMap[key];
  }

  /// Formats total amount into clean Indonesian currency text.
  /// E.g. 75.0 -> "75 Riyal", 75.5 -> "75.50 Riyal"
  static String formatAmount(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} Riyal';
    }
    return '${amount.toStringAsFixed(2)} Riyal';
  }

  /// Converts an integer number (up to 999999) to Indonesian spoken words.
  static String numberToIndonesianWords(int number) {
    if (number == 0) return 'nol';

    final units = [
      '',
      'satu',
      'dua',
      'tiga',
      'empat',
      'lima',
      'enam',
      'tujuh',
      'delapan',
      'sembilan',
      'sepuluh',
      'sebelas',
    ];

    if (number < 12) {
      return units[number];
    } else if (number < 20) {
      return '${units[number - 10]} belas';
    } else if (number < 100) {
      final tens = number ~/ 10;
      final remainder = number % 10;
      return '${units[tens]} puluh${remainder > 0 ? ' ${units[remainder]}' : ''}';
    } else if (number < 200) {
      final remainder = number - 100;
      return 'seratus${remainder > 0 ? ' ${numberToIndonesianWords(remainder)}' : ''}';
    } else if (number < 1000) {
      final hundreds = number ~/ 100;
      final remainder = number % 100;
      return '${units[hundreds]} ratus${remainder > 0 ? ' ${numberToIndonesianWords(remainder)}' : ''}';
    } else if (number < 2000) {
      final remainder = number - 1000;
      return 'seribu${remainder > 0 ? ' ${numberToIndonesianWords(remainder)}' : ''}';
    } else if (number < 1000000) {
      final thousands = number ~/ 1000;
      final remainder = number % 1000;
      return '${numberToIndonesianWords(thousands)} ribu${remainder > 0 ? ' ${numberToIndonesianWords(remainder)}' : ''}';
    }

    return number.toString();
  }

  /// Converts a total Riyal amount to natural Indonesian spoken sentence.
  /// E.g. 125.0 -> "seratus dua puluh lima Riyal"
  /// E.g. 0.50 -> "lima puluh halala"
  static String totalToSpokenIndonesian(double amount) {
    if (amount <= 0) return 'nol Riyal';

    final whole = amount.floor();
    final halala = ((amount - whole) * 100).round();

    if (whole == 0 && halala > 0) {
      return '${numberToIndonesianWords(halala)} halala';
    }

    final wholeWords = '${numberToIndonesianWords(whole)} Riyal';
    if (halala > 0) {
      return '$wholeWords dan ${numberToIndonesianWords(halala)} halala';
    }
    return wholeWords;
  }
}
