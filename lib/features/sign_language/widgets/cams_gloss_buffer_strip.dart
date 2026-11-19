import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/bisindo_recognition_controller.dart';
import '../controllers/cams_translation_controller.dart';
import '../models/sign_token.dart';

/// Live Gloss Buffer Strip displaying removable gesture chips with model-origin
/// badges (e.g. `[BANTU · BISINDO ×] + [DOKTER · SIBI ×]`), Hapus 1 Kata (⌫),
/// Reset, and primary Terjemahkan button.
class CamsGlossBufferStrip extends StatelessWidget {
  final BisindoRecognitionController recognitionController;
  final CamsTranslationController camsController;

  const CamsGlossBufferStrip({
    super.key,
    required this.recognitionController,
    required this.camsController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = AppColors.isDark(context);
      final tokens = recognitionController.tokens;
      final isPending = camsController.isAutoTranslatePending.value;
      final accent = isDark ? AppColors.goldLight : AppColors.espressoDark;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.cardBorderColor(context),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('sign.cams.glossBufferTitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
                if (isPending)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('sign.cams.autoTranslating'),
                        style: AppTypography.captionSmall.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (tokens.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  context.tr('sign.startSigningHint'),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < tokens.length; i++)
                    if (tokens[i].type != SignTokenType.space)
                      _RemovableGlossChip(
                        token: tokens[i],
                        onRemove: () {
                          HapticFeedback.lightImpact();
                          recognitionController.removeTokenAt(i);
                        },
                      ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _CompactBufferActionButton(
                    icon: Icons.backspace_outlined,
                    label: context.tr('sign.cams.deleteOne'),
                    color: AppColors.distanceWarning,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      recognitionController.deleteLast();
                    },
                  ),
                  const SizedBox(width: 8),
                  _CompactBufferActionButton(
                    icon: Icons.restart_alt_rounded,
                    label: context.tr('sign.reset'),
                    color: AppColors.textSecondaryColor(context),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      recognitionController.resetTranscript();
                      camsController.clearResult();
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          camsController.translateNow();
                        },
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text(
                          context.tr('sign.cams.translateNow'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge.copyWith(
                            color: isDark
                                ? AppColors.darkOnPrimary
                                : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.goldLight
                              : AppColors.espressoDark,
                          foregroundColor: isDark
                              ? AppColors.darkOnPrimary
                              : Colors.white,
                          minimumSize: const Size(88, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _RemovableGlossChip extends StatelessWidget {
  final SignToken token;
  final VoidCallback onRemove;

  const _RemovableGlossChip({
    required this.token,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final label = token.value.toUpperCase();
    final modelBadge = token.sourceModel?.toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkPrimaryContainer.withValues(alpha: 0.65)
                : AppColors.canvasCreamSubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? AppColors.accentGoldStar.withValues(alpha: 0.45)
                  : AppColors.tanLight,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textHeadingColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (modelBadge != null && modelBadge.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.espressoDark.withValues(alpha: 0.7)
                        : AppColors.espressoDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    modelBadge,
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textSecondaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactBufferActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CompactBufferActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
