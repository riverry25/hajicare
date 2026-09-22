import 'package:flutter/material.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../hajj_dua_typography.dart';

class ArabicDuaText extends StatelessWidget {
  final String text;

  const ArabicDuaText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('hajjDuaArabicSemantics'),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SelectableText(
          text,
          textAlign: TextAlign.right,
          style: HajjDuaTypography.arabic.copyWith(
            color: AppColors.textHeadingColor(context),
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
      label: context.tr('hajjDuaTransliteration'),
      child: SelectableText(
        text,
        style: HajjDuaTypography.transliteration.copyWith(
          color: AppColors.textBodyColor(context),
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
      label: context.tr('hajjDuaMeaning'),
      child: SelectableText(
        text,
        style: HajjDuaTypography.translation.copyWith(
          color: AppColors.textBodyColor(context),
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
          style: HajjDuaTypography.metadataLabel.copyWith(
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
