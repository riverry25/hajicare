import 'package:flutter/material.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../hajj_dua_typography.dart';

class ArabicDuaText extends StatelessWidget {
  final String text;
  final double scale;

  const ArabicDuaText({super.key, required this.text, this.scale = 1.0});

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
            fontSize: (HajjDuaTypography.arabic.fontSize ?? 31) * scale,
            height: 1.95,
          ),
        ),
      ),
    );
  }
}

class TransliterationText extends StatelessWidget {
  final String text;
  final double scale;

  const TransliterationText({super.key, required this.text, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return _LabeledTextSection(
      label: context.tr('hajjDuaTransliteration'),
      child: SelectableText(
        text,
        style: HajjDuaTypography.transliteration.copyWith(
          color: AppColors.textBodyColor(context),
          fontSize: (HajjDuaTypography.transliteration.fontSize ?? 15) * scale,
        ),
      ),
    );
  }
}

class TranslationText extends StatelessWidget {
  final String text;
  final double scale;

  const TranslationText({super.key, required this.text, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return _LabeledTextSection(
      label: context.tr('hajjDuaMeaning'),
      child: SelectableText(
        text,
        style: HajjDuaTypography.translation.copyWith(
          color: AppColors.textBodyColor(context),
          fontSize: (HajjDuaTypography.translation.fontSize ?? 14.5) * scale,
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
