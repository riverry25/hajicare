import 'package:flutter/material.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class MapBottomSheet extends StatelessWidget {
  final HajiCareState state;
  final JamaahData? activeJamaah;
  final RoomMemberModel? selectedMember;
  final List<RoomMemberModel>? roomMembers;
  final String? Function(RoomMemberModel)? getMemberDistanceText;
  final ValueChanged<RoomMemberModel>? onMemberTap;
  final VoidCallback? onCloseMemberDetail;
  final VoidCallback? onNavigate;
  final VoidCallback? onShareLocation;
  final VoidCallback? onCall;

  final double bottomOffset;

  const MapBottomSheet({
    super.key,
    required this.state,
    this.activeJamaah,
    this.selectedMember,
    this.roomMembers,
    this.getMemberDistanceText,
    this.onMemberTap,
    this.onCloseMemberDetail,
    this.onNavigate,
    this.onShareLocation,
    this.onCall,
    this.bottomOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottomOffset,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          border: Border(
            top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),

            if (selectedMember != null)
              _buildSelectedMemberDetail(context, selectedMember!)
            else if (roomMembers != null && roomMembers!.isNotEmpty)
              _buildRoomMembersList(context, roomMembers!)
            else
              _buildLegacyJamaahCard(context),
          ],
        ),
      ),
    );
  }

  // ── 1. SELECTED MEMBER DETAIL CARD ─────────────────────────────────────────

  Widget _buildSelectedMemberDetail(BuildContext context, RoomMemberModel member) {
    final distText = getMemberDistanceText != null
        ? getMemberDistanceText!(member) ?? 'Lokasi belum tersedia'
        : (member.hasLocation ? 'Lokasi aktif' : 'Lokasi belum tersedia');
    final locStatus = member.getLocationStatus();
    final isPendamping = member.isPendamping;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Avatar with Role Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPendamping
                      ? AppColors.primaryContainer
                      : AppColors.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isPendamping
                        ? AppColors.accentGoldStar
                        : AppColors.statusSafe,
                    width: 2,
                  ),
                ),
                child: Icon(
                  isPendamping ? Icons.shield : Icons.person,
                  color: isPendamping
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSecondaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Name & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPendamping
                                ? AppColors.accentGoldStar.withValues(alpha: 0.2)
                                : AppColors.statusSafe.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            isPendamping ? 'Pendamping' : 'Jamaah',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPendamping
                                  ? AppColors.primary
                                  : AppColors.statusSafe,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.near_me,
                          size: 13,
                          color: member.hasLocation
                              ? AppColors.primary
                              : AppColors.outlineVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$distText dari Anda',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.espressoDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' • $locStatus',
                          style: AppTypography.captionSmall.copyWith(
                            color: locStatus == 'Online'
                                ? AppColors.statusSafe
                                : AppColors.textBody,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Close detail button
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: AppColors.outlineVariant,
                onPressed: onCloseMemberDetail,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Action button
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightSecondary,
            child: ElevatedButton.icon(
              onPressed: member.hasLocation ? onNavigate : null,
              icon: const Icon(Icons.directions, size: 18),
              label: Text(
                member.hasLocation
                    ? 'Arahkan Rute ke ${member.name.split(' ').first}'
                    : 'Lokasi Belum Tersedia',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.surfaceWhite,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espressoDark,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. ROOM MEMBERS LIST PANEL ─────────────────────────────────────────────

  Widget _buildRoomMembersList(
    BuildContext context,
    List<RoomMemberModel> members,
  ) {
    // Sort: members with location first, sorted by distance; then members without location
    final sorted = List<RoomMemberModel>.from(members);
    sorted.sort((a, b) {
      if (a.hasLocation && !b.hasLocation) return -1;
      if (!a.hasLocation && b.hasLocation) return 1;
      return a.name.compareTo(b.name);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Anggota Room',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.espressoDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '${members.length} orang',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.espressoDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const Divider(
                height: 1,
                color: AppColors.outlineVariant,
              ),
              itemBuilder: (context, index) {
                final m = sorted[index];
                final dist = getMemberDistanceText != null
                    ? getMemberDistanceText!(m) ?? 'Lokasi belum tersedia'
                    : (m.hasLocation ? 'Lokasi aktif' : 'Lokasi belum tersedia');
                final isPendamping = m.isPendamping;
                final locStatus = m.getLocationStatus();

                return InkWell(
                  onTap: () => onMemberTap?.call(m),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPendamping
                                ? AppColors.accentGoldStar.withValues(alpha: 0.2)
                                : AppColors.statusSafe.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            isPendamping ? 'Pendamping' : 'Jamaah',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPendamping
                                  ? AppColors.primary
                                  : AppColors.statusSafe,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            m.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              dist,
                              style: AppTypography.captionSmall.copyWith(
                                color: m.hasLocation
                                    ? AppColors.primary
                                    : AppColors.outlineVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              locStatus,
                              style: TextStyle(
                                fontSize: 9,
                                color: locStatus == 'Online'
                                    ? AppColors.statusSafe
                                    : AppColors.textBody,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.tanMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. LEGACY JAMAAH CARD FALLBACK ─────────────────────────────────────────

  Widget _buildLegacyJamaahCard(BuildContext context) {
    final jamaah = activeJamaah ?? state.self;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.canvasCream,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldLight),
                ),
                child: const Icon(
                  Icons.elderly,
                  color: AppColors.tanMedium,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jamaah.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.espressoDark,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${jamaah.shortLabel} • ${jamaah.distance.toInt()}m',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeightSecondary,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.directions, size: 18),
              label: Text(
                'Navigasi',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.surfaceWhite,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espressoDark,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
