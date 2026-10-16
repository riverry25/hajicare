import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
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
    final colors = context.hc;
    final textTheme = context.text;
    final controller = Get.isRegistered<CommunicationController>()
        ? Get.find<CommunicationController>()
        : Get.put(CommunicationController());

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: colors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('quickComm.audioHelpTitle'),
                  style: textTheme.titleMedium.copyWith(
                    color: colors.textPrimary,
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
                  style: textTheme.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                _buildHelpItem(
                  context: context,
                  icon: Icons.volume_up_rounded,
                  title: context.tr('quickComm.audioHelpVolumeTitle'),
                  subtitle: context.tr('quickComm.audioHelpVolumeDesc'),
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  context: context,
                  icon: Icons.notifications_active_rounded,
                  title: context.tr('quickComm.audioHelpRingerTitle'),
                  subtitle: context.tr('quickComm.audioHelpRingerDesc'),
                ),
                const SizedBox(height: 12),
                _buildHelpItem(
                  context: context,
                  icon: Icons.language_rounded,
                  title: context.tr('quickComm.audioHelpVoiceTitle'),
                  subtitle: context.tr('quickComm.audioHelpVoiceDesc'),
                  trailing: Obx(() {
                    final isReady = controller.isArabicVoiceAvailable.value;
                    return Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isReady
                            ? colors.success.withValues(alpha: 0.1)
                            : colors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isReady
                              ? colors.success.withValues(alpha: 0.35)
                              : colors.accent.withValues(alpha: 0.35),
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
                                color: isReady ? colors.success : colors.accent,
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
                                        ? colors.success
                                        : colors.textPrimary,
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
                                backgroundColor: colors.accent,
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
                                  color: colors.accentText,
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
                style: TextStyle(
                  color: colors.accent,
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    final colors = context.hc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textMuted,
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
    final colors = context.hc;
    final textTheme = context.text;

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
            color: colors.surface,
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
                  color: colors.border,
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
                      Icon(
                        Icons.visibility_rounded,
                        color: colors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('quickComm.showLocals').isNotEmpty
                            ? context.tr('quickComm.showLocals')
                            : 'Tunjukkan ke Warga / Petugas',
                        style: textTheme.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textPrimary),
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
                      ? colors.danger.withValues(alpha: 0.08)
                      : colors.surfaceSand,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: phrase.isUrgent
                        ? colors.danger.withValues(alpha: 0.6)
                        : colors.accent.withValues(alpha: 0.4),
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
                          style: textTheme.labelSmall.copyWith(
                            color: colors.danger,
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
                        fontFamily: 'Amiri',
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
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
                        color: colors.textMuted,
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
                        color: colors.textPrimary,
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
                              ? colors.danger
                              : (isPlaying ? colors.primary : colors.accent),
                          foregroundColor: Colors.white,
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
                      backgroundColor: colors.surfaceSand,
                      foregroundColor: colors.textPrimary,
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
    final colors = context.hc;
    final textTheme = context.text;
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
        color: colors.surface,
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
                      color: colors.border,
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
                      color: colors.surfaceSand,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      color: colors.accentText,
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
                            style: textTheme.titleLarge.copyWith(
                              color: colors.textPrimary,
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
                          style: textTheme.bodySmall.copyWith(
                            color: colors.textMuted,
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
                      color: colors.accentText,
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
                    icon: Icon(Icons.close_rounded, color: colors.textMuted),
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
                  color: colors.surfaceSand,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      color: colors.accent,
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
                          color: colors.textPrimary,
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
                    color: colors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.download_for_offline_rounded,
                        color: colors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('quickComm.voiceDownloadPrompt'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
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
                          backgroundColor: colors.accent,
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
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: context.tr('quickComm.searchHint').isNotEmpty
                        ? context.tr('quickComm.searchHint')
                        : 'Cari percakapan (dokter, arah, sakit...)',
                    hintStyle: TextStyle(fontSize: 12, color: colors.textMuted),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: colors.accent,
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
                      context: context,
                      categoryKey: cat.key,
                      label: label,
                      count: count,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 6),
            Divider(height: 1, color: colors.border),

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
                  color: colors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: colors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.volume_off_rounded,
                      color: colors.danger,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('quickComm.ttsError').isNotEmpty
                            ? context.tr('quickComm.ttsError')
                            : 'Audio belum bersuara. Pastikan volume media aktif atau unduh paket suara Arab di HP.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.danger,
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
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.danger,
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
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.danger,
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
                              color: colors.border,
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
                                color: colors.textMuted,
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
    required BuildContext context,
    required String categoryKey,
    required String label,
    required int count,
  }) {
    final colors = context.hc;
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
          color: isSelected ? colors.primary : colors.surfaceSand,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: isSelected ? colors.accent : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.onPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.onPrimary.withValues(alpha: 0.2)
                    : colors.textMuted.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colors.onPrimary : colors.textMuted,
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
  }) {
    final colors = context.hc;
    final textTheme = context.text;

    return Obx(() {
      final isCurrentlyPlaying = controller.activePhrase.value == phrase.arabic;

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: phrase.isUrgent
              ? colors.danger.withValues(alpha: 0.08)
              : (isCurrentlyPlaying
                    ? colors.accent.withValues(alpha: 0.15)
                    : colors.surface),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isCurrentlyPlaying
                ? colors.accent
                : (phrase.isUrgent
                      ? colors.danger.withValues(alpha: 0.45)
                      : colors.border),
            width: isCurrentlyPlaying ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCurrentlyPlaying
                  ? colors.accent.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
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
                        color: colors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: colors.danger.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        context.tr('quickComm.urgentBadge').isNotEmpty
                            ? context.tr('quickComm.urgentBadge')
                            : 'PENTING / DARURAT',
                        style: textTheme.labelSmall.copyWith(
                          color: colors.danger,
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
                        color: colors.accentText,
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
                        color: colors.textMuted,
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
                              color: colors.textPrimary,
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
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Latin Transliteration
                      Text(
                        phrase.transliteration,
                        style: TextStyle(
                          color: colors.textMuted,
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
                            ? colors.danger
                            : (isCurrentlyPlaying
                                  ? colors.primary
                                  : colors.surfaceSand),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrentlyPlaying
                              ? colors.accent
                              : colors.border,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (phrase.isUrgent
                                        ? colors.danger
                                        : colors.accent)
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
                            ? Colors.white
                            : colors.accentText,
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
