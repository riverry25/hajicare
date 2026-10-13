import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/app_settings_controller.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

class JamaahProfileHeader extends StatelessWidget {
  final HajiCareState state;

  const JamaahProfileHeader({super.key, required this.state});

  void _showTextSizeSheet(BuildContext context) {
    final settings = Get.find<AppSettingsController>();
    final hc = context.hc;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: hc.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
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
                    color: hc.borderSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.tr('selectTextSizeTitle'),
                style: context.text.titleLarge.copyWith(
                  color: hc.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...AppTextScale.values.map((scale) {
                return Obx(() {
                  final isSelected = settings.rxTextScale.value == scale;
                  return InkWell(
                    onTap: () {
                      settings.setTextScale(scale);
                      Get.back();
                    },
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: hc.borderSubtle.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected ? hc.brand : hc.textTertiary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                scale.localizedLabel(context),
                                style: context.text.bodyMedium.copyWith(
                                  color: hc.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(scale.factor * 100).toStringAsFixed(0)}%',
                            style: context.text.labelSmall.copyWith(
                              color: hc.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                });
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Obx(() {
      final jamaah = state.self;
      final userName = jamaah.name;
      final effectiveKloter =
          (jamaah.kloter != null && jamaah.kloter!.isNotEmpty)
          ? jamaah.kloter
          : state.activeRoom.value?.kloter;
      final effectiveMaktab =
          (jamaah.maktab != null && jamaah.maktab!.isNotEmpty)
          ? jamaah.maktab
          : state.activeRoom.value?.maktab;
      final kloterLabel = context.tr('kloterLabelShort');
      final maktabLabel = context.tr('maktabLabelShort');
      final kloterText =
          (effectiveKloter != null && effectiveKloter.trim().isNotEmpty)
          ? (effectiveKloter.trim().toLowerCase().startsWith('kloter')
                ? effectiveKloter.trim()
                : '$kloterLabel ${effectiveKloter.trim()}')
          : '';
      final maktabText =
          (effectiveMaktab != null && effectiveMaktab.trim().isNotEmpty)
          ? (effectiveMaktab.trim().toLowerCase().startsWith('maktab')
                ? effectiveMaktab.trim()
                : '$maktabLabel ${effectiveMaktab.trim()}')
          : '';

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hc.sandLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hc.sandDark.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(Icons.account_circle, color: hc.brand, size: 36),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: context.text.titleLarge.copyWith(
                                color: hc.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.verified, color: hc.success, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (kloterText.isNotEmpty && maktabText.isNotEmpty)
                        Text(
                          '$kloterText • $maktabText',
                          style: context.text.bodySmall.copyWith(
                            color: hc.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (kloterText.isNotEmpty || maktabText.isNotEmpty)
                        Text(
                          kloterText.isNotEmpty ? kloterText : maktabText,
                          style: context.text.bodySmall.copyWith(
                            color: hc.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (state.activeRoom.value != null &&
                          state.activeRoom.value!.name.isNotEmpty)
                        Text(
                          state.activeRoom.value!.name,
                          style: context.text.bodySmall.copyWith(
                            color: hc.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.format_size, color: hc.textPrimary),
                  onPressed: () => _showTextSizeSheet(context),
                  tooltip: context.tr('changeTextSize'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: hc.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: hc.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  AnimatedPingDot(color: hc.success, size: 10),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: context.tr('connectedWith'),
                        style: context.text.bodySmall.copyWith(
                          color: hc.textPrimary,
                        ),
                        children: [
                          TextSpan(
                            text: state.pendampingName.value,
                            style: context.text.labelSmall.copyWith(
                              color: hc.brand,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AppStatusBadge(
                    label: context.tr('activeStatus'),
                    statusType: AppStatusType.safe,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
