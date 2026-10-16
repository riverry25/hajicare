import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/currency_code.dart';

/// Represents a single logged test trial for Money Recognition.
class MoneyTestLog {
  final String id;
  final DateTime timestamp;
  final CurrencyCode currency;
  final String groundTruthNominal; // e.g. "10 SAR", "Rp50.000", "$10"
  final String detectedNominal; // e.g. "10 SAR" or "Tidak Terdeteksi"
  final bool isSuccess; // true if predicted matches ground truth
  final double confidence; // detection confidence
  final double inferenceDurationSeconds; // durasi proses deteksi dalam detik

  MoneyTestLog({
    required this.id,
    required this.timestamp,
    required this.currency,
    required this.groundTruthNominal,
    required this.detectedNominal,
    required this.isSuccess,
    required this.confidence,
    this.inferenceDurationSeconds = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'currency': currency.name,
        'groundTruthNominal': groundTruthNominal,
        'detectedNominal': detectedNominal,
        'isSuccess': isSuccess,
        'confidence': confidence,
        'inferenceDurationSeconds': inferenceDurationSeconds,
      };

  factory MoneyTestLog.fromJson(Map<String, dynamic> json) => MoneyTestLog(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        currency: CurrencyCode.values.firstWhere(
          (c) => c.name == json['currency'],
          orElse: () => CurrencyCode.sar,
        ),
        groundTruthNominal: json['groundTruthNominal'] as String,
        detectedNominal: json['detectedNominal'] as String,
        isSuccess: json['isSuccess'] as bool,
        confidence: (json['confidence'] as num).toDouble(),
        inferenceDurationSeconds:
            (json['inferenceDurationSeconds'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Statistics per currency category.
class CurrencyEvalStat {
  final CurrencyCode currency;
  final int totalSamples;
  final int correctPredictions;
  final int wrongPredictions;

  const CurrencyEvalStat({
    required this.currency,
    required this.totalSamples,
    required this.correctPredictions,
    required this.wrongPredictions,
  });

  double get accuracyPercent =>
      totalSamples == 0 ? 0.0 : (correctPredictions / totalSamples) * 100.0;
}

/// Overall functional test stats (TC-02 / F04).
class FunctionalTestStat {
  final int totalTrials;
  final int successes;
  final int failures;

  const FunctionalTestStat({
    required this.totalTrials,
    required this.successes,
    required this.failures,
  });

  double get successRatePercent =>
      totalTrials == 0 ? 0.0 : (successes / totalTrials) * 100.0;
}

/// Service to track and persist validation test trials for Money Recognition.
class MoneyValidationTrackerService {
  MoneyValidationTrackerService._();
  static final MoneyValidationTrackerService instance =
      MoneyValidationTrackerService._();

  static const String _storageKey = 'hajicare_money_validation_logs';
  final ValueNotifier<List<MoneyTestLog>> logsNotifier =
      ValueNotifier<List<MoneyTestLog>>([]);

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        logsNotifier.value = decoded
            .map((item) => MoneyTestLog.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[ValidationTracker] Failed to load logs: $e');
    }
    _isInitialized = true;
  }

  Future<void> logTrial({
    required CurrencyCode currency,
    required String groundTruthNominal,
    required String detectedNominal,
    required bool isSuccess,
    required double confidence,
    double durationSeconds = 0.0,
  }) async {
    final entry = MoneyTestLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      currency: currency,
      groundTruthNominal: groundTruthNominal,
      detectedNominal: detectedNominal,
      isSuccess: isSuccess,
      confidence: confidence,
      inferenceDurationSeconds: durationSeconds,
    );

    final updated = List<MoneyTestLog>.from(logsNotifier.value)..add(entry);
    logsNotifier.value = updated;
    await _save(updated);

    debugPrint('\n======================================================');
    debugPrint('📊 DATA VALIDASI BARU TERCATAT:');
    debugPrint('Uji #${updated.length} | [${currency.name.toUpperCase()}] Nominal: $groundTruthNominal | Waktu Deteksi: ${durationSeconds.toStringAsFixed(2)}s | Status: ${isSuccess ? "BENAR ✅" : "SALAH ❌"}');
    debugPrint('======================================================\n');
  }

  /// Menghasilkan format CSV yang langsung bisa dibuka di Microsoft Excel
  String generateCsvContent() {
    final func = getFunctionalStat();
    final sar = getCurrencyStat(CurrencyCode.sar);
    final idr = getCurrencyStat(CurrencyCode.idr);
    final usd = getCurrencyStat(CurrencyCode.usd);
    final logs = logsNotifier.value;

    final buffer = StringBuffer();
    // TABEL 1: PENGUJIAN FUNGSIONAL
    buffer.writeln('TABEL 1: HASIL PENGUJIAN FUNGSIONAL APLIKASI HAJICARE (TC-02)');
    buffer.writeln('Kode,Fitur,Skenario Pengujian,Jumlah Percobaan,Berhasil,Gagal,Keberhasilan (%)');
    buffer.writeln('TC-02,Money Recognition,Memindai uang dengan nominal diketahui,${func.totalTrials},${func.successes},${func.failures},${func.successRatePercent.toStringAsFixed(1)}%');
    buffer.writeln('');

    // TABEL 4: EVALUASI MODEL
    buffer.writeln('TABEL 2: HASIL EVALUASI MODEL MONEY RECOGNITION HAJICARE (TABEL 4)');
    buffer.writeln('Mata Uang,Denominasi yang Diuji,Jumlah Sampel Uji,Prediksi Benar,Prediksi Salah,Akurasi (%)');
    buffer.writeln('SAR,Sesuai kelas yang didukung,${sar.totalSamples},${sar.correctPredictions},${sar.wrongPredictions},${sar.accuracyPercent.toStringAsFixed(1)}%');
    buffer.writeln('IDR,Sesuai kelas yang didukung,${idr.totalSamples},${idr.correctPredictions},${idr.wrongPredictions},${idr.accuracyPercent.toStringAsFixed(1)}%');
    buffer.writeln('USD,Sesuai kelas yang didukung,${usd.totalSamples},${usd.correctPredictions},${usd.wrongPredictions},${usd.accuracyPercent.toStringAsFixed(1)}%');
    final totalSamples = sar.totalSamples + idr.totalSamples + usd.totalSamples;
    final totalCorrect = sar.correctPredictions + idr.correctPredictions + usd.correctPredictions;
    final overallAcc = totalSamples == 0 ? 0.0 : (totalCorrect / totalSamples) * 100.0;
    buffer.writeln('KESELURUHAN,Seluruh kelas yang diuji,$totalSamples,$totalCorrect,${totalSamples - totalCorrect},${overallAcc.toStringAsFixed(1)}%');
    buffer.writeln('');

    // TABEL RINCIAN LOG PERCOBAAN DENGAN WAKTU DETEKSI (DETIK)
    buffer.writeln('TABEL 3: LOG RINCIAN PERCOBAAN (AUDIT TRAIL DENGAN WAKTU RESPON)');
    buffer.writeln('No,Timestamp,Mata Uang,Nominal Sebenarnya,Hasil Deteksi,Waktu Deteksi (Detik),Confidence Score,Status');
    for (int i = 0; i < logs.length; i++) {
      final l = logs[i];
      final timeStr = '${l.timestamp.hour.toString().padLeft(2, '0')}:${l.timestamp.minute.toString().padLeft(2, '0')}:${l.timestamp.second.toString().padLeft(2, '0')}';
      buffer.writeln('${i + 1},$timeStr,${l.currency.name.toUpperCase()},"${l.groundTruthNominal}","${l.detectedNominal}",${l.inferenceDurationSeconds.toStringAsFixed(2)},${(l.confidence * 100).toStringAsFixed(1)}%,${l.isSuccess ? "BENAR" : "SALAH"}');
    }

    return buffer.toString();
  }

  Future<void> clearAll() async {
    logsNotifier.value = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _save(List<MoneyTestLog> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      debugPrint('[ValidationTracker] Failed to save logs: $e');
    }
  }

  /// Calculates Functional Test statistics (TC-02 / F04).
  FunctionalTestStat getFunctionalStat() {
    final total = logsNotifier.value.length;
    final success = logsNotifier.value.where((l) => l.isSuccess).length;
    final fail = total - success;
    return FunctionalTestStat(
      totalTrials: total,
      successes: success,
      failures: fail,
    );
  }

  /// Calculates Model Evaluation statistics per currency (Table 4).
  CurrencyEvalStat getCurrencyStat(CurrencyCode code) {
    final list = logsNotifier.value.where((l) => l.currency == code).toList();
    final correct = list.where((l) => l.isSuccess).length;
    final wrong = list.length - correct;
    return CurrencyEvalStat(
      currency: code,
      totalSamples: list.length,
      correctPredictions: correct,
      wrongPredictions: wrong,
    );
  }

  /// Generates the complete Markdown report matching the user's PDF validation tables.
  String generateMarkdownReport() {
    final func = getFunctionalStat();
    final sar = getCurrencyStat(CurrencyCode.sar);
    final idr = getCurrencyStat(CurrencyCode.idr);
    final usd = getCurrencyStat(CurrencyCode.usd);

    final totalModelSamples = sar.totalSamples + idr.totalSamples + usd.totalSamples;
    final totalModelCorrect = sar.correctPredictions + idr.correctPredictions + usd.correctPredictions;
    final overallAccuracy = totalModelSamples == 0
        ? 0.0
        : (totalModelCorrect / totalModelSamples) * 100.0;

    final buffer = StringBuffer();
    buffer.writeln('# LAPORAN HASIL VALIDASI MONEY RECOGNITION HAJICARE\n');

    buffer.writeln('### 1. Hasil Pengujian Fungsional (TC-02 / F04)');
    buffer.writeln('| Kode | Fitur | Skenario pengujian | Jumlah percobaan | Berhasil | Gagal | Keberhasilan (%) |');
    buffer.writeln('| :--- | :--- | :--- | :---: | :---: | :---: | :---: |');
    buffer.writeln(
      '| TC-02 | Money Recognition | Memindai uang dengan nominal diketahui | ${func.totalTrials} | ${func.successes} | ${func.failures} | ${func.successRatePercent.toStringAsFixed(1)}% |',
    );
    buffer.writeln('');

    buffer.writeln('### 2. Hasil Evaluasi Model Money Recognition HajiCare (Tabel 4)');
    buffer.writeln('| Mata Uang | Denominasi yang diuji | Jumlah sampel uji | Prediksi benar | Prediksi salah | Akurasi (%) |');
    buffer.writeln('| :--- | :--- | :---: | :---: | :---: | :---: |');
    buffer.writeln(
      '| SAR | Sesuai kelas yang didukung | ${sar.totalSamples} | ${sar.correctPredictions} | ${sar.wrongPredictions} | ${sar.accuracyPercent.toStringAsFixed(1)}% |',
    );
    buffer.writeln(
      '| IDR | Sesuai kelas yang didukung | ${idr.totalSamples} | ${idr.correctPredictions} | ${idr.wrongPredictions} | ${idr.accuracyPercent.toStringAsFixed(1)}% |',
    );
    buffer.writeln(
      '| USD | Sesuai kelas yang didukung | ${usd.totalSamples} | ${usd.correctPredictions} | ${usd.wrongPredictions} | ${usd.accuracyPercent.toStringAsFixed(1)}% |',
    );
    buffer.writeln(
      '| **Keseluruhan** | Seluruh kelas yang diuji | **$totalModelSamples** | **$totalModelCorrect** | **${totalModelSamples - totalModelCorrect}** | **${overallAccuracy.toStringAsFixed(1)}%** |',
    );
    buffer.writeln('');

    buffer.writeln('### 3. Log Rincian Tiap Percobaan');
    buffer.writeln('| No | Waktu | Mata Uang | Nominal Sebenarnya | Hasil Deteksi | Status | Keyakinan |');
    buffer.writeln('| :---: | :--- | :---: | :--- | :--- | :---: | :---: |');

    final logs = logsNotifier.value;
    for (int i = 0; i < logs.length; i++) {
      final l = logs[i];
      final status = l.isSuccess ? '✅ Benar' : '❌ Salah';
      final timeStr = '${l.timestamp.hour.toString().padLeft(2, '0')}:${l.timestamp.minute.toString().padLeft(2, '0')}:${l.timestamp.second.toString().padLeft(2, '0')}';
      buffer.writeln(
        '| ${i + 1} | $timeStr | ${l.currency.name.toUpperCase()} | ${l.groundTruthNominal} | ${l.detectedNominal} | $status | ${(l.confidence * 100).toStringAsFixed(1)}% |',
      );
    }

    return buffer.toString();
  }
}
