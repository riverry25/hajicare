import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/communication_controller.dart';

/// Modern gesture-driven modal sheet for quick Arabic-Indonesian communication.
/// Fully responsive under large accessibility text scales, dynamic multi-language,
/// search-capable, with full-screen zoom mode and robust audio playback.
class CommunicationGestureDialog extends StatefulWidget {
  const CommunicationGestureDialog({super.key});

  /// Static helper to display this gesture dialog from anywhere with a single call.
  static Future<T?> show<T>(BuildContext context) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => const CommunicationGestureDialog(),
    );
  }

  @override
  State<CommunicationGestureDialog> createState() =>
      _CommunicationGestureDialogState();
}

class _CommCategoryItem {
  final String key;
  final String translationKey;
  final String defaultLabel;
  final IconData icon;

  const _CommCategoryItem({
    required this.key,
    required this.translationKey,
    required this.defaultLabel,
    required this.icon,
  });
}

class _CommunicationGestureDialogState
    extends State<CommunicationGestureDialog> {
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  static const List<_CommCategoryItem> _categories = [
    _CommCategoryItem(
      key: 'Semua',
      translationKey: 'quickComm.catAll',
      defaultLabel: 'Semua',
      icon: Icons.apps_rounded,
    ),
    _CommCategoryItem(
      key: 'Darurat & Kesehatan',
      translationKey: 'quickComm.catEmergency',
      defaultLabel: 'Darurat & Kesehatan',
      icon: Icons.health_and_safety_rounded,
    ),
    _CommCategoryItem(
      key: 'Arah & Lokasi',
      translationKey: 'quickComm.catDirections',
      defaultLabel: 'Arah & Lokasi',
      icon: Icons.near_me_rounded,
    ),
    _CommCategoryItem(
      key: 'Umum',
      translationKey: 'quickComm.catGeneral',
      defaultLabel: 'Umum',
      icon: Icons.chat_bubble_outline_rounded,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAudioHelpDialog(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final controller = Get.isRegistered<CommunicationController>()
        ? Get.find<CommunicationController>()
        : Get.put(CommunicationController());

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.goldPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('quickComm.audioHelpTitle'),
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('quickComm.audioHelpDesc'),
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                _buildHelpItem(
                  icon: Icons.volume_up_rounded,
                  title: context.tr('quickComm.audioHelpVolumeTitle'),
                  subtitle: context.tr('quickComm.audioHelpVolumeDesc'),
                  isDark: isDark,
                  headingColor: headingColor,
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  icon: Icons.notifications_active_rounded,
                  title: context.tr('quickComm.audioHelpRingerTitle'),
                  subtitle: context.tr('quickComm.audioHelpRingerDesc'),
                  isDark: isDark,
                  headingColor: headingColor,
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  icon: Icons.language_rounded,
                  title: context.tr('quickComm.audioHelpVoiceTitle'),
                  subtitle: context.tr('quickComm.audioHelpVoiceDesc'),
                  isDark: isDark,
                  headingColor: headingColor,
                  trailing: Obx(() {
                    final isReady = controller.isArabicVoiceAvailable.value;
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isReady
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.1)
                            : AppColors.goldPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isReady
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.35)
                              : AppColors.goldPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isReady
                                    ? Icons.check_circle_rounded
                                    : Icons.info_outline_rounded,
                                size: 16,
                                color: isReady
                                    ? const Color(0xFF2E7D32)
                                    : AppColors.goldPrimary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isReady
                                      ? context.tr('quickComm.arabicVoiceReady')
                                      : context.tr(
                                          'quickComm.arabicVoiceNotInstalled',
                                        ),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isReady
                                        ? const Color(0xFF2E7D32)
                                        : (isDark
                                              ? AppColors.goldLight
                                              : AppColors.espressoDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                controller.installOrDownloadArabicVoice();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 16,
                              ),
                              label: Text(
                                context.tr('quickComm.installArabicVoice'),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                controller.openTtsSettings();
                              },
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                              ),
                              child: Text(
                                context.tr('quickComm.openTtsSettings'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark
                                      ? AppColors.goldLight
                                      : AppColors.goldPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                context.tr('common.close'),
                style: const TextStyle(
                  color: AppColors.goldPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color headingColor,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.goldPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: headingColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? AppColors.darkTextBody : AppColors.textMuted,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ],
    );
  }

  void _showZoomModal(
    BuildContext context,
    PhraseItem phrase,
    CommunicationController controller,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (zoomCtx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(zoomCtx).bottom + 20,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_rounded,
                        color: AppColors.goldPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('quickComm.showLocals').isNotEmpty
                            ? context.tr('quickComm.showLocals')
                            : 'Tunjukkan ke Warga / Petugas',
                        style: AppTypography.titleSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(zoomCtx).pop(),
                    tooltip: context.tr('quickComm.closeTooltip').isNotEmpty
                        ? context.tr('quickComm.closeTooltip')
                        : 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Giant Arabic Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: phrase.isUrgent
                      ? (isDark
                            ? const Color(0xFF381418)
                            : const Color(0xFFFFF0F2))
                      : (isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.canvasCream),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: phrase.isUrgent
                        ? AppColors.sosEmergency.withValues(alpha: 0.6)
                        : (isDark
                              ? AppColors.goldLight.withValues(alpha: 0.3)
                              : AppColors.goldPrimary.withValues(alpha: 0.4)),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    if (phrase.isUrgent) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.sosEmergency.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: AppColors.sosEmergency.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        child: Text(
                          context.tr('quickComm.urgentBadge').isNotEmpty
                              ? context.tr('quickComm.urgentBadge')
                              : 'PENTING / DARURAT',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.sosEmergency,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                    // Giant Arabic Text
                    SelectableText(
                      phrase.arabic,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.espressoDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Transliteration
                    Text(
                      phrase.transliteration,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.darkTextBody
                            : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Localized Meaning
                    Text(
                      phrase.localizedMeaning(context),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: headingColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons Row: Big Speaker & Copy
              Row(
                children: [
                  // Big Speaker Button
                  Expanded(
                    flex: 2,
                    child: Obx(() {
                      final isPlaying =
                          controller.activePhrase.value == phrase.arabic;

                      return ElevatedButton.icon(
                        onPressed: () {
                          if (isPlaying) {
                            controller.stop();
                          } else {
                            controller.speak(phrase.arabic);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: phrase.isUrgent
                              ? AppColors.sosEmergency
                              : (isPlaying
                                    ? (isDark
                                          ? AppColors.goldLight
                                          : AppColors.espressoDark)
                                    : AppColors.primaryGold),
                          foregroundColor: isPlaying && isDark
                              ? AppColors.espressoDark
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          elevation: 2,
                        ),
                        icon: Icon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.volume_up_rounded,
                          size: 24,
                        ),
                        label: Text(
                          isPlaying
                              ? (context.tr('quickComm.stopAudio').isNotEmpty
                                    ? context.tr('quickComm.stopAudio')
                                    : 'Hentikan')
                              : (context.tr('quickComm.tapToListen').isNotEmpty
                                    ? context.tr('quickComm.tapToListen')
                                    : 'Lafalkan Suara'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 10),
                  // Copy Button
                  IconButton.filledTonal(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phrase.arabic));
                      final msg = context.tr('quickComm.copied').isNotEmpty
                          ? context.tr('quickComm.copied')
                          : 'Teks Arab berhasil disalin';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    tooltip: context.tr('quickComm.copyTooltip').isNotEmpty
                        ? context.tr('quickComm.copyTooltip')
                        : 'Salin Teks Arab',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final controller = Get.isRegistered<CommunicationController>()
        ? Get.find<CommunicationController>()
        : Get.put(CommunicationController());

    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Gesture Drag Indicator ────────────────────────────────────
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

            // ── Header Row ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
                vertical: 6,
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
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.tr('quickComm.title').isNotEmpty
                                ? context.tr('quickComm.title')
                                : 'Komunikasi Cepat',
                            style: AppTypography.titleLarge.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.tr('quickComm.subtitle').isNotEmpty
                              ? context.tr('quickComm.subtitle')
                              : 'Lafal & Audio Arab-Indonesia untuk Jamaah',
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
                    onPressed: () => _showAudioHelpDialog(context),
                    icon: Icon(
                      Icons.help_outline_rounded,
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark,
                      size: 22,
                    ),
                    tooltip: context.tr('quickComm.audioHelpTitle').isNotEmpty
                        ? context.tr('quickComm.audioHelpTitle')
                        : 'Bantuan Audio',
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
                    tooltip: context.tr('quickComm.closeTooltip').isNotEmpty
                        ? context.tr('quickComm.closeTooltip')
                        : 'Tutup',
                  ),
                ],
              ),
            ),

            // ── Tip Guidance Banner ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
                vertical: 4,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
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
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.primaryGold,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('quickComm.tipBanner').isNotEmpty
                            ? context.tr('quickComm.tipBanner')
                            : 'Tunjukkan layar ini kepada petugas / warga lokal atau tekan icon speaker untuk melafalkan suara.',
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

            // ── Arabic Voice Download Prompt Banner (If Missing) ──────────
            Obx(() {
              if (controller.isArabicVoiceAvailable.value ||
                  !controller.isTtsInitialized.value) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                  vertical: 3,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.download_for_offline_rounded,
                        color: AppColors.goldPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('quickComm.voiceDownloadPrompt'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.goldLight
                                : AppColors.espressoDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          controller.installOrDownloadArabicVoice();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Text(
                          context.tr('quickComm.downloadVoice'),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // ── Search Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
                vertical: 6,
              ),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.cardBorderColor(context),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 13, color: headingColor),
                  decoration: InputDecoration(
                    hintText: context.tr('quickComm.searchHint').isNotEmpty
                        ? context.tr('quickComm.searchHint')
                        : 'Cari percakapan (dokter, arah, sakit...)',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.goldPrimary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              controller.clearSearchQuery();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) {
                    controller.updateSearchQuery(val);
                    setState(() {});
                  },
                ),
              ),
            ),

            // ── Filter Chips Row ──────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
                vertical: 4,
              ),
              child: Row(
                children: _categories.map((cat) {
                  final rawLabel = context.tr(cat.translationKey);
                  final label = rawLabel.isNotEmpty
                      ? rawLabel
                      : cat.defaultLabel;
                  final count = cat.key == 'Semua'
                      ? controller.phrases.length
                      : controller.phrases
                            .where((p) => p.category == cat.key)
                            .length;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      categoryKey: cat.key,
                      label: label,
                      count: count,
                      isDark: isDark,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 6),
            const Divider(height: 1),

            // ── TTS Error Helper Banner (If Active) ───────────────────────
            Obx(() {
              if (!controller.hasTtsError.value) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                  vertical: 6,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sosEmergency.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.sosEmergency.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.volume_off_rounded,
                      color: AppColors.sosEmergency,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('quickComm.ttsError').isNotEmpty
                            ? context.tr('quickComm.ttsError')
                            : 'Audio belum bersuara. Pastikan volume media aktif atau unduh paket suara Arab di HP.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!controller.isArabicVoiceAvailable.value) ...[
                      TextButton(
                        onPressed: () =>
                            controller.installOrDownloadArabicVoice(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          context.tr('quickComm.downloadVoice'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.sosEmergency,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    TextButton(
                      onPressed: () => _showAudioHelpDialog(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        context.tr('quickComm.audioHelpTitle').isNotEmpty
                            ? context.tr('quickComm.audioHelpTitle')
                            : 'Bantuan',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── Scrollable Phrase List ────────────────────────────────────
            Expanded(
              child: Builder(
                builder: (context) {
                  final filteredPhrases = controller.filterPhrases(
                    selectedCategory: _selectedCategory,
                    query: _searchController.text,
                    context: context,
                  );

                  if (filteredPhrases.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : AppColors.outlineVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context
                                      .tr('quickComm.emptySearchResult')
                                      .isNotEmpty
                                  ? context.tr('quickComm.emptySearchResult')
                                  : 'Tidak ada percakapan yang cocok.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextBody
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenEdgeGutter,
                      vertical: 12,
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String categoryKey,
    required String label,
    required int count,
    required bool isDark,
  }) {
    final isSelected = _selectedCategory == categoryKey;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = categoryKey;
        });
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.espressoDark)
              : (isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.canvasCream),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.goldLight : AppColors.espressoDark)
                : (isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.goldPrimary.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AppColors.darkTextBody
                          : AppColors.espressoDark),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                          ? AppColors.goldLight.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.2))
                    : (isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.espressoDark.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.darkTextBody : AppColors.textMuted),
                ),
              ),
            ),
          ],
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
      final isCurrentlyPlaying = controller.activePhrase.value == phrase.arabic;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: phrase.isUrgent
              ? (isDark ? const Color(0xFF2E1517) : const Color(0xFFFFECEF))
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Urgent badge (if any) and Action Buttons (Zoom & Copy)
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (phrase.isUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.sosEmergency.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        context.tr('quickComm.urgentBadge').isNotEmpty
                            ? context.tr('quickComm.urgentBadge')
                            : 'PENTING / DARURAT',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.w800,
                          fontSize: 9.5,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zoom Fullscreen Button
                      IconButton(
                        icon: const Icon(Icons.fullscreen_rounded, size: 20),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: context.tr('quickComm.zoomTooltip').isNotEmpty
                            ? context.tr('quickComm.zoomTooltip')
                            : 'Perbesar untuk Warga Lokal',
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.espressoDark,
                        onPressed: () =>
                            _showZoomModal(context, phrase, controller),
                      ),
                      const SizedBox(width: 8),
                      // Copy Button
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: context.tr('quickComm.copyTooltip').isNotEmpty
                            ? context.tr('quickComm.copyTooltip')
                            : 'Salin Teks Arab',
                        color: isDark
                            ? AppColors.darkTextBody
                            : AppColors.textMuted,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: phrase.arabic));
                          final msg = context.tr('quickComm.copied').isNotEmpty
                              ? context.tr('quickComm.copied')
                              : 'Teks Arab berhasil disalin';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(msg),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Middle Row: Text content and Speaker Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arabic Text (Right-aligned, large, crisp RTL)
                      Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            phrase.arabic,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.espressoDark,
                              fontSize: 24,
                              height: 1.4,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Localized Meaning
                      Text(
                        phrase.localizedMeaning(context),
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

                // Primary Speaker Play/Stop Button
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
                            color:
                                (phrase.isUrgent
                                        ? AppColors.sosEmergency
                                        : (isDark
                                              ? AppColors.goldLight
                                              : AppColors.espressoDark))
                                    .withValues(alpha: 0.25),
                            blurRadius: isCurrentlyPlaying ? 10 : 6,
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
          ],
        ),
      );
    });
  }
}
