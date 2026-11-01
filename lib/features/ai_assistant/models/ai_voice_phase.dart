/// Status fase pada tampilan Mode Suara Penuh (Immersive Voice Orb).
enum AiVoicePhase {
  /// Siap menerima input suara pengguna.
  idle,

  /// Sedang merekam suara pengguna melalui mikrofon (STT aktif).
  listening,

  /// Menunggu respons dari model AI (pertanyaan pengguna ditampilkan, belum ada token balasan).
  thinking,

  /// Sedang menerima streaming token jawaban atau sedang membacakan TTS.
  answering,
}

