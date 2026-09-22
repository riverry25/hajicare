import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../models/hajj_dua.dart';
import 'dua_text_sections.dart';

class DuaCard extends StatelessWidget {
  final HajjDua dua;
  final bool initiallyExpanded;

  const DuaCard({super.key, required this.dua, this.initiallyExpanded = false});

  Future<void> _copyDua(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: dua.toClipboardText()));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${dua.title} sudah disalin.'),
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
          dua.title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textHeadingColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: dua.subtitle == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  dua.subtitle!,
                  style: AppTypography.caption.copyWith(
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
          if (dua.translation?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            TranslationText(
              key: Key('translation_${dua.id}'),
              text: dua.translation!,
            ),
          ],
          if (dua.description?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            _InformationBox(
              icon: Icons.info_outline_rounded,
              title: 'Keterangan',
              message: dua.description!,
              color: AppColors.secondary,
            ),
          ],
          if (dua.requiresSourceVerification) ...[
            const SizedBox(height: AppSpacing.md),
            _InformationBox(
              icon: Icons.fact_check_outlined,
              title: 'Perlu verifikasi sumber',
              message:
                  dua.notes ??
                  'Sumber bacaan belum dicantumkan pada data aplikasi.',
              color: AppColors.distanceWarning,
            ),
          ] else if (dua.source?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.md),
            _InformationBox(
              icon: Icons.menu_book_outlined,
              title: 'Sumber',
              message: dua.source!,
              color: AppColors.statusPositive,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _copyDua(context),
              icon: const Icon(Icons.copy_rounded, size: 19),
              label: const Text('Salin bacaan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InformationBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _InformationBox({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, color: color, size: 21),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textHeadingColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.bodySmall.copyWith(
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
