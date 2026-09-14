import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// Centralized alert & dialog service for HajiCare.
/// Styled according to the HajiCare design system (Cream / Gold / Espresso palette).
/// Uses Flutter-native icons (no Lottie) to guarantee correct rendering on all devices.
class AppAlert {
  AppAlert._();

  static BuildContext? _resolveContext(BuildContext? context) =>
      context ?? Get.context;

  // ── Internal helpers ─────────────────────────────────────────────────────

  /// Builds a styled circular icon header — replaces Lottie animation.
  static Widget _buildHeader(IconData icon, Color color) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 2),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }

  static void _showDialog({
    required BuildContext ctx,
    required IconData headerIcon,
    required Color accentColor,
    required String title,
    required String desc,
    required VoidCallback btnOkOnPress,
    String btnOkText = 'OK',
    Color? btnOkColor,
    VoidCallback? btnCancelOnPress,
    String? btnCancelText,
    Color? btnCancelColor,
  }) {
    final isDark = AppColors.isDark(ctx);
    AwesomeDialog(
      context: ctx,
      dialogType: DialogType.noHeader,
      animType: AnimType.scale,
      dialogBackgroundColor:
          isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      borderSide: BorderSide(
        color: accentColor.withValues(alpha: 0.4),
        width: 1.5,
      ),
      buttonsBorderRadius: BorderRadius.circular(AppRadius.md),
      customHeader: Padding(
        padding: const EdgeInsets.only(top: 18),
        child: _buildHeader(headerIcon, accentColor),
      ),
      title: title,
      desc: desc,
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: isDark ? AppColors.darkTextHeading : AppColors.espressoDark,
        fontWeight: FontWeight.bold,
      ),
      descTextStyle: AppTypography.bodyMedium.copyWith(
        color: isDark ? AppColors.darkTextBody : AppColors.textBody,
        height: 1.4,
      ),
      buttonsTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      btnOkText: btnOkText,
      btnOkColor: btnOkColor ?? accentColor,
      btnOkOnPress: btnOkOnPress,
      btnCancelText: btnCancelText,
      btnCancelColor: btnCancelColor,
      btnCancelOnPress: btnCancelOnPress,
    ).show();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Menampilkan dialog sukses.
  static void success(
    BuildContext? context, {
    String title = 'Berhasil',
    required String message,
    VoidCallback? onOk,
    String okText = 'OK',
  }) {
    final ctx = _resolveContext(context);
    if (ctx == null) return;
    _showDialog(
      ctx: ctx,
      headerIcon: Icons.check_circle_rounded,
      accentColor: AppColors.statusSafe,
      title: title,
      desc: message,
      btnOkText: okText,
      btnOkOnPress: onOk ?? () {},
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
    final ctx = _resolveContext(context);
    if (ctx == null) return;
    _showDialog(
      ctx: ctx,
      headerIcon: Icons.error_rounded,
      accentColor: AppColors.error,
      title: title,
      desc: message,
      btnOkText: okText,
      btnOkOnPress: onOk ?? () {},
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
    final ctx = _resolveContext(context);
    if (ctx == null) return;
    _showDialog(
      ctx: ctx,
      headerIcon: Icons.warning_rounded,
      accentColor: AppColors.statusWarning,
      title: title,
      desc: message,
      btnOkText: okText,
      btnOkOnPress: onOk ?? () {},
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
    final ctx = _resolveContext(context);
    if (ctx == null) return;
    _showDialog(
      ctx: ctx,
      headerIcon: Icons.info_rounded,
      accentColor: AppColors.primaryGold,
      title: title,
      desc: message,
      btnOkText: okText,
      btnOkOnPress: onOk ?? () {},
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
    final ctx = _resolveContext(context);
    if (ctx == null) return;
    final isDark = AppColors.isDark(ctx);
    final accentColor = isDestructive ? AppColors.error : AppColors.primaryGold;
    final headerIcon =
        isDestructive ? Icons.delete_forever_rounded : Icons.help_rounded;

    _showDialog(
      ctx: ctx,
      headerIcon: headerIcon,
      accentColor: accentColor,
      title: title,
      desc: message,
      btnOkText: confirmText,
      btnOkColor: accentColor,
      btnOkOnPress: onConfirm,
      btnCancelText: cancelText,
      btnCancelColor:
          isDark ? AppColors.darkSurfaceContainerHigh : AppColors.textSecondary,
      btnCancelOnPress: onCancel ?? () {},
    );
  }

  /// Menampilkan dialog loading non-dismissible.
  static void loading(
    BuildContext? context, {
    String message = 'Memproses...',
  }) {
    final ctx = _resolveContext(context);
    if (ctx == null) return;
    final isDark = AppColors.isDark(ctx);
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dCtx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.espressoDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Menutup dialog loading.
  static void dismissLoading(BuildContext? context) {
    final ctx = _resolveContext(context);
    if (ctx != null &&
        Navigator.of(ctx, rootNavigator: true).canPop()) {
      Navigator.of(ctx, rootNavigator: true).pop();
    }
  }
}

