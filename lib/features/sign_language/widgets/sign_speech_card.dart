import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';

/// Kartu integrasi Speech-to-Sign Language dengan umpan balik visual dan audio haptik.
class SignSpeechCard extends StatefulWidget {
  final TextToSignController controller;

  const SignSpeechCard({super.key, required this.controller});

  @override
  State<SignSpeechCard> createState() => _SignSpeechCardState();
}

class _SignSpeechCardState extends State<SignSpeechCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Obx(() {
      final isListening = widget.controller.isListening.value;
      final recognized = widget.controller.recognizedWords.value;
      final activeText = widget.controller.textController.text.trim();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: isListening
              ? colors.surface
              : colors.surfaceSand.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isListening
                ? colors.danger.withValues(alpha: 0.5)
                : colors.border,
            width: isListening ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isListening
                  ? colors.danger.withValues(alpha: 0.08)
                  : colors.shadow.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isListening
                        ? colors.danger.withValues(alpha: 0.15)
                        : colors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isListening
                        ? Icons.graphic_eq_rounded
                        : Icons.record_voice_over_rounded,
                    size: 20,
                    color: isListening ? colors.danger : colors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('sign.voiceToSignTitle'),
                        style: textTheme.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('sign.voiceToSignSub'),
                        style: textTheme.labelSmall.copyWith(
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isListening)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'REC',
                          style: textTheme.labelSmall.copyWith(
                            color: colors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Mic Centerpiece with Tactile Animation
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.controller.toggleVoiceRecognition();
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated halo when active
                  if (isListening)
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.danger.withValues(alpha: 0.18),
                          border: Border.all(
                            color: colors.danger.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceSand,
                      ),
                    ),

                  // Main Button Circle
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isListening
                            ? [
                                colors.danger,
                                colors.danger.withValues(alpha: 0.85),
                              ]
                            : [colors.accent, colors.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isListening
                              ? colors.danger.withValues(alpha: 0.35)
                              : colors.shadow.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Real-Time Transcript or Idle Prompt Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isListening
                    ? colors.danger.withValues(alpha: 0.08)
                    : colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isListening
                      ? colors.danger.withValues(alpha: 0.3)
                      : colors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isListening)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.danger,
                        ),
                      ),
                    ),
                  Flexible(
                    child: Text(
                      isListening
                          ? (recognized.isEmpty
                                ? context.tr('sign.listeningPrompt')
                                : context.tr('sign.heardWords', {
                                    'words': recognized,
                                  }))
                          : (activeText.isNotEmpty
                                ? context.tr('sign.activeWord', {
                                    'word': activeText,
                                  })
                                : context.tr('sign.tapBigMicHint')),
                      style: textTheme.labelSmall.copyWith(
                        color: isListening ? colors.danger : colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons when Listening (Finish)
            if (isListening) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 38,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    widget.controller.stopVoiceRecognition();
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    context.tr('sign.finishListening'),
                    style: textTheme.labelMedium.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
