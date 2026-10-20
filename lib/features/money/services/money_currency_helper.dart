import '../models/currency_code.dart';

/// Formats numeric currency values into clean display strings for UI presentation.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Formats [amount] according to [currency] rules.
  static String format(double amount, CurrencyCode currency) {
    switch (currency) {
      case CurrencyCode.sar:
        return formatSar(amount);
      case CurrencyCode.idr:
        return formatRupiah(amount);
      case CurrencyCode.usd:
        return formatUsd(amount);
    }
  }

  /// Formats Saudi Riyal amounts.
  /// E.g. 15.0 -> "15 SAR", 0.50 -> "0.50 SAR"
  static String formatSar(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt()} SAR';
    }
    return '${amount.toStringAsFixed(2)} SAR';
  }

  /// Formats Indonesian Rupiah amounts with dot thousand separators.
  /// E.g. 43000 -> "Rp 43.000", 2150000 -> "Rp 2.150.000"
  static String formatRupiah(double rupiah) {
    final int rounded = rupiah.round();
    if (rounded <= 0) return 'Rp 0';
    final str = rounded.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    final formatted = buffer.toString().split('').reversed.join('');
    return 'Rp $formatted';
  }

  /// Formats US Dollar amounts.
  /// E.g. 35.0 -> "$35.00", 20.5 -> "$20.50"
  static String formatUsd(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '\$${amount.toStringAsFixed(2)}';
  }
}

/// Generates natural Indonesian and English spoken text for Text-to-Speech (TTS).
class MoneySpeechFormatter {
  MoneySpeechFormatter._();

  /// Converts an integer number into natural spoken words based on [languageCode] ('id' or 'en').
  static String numberToWords(int number, {String? languageCode}) {
    final lang = languageCode?.toLowerCase() ?? 'id';
    if (lang == 'en') {
      return numberToEnglishWords(number);
    }
    return numberToIndonesianWords(number);
  }

