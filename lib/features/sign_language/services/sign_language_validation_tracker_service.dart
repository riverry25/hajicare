import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single recorded test trial for Sign Language (SIBI / BISINDO).
class SignValidationLog {
  final String id;
  final DateTime timestamp;
  final String model; // 'SIBI' or 'BISINDO'
  final String category; // 'Alfabet', 'Kata', 'Kalimat'
  final String groundTruth;
  final String detected;
  final bool isSuccess;
  final double confidence;
  final double inferenceDurationSeconds;

  SignValidationLog({
    required this.id,
    required this.timestamp,
    required this.model,
    required this.category,
    required this.groundTruth,
    required this.detected,
    required this.isSuccess,
    required this.confidence,
    this.inferenceDurationSeconds = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'model': model,
    'category': category,
    'groundTruth': groundTruth,
    'detected': detected,
    'isSuccess': isSuccess,
    'confidence': confidence,
    'inferenceDurationSeconds': inferenceDurationSeconds,
  };

  factory SignValidationLog.fromJson(Map<String, dynamic> json) =>
      SignValidationLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        model: json['model'] as String,
        category: json['category'] as String,
        groundTruth: json['groundTruth'] as String,
        detected: json['detected'] as String,
        isSuccess: json['isSuccess'] as bool,
        confidence: (json['confidence'] as num).toDouble(),
        inferenceDurationSeconds:
            (json['inferenceDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Service managing Sign Language validation logs and CSV report generation.
class SignLanguageValidationTrackerService {
  SignLanguageValidationTrackerService._();
  static final SignLanguageValidationTrackerService instance =
      SignLanguageValidationTrackerService._();

  static const String _kStorageKey = 'hajicare_sign_validation_logs';
  final ValueNotifier<List<SignValidationLog>> logsNotifier =
      ValueNotifier<List<SignValidationLog>>([]);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_kStorageKey);
      if (savedJson != null) {
        final List<dynamic> list = jsonDecode(savedJson) as List<dynamic>;
        final logs = list
            .map(
              (item) =>
                  SignValidationLog.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        logsNotifier.value = logs;
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('[SIGN_TRACKER] Failed to load logs: $e');
    }
  }

  Future<void> recordTrial({
    required String model,
    required String category,
    required String groundTruth,
    required String detected,
    required bool isSuccess,
    required double confidence,
    required double inferenceDurationSeconds,
  }) async {
    await init();
    final log = SignValidationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      model: model,
      category: category,
      groundTruth: groundTruth,
      detected: detected,
      isSuccess: isSuccess,
      confidence: confidence,
      inferenceDurationSeconds: inferenceDurationSeconds,
    );

    final updated = List<SignValidationLog>.from(logsNotifier.value)..add(log);
    logsNotifier.value = updated;

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(updated.map((l) => l.toJson()).toList());
      await prefs.setString(_kStorageKey, encoded);

      // Log tag for adb capture
      debugPrint(
        '[SIGN_VALIDATION_LOG] ${log.id}|${log.model}|${log.category}|${log.groundTruth}|${log.detected}|${log.isSuccess ? 'BENAR' : 'SALAH'}|${(log.confidence * 100).toStringAsFixed(1)}%|${log.inferenceDurationSeconds.toStringAsFixed(2)}s',
      );
    } catch (e) {
      debugPrint('[SIGN_TRACKER] Failed to save log: $e');
    }
  }

  Future<void> updateLastTrialStatus(bool isSuccess) async {
    await init();
    if (logsNotifier.value.isEmpty) return;
    final list = List<SignValidationLog>.from(logsNotifier.value);
    final last = list.removeLast();
    final updated = SignValidationLog(
      id: last.id,
      timestamp: last.timestamp,
      model: last.model,
      category: last.category,
      groundTruth: last.groundTruth,
      detected: isSuccess ? last.groundTruth : 'Tidak Sesuai',
      isSuccess: isSuccess,
      confidence: last.confidence,
      inferenceDurationSeconds: last.inferenceDurationSeconds,
    );
    list.add(updated);
    logsNotifier.value = list;

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((l) => l.toJson()).toList());
      await prefs.setString(_kStorageKey, encoded);

      debugPrint(
        '[SIGN_VALIDATION_LOG] UPDATE|${updated.id}|${updated.model}|${updated.category}|${updated.groundTruth}|${updated.detected}|${updated.isSuccess ? 'BENAR' : 'SALAH'}|${(updated.confidence * 100).toStringAsFixed(1)}%|${updated.inferenceDurationSeconds.toStringAsFixed(2)}s',
      );
    } catch (e) {
      debugPrint('[SIGN_TRACKER] Failed to update log: $e');
    }
  }

  Future<void> removeLastTrial() async {
    await init();
    if (logsNotifier.value.isEmpty) return;
    final list = List<SignValidationLog>.from(logsNotifier.value);
    final removed = list.removeLast();
    logsNotifier.value = list;

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(list.map((l) => l.toJson()).toList());
      await prefs.setString(_kStorageKey, encoded);

      debugPrint('[SIGN_VALIDATION_LOG] REMOVED|${removed.id}');
    } catch (e) {
      debugPrint('[SIGN_TRACKER] Failed to remove log: $e');
    }
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStorageKey);
    logsNotifier.value = [];
  }

  Future<void> clearLogsForModel(String model) async {
    await init();
    final updated = logsNotifier.value.where((l) => l.model != model).toList();
    logsNotifier.value = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kStorageKey,
      jsonEncode(updated.map((l) => l.toJson()).toList()),
    );
  }
}
