import 'package:flutter/foundation.dart';

/// Status pengiriman teks ke layar OLED gelang.
enum OledDeliveryStatus {
  /// Belum ada pesan AI yang dikirim.
  idle,

  /// Sedang menulis ke BLE RX characteristic.
  sending,

  /// Berhasil ditulis ke gelang via BLE.
  deliveredBle,

  /// Gelang belum terhubung: hanya ditampilkan di pratinjau aplikasi.
  previewOnly,

  /// Gelang terhubung tetapi penulisan BLE gagal.
  failed,
}

/// Snapshot immutable layar OLED 128x64 (SSD1306) di gelang.
@immutable
class OledDisplayState {
  const OledDisplayState({
    required this.text,
    required this.status,
    this.payload,
    this.updatedAt,
  });

  static const OledDisplayState initial = OledDisplayState(
    text: 'Tanya AI HajiCare',
    status: OledDeliveryStatus.idle,
  );

  /// Teks yang tampil di OLED (tanpa prefix `AI:`).
  final String text;

  /// Payload persis yang ditulis ke BLE, mis. `AI:Kondisi Anda stabil`.
  final String? payload;

  final OledDeliveryStatus status;
  final DateTime? updatedAt;

  bool get isDeliveredToBand => status == OledDeliveryStatus.deliveredBle;

  OledDisplayState copyWith({
    String? text,
    String? payload,
    OledDeliveryStatus? status,
    DateTime? updatedAt,
  }) {
    return OledDisplayState(
      text: text ?? this.text,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OledDisplayState &&
          other.text == text &&
          other.payload == payload &&
          other.status == status &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(text, payload, status, updatedAt);
}

