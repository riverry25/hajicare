import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/currency_code.dart';
import 'money_aggregator.dart';

/// Immutable snapshot representing multi-currency exchange rates relative to a base currency.
class ExchangeRateSnapshot {
  final CurrencyCode base;
  final Map<CurrencyCode, double> rates;
  final DateTime updatedAt;
  final String? apiUtcString;

  const ExchangeRateSnapshot({
    required this.base,
    required this.rates,
    required this.updatedAt,
    this.apiUtcString,
  });

  /// Computes cross-rate from [from] to [to].
  /// Returns `1.0` if [from] equals [to].
  double getRate(CurrencyCode from, CurrencyCode to) {
    if (from == to) return 1.0;
    final rateFrom = rates[from];
    final rateTo = rates[to];
    if (rateFrom == null || rateTo == null || rateFrom <= 0) {
      return 1.0;
    }
    return rateTo / rateFrom;
  }

  /// Converts [amount] from [from] to [to].
  double convert(
    double amount, {
    required CurrencyCode from,
    required CurrencyCode to,
  }) {
    if (from == to) return amount;
    return amount * getRate(from, to);
  }
}

/// Service managing multi-currency exchange rates (SAR, IDR, USD) with
/// automatic caching, in-flight request guarding, cross-rate calculation,
/// background staleness refresh, and graceful offline fallback.
class CurrencyRateService implements CurrencyConversionService {
  CurrencyRateService._();
  static final CurrencyRateService instance = CurrencyRateService._();

  static const String _kRateKey = 'hajicare_sar_to_idr_rate';
  static const String _kLastUpdatedKey = 'hajicare_sar_to_idr_last_updated';
  static const String _kApiUpdateUtcKey = 'hajicare_sar_to_idr_utc_string';
  static const String _kRatesMapKey = 'hajicare_multi_fx_rates_map';

  /// Initial benchmark rate for 1 SAR to IDR (Rp 4,750).
  static const double defaultRate = 4750.0;

  /// Default benchmark exchange rate snapshot (Base USD).
  /// 1 USD = 3.75 SAR
  /// 1 USD = 17,812.5 IDR (=> 1 SAR = 4,750 IDR)
  static final ExchangeRateSnapshot defaultSnapshot = ExchangeRateSnapshot(
    base: CurrencyCode.usd,
    rates: const {
      CurrencyCode.usd: 1.0,
      CurrencyCode.sar: 3.75,
      CurrencyCode.idr: 17812.5,
    },
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    apiUtcString: null,
  );

  /// Cache expiration before attempting background refresh (12 hours).
  static const Duration _cacheStaleness = Duration(hours: 12);

  ExchangeRateSnapshot _snapshot = defaultSnapshot;
  bool _isFetching = false;
  bool _isInitialized = false;

  /// Current exchange rate snapshot.
  ExchangeRateSnapshot get snapshot => _snapshot;

  /// Current SAR to IDR rate (preserved for backward compatibility).
  double get currentRate =>
      _snapshot.getRate(CurrencyCode.sar, CurrencyCode.idr);

  DateTime? get lastUpdated => _snapshot.updatedAt.millisecondsSinceEpoch == 0
      ? null
      : _snapshot.updatedAt;

  String? get lastApiUtcTime => _snapshot.apiUtcString;

  bool get isFetching => _isFetching;

  /// Notifier triggered whenever active rates update.
  final ValueNotifier<double> rateNotifier = ValueNotifier<double>(defaultRate);

  /// Initializes exchange rates from persistent SharedPreferences storage,
  /// falling back to defaults, and triggers background refresh if stale.
  Future<void> init() async {
    if (_isInitialized) {
      autoSyncIfStale();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRatesJson = prefs.getString(_kRatesMapKey);
      final savedTime = prefs.getString(_kLastUpdatedKey);
      final apiUtc = prefs.getString(_kApiUpdateUtcKey);
      final savedSarToIdr = prefs.getDouble(_kRateKey);

      if (savedRatesJson != null) {
        try {
          final decoded = jsonDecode(savedRatesJson) as Map<String, dynamic>;
          final Map<CurrencyCode, double> loadedRates = {};
          decoded.forEach((key, val) {
            final code = CurrencyCode.tryParse(key);
            if (code != null && val is num && val > 0) {
              loadedRates[code] = val.toDouble();
            }
          });

          if (loadedRates.containsKey(CurrencyCode.sar) &&
              loadedRates.containsKey(CurrencyCode.idr) &&
              loadedRates.containsKey(CurrencyCode.usd)) {
            _snapshot = ExchangeRateSnapshot(
              base: CurrencyCode.usd,
              rates: loadedRates,
              updatedAt: savedTime != null
                  ? (DateTime.tryParse(savedTime) ?? DateTime.now())
                  : DateTime.now(),
              apiUtcString: apiUtc,
            );
          }
        } catch (e) {
          debugPrint('[MoneyFX] Error reading cached rates: $e');
        }
      } else if (savedSarToIdr != null &&
          savedSarToIdr > 500 &&
          savedSarToIdr < 30000) {
        _snapshot = ExchangeRateSnapshot(
          base: CurrencyCode.usd,
          rates: {
            CurrencyCode.usd: 1.0,
            CurrencyCode.sar: 3.75,
            CurrencyCode.idr: 3.75 * savedSarToIdr,
          },
          updatedAt: savedTime != null
              ? (DateTime.tryParse(savedTime) ?? DateTime.now())
              : DateTime.now(),
          apiUtcString: apiUtc,
        );
      }

      rateNotifier.value = currentRate;
      _isInitialized = true;

      // Automatically sync in background if cache is stale or missing
      autoSyncIfStale();
    } catch (e) {
      debugPrint('[MoneyFX] init error: $e');
    }
  }

