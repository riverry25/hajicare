import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';
import '../models/sign_video_entry.dart';

/// Widget pemutar video bahasa isyarat yang responsif dan ramah aksesibilitas.
class SignVideoPlayerWidget extends StatelessWidget {
  final TextToSignController controller;

  const SignVideoPlayerWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entry = controller.currentEntry.value;

      // 1. KONDISI BELUM ADA VIDEO DIPILIH
      if (entry == null) {
        return _buildEmptyPlaceholder(context);
      }

      // 2. KONDISI VIDEO REMOTE PERLU DIUNDUH
      if (entry.source == SignVideoSource.remote) {
        return _buildRemoteDownloadCard(context, entry);
      }

      // 2.1 JIKA LOCAL CACHED TAPI FILE TIDAK ADA DI DISK (MISAL DIHAPUS DARI CACHE
      if (entry.source == SignVideoSource.localCached) {
        final cachedPath = entry.cachedFilePath;
        if (cachedPath == null || !File(cachedPath).existsSync()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            controller.refreshCurrentEntrySource();
          });
          return _buildRemoteDownloadCard(
            context,
            entry.copyWith(
              source: SignVideoSource.remote,
              cachedFilePath: null,
            ),
          );
        }
      }

      // 2.2 KONDISI TERJADI ERROR SAAT MEMUAT VIDEO
      if (controller.errorMessage.value != null &&
          !controller.isVideoInitialized.value) {
        return _buildErrorCard(context, entry);
      }

      // 3. KONDISI VIDEO SEDANG MEMUAT / INITIALIZING
      if (!controller.isVideoInitialized.value) {
        return _buildLoadingCard(context, entry);
      }

      // 4. KONDISI PEMUTAR AKTIF (ASSET / LOCAL CACHED
      return _buildActivePlayerCard(context, entry);
    });
  }

  // EMPTY STATE

  Widget _buildEmptyPlaceholder(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.surfaceSand,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sign_language_rounded,
              size: 36,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('sign.emptyPlayerTitle'),
            style: textTheme.titleMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('sign.emptyPlayerSub'),
            style: textTheme.bodySmall.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // REMOTE DOWNLOAD REQUIRED CARD

  Widget _buildRemoteDownloadCard(BuildContext context, SignVideoEntry entry) {
    final colors = context.hc;
    final textTheme = context.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Header info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_download_rounded,
                  color: colors.accent,
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
                      style: textTheme.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('sign.videoInCloud', {
                        'category': entry.category.toUpperCase(),
                      }),
                      style: textTheme.labelSmall.copyWith(
                        color: colors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _buildSourceBadge(context, entry.source),
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
                      backgroundColor: colors.surfaceSand,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.tr('sign.downloadingProgress', {
                      'percent': '${(progress * 100).toInt()}',
                    }),
                    style: textTheme.bodySmall.copyWith(
                      color: colors.accent,
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
                label: Text(
                  context.tr('sign.downloadVideoForOffline'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
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

  // ERROR CARD

  Widget _buildErrorCard(BuildContext context, SignVideoEntry entry) {
    final colors = context.hc;
    final textTheme = context.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.danger.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: colors.danger,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('sign.emptyPlayerTitle'),
            style: textTheme.titleSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            controller.errorMessage.value ?? '',
            style: textTheme.bodySmall.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () => controller.playEntry(entry, force: true),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.tr('sign.retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // LOADING CARD

  Widget _buildLoadingCard(BuildContext context, SignVideoEntry entry) {
    final colors = context.hc;
    final textTheme = context.text;

    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.accent),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.tr('sign.preparingVideoPlayer'),
              style: textTheme.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ACTIVE PLAYER CARD

  Widget _buildActivePlayerCard(BuildContext context, SignVideoEntry entry) {
    final player = controller.playerController;
    if (player == null || !player.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final colors = context.hc;
    final textTheme = context.text;
    final isPlaying = controller.isVideoPlaying.value;
    final position = controller.videoPosition.value;
    final duration = controller.videoDuration.value;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),
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
          // Video Canvas with Tap-to-Play
          GestureDetector(
            onTap: controller.togglePlayPause,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: player.value.aspectRatio > 0
                      ? player.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(
                    player,
                    key: ValueKey(
                      'sign_video_${entry.id}_${player.dataSource}',
                    ),
                  ),
                ),

                // Center Play/Pause button overlay (fades or visible when paused
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

                // Floating Speed Indicator Overlay (Top Right of video
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Obx(() {
                    final show = controller.showSpeedOverlay.value;
                    final text = controller.speedOverlayText.value;
                    final speed = controller.playbackSpeed.value;
                    final isCustom = speed != 1.0;

                    return AnimatedOpacity(
                      opacity: show ? 1.0 : (isCustom ? 0.85 : 0.0),
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !show && !isCustom,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: isCustom
                                  ? colors.accent.withValues(alpha: 0.85)
                                  : Colors.white24,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.speed_rounded,
                                size: 13,
                                color: isCustom
                                    ? colors.accent
                                    : Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                text.isNotEmpty
                                    ? text
                                    : (speed == speed.toInt()
                                          ? '${speed.toInt()}.0x'
                                          : '${speed}x'),
                                style: textTheme.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Scrubber & Bottom Controls
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
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: colors.accent,
                    inactiveTrackColor: colors.border,
                    thumbColor: colors.accent,
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

                // Action controls row (Play, Replay, Speed Capsule, Duration
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: colors.textPrimary,
                        size: 28,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        controller.togglePlayPause();
                      },
                      tooltip: isPlaying
                          ? context.tr('sign.pause')
                          : context.tr('sign.play'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.replay_rounded,
                        color: colors.textPrimary,
                        size: 22,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        controller.replay();
                      },
                      tooltip: context.tr('sign.replay'),
                    ),

                    const Spacer(),

                    // Speed Controller Capsule (Slow Down, Speed, Speed Up
                    _buildSpeedCapsule(context),

                    const Spacer(),

                    // Duration display (e.g. 00:02 / 00:05
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      style: textTheme.labelSmall.copyWith(
                        color: colors.textMuted,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colors.border),

          // Video Meta & Offline Status Footer
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
                        style: textTheme.titleMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('sign.langCategoryMeta', {
                          'lang': entry.language.toUpperCase(),
                          'category': entry.category.toUpperCase(),
                        }),
                        style: textTheme.labelSmall.copyWith(
                          color: colors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _buildSourceBadge(context, entry.source),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // BADGE STATUS

  Widget _buildSourceBadge(BuildContext context, SignVideoSource source) {
    final colors = context.hc;
    final textTheme = context.text;
    Color bg;
    Color fg;
    IconData icon;

    switch (source) {
      case SignVideoSource.asset:
        bg = colors.success.withValues(alpha: 0.15);
        fg = colors.success;
        icon = Icons.offline_pin_rounded;
        break;
      case SignVideoSource.localCached:
        bg = colors.success.withValues(alpha: 0.15);
        fg = colors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SignVideoSource.remote:
        bg = colors.accent.withValues(alpha: 0.15);
        fg = colors.accent;
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
          Flexible(
            child: Text(
              _localizedSource(context, source),
              style: textTheme.labelSmall.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _localizedSource(BuildContext context, SignVideoSource source) {
    switch (source) {
      case SignVideoSource.asset:
        return context.tr('sign.sourceAsset');
      case SignVideoSource.localCached:
        return context.tr('sign.sourceLocalCached');
      case SignVideoSource.remote:
        return context.tr('sign.sourceRemote');
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // SPEED CONTROLS

  Widget _buildSpeedCapsule(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Obx(() {
      final currentSpeed = controller.playbackSpeed.value;
      final isCustomSpeed = currentSpeed != 1.0;
      final canSlow = controller.canSlowDown;
      final canFast = controller.canSpeedUp;
      final speedLabel = currentSpeed == currentSpeed.toInt()
          ? '${currentSpeed.toInt()}.0x'
          : '${currentSpeed}x';

      return Container(
        decoration: BoxDecoration(
          color: isCustomSpeed
              ? colors.accent.withValues(alpha: 0.12)
              : colors.surfaceSand,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isCustomSpeed
                ? colors.accent.withValues(alpha: 0.5)
                : colors.border,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Slow down button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: canSlow
                    ? () {
                        HapticFeedback.lightImpact();
                        controller.slowDown();
                      }
                    : null,
                child: Tooltip(
                  message: context.tr('sign.slowDown'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 6,
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      size: 16,
                      color: canSlow
                          ? colors.textPrimary
                          : colors.textTertiary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),

            // Speed Display & Sheet Trigger (e.g. ⚡ 1.0x
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showSpeedSelectorSheet(context);
                },
                child: Tooltip(
                  message: context.tr('sign.playbackSpeed'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 15,
                          color: isCustomSpeed
                              ? colors.accent
                              : colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          speedLabel,
                          style: textTheme.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isCustomSpeed
                                ? colors.accentText
                                : colors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Speed up button (+
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                onTap: canFast
                    ? () {
                        HapticFeedback.lightImpact();
                        controller.speedUp();
                      }
                    : null,
                child: Tooltip(
                  message: context.tr('sign.speedUp'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 6,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: canFast
                          ? colors.textPrimary
                          : colors.textTertiary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showSpeedSelectorSheet(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    final speeds = TextToSignController.supportedPlaybackSpeeds;

    final speedMetadata = <double, Map<String, dynamic>>{
      0.5: {
        'title': '0.5x',
        'badge': context.tr('sign.speedVerySlow'),
        'desc': 'Sangat lambat, amati posisi & lekuk jari secara teliti',
        'icon': Icons.slow_motion_video_rounded,
      },
      0.75: {
        'title': '0.75x',
        'badge': context.tr('sign.speedSlow'),
        'desc': 'Lambat, kecepatan ideal bagi pemula untuk menirukan gerakan',
        'icon': Icons.slow_motion_video_rounded,
      },
      1.0: {
        'title': '1.0x',
        'badge': context.tr('sign.speedNormal'),
        'desc': 'Kecepatan alami bahasa isyarat sehari-hari',
        'icon': Icons.play_circle_outline_rounded,
      },
      1.25: {
        'title': '1.25x',
        'badge': context.tr('sign.speedFast'),
        'desc': 'Sedikit lebih cepat untuk latihan kelancaran pemahaman',
        'icon': Icons.fast_forward_rounded,
      },
      1.5: {
        'title': '1.5x',
        'badge': context.tr('sign.speedVeryFast'),
        'desc': 'Cepat, efektif untuk pengulangan kosakata yang sudah dihafal',
        'icon': Icons.fast_forward_rounded,
      },
      2.0: {
        'title': '2.0x',
        'badge': context.tr('sign.speedUltraFast'),
        'desc': 'Sangat cepat untuk pratinjau kilat',
        'icon': Icons.fast_forward_rounded,
      },
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
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
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.speed_rounded,
                        color: colors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ctx.tr('sign.playbackSpeed'),
                            style: textTheme.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ctx.tr('sign.playbackSpeedDesc'),
                            style: textTheme.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: colors.border),
                const SizedBox(height: AppSpacing.sm),

                // Options list
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: speeds.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final speed = speeds[index];
                      final info = speedMetadata[speed]!;

                      return Obx(() {
                        final isSelected =
                            controller.playbackSpeed.value == speed;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              controller.setPlaybackSpeed(speed);
                              Navigator.pop(ctx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.accent.withValues(alpha: 0.12)
                                    : colors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? colors.accent
                                      : colors.border.withValues(alpha: 0.5),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    info['icon'] as IconData,
                                    size: 20,
                                    color: isSelected
                                        ? colors.accent
                                        : colors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              info['title'] as String,
                                              style: textTheme.titleSmall
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? colors.accentText
                                                        : colors.textPrimary,
                                                  ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? colors.accent.withValues(
                                                        alpha: 0.2,
                                                      )
                                                    : colors.surfaceSand,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      AppRadius.pill,
                                                    ),
                                              ),
                                              child: Text(
                                                info['badge'] as String,
                                                style: textTheme.labelSmall
                                                    .copyWith(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isSelected
                                                          ? colors.accentText
                                                          : colors
                                                                .textSecondary,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          info['desc'] as String,
                                          style: textTheme.bodySmall.copyWith(
                                            color: colors.textTertiary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: colors.accent,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }
}
