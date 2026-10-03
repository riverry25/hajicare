import '../models/currency_code.dart';

/// Metadata associated with a parsed denomination from YOLO models.
class MoneyDenominationInfo {
  final CurrencyCode currency;
  final double amount;
  final String displayName;
  final String spokenName;
  final bool isCoin;

  const MoneyDenominationInfo({
    required this.currency,
    required this.amount,
    required this.displayName,
    required this.spokenName,
    this.isCoin = false,
  });
}

/// Centralized parser mapping YOLO class labels from `assets/models/labels.txt`
/// directly to structured [MoneyDenominationInfo].
class MoneyClassParser {
  MoneyClassParser._();

  static const Map<String, MoneyDenominationInfo> _labelMap = {
    // -------------------------------------------------------------------------
    // UNITED STATES DOLLAR (USD)
    // -------------------------------------------------------------------------
    'one dollar': MoneyDenominationInfo(
      currency: CurrencyCode.usd,
      amount: 1.0,
      displayName: '\$1',
      spokenName: 'satu Dolar Amerika',
      isCoin: false,
    ),
    'two dollar': MoneyDenominationInfo(
      currency: CurrencyCode.usd,
      amount: 2.0,
      displayName: '\$2',
      spokenName: 'dua Dolar Amerika',
      isCoin: false,
    ),
    'five dollar': MoneyDenominationInfo(
      currency: CurrencyCode.usd,
      amount: 5.0,
      displayName: '\$5',
      spokenName: 'lima Dolar Amerika',
      isCoin: false,
    ),
    'ten dollar': MoneyDenominationInfo(
      currency: CurrencyCode.usd,
      amount: 10.0,
      displayName: '\$10',
      spokenName: 'sepuluh Dolar Amerika',
      isCoin: false,
    ),
    'twenty dollar': MoneyDenominationInfo(
      currency: CurrencyCode.usd,
      amount: 20.0,
      displayName: '\$20',
      spokenName: 'dua puluh Dolar Amerika',
      isCoin: false,
    ),
    'fifty dollar': MoneyDenominationInfo(
      currency: CurrencyCode.usd,
      amount: 50.0,
      displayName: '\$50',
      spokenName: 'lima puluh Dolar Amerika',
      isCoin: false,
    ),
    'one hundred dollar': MoneyDenominationInfo(
      currency: CurrencyCode.usd,
      amount: 100.0,
      displayName: '\$100',
      spokenName: 'seratus Dolar Amerika',
      isCoin: false,
    ),

    // -------------------------------------------------------------------------
    // SAUDI RIYAL (SAR) — COINS
    // -------------------------------------------------------------------------
    'one halalas': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 0.01,
      displayName: '0.01 SAR',
      spokenName: 'satu Halala',
      isCoin: true,
    ),
    'five halalas': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 0.05,
      displayName: '0.05 SAR',
      spokenName: 'lima Halala',
      isCoin: true,
    ),
    'ten halalas': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 0.10,
      displayName: '0.10 SAR',
      spokenName: 'sepuluh Halala',
      isCoin: true,
    ),
    'twenty five halalas': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 0.25,
      displayName: '0.25 SAR',
      spokenName: 'dua puluh lima Halala',
      isCoin: true,
    ),
    'fifty halalas': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 0.50,
      displayName: '0.50 SAR',
      spokenName: 'lima puluh Halala',
      isCoin: true,
    ),

    // -------------------------------------------------------------------------
    // SAUDI RIYAL (SAR) — BANKNOTES
    // -------------------------------------------------------------------------
    'one riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 1.0,
      displayName: '1 SAR',
      spokenName: 'satu Riyal Saudi',
      isCoin: false,
    ),
    'two riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 2.0,
      displayName: '2 SAR',
      spokenName: 'dua Riyal Saudi',
      isCoin: false,
    ),
    'five riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 5.0,
      displayName: '5 SAR',
      spokenName: 'lima Riyal Saudi',
      isCoin: false,
    ),
    'ten riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 10.0,
      displayName: '10 SAR',
      spokenName: 'sepuluh Riyal Saudi',
      isCoin: false,
    ),
    'twenty riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 20.0,
      displayName: '20 SAR',
      spokenName: 'dua puluh Riyal Saudi',
      isCoin: false,
    ),
    'fifty riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 50.0,
      displayName: '50 SAR',
      spokenName: 'lima puluh Riyal Saudi',
      isCoin: false,
    ),
    'one hundred riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 100.0,
      displayName: '100 SAR',
      spokenName: 'seratus Riyal Saudi',
      isCoin: false,
    ),
    'two hundred riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 200.0,
      displayName: '200 SAR',
      spokenName: 'dua ratus Riyal Saudi',
      isCoin: false,
    ),
    'five hundred riyal': MoneyDenominationInfo(
      currency: CurrencyCode.sar,
      amount: 500.0,
      displayName: '500 SAR',
      spokenName: 'lima ratus Riyal Saudi',
      isCoin: false,
    ),

    // -------------------------------------------------------------------------
    // INDONESIAN RUPIAH (IDR) — COINS
    // -------------------------------------------------------------------------
    'one hundred coin rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 100.0,
      displayName: 'Rp100',
      spokenName: 'seratus Rupiah',
      isCoin: true,
    ),
    'two hundred coin rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 200.0,
      displayName: 'Rp200',
      spokenName: 'dua ratus Rupiah',
      isCoin: true,
    ),
    'five hundred coin rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 500.0,
      displayName: 'Rp500',
      spokenName: 'lima ratus Rupiah',
      isCoin: true,
    ),

    // -------------------------------------------------------------------------
    // INDONESIAN RUPIAH (IDR) — BANKNOTES
    // -------------------------------------------------------------------------
    'one thousand rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 1000.0,
      displayName: 'Rp1.000',
      spokenName: 'seribu Rupiah',
      isCoin: false,
    ),
    'two thousand rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 2000.0,
      displayName: 'Rp2.000',
      spokenName: 'dua ribu Rupiah',
      isCoin: false,
    ),
    'five thousand rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 5000.0,
      displayName: 'Rp5.000',
      spokenName: 'lima ribu Rupiah',
      isCoin: false,
    ),
    'ten thousand rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 10000.0,
      displayName: 'Rp10.000',
      spokenName: 'sepuluh ribu Rupiah',
      isCoin: false,
    ),
    'twenty thousand rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 20000.0,
      displayName: 'Rp20.000',
      spokenName: 'dua puluh ribu Rupiah',
      isCoin: false,
    ),
    'fifty thousand rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 50000.0,
      displayName: 'Rp50.000',
      spokenName: 'lima puluh ribu Rupiah',
      isCoin: false,
    ),
    'seventy five thousand rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 75000.0,
      displayName: 'Rp75.000',
      spokenName: 'tujuh puluh lima ribu Rupiah',
      isCoin: false,
    ),
    'one hundred thousand rupiah': MoneyDenominationInfo(
      currency: CurrencyCode.idr,
      amount: 100000.0,
      displayName: 'Rp100.000',
      spokenName: 'seratus ribu Rupiah',
      isCoin: false,
    ),
  };

  /// Parses a raw YOLO class label from model prediction into [MoneyDenominationInfo].
  /// Returns `null` if the class is not recognized.
  static MoneyDenominationInfo? parse(String rawLabel) {
    final key = rawLabel.trim().toLowerCase();
    return _labelMap[key];
  }

  /// Returns whether a label is a known class in the model.
  static bool isKnownLabel(String rawLabel) {
    return parse(rawLabel) != null;
  }

  /// All supported labels list.
  static List<String> get allLabels => _labelMap.keys.toList();
}
