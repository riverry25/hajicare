import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single logged test trial for Text-to-Speech (TC-05).
class TtsTestLog {
  final String id;
  final DateTime timestamp;
  final String textSpoken;
  final String languageCode;
  final double durationSeconds;
  final bool isSuccess;
  final String? errorMessage;

  TtsTestLog({
    required this.id,
    required this.timestamp,
    required this.textSpoken,
    required this.languageCode,
    required this.durationSeconds,
    required this.isSuccess,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'textSpoken': textSpoken,
    'languageCode': languageCode,
    'durationSeconds': durationSeconds,
    'isSuccess': isSuccess,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory TtsTestLog.fromJson(Map<String, dynamic> json) => TtsTestLog(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    textSpoken: json['textSpoken'] as String? ?? '',
    languageCode: json['languageCode'] as String? ?? 'ar',
    durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
    isSuccess: json['isSuccess'] as bool? ?? false,
    errorMessage: json['errorMessage'] as String?,
  );
}

/// Service to track and persist validation test trials for TTS (TC-05).
class TtsValidationTrackerService {
  TtsValidationTrackerService._();
  static final TtsValidationTrackerService instance =
      TtsValidationTrackerService._();

  static const String _storageKey = 'hajicare_tts_validation_logs';
  final ValueNotifier<List<TtsTestLog>> logsNotifier =
      ValueNotifier<List<TtsTestLog>>([]);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        logsNotifier.value = decoded
            .map((item) => TtsTestLog.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[TtsValidationTracker] Failed to load logs: $e');
    }
    _isInitialized = true;
  }

  Future<void> logTrial({
    required String textSpoken,
    required String languageCode,
    required double durationSeconds,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    await init();
    final entry = TtsTestLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      textSpoken: textSpoken,
      languageCode: languageCode,
      durationSeconds: durationSeconds,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
    );

    final updated = List<TtsTestLog>.from(logsNotifier.value)..add(entry);
    logsNotifier.value = updated;
    await _save(updated);

    debugPrint('\n======================================================');
    debugPrint('🔊 LOG VALIDASI TEXT-TO-SPEECH (TC-05) BARU TERCATAT:');
    debugPrint(
      'Percobaan #${updated.length} | [$languageCode] Teks: "$textSpoken" | Waktu Respon: ${durationSeconds.toStringAsFixed(2)}s | Status: ${isSuccess ? "BERHASIL ✅" : "GAGAL ❌"}',
    );
    debugPrint('======================================================\n');
  }

  Future<void> clearAll() async {
    logsNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<TtsTestLog> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[TtsValidationTracker] Failed to save logs: $e');
    }
  }
}
