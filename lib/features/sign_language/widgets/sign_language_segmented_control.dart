import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';

/// Segmented control pill untuk memilih bahasa isyarat aktif (SIBI vs BISINDO).
class SignLanguageSegmentedControl extends StatelessWidget {
  final TextToSignController controller;

  const SignLanguageSegmentedControl({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;

    return Obx(() {
      final active = controller.selectedLanguage.value;

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceSand,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentItem(
                context: context,
                label: context.tr('sign.sibiTabTitle'),
                subtitle: context.tr('sign.sibiTabSub'),
                isActive: active == 'sibi',
                onTap: () {
                  if (active != 'sibi') {
                    HapticFeedback.selectionClick();
                    controller.setLanguage('sibi');
                  }
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildSegmentItem(
                context: context,
                label: context.tr('sign.bisindoTabTitle'),
                subtitle: context.tr('sign.bisindoTabSub'),
                isActive: active == 'bisindo',
                onTap: () {
                  if (active != 'bisindo') {
                    HapticFeedback.selectionClick();
                    controller.setLanguage('bisindo');
                  }
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSegmentItem({
    required BuildContext context,
    required String label,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colors = context.hc;
    final textTheme = context.text;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: isActive
                ? Border.all(color: colors.border.withValues(alpha: 0.8))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.bodySmall.copyWith(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? colors.primary : colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.labelSmall.copyWith(
                  fontSize: 10,
                  color: isActive ? colors.accentText : colors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
