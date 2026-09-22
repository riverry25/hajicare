import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ArabicDuaText extends StatelessWidget {
  final String text;

  const ArabicDuaText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Teks Arab',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SelectableText(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: AppColors.textHeadingColor(context),
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 2.0,
          ),
        ),
      ),
    );
  }
}

class TransliterationText extends StatelessWidget {
  final String text;

  const TransliterationText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return _LabeledTextSection(
      label: 'LATIN / TRANSLITERASI',
      child: SelectableText(
        text,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textBodyColor(context),
          fontStyle: FontStyle.italic,
          height: 1.65,
        ),
      ),
    );
  }
}

class TranslationText extends StatelessWidget {
  final String text;

  const TranslationText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return _LabeledTextSection(
      label: 'ARTI',
      child: SelectableText(
        text,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textBodyColor(context),
          height: 1.65,
        ),
      ),
    );
  }
}

class _LabeledTextSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledTextSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: isDark ? AppColors.goldLight : AppColors.goldDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}
