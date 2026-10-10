import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../controllers/login_controller.dart';

class ForgotPasswordSheet extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordSheet({super.key, this.initialEmail});

  static Future<void> show(BuildContext context, {String? initialEmail}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForgotPasswordSheet(initialEmail: initialEmail),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final TextEditingController _emailController;
  final LoginController _loginController = Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final success = await _loginController.sendPasswordReset(
      _emailController.text,
    );
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenEdgeGutter,
        AppSpacing.md,
        AppSpacing.screenEdgeGutter,
        AppSpacing.xl + bottomInset,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineColor(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Icon header
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerHighest
                    : AppColors.canvasCream,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.goldPrimary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 28,
                color: isDark ? AppColors.goldLight : AppColors.espressoDark,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            context.tr('auth.forgotPasswordTitle'),
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textHeadingColor(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              context.tr('auth.forgotPasswordSubtitle'),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryColor(context),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Email input
          Text(
            context.tr('auth.email'),
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textHeadingColor(context),
            ),
          ),
          const SizedBox(height: 8),

          AppTextField(
            controller: _emailController,
            hintText: context.tr('auth.emailHint'),
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              color: AppColors.tanMedium,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Submit button
          Obx(
            () => SizedBox(
              height: 52,
              child: PillButton(
                label: _loginController.isResetPasswordLoading.value
                    ? context.tr('auth.loginLoading')
                    : context.tr('auth.sendResetLink'),
                icon: Icons.send_rounded,
                color: isDark ? AppColors.goldPrimary : AppColors.espressoDark,
                textColor: isDark
                    ? AppColors.espressoDark
                    : AppColors.surfaceWhite,
                onPressed: _loginController.isResetPasswordLoading.value
                    ? null
                    : _handleSubmit,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.tr('common.cancel'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
