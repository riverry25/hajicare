import 'package:flutter/foundation.dart';
import 'ai_reply.dart';
import 'oled_display_state.dart';
import 'sensor_context.dart';

/// Event streaming tingkat rendah dari [HermesAiService].
@immutable
sealed class AiStreamEvent {
  const AiStreamEvent();
}

/// Token speech kumulatif yang telah dibersihkan secara bertahap.
@immutable
class AiStreamDelta extends AiStreamEvent {
  const AiStreamDelta(this.speechSoFar);

  /// Teks kumulatif bersih sampai saat ini.
  final String speechSoFar;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiStreamDelta && other.speechSoFar == speechSoFar;

  @override
  int get hashCode => speechSoFar.hashCode;

  @override
  String toString() => 'AiStreamDelta(${speechSoFar.length} chars)';
}

/// Respons akhir lengkap dari model yang berisi speech dan oled terverifikasi.
@immutable
class AiStreamDone extends AiStreamEvent {
  const AiStreamDone(this.reply);

  final AiReply reply;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AiStreamDone && other.reply == reply;

  @override
  int get hashCode => reply.hashCode;

  @override
  String toString() => 'AiStreamDone(speech: ${reply.speech.length} chars, oled: ${reply.oled})';
}

/// Event streaming tingkat tinggi dari [AiAssistantRepository] ke Controller.
@immutable
sealed class AiTurnEvent {
  const AiTurnEvent();
}

/// Delta pembaruan teks percakapan saat proses streaming berlangsung.
@immutable
class AiTurnDelta extends AiTurnEvent {
  const AiTurnDelta(this.speechSoFar);

  final String speechSoFar;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiTurnDelta && other.speechSoFar == speechSoFar;

  @override
  int get hashCode => speechSoFar.hashCode;

  @override
  String toString() => 'AiTurnDelta(${speechSoFar.length} chars)';
}

/// Hasil akhir lengkap dari satu siklus turn percakapan, termasuk snapshot sensor dan status OLED.
@immutable
class AiTurnDone extends AiTurnEvent {
  const AiTurnDone({
    required this.reply,
    required this.sensorSnapshot,
    required this.oledState,
    this.errorBannerMessage,
  });

  final AiReply reply;
  final SensorContext sensorSnapshot;
  final OledDisplayState oledState;
  final String? errorBannerMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiTurnDone &&
          other.reply == reply &&
          other.sensorSnapshot == sensorSnapshot &&
          other.oledState == oledState &&
          other.errorBannerMessage == errorBannerMessage;

  @override
  int get hashCode => Object.hash(
        reply,
        sensorSnapshot,
        oledState,
        errorBannerMessage,
      );

  @override
  String toString() =>
      'AiTurnDone(speech: ${reply.speech.length} chars, oled: ${reply.oled})';
}

