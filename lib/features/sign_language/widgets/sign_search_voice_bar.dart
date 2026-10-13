import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';

/// Bilah pencarian teks dan pemicu input suara dengan auto-suggest dropdown.
class SignSearchVoiceBar extends StatelessWidget {
  final TextToSignController controller;

  const SignSearchVoiceBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Input Field Container ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.translate_rounded, color: colors.accent, size: 22),
              const SizedBox(width: AppSpacing.sm),

              // Search Text Field
              Expanded(
                child: Obx(() {
                  final lang = controller.selectedLanguage.value;
                  final hintText = lang == 'sibi'
                      ? context.tr('sign.searchHintSibi')
                      : context.tr('sign.searchHintBisindo');

                  return TextField(
                    controller: controller.textController,
                    focusNode: controller.searchFocusNode,
                    cursorColor: colors.accent,
                    style: textTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintStyle: textTheme.bodySmall.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      controller.dismissSuggestions();
                      controller.searchSign(val);
                    },
                    onChanged: (val) => controller.updateSearchQuery(val),
                  );
                }),
              ),

              // Action Buttons Row (Clear, Mic, Search)
              Obx(() {
                final isListening = controller.isListening.value;
                final isSearching = controller.isSearching.value;
                final hasText = controller.currentQuery.value.isNotEmpty;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clear Input Button
                    if (hasText)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: colors.textTertiary,
                        tooltip: context.tr('sign.clearSearchText'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          controller.clearSearch();
                        },
                      ),

                    // Microphone Toggle Button
                    Tooltip(
                      message: isListening
                          ? context.tr('sign.listeningTapFinish')
                          : context.tr('sign.speakVoiceToSign'),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            controller.toggleVoiceRecognition();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isListening
                                  ? colors.danger.withValues(alpha: 0.15)
                                  : colors.surfaceSand,
                              border: isListening
                                  ? Border.all(color: colors.danger, width: 1.5)
                                  : null,
                            ),
                            child: Icon(
                              isListening
                                  ? Icons.mic_rounded
                                  : Icons.mic_none_rounded,
                              size: 20,
                              color: isListening
                                  ? colors.danger
                                  : colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Search Submit Button
                    if (isSearching)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.accent,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search_rounded),
                        color: colors.accent,
                        tooltip: context.tr('sign.searchSignVideo'),
                        onPressed: () {
                          controller.dismissSuggestions();
                          controller.searchFocusNode.unfocus();
                          controller.searchSign(
                            controller.textController.text,
                            force: true,
                          );
                        },
                      ),
                  ],
                );
              }),
            ],
          ),
        ),

        // ── Autocomplete Suggestions Popover ───────────────────────────────
        _buildAutocompleteDropdown(context),
      ],
    );
  }

  Widget _buildAutocompleteDropdown(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Obx(() {
      if (!controller.showSuggestions.value ||
          controller.searchSuggestions.isEmpty) {
        return const SizedBox.shrink();
      }

      final suggestions = controller.searchSuggestions;
      final query = controller.currentQuery.value.trim();

      return Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: colors.accent.withValues(alpha: 0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Suggestion Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: colors.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('sign.vocabSuggestions'),
                      style: textTheme.labelSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.accentText,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: controller.dismissSuggestions,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),

            // Suggestions List
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
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.selectSuggestion(text);
                      },
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
                                color: colors.accent.withValues(alpha: 0.12),
                              ),
                              child: Icon(
                                Icons.sign_language_rounded,
                                size: 16,
                                color: colors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildHighlightedText(
                                context: context,
                                text: text,
                                query: query,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surfaceSand,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                controller.selectedLanguage.value == 'sibi'
                                    ? 'SIBI'
                                    : 'BISINDO',
                                style: textTheme.labelSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.north_west_rounded,
                              size: 15,
                              color: colors.textTertiary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, indent: 46, color: colors.border),
                ],
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildHighlightedText({
    required BuildContext context,
    required String text,
    required String query,
  }) {
    final colors = context.hc;
    final textTheme = context.text;

    if (query.isEmpty) {
      return Text(
        text,
        style: textTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerText.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        text,
        style: textTheme.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      );
    }

    final beforeMatch = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + query.length);
    final afterMatch = text.substring(matchIndex + query.length);

    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium.copyWith(color: colors.textPrimary),
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
              color: colors.accent,
              backgroundColor: colors.accent.withValues(alpha: 0.15),
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
}
