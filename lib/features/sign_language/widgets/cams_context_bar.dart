import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../services/cams_canonical_frames.dart';
import '../controllers/cams_translation_controller.dart';

/// Top Context Bar with 2 interactive pill chips side-by-side:
/// 1) Lokasi Haji (auto-filled from GPS or 1-tap select from 8 Hajj locations)
/// 2) Lawan Bicara (1-tap select from 6 interlocutor roles)
class CamsContextBar extends StatelessWidget {
  final CamsTranslationController controller;

  const CamsContextBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loc = controller.selectedLocation.value;
      final isGps = controller.isAutoGpsDetected.value;
      final role = controller.selectedRole.value;
      final isEn =
          AppLocalizations.of(context).locale.languageCode.toLowerCase() ==
          'en';

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Row(
          children: [
            Expanded(
              child: _ContextPillChip(
                icon: Icons.location_on_rounded,
                label: isEn ? loc.shortEn : loc.shortId,
                badgeText: isGps ? context.tr('sign.cams.gpsBadge') : null,
                isActive: loc != CamsLocation.unknown,
                onTap: () => _showLocationPicker(context, isEn),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ContextPillChip(
                icon: Icons.person_pin_rounded,
                label: isEn ? role.shortEn : role.shortId,
                isActive: role != CamsInterlocutorRole.unknown,
                onTap: () => _showRolePicker(context, isEn),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showLocationPicker(BuildContext context, bool isEn) {
    HapticFeedback.selectionClick();
    final isDark = AppColors.isDark(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBgColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineColor(ctx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Text(
                    ctx.tr('sign.cams.selectLocationTitle'),
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textHeadingColor(ctx),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: CamsLocation.values.length,
                    itemBuilder: (_, idx) {
                      final item = CamsLocation.values[idx];
                      final isSelected =
                          controller.selectedLocation.value == item;
                      final accent = isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark;
                      return ListTile(
                        minVerticalPadding: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        selected: isSelected,
                        selectedTileColor: accent.withValues(alpha: 0.12),
                        leading: Icon(
                          item == CamsLocation.unknown
                              ? Icons.public_rounded
                              : Icons.place_rounded,
                          color: isSelected
                              ? accent
                              : AppColors.textSecondaryColor(ctx),
                        ),
                        title: Text(
                          isEn ? item.labelEn : item.labelId,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textHeadingColor(ctx),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: accent)
                            : null,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          controller.setLocation(item, fromGps: false);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRolePicker(BuildContext context, bool isEn) {
    HapticFeedback.selectionClick();
    final isDark = AppColors.isDark(context);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBgColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.68,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.outlineColor(ctx),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Text(
                    ctx.tr('sign.cams.selectRoleTitle'),
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textHeadingColor(ctx),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    itemCount: CamsInterlocutorRole.values.length,
                    itemBuilder: (_, idx) {
                      final item = CamsInterlocutorRole.values[idx];
                      final isSelected = controller.selectedRole.value == item;
                      final accent = isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark;
                      return ListTile(
                        minVerticalPadding: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        selected: isSelected,
                        selectedTileColor: accent.withValues(alpha: 0.12),
                        leading: Icon(
                          _roleIcon(item),
                          color: isSelected
                              ? accent
                              : AppColors.textSecondaryColor(ctx),
                        ),
                        title: Text(
                          isEn ? item.labelEn : item.labelId,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textHeadingColor(ctx),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: accent)
                            : null,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          controller.setRole(item);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _roleIcon(CamsInterlocutorRole role) {
    switch (role) {
      case CamsInterlocutorRole.dokterKlinikSaudi:
        return Icons.medical_services_rounded;
      case CamsInterlocutorRole.petugasMedisTkhi:
        return Icons.health_and_safety_rounded;
      case CamsInterlocutorRole.asykarKeamananSaudi:
        return Icons.shield_rounded;
      case CamsInterlocutorRole.pembimbingManasikMutawwif:
        return Icons.menu_book_rounded;
      case CamsInterlocutorRole.petugasLayananJamaah:
        return Icons.apartment_rounded;
      case CamsInterlocutorRole.petugasTransportasiHaji:
        return Icons.directions_bus_rounded;
      case CamsInterlocutorRole.unknown:
        return Icons.people_outline_rounded;
    }
  }
}

class _ContextPillChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badgeText;
  final bool isActive;
  final VoidCallback onTap;

  const _ContextPillChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final accent = isDark ? AppColors.goldLight : AppColors.espressoDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                      ? AppColors.darkPrimaryContainer.withValues(alpha: 0.75)
                      : AppColors.primaryContainer)
                : AppColors.cardBgColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive
                  ? accent.withValues(alpha: 0.6)
                  : AppColors.cardBorderColor(context),
              width: isActive ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textHeadingColor(context),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldIslamic.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText!,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.emeraldIslamic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.textSecondaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
