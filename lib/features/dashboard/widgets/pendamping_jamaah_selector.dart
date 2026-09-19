import 'package:flutter/material.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../room/widgets/jamaah_detail_sheet.dart';

class PendampingJamaahSelector extends StatelessWidget {
  final HajiCareState state;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  const PendampingJamaahSelector({
    super.key,
    required this.state,
    this.selectedIndex = 0,
    this.onSelected,
  });

  String _localizedTierLabel(BuildContext context, DistanceTier tier) {
    switch (tier) {
      case DistanceTier.aman:
        return context.tr('statusSafe');
      case DistanceTier.waspada:
        return context.tr('statusWarning');
      case DistanceTier.terlalujJauh:
        return context.tr('statusDanger');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);

    final jamaahList = state.jamaahList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('monitoredPilgrims'),
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.goldLight.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: isDark
                          ? AppColors.goldPrimary.withValues(alpha: 0.3)
                          : AppColors.goldPrimary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${jamaahList.length} Jamaah',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.statusSafe.withValues(
                  alpha: isDark ? 0.15 : 0.1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.statusSafe.withValues(
                    alpha: isDark ? 0.35 : 0.25,
                  ),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.statusSafe,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.statusSafe.withValues(alpha: 0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Radar Terhubung',
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark
                          ? const Color(0xFF81C784)
                          : const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < jamaahList.length; i++) ...[
                _buildJamaahPill(
                  context: context,
                  jamaah: jamaahList[i],
                  isActive: selectedIndex == i,
                  isDark: isDark,
                  onTap: () => onSelected?.call(i),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _openJamaahDetail(BuildContext context, JamaahData jamaah) {
    final roomId = state.activeRoomId.value ?? '';
    final roomName =
        state.activeRoom.value?.capitalizedName ?? 'Room Pemantauan';
    final roomCode = state.activeRoom.value?.code ?? '';
    JamaahDetailSheet.show(
      context,
      jamaah: jamaah,
      roomId: roomId,
      roomName: roomName,
      roomCode: roomCode,
    );
  }

  Widget _buildJamaahPill({
    required BuildContext context,
    required JamaahData jamaah,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final initial = jamaah.name.trim().isNotEmpty
        ? jamaah.name.trim()[0].toUpperCase()
        : 'J';
    final distance = jamaah.formattedDistance;

    return InkWell(
      onTap: onTap,
      onLongPress: () => _openJamaahDetail(context, jamaah),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.only(
          left: 5,
          top: 5,
          bottom: 5,
          right: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? (isActive
                    ? AppColors.darkPrimaryContainer
                    : AppColors.darkSurface)
              : (isActive
                    ? AppColors.surfaceWhite
                    : AppColors.surfaceWhite.withValues(alpha: 0.9)),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isActive
                ? (isDark ? AppColors.goldPrimary : AppColors.primaryContainer)
                : (isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder),
            width: isActive ? 1.8 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.espressoDark)
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              AppColors.darkPrimaryContainer,
                              AppColors.darkSurfaceContainerHighest,
                            ]
                          : [
                              AppColors.espressoDark,
                              AppColors.primaryContainer,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.surfaceWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: jamaah.isGpsActive
                          ? AppColors.statusSafe
                          : AppColors.outline,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.surfaceWhite,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      jamaah.shortLabel,
                      style: AppTypography.labelLarge.copyWith(
                        color: headingColor,
                        fontWeight: isActive
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (jamaah.sosActive) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.sosEmergency,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: jamaah.tier.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_localizedTierLabel(context, jamaah.tier)} • $distance',
                      style: AppTypography.captionSmall.copyWith(
                        color: isActive ? jamaah.tier.color : bodyColor,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: () => _openJamaahDetail(context, jamaah),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isActive
                      ? headingColor
                      : bodyColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
