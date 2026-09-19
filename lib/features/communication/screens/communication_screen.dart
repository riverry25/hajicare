import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/communication_controller.dart';

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CommunicationController>()
        ? Get.find<CommunicationController>()
        : Get.put(CommunicationController());

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.cardBgColor(context),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.espressoDark,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          context.tr('komunikasi').isEmpty
              ? 'Percakapan Cepat'
              : context.tr('komunikasi'),
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textHeadingColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: AppColors.cardBorderColor(context),
            width: 1,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdgeGutter,
          vertical: AppSpacing.md,
        ),
        children: [
          // Tip & Guidance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDark.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.canvasCream,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.record_voice_over_rounded,
                    color: AppColors.goldPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tunjukkan Layar atau Putar Suara',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textHeadingColor(context),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tekan tombol pengeras suara untuk melafalkan ke warga lokal atau petugas.',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 1. Darurat & Kesehatan
          _buildCategoryHeader(
            context,
            title: 'Darurat & Kesehatan',
            icon: Icons.health_and_safety_rounded,
            badgeColor: AppColors.sosEmergency,
          ),
          const SizedBox(height: 8),
          ...controller.phrases
              .where((p) => p.category == 'Darurat & Kesehatan')
              .map((p) => _buildPhraseCard(context, controller, p)),

          const SizedBox(height: AppSpacing.lg),

          // 2. Arah & Lokasi
          _buildCategoryHeader(
            context,
            title: 'Arah & Lokasi',
            icon: Icons.near_me_rounded,
            badgeColor: AppColors.goldPrimary,
          ),
          const SizedBox(height: 8),
          ...controller.phrases
              .where((p) => p.category == 'Arah & Lokasi')
              .map((p) => _buildPhraseCard(context, controller, p)),

          const SizedBox(height: AppSpacing.lg),

          // 3. Umum
          _buildCategoryHeader(
            context,
            title: 'Percakapan Umum',
            icon: Icons.chat_bubble_outline_rounded,
            badgeColor: AppColors.tanMedium,
          ),
          const SizedBox(height: 8),
          ...controller.phrases
              .where((p) => p.category == 'Umum')
              .map((p) => _buildPhraseCard(context, controller, p)),

          const SizedBox(height: AppConstants.space3xl),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: badgeColor, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textHeadingColor(context),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPhraseCard(
    BuildContext context,
    CommunicationController controller,
    PhraseItem phrase,
  ) {
    return Obx(() {
      final isCurrentlyPlaying = controller.activePhrase.value == phrase.arabic;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: phrase.isUrgent
              ? AppColors.errorContainer.withValues(alpha: 0.35)
              : (isCurrentlyPlaying
                    ? AppColors.goldPrimary.withValues(alpha: 0.12)
                    : AppColors.cardBgColor(context)),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isCurrentlyPlaying
                ? AppColors.goldPrimary
                : (phrase.isUrgent
                      ? AppColors.sosEmergency.withValues(alpha: 0.4)
                      : AppColors.cardBorderColor(context)),
            width: isCurrentlyPlaying ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentlyPlaying
                  ? AppColors.goldPrimary.withValues(alpha: 0.15)
                  : AppColors.espressoDark.withValues(alpha: 0.03),
              blurRadius: isCurrentlyPlaying ? 10 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (phrase.isUrgent) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.sosEmergency.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'PENTING / DARURAT',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],

                  // Arabic Text (Large, crisp, readable for elderly)
                  Text(
                    phrase.arabic,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.espressoDark,
                      fontSize: 26,
                      height: 1.35,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),

                  // Indonesian Meaning
                  Text(
                    phrase.indonesian,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textHeadingColor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Latin Transliteration
                  Text(
                    phrase.transliteration,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),

            // Wide Audio Playback Button (50x50 touch target)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isCurrentlyPlaying) {
                    controller.stop();
                  } else {
                    controller.speak(phrase.arabic);
                  }
                },
                borderRadius: BorderRadius.circular(25),
                child: Ink(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: phrase.isUrgent
                        ? AppColors.sosEmergency
                        : (isCurrentlyPlaying
                              ? AppColors.espressoDark
                              : AppColors.canvasCream),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrentlyPlaying
                          ? AppColors.goldPrimary
                          : AppColors.cardBorderColor(context),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (phrase.isUrgent
                                    ? AppColors.sosEmergency
                                    : AppColors.espressoDark)
                                .withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCurrentlyPlaying
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded,
                    color: phrase.isUrgent || isCurrentlyPlaying
                        ? Colors.white
                        : AppColors.espressoDark,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
