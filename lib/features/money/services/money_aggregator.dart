import '../models/currency_code.dart';
import '../models/money_detection.dart';

/// Contract for currency conversion used by aggregator.
abstract class CurrencyConversionService {
  double convert({
    required double amount,
    required CurrencyCode from,
    required CurrencyCode to,
  });
}

/// Utility performing multi-currency aggregation and arithmetic calculations
/// across detected money objects.
class MoneyAggregator {
  MoneyAggregator._();

  /// Calculates total monetary amount grouped by [CurrencyCode].
  ///
  /// E.g. [10 SAR, 5 SAR, 20 USD, 100000 IDR] ->
  /// `{ CurrencyCode.sar: 15.0, CurrencyCode.usd: 20.0, CurrencyCode.idr: 100000.0 }`
  static Map<CurrencyCode, double> totalsByCurrency(
    List<MoneyDetection> detections,
  ) {
    final Map<CurrencyCode, double> totals = {};
    for (final item in detections) {
      totals[item.currency] = (totals[item.currency] ?? 0.0) + item.amount;
    }
    return totals;
  }

  /// Calculates the count of physical currency items per [CurrencyCode].
  static Map<CurrencyCode, int> countsByCurrency(
    List<MoneyDetection> detections,
  ) {
    final Map<CurrencyCode, int> counts = {};
    for (final item in detections) {
      counts[item.currency] = (counts[item.currency] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns `true` if detections contain 2 or more different currencies.
  static bool hasMixedCurrencies(List<MoneyDetection> detections) {
    if (detections.length <= 1) return false;
    final first = detections.first.currency;
    return detections.any((d) => d.currency != first);
  }

  /// Returns the unique currency if all detections share the same currency,
  /// or `null` if mixed or empty.
  static CurrencyCode? singleCurrencyOrNull(List<MoneyDetection> detections) {
    if (detections.isEmpty) return null;
    final first = detections.first.currency;
    for (final d in detections) {
      if (d.currency != first) return null;
    }
    return first;
  }

  /// Calculates grand total converted equivalent into [targetCurrency]
  /// using the provided [conversionService].
  ///
  /// If currency equals [targetCurrency], exact original amount is used without rounding.
  static double grandTotalIn({
    required Map<CurrencyCode, double> totals,
    required CurrencyCode targetCurrency,
    required CurrencyConversionService conversionService,
  }) {
    double grandTotal = 0.0;
    for (final entry in totals.entries) {
      if (entry.key == targetCurrency) {
        grandTotal += entry.value;
      } else {
        grandTotal += conversionService.convert(
          amount: entry.value,
          from: entry.key,
          to: targetCurrency,
        );
      }
    }
    return grandTotal;
  }
}
