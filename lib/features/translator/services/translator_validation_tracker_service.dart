import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single logged test trial for Translator (TC-03).
class TranslatorTestLog {
  final String id;
  final DateTime timestamp;
  final String sourceLang;
  final String targetLang;
  final String inputText;
  final String translatedText;
  final String inputMethod; // 'Teks' or 'Suara'
  final double durationSeconds;
  final bool isSuccess;
  final String? errorMessage;

  TranslatorTestLog({
    required this.id,
    required this.timestamp,
    required this.sourceLang,
    required this.targetLang,
    required this.inputText,
    required this.translatedText,
    required this.inputMethod,
    required this.durationSeconds,
    required this.isSuccess,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sourceLang': sourceLang,
    'targetLang': targetLang,
    'inputText': inputText,
    'translatedText': translatedText,
    'inputMethod': inputMethod,
    'durationSeconds': durationSeconds,
    'isSuccess': isSuccess,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory TranslatorTestLog.fromJson(Map<String, dynamic> json) =>
      TranslatorTestLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        sourceLang: json['sourceLang'] as String? ?? 'id',
        targetLang: json['targetLang'] as String? ?? 'ar',
        inputText: json['inputText'] as String? ?? '',
        translatedText: json['translatedText'] as String? ?? '',
        inputMethod: json['inputMethod'] as String? ?? 'Teks',
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
        isSuccess: json['isSuccess'] as bool? ?? false,
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Service to track and persist validation test trials for Translator (TC-03).
class TranslatorValidationTrackerService {
  TranslatorValidationTrackerService._();
  static final TranslatorValidationTrackerService instance =
      TranslatorValidationTrackerService._();

  static const String _storageKey = 'hajicare_translator_validation_logs';
  final ValueNotifier<List<TranslatorTestLog>> logsNotifier =
      ValueNotifier<List<TranslatorTestLog>>([]);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        logsNotifier.value = decoded
            .map(
              (item) =>
                  TranslatorTestLog.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[TranslatorValidationTracker] Failed to load logs: $e');
    }
    _isInitialized = true;
  }

  Future<void> logTrial({
    required String sourceLang,
    required String targetLang,
    required String inputText,
    required String translatedText,
    required String inputMethod,
    required double durationSeconds,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    await init();
    final entry = TranslatorTestLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      sourceLang: sourceLang,
      targetLang: targetLang,
      inputText: inputText,
      translatedText: translatedText,
      inputMethod: inputMethod,
      durationSeconds: durationSeconds,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );

    final updated = List<TranslatorTestLog>.from(logsNotifier.value)
      ..add(entry);
    logsNotifier.value = updated;
    await _save(updated);

    debugPrint('\n======================================================');
    debugPrint('🌐 LOG VALIDASI PENERJEMAH (TC-03) BARU TERCATAT:');
    debugPrint(
      'Percobaan #${updated.length} | [$inputMethod: $sourceLang -> $targetLang] | Input: "$inputText" -> "$translatedText" | Durasi: ${durationSeconds.toStringAsFixed(2)}s | Status: ${isSuccess ? "BERHASIL ✅" : "GAGAL ❌"}',
    );
    debugPrint('======================================================\n');
  }

  Future<void> clearAll() async {
    logsNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<TranslatorTestLog> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[TranslatorValidationTracker] Failed to save logs: $e');
    }
  }
}
