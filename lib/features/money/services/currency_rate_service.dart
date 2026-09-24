import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing dynamic Saudi Riyal (SAR) to Indonesian Rupiah (IDR) exchange rates.
/// Uses open.er-api.com (ExchangeRate-API) with automatic caching, background staleness refresh,
/// and graceful offline fallback.
class CurrencyRateService {
  CurrencyRateService._();
  static final CurrencyRateService instance = CurrencyRateService._();

  static const String _kRateKey = 'hajicare_sar_to_idr_rate';
  static const String _kLastUpdatedKey = 'hajicare_sar_to_idr_last_updated';
  static const String _kApiUpdateUtcKey = 'hajicare_sar_to_idr_utc_string';

  /// Initial benchmark rate (1 SAR ≈ Rp 4,750).
  static const double defaultRate = 4750.0;

  /// Cache expiration before attempting a background refresh (12 hours).
  static const Duration _cacheStaleness = Duration(hours: 12);

  double _currentRate = defaultRate;
  DateTime? _lastUpdated;
  String? _lastApiUtcTime;
  bool _isFetching = false;
  bool _isInitialized = false;

  double get currentRate => _currentRate;
  DateTime? get lastUpdated => _lastUpdated;
  String? get lastApiUtcTime => _lastApiUtcTime;
  bool get isFetching => _isFetching;

  final ValueNotifier<double> rateNotifier = ValueNotifier<double>(defaultRate);

  /// Initializes exchange rate from persistent SharedPreferences storage,
  /// and automatically triggers background online refresh if stale.
  Future<void> init() async {
    if (_isInitialized) {
      autoSyncIfStale();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRate = prefs.getDouble(_kRateKey);
      final savedTime = prefs.getString(_kLastUpdatedKey);
      _lastApiUtcTime = prefs.getString(_kApiUpdateUtcKey);

      if (savedRate != null && savedRate > 500 && savedRate < 30000) {
        _currentRate = savedRate;
      } else {
        _currentRate = defaultRate;
      }

      if (savedTime != null) {
        _lastUpdated = DateTime.tryParse(savedTime);
      }
      rateNotifier.value = _currentRate;
      _isInitialized = true;

      // Automatically sync in background if cache is stale or missing
      autoSyncIfStale();
    } catch (e) {
      debugPrint('[CurrencyRateService] init error: $e');
    }
  }

  /// Checks if cached rate is older than 12 hours (or never fetched) and triggers background sync.
  Future<void> autoSyncIfStale() async {
    final now = DateTime.now();
    final bool isStale =
        _lastUpdated == null || now.difference(_lastUpdated!) > _cacheStaleness;
    if (isStale && !_isFetching) {
      // Run asynchronously without blocking caller
      fetchLatestOnlineRate();
    }
  }

  /// Sets and persists a custom exchange rate chosen by user or fetched online.
  Future<void> setCustomRate(double newRate, {String? utcTimeString}) async {
    if (newRate <= 0) return;
    _currentRate = newRate;
    _lastUpdated = DateTime.now();
    if (utcTimeString != null) {
      _lastApiUtcTime = utcTimeString;
    }
    rateNotifier.value = newRate;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kRateKey, newRate);
      await prefs.setString(_kLastUpdatedKey, _lastUpdated!.toIso8601String());
      if (_lastApiUtcTime != null) {
        await prefs.setString(_kApiUpdateUtcKey, _lastApiUtcTime!);
      }
    } catch (e) {
      debugPrint('[CurrencyRateService] Error saving rate: $e');
    }
  }

  /// Resets exchange rate back to default benchmark and refetches online.
  Future<void> resetToDefault() async {
    await setCustomRate(defaultRate);
    await fetchLatestOnlineRate();
  }

  /// Fetches live SAR to IDR rate from open.er-api.com (ExchangeRate-API).
  /// Falls back gracefully without throwing if offline or unreachable.
  Future<bool> fetchLatestOnlineRate() async {
    if (_isFetching) return false;
    _isFetching = true;

    try {
      final url = Uri.parse('https://open.er-api.com/v6/latest/SAR');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        if (data is Map &&
            data['result'] == 'success' &&
            data['rates'] != null) {
          final rates = data['rates'] as Map;
          if (rates['IDR'] != null) {
            final double idrRate = (rates['IDR'] as num).toDouble();
            if (idrRate >= 1000 && idrRate <= 30000) {
              final String? utcTime = data['time_last_update_utc']?.toString();
              await setCustomRate(
                idrRate.roundToDouble(),
                utcTimeString: utcTime,
              );
              debugPrint(
                '[CurrencyRateService] Live rate updated: 1 SAR = $idrRate IDR (UTC: $utcTime)',
              );
              _isFetching = false;
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[CurrencyRateService] Online fetch failed (offline or timeout): $e',
      );
    } finally {
      _isFetching = false;
    }
    return false;
  }

  /// Converts Riyal to Rupiah using the current active rate.
  double convertToRupiah(double riyal) {
    return (riyal * _currentRate).roundToDouble();
  }
}
