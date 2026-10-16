import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

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
    IconData? icon,
    String okText = 'Baik',
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
    if (ctx == null) {
      return Future<T?>.value();
    }

    final hc = ctx.hc;
    final textTheme = ctx.text;

    // Theme color and icon configuration based on dialog type
    final Color accentColor;
    final IconData iconData;

    switch (type) {
      case AppDialogType.success:
        accentColor = hc.success;
        iconData = icon ?? Icons.check_circle_rounded;
        break;
      case AppDialogType.error:
        accentColor = hc.danger;
        iconData = icon ?? Icons.cancel_rounded;
        break;
      case AppDialogType.warning:
        accentColor = hc.warning;
        iconData = icon ?? Icons.warning_amber_rounded;
        break;
      case AppDialogType.info:
        accentColor = hc.accent;
        iconData = icon ?? Icons.info_rounded;
        break;
      case AppDialogType.confirm:
        accentColor = isDestructive ? hc.danger : (okColor ?? hc.accent);
        iconData =
            icon ??
            (isDestructive
                ? Icons.delete_forever_rounded
                : Icons.help_outline_rounded);
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
            constraints: const BoxConstraints(
              maxWidth: AppBreakpoints.maxDialogWidth,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s24,
              ),
              decoration: BoxDecoration(
                color: hc.surface,
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                border: Border.all(color: hc.border, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: hc.shadow,
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
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.28),
                              width: 2,
                            ),
                          ),
                          child: Icon(iconData, color: accentColor, size: 36),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Title
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium.copyWith(
                          color: hc.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Message
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: SingleChildScrollView(
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium.copyWith(
                              color: hc.textSecondary,
                              height: 1.5,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Buttons Row / Adaptive Column for Accessibility Scaling
                      Builder(
                        builder: (context) {
                          final textScaler = MediaQuery.textScalerOf(context);
                          final isLargeScale = textScaler.scale(15) > 19;
                          final okTextColor =
                              effectiveOkColor.computeLuminance() > 0.5
                              ? hc.textPrimary
                              : hc.onPrimary;

                          final cancelButton =
                              cancelText != null && cancelText.isNotEmpty
                              ? OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: hc.textSecondary,
                                    side: BorderSide(color: hc.borderStrong),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    minimumSize: const Size(
                                      0,
                                      AppSizes.buttonHeightSecondary,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (Get.isDialogOpen ?? false) {
                                      Get.back();
                                    }
                                    onCancel?.call();
                                  },
                                  child: Text(
                                    cancelText,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelLarge.copyWith(
                                      color: hc.textSecondary,
                                    ),
                                  ),
                                )
                              : null;

                          final okButton = ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: effectiveOkColor,
                              foregroundColor: okTextColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              minimumSize: const Size(
                                0,
                                AppSizes.buttonHeightSecondary,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (Get.isDialogOpen ?? false) {
                                Get.back();
                              }
                              onOk?.call();
                            },
                            child: Text(
                              okText,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelLarge.copyWith(
                                color: okTextColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );

                          if (cancelButton == null) {
                            return SizedBox(
                              width: double.infinity,
                              child: okButton,
                            );
                          }

                          if (isLargeScale) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                okButton,
                                const SizedBox(height: 10),
                                cancelButton,
                              ],
                            );
                          }

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: cancelButton),
                                const SizedBox(width: 10),
                                Expanded(child: okButton),
                              ],
                            ),
                          );
                        },
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
    String okText = 'Selesai',
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
    String title = 'Belum Berhasil',
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
    String okText = 'Baik',
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
    IconData? icon,
  }) async {
    await _show(
      context: context,
      type: AppDialogType.confirm,
      title: title,
      message: message,
      icon: icon,
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
    String message = 'Mohon tunggu...',
  }) {
    final ctx = resolveSafeContext(context);
    final hc = ctx?.hc ?? (Get.isDarkMode ? HajiColors.dark : HajiColors.light);

    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: hc.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: hc.border),
              boxShadow: [
                BoxShadow(
                  color: hc.shadow,
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: hc.accent,
                  ),
                ),
                const SizedBox(width: 16),
                Material(
                  color: Colors.transparent,
                  child: Text(
                    message,
                    style:
                        ctx?.text.bodyMedium.copyWith(
                          color: hc.textPrimary,
                          fontWeight: FontWeight.w600,
                        ) ??
                        TextStyle(
                          color: hc.textPrimary,
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
