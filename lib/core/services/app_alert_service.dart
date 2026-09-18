import 'package:flutter/material.dart';
import '../utils/app_dialog.dart';

export '../utils/app_dialog.dart';

/// Centralized alert & dialog service for HajiCare.
/// Styled according to the HajiCare design system (Cream / Gold / Espresso palette).
/// Now powered by [AppDialog] to guarantee zero crashes on unmounted contexts or route pops.
class AppAlert {
  AppAlert._();

  /// Menampilkan dialog sukses.
  static void success(
    BuildContext? context, {
    String title = 'Berhasil',
    required String message,
    VoidCallback? onOk,
    String okText = 'OK',
  }) {
    AppDialog.success(
      context: context,
      title: title,
      message: message,
      onOk: onOk,
      okText: okText,
    );
  }

  /// Menampilkan dialog error.
  static void error(
    BuildContext? context, {
    String title = 'Terjadi Kesalahan',
    required String message,
    VoidCallback? onOk,
    String okText = 'Tutup',
  }) {
    AppDialog.error(
      context: context,
      title: title,
      message: message,
      onOk: onOk,
      okText: okText,
    );
  }

  /// Menampilkan dialog peringatan.
  static void warning(
    BuildContext? context, {
    String title = 'Perhatian',
    required String message,
    VoidCallback? onOk,
    String okText = 'Mengerti',
  }) {
    AppDialog.warning(
      context: context,
      title: title,
      message: message,
      onOk: onOk,
      okText: okText,
    );
  }

  /// Menampilkan dialog informasi.
  static void info(
    BuildContext? context, {
    String title = 'Informasi',
    required String message,
    VoidCallback? onOk,
    String okText = 'OK',
  }) {
    AppDialog.info(
      context: context,
      title: title,
      message: message,
      onOk: onOk,
      okText: okText,
    );
  }

  /// Menampilkan dialog konfirmasi (termasuk aksi destruktif).
  static void confirm(
    BuildContext? context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDestructive = false,
  }) {
    AppDialog.confirm(
      context: context,
      title: title,
      message: message,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    );
  }

  /// Menampilkan dialog loading non-dismissible.
  static void loading(
    BuildContext? context, {
    String message = 'Memproses...',
  }) {
    AppDialog.loading(context: context, message: message);
  }

  /// Menutup dialog loading.
  static void dismissLoading(BuildContext? context) {
    AppDialog.dismissLoading(context);
  }
}

