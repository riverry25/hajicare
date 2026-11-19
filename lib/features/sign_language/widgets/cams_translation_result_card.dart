import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/cams_canonical_frames.dart';
import '../../../services/cams_nlp_engine.dart';
import '../controllers/cams_translation_controller.dart';
import 'cams_fullscreen_display_page.dart';

/// 3-Language CAMS NLP Result Card (Indonesia C3/C0, Arabic MSA RTL, English)
/// with per-language TTS buttons, 1-meter Fullscreen Expand button, and
/// single-tap REQUEST_CLARIFICATION / REJECT_OOV safety gate states.
class CamsTranslationResultCard extends StatelessWidget {
  final CamsTranslationController controller;

  const CamsTranslationResultCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final result = controller.latestResult.value;
      if (result == null) {
        return const SizedBox.shrink();
      }

      switch (result.decision) {
        case CamsDecision.proceedTranslate:
          return _ProceedTranslateView(
            result: result,
            controller: controller,
          );
        case CamsDecision.requestClarification:
          return _RequestClarificationView(
            result: result,
            controller: controller,
          );
        case CamsDecision.rejectOov:
          return _RejectOovView(
            result: result,
            controller: controller,
          );
      }
    });
  }
}

class _ProceedTranslateView extends StatelessWidget {
  final CamsResult result;
  final CamsTranslationController controller;

  const _ProceedTranslateView({
    required this.result,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = isDark ? AppColors.goldLight : AppColors.espressoDark;
    final pct = (result.confidence * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row + Confidence + Fullscreen Button
          Row(
            children: [
              Icon(Icons.translate_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('sign.cams.resultHeader'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.emeraldIslamic.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pct%',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.emeraldIslamic,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CamsFullscreenDisplayPage(
                          result: result,
                          controller: controller,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      minWidth: 48,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fullscreen_rounded,
                          size: 18,
                          color: accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.tr('sign.cams.fullscreenBtn'),
                          style: AppTypography.captionSmall.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Primary Indonesian Card (18-20pt bold)
          _LanguageBlockCard(
            title: context.tr('sign.cams.langId'),
            languageCode: 'id',
            controller: controller,
            isHighlighted: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.idC3,
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: 19,
                    color: AppColors.textHeadingColor(context),
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                if (result.idC0.isNotEmpty && result.idC0 != result.idC3) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${context.tr('sign.cams.shortFormLabel')} ${result.idC0}',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textSecondaryColor(context),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2. Large Arabic MSA Card (24-26pt, RTL, NotoNaskhArabic)
          _LanguageBlockCard(
            title: context.tr('sign.cams.langAr'),
            languageCode: 'ar',
            controller: controller,
            isHighlighted: true,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                result.arText,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 25,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextHeading : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 3. English Card (16pt)
          _LanguageBlockCard(
            title: context.tr('sign.cams.langEn'),
            languageCode: 'en',
            controller: controller,
            isHighlighted: false,
            child: Text(
              result.enText,
              style: AppTypography.bodyLarge.copyWith(
                fontSize: 16,
                color: AppColors.textHeadingColor(context),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageBlockCard extends StatelessWidget {
  final String title;
  final String languageCode;
  final CamsTranslationController controller;
  final bool isHighlighted;
  final Widget child;

  const _LanguageBlockCard({
    required this.title,
    required this.languageCode,
    required this.controller,
    required this.isHighlighted,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final bgColor = isHighlighted
        ? (isDark ? AppColors.darkPrimaryContainer : AppColors.espressoDark)
        : (isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.canvasCreamSubtle);

    final borderColor = isHighlighted
        ? AppColors.goldLight.withValues(alpha: 0.65)
        : AppColors.cardBorderColor(context);

    final titleColor = isHighlighted
        ? AppColors.goldLight
        : AppColors.textSecondaryColor(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelMedium.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Obx(() {
                final isSpeaking =
                    controller.speakingLanguageCode.value == languageCode;
                final iconColor = isHighlighted
                    ? AppColors.goldLight
                    : (isDark ? AppColors.goldLight : AppColors.espressoDark);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.speakLanguage(languageCode);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        minWidth: 48,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSpeaking)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: iconColor,
                              ),
                            )
                          else
                            Icon(
                              Icons.volume_up_rounded,
                              size: 18,
                              color: iconColor,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('sign.cams.playAudio'),
                            style: AppTypography.labelMedium.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _RequestClarificationView extends StatelessWidget {
  final CamsResult result;
  final CamsTranslationController controller;

  const _RequestClarificationView({
    required this.result,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isEn =
        AppLocalizations.of(context).locale.languageCode.toLowerCase() == 'en';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.distanceWarning.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                color: AppColors.distanceWarning,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('sign.cams.clarificationTitle'),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.textHeadingColor(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('sign.cams.clarificationSub'),
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          for (final opt in result.clarificationOptions) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.applyClarification(opt);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer.withValues(
                              alpha: 0.65,
                            )
                          : AppColors.canvasCreamSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.goldLight.withValues(alpha: 0.45)
                            : AppColors.tanLight,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _clarificationIcon(opt.iconKey),
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.espressoDark,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isEn ? opt.labelEn : opt.labelId,
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.textHeadingColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.textSecondaryColor(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _clarificationIcon(String key) {
    switch (key) {
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'local_drink':
        return Icons.local_drink_rounded;
      case 'mosque':
        return Icons.mosque_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'emergency':
        return Icons.emergency_rounded;
      case 'explore':
        return Icons.explore_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }
}

class _RejectOovView extends StatelessWidget {
  final CamsResult result;
  final CamsTranslationController controller;

  const _RejectOovView({
    required this.result,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.sosEmergency.withValues(alpha: 0.5),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.sosEmergency,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('sign.cams.oovTitle'),
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.sosEmergency,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${context.tr('sign.cams.oovSub')} (${result.oovTokens.join(', ')})',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