  /// Converts an integer number into natural Indonesian spoken words.
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
    } else if (number < 1000000000) {
      final millions = number ~/ 1000000;
      final remainder = number % 1000000;
      return '${numberToIndonesianWords(millions)} juta${remainder > 0 ? ' ${numberToIndonesianWords(remainder)}' : ''}';
    } else if (number < 1000000000000) {
      final billions = number ~/ 1000000000;
      final remainder = number % 1000000000;
      return '${numberToIndonesianWords(billions)} miliar${remainder > 0 ? ' ${numberToIndonesianWords(remainder)}' : ''}';
    }

    return number.toString();
  }

  /// Converts an integer number into natural English spoken words.
  static String numberToEnglishWords(int number) {
    if (number == 0) return 'zero';

    final units = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen',
    ];
    final tens = [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety',
    ];

    if (number < 20) {
      return units[number];
    } else if (number < 100) {
      final t = number ~/ 10;
      final r = number % 10;
      return '${tens[t]}${r > 0 ? '-${units[r]}' : ''}';
    } else if (number < 1000) {
      final h = number ~/ 100;
      final r = number % 100;
      return '${units[h]} hundred${r > 0 ? ' and ${numberToEnglishWords(r)}' : ''}';
    } else if (number < 1000000) {
      final th = number ~/ 1000;
      final r = number % 1000;
      return '${numberToEnglishWords(th)} thousand${r > 0 ? ' ${numberToEnglishWords(r)}' : ''}';
    } else if (number < 1000000000) {
      final m = number ~/ 1000000;
      final r = number % 1000000;
      return '${numberToEnglishWords(m)} million${r > 0 ? ' ${numberToEnglishWords(r)}' : ''}';
    } else if (number < 1000000000000) {
      final b = number ~/ 1000000000;
      final r = number % 1000000000;
      return '${numberToEnglishWords(b)} billion${r > 0 ? ' ${numberToEnglishWords(r)}' : ''}';
    }

    return number.toString();
  }

  /// Converts a numeric amount to natural spoken sentence for the given currency.
  static String amountToSpoken(
    double amount,
    CurrencyCode currency, {
    bool includeCurrencyName = true,
    String? languageCode,
  }) {
    final lang = languageCode?.toLowerCase() ?? 'id';
    if (lang == 'en') {
      return amountToSpokenEn(
        amount,
        currency,
        includeCurrencyName: includeCurrencyName,
      );
    }

    switch (currency) {
      case CurrencyCode.sar:
        return _sarToSpoken(amount, includeName: includeCurrencyName);
      case CurrencyCode.idr:
        return _idrToSpoken(amount, includeName: includeCurrencyName);
      case CurrencyCode.usd:
        return _usdToSpoken(amount, includeName: includeCurrencyName);
    }
  }

  /// Converts a numeric amount to natural English spoken sentence.
  static String amountToSpokenEn(
    double amount,
    CurrencyCode currency, {
    bool includeCurrencyName = true,
  }) {
    switch (currency) {
      case CurrencyCode.sar:
        return _sarToSpokenEn(amount, includeName: includeCurrencyName);
      case CurrencyCode.idr:
        return _idrToSpokenEn(amount, includeName: includeCurrencyName);
      case CurrencyCode.usd:
        return _usdToSpokenEn(amount, includeName: includeCurrencyName);
    }
  }

  static String _sarToSpoken(double amount, {bool includeName = true}) {
    if (amount <= 0) {
      return includeName ? 'nol Riyal Saudi' : 'nol';
    }

    final whole = amount.floor();
    final halala = ((amount - whole) * 100).round();

    if (whole == 0 && halala > 0) {
      return '${numberToIndonesianWords(halala)} Halala';
    }

    final wholeWords = includeName
        ? '${numberToIndonesianWords(whole)} Riyal Saudi'
        : numberToIndonesianWords(whole);

    if (halala > 0) {
      return '$wholeWords dan ${numberToIndonesianWords(halala)} Halala';
    }
    return wholeWords;
  }

  static String _sarToSpokenEn(double amount, {bool includeName = true}) {
    if (amount <= 0) {
      return includeName ? 'zero Saudi Riyal' : 'zero';
    }

    final whole = amount.floor();
    final halala = ((amount - whole) * 100).round();

    if (whole == 0 && halala > 0) {
      return '${numberToEnglishWords(halala)} Halala';
    }

    final wholeWords = includeName
        ? '${numberToEnglishWords(whole)} Saudi Riyal'
        : numberToEnglishWords(whole);

    if (halala > 0) {
      return '$wholeWords and ${numberToEnglishWords(halala)} Halala';
    }
    return wholeWords;
  }

  static String _idrToSpoken(double amount, {bool includeName = true}) {
    final int rounded = amount.round();
    if (rounded <= 0) {
      return includeName ? 'nol Rupiah' : 'nol';
    }
    final words = numberToIndonesianWords(rounded);
    return includeName ? '$words Rupiah' : words;
  }

  static String _idrToSpokenEn(double amount, {bool includeName = true}) {
    final int rounded = amount.round();
    if (rounded <= 0) {
      return includeName ? 'zero Indonesian Rupiah' : 'zero';
    }
    final words = numberToEnglishWords(rounded);
    return includeName ? '$words Indonesian Rupiah' : words;
  }

  static String _usdToSpoken(double amount, {bool includeName = true}) {
    if (amount <= 0) {
      return includeName ? 'nol Dolar Amerika' : 'nol';
    }

    final whole = amount.floor();
    final cents = ((amount - whole) * 100).round();

    final wholeWords = includeName
        ? '${numberToIndonesianWords(whole)} Dolar Amerika'
        : numberToIndonesianWords(whole);

    if (cents > 0) {
      return '$wholeWords ${numberToIndonesianWords(cents)} sen';
    }
    return wholeWords;
  }

  static String _usdToSpokenEn(double amount, {bool includeName = true}) {
    if (amount <= 0) {
      return includeName ? 'zero US Dollar' : 'zero';
    }

    final whole = amount.floor();
    final cents = ((amount - whole) * 100).round();

    final wholeWords = includeName
        ? '${numberToEnglishWords(whole)} US Dollar'
        : numberToEnglishWords(whole);

    if (cents > 0) {
      return '$wholeWords and ${numberToEnglishWords(cents)} cents';
    }
    return wholeWords;
  }

  /// Connects items with commas and "dan" (ID) or "and" (EN
  /// e.g. ["A", "B", "C"] -> "A, B, dan C" or "A, B, and C"
  static String joinNaturalSpoken(List<String> items, {String? languageCode}) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first;
    final isEn = languageCode?.toLowerCase() == 'en';
    final conjunction = isEn ? 'and' : 'dan';
    if (items.length == 2) return '${items[0]} $conjunction ${items[1]}';
    final leading = items.sublist(0, items.length - 1).join(', ');
    return '$leading, $conjunction ${items.last}';
  }
}
