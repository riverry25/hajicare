import 'package:flutter/material.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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

  final bool isRouteLoading;
  final double? routeDistanceMeters;
  final int? routeDurationSeconds;
  final String? routeError;
  final VoidCallback? onRetryRoute;

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
    this.isRouteLoading = false,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
    this.routeError,
    this.onRetryRoute,
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
          color: AppColors.cardBgColor(context),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(
              color: AppColors.cardBorderColor(context),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.cardBorderColor(context),
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

    final mq = MediaQuery.of(context);
    final double maxDetailHeight = (mq.size.height * 0.46).clamp(240.0, 420.0);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxDetailHeight),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.cardPadding,
          AppSpacing.xs,
          AppSpacing.cardPadding,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Avatar with Role Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPendamping
                        ? AppColors.primaryContainer
                        : AppColors.canvasCream,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPendamping
                          ? AppColors.goldPrimary
                          : AppColors.statusSafe,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espressoDark.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPendamping ? Icons.shield_rounded : Icons.person_rounded,
                    color: isPendamping
                        ? AppColors.goldPrimary
                        : AppColors.espressoDark,
                    size: 26,
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
                                color: AppColors.textHeadingColor(context),
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPendamping
                                  ? AppColors.goldPrimary.withValues(alpha: 0.16)
                                  : AppColors.statusSafe.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isPendamping
                                    ? AppColors.goldPrimary.withValues(alpha: 0.4)
                                    : AppColors.statusSafe.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              isPendamping ? 'Pendamping' : 'Jamaah',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isPendamping
                                    ? AppColors.espressoDark
                                    : AppColors.statusSafe,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_rounded,
                            size: 14,
                            color: member.hasLocation
                                ? AppColors.goldPrimary
                                : AppColors.outlineVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$distText dari Anda',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textBodyColor(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: locStatus == 'Online'
                                  ? AppColors.statusSafe
                                  : AppColors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locStatus,
                            style: AppTypography.captionSmall.copyWith(
                              color: locStatus == 'Online'
                                  ? AppColors.statusSafe
                                  : AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close detail button
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: AppColors.tanMedium,
                  splashRadius: 20,
                  onPressed: onCloseMemberDetail,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action button (52px height)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: _buildRouteButton(member),
            ),

            if (routeDistanceMeters != null && routeDurationSeconds != null)
              _buildRouteInfoBar(distText),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteButton(RoomMemberModel member) {
    if (!member.hasLocation) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.directions_rounded, size: 18),
        label: Text(
          'Lokasi Anggota Belum Tersedia',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.canvasCream,
          disabledBackgroundColor: AppColors.canvasCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      );
    }

    if (isRouteLoading) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.espressoDark),
          ),
        ),
        label: Text(
          'Mencari rute jalan kaki terbaik...',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.canvasCream,
          disabledBackgroundColor: AppColors.canvasCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            side: const BorderSide(color: AppColors.goldLight),
          ),
        ),
      );
    }

    if (routeError != null) {
      return ElevatedButton.icon(
        onPressed: onRetryRoute,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(
          'Rute tidak ditemukan · Coba Lagi',
          style: AppTypography.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sosEmergency,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onNavigate,
      icon: const Icon(
        Icons.directions_walk_rounded,
        size: 20,
        color: AppColors.goldPrimary,
      ),
      label: Text(
        'Arahkan Rute ke ${member.name.split(' ').first}',
        style: AppTypography.labelLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.espressoDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColors.espressoDark.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(
            color: AppColors.goldPrimary.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoBar(String directDist) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.canvasCream.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            icon: Icons.straighten_rounded,
            label: 'Jarak Langsung',
            value: directDist,
          ),
          Container(
            width: 1,
            height: 28,
            color: AppColors.goldLight.withValues(alpha: 0.4),
          ),
          _buildInfoItem(
            icon: Icons.directions_walk_rounded,
            label: 'Jalan Kaki',
            value: _formatDistance(routeDistanceMeters!),
            highlight: true,
          ),
          Container(
            width: 1,
            height: 28,
            color: AppColors.goldLight.withValues(alpha: 0.4),
          ),
          _buildInfoItem(
            icon: Icons.timer_outlined,
            label: 'Estimasi Tiba',
            value: _formatDuration(routeDurationSeconds!),
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: highlight ? AppColors.espressoDark : AppColors.tanMedium,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.captionSmall.copyWith(
            color: highlight
                ? AppColors.espressoDark
                : AppColors.textHeading,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toInt()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds dtk';
    if (seconds < 3600) return '${seconds ~/ 60} mnt';
    return '${seconds ~/ 3600}j ${(seconds % 3600) ~/ 60}m';
  }

  // ── 2. ROOM MEMBERS LIST PANEL ─────────────────────────────────────────────

  Widget _buildRoomMembersList(
    BuildContext context,
    List<RoomMemberModel> members,
  ) {
    final sorted = List<RoomMemberModel>.from(members);
    sorted.sort((a, b) {
      if (a.hasLocation && !b.hasLocation) return -1;
      if (!a.hasLocation && b.hasLocation) return 1;
      return a.name.compareTo(b.name);
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        AppSpacing.xs,
        AppSpacing.cardPadding,
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
                  color: AppColors.textHeadingColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: AppColors.cardBorderColor(context),
                  ),
                ),
                child: Text(
                  '${members.length} anggota',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.espressoDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildMemberListView(context, sorted),
        ],
      ),
    );
  }

  Widget _buildMemberListView(
    BuildContext context,
    List<RoomMemberModel> sorted,
  ) {
    final mq = MediaQuery.of(context);
    const double kOverhead = 30 + 44 + 24 + 16;
    final double listMaxHeight = mq.size.height
        - mq.padding.top
        - bottomOffset
        - mq.padding.bottom
        - kOverhead;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: listMaxHeight.clamp(160.0, double.infinity),
      ),
      child: ListView.separated(
        padding: EdgeInsets.only(
          bottom: mq.padding.bottom + 8,
        ),
        itemCount: sorted.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppColors.cardBorderColor(context),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isPendamping
                          ? AppColors.goldPrimary.withValues(alpha: 0.16)
                          : AppColors.statusSafe.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isPendamping
                            ? AppColors.goldPrimary.withValues(alpha: 0.35)
                            : AppColors.statusSafe.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      isPendamping ? 'Pendamping' : 'Jamaah',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPendamping
                            ? AppColors.espressoDark
                            : AppColors.statusSafe,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      m.name,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w700,
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
                              ? AppColors.goldPrimary
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        locStatus,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: locStatus == 'Online'
                              ? AppColors.statusSafe
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.tanMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 3. LEGACY JAMAAH CARD FALLBACK ─────────────────────────────────────────

  Widget _buildLegacyJamaahCard(BuildContext context) {
    final jamaah = activeJamaah ?? state.self;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.canvasCream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.elderly_rounded,
                  color: AppColors.espressoDark,
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
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${jamaah.shortLabel} • Jarak ${jamaah.distance.toInt()}m',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textBodyColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(
                Icons.directions_walk_rounded,
                size: 20,
                color: AppColors.goldPrimary,
              ),
              label: Text(
                'Mulai Navigasi',
                style: AppTypography.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.espressoDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(
                    color: AppColors.goldPrimary.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
