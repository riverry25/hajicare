import 'package:flutter/foundation.dart';

enum AiChatRole { user, assistant }

enum AiChatStatus {
  /// Menunggu balasan server (indikator mengetik).
  pending,

  /// Pesan final.
  done,

  /// Gagal mendapatkan balasan (dapat dicoba ulang).
  error,
}

/// Satu gelembung percakapan pada asisten AI.
@immutable
class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.status = AiChatStatus.done,
    this.oledText,
    this.isOfflineFallback = false,
    this.retryPrompt,
  });

  factory AiChatMessage.user(String text) => AiChatMessage(
    id: _nextId(),
    role: AiChatRole.user,
    text: text,
    createdAt: DateTime.now(),
  );

  factory AiChatMessage.pending() => AiChatMessage(
    id: _nextId(),
    role: AiChatRole.assistant,
    text: '',
    createdAt: DateTime.now(),
    status: AiChatStatus.pending,
  );

  final String id;
  final AiChatRole role;
  final String text;
  final DateTime createdAt;
  final AiChatStatus status;

  /// Teks OLED yang dikirim ke gelang untuk balasan ini.
  final String? oledText;

  /// True jika balasan merupakan ringkasan lokal saat server offline.
  final bool isOfflineFallback;

  /// Pertanyaan asal yang dapat dikirim ulang bila [status] == error.
  final String? retryPrompt;

  bool get isUser => role == AiChatRole.user;
  bool get isAssistant => role == AiChatRole.assistant;
  bool get isPending => status == AiChatStatus.pending;
  bool get isError => status == AiChatStatus.error;

  /// Hanya pesan final non-error yang layak dibacakan ulang / jadi histori.
  bool get isSpeakable => isAssistant && status == AiChatStatus.done && text.isNotEmpty;

  AiChatMessage copyWith({
    String? text,
    AiChatStatus? status,
    String? oledText,
    bool? isOfflineFallback,
    String? retryPrompt,
  }) {
    return AiChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      createdAt: createdAt,
      status: status ?? this.status,
      oledText: oledText ?? this.oledText,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
      retryPrompt: retryPrompt ?? this.retryPrompt,
    );
  }

  static int _counter = 0;
  static String _nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiChatMessage &&
          other.id == id &&
          other.role == role &&
          other.text == text &&
          other.status == status &&
          other.oledText == oledText &&
          other.isOfflineFallback == isOfflineFallback &&
          other.retryPrompt == retryPrompt;

  @override
  int get hashCode => Object.hash(
    id,
    role,
    text,
    status,
    oledText,
    isOfflineFallback,
    retryPrompt,
  );
}

