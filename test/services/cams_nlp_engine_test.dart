import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/services/cams_canonical_frames.dart';
import 'package:hajicare/services/cams_nlp_engine.dart';

void main() {
  late CamsNlpEngine engine;

  setUpAll(() {
    final file = File('assets/cams/cams_v3_offline_weights.json');
    expect(file.existsSync(), isTrue, reason: 'CAMS v3 offline weights JSON must exist');
    final jsonMap = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    engine = CamsNlpEngine.instance;
    engine.loadFromJsonMap(jsonMap);
  });

  group('CAMS NLP v3 Offline Engine - Core Scenarios', () {
    test('cross-model ["BANTU", "DOKTER"] proceeds with exact 3-language canonical frame', () {
      final result = engine.translate(
        glossTokens: ['BANTU', 'DOKTER'],
        location: 'UNKNOWN',
        interlocutorRole: 'UNKNOWN',
        minCameraConf: 0.85,
      );

      expect(result.decision, equals(CamsDecision.proceedTranslate));
      expect(result.intent, equals('MEDICAL_EMERGENCY_CRITICAL'));
      expect(result.confidence, closeTo(0.8469, 0.005));
      expect(result.normalizedTokens, equals(['BANTU', 'DOKTER']));
      expect(result.idC0, equals('Bantu saya dokter.'));
      expect(result.idC3, equals('Tolong bantu saya memanggil dokter.'));
      expect(result.enText, equals('Please help me call a doctor.'));
      expect(result.arText, equals('من فضلك ساعدني في استدعاء الطبيب.'));
    });

    test('normalizes mixed casing and spaces ["bantu ", "Dokter"] seamlessly', () {
      final result = engine.translate(
        glossTokens: ['bantu ', 'Dokter'],
        location: 'KLINIK_SEKTOR_MINA',
        interlocutorRole: 'DOKTER_KLINIK_SAUDI',
        minCameraConf: 0.90,
      );

      expect(result.decision, equals(CamsDecision.proceedTranslate));
      expect(result.intent, equals('MEDICAL_EMERGENCY_CRITICAL'));
      expect(result.confidence, closeTo(0.7424, 0.005));
      expect(result.idC3, contains('dokter'));
      expect(result.arText, isNotEmpty);
    });

    test('short phrase ["MANA", "MASJID"] translates to WORSHIP_FACILITY_ACCESS in 3 languages', () {
      final result = engine.translate(
        glossTokens: ['MANA', 'MASJID'],
        location: 'UNKNOWN',
        interlocutorRole: 'UNKNOWN',
        minCameraConf: 0.88,
      );

      expect(result.decision, equals(CamsDecision.proceedTranslate));
      expect(result.intent, equals('WORSHIP_FACILITY_ACCESS'));
      expect(result.confidence, greaterThanOrEqualTo(0.45));
      expect(result.idC3.toLowerCase(), contains('masjid'));
      expect(result.enText.toLowerCase(), contains('mosque'));
      expect(result.arText, contains('مسجد'));
    });

    test('ambiguous input ["SAYA", "BANTU"] triggers REQUEST_CLARIFICATION with quick-tap options', () {
      final result = engine.translate(
        glossTokens: ['SAYA', 'BANTU'],
        location: 'UNKNOWN',
        interlocutorRole: 'UNKNOWN',
        minCameraConf: 0.85,
      );

      expect(result.decision, equals(CamsDecision.requestClarification));
      expect(result.clarificationOptions.length, greaterThanOrEqualTo(2));
      expect(result.clarificationOptions.first.glossTokens, isNotEmpty);
    });

    test('out-of-vocabulary ["SAYA", "KURSI_RODA"] triggers REJECT_OOV with oovTokens', () {
      final result = engine.translate(
        glossTokens: ['SAYA', 'KURSI_RODA'],
        location: 'UNKNOWN',
        interlocutorRole: 'UNKNOWN',
        minCameraConf: 0.90,
      );

      expect(result.decision, equals(CamsDecision.rejectOov));
      expect(result.oovTokens, equals(['KURSI_RODA']));
    });

    test('maps legacy MINUM_OLD / "minum old" to MINUM before OOV check and translates', () {
      final result = engine.translate(
        glossTokens: ['minum old', 'air'],
        location: 'UNKNOWN',
        interlocutorRole: 'UNKNOWN',
        minCameraConf: 0.85,
      );

      expect(result.decision, equals(CamsDecision.proceedTranslate));
      expect(result.normalizedTokens, equals(['MINUM', 'AIR']));
      expect(result.intent, equals('DAILY_ASSISTANCE'));
      expect(result.confidence, greaterThan(0.90));
      expect(result.idC3.toLowerCase(), contains('air minum'));
    });

    test('low camera confidence (< 0.50) triggers REQUEST_CLARIFICATION even on valid tokens', () {
      final result = engine.translate(
        glossTokens: ['BANTU', 'DOKTER'],
        location: 'UNKNOWN',
        interlocutorRole: 'UNKNOWN',
        minCameraConf: 0.42,
      );

      expect(result.decision, equals(CamsDecision.requestClarification));
      expect(result.clarificationOptions, isNotEmpty);
    });

    test('empty glossTokens safely returns REQUEST_CLARIFICATION without throwing', () {
      final result = engine.translate(
        glossTokens: const [],
        location: 'UNKNOWN',
        interlocutorRole: 'UNKNOWN',
      );

      expect(result.decision, equals(CamsDecision.requestClarification));
    });
  });
}
