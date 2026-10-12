import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_context.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool isPhone;
  final String phonePrefix;

  const AppTextField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.isPhone = false,
    this.phonePrefix = '+62',
  });

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.labelLarge?.copyWith(
              color: hc.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: isPhone ? TextInputType.phone : keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: textTheme.bodyMedium?.copyWith(
            color: hc.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: hc.textTertiary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            filled: true,
            fillColor: hc.surface,
            prefixIcon: isPhone ? _buildPhonePrefix(context) : prefixIcon,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: hc.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: hc.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(
                color: hc.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: hc.danger),
            ),
            constraints: const BoxConstraints(
              minHeight: AppSizes.buttonHeightSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhonePrefix(BuildContext context) {
    final hc = context.hc;
    final textTheme = context.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      margin: const EdgeInsets.only(right: AppSpacing.s8),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: hc.border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇮🇩', style: TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.s4),
          Text(
            phonePrefix,
            style: textTheme.bodyMedium?.copyWith(
              color: hc.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
