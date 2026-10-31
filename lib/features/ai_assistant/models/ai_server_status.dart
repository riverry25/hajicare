import 'package:flutter/foundation.dart';

enum AiServerHealth {
  /// Belum pernah dicek.
  unknown,

  /// Sedang melakukan health-check.
  checking,

  /// Server merespons normal.
  online,

  /// Server merespons tetapi API key ditolak (401/403).
  unauthorized,

  /// URL masih placeholder / belum dikonfigurasi.
  notConfigured,

  /// Tidak dapat dihubungi (timeout, DNS, tunnel ngrok offline, 5xx).
  offline,
}

/// Hasil health-check server Hermes yang immutable.
@immutable
class AiServerStatus {
  const AiServerStatus({
    required this.health,
    this.message,
    this.latency,
    this.checkedAt,
  });

  static const AiServerStatus initial = AiServerStatus(
    health: AiServerHealth.unknown,
  );

  final AiServerHealth health;

  /// Pesan ramah pengguna untuk ditampilkan pada status bar / settings.
  final String? message;

  /// Waktu respons health-check.
  final Duration? latency;

  final DateTime? checkedAt;

  bool get isOnline => health == AiServerHealth.online;
  bool get isChecking => health == AiServerHealth.checking;

  String get label => switch (health) {
    AiServerHealth.unknown => 'Belum dicek',
    AiServerHealth.checking => 'Memeriksa...',
    AiServerHealth.online => 'Online',
    AiServerHealth.unauthorized => 'API Key ditolak',
    AiServerHealth.notConfigured => 'Belum diatur',
    AiServerHealth.offline => 'Offline',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiServerStatus &&
          other.health == health &&
          other.message == message &&
          other.latency == latency &&
          other.checkedAt == checkedAt;

  @override
  int get hashCode => Object.hash(health, message, latency, checkedAt);
}

