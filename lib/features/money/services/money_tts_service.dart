import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/currency_code.dart';
import '../models/money_detection.dart';
import 'currency_rate_service.dart';
import 'money_aggregator.dart';
import 'money_currency_helper.dart';

/// Service responsible for managing Indonesian Text-to-Speech (TTS)
/// for multi-currency money detection with debounce, stabilization, and accessibility.
class MoneyTtsService {
  final FlutterTts _tts = FlutterTts();

  bool isVoiceEnabled = true;
  double speechRate = 0.45;
  int cooldownMs = 3500;

  bool _isInitialized = false;
  int _lastSpeakTime = 0;
  String _lastSpokenSignature = '';

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('id-ID');
      await _tts.setSpeechRate(speechRate);
      await _tts.setPitch(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[MoneyTTS] init error: $e');
    }
  }

  /// Sets speech rate and updates active TTS instance.
  Future<void> setSpeechRate(double rate) async {
    speechRate = rate;
    if (_isInitialized) {
      try {
        await _tts.setSpeechRate(rate);
      } catch (e) {
        debugPrint('[MoneyTTS] setSpeechRate error: $e');
      }
    }
  }

  /// Speaks the results of a single photo inference once, including multi-currency
  /// breakdowns and conversions into the selected target currency.
  Future<void> speakResults(
    List<MoneyDetection> detections, [
    dynamic totalAmountOrTotals,
    double? legacyExchangeRate,
  ]) async {
    if (!isVoiceEnabled || !_isInitialized) return;

    if (detections.isEmpty) {
      await speak(
        'Belum ada uang terdeteksi. Pastikan uang terlihat jelas dan coba foto lagi.',
      );
      return;
    }

    try {
      Map<CurrencyCode, double> totals;
      if (totalAmountOrTotals is Map<CurrencyCode, double>) {
        totals = totalAmountOrTotals;
      } else {
        totals = MoneyAggregator.totalsByCurrency(detections);
      }

      final conversionService = CurrencyRateService.instance;
      final sentence = buildSpeechSentence(
        detections: detections,
        totalsByCurrency: totals,
        targetCurrency: CurrencyCode.idr,
        conversionService: conversionService,
        isConversionAvailable: true,
      );

      await speak(sentence);
    } catch (e) {
      debugPrint('[MoneyTTS] speakResults error (non-fatal): $e');
    }
  }

  /// Builds a natural Indonesian speech sentence for single or multi-currency detections.
  String buildSpeechSentence({
    required List<MoneyDetection> detections,
    required Map<CurrencyCode, double> totalsByCurrency,
    CurrencyCode targetCurrency = CurrencyCode.idr,
    CurrencyConversionService? conversionService,
    bool isConversionAvailable = true,
  }) {
    if (detections.isEmpty) return '';

    final conv = conversionService ?? CurrencyRateService.instance;
    final isMixed = MoneyAggregator.hasMixedCurrencies(detections);

    // -------------------------------------------------------------------------
    // SINGLE CURRENCY SCENARIOS
    // -------------------------------------------------------------------------
    if (!isMixed) {
      final currency = detections.first.currency;
      final totalAmount = totalsByCurrency[currency] ?? 0.0;
      final countWords = MoneySpeechFormatter.numberToIndonesianWords(
        detections.length,
      );

      // Determine the other two currencies for equivalent announcement
      final otherCurrencies = CurrencyCode.values
          .where((c) => c != currency)
          .toList();

      String conversionSentence = '';
      if (isConversionAvailable && otherCurrencies.length >= 2) {
        final c1 = otherCurrencies[0];
        final c2 = otherCurrencies[1];

        final eq1 = conv.convert(amount: totalAmount, from: currency, to: c1);
        final eq2 = conv.convert(amount: totalAmount, from: currency, to: c2);

        final s1 = MoneySpeechFormatter.amountToSpoken(eq1, c1);
        final s2 = MoneySpeechFormatter.amountToSpoken(eq2, c2);

        conversionSentence = ' Setara sekitar $s1 dan $s2.';
      }

      if (detections.length == 1) {
        final item = detections.first;
        return 'Terdeteksi satu uang, ${item.spokenName}.$conversionSentence';
      }

      final itemsSpoken = MoneySpeechFormatter.joinNaturalSpoken(
        detections.map((d) => d.spokenName).toList(),
      );
      final totalSpoken = MoneySpeechFormatter.amountToSpoken(
        totalAmount,
        currency,
      );

      return 'Terdeteksi $countWords uang. $itemsSpoken. Total $totalSpoken.$conversionSentence';
    }

    // -------------------------------------------------------------------------
    // MIXED CURRENCY SCENARIOS
    // -------------------------------------------------------------------------
    final countWords = MoneySpeechFormatter.numberToIndonesianWords(
      detections.length,
    );
    final itemsSpoken = MoneySpeechFormatter.joinNaturalSpoken(
      detections.map((d) => d.spokenName).toList(),
    );

    // Format totals per currency: "A, B, dan C"
    final activeTotals = totalsByCurrency.entries
        .where((e) => e.value > 0)
        .map((e) => MoneySpeechFormatter.amountToSpoken(e.value, e.key))
        .toList();
    final totalsSpoken = MoneySpeechFormatter.joinNaturalSpoken(activeTotals);

    if (isConversionAvailable) {
      final grandTotal = MoneyAggregator.grandTotalIn(
        totals: totalsByCurrency,
        targetCurrency: targetCurrency,
        conversionService: conv,
      );
      final grandTotalSpoken = MoneySpeechFormatter.amountToSpoken(
        grandTotal,
        targetCurrency,
      );
      final targetName = targetCurrency.spokenName;

      return 'Terdeteksi $countWords uang. $itemsSpoken. '
          'Total per mata uang: $totalsSpoken. '
          'Jika seluruhnya dikonversikan ke $targetName, total setara sekitar $grandTotalSpoken.';
    } else {
      return 'Terdeteksi $countWords uang. '
          'Total: $totalsSpoken. '
          'Konversi mata uang sedang tidak tersedia.';
    }
  }

  /// Evaluates detections and speaks if stable or cooldown elapsed.
  Future<void> processDetections(
    List<MoneyDetection> detections, {
    Map<CurrencyCode, double>? totalsByCurrency,
  }) async {
    if (!isVoiceEnabled || !_isInitialized || detections.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final totals =
        totalsByCurrency ?? MoneyAggregator.totalsByCurrency(detections);
    final sortedItems = detections.map((d) => d.displayName).toList()..sort();
    final currentSignature =
        '${detections.length}_${totals.entries.map((e) => "${e.key.code}:${e.value}").join("|")}_${sortedItems.join(",")}';

    final bool signatureChanged = currentSignature != _lastSpokenSignature;
    final bool cooldownPassed = (now - _lastSpeakTime) >= cooldownMs;

    if (signatureChanged || cooldownPassed) {
      final sentence = buildSpeechSentence(
        detections: detections,
        totalsByCurrency: totals,
      );
      await speak(sentence);
      _lastSpokenSignature = currentSignature;
      _lastSpeakTime = now;
    }
  }

  /// Speaks immediate text (interrupts previous utterance safely).
  Future<void> speak(String text) async {
    if (!isVoiceEnabled || !_isInitialized || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[MoneyTTS] speak error: $e');
    }
  }

  /// Stops any currently playing speech safely without throwing.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[MoneyTTS] stop error: $e');
    }
  }

  void resetState() {
    _lastSpokenSignature = '';
    _lastSpeakTime = 0;
  }

  void dispose() {
    stop();
  }
}
