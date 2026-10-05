import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/text_to_sign_controller.dart';
import '../models/sign_video_entry.dart';

/// Widget pemutar video bahasa isyarat yang responsif dan ramah aksesibilitas.
class SignVideoPlayerWidget extends StatelessWidget {
  final TextToSignController controller;

  const SignVideoPlayerWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Obx(() {
      final entry = controller.currentEntry.value;

      // ── 1. KONDISI BELUM ADA VIDEO DIPILIH ─────────────────────────────────
      if (entry == null) {
        return _buildEmptyPlaceholder(context, isDark);
      }

      // ── 2. KONDISI VIDEO REMOTE PERLU DIUNDUH ──────────────────────────────
      if (entry.source == SignVideoSource.remote) {
        return _buildRemoteDownloadCard(context, entry, isDark);
      }

      // ── 3. KONDISI VIDEO SEDANG MEMUAT / INITIALIZING ──────────────────────
      if (!controller.isVideoInitialized.value) {
        return _buildLoadingCard(context, entry, isDark);
      }

      // ── 4. KONDISI PEMUTAR AKTIF (ASSET / LOCAL CACHED) ────────────────────
      return _buildActivePlayerCard(context, entry, isDark);
    });
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────────────

  Widget _buildEmptyPlaceholder(BuildContext context, bool isDark) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.canvasCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sign_language_rounded,
              size: 36,
              color: isDark ? AppColors.goldLight : AppColors.goldPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Ketik Kalimat atau Pilih Kata',
            style: AppTypography.titleMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Penerjemah akan menampilkan video peragaan bahasa isyarat SIBI atau BISINDO secara nyata.',
            style: AppTypography.bodySmall.copyWith(color: bodyColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── REMOTE DOWNLOAD REQUIRED CARD ──────────────────────────────────────────

  Widget _buildRemoteDownloadCard(
    BuildContext context,
    SignVideoEntry entry,
    bool isDark,
  ) {
    final headingColor = AppColors.textHeadingColor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          // Header info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_download_rounded,
                  color: AppColors.goldPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.label,
                      style: AppTypography.titleLarge.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Video berada di cloud (${entry.category.toUpperCase()})',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSourceBadge(entry.source),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Download Progress / Button
          Obx(() {
            final isDownloading = controller.isDownloading.value;
            final progress = controller.downloadProgress.value;

            if (isDownloading) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.goldPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Mengunduh video ${(progress * 100).toInt()}%...',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.goldPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }

            return SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => controller.downloadAndPlay(entry),
                icon: const Icon(Icons.download_rounded),
                label: const Text('Unduh Video untuk Offline'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── LOADING CARD ───────────────────────────────────────────────────────────

  Widget _buildLoadingCard(
    BuildContext context,
    SignVideoEntry entry,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.goldPrimary),
            SizedBox(height: AppSpacing.md),
            Text('Menyiapkan pemutar video...'),
          ],
        ),
      ),
    );
  }

  // ── ACTIVE PLAYER CARD ─────────────────────────────────────────────────────

  Widget _buildActivePlayerCard(
    BuildContext context,
    SignVideoEntry entry,
    bool isDark,
  ) {
    final player = controller.playerController;
    if (player == null || !player.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final headingColor = AppColors.textHeadingColor(context);
    final isPlaying = controller.isVideoPlaying.value;
    final position = controller.videoPosition.value;
    final duration = controller.videoDuration.value;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Video Canvas with Tap-to-Play ──────────────────────────────────
          GestureDetector(
            onTap: controller.togglePlayPause,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: player.value.aspectRatio > 0
                      ? player.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(player),
                ),

                // Center Play/Pause button overlay (fades or visible when paused)
                if (!isPlaying)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ),

          // ── Scrubber & Bottom Controls ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                // Scrubber Bar
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: AppColors.goldPrimary,
                    inactiveTrackColor: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.outlineVariant,
                    thumbColor: AppColors.goldPrimary,
                  ),
                  child: Slider(
                    value: position.inMilliseconds
                        .clamp(0, duration.inMilliseconds)
                        .toDouble(),
                    min: 0.0,
                    max: duration.inMilliseconds > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (val) {
                      controller.seekTo(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),

                // Action controls row
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: headingColor,
                        size: 28,
                      ),
                      onPressed: controller.togglePlayPause,
                      tooltip: isPlaying ? 'Jeda' : 'Putar',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.replay_rounded,
                        color: headingColor,
                        size: 22,
                      ),
                      onPressed: controller.replay,
                      tooltip: 'Ulangi Video',
                    ),
                    const Spacer(),

                    // Duration display (e.g. 00:02 / 00:05)
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Video Meta & Offline Status Footer ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bahasa: ${entry.language.toUpperCase()} • Kategori: ${entry.category.toUpperCase()}',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildSourceBadge(entry.source),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BADGE STATUS ───────────────────────────────────────────────────────────

  Widget _buildSourceBadge(SignVideoSource source) {
    Color bg;
    Color fg;
    IconData icon;

    switch (source) {
      case SignVideoSource.asset:
        bg = AppColors.statusSafe.withValues(alpha: 0.15);
        fg = AppColors.statusSafe;
        icon = Icons.offline_pin_rounded;
        break;
      case SignVideoSource.localCached:
        bg = AppColors.statusSafe.withValues(alpha: 0.15);
        fg = AppColors.statusSafe;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SignVideoSource.remote:
        bg = AppColors.goldPrimary.withValues(alpha: 0.15);
        fg = AppColors.goldPrimary;
        icon = Icons.cloud_download_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            source.displayName,
            style: AppTypography.captionSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
