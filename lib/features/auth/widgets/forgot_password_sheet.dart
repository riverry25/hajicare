import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
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
      constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxSheetWidth),
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
    final colors = context.hc;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenEdgeGutter,
        AppSpacing.md,
        AppSpacing.screenEdgeGutter,
        AppSpacing.xl + bottomInset,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
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
                color: colors.borderStrong,
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
                color: colors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 28,
                color: colors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            context.tr('auth.forgotPasswordTitle'),
            textAlign: TextAlign.center,
            style: context.text.titleLarge.copyWith(
              color: colors.textPrimary,
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
              style: context.text.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Email input
          Text(
            context.tr('auth.email'),
            style: context.text.labelLarge.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 8),

          AppTextField(
            controller: _emailController,
            hintText: context.tr('auth.emailHint'),
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icon(
              Icons.mail_outline_rounded,
              color: colors.accent,
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
                color: colors.primary,
                textColor: colors.onPrimary,
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
              style: context.text.bodySmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
