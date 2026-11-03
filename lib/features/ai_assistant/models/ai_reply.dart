import 'package:flutter/foundation.dart';

/// Balasan terstruktur dari Hermes Agent.
@immutable
class AiReply {
  const AiReply({
    required this.speech,
    required this.oled,
    this.isStructured = true,
    this.isOfflineFallback = false,
    this.notifyChannel,
    this.notifyMessage,
  });

  /// Kalimat lengkap untuk dibacakan TTS & ditampilkan di gelembung chat.
  final String speech;

  /// Ringkasan ASCII ≤ 55 karakter untuk layar OLED gelang.
  final String oled;

  /// False jika LLM tidak membalas JSON valid dan parser memakai fallback teks.
  final bool isStructured;

  /// True jika balasan dibuat lokal karena server AI tidak dapat dihubungi.
  final bool isOfflineFallback;

  /// Saluran pengiriman eksternal opsional jika pengguna meminta meneruskan pesan
  /// (misal `'whatsapp'` atau `'none'`).
  final String? notifyChannel;

  /// Isi pesan opsional yang disusun khusus oleh AI untuk dikirim ke WhatsApp Pendamping/Keluarga.
  final String? notifyMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiReply &&
          other.speech == speech &&
          other.oled == oled &&
          other.isStructured == isStructured &&
          other.isOfflineFallback == isOfflineFallback &&
          other.notifyChannel == notifyChannel &&
          other.notifyMessage == notifyMessage;

  @override
  int get hashCode => Object.hash(
    speech,
    oled,
    isStructured,
    isOfflineFallback,
    notifyChannel,
    notifyMessage,
  );

  @override
  String toString() =>
      'AiReply(speech: $speech, oled: $oled, structured: $isStructured, '
      'offline: $isOfflineFallback, notify: $notifyChannel)';
}
