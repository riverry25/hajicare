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

/// Jenis tombol aksi cepat kontekstual yang membantu jamaah langsung dari chat.
enum AiContextualAction {
  openMap,
  openDua,
  openPrayer,
  openSos,
  openSmartbandSheet,
  sendWhatsApp,
}

/// Satu gelembung percakapan pada asisten AI.
@immutable
class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.fullText,
    this.isStreaming = false,
    this.status = AiChatStatus.done,
    this.oledText,
    this.isOfflineFallback = false,
    this.retryPrompt,
    this.promptQuestion,
    this.contextualActions = const <AiContextualAction>[],
    this.whatsAppStatusText,
  });

  factory AiChatMessage.user(String text) => AiChatMessage(
    id: _nextId(),
    role: AiChatRole.user,
    text: text,
    fullText: text,
    createdAt: DateTime.now(),
  );

  factory AiChatMessage.pending({String? promptQuestion}) => AiChatMessage(
    id: _nextId(),
    role: AiChatRole.assistant,
    text: '',
    createdAt: DateTime.now(),
    status: AiChatStatus.pending,
    promptQuestion: promptQuestion,
  );

  final String id;
  final AiChatRole role;

  /// Teks yang sedang ditampilkan di layar (bertambah kata demi kata saat streaming).
  final String text;

  /// Teks utuh untuk dibacakan oleh `flutter_tts` dan disalin ke clipboard.
  final String? fullText;

  /// True ketika efek pengetikan kata demi kata sedang berlangsung.
  final bool isStreaming;

  final DateTime createdAt;
  final AiChatStatus status;

  /// Teks OLED yang dikirim ke gelang untuk balasan ini.
  final String? oledText;

  /// True jika balasan merupakan ringkasan lokal saat server offline.
  final bool isOfflineFallback;

  /// Pertanyaan asal yang dapat dikirim ulang bila [status] == error.
  final String? retryPrompt;

  /// Pertanyaan pengguna yang menghasilkan balasan ini (untuk tombol Regenerate ↻).
  final String? promptQuestion;

  /// Tombol aksi cepat kontekstual di bawah pesan asisten.
  final List<AiContextualAction> contextualActions;

  /// Status pengiriman ke WhatsApp bila balasan ini diteruskan otomatis/manual ke WA.
  final String? whatsAppStatusText;

  String get effectiveFullText =>
      (fullText != null && fullText!.isNotEmpty) ? fullText! : text;

  bool get isUser => role == AiChatRole.user;
  bool get isAssistant => role == AiChatRole.assistant;
  bool get isPending => status == AiChatStatus.pending;
  bool get isError => status == AiChatStatus.error;

  /// Hanya pesan final non-error yang layak dibacakan ulang / jadi histori.
  bool get isSpeakable =>
      isAssistant &&
      status == AiChatStatus.done &&
      effectiveFullText.isNotEmpty;

  AiChatMessage copyWith({
    String? text,
    String? fullText,
    bool? isStreaming,
    AiChatStatus? status,
    String? oledText,
    bool? isOfflineFallback,
    String? retryPrompt,
    String? promptQuestion,
    List<AiContextualAction>? contextualActions,
    String? whatsAppStatusText,
  }) {
    return AiChatMessage(
      id: id,
      role: role,
      text: text ?? this.text,
      fullText: fullText ?? this.fullText,
      isStreaming: isStreaming ?? this.isStreaming,
      createdAt: createdAt,
      status: status ?? this.status,
      oledText: oledText ?? this.oledText,
      isOfflineFallback: isOfflineFallback ?? this.isOfflineFallback,
      retryPrompt: retryPrompt ?? this.retryPrompt,
      promptQuestion: promptQuestion ?? this.promptQuestion,
      contextualActions: contextualActions ?? this.contextualActions,
      whatsAppStatusText: whatsAppStatusText ?? this.whatsAppStatusText,
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
          other.fullText == fullText &&
          other.isStreaming == isStreaming &&
          other.status == status &&
          other.oledText == oledText &&
          other.isOfflineFallback == isOfflineFallback &&
          other.retryPrompt == retryPrompt &&
          other.promptQuestion == promptQuestion &&
          listEquals(other.contextualActions, contextualActions) &&
          other.whatsAppStatusText == whatsAppStatusText;

  @override
  int get hashCode => Object.hash(
    id,
    role,
    text,
    fullText,
    isStreaming,
    status,
    oledText,
    isOfflineFallback,
    retryPrompt,
    promptQuestion,
    whatsAppStatusText,
  );
}
