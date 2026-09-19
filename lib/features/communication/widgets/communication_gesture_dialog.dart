import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/communication_controller.dart';

/// Modern gesture-driven modal sheet for quick Arabic-Indonesian communication.
/// Optimized for elderly jamaah with large Arabic typography, clear audio playback,
/// swipe-down dismiss gesture, and category filtering.
class CommunicationGestureDialog extends StatefulWidget {
  const CommunicationGestureDialog({super.key});

  /// Static helper to display this gesture dialog from anywhere with a single call.
  static Future<T?> show<T>(BuildContext context) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => const CommunicationGestureDialog(),
    );
  }

  @override
  State<CommunicationGestureDialog> createState() =>
      _CommunicationGestureDialogState();
}

class _CommunicationGestureDialogState
    extends State<CommunicationGestureDialog> {
  String _selectedCategory = 'Semua';

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final controller = Get.isRegistered<CommunicationController>()
        ? Get.find<CommunicationController>()
        : Get.put(CommunicationController());

    final filteredPhrases = _selectedCategory == 'Semua'
        ? controller.phrases
        : controller.phrases
            .where((p) => p.category == _selectedCategory)
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gesture Drag Indicator ──────────────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
          ),

          // ── Header Row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdgeGutter,
              vertical: 8,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.goldLight.withValues(alpha: 0.25)
                          : AppColors.goldPrimary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.record_voice_over_rounded,
                    color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Komunikasi Cepat',
                        style: AppTypography.titleLarge.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Lafal & Audio Arab-Indonesia untuk Jamaah',
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? AppColors.darkTextBody
                              : AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.stop();
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? AppColors.darkTextBody
                        : AppColors.textMuted,
                  ),
                  tooltip: 'Tutup',
                ),
              ],
            ),
          ),

          // ── Tip Banner: Layar & Pengeras Suara ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdgeGutter,
              vertical: 4,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.canvasCream,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark
                      ? AppColors.goldLight.withValues(alpha: 0.2)
                      : AppColors.goldPrimary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_rounded,
                    color: isDark ? AppColors.goldLight : AppColors.primaryGold,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tunjukkan layar ini kepada petugas / warga lokal atau tekan icon speaker untuk melafalkan suara.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextBody
                            : AppColors.espressoDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Quick Filter Chips ──────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdgeGutter,
            ),
            child: Row(
              children: [
                _buildFilterChip('Semua', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Darurat & Kesehatan', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Arah & Lokasi', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Umum', isDark),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),

          // ── Scrollable Phrase List ──────────────────────────────────────
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
                vertical: 14,
              ),
              itemCount: filteredPhrases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final phrase = filteredPhrases[i];
                return _buildPhraseCard(
                  context: context,
                  controller: controller,
                  phrase: phrase,
                  isDark: isDark,
                  headingColor: headingColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedCategory == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimaryContainer : AppColors.espressoDark)
              : (isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.goldLight : AppColors.espressoDark)
                : (isDark
                    ? AppColors.darkOutlineVariant
                    : AppColors.goldPrimary.withValues(alpha: 0.2)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextBody : AppColors.espressoDark),
          ),
        ),
      ),
    );
  }

  Widget _buildPhraseCard({
    required BuildContext context,
    required CommunicationController controller,
    required PhraseItem phrase,
    required bool isDark,
    required Color headingColor,
  }) {
    return Obx(() {
      final isCurrentlyPlaying =
          controller.activePhrase.value == phrase.arabic;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: phrase.isUrgent
              ? (isDark
                  ? const Color(0xFF2E1517)
                  : const Color(0xFFFFECEF))
              : (isCurrentlyPlaying
                  ? (isDark
                      ? AppColors.goldPrimary.withValues(alpha: 0.18)
                      : AppColors.goldLight.withValues(alpha: 0.25))
                  : (isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.cardBgColor(context))),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isCurrentlyPlaying
                ? (isDark ? AppColors.goldLight : AppColors.goldPrimary)
                : (phrase.isUrgent
                    ? AppColors.sosEmergency.withValues(alpha: 0.45)
                    : (isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.cardBorderColor(context))),
            width: isCurrentlyPlaying ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentlyPlaying
                  ? AppColors.goldPrimary.withValues(alpha: 0.12)
                  : AppColors.espressoDark.withValues(alpha: 0.03),
              blurRadius: isCurrentlyPlaying ? 10 : 4,
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
                        vertical: 2.5,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.sosEmergency.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'PENTING / DARURAT',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],

                  // Arabic Text (Large, crisp, RTL)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      phrase.arabic,
                      style: TextStyle(
                        fontFamily: 'Amiri', // Or default arabic font
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.espressoDark,
                        fontSize: 24,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Indonesian Meaning
                  Text(
                    phrase.indonesian,
                    style: TextStyle(
                      color: headingColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Latin Transliteration
                  Text(
                    phrase.transliteration,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Speaker Play/Stop Button
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
                borderRadius: BorderRadius.circular(24),
                child: Ink(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: phrase.isUrgent
                        ? AppColors.sosEmergency
                        : (isCurrentlyPlaying
                            ? (isDark
                                ? AppColors.goldLight
                                : AppColors.espressoDark)
                            : (isDark
                                ? AppColors.darkSurface
                                : AppColors.canvasCream)),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrentlyPlaying
                          ? (isDark
                              ? AppColors.goldLight
                              : AppColors.goldPrimary)
                          : (isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.cardBorderColor(context)),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (phrase.isUrgent
                                ? AppColors.sosEmergency
                                : (isDark
                                    ? AppColors.goldLight
                                    : AppColors.espressoDark))
                            .withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isCurrentlyPlaying
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded,
                    color: phrase.isUrgent || isCurrentlyPlaying
                        ? (isCurrentlyPlaying && isDark
                            ? AppColors.espressoDark
                            : Colors.white)
                        : (isDark
                            ? AppColors.goldLight
                            : AppColors.espressoDark),
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
