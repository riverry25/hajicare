import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';
import '../widgets/sign_cache_options_sheet.dart';
import '../widgets/sign_candidates_bar.dart';
import '../widgets/sign_language_segmented_control.dart';
import '../widgets/sign_offline_packages_section.dart';
import '../widgets/sign_quick_phrase_chips.dart';
import '../widgets/sign_search_voice_bar.dart';
import '../widgets/sign_speech_card.dart';
import '../widgets/sign_video_player.dart';
import '../widgets/sign_vocabulary_section.dart';

/// Halaman fitur Text and Speech to Sign Language (SIBI & BISINDO).
/// Menerjemahkan input teks dan ucapan suara jamaah ke peragaan video bahasa isyarat
/// dengan dukungan hybrid offline bundled assets dan persistent remote caching.
class TextToSignScreen extends StatefulWidget {
  const TextToSignScreen({super.key});

  @override
  State<TextToSignScreen> createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends State<TextToSignScreen> {
  late final TextToSignController controller;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _videoPlayerKey = GlobalKey();
  final GlobalKey _vocabSectionKey = GlobalKey();
  Worker? _searchResultWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<TextToSignController>()
        ? Get.find<TextToSignController>()
        : Get.put(TextToSignController());

    _searchResultWorker = ever(controller.searchResult, (result) {
      if (result != null && result.isFound && result.exactMatch != null) {
        _scrollToVideoPlayer();
      }
    });
  }

  @override
  void dispose() {
    _searchResultWorker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToVideoPlayer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_videoPlayerKey.currentContext != null) {
        Scrollable.ensureVisible(
          _videoPlayerKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: 0.05,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _scrollToVocabularySection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_vocabSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _vocabSectionKey.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          alignment: 0.05,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.record_voice_over_rounded,
                color: colors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('sign.textAndVoiceToSign'),
                    style: textTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    context.tr('sign.videoTranslatorSub'),
                    style: textTheme.labelSmall.copyWith(
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: context.tr('sign.manageDownloads'),
            color: colors.textPrimary,
            onPressed: () => SignCacheOptionsSheet.show(context, controller),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. SEGMENTED LANGUAGE SELECTOR (SIBI vs BISINDO) ─────────────
            SignLanguageSegmentedControl(controller: controller),
            const SizedBox(height: AppSpacing.md),

            // ── 2. TEXT SEARCH & VOICE INPUT BAR (DENGAN AUTOCOMPLETE) ───────
            SignSearchVoiceBar(controller: controller),
            const SizedBox(height: AppSpacing.sm),

            // ── 3. QUICK PHRASE CHIPS ────────────────────────────────────────
            SignQuickPhraseChips(controller: controller),
            const SizedBox(height: AppSpacing.md),

            // ── 4. ERROR BANNER (JIKA ADA KENDALA) ───────────────────────────
            Obx(() {
              final err = controller.errorMessage.value;
              if (err == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
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
                      Icons.error_outline_rounded,
                      color: colors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        err,
                        style: textTheme.bodySmall.copyWith(
                          color: colors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // ── 5. PEMUTAR VIDEO BAHASA ISYARAT ──────────────────────────────
            SignVideoPlayerWidget(key: _videoPlayerKey, controller: controller),

            // ── 5.1 MULTI-CANDIDATES SELECTOR (JIKA LEBIH DARI 1 KATA) ───────
            SignCandidatesBar(controller: controller),
            const SizedBox(height: AppSpacing.lg),

            // ── 6. SPEECH TO SIGN HERO SECTION (VOICE RECOGNITION) ───────────
            SignSpeechCard(controller: controller),
            const SizedBox(height: AppSpacing.xl),

            // ── 7. PAKET UNDUHAN OFFLINE KATEGORI ────────────────────────────
            SignOfflinePackagesSection(controller: controller),
            const SizedBox(height: AppSpacing.xl),

            // ── 8. DAFTAR KOSAKATA TERSEDIA & PAGINASI (5 ITEM / HAL) ────────
            Container(
              key: _vocabSectionKey,
              child: SignVocabularySection(
                controller: controller,
                onItemTapped: _scrollToVideoPlayer,
                onPageChanged: _scrollToVocabularySection,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
