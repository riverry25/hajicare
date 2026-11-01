import 'dart:async';
import 'package:flutter/foundation.dart';

/// Antrean pemecah kalimat untuk membacakan streaming teks secara beruntun (*sentence-by-sentence TTS*).
///
/// Memungkinkan pembacaan suara dimulai sejak kalimat pertama selesai dikirim oleh model AI,
/// tanpa perlu menunggu seluruh paragraf atau respons model selesai di-generate.
class SentenceSpeechQueue {
  SentenceSpeechQueue({
    required Future<void> Function(String sentence) speakFunction,
    required Future<void> Function() stopFunction,
  })  : _speakFunction = speakFunction,
        _stopFunction = stopFunction;

  final Future<void> Function(String sentence) _speakFunction;
  final Future<void> Function() _stopFunction;

  final List<String> _pendingQueue = <String>[];
  int _lastProcessedLength = 0;
  bool _isPlaying = false;
  int _generation = 0;
  String _bufferedIncomplete = '';

  void Function(bool isSpeaking)? onSpeakingStateChanged;

  /// Apakah antrean sedang aktif memutar kalimat.
  bool get isPlaying => _isPlaying;

  /// Masukkan teks kumulatif streaming terbaru. Kalimat yang telah lengkap
  /// akan otomatis dipotong dan dimasukkan ke dalam antrean pemutaran TTS.
  void feed(String cumulativeSpeech) {
    if (cumulativeSpeech.length <= _lastProcessedLength) return;

    final newPart = cumulativeSpeech.substring(_lastProcessedLength);
    _lastProcessedLength = cumulativeSpeech.length;

    _bufferedIncomplete += newPart;

    // Cari pemisah kalimat di _bufferedIncomplete
    final sentences = _extractSentencesFromBuffer(isFinal: false);
    for (final s in sentences) {
      if (s.trim().isNotEmpty) {
        _pendingQueue.add(s.trim());
      }
    }

    _pumpQueue();
  }

  /// Sinyal bahwa streaming telah selesai. Sisa kalimat/fragmen terakhir
  /// di dalam buffer akan dimasukkan ke antrean.
  void finish([String? finalSpeech]) {
    if (finalSpeech != null && finalSpeech.length > _lastProcessedLength) {
      final remainder = finalSpeech.substring(_lastProcessedLength);
      _bufferedIncomplete += remainder;
      _lastProcessedLength = finalSpeech.length;
    }

    final sentences = _extractSentencesFromBuffer(isFinal: true);
    for (final s in sentences) {
      if (s.trim().isNotEmpty) {
        _pendingQueue.add(s.trim());
      }
    }

    _pumpQueue();
  }

  /// Ekstrak kalimat lengkap dari `_bufferedIncomplete`.
  List<String> _extractSentencesFromBuffer({required bool isFinal}) {
    final result = <String>[];
    var buffer = _bufferedIncomplete;
    var searchStart = 0;

    while (searchStart < buffer.length) {
      final match = RegExp(r'([.!?؟…]+|\n+)\s*').firstMatch(buffer.substring(searchStart));
      if (match == null) {
        break;
      }

      final punctuationIndex = searchStart + match.start;
      final fullMatchEnd = searchStart + match.end;

      // Cek apakah tanda titik merupakan pemisah angka desimal (mis. 36.5 atau 37.2)
      if (buffer[punctuationIndex] == '.' &&
          punctuationIndex > 0 &&
          punctuationIndex + 1 < buffer.length) {
        final before = buffer[punctuationIndex - 1];
        final after = buffer[punctuationIndex + 1];
        if (RegExp(r'\d').hasMatch(before) && RegExp(r'\d').hasMatch(after)) {
          // Titik desimal, abaikan sebagai tanda baca akhir kalimat
          searchStart = fullMatchEnd;
          continue;
        }
      }

      // Potong kalimat
      final candidate = buffer.substring(0, fullMatchEnd).trim();
      buffer = buffer.substring(fullMatchEnd);
      searchStart = 0;

      if (candidate.isNotEmpty) {
        // Gabungkan fragmen yang terlalu pendek (< 18 char) dengan kalimat berikutnya jika bukan isFinal
        if (candidate.length < 18 && !isFinal) {
          buffer = '$candidate $buffer';
          break;
        }
        result.add(candidate);
      }
    }

    if (isFinal && buffer.trim().isNotEmpty) {
      result.add(buffer.trim());
      buffer = '';
    }

    _bufferedIncomplete = buffer;
    return result;
  }

  Future<void> _pumpQueue() async {
    if (_isPlaying || _pendingQueue.isEmpty) return;

    _isPlaying = true;
    onSpeakingStateChanged?.call(true);
    final currentGen = _generation;

    while (_pendingQueue.isNotEmpty && currentGen == _generation) {
      final nextSentence = _pendingQueue.removeAt(0);
      try {
        await _speakFunction(nextSentence);
      } catch (e) {
        debugPrint('[SentenceSpeechQueue] Speak error: $e');
      }
    }

    if (currentGen == _generation && _pendingQueue.isEmpty) {
      _isPlaying = false;
      onSpeakingStateChanged?.call(false);
    }
  }

  /// Hentikan pembacaan suara dan bersihkan seluruh antrean saat ini.
  Future<void> stop() async {
    _generation++;
    _pendingQueue.clear();
    _bufferedIncomplete = '';
    _lastProcessedLength = 0;
    _isPlaying = false;
    onSpeakingStateChanged?.call(false);
    await _stopFunction();
  }

  /// Reset antrean untuk kalimat baru tanpa memanggil stopFunction.
  void reset() {
    _generation++;
    _pendingQueue.clear();
    _bufferedIncomplete = '';
    _lastProcessedLength = 0;
    _isPlaying = false;
  }
}

