import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/cams_nlp_engine.dart';
import '../controllers/cams_translation_controller.dart';

/// Distraction-free, high-contrast Fullscreen Presentation Page for showing
/// the 3-language CAMS NLP result (Arabic MSA RTL, Indonesian, English) to an
/// interlocutor (Doctor, Asykar, Hotel Staff) from a 1-meter distance.
class CamsFullscreenDisplayPage extends StatelessWidget {
  final CamsResult result;
  final CamsTranslationController controller;

  const CamsFullscreenDisplayPage({
    super.key,
    required this.result,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = isDark ? AppColors.goldLight : AppColors.espressoDark;

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.cardBgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close_rounded,
            color: AppColors.textHeadingColor(context),
          ),
        ),
        title: Text(
          context.tr('sign.cams.fullscreenTitle'),
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textHeadingColor(context),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('sign.cams.fullscreenSub'),
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // 1. Large Arabic MSA Card (Primary for Saudi Doctors & Asykar)
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.espressoDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('sign.cams.langAr'),
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _FullscreenSpeakButton(
                          controller: controller,
                          languageCode: 'ar',
                          isInverted: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        result.arText,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'NotoNaskhArabic',
                          fontSize: 34,
                          height: 1.55,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Indonesian Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBgColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('sign.cams.langId'),
                          style: AppTypography.labelLarge.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _FullscreenSpeakButton(
                          controller: controller,
                          languageCode: 'id',
                          isInverted: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.idC3,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 23,
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. English Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBgColor(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.cardBorderColor(context),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('sign.cams.langEn'),
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textSecondaryColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _FullscreenSpeakButton(
                          controller: controller,
                          languageCode: 'en',
                          isInverted: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.enText,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenSpeakButton extends StatelessWidget {
  final CamsTranslationController controller;
  final String languageCode;
  final bool isInverted;

  const _FullscreenSpeakButton({
    required this.controller,
    required this.languageCode,
    required this.isInverted,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSpeakingThis =
          controller.speakingLanguageCode.value == languageCode;
      final isDark = AppColors.isDark(context);
      final fg = isInverted
          ? AppColors.espressoDark
          : (isDark ? AppColors.darkOnPrimary : Colors.white);
      final bg = isInverted
          ? AppColors.goldLight
          : (isDark ? AppColors.goldLight : AppColors.espressoDark);

      return SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            controller.speakLanguage(languageCode);
          },
          icon: isSpeakingThis
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              : Icon(Icons.volume_up_rounded, size: 20, color: fg),
          label: Text(
            '${context.tr('sign.cams.playAudio')} (${languageCode.toUpperCase()})',
            style: AppTypography.labelLarge.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            minimumSize: const Size(88, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    });
  }
}
