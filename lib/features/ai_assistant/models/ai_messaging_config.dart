import 'package:flutter/foundation.dart';

/// Provider gateway untuk pengiriman WhatsApp otomatis di background.
enum WhatsAppGatewayProvider {
  /// Fonnte API (`https://api.fonnte.com/send`) — populer & mudah digunakan di Indonesia.
  fonnte,

  /// CallMeBot API (`https://api.callmebot.com/whatsapp.php`) — alternatif gratis untuk notifikasi personal.
  callmebot,
}

extension WhatsAppGatewayProviderX on WhatsAppGatewayProvider {
  String get id => switch (this) {
    WhatsAppGatewayProvider.fonnte => 'fonnte',
    WhatsAppGatewayProvider.callmebot => 'callmebot',
  };

  String get displayName => switch (this) {
    WhatsAppGatewayProvider.fonnte => 'Fonnte WhatsApp API',
    WhatsAppGatewayProvider.callmebot => 'CallMeBot API',
  };

  static WhatsAppGatewayProvider fromId(String? raw) {
    if (raw?.toLowerCase().trim() == 'callmebot') {
      return WhatsAppGatewayProvider.callmebot;
    }
    return WhatsAppGatewayProvider.fonnte;
  }
}

/// Konfigurasi pengiriman pesan otomatis dari **HajiCare AI & Smartband** ke **WhatsApp**.
///
/// Mendukung 2 metode pengiriman:
/// 1. **Otomatis di Background (Tanpa buka aplikasi WA)**: jika [whatsAppApiToken] diisi
///    (menggunakan Fonnte API atau CallMeBot API).
/// 2. **Fallback Instan (`wa.me`)**: jika [whatsAppApiToken] kosong, otomatis membuka
///    WhatsApp dengan pesan laporan lengkap yang sudah disusun oleh AI.
@immutable
class AiMessagingConfig {
  const AiMessagingConfig({
    this.whatsAppPhone = '',
    this.whatsAppApiToken = '',
    this.gatewayProvider = WhatsAppGatewayProvider.fonnte,
    this.autoAlertOnSosAndFall = true,
    this.autoAlertOnSafeRadius = true,
  });

  static const AiMessagingConfig defaults = AiMessagingConfig();

  /// Nomor WhatsApp tujuan (Pendamping / Keluarga), misal `6281234567890`.
  final String whatsAppPhone;

  /// Token API Gateway WhatsApp opsional (Fonnte Token atau CallMeBot API Key)
  /// agar pesan terkirim otomatis di background (mis. saat jamaah bicara dari mic gelang).
  final String whatsAppApiToken;

  /// Provider gateway yang digunakan bila [whatsAppApiToken] diisi.
  final WhatsAppGatewayProvider gatewayProvider;

  /// Kirim laporan darurat otomatis ke WhatsApp saat Tombol SOS (3 detik) atau Deteksi Jatuh MPU6050 aktif.
  final bool autoAlertOnSosAndFall;

  /// Kirim peringatan otomatis ke WhatsApp saat jamaah keluar dari batas Safe Radius.
  final bool autoAlertOnSafeRadius;

  /// Nomor WhatsApp yang sudah dinormalisasi ke format internasional (`628...` tanpa `+` atau spasi).
  String get normalizedPhone => normalizePhoneNumber(whatsAppPhone);

  /// True jika nomor WhatsApp tujuan sudah valid.
  bool get hasValidPhone => normalizedPhone.length >= 9;

  /// True jika token gateway diisi sehingga pengiriman bisa dilakukan 100% otomatis di background.
  bool get hasBackgroundGatewayToken => whatsAppApiToken.trim().isNotEmpty;

  /// Normalisasi nomor telepon Indonesia / Internasional ke digit murni (misal `0812...` -> `62812...`).
  static String normalizePhoneNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('08')) {
      return '62${digits.substring(1)}';
    }
    if (digits.startsWith('8') && digits.length >= 9) {
      return '62$digits';
    }
    return digits;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'whatsAppPhone': whatsAppPhone.trim(),
    'whatsAppApiToken': whatsAppApiToken.trim(),
    'gatewayProvider': gatewayProvider.id,
    'autoAlertOnSosAndFall': autoAlertOnSosAndFall,
    'autoAlertOnSafeRadius': autoAlertOnSafeRadius,
  };

  factory AiMessagingConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AiMessagingConfig.defaults;
    return AiMessagingConfig(
      whatsAppPhone: (map['whatsAppPhone'] as String?)?.trim() ?? '',
      whatsAppApiToken: (map['whatsAppApiToken'] as String?)?.trim() ?? '',
      gatewayProvider: WhatsAppGatewayProviderX.fromId(
        map['gatewayProvider'] as String?,
      ),
      autoAlertOnSosAndFall: (map['autoAlertOnSosAndFall'] as bool?) ?? true,
      autoAlertOnSafeRadius: (map['autoAlertOnSafeRadius'] as bool?) ?? true,
    );
  }

  AiMessagingConfig copyWith({
    String? whatsAppPhone,
    String? whatsAppApiToken,
    WhatsAppGatewayProvider? gatewayProvider,
    bool? autoAlertOnSosAndFall,
    bool? autoAlertOnSafeRadius,
  }) {
    return AiMessagingConfig(
      whatsAppPhone: whatsAppPhone ?? this.whatsAppPhone,
      whatsAppApiToken: whatsAppApiToken ?? this.whatsAppApiToken,
      gatewayProvider: gatewayProvider ?? this.gatewayProvider,
      autoAlertOnSosAndFall:
          autoAlertOnSosAndFall ?? this.autoAlertOnSosAndFall,
      autoAlertOnSafeRadius:
          autoAlertOnSafeRadius ?? this.autoAlertOnSafeRadius,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiMessagingConfig &&
          other.whatsAppPhone == whatsAppPhone &&
          other.whatsAppApiToken == whatsAppApiToken &&
          other.gatewayProvider == gatewayProvider &&
          other.autoAlertOnSosAndFall == autoAlertOnSosAndFall &&
          other.autoAlertOnSafeRadius == autoAlertOnSafeRadius;

  @override
  int get hashCode => Object.hash(
    whatsAppPhone,
    whatsAppApiToken,
    gatewayProvider,
    autoAlertOnSosAndFall,
    autoAlertOnSafeRadius,
  );
}
