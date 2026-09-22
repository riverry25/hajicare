import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../models/hajj_dua.dart';
import '../hajj_dua_typography.dart';
import 'dua_text_sections.dart';

class DuaCard extends StatelessWidget {
  final HajjDua dua;
  final bool initiallyExpanded;

  const DuaCard({super.key, required this.dua, this.initiallyExpanded = false});

  Future<void> _copyDua(BuildContext context) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final localizedTitle = context.tr(dua.titleKey);
    await Clipboard.setData(
      ClipboardData(
        text: dua.toClipboardText(
          localizedTitle: localizedTitle,
          meaningLabel: context.tr('hajjDuaMeaning'),
          languageCode: languageCode,
          sourceLabel: context.tr('hajjDuaSource'),
        ),
      ),
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.tr('hajjDuaCopied', {'title': localizedTitle}),
            style: HajjDuaTypography.body.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accentColor = isDark ? AppColors.goldLight : AppColors.goldDark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final localizedTranslation = dua.translationFor(languageCode);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        iconColor: accentColor,
        collapsedIconColor: AppColors.textSecondaryColor(context),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          context.tr(dua.titleKey),
          style: HajjDuaTypography.cardTitle.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        subtitle: dua.subtitleKey == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  context.tr(dua.subtitleKey!),
                  style: HajjDuaTypography.caption.copyWith(
                    color: AppColors.textBodyColor(context),
                  ),
                ),
              ),
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          ArabicDuaText(key: Key('arabic_${dua.id}'), text: dua.arabic),
          if (dua.transliteration?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            TransliterationText(
              key: Key('transliteration_${dua.id}'),
              text: dua.transliteration!,
            ),
          ],
          if (localizedTranslation?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            TranslationText(
              key: Key('translation_${dua.id}'),
              text: localizedTranslation!,
            ),
          ],
          if (dua.descriptionKey != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _PlainInformation(
              title: context.tr('hajjDuaInformation'),
              message: context.tr(dua.descriptionKey!),
            ),
          ],
          if (dua.requiresSourceVerification) ...[
            const SizedBox(height: AppSpacing.lg),
            _VerificationNotice(
              title: context.tr('hajjDuaVerificationRequired'),
              message: dua.notesKey == null
                  ? context.tr('hajjDuaSourceUnknown')
                  : context.tr(dua.notesKey!),
            ),
          ] else if (dua.source?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            _PlainInformation(
              title: context.tr('hajjDuaSource'),
              message: dua.source!,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => _copyDua(context),
              icon: const Icon(Icons.copy_rounded, size: 19),
              label: Text(
                context.tr('hajjDuaCopy'),
                style: HajjDuaTypography.button,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainInformation extends StatelessWidget {
  final String title;
  final String message;

  const _PlainInformation({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: HajjDuaTypography.metadataLabel.copyWith(
            color: AppColors.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: HajjDuaTypography.body.copyWith(
            color: AppColors.textBodyColor(context),
          ),
        ),
      ],
    );
  }
}

class _VerificationNotice extends StatelessWidget {
  final String title;
  final String message;

  const _VerificationNotice({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.distanceWarning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.13 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_outlined, color: color, size: 21),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HajjDuaTypography.cardTitle.copyWith(
                    color: AppColors.textHeadingColor(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: HajjDuaTypography.caption.copyWith(
                    color: AppColors.textBodyColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
