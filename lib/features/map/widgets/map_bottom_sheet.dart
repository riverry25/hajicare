import '../../../core/locales/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class MapBottomSheet extends StatefulWidget {
  final HajiCareState state;
  final JamaahData? activeJamaah;
  final RoomMemberModel? selectedMember;
  final List<RoomMemberModel>? roomMembers;
  final String? Function(RoomMemberModel)? getMemberDistanceText;
  final ValueChanged<RoomMemberModel>? onMemberTap;
  final VoidCallback? onCloseMemberDetail;
  final VoidCallback? onBackToList;
  final VoidCallback? onNavigate;
  final VoidCallback? onShareLocation;
  final VoidCallback? onCall;

  final bool isRouteLoading;
  final double? routeDistanceMeters;
  final int? routeDurationSeconds;
  final String? routeError;
  final VoidCallback? onRetryRoute;

  final VoidCallback? onCenterOnMember;

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
    this.onBackToList,
    this.onNavigate,
    this.onShareLocation,
    this.onCall,
    this.onCenterOnMember,
    this.isRouteLoading = false,
    this.routeDistanceMeters,
    this.routeDurationSeconds,
    this.routeError,
    this.onRetryRoute,
    this.bottomOffset = 0.0,
  });

  @override
  State<MapBottomSheet> createState() => _MapBottomSheetState();
}