  /// Checks if cached rate is older than 12 hours (or never fetched) and triggers background sync.
  Future<void> autoSyncIfStale() async {
    final now = DateTime.now();
    final bool isStale =
        lastUpdated == null || now.difference(lastUpdated!) > _cacheStaleness;
    if (isStale && !_isFetching) {
      fetchLatestOnlineRate();
    }
  }

  /// Converts [amount] from [from] currency to [to] currency.
  /// If `from == to`, returns [amount] immediately without calculation.
  @override
  double convert({
    required double amount,
    required CurrencyCode from,
    required CurrencyCode to,
  }) {
    if (from == to) return amount;
    return _snapshot.convert(amount, from: from, to: to);
  }

  /// Returns cross-rate between [from] and [to].
  double getRate(CurrencyCode from, CurrencyCode to) {
    return _snapshot.getRate(from, to);
  }

  /// Backward-compatible conversion from SAR to IDR.
  double convertToRupiah(double riyal) {
    return convert(amount: riyal, from: CurrencyCode.sar, to: CurrencyCode.idr);
  }

  /// Sets and persists custom rates, updating SharedPreferences.
  Future<void> setCustomRates(
    Map<CurrencyCode, double> newRates, {
    String? utcTimeString,
  }) async {
    _snapshot = ExchangeRateSnapshot(
      base: CurrencyCode.usd,
      rates: Map.unmodifiable(newRates),
      updatedAt: DateTime.now(),
      apiUtcString: utcTimeString,
    );
    rateNotifier.value = currentRate;

    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = {
        for (final entry in _snapshot.rates.entries)
          entry.key.code: entry.value,
      };
      await prefs.setString(_kRatesMapKey, jsonEncode(mapToSave));
      await prefs.setDouble(_kRateKey, currentRate);
      await prefs.setString(
        _kLastUpdatedKey,
        _snapshot.updatedAt.toIso8601String(),
      );
      if (_snapshot.apiUtcString != null) {
        await prefs.setString(_kApiUpdateUtcKey, _snapshot.apiUtcString!);
      }
    } catch (e) {
      debugPrint('[MoneyFX] Error saving rates: $e');
    }
  }

  /// Sets custom SAR -> IDR rate while keeping base cross-rates consistent.
  Future<void> setCustomRate(
    double newSarToIdrRate, {
    String? utcTimeString,
  }) async {
    if (newSarToIdrRate <= 0) return;
    final currentUsdToSar = _snapshot.rates[CurrencyCode.sar] ?? 3.75;
    final updatedRates = {
      CurrencyCode.usd: 1.0,
      CurrencyCode.sar: currentUsdToSar,
      CurrencyCode.idr: currentUsdToSar * newSarToIdrRate,
    };
    await setCustomRates(updatedRates, utcTimeString: utcTimeString);
  }

  /// Resets exchange rates to default benchmark and refetches online.
  Future<void> resetToDefault() async {
    await setCustomRates(defaultSnapshot.rates);
    await fetchLatestOnlineRate();
  }

  /// Fetches live multi-currency rates from open.er-api.com (base USD).
  /// Falls back gracefully without throwing if offline or unreachable.
  Future<bool> fetchLatestOnlineRate() async {
    if (_isFetching) return false;
    _isFetching = true;

    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map &&
            data['result'] == 'success' &&
            data['rates'] is Map) {
          final ratesMap = data['rates'] as Map;
          final sarNum = ratesMap['SAR'];
          final idrNum = ratesMap['IDR'];
          final usdNum = ratesMap['USD'] ?? 1.0;

          if (sarNum is num && idrNum is num && usdNum is num) {
            final double sar = sarNum.toDouble();
            final double idr = idrNum.toDouble();
            final double usd = usdNum.toDouble();

            if (sar > 1.0 && sar < 10.0 && idr > 5000.0 && idr < 50000.0) {
              final String? utcTime = data['time_last_update_utc']?.toString();
              final freshRates = {
                CurrencyCode.usd: usd,
                CurrencyCode.sar: sar,
                CurrencyCode.idr: idr,
              };

              await setCustomRates(freshRates, utcTimeString: utcTime);
              debugPrint(
                '[MoneyFX] Live rates updated: 1 USD = $usd, 1 SAR = ${(idr / sar).toStringAsFixed(1)} IDR (UTC: $utcTime)',
              );
              _isFetching = false;
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[MoneyFX] Online fetch failed (offline or timeout): $e');
    } finally {
      _isFetching = false;
    }
    return false;
  }
}
