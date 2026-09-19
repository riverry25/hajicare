import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Semantic dialog types for AppDialog.
enum AppDialogType { success, error, warning, info, confirm }

/// Centralized, lifecycle-safe dialog and alert helper for HajiCare.
/// Built with native Flutter widgets & GetX dialog engine to completely eliminate
/// the AwesomeDialog unmounted context crash (`Null check operator used on a null value`).
class AppDialog {
  AppDialog._();

  /// Resolves an active, mounted BuildContext safely.
  /// Prioritizes [context] if it is valid and mounted, otherwise falls back to GetX overlays.
  static BuildContext? resolveSafeContext([BuildContext? context]) {
    if (context != null && context.mounted) {
      return context;
    }
    final overlayCtx = Get.overlayContext;
    if (overlayCtx != null && overlayCtx.mounted) {
      return overlayCtx;
    }
    final getCtx = Get.context;
    if (getCtx != null && getCtx.mounted) {
      return getCtx;
    }
    return null;
  }

  /// Base method to show a stylized, animated HajiCare dialog.
  static Future<T?> _show<T>({
    BuildContext? context,
    required AppDialogType type,
    required String title,
    required String message,
    String okText = 'OK',
    Color? okColor,
    VoidCallback? onOk,
    String? cancelText,
    Color? cancelColor,
    VoidCallback? onCancel,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
    bool barrierDismissible = true,
    bool isDestructive = false,
  }) {
    final ctx = resolveSafeContext(context);
    final isDark = ctx != null ? AppColors.isDark(ctx) : Get.isDarkMode;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;

    // Theme color and icon configuration based on dialog type
    final Color accentColor;
    final IconData iconData;

    switch (type) {
      case AppDialogType.success:
        accentColor = AppColors.statusSafe;
        iconData = Icons.check_circle_rounded;
        break;
      case AppDialogType.error:
        accentColor = AppColors.sosEmergency;
        iconData = Icons.cancel_rounded;
        break;
      case AppDialogType.warning:
        accentColor = AppColors.statusWarning;
        iconData = Icons.warning_amber_rounded;
        break;
      case AppDialogType.info:
        accentColor = isDark ? AppColors.goldLight : AppColors.goldPrimary;
        iconData = Icons.info_rounded;
        break;
      case AppDialogType.confirm:
        accentColor = isDestructive
            ? AppColors.sosEmergency
            : (isDark ? AppColors.goldLight : AppColors.goldPrimary);
        iconData = isDestructive
            ? Icons.delete_forever_rounded
            : Icons.help_outline_rounded;
        break;
    }

    final effectiveOkColor = okColor ?? accentColor;
    bool hasHandledDismiss = false;

    if (autoDismissDuration != null) {
      Future.delayed(autoDismissDuration, () {
        if (!hasHandledDismiss && (Get.isDialogOpen ?? false)) {
          hasHandledDismiss = true;
          Get.back();
          onOk?.call();
          onDismiss?.call();
        }
      });
    }

    return Get.dialog<T>(
      PopScope(
        canPop: barrierDismissible,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated Header Icon Badge
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.elasticOut,
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.28),
                              width: 2,
                            ),
                          ),
                          child: Icon(iconData, color: accentColor, size: 32),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Message
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Buttons Row
                      Row(
                        children: [
                          if (cancelText != null && cancelText.isNotEmpty) ...[
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: bodyColor,
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkOutlineVariant
                                        : AppColors.surfaceVariant,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  // Close dialog first
                                  if (Get.isDialogOpen ?? false) {
                                    Get.back();
                                  }
                                  onCancel?.call();
                                },
                                child: Text(
                                  cancelText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: effectiveOkColor,
                                foregroundColor: isDestructive
                                    ? Colors.white
                                    : (type == AppDialogType.info && !isDark
                                          ? Colors.white
                                          : Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                // Close dialog safely first to avoid any double-navigation or context-death
                                if (Get.isDialogOpen ?? false) {
                                  Get.back();
                                }
                                onOk?.call();
                              },
                              child: Text(
                                okText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  // ── Public APIs ───────────────────────────────────────────────────────────

  /// Shows a success modal feedback dialog.
  static Future<void> success({
    BuildContext? context,
    String title = 'Berhasil',
    required String message,
    VoidCallback? onOk,
    String okText = 'OK',
    Color? okColor,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) async {
    await _show(
      context: context,
      type: AppDialogType.success,
      title: title,
      message: message,
      okText: okText,
      okColor: okColor,
      onOk: onOk,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
    );
  }

  /// Shows an error modal feedback dialog.
  static Future<void> error({
    BuildContext? context,
    String title = 'Terjadi Kesalahan',
    required String message,
    VoidCallback? onOk,
    String okText = 'Tutup',
    Color? okColor,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) async {
    await _show(
      context: context,
      type: AppDialogType.error,
      title: title,
      message: message,
      okText: okText,
      okColor: okColor,
      onOk: onOk,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
    );
  }

  /// Shows a warning modal feedback dialog.
  static Future<void> warning({
    BuildContext? context,
    String title = 'Perhatian',
    required String message,
    VoidCallback? onOk,
    String okText = 'Mengerti',
    Color? okColor,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) async {
    await _show(
      context: context,
      type: AppDialogType.warning,
      title: title,
      message: message,
      okText: okText,
      okColor: okColor,
      onOk: onOk,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
    );
  }

  /// Shows an informational modal feedback dialog.
  static Future<void> info({
    BuildContext? context,
    String title = 'Informasi',
    required String message,
    VoidCallback? onOk,
    String okText = 'OK',
    Color? okColor,
    Duration? autoDismissDuration,
    VoidCallback? onDismiss,
  }) async {
    await _show(
      context: context,
      type: AppDialogType.info,
      title: title,
      message: message,
      okText: okText,
      okColor: okColor,
      onOk: onOk,
      autoDismissDuration: autoDismissDuration,
      onDismiss: onDismiss,
    );
  }

  /// Shows a confirmation dialog with OK and Cancel actions.
  static Future<void> confirm({
    BuildContext? context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    Color? confirmColor,
    Color? cancelColor,
    bool isDestructive = false,
  }) async {
    await _show(
      context: context,
      type: AppDialogType.confirm,
      title: title,
      message: message,
      okText: confirmText,
      okColor: confirmColor,
      onOk: onConfirm,
      cancelText: cancelText,
      cancelColor: cancelColor,
      onCancel: onCancel,
      isDestructive: isDestructive,
    );
  }

  /// Shows a modal non-dismissible loading spinner.
  static void loading({
    BuildContext? context,
    String message = 'Memproses...',
  }) {
    final ctx = resolveSafeContext(context);
    final isDark = ctx != null ? AppColors.isDark(ctx) : Get.isDarkMode;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppColors.goldLight.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 20,
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
                    color: AppColors.goldPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Material(
                  color: Colors.transparent,
                  child: Text(
                    message,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextHeading
                          : AppColors.espressoDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Closes active loading dialog safely.
  static void dismissLoading([BuildContext? context]) {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
