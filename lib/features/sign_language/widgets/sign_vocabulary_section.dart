import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';
import '../models/sign_video_entry.dart';

/// Bagian daftar kosakata bahasa isyarat yang dipaginasikan (maks 5 video per halaman)
/// dengan kontrol navigasi halaman dan indikator sumber offline/cloud.
class SignVocabularySection extends StatelessWidget {
  final TextToSignController controller;
  final VoidCallback? onItemTapped;
  final VoidCallback? onPageChanged;

  const SignVocabularySection({
    super.key,
    required this.controller,
    this.onItemTapped,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Bar: Judul + Badge Jumlah Video + Refresh Button ─────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  context.tr('sign.vocabListTitle'),
                  style: textTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Obx(() {
                  final queryActive = controller.currentQuery.value
                      .trim()
                      .isNotEmpty;
                  final filteredCount = controller.filteredVocabulary.length;
                  final totalCount = controller.availableVideos.length;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      queryActive
                          ? context.tr('sign.vocabCountFiltered', {
                              'filtered': '$filteredCount',
                              'total': '$totalCount',
                            })
                          : context.tr('sign.vocabCountTotal', {
                              'total': '$totalCount',
                            }),
                      style: textTheme.labelSmall.copyWith(
                        color: colors.accentText,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                }),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: context.tr('sign.refreshList'),
              color: colors.textSecondary,
              onPressed: () {
                HapticFeedback.lightImpact();
                controller.loadAvailableVideos(forceRefresh: true);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // ── Konten Kosakata / Paginasi ──────────────────────────────────────
        Obx(() {
          if (controller.isLoadingVideos.value) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(color: colors.accent),
              ),
            );
          }

          final allVideos = controller.availableVideos;
          if (allVideos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  context.tr('sign.noVideosAvailable'),
                  style: textTheme.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
            );
          }

          final filteredList = controller.filteredVocabulary;
          if (filteredList.isEmpty) {
            final query = controller.currentQuery.value.trim();
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl,
                  horizontal: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 40,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      context.tr('sign.noVocabMatch', {'query': query}),
                      style: textTheme.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        controller.clearSearch();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        context.tr('sign.showAllVocab'),
                        style: textTheme.labelMedium,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final paginatedVideos = controller.paginatedVocabulary;
          final totalPages = controller.totalVocabPages;
          final currentPage = controller.currentVocabPage.value.clamp(
            1,
            totalPages,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListView.separated(
                key: ValueKey(
                  'vocab_list_p_${currentPage}_${controller.currentQuery.value}',
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paginatedVideos.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final video = paginatedVideos[index];
                  return _buildVocabularyTile(
                    context,
                    video,
                    key: ValueKey('vocab_item_${video.id}'),
                  );
                },
              ),
              if (totalPages > 1) ...[
                const SizedBox(height: AppSpacing.md),
                _buildPaginationFooter(
                  context: context,
                  totalPages: totalPages,
                  currentPage: currentPage,
                ),
              ],
            ],
          );
        }),
      ],
    );
  }

  // ── Tile Kosakata ──────────────────────────────────────────────────────────
  Widget _buildVocabularyTile(
    BuildContext context,
    SignVideoEntry video, {
    Key? key,
  }) {
    final colors = context.hc;
    final textTheme = context.text;

    return Obx(key: key, () {
      final isSelected = controller.currentEntry.value?.id == video.id;

      return Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            controller.selectVocabularyItem(video);
            onItemTapped?.call();
          },
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isSelected ? colors.accent : colors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.accent.withValues(alpha: 0.2)
                        : colors.surfaceSand,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.play_arrow_rounded
                        : Icons.videocam_rounded,
                    color: isSelected ? colors.accent : colors.primary,
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
                        style: textTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colors.accent
                              : colors.textPrimary,
                        ),
                      ),
                      Text(
                        context.tr('sign.category', {
                          'category': video.category.toUpperCase(),
                          'type': video.type.toUpperCase(),
                        }),
                        style: textTheme.labelSmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSourcePill(context, video.source),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ── Source Pill (Asset, Local, Cloud) ──────────────────────────────────────
  Widget _buildSourcePill(BuildContext context, SignVideoSource source) {
    final colors = context.hc;
    final textTheme = context.text;
    Color bg;
    Color fg;
    String text;

    switch (source) {
      case SignVideoSource.asset:
        bg = colors.success.withValues(alpha: 0.15);
        fg = colors.success;
        text = context.tr('sign.sourceAsset');
        break;
      case SignVideoSource.localCached:
        bg = colors.success.withValues(alpha: 0.15);
        fg = colors.success;
        text = context.tr('sign.sourceLocalCached');
        break;
      case SignVideoSource.remote:
        bg = colors.accent.withValues(alpha: 0.15);
        fg = colors.accentText;
        text = context.tr('sign.sourceRemote');
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
        style: textTheme.labelSmall.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  // ── Kontrol Navigasi Paginasi ──────────────────────────────────────────────
  Widget _buildPaginationFooter({
    required BuildContext context,
    required int totalPages,
    required int currentPage,
  }) {
    final colors = context.hc;
    final textTheme = context.text;
    final canGoPrev = currentPage > 1;
    final canGoNext = currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: canGoPrev
                ? () {
                    HapticFeedback.lightImpact();
                    controller.previousVocabPage();
                    onPageChanged?.call();
                  }
                : null,
            tooltip: context.tr('sign.prevPage'),
            color: colors.textPrimary,
            disabledColor: colors.textTertiary.withValues(alpha: 0.3),
          ),
          Flexible(
            child: Text(
              context.tr('sign.pageOf', {
                'current': '$currentPage',
                'total': '$totalPages',
              }),
              style: textTheme.labelMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: canGoNext
                ? () {
                    HapticFeedback.lightImpact();
                    controller.nextVocabPage();
                    onPageChanged?.call();
                  }
                : null,
            tooltip: context.tr('sign.nextPage'),
            color: colors.textPrimary,
            disabledColor: colors.textTertiary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
