import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/money_detection.dart';
import 'currency_rate_service.dart';
import 'riyal_currency_helper.dart';

/// Service responsible for managing Indonesian Text-to-Speech (TTS)
/// for multi-money detection with debounce, stabilization, and cooldown logic.
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
      debugPrint('MoneyTtsService init error: $e');
    }
  }

  /// Sets speech rate and updates active TTS instance.
  Future<void> setSpeechRate(double rate) async {
    speechRate = rate;
    if (_isInitialized) {
      await _tts.setSpeechRate(rate);
    }
  }

  /// Speaks the results of a single photo inference once, including Rupiah translation.
  Future<void> speakResults(
    List<MoneyDetection> detections,
    double totalAmount, {
    double? exchangeRate,
  }) async {
    if (!isVoiceEnabled || !_isInitialized) return;
    if (detections.isEmpty) {
      await speak(
        'Belum ada uang terdeteksi. Pastikan uang terlihat jelas dan coba foto lagi.',
      );
      return;
    }
    final rate = exchangeRate ?? CurrencyRateService.instance.currentRate;
    final speechSentence = _buildSpeechSentence(detections, totalAmount, rate);
    await speak(speechSentence);
  }

  /// Evaluates the current frame's detections and speaks if the detection state is stable
  /// and either represents a change in detected items or has passed cooldown.
  Future<void> processDetections(
    List<MoneyDetection> detections, {
    double? exchangeRate,
  }) async {
    if (!isVoiceEnabled || !_isInitialized) return;
    if (detections.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Create a deterministic signature based on sorted denominations and count
    final sortedDenominations = detections.map((d) => d.displayName).toList()
      ..sort();
    final double totalAmount = detections.fold(
      0.0,
      (sum, item) => sum + item.amount,
    );
    final rate = exchangeRate ?? CurrencyRateService.instance.currentRate;
    final currentSignature =
        '${detections.length}_${totalAmount.toStringAsFixed(2)}_${rate.toInt()}_${sortedDenominations.join(',')}';

    final bool signatureChanged = currentSignature != _lastSpokenSignature;
    final bool cooldownPassed = (now - _lastSpeakTime) >= cooldownMs;

    // Only speak when signature changed or cooldown elapsed
    if (signatureChanged || cooldownPassed) {
      final speechSentence = _buildSpeechSentence(
        detections,
        totalAmount,
        rate,
      );
      await speak(speechSentence);
      _lastSpokenSignature = currentSignature;
      _lastSpeakTime = now;
    }
  }

  /// Builds a natural Indonesian speech sentence for single or multiple detected items,
  /// seamlessly translating the Riyal value into its Rupiah equivalent.
  String _buildSpeechSentence(
    List<MoneyDetection> detections,
    double totalAmount,
    double exchangeRate,
  ) {
    if (detections.isEmpty) return '';

    if (detections.length == 1) {
      final item = detections.first;
      final rupiah = (item.amount * exchangeRate).roundToDouble();
      final rupiahWords = RiyalCurrencyHelper.rupiahToSpokenIndonesian(rupiah);
      return 'Terdeteksi satu uang, ${item.spokenName}, setara sekitar $rupiahWords.';
    }

    // Multi-money speech
    final countWords = RiyalCurrencyHelper.numberToIndonesianWords(
      detections.length,
    );
    final List<String> spokenItems = detections
        .map((d) => d.spokenName)
        .toList();

    // Format list: "A, B, C, dan D"
    String itemsListStr;
    if (spokenItems.length == 2) {
      itemsListStr = '${spokenItems[0]} dan ${spokenItems[1]}';
    } else {
      final allExceptLast = spokenItems
          .sublist(0, spokenItems.length - 1)
          .join(', ');
      itemsListStr = '$allExceptLast, dan ${spokenItems.last}';
    }

    final totalRupiah = (totalAmount * exchangeRate).roundToDouble();
    final totalSpoken = RiyalCurrencyHelper.totalWithRupiahSpoken(
      totalAmount,
      totalRupiah,
    );
    return 'Terdeteksi $countWords uang. $itemsListStr. Total $totalSpoken.';
  }

  /// Speaks immediate text (interrupts previous utterance).
  Future<void> speak(String text) async {
    if (!isVoiceEnabled || !_isInitialized || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('MoneyTtsService speak error: $e');
    }
  }

  /// Stops any currently playing speech.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('MoneyTtsService stop error: $e');
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
