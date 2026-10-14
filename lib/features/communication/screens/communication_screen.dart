import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/communication_controller.dart';
import '../widgets/bisindo_card.dart';

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final controller = Get.find<CommunicationController>();

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.primary),
          onPressed: () => Get.back(),
        ),
        title: Text(
          context.tr('komunikasi').isEmpty
              ? 'Percakapan Cepat'
              : context.tr('komunikasi'),
          style: context.text.titleLarge.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      body: ResponsiveCenter(
        maxWidth: AppBreakpoints.maxTabletContentWidth,
        child: ListView(
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
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.03),
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
                      color: colors.surfaceSubtle,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: colors.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('quickComm.showLocals').isNotEmpty
                              ? context.tr('quickComm.showLocals')
                              : 'Tunjukkan Layar atau Putar Suara',
                          style: context.text.labelSmall.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('quickComm.tipBanner').isNotEmpty
                              ? context.tr('quickComm.tipBanner')
                              : 'Tekan tombol pengeras suara untuk melafalkan ke warga lokal atau petugas.',
                          style: context.text.labelSmall.copyWith(
                            color: colors.textSecondary,
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

            // BISINDO Neural Network Gesture Recognizer
            const BisindoCard(),

            // 1. Darurat & Kesehatan
            _buildCategoryHeader(
              context,
              title: context.tr('comm.emergencyAndHealth'),
              icon: Icons.health_and_safety_rounded,
              badgeColor: colors.danger,
            ),
            const SizedBox(height: 8),
            ...controller.phrases
                .where((p) => p.category == 'Darurat & Kesehatan')
                .map((p) => _buildPhraseCard(context, controller, p)),

            const SizedBox(height: AppSpacing.lg),

            // 2. Arah & Lokasi
            _buildCategoryHeader(
              context,
              title: context.tr('comm.directionAndLocation'),
              icon: Icons.near_me_rounded,
              badgeColor: colors.accent,
            ),
            const SizedBox(height: 8),
            ...controller.phrases
                .where((p) => p.category == 'Arah & Lokasi')
                .map((p) => _buildPhraseCard(context, controller, p)),

            const SizedBox(height: AppSpacing.lg),

            // 3. Umum
            _buildCategoryHeader(
              context,
              title: context.tr('comm.generalConversation'),
              icon: Icons.chat_bubble_outline_rounded,
              badgeColor: colors.accentText,
            ),
            const SizedBox(height: 8),
            ...controller.phrases
                .where((p) => p.category == 'Umum')
                .map((p) => _buildPhraseCard(context, controller, p)),

            const SizedBox(height: AppConstants.space3xl),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color badgeColor,
  }) {
    final colors = context.hc;
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
          style: context.text.titleMedium.copyWith(
            color: colors.textPrimary,
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
    final colors = context.hc;
    return Obx(() {
      final isCurrentlyPlaying = controller.activePhrase.value == phrase.arabic;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: phrase.isUrgent
              ? colors.dangerContainer.withValues(alpha: 0.35)
              : (isCurrentlyPlaying
                    ? colors.primaryContainer.withValues(alpha: 0.35)
                    : colors.surface),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isCurrentlyPlaying
                ? colors.accent
                : (phrase.isUrgent
                      ? colors.danger.withValues(alpha: 0.4)
                      : colors.border),
            width: isCurrentlyPlaying ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentlyPlaying
                  ? colors.accent.withValues(alpha: 0.15)
                  : colors.primary.withValues(alpha: 0.03),
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
                        color: colors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: colors.danger.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        context.tr('quickComm.urgentBadge').isNotEmpty
                            ? context.tr('quickComm.urgentBadge')
                            : 'PENTING / DARURAT',
                        style: context.text.labelSmall.copyWith(
                          color: colors.danger,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],

                  // Arabic Text (Large, crisp, readable for elderly)
                  Text(
                    phrase.arabic,
                    style: context.textX.arabic.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                      fontSize: 26,
                      height: 1.35,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 6),

                  // Localized Meaning
                  Text(
                    phrase.localizedMeaning(context),
                    style: context.text.titleMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Latin Transliteration
                  Text(
                    phrase.transliteration,
                    style: context.text.bodySmall.copyWith(
                      color: colors.textSecondary,
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
                        ? colors.danger
                        : (isCurrentlyPlaying
                              ? colors.primary
                              : colors.surfaceSubtle),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrentlyPlaying ? colors.accent : colors.border,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (phrase.isUrgent ? colors.danger : colors.primary)
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
                        : colors.primary,
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
