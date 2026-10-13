import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';

/// Bilah pemilih kandidat ketika sebuah kalimat/kata memiliki lebih dari 1 kecocokan gerakan isyarat.
class SignCandidatesBar extends StatelessWidget {
  final TextToSignController controller;

  const SignCandidatesBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Obx(() {
      final result = controller.searchResult.value;
      if (result == null || result.candidates.length <= 1) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.only(top: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.segment_rounded, size: 16, color: colors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr('sign.selectCandidateToPlay'),
                    style: textTheme.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.candidates.map((candidate) {
                final isPlayingThis =
                    controller.currentEntry.value?.id == candidate.id;

                return ChoiceChip(
                  label: Text(candidate.label),
                  selected: isPlayingThis,
                  selectedColor: colors.accent,
                  backgroundColor: colors.surfaceSand,
                  labelStyle: textTheme.labelSmall.copyWith(
                    color: isPlayingThis
                        ? colors.onPrimary
                        : colors.textPrimary,
                    fontWeight: isPlayingThis
                        ? FontWeight.bold
                        : FontWeight.w500,
                  ),
                  onSelected: (_) {
                    HapticFeedback.lightImpact();
                    controller.playEntry(candidate);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      );
    });
  }
}
