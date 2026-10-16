import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a single logged test trial for Authentication / Login.
class AuthTestLog {
  final String id;
  final DateTime timestamp;
  final String method; // 'Email' or 'Google'
  final String account; // Email / Akun Pengguna
  final bool isSuccess;
  final double durationSeconds;
  final String? errorMessage;

  AuthTestLog({
    required this.id,
    required this.timestamp,
    required this.method,
    this.account = '',
    required this.isSuccess,
    required this.durationSeconds,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'method': method,
    'account': account,
    'isSuccess': isSuccess,
    'durationSeconds': durationSeconds,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory AuthTestLog.fromJson(Map<String, dynamic> json) => AuthTestLog(
    id: json['id'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    method: json['method'] as String? ?? 'Email',
    account: json['account'] as String? ?? '',
    isSuccess: json['isSuccess'] as bool? ?? false,
    durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0.0,
    errorMessage: json['errorMessage'] as String?,
  );
}

/// Overall functional test stats for TC-01 (Login).
class AuthFunctionalStat {
  final int totalTrials;
  final int successes;
  final int failures;

  const AuthFunctionalStat({
    required this.totalTrials,
    required this.successes,
    required this.failures,
  });

  double get successRatePercent =>
      totalTrials == 0 ? 0.0 : (successes / totalTrials) * 100.0;
}

/// Service to track and persist validation test trials for Authentication / Login (TC-01).
class AuthValidationTrackerService {
  AuthValidationTrackerService._();
  static final AuthValidationTrackerService instance =
      AuthValidationTrackerService._();

  static const String _storageKey = 'hajicare_auth_validation_logs';
  final ValueNotifier<List<AuthTestLog>> logsNotifier =
      ValueNotifier<List<AuthTestLog>>([]);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        logsNotifier.value = decoded
            .map((item) => AuthTestLog.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[AuthValidationTracker] Failed to load logs: $e');
    }
    _isInitialized = true;
  }

  Future<void> logTrial({
    required String method,
    String account = '',
    required bool isSuccess,
    required double durationSeconds,
    String? errorMessage,
  }) async {
    await init();
    final entry = AuthTestLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      method: method,
      account: account,
      isSuccess: isSuccess,
      durationSeconds: durationSeconds,
      errorMessage: errorMessage,
    );

    final updated = List<AuthTestLog>.from(logsNotifier.value)..add(entry);
    logsNotifier.value = updated;
    await _save(updated);

    debugPrint('\n======================================================');
    debugPrint('🔐 LOG VALIDASI LOGIN (TC-01) BARU TERCATAT:');
    debugPrint(
      'Percobaan #${updated.length} | Akun: $account | Metode: $method | Durasi: ${durationSeconds.toStringAsFixed(2)}s | Status: ${isSuccess ? "BERHASIL ✅" : "GAGAL ❌"}',
    );
    debugPrint('======================================================\n');
  }

  Future<void> clearAll() async {
    logsNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<AuthTestLog> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[AuthValidationTracker] Failed to save logs: $e');
    }
  }

  AuthFunctionalStat getFunctionalStat() {
    final total = logsNotifier.value.length;
    final success = logsNotifier.value.where((l) => l.isSuccess).length;
    final fail = total - success;
    return AuthFunctionalStat(
      totalTrials: total,
      successes: success,
      failures: fail,
    );
  }
}
