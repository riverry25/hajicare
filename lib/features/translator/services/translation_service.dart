import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  OnDeviceTranslator? _translator;
  TranslateLanguage? _currentSource;
  TranslateLanguage? _currentTarget;

  /// Map language codes ('id', 'ar', 'en') to TranslateLanguage
  static TranslateLanguage languageFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'id':
        return TranslateLanguage.indonesian;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'en':
        return TranslateLanguage.english;
      default:
        return TranslateLanguage.indonesian;
    }
  }

  /// Ensure that both source and target models are downloaded.
  /// Calls [onStatusUpdate] with user-friendly messages.
  Future<bool> ensureModelsDownloaded({
    required TranslateLanguage source,
    required TranslateLanguage target,
    Function(String status)? onStatusUpdate,
  }) async {
    try {
      final isSourceDownloaded = await _modelManager.isModelDownloaded(
        source.bcpCode,
      );
      if (!isSourceDownloaded) {
        onStatusUpdate?.call('Menyiapkan bahasa sumber (${source.name})...');
        final success = await _modelManager.downloadModel(
          source.bcpCode,
          isWifiRequired: false,
        );
        if (!success) {
          onStatusUpdate?.call('Gagal mengunduh model bahasa sumber.');
          return false;
        }
      }

      final isTargetDownloaded = await _modelManager.isModelDownloaded(
        target.bcpCode,
      );
      if (!isTargetDownloaded) {
        onStatusUpdate?.call('Menyiapkan bahasa tujuan (${target.name})...');
        final success = await _modelManager.downloadModel(
          target.bcpCode,
          isWifiRequired: false,
        );
        if (!success) {
          onStatusUpdate?.call('Gagal mengunduh model bahasa tujuan.');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('[TranslationService] ensureModelsDownloaded error: $e');
      onStatusUpdate?.call('Gagal memeriksa atau mengunduh model bahasa: $e');
      return false;
    }
  }

  /// Translate text from source to target language
  Future<String> translate({
    required String text,
    required TranslateLanguage source,
    required TranslateLanguage target,
    Function(String status)? onStatusUpdate,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    if (source == target) return trimmed;

    final modelsReady = await ensureModelsDownloaded(
      source: source,
      target: target,
      onStatusUpdate: onStatusUpdate,
    );

    if (!modelsReady) {
      throw Exception('Model bahasa belum siap atau gagal diunduh.');
    }

    // Recreate translator instance only if language pair changed
    if (_translator == null ||
        _currentSource != source ||
        _currentTarget != target) {
      await _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: source,
        targetLanguage: target,
      );
      _currentSource = source;
      _currentTarget = target;
    }

    return await _translator!.translateText(trimmed);
  }

  void dispose() {
    _translator?.close();
    _translator = null;
  }
}
