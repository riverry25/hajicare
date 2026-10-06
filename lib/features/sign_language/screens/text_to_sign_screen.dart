import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/text_to_sign_controller.dart';
import '../models/sign_video_entry.dart';
import '../widgets/sign_video_player.dart';

/// Halaman fitur Text-to-Sign Language (SIBI & BISINDO).
/// Menerjemahkan input teks jamaah ke peragaan video bahasa isyarat
/// dengan dukungan hybrid offline bundled assets dan persistent remote caching.
class TextToSignScreen extends StatefulWidget {
  const TextToSignScreen({super.key});

  @override
  State<TextToSignScreen> createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends State<TextToSignScreen>
    with SingleTickerProviderStateMixin {
  late final TextToSignController controller;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<TextToSignController>()
        ? Get.find<TextToSignController>()
        : Get.put(TextToSignController());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showCacheOptionsDialog(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Pengaturan Unduhan Video',
              style: AppTypography.titleMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kelola video cloud yang tersimpan di perangkat Anda. Video bawaan aplikasi tidak akan terhapus.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sync_rounded,
                  color: AppColors.goldPrimary,
                ),
              ),
              title: Text(
                'Perbarui Katalog Cloud',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                ),
              ),
              subtitle: const Text(
                'Sinkronkan daftar video terbaru dari server',
              ),
              onTap: () {
                Get.back();
                controller.loadAvailableVideos(forceRefresh: true);
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sosEmergency.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppColors.sosEmergency,
                ),
              ),
              title: Text(
                'Hapus Video Unduhan',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.sosEmergency,
                ),
              ),
              subtitle: const Text(
                'Bersihkan ruang memori (video bawaan tetap aman)',
              ),
              onTap: () {
                Get.back();
                controller.clearDownloadedVideos();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teks ke Isyarat',
              style: AppTypography.titleLarge.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Penerjemah Video SIBI & BISINDO',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Kelola Unduhan',
            onPressed: () => _showCacheOptionsDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. SEGMENTED LANGUAGE SELECTOR (SIBI vs BISINDO) ─────────────
            _buildLanguageSelector(context, isDark),
            const SizedBox(height: AppSpacing.md),

            // ── 2. TEXT SEARCH / INPUT CARD ──────────────────────────────────
            _buildSearchInputCard(context, isDark),

            // ── 2.1 AUTOCOMPLETE SUGGESTIONS (JIKA ADA MATCH) ────────────────
            _buildSearchSuggestions(context, isDark),

            // ── 2.2 BANNER STATUS MIKROFON (JIKA MIC AKTIF) ──────────────────
            _buildActiveListeningBanner(context, isDark),
            const SizedBox(height: AppSpacing.sm),

            // ── 3. QUICK PHRASE CHIPS ────────────────────────────────────────
            _buildQuickPhraseChips(context, isDark),
            const SizedBox(height: AppSpacing.lg),

            // ── 4. ERROR BANNER (JIKA ADA) ───────────────────────────────────
            Obx(() {
              final err = controller.errorMessage.value;
              if (err == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.sosEmergency.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.sosEmergency.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.sosEmergency,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        err,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── 5. MAIN VIDEO PLAYER AREA ────────────────────────────────────
            SignVideoPlayerWidget(controller: controller),
            const SizedBox(height: AppSpacing.xl),

            // ── FITUR UTAMA: SUARA KE BAHASA ISYARAT (SPEECH TO SIGN) ────────
            _buildSpeechToSignSection(context, isDark, headingColor),
            const SizedBox(height: AppSpacing.xl),

            // ── 6. PAKET UNDUHAN OFFLINE (DOWNLOAD PACKAGES) ─────────────────
            _buildOfflinePackagesSection(context, isDark, headingColor),
            const SizedBox(height: AppSpacing.xl),

            // ── 7. DAFTAR KOSAKATA TERSEDIA ──────────────────────────────────
            _buildAvailableVocabularySection(
              context,
              isDark,
              headingColor,
              bodyColor,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  // ── 1. LANGUAGE SELECTOR ───────────────────────────────────────────────────

  Widget _buildLanguageSelector(BuildContext context, bool isDark) {
    return Obx(() {
      final active = controller.selectedLanguage.value;

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.canvasCream,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildLanguageTabItem(
                label: 'SIBI (Bahasa Isyarat)',
                subtitle: 'Kata & Kalimat',
                isActive: active == 'sibi',
                onTap: () => controller.setLanguage('sibi'),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _buildLanguageTabItem(
                label: 'BISINDO (Isyarat Alami)',
                subtitle: 'Alfabet & Isyarat',
                isActive: active == 'bisindo',
                onTap: () => controller.setLanguage('bisindo'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLanguageTabItem({
    required String label,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.surfaceWhite)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive
                    ? (isDark ? AppColors.goldLight : AppColors.espressoDark)
                    : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: AppTypography.captionSmall.copyWith(
                fontSize: 10,
                color: isActive
                    ? (isDark
                          ? AppColors.goldLight.withValues(alpha: 0.7)
                          : AppColors.espressoDark.withValues(alpha: 0.6))
                    : AppColors.textMuted.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. SEARCH INPUT CARD ───────────────────────────────────────────────────

  Widget _buildSearchInputCard(BuildContext context, bool isDark) {
    return AppCard(
      borderColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.translate_rounded,
            color: isDark ? AppColors.goldLight : AppColors.goldPrimary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller.textController,
              focusNode: controller.searchFocusNode,
              decoration: InputDecoration(
                hintText: controller.selectedLanguage.value == 'sibi'
                    ? 'Ketik kata misal: Masjid, Bantu, Dokter...'
                    : 'Ketik huruf misal: J atau L...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (val) {
                controller.dismissSuggestions();
                controller.searchSign(val);
              },
              onChanged: (val) => controller.updateSearchQuery(val),
            ),
          ),
          Obx(() {
            final isListening = controller.isListening.value;
            final isSearching = controller.isSearching.value;
            final hasText = controller.currentQuery.value.isNotEmpty;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol clear input (X) jika terdapat teks
                if (hasText)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: AppColors.textMuted,
                    tooltip: 'Hapus Teks',
                    onPressed: () => controller.clearSearch(),
                  ),

                // Tombol Mikrofon (Speech-to-Sign)
                Tooltip(
                  message: isListening
                      ? 'Sedang Mendengarkan (Ketuk untuk Selesai)'
                      : 'Bicara (Suara ke Isyarat)',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () => controller.toggleVoiceRecognition(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? AppColors.sosEmergency.withValues(alpha: 0.18)
                              : (isDark
                                    ? AppColors.goldLight.withValues(alpha: 0.1)
                                    : AppColors.goldPrimary.withValues(
                                        alpha: 0.1,
                                      )),
                          border: isListening
                              ? Border.all(
                                  color: AppColors.sosEmergency,
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Icon(
                          isListening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          size: 20,
                          color: isListening
                              ? AppColors.sosEmergency
                              : (isDark
                                    ? AppColors.goldLight
                                    : AppColors.goldPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Tombol Pencarian (Search Button berdampingan dengan mic)
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.goldPrimary,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    color: isDark ? AppColors.goldLight : AppColors.goldPrimary,
                    tooltip: 'Cari Video Isyarat',
                    onPressed: () {
                      controller.dismissSuggestions();
                      controller.searchSign(controller.textController.text);
                    },
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── 2.1 SEARCH AUTOCOMPLETE SUGGESTIONS ────────────────────────────────────

  Widget _buildSearchSuggestions(BuildContext context, bool isDark) {
    return Obx(() {
      if (!controller.showSuggestions.value ||
          controller.searchSuggestions.isEmpty) {
        return const SizedBox.shrink();
      }

      final suggestions = controller.searchSuggestions;
      final query = controller.currentQuery.value.trim();

      return Container(
        margin: const EdgeInsets.only(top: 4, bottom: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark
                ? AppColors.goldLight.withValues(alpha: 0.3)
                : AppColors.goldPrimary.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header bar saran
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppColors.goldPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saran Kosakata Isyarat',
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.goldDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => controller.dismissSuggestions(),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),

            // Daftar item saran
            ...suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final text = entry.value;
              final isLast = index == suggestions.length - 1;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: isLast
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(AppRadius.card),
                            )
                          : BorderRadius.zero,
                      onTap: () => controller.selectSuggestion(text),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    (isDark
                                            ? AppColors.goldLight
                                            : AppColors.goldPrimary)
                                        .withValues(alpha: 0.12),
                              ),
                              child: Icon(
                                Icons.sign_language_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.goldLight
                                    : AppColors.goldPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildHighlightedText(
                                text: text,
                                query: query,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkSurfaceContainer
                                    : AppColors.canvasCream,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                controller.selectedLanguage.value == 'sibi'
                                    ? 'SIBI'
                                    : 'BISINDO',
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.north_west_rounded,
                              size: 15,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 46),
                ],
              );
            }),
          ],
        ),
      );
    });
  }

  /// Memformat teks saran dengan highlighting pada potongan kata yang cocok dengan query.
  Widget _buildHighlightedText({
    required String text,
    required String query,
    required bool isDark,
  }) {
    final textColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;

    if (query.isEmpty) {
      return Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        text,
        style: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      );
    }

    final beforeMatch = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + query.length);
    final afterMatch = text.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        style: AppTypography.bodyMedium.copyWith(color: textColor),
        children: [
          if (beforeMatch.isNotEmpty)
            TextSpan(
              text: beforeMatch,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          TextSpan(
            text: match,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.goldLight : AppColors.goldPrimary,
              backgroundColor:
                  (isDark ? AppColors.goldLight : AppColors.goldPrimary)
                      .withValues(alpha: 0.15),
            ),
          ),
          if (afterMatch.isNotEmpty)
            TextSpan(
              text: afterMatch,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  // ── 2.2 ACTIVE LISTENING BANNER ────────────────────────────────────────────

  Widget _buildActiveListeningBanner(BuildContext context, bool isDark) {
    return Obx(() {
      if (!controller.isListening.value) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.sosEmergency.withValues(alpha: 0.18)
              : AppColors.sosEmergency.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.sosEmergency.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sosEmergency,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.speechStatusMessage.value,
                    style: AppTypography.captionSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.sosEmergency,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ucapkan kata, input akan otomatis terisi...',
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => controller.stopVoiceRecognition(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sosEmergency,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                'Selesai',
                style: AppTypography.captionSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 3. QUICK PHRASE CHIPS ──────────────────────────────────────────────────

  Widget _buildQuickPhraseChips(BuildContext context, bool isDark) {
    return Obx(() {
      final lang = controller.selectedLanguage.value;
      final List<String> suggestions = lang == 'sibi'
          ? ['Masjid', 'Bantu', 'Dokter', 'Obat', 'Tolong bantu saya']
          : ['J', 'L'];

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: suggestions.map((text) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(text),
                backgroundColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.canvasCream,
                labelStyle: AppTypography.captionSmall.copyWith(
                  color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder,
                  ),
                ),
                onPressed: () {
                  controller.textController.text = text;
                  controller.searchSign(text);
                },
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ── 5.5 SPEECH TO SIGN LANGUAGE HERO SECTION (MIC BESAR) ───────────────────

  Widget _buildSpeechToSignSection(
    BuildContext context,
    bool isDark,
    Color headingColor,
  ) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      borderColor: isDark
          ? AppColors.goldLight.withValues(alpha: 0.25)
          : AppColors.goldPrimary.withValues(alpha: 0.35),
      backgroundColor: isDark
          ? AppColors.darkSurfaceContainer
          : AppColors.canvasCreamSubtle.withValues(alpha: 0.6),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  size: 20,
                  color: AppColors.goldPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suara ke Bahasa Isyarat',
                      style: AppTypography.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ucapkan kata untuk memutar gerakan isyarat otomatis',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Big Mic Button with Pulse Animation
          Obx(() {
            final isListening = controller.isListening.value;

            return Column(
              children: [
                GestureDetector(
                  onTap: () => controller.toggleVoiceRecognition(),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated pulse ring when listening
                      if (isListening)
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.sosEmergency.withValues(
                                alpha: 0.2,
                              ),
                              border: Border.all(
                                color: AppColors.sosEmergency.withValues(
                                  alpha: 0.5,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.goldPrimary.withValues(
                              alpha: 0.12,
                            ),
                          ),
                        ),

                      // Main Mic Circle
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isListening
                                ? [
                                    AppColors.sosEmergency,
                                    Colors.redAccent.shade700,
                                  ]
                                : [AppColors.goldLight, AppColors.goldPrimary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isListening
                                  ? AppColors.sosEmergency.withValues(
                                      alpha: 0.4,
                                    )
                                  : AppColors.goldPrimary.withValues(
                                      alpha: 0.35,
                                    ),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          isListening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          size: 34,
                          color: isListening
                              ? Colors.white
                              : AppColors.espressoDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Speech Status & Live Recognized Words Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isListening
                        ? AppColors.sosEmergency.withValues(alpha: 0.1)
                        : (isDark
                              ? AppColors.darkSurfaceContainerHigh
                              : AppColors.surfaceWhite),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isListening
                          ? AppColors.sosEmergency.withValues(alpha: 0.3)
                          : (isDark
                                ? AppColors.darkOutlineVariant
                                : AppColors.cardBorderColor(context)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isListening)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.sosEmergency,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          isListening
                              ? (controller.recognizedWords.value.isEmpty
                                    ? 'Mendengarkan... Silakan bicara'
                                    : 'Mendengar: "${controller.recognizedWords.value}"')
                              : (controller.textController.text
                                        .trim()
                                        .isNotEmpty
                                    ? 'Kata aktif: "${controller.textController.text}"'
                                    : 'Ketuk mikrofon besar untuk mulai bicara'),
                          style: AppTypography.captionSmall.copyWith(
                            color: isListening
                                ? AppColors.sosEmergency
                                : (isDark
                                      ? AppColors.goldLight
                                      : AppColors.espressoDark),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── 6. OFFLINE PACKAGES SECTION ────────────────────────────────────────────

  Widget _buildOfflinePackagesSection(
    BuildContext context,
    bool isDark,
    Color headingColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.downloading_rounded,
              size: 20,
              color: AppColors.goldPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              'Unduh Paket Offline HajiCare',
              style: AppTypography.titleMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Simpan seluruh video per kategori sekaligus agar siap digunakan di Tanah Suci tanpa internet.',
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Obx(() {
          final lang = controller.selectedLanguage.value;
          if (lang == 'sibi') {
            return Row(
              children: [
                Expanded(
                  child: _buildPackageCard(
                    context: context,
                    title: 'Paket Kesehatan',
                    subtitle: 'Dokter, Obat',
                    category: 'health',
                    icon: Icons.local_hospital_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildPackageCard(
                    context: context,
                    title: 'Paket Ibadah',
                    subtitle: 'Masjid, Doa',
                    category: 'hajj',
                    icon: Icons.mosque_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: _buildPackageCard(
                    context: context,
                    title: 'Paket Alfabet',
                    subtitle: 'Huruf J, L',
                    category: 'alphabet',
                    icon: Icons.spellcheck_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            );
          }
        }),
      ],
    );
  }

  Widget _buildPackageCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String category,
    required IconData icon,
    required bool isDark,
  }) {
    final headingColor = AppColors.textHeadingColor(context);

    return Obx(() {
      final isDownloading = controller.categoryDownloading[category] == true;
      final progress = controller.categoryDownloadProgress[category] ?? 0.0;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.canvasCream,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDark ? AppColors.goldLight : AppColors.goldPrimary,
                  ),
                ),
                if (isDownloading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.goldPrimary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: headingColor,
              ),
            ),
            Text(
              subtitle,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: isDownloading
                    ? null
                    : () => controller.downloadCategoryPackage(category),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isDownloading
                      ? '${(progress * 100).toInt()}%'
                      : 'Unduh Paket',
                  style: AppTypography.captionSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── 7. AVAILABLE VOCABULARY SECTION ────────────────────────────────────────

  Widget _buildAvailableVocabularySection(
    BuildContext context,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Daftar Kosakata',
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${controller.availableVideos.length} Video',
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.goldPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Perbarui Daftar',
              onPressed: () =>
                  controller.loadAvailableVideos(forceRefresh: true),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        Obx(() {
          if (controller.isLoadingVideos.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(color: AppColors.goldPrimary),
              ),
            );
          }

          final allVideos = controller.availableVideos;
          if (allVideos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Belum ada video tersedia.',
                  style: AppTypography.bodySmall.copyWith(color: bodyColor),
                ),
              ),
            );
          }

          final paginatedVideos = controller.paginatedVocabulary;
          final totalPages = controller.totalVocabPages;
          final currentPage = controller.currentVocabPage.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paginatedVideos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final video = paginatedVideos[index];
                  return _buildVocabularyTile(
                    context,
                    video,
                    isDark,
                    headingColor,
                  );
                },
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.cardBorderColor(context),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: currentPage > 1
                            ? () => controller.previousVocabPage()
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded, size: 18),
                        label: const Text(
                          'Sebelumnya',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          foregroundColor: isDark
                              ? AppColors.goldLight
                              : AppColors.espressoDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      Text(
                        'Hal $currentPage dari $totalPages',
                        style: AppTypography.captionSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: currentPage < totalPages
                            ? () => controller.nextVocabPage()
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded, size: 18),
                        label: const Text(
                          'Selanjutnya',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.goldPrimary,
                          foregroundColor: AppColors.espressoDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _buildVocabularyTile(
    BuildContext context,
    SignVideoEntry video,
    bool isDark,
    Color headingColor,
  ) {
    final isSelected = controller.currentEntry.value?.id == video.id;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {
        controller.textController.text = video.label;
        controller.playEntry(video);
      },
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.goldPrimary.withValues(alpha: 0.2)
                  : (isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.canvasCream),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelected ? Icons.play_arrow_rounded : Icons.videocam_rounded,
              color: isSelected
                  ? AppColors.goldPrimary
                  : (isDark ? AppColors.goldLight : AppColors.espressoDark),
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.label,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.goldPrimary : headingColor,
                  ),
                ),
                Text(
                  'Kategori: ${video.category.toUpperCase()} • Tipe: ${video.type.toUpperCase()}',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _buildSourcePill(video.source),
        ],
      ),
    );
  }

  Widget _buildSourcePill(SignVideoSource source) {
    Color bg;
    Color fg;
    String text;

    switch (source) {
      case SignVideoSource.asset:
        bg = AppColors.statusSafe.withValues(alpha: 0.15);
        fg = AppColors.statusSafe;
        text = 'Offline';
        break;
      case SignVideoSource.localCached:
        bg = AppColors.statusSafe.withValues(alpha: 0.15);
        fg = AppColors.statusSafe;
        text = 'Tersimpan';
        break;
      case SignVideoSource.remote:
        bg = AppColors.goldPrimary.withValues(alpha: 0.15);
        fg = AppColors.goldPrimary;
        text = 'Unduh';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTypography.captionSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
