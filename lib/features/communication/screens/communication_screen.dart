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
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espressoDark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          context.tr('komunikasi').isEmpty ? 'Komunikasi Cepat' : context.tr('komunikasi'),
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdgeGutter,
          vertical: AppSpacing.md,
        ),
        children: [
          Text(
            'Tekan tombol suara untuk memutar rekaman bahasa Arab',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textBody),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildCategoryHeader('Darurat & Kesehatan'),
          ...controller.phrases
              .where((p) => p.category == 'Darurat & Kesehatan')
              .map((p) => _buildPhraseCard(controller, p)),

          const SizedBox(height: AppSpacing.md),
          _buildCategoryHeader('Arah & Lokasi'),
          ...controller.phrases
              .where((p) => p.category == 'Arah & Lokasi')
              .map((p) => _buildPhraseCard(controller, p)),

          const SizedBox(height: AppSpacing.md),
          _buildCategoryHeader('Umum'),
          ...controller.phrases
              .where((p) => p.category == 'Umum')
              .map((p) => _buildPhraseCard(controller, p)),

          const SizedBox(height: AppConstants.space3xl),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.espressoDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhraseCard(CommunicationController controller, PhraseItem phrase) {
    return Obx(() {
      final isCurrentlyPlaying = controller.activePhrase.value == phrase.arabic;

      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: phrase.isUrgent
              ? AppColors.errorContainer
              : (isCurrentlyPlaying
                  ? AppColors.goldLight.withValues(alpha: 0.15)
                  : AppColors.surfaceWhite),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isCurrentlyPlaying
                ? AppColors.accentGoldStar
                : (phrase.isUrgent
                    ? AppColors.sosEmergency.withValues(alpha: 0.3)
                    : AppColors.canvasCreamSubtle),
            width: isCurrentlyPlaying ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phrase.arabic,
                    style: AppTypography.displayMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.espressoDark,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: AppSpacing.sm2),
                  Text(
                    phrase.indonesian,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.espressoDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    phrase.transliteration,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textBody,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                color: phrase.isUrgent
                    ? AppColors.sosEmergency
                    : (isCurrentlyPlaying
                        ? AppColors.accentGoldStar
                        : AppColors.primaryContainer),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  isCurrentlyPlaying ? Icons.stop : Icons.volume_up,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (isCurrentlyPlaying) {
                    controller.stop();
                  } else {
                    controller.speak(phrase.arabic);
                  }
                },
              ),
            ),
          ],
        ),
      );
    });
  }
}
