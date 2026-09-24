import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../models/hajj_dua.dart';
import '../../services/hajj_dua_service.dart';
import '../hajj_dua_typography.dart';
import 'dua_text_sections.dart';

class DuaCard extends StatefulWidget {
  final HajjDua dua;
  final bool initiallyExpanded;

  const DuaCard({super.key, required this.dua, this.initiallyExpanded = false});

  @override
  State<DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<DuaCard> {
  late final HajjDuaService _service;

  @override
  void initState() {
    super.initState();
    _service = HajjDuaService.instance;
  }

  String _resolveTitle(BuildContext context) {
    final translated = context.tr(widget.dua.titleKey);
    if (translated != widget.dua.titleKey) return translated;
    return widget.dua.title ?? translated;
  }

  Future<void> _copyDua(BuildContext context) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final localizedTitle = _resolveTitle(context);
    await Clipboard.setData(
      ClipboardData(
        text: widget.dua.toClipboardText(
          localizedTitle: localizedTitle,
          meaningLabel: context.tr('hajjDuaMeaning'),
          languageCode: languageCode,
          sourceLabel: context.tr('hajjDuaSource'),
        ),
      ),
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.tr('hajjDuaCopied', {'title': localizedTitle}),
            style: HajjDuaTypography.body.copyWith(color: Colors.white),
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accentColor = isDark ? AppColors.goldLight : AppColors.goldDark;
    final languageCode = Localizations.localeOf(context).languageCode;
    final localizedTranslation = widget.dua.translationFor(languageCode);
    final title = _resolveTitle(context);

    return Obx(() {
      final isSaved = _service.isBookmarked(widget.dua.id);
      final textScale = _service.textScaleMultiplier.value;

      return AppCard(
        padding: EdgeInsets.zero,
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (expanded) {
            if (expanded) {
              _service.recordDuaOpened(widget.dua.id);
            }
          },
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          iconColor: accentColor,
          collapsedIconColor: AppColors.textSecondaryColor(context),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.dua.activity != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          widget.dua.activity!,
                          style: HajjDuaTypography.metadataLabel.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                    Text(
                      title,
                      style: HajjDuaTypography.cardTitle.copyWith(
                        color: AppColors.textHeadingColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSaved)
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.goldPrimary,
                  size: 20,
                ),
            ],
          ),
          subtitle: widget.dua.subtitleKey == null && widget.dua.subtitle == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    widget.dua.subtitle ?? context.tr(widget.dua.subtitleKey!),
                    style: HajjDuaTypography.caption.copyWith(
                      color: AppColors.textBodyColor(context),
                    ),
                  ),
                ),
          children: [
            const Divider(),
            if (widget.dua.contextText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _ContextBox(contextText: widget.dua.contextText!),
            ],
            const SizedBox(height: AppSpacing.md),
            ArabicDuaText(
              key: Key('arabic_${widget.dua.id}'),
              text: widget.dua.arabic,
              scale: textScale,
            ),
            if (widget.dua.transliteration?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.lg),
              TransliterationText(
                key: Key('transliteration_${widget.dua.id}'),
                text: widget.dua.transliteration!,
                scale: textScale,
              ),
            ],
            if (localizedTranslation?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: AppSpacing.lg),
              TranslationText(
                key: Key('translation_${widget.dua.id}'),
                text: localizedTranslation!,
                scale: textScale,
              ),
            ],
            if (widget.dua.descriptionKey != null || widget.dua.description != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _PlainInformation(
                title: context.tr('hajjDuaInformation'),
                message: widget.dua.description ?? context.tr(widget.dua.descriptionKey!),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Audio Section
            _AudioPlayerSection(dua: widget.dua, service: _service),
            const SizedBox(height: AppSpacing.md),
            // Source & Verification Section
            if (widget.dua.requiresSourceVerification) ...[
              _VerificationNotice(
                title: context.tr('hajjDuaVerificationRequired'),
                message: widget.dua.notesKey == null
                    ? context.tr('hajjDuaSourceUnknown')
                    : context.tr(widget.dua.notesKey!),
              ),
            ] else if (widget.dua.source?.trim().isNotEmpty ?? false) ...[
              _SourceCard(
                sourceTitle: widget.dua.source!,
                reference: widget.dua.sourceReference,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // Action Buttons (Simpan & Salin)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copyDua(context),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(
                    context.tr('hajjDuaCopy'),
                    style: HajjDuaTypography.button,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _service.toggleBookmark(widget.dua.id),
                  icon: Icon(
                    isSaved ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSaved ? AppColors.goldPrimary : AppColors.textBodyColor(context),
                    size: 20,
                  ),
                  tooltip: isSaved
                      ? context.tr('hajjDuaSavedAction')
                      : context.tr('hajjDuaSaveAction'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ContextBox extends StatelessWidget {
  final String contextText;

  const _ContextBox({required this.contextText});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bgColor = isDark
        ? AppColors.darkSurfaceContainer
        : AppColors.goldPrimary.withValues(alpha: 0.08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.access_time_rounded,
            size: 17,
            color: AppColors.goldPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('hajjDuaWhenToRead'),
                  style: HajjDuaTypography.metadataLabel.copyWith(
                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contextText,
                  style: HajjDuaTypography.body.copyWith(
                    fontSize: 13,
                    color: AppColors.textBodyColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioPlayerSection extends StatelessWidget {
  final HajjDua dua;
  final HajjDuaService service;

  const _AudioPlayerSection({required this.dua, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final hasAudio = dua.audioPath != null && dua.audioPath!.trim().isNotEmpty;

    if (!hasAudio) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.outlineColor(context).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.volume_off_rounded,
              color: AppColors.textSecondaryColor(context),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr('hajjDuaAudioUnavailable'),
              style: HajjDuaTypography.caption.copyWith(
                color: AppColors.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return Obx(() {
      final isCurrent = service.currentlyPlayingId.value == dua.id;
      final isPlaying = isCurrent && service.isAudioPlaying.value;

      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            IconButton.filled(
              onPressed: () => service.playOrPauseAudio(
                duaId: dua.id,
                audioPath: dua.audioPath,
              ),
              icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPlaying
                        ? context.tr('hajjDuaAudioPause')
                        : context.tr('hajjDuaAudioPlay'),
                    style: HajjDuaTypography.button.copyWith(
                      color: AppColors.textHeadingColor(context),
                    ),
                  ),
                  if (isCurrent && service.totalDuration.value > Duration.zero)
                    LinearProgressIndicator(
                      value: service.currentPosition.value.inMilliseconds /
                          service.totalDuration.value.inMilliseconds,
                      backgroundColor: AppColors.outlineColor(context),
                      color: AppColors.goldPrimary,
                    ),
                ],
              ),
            ),
            if (isCurrent)
              IconButton(
                onPressed: () => service.replayAudio(
                  duaId: dua.id,
                  audioPath: dua.audioPath,
                ),
                icon: const Icon(Icons.replay_rounded, size: 20),
                tooltip: context.tr('hajjDuaAudioReplay'),
              ),
          ],
        ),
      );
    });
  }
}

class _SourceCard extends StatelessWidget {
  final String sourceTitle;
  final String? reference;

  const _SourceCard({required this.sourceTitle, this.reference});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineColor(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 16,
                color: AppColors.goldPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('hajjDuaSource'),
                style: HajjDuaTypography.metadataLabel.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sourceTitle,
            style: HajjDuaTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppColors.textHeadingColor(context),
            ),
          ),
          if (reference != null && reference!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              reference!,
              style: HajjDuaTypography.caption.copyWith(
                color: AppColors.textBodyColor(context),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlainInformation extends StatelessWidget {
  final String title;
  final String message;

  const _PlainInformation({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: HajjDuaTypography.metadataLabel.copyWith(
            color: AppColors.textSecondaryColor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          style: HajjDuaTypography.body.copyWith(
            color: AppColors.textBodyColor(context),
          ),
        ),
      ],
    );
  }
}

class _VerificationNotice extends StatelessWidget {
  final String title;
  final String message;

  const _VerificationNotice({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    const color = AppColors.distanceWarning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppColors.isDark(context) ? 0.13 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fact_check_outlined, color: color, size: 21),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: HajjDuaTypography.cardTitle.copyWith(
                    color: AppColors.textHeadingColor(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: HajjDuaTypography.caption.copyWith(
                    color: AppColors.textBodyColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
