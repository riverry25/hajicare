import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechStatus {
  idle,
  listening,
  permissionDenied,
  serviceUnavailable,
  done,
}

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _hasPermission = false;
  bool _isDisposed = false;
  int _generation = 0;

  SpeechStatus _status = SpeechStatus.idle;
  SpeechStatus get status => _status;
  bool get isListening =>
      _speechToText.isListening || _status == SpeechStatus.listening;

  Function(SpeechStatus status, String message)? onStatusChanged;
  Function(String recognizedWords, bool isFinal)? onResult;

  Future<bool> init() async {
    if (_isDisposed) return false;
    if (_isInitialized) return _hasPermission;
    final generation = _generation;

    try {
      _hasPermission = await _speechToText.initialize(
        onStatus: (status) {
          if (_isDisposed || generation != _generation) return;
          if (status == 'listening') {
            _status = SpeechStatus.listening;
            onStatusChanged?.call(_status, 'Mendengarkan... Silakan bicara');
          } else if (status == 'notListening' || status == 'done') {
            _status = SpeechStatus.done;
            onStatusChanged?.call(_status, 'Selesai mendengarkan');
          }
        },
        onError: (errorNotification) {
          if (_isDisposed || generation != _generation) return;
          debugPrint('[SpeechService] onError: ${errorNotification.errorMsg}');
          if (errorNotification.errorMsg.contains('error_permission')) {
            _status = SpeechStatus.permissionDenied;
            onStatusChanged?.call(_status, 'Izin mikrofon ditolak.');
          } else if (errorNotification.errorMsg.contains('error_no_match')) {
            _status = SpeechStatus.done;
            onStatusChanged?.call(
              _status,
              'Suara tidak terdeteksi. Silakan coba lagi.',
            );
          } else {
            _status = SpeechStatus.serviceUnavailable;
            onStatusChanged?.call(_status, 'Layanan suara tidak tersedia.');
          }
        },
      );

      if (_isDisposed || generation != _generation) {
        await _speechToText.cancel();
        return false;
      }

      _isInitialized = true;
      if (!_hasPermission) {
        _status = SpeechStatus.permissionDenied;
        onStatusChanged?.call(_status, 'Izin mikrofon diperlukan.');
      } else {
        _status = SpeechStatus.idle;
        onStatusChanged?.call(_status, 'Siap mendengarkan.');
      }
      return _hasPermission;
    } catch (e) {
      if (_isDisposed || generation != _generation) return false;
      debugPrint('[SpeechService] init error: $e');
      _isInitialized = true;
      _hasPermission = false;
      _status = SpeechStatus.serviceUnavailable;
      onStatusChanged?.call(
        _status,
        'Layanan suara offline atau tidak tersedia.',
      );
      return false;
    }
  }

  Future<void> startListening({required String languageCode}) async {
    if (_isDisposed) return;
    final generation = _generation;
    if (!_isInitialized || !_hasPermission) {
      final ok = await init();
      if (!ok) return;
    }

    try {
      final locales = await _speechToText.locales();
      if (_isDisposed || generation != _generation) return;
      String? matchedLocaleId;
      final targetPrefix = languageCode.toLowerCase();
      for (final loc in locales) {
        if (loc.localeId.toLowerCase().startsWith(targetPrefix)) {
          matchedLocaleId = loc.localeId;
          break;
        }
      }

      _status = SpeechStatus.listening;
      onStatusChanged?.call(_status, 'Mendengarkan... Silakan bicara');

      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          if (_isDisposed || generation != _generation) return;
          onResult?.call(result.recognizedWords, result.finalResult);
        },
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          partialResults: true,
          localeId: matchedLocaleId,
        ),
      );
    } catch (e) {
      if (_isDisposed || generation != _generation) return;
      debugPrint('[SpeechService] startListening error: $e');
      _status = SpeechStatus.serviceUnavailable;
      onStatusChanged?.call(
        _status,
        'Mikrofon belum dapat digunakan. Periksa izin mikrofon, lalu coba lagi.',
      );
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
    } catch (_) {}
    _status = SpeechStatus.done;
    onStatusChanged?.call(_status, 'Selesai');
  }

  Future<void> toggleListening({required String languageCode}) async {
    if (isListening) {
      await stopListening();
    } else {
      await startListening(languageCode: languageCode);
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _generation++;
    onStatusChanged = null;
    onResult = null;
    unawaited(_speechToText.cancel());
  }
}
