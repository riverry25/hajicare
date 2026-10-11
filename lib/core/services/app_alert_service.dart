import 'package:flutter/material.dart';
import '../utils/app_dialog.dart';

export '../utils/app_dialog.dart';

/// Centralized alert & dialog service for HajiCare.
/// Styled according to the HajiCare design system (Cream / Gold / Espresso palette).
/// Now powered by [AppDialog] to guarantee zero crashes on unmounted contexts or route pops.
class AppAlert {
  AppAlert._();

  /// Menampilkan dialog sukses.
  static Future<void> success(
    BuildContext? context, {
    String title = 'Berhasil',
    required String message,
    VoidCallback? onOk,
    String okText = 'Selesai',
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) {
    return AppDialog.success(
      context: context,
      title: title,
      message: message,
      onOk: onOk,
      okText: okText,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
    );
  }

  /// Menampilkan dialog error.
  static Future<void> error(
    BuildContext? context, {
    String title = 'Belum Berhasil',
    required String message,
    VoidCallback? onOk,
    String okText = 'Tutup',
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) {
    return AppDialog.error(
      context: context,
      title: title,
      message: message,
      onOk: onOk,
      okText: okText,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
    );
  }

  /// Menampilkan dialog peringatan.
  static Future<void> warning(
    BuildContext? context, {
    String title = 'Perhatian',
    required String message,
    VoidCallback? onOk,
    String okText = 'Mengerti',
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) {
    return AppDialog.warning(
      context: context,
      title: title,
      message: message,
      onOk: onOk,
      okText: okText,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
    );
  }

  /// Menampilkan dialog informasi.
  static Future<void> info(
    BuildContext? context, {
    String title = 'Informasi',
    required String message,
    VoidCallback? onOk,
    String okText = 'Baik',
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) {
    return AppDialog.info(
      context: context,
      title: title,
      message: message,
      onOk: onOk,
      okText: okText,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
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
    String message = 'Mohon tunggu...',
  }) {
    AppDialog.loading(context: context, message: message);
  }

  /// Menutup dialog loading.
  static void dismissLoading(BuildContext? context) {
    AppDialog.dismissLoading(context);
  }
}
