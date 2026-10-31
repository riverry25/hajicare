import 'package:flutter/foundation.dart';

/// Balasan terstruktur dari Hermes Agent.
@immutable
class AiReply {
  const AiReply({
    required this.speech,
    required this.oled,
    this.isStructured = true,
    this.isOfflineFallback = false,
  });

  /// Kalimat lengkap untuk dibacakan TTS & ditampilkan di gelembung chat.
  final String speech;

  /// Ringkasan ASCII ≤ 55 karakter untuk layar OLED gelang.
  final String oled;

  /// False jika LLM tidak membalas JSON valid dan parser memakai fallback teks.
  final bool isStructured;

  /// True jika balasan dibuat lokal karena server AI tidak dapat dihubungi.
  final bool isOfflineFallback;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiReply &&
          other.speech == speech &&
          other.oled == oled &&
          other.isStructured == isStructured &&
          other.isOfflineFallback == isOfflineFallback;

  @override
  int get hashCode => Object.hash(speech, oled, isStructured, isOfflineFallback);

  @override
  String toString() =>
      'AiReply(speech: $speech, oled: $oled, structured: $isStructured, '
      'offline: $isOfflineFallback)';
}