class _MapBottomSheetState extends State<MapBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  Animation<double>? _slideAnim;
  bool _isDismissing = false;
  double _dragOffset = 0.0;

  bool _isSearchOpen = false;
  String _searchQuery = '';
  late final TextEditingController _searchCtrl;

  HajiCareState get state => widget.state;
  JamaahData? get activeJamaah => widget.activeJamaah;
  RoomMemberModel? get selectedMember => widget.selectedMember;
  List<RoomMemberModel>? get roomMembers => widget.roomMembers;
  String? Function(RoomMemberModel)? get getMemberDistanceText =>
      widget.getMemberDistanceText;
  ValueChanged<RoomMemberModel>? get onMemberTap => widget.onMemberTap;
  VoidCallback? get onCloseMemberDetail => widget.onCloseMemberDetail;
  VoidCallback? get onBackToList => widget.onBackToList;
  VoidCallback? get onNavigate => widget.onNavigate;
  VoidCallback? get onShareLocation => widget.onShareLocation;
  VoidCallback? get onCall => widget.onCall;
  bool get isRouteLoading => widget.isRouteLoading;
  double? get routeDistanceMeters => widget.routeDistanceMeters;
  int? get routeDurationSeconds => widget.routeDurationSeconds;
  String? get routeError => widget.routeError;
  VoidCallback? get onRetryRoute => widget.onRetryRoute;
  VoidCallback? get onCenterOnMember => widget.onCenterOnMember;
  double get bottomOffset => widget.bottomOffset;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    // Smooth entrance slide up
    _dragOffset = 60.0;
    _slideAnim = Tween<double>(begin: 60.0, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    )..addListener(_onAnimTick);
    _animCtrl.forward();
  }

  void _onAnimTick() {
    if (mounted && _slideAnim != null) {
      setState(() {
        _dragOffset = _slideAnim!.value;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _slideAnim?.removeListener(_onAnimTick);
    _animCtrl.dispose();
    super.dispose();
  }

  void _dismissWithAnimation({double velocity = 0.0}) {
    if (_isDismissing) return;
    _isDismissing = true;

    final startOffset = _dragOffset;
    final targetOffset = math.max(450.0, startOffset + 320.0);

    // Dynamic duration based on downward velocity
    int durationMs = 220;
    if (velocity > 800) {
      durationMs = 150;
    } else if (velocity > 400) {
      durationMs = 180;
    }

    _slideAnim?.removeListener(_onAnimTick);
    _animCtrl.duration = Duration(milliseconds: durationMs);
    _slideAnim = Tween<double>(begin: startOffset, end: targetOffset).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInCubic),
    )..addListener(_onAnimTick);

    _animCtrl.reset();
    _animCtrl.forward().then((_) {
      if (mounted) {
        widget.onCloseMemberDetail?.call();
      }
    });
  }

  void _springBackAnimation() {
    if (_isDismissing) return;
    if (_dragOffset == 0.0) return;

    final startOffset = _dragOffset;
    _slideAnim?.removeListener(_onAnimTick);
    _animCtrl.duration = const Duration(milliseconds: 220);
    _slideAnim = Tween<double>(begin: startOffset, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    )..addListener(_onAnimTick);

    _animCtrl.reset();
    _animCtrl.forward();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isDismissing) return;
    if (_animCtrl.isAnimating) {
      _animCtrl.stop();
    }
    if (details.primaryDelta != null) {
      setState(() {
        if (details.primaryDelta! > 0) {
          _dragOffset += details.primaryDelta!;
        } else {
          if (_dragOffset > 0) {
            _dragOffset = math.max(0.0, _dragOffset + details.primaryDelta!);
          } else {
            _dragOffset = math.max(
              -20.0,
              _dragOffset + details.primaryDelta! * 0.25,
            );
          }
        }
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isDismissing) return;
    final velocity = details.primaryVelocity ?? 0.0;
    final isFlingDown = velocity > 300.0;
    final isDraggedDown = _dragOffset > 60.0 && velocity > -100.0;
    final isDeepDrag = _dragOffset > 110.0;

    if (isFlingDown || isDraggedDown || isDeepDrag) {
      _dismissWithAnimation(velocity: velocity);
    } else {
      _springBackAnimation();
    }
  }

  void _onVerticalDragCancel() {
    if (!_isDismissing) {
      _springBackAnimation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final opacity = (1.0 - (_dragOffset / 280.0)).clamp(0.0, 1.0);

    final effectiveMember =
        selectedMember ??
        (activeJamaah != null
            ? RoomMemberModel(
                uid: activeJamaah!.id,
                name: activeJamaah!.name,
                role: 'jamaah',
                currentLocation: activeJamaah!.currentLocation,
                locationUpdatedAt: activeJamaah!.locationUpdatedAt,
              )
            : null);

    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: bottomOffset,
      child: RepaintBoundary(
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              onVerticalDragCancel: _onVerticalDragCancel,
              child: effectiveMember != null
                  ? Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        // Card container with top margin for overlapping avatar
                        Container(
                          margin: const EdgeInsets.only(top: 26),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : AppColors.espressoDark.withValues(
                                      alpha: 0.06,
                                    ),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.35 : 0.09,
                                ),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: _buildSelectedMemberDetail(
                              context,
                              effectiveMember,
                            ),
                          ),
                        ),

                        // Corner Utility: Back to List
                        if (onBackToList != null)
                          Positioned(
                            top: 36,
                            left: 14,
                            child: _buildSmallCircularButton(
                              context: context,
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Kembali ke Daftar',
                              onTap: onBackToList!,
                            ),
                          ),

                        // Corner Utility: Center on Map
                        if (onCenterOnMember != null)
                          Positioned(
                            top: 36,
                            right: 14,
                            child: _buildSmallCircularButton(
                              context: context,
                              icon: Icons.my_location_rounded,
                              tooltip: 'Fokus ke Peta',
                              onTap: onCenterOnMember!,
                            ),
                          ),

                        // Overlapping circular avatar popping out at top center
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildOverlappingAvatar(
                              context,
                              effectiveMember,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.espressoDark.withValues(
                                    alpha: 0.06,
                                  ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.08,
                              ),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Interactive Drag Handle
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _dismissWithAnimation(),
                              onVerticalDragUpdate: _onVerticalDragUpdate,
                              onVerticalDragEnd: _onVerticalDragEnd,
                              onVerticalDragCancel: _onVerticalDragCancel,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                color: Colors.transparent,
                                child: Center(
                                  child: Container(
                                    width: 38,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.darkOutline
                                          : AppColors.outlineVariant.withValues(
                                              alpha: 0.7,
                                            ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            if (roomMembers != null && roomMembers!.isNotEmpty)
                              _buildRoomMembersList(context, roomMembers!)
                            else
                              _buildLegacyJamaahCard(context),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. SELECTED MEMBER DETAIL CARD (Reference Photo UI & UX) ───────────────

  Widget _buildSelectedMemberDetail(
    BuildContext context,
    RoomMemberModel member,
  ) {
    final isDark = AppColors.isDark(context);
    final distText = getMemberDistanceText != null
        ? getMemberDistanceText!(member) ?? 'Lokasi belum tersedia'
        : (member.hasLocation ? 'Lokasi aktif' : 'Lokasi belum tersedia');
    final hasRoute =
        routeDistanceMeters != null && routeDurationSeconds != null;

    final mq = MediaQuery.of(context);
    final double maxDetailHeight = ((mq.size.height * 0.46)).clamp(
      280.0,
      410.0,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxDetailHeight),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (_isDismissing) return false;
          if (notification is OverscrollNotification &&
              notification.overscroll < 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDismissing) {
                if (_animCtrl.isAnimating) _animCtrl.stop();
                setState(() {
                  _dragOffset = math.max(
                    0.0,
                    _dragOffset - notification.overscroll * 0.4,
                  );
                });
              }
            });
          } else if (notification is ScrollEndNotification) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDismissing) {
                if (_dragOffset > 60.0) {
                  _dismissWithAnimation();
                } else if (_dragOffset > 0.0) {
                  _springBackAnimation();
                }
              }
            });
          }
          return false;
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Clearance for overlapping floating avatar ──────────────────
              const SizedBox(height: 40),

              // ── Member Name (Centered bold title) ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 46),
                child: Text(
                  member.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.espressoDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              // ── Waktu Terakhir Update Lokasi ──────────────────────────────
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: BoxDecoration(
                          color: _getLocationStatusColor(member),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _formatLastLocationUpdate(member),
                          style: AppTypography.captionSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextBody
                                : AppColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 3-Column Metric Box (Kondisi, Jarak, GPS) ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildThreeColumnStatsBox(
                  context,
                  member,
                  distText,
                  hasRoute,
                ),
              ),

              const SizedBox(height: 10),

              // ── Primary Pill Button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 42,
                  child: _buildPrimaryPillButton(context, member, hasRoute),
                ),
              ),

              // ── Dismiss Action (Tutup text button) ─────────────────────────
              if (member.hasLocation)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: TextButton(
                      onPressed: () => _dismissWithAnimation(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        visualDensity: VisualDensity.compact,
                        minimumSize: const Size(60, 26),
                      ),
                      child: Text(
                        'Tutup',
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextBody
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Overlapping Circular Avatar (Centered & Proportional) ───────────────────

  Widget _buildOverlappingAvatar(BuildContext context, RoomMemberModel member) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final isPendamping = member.isPendamping;
    final isEmergency = member.sosActive;

    final List<Color> gradientColors;
    if (isEmergency) {
      gradientColors = const [Color(0xFFFEE2E2), Color(0xFFFECACA)];
    } else if (isPendamping) {
      gradientColors = const [Color(0xFFDBEAFE), Color(0xFFBFDBFE)];
    } else {
      gradientColors = const [Color(0xFFDCFCE7), Color(0xFFBBF7D0)];
    }

    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cardBg,
        border: Border.all(color: cardBg, width: 3.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Character Avatar Graphic (Centered cleanly)
              Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 38,
                  color: isEmergency
                      ? AppColors.sosEmergency
                      : (isPendamping
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF16A34A)),
                ),
              ),

              // Role / Status Badge on the avatar
              if (isPendamping)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),

              if (isEmergency)
                Positioned(
                  top: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 3-Column Metric Box (Kondisi, Jarak, GPS) ───────────────────────────────

  Widget _buildThreeColumnStatsBox(
    BuildContext context,
    RoomMemberModel member,
    String distText,
    bool hasRoute,
  ) {
    final isDark = AppColors.isDark(context);
    final containerBg = isDark
        ? AppColors.darkSurfaceContainer
        : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? AppColors.darkOutline.withValues(alpha: 0.25)
        : const Color(0xFFE2E8F0);
    final isPendamping = member.isPendamping;

    // Stat 1: Status Kondisi Jamaah (Kesehatan / Keselamatan - Pengganti Bintang)
    final stat1Value = member.sosActive ? 'SOS' : 'Aman';
    final stat1Label = 'Kondisi';

    // Stat 2: Distance / Route ETA
    final String stat2Value;
    final String stat2Label;
    if (hasRoute && routeDurationSeconds != null) {
      stat2Value = _formatDuration(routeDurationSeconds!);
      stat2Label = routeDistanceMeters != null
          ? _formatDistance(routeDistanceMeters!)
          : 'Rute';
    } else {
      final parts = distText.split(' ');
      stat2Value = parts.isNotEmpty ? parts.first : '--';
      stat2Label = parts.length > 1 ? parts.sublist(1).join(' ') : 'Jarak';
    }

    // Stat 3: Role / GPS Status
    final stat3Value = isPendamping
        ? 'Petugas'
        : (member.hasLocation ? 'Aktif' : 'Off');
    final stat3Label = isPendamping ? 'Peran' : 'GPS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Column 1: Kondisi Jamaah (Aman / SOS)
          Expanded(
            child: _buildStatColumn(
              context: context,
              icon: Icons.health_and_safety_rounded,
              value: stat1Value,
              label: stat1Label,
              isEmergency: member.sosActive,
            ),
          ),
          Container(height: 24, width: 1, color: borderColor),
          // Column 2: Walk / Jarak
          Expanded(
            child: _buildStatColumn(
              context: context,
              icon: Icons.directions_walk_rounded,
              value: stat2Value,
              label: stat2Label,
            ),
          ),
          Container(height: 24, width: 1, color: borderColor),
          // Column 3: Shield / GPS Status
          Expanded(
            child: _buildStatColumn(
              context: context,
              icon: Icons.shield_outlined,
              value: stat3Value,
              label: stat3Label,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    bool isEmergency = false,
  }) {
    final isDark = AppColors.isDark(context);
    final greenColor = isEmergency
        ? AppColors.sosEmergency
        : const Color(0xFF22C55E);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: greenColor),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                value,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isEmergency
                      ? AppColors.sosEmergency
                      : (isDark
                            ? AppColors.darkTextHeading
                            : AppColors.espressoDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: AppTypography.captionSmall.copyWith(
                  fontSize: 10.5,
                  color: isDark ? AppColors.darkTextBody : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Primary Pill Button (Vibrant green pill button matching reference) ─────

  Widget _buildPrimaryPillButton(
    BuildContext context,
    RoomMemberModel member,
    bool hasRoute,
  ) {
    final isDark = AppColors.isDark(context);

    if (!member.hasLocation) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          gradient: const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _dismissWithAnimation(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
          ),
          child: const Text(
            'Tutup',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (isRouteLoading) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: isDark
              ? AppColors.darkSurfaceContainer
              : const Color(0xFFE2E8F0),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? AppColors.goldPrimary : const Color(0xFF16A34A),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Mencari rute jalan kaki...',
                style: AppTypography.labelLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextBody
                      : AppColors.espressoDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (routeError != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: AppColors.sosEmergency,
          boxShadow: [
            BoxShadow(
              color: AppColors.sosEmergency.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onRetryRoute,
          icon: const Icon(
            Icons.refresh_rounded,
            size: 18,
            color: Colors.white,
          ),
          label: const Text(
            'Rute Tidak Ditemukan · Coba Lagi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: const StadiumBorder(),
          ),
        ),
      );
    }

    // Default & Loaded route states: Vibrant Green Pill Button matching reference
    final buttonLabel = hasRoute
        ? 'Mulai Navigasi'
        : 'Arahkan Rute ke ${member.name.split(' ').first}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onNavigate,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Text(
          buttonLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCircularButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.canvasCream.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? AppColors.darkOutline.withValues(alpha: 0.25)
                    : AppColors.outlineVariant.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 16,
                color: isDark
                    ? AppColors.darkTextBody
                    : AppColors.espressoMedium,
              ),
            ),
          ),
        ),
      ),
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

  String _formatLastLocationUpdate(RoomMemberModel member) {
    final updatedAt = member.locationUpdatedAt;
    if (!member.hasLocation || updatedAt == null) {
      return 'Lokasi belum tersedia';
    }

    final now = DateTime.now();
    final diff = now.difference(updatedAt);

    if (diff.isNegative || diff.inSeconds < 45) {
      return 'Update baru saja';
    } else if (diff.inMinutes < 60) {
      return 'Update ${diff.inMinutes} mnt lalu';
    } else if (diff.inHours < 24) {
      final hourStr = updatedAt.hour.toString().padLeft(2, '0');
      final minStr = updatedAt.minute.toString().padLeft(2, '0');
      return 'Update pukul $hourStr:$minStr';
    } else {
      return 'Update ${diff.inDays} hari lalu';
    }
  }

  Color _getLocationStatusColor(RoomMemberModel member) {
    if (member.sosActive) return AppColors.sosEmergency;
    if (!member.hasLocation || member.locationUpdatedAt == null) {
      return AppColors.textMuted.withValues(alpha: 0.6);
    }
    final diff = DateTime.now().difference(member.locationUpdatedAt!);
    if (diff.inMinutes <= 5) {
      return const Color(0xFF22C55E);
    } else if (diff.inMinutes <= 30) {
      return const Color(0xFFEAB308);
    }
    return AppColors.textMuted;
  }

  // ── 2. ROOM MEMBERS LIST PANEL (Gambar 2 Fusion & Compact Design) ──────────

  Widget _buildCircularHeaderButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final isDark = AppColors.isDark(context);
    final activeBg = isDark
        ? AppColors.darkPrimaryContainer
        : AppColors.espressoDark;
    final activeColor = isDark ? AppColors.goldLight : AppColors.canvasCream;
    final defaultBg = isDark
        ? AppColors.darkSurfaceContainerHighest
        : AppColors.canvasCream;
    final defaultColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Ink(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? activeBg : defaultBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? (isDark
                            ? AppColors.goldPrimary
                            : AppColors.espressoDark)
                      : (isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.lightCardBorder),
                  width: 1.1,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 17,
                  color: isActive ? activeColor : defaultColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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

    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.cardPadding,
        AppSpacing.xs,
        AppSpacing.cardPadding,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Title on Left, 2 Circular Action Buttons on Right ──
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            onVerticalDragCancel: _onVerticalDragCancel,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Title block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pilih Anggota',
                      style: AppTypography.titleSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextBody
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Rombongan',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${members.length} anggota terdaftar',
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),

                // Right Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCircularHeaderButton(
                      context: context,
                      icon: Icons.search_rounded,
                      tooltip: _isSearchOpen
                          ? 'Tutup Pencarian'
                          : 'Cari Anggota',
                      isActive: _isSearchOpen,
                      onTap: () {
                        setState(() {
                          _isSearchOpen = !_isSearchOpen;
                          if (!_isSearchOpen) {
                            _searchQuery = '';
                            _searchCtrl.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildCircularHeaderButton(
                      context: context,
                      icon: Icons.close_rounded,
                      tooltip: 'Tutup Dialog',
                      onTap: () => _dismissWithAnimation(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Search Bar: Unified styling (no color clash / belang) ──
          if (_isSearchOpen) ...[
            const SizedBox(height: 8),
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.canvasCream,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.lightCardBorder,
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 17,
                      color: isDark
                          ? AppColors.goldLight
                          : AppColors.espressoDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHeadingColor(context),
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('maps.searchNameOrStatus'),
                          hintStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? AppColors.darkOutline
                                : AppColors.textMuted,
                          ),
                          filled: false,
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchQuery = '';
                            _searchCtrl.clear();
                          });
                        },
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          _buildMemberListView(context, sorted),
        ],
      ),
    );
  }

  Widget _buildMemberListView(
    BuildContext context,
    List<RoomMemberModel> sorted,
  ) {
    final isDark = AppColors.isDark(context);
    final mq = MediaQuery.of(context);
    // Compact max height so it does NOT dominate or cover the map view
    final double listMaxHeight = (mq.size.height * 0.38).clamp(180.0, 310.0);

    final filtered = sorted.where((m) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final nameMatches = m.name.toLowerCase().contains(q);
      final roleMatches = (m.isPendamping ? 'pendamping' : 'jamaah').contains(
        q,
      );
      final locStatus = m.getLocationStatus().toLowerCase();
      final statusMatches = locStatus.contains(q);
      return nameMatches || roleMatches || statusMatches;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 28,
              color: AppColors.outlineVariant,
            ),
            SizedBox(height: 6),
            Text(
              'Tidak ada anggota yang cocok',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_isDismissing) return false;
        if (notification is OverscrollNotification &&
            notification.overscroll < 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isDismissing) {
              if (_animCtrl.isAnimating) _animCtrl.stop();
              setState(() {
                _dragOffset = math.max(
                  0.0,
                  _dragOffset - notification.overscroll * 0.4,
                );
              });
            }
          });
        } else if (notification is ScrollEndNotification) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isDismissing) {
              if (_dragOffset > 60.0) {
                _dismissWithAnimation();
              } else if (_dragOffset > 0.0) {
                _springBackAnimation();
              }
            }
          });
        }
        return false;
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: listMaxHeight),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(top: 2, bottom: mq.padding.bottom + 4),
          itemCount: filtered.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 138,
          ),
          itemBuilder: (context, index) {
            final m = filtered[index];
            final dist = getMemberDistanceText != null
                ? getMemberDistanceText!(m) ?? 'Lokasi -'
                : (m.hasLocation ? 'Lokasi aktif' : 'Lokasi -');
            final isPendamping = m.isPendamping;
            final locStatus = m.getLocationStatus();
            final isOnline = locStatus == 'Online';
            final initial = m.name.trim().isNotEmpty
                ? m.name.trim()[0].toUpperCase()
                : (isPendamping ? 'P' : 'J');

            // ── Unified Color Configuration (Same clean card for all members) ──
            final cardBg = isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.surfaceWhite;
            final cardBorder = isDark
                ? AppColors.darkOutlineVariant
                : AppColors.lightCardBorder;
            final cardTextColor = isDark
                ? AppColors.darkTextHeading
                : AppColors.textHeading;
            final cardSubtextColor = isDark
                ? AppColors.darkTextBody.withValues(alpha: 0.8)
                : AppColors.textMuted;
            final cardDistanceColor = isDark
                ? AppColors.darkTextHeading
                : AppColors.textHeading;
            final cardDistanceIconColor = isDark
                ? AppColors.darkPrimary
                : AppColors.goldPrimary;
            final roleBgColor = isPendamping
                ? AppColors.goldPrimary.withValues(alpha: isDark ? 0.25 : 0.15)
                : AppColors.statusSafe.withValues(alpha: isDark ? 0.2 : 0.1);
            final roleBorderColor = isPendamping
                ? AppColors.goldPrimary.withValues(alpha: isDark ? 0.45 : 0.35)
                : AppColors.statusSafe.withValues(alpha: 0.28);
            final roleTextColor = isPendamping
                ? (isDark ? AppColors.goldLight : AppColors.espressoDark)
                : AppColors.statusSafe;
            final arrowBtnBg = isDark
                ? AppColors.darkSurfaceContainerHighest
                : AppColors.canvasCream;
            final arrowBtnBorder = isDark
                ? AppColors.darkOutlineVariant
                : AppColors.lightCardBorder;
            final arrowBtnIconColor = isDark
                ? AppColors.darkTextHeading
                : AppColors.espressoDark;
            final displayStatus = locStatus == 'Lokasi tidak diperbarui'
                ? 'Tidak diperbarui'
                : locStatus;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onMemberTap?.call(m),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cardBorder, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ── Top Row: Avatar on Left, Member Name on Right ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar with Status Dot
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isPendamping
                                        ? (isDark
                                              ? [
                                                  AppColors
                                                      .darkSurfaceContainerHighest,
                                                  AppColors
                                                      .darkPrimaryContainer,
                                                ]
                                              : [
                                                  AppColors.espressoMedium,
                                                  AppColors.primaryContainer,
                                                ])
                                        : (isDark
                                              ? [
                                                  AppColors
                                                      .darkSurfaceContainerHigh,
                                                  AppColors
                                                      .darkSurfaceContainer,
                                                ]
                                              : [
                                                  AppColors.tanLight.withValues(
                                                    alpha: 0.4,
                                                  ),
                                                  AppColors.canvasCream,
                                                ]),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: isPendamping
                                        ? AppColors.goldPrimary
                                        : (isDark
                                              ? AppColors.darkOutlineVariant
                                              : AppColors.tanMedium.withValues(
                                                  alpha: 0.35,
                                                )),
                                    width: 1.1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isPendamping
                                    ? Icon(
                                        Icons.shield_rounded,
                                        size: 17,
                                        color: isDark
                                            ? AppColors.goldLight
                                            : Colors.white,
                                      )
                                    : Text(
                                        initial,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? AppColors.darkTextHeading
                                              : AppColors.espressoDark,
                                        ),
                                      ),
                              ),
                              Positioned(
                                right: -1,
                                bottom: -1,
                                child: Container(
                                  width: 9.5,
                                  height: 9.5,
                                  decoration: BoxDecoration(
                                    color: m.hasLocation && isOnline
                                        ? AppColors.statusSafe
                                        : (m.hasLocation
                                              ? AppColors.statusWarning
                                              : AppColors.outlineVariant),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cardBg,
                                      width: 1.8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Member Name (bold, 2 lines max, legible)
                          Expanded(
                            child: Text(
                              m.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: cardTextColor,
                                height: 1.15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // ── Middle: Role Badge Pill ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleBgColor,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: roleBorderColor,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isPendamping ? '👑 Pendamping' : 'Jamaah',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: roleTextColor,
                          ),
                        ),
                      ),

                      // ── Bottom Row: Distance & Status on Left, Diagonal Arrow on Right (Gambar 2 Fusion) ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Left side: Distance & Location Status on 2 separate lines (Never truncated!)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      m.hasLocation
                                          ? Icons.near_me_rounded
                                          : Icons.location_off_rounded,
                                      size: 11,
                                      color: cardDistanceIconColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        dist,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: cardDistanceColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      isOnline
                                          ? Icons.sensors_rounded
                                          : Icons.access_time_rounded,
                                      size: 10,
                                      color: isOnline
                                          ? AppColors.statusSafe
                                          : cardSubtextColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        displayStatus,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: isOnline
                                              ? AppColors.statusSafe
                                              : cardSubtextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Right side: Circular Diagonal Arrow Button (matching Gambar 2 bottom-right)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onMemberTap?.call(m),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: arrowBtnBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: arrowBtnBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_outward_rounded,
                                    size: 16,
                                    color: arrowBtnIconColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── 3. LEGACY JAMAAH CARD FALLBACK ─────────────────────────────────────────

  Widget _buildLegacyJamaahCard(BuildContext context) {
    final isDark = AppColors.isDark(context);
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
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(
                  Icons.elderly_rounded,
                  color: isDark
                      ? AppColors.goldPrimary
                      : AppColors.espressoDark,
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
                      '${jamaah.shortLabel} • ${jamaah.distance >= 1000 ? '${(jamaah.distance / 1000).toStringAsFixed(jamaah.distance >= 100000 ? 0 : 1)}km' : '${jamaah.distance.toInt()}m'}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textBodyColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.outlineVariant,
                onPressed: () => _dismissWithAnimation(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: Icon(
                Icons.directions_walk_rounded,
                size: 20,
                color: isDark ? AppColors.espressoDark : AppColors.goldPrimary,
              ),
              label: Text(
                'Mulai Navigasi',
                style: AppTypography.labelLarge.copyWith(
                  color: isDark ? AppColors.espressoDark : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? AppColors.goldPrimary
                    : AppColors.espressoDark,
                foregroundColor: isDark ? AppColors.espressoDark : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.goldPrimary
                        : AppColors.goldPrimary.withValues(alpha: 0.5),
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
