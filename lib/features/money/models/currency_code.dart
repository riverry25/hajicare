/// Supported currency codes in HajiCare multi-currency money recognition.
enum CurrencyCode {
  sar,
  idr,
  usd;

  /// ISO 4217 Currency Code in uppercase (e.g. 'SAR', 'IDR', 'USD').
  String get code {
    switch (this) {
      case CurrencyCode.sar:
        return 'SAR';
      case CurrencyCode.idr:
        return 'IDR';
      case CurrencyCode.usd:
        return 'USD';
    }
  }

  /// Currency symbol or abbreviation.
  String get symbol {
    switch (this) {
      case CurrencyCode.sar:
        return 'SAR';
      case CurrencyCode.idr:
        return 'Rp';
      case CurrencyCode.usd:
        return '\$';
    }
  }

  /// Official localized display name in Indonesian.
  String get displayName {
    switch (this) {
      case CurrencyCode.sar:
        return 'Riyal Saudi';
      case CurrencyCode.idr:
        return 'Rupiah Indonesia';
      case CurrencyCode.usd:
        return 'Dolar Amerika';
    }
  }

  /// Spoken currency name for Text-to-Speech in natural Indonesian.
  String get spokenName {
    switch (this) {
      case CurrencyCode.sar:
        return 'Riyal Saudi';
      case CurrencyCode.idr:
        return 'Rupiah';
      case CurrencyCode.usd:
        return 'Dolar Amerika';
    }
  }

  /// Parses a string representation (e.g. 'SAR', 'sar', 'idr', 'USD') into [CurrencyCode].
  static CurrencyCode? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toLowerCase();
    for (final c in CurrencyCode.values) {
      if (c.name == normalized || c.code.toLowerCase() == normalized) {
        return c;
      }
    }
    return null;
  }
}
