import '../../../core/locales/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';

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
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxSheetWidth,
          ),
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
                                color: context.hc.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: context.hc.border,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: context.hc.shadow,
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
                              color: context.hc.surface,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              border: Border.all(
                                color: context.hc.border,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: context.hc.shadow,
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
                                          color: context.hc.borderStrong,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pill,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                if (roomMembers != null &&
                                    roomMembers!.isNotEmpty)
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
        ),
      ),
    );
  }

  // 1. SELECTED MEMBER DETAIL CARD Photo UI & UX

  Widget _buildSelectedMemberDetail(
    BuildContext context,
    RoomMemberModel member,
  ) {
    final distText = getMemberDistanceText != null
        ? getMemberDistanceText!(member) ??
              context.tr('maps.locationUnavailable')
        : (member.hasLocation
              ? context.tr('maps.locationActive')
              : context.tr('maps.locationUnavailable'));
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
              // Clearance for overlapping floating avatar
              const SizedBox(height: 40),

              // Member Name (Centered bold title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 46),
                child: Text(
                  member.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge.copyWith(
                    color: context.hc.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              const SizedBox(height: 3),

              // Waktu Terakhir Update Lokasi
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
                          color: _getLocationStatusColor(context, member),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _formatLastLocationUpdate(member, context),
                          style: context.text.captionSmall.copyWith(
                            color: context.hc.textSecondary,
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

              // 3-Column Metric Box (Kondisi, Jarak, GPS
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

              // Primary Pill Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 42,
                  child: _buildPrimaryPillButton(context, member, hasRoute),
                ),
              ),

              // Dismiss Action (Tutup text button
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
                        context.tr('common.close'),
                        style: context.text.labelMedium.copyWith(
                          color: context.hc.textSecondary,
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

  // Overlapping Circular Avatar (Centered & Proportional

  Widget _buildOverlappingAvatar(BuildContext context, RoomMemberModel member) {
    final hc = context.hc;
    final cardBg = hc.surface;
    final isPendamping = member.isPendamping;
    final isEmergency = member.sosActive;

    final List<Color> gradientColors;
    if (isEmergency) {
      gradientColors = [
        hc.dangerContainer,
        hc.dangerContainer.withValues(alpha: 0.8),
      ];
    } else if (isPendamping) {
      gradientColors = [
        hc.infoContainer,
        hc.infoContainer.withValues(alpha: 0.8),
      ];
    } else {
      gradientColors = [
        hc.successContainer,
        hc.successContainer.withValues(alpha: 0.8),
      ];
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
            color: hc.shadow,
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
              // Character Avatar Graphic (Centered cleanly
              Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 38,
                  color: isEmergency
                      ? hc.danger
                      : (isPendamping ? hc.info : hc.success),
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
                      color: hc.info,
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
                      color: hc.danger,
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

  // 3-Column Metric Box (Kondisi, Jarak, GPS

  Widget _buildThreeColumnStatsBox(
    BuildContext context,
    RoomMemberModel member,
    String distText,
    bool hasRoute,
  ) {
    final hc = context.hc;
    final containerBg = hc.surfaceSubtle;
    final borderColor = hc.border;
    final isPendamping = member.isPendamping;

    // Stat 1: Status Kondisi Jamaah (Kesehatan / Keselamatan - Pengganti Bintang
    final stat1Value = member.sosActive
        ? 'SOS'
        : context.tr('maps.conditionSafe');
    final stat1Label = context.tr('maps.conditionLabel');

    // Stat 2: Distance / Route ETA
    final String stat2Value;
    final String stat2Label;
    if (hasRoute && routeDurationSeconds != null) {
      stat2Value = _formatDuration(routeDurationSeconds!);
      stat2Label = routeDistanceMeters != null
          ? _formatDistance(routeDistanceMeters!)
          : context.tr('maps.routeLabel');
    } else {
      final parts = distText.split(' ');
      stat2Value = parts.isNotEmpty ? parts.first : '--';
      stat2Label = parts.length > 1
          ? parts.sublist(1).join(' ')
          : context.tr('maps.distanceLabel');
    }

    // Stat 3: Role / GPS Status
    final stat3Value = isPendamping
        ? context.tr('maps.rolePetugas')
        : (member.hasLocation
              ? context.tr('maps.statusActive')
              : context.tr('maps.statusOff'));
    final stat3Label = isPendamping ? context.tr('maps.roleLabel') : 'GPS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          // Column 1: Kondisi Jamaah (Aman / SOS
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
    final hc = context.hc;
    final statusColor = isEmergency ? hc.danger : hc.success;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: statusColor),
        const SizedBox(height: 3),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                value,
                style: context.text.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isEmergency ? hc.danger : hc.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: context.text.captionSmall.copyWith(
                  fontSize: 10.5,
                  color: hc.textSecondary,
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

  // Primary Pill Button (Vibrant green pill button

  Widget _buildPrimaryPillButton(
    BuildContext context,
    RoomMemberModel member,
    bool hasRoute,
  ) {
    final hc = context.hc;

    if (!member.hasLocation) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: hc.success,
          boxShadow: [
            BoxShadow(
              color: hc.success.withValues(alpha: 0.35),
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
          child: Text(
            context.tr('common.close'),
            style: TextStyle(
              color: hc.onPrimary,
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
          color: hc.surfaceSubtle,
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
                  valueColor: AlwaysStoppedAnimation<Color>(hc.primary),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('maps.searchingWalkingRoute'),
                style: context.text.labelLarge.copyWith(
                  color: hc.textPrimary,
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
          color: hc.danger,
          boxShadow: [
            BoxShadow(
              color: hc.danger.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onRetryRoute,
          icon: Icon(Icons.refresh_rounded, size: 18, color: hc.onDanger),
          label: Text(
            context.tr('maps.routeNotFoundRetry'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hc.onDanger,
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

    // Default & Loaded route states: Vibrant Green Pill Button
    final buttonLabel = hasRoute
        ? context.tr('maps.startNavigation')
        : context.tr('maps.routeToName', {
            'name': member.name.split(' ').first,
          });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: hc.success,
        boxShadow: [
          BoxShadow(
            color: hc.success.withValues(alpha: 0.35),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            buttonLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hc.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
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
    final hc = context.hc;
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
              color: hc.surfaceSubtle,
              shape: BoxShape.circle,
              border: Border.all(color: hc.border, width: 1),
            ),
            child: Center(child: Icon(icon, size: 16, color: hc.textPrimary)),
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

  String _formatLastLocationUpdate(
    RoomMemberModel member,
    BuildContext context,
  ) {
    final updatedAt = member.locationUpdatedAt;
    if (!member.hasLocation || updatedAt == null) {
      return context.tr('maps.locationUnavailable');
    }

    final now = DateTime.now();
    final diff = now.difference(updatedAt);

    if (diff.isNegative || diff.inSeconds < 45) {
      return context.tr('maps.updateJustNow');
    } else if (diff.inMinutes < 60) {
      return context.tr('maps.updateMinutesAgo', {
        'min': diff.inMinutes.toString(),
      });
    } else if (diff.inHours < 24) {
      final hourStr = updatedAt.hour.toString().padLeft(2, '0');
      final minStr = updatedAt.minute.toString().padLeft(2, '0');
      return context.tr('maps.updateAtTime', {'time': '$hourStr:$minStr'});
    } else {
      return context.tr('maps.updateDaysAgo', {'days': diff.inDays.toString()});
    }
  }

  Color _getLocationStatusColor(BuildContext context, RoomMemberModel member) {
    if (member.sosActive) return context.hc.danger;
    if (!member.hasLocation || member.locationUpdatedAt == null) {
      return context.hc.textMuted.withValues(alpha: 0.6);
    }
    final diff = DateTime.now().difference(member.locationUpdatedAt!);
    if (diff.inMinutes <= 5) {
      return context.hc.success;
    } else if (diff.inMinutes <= 30) {
      return context.hc.warning;
    }
    return context.hc.textMuted;
  }

  // 2. ROOM MEMBERS LIST PANEL

  Widget _buildCircularHeaderButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final hc = context.hc;
    final activeBg = hc.primary;
    final activeColor = hc.onPrimary;
    final defaultBg = hc.surfaceSubtle;
    final defaultColor = hc.textPrimary;

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
                  color: isActive ? hc.accent : hc.border,
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
    final hc = context.hc;
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
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Title on Left, 2 Circular Action Buttons on Right
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('maps.selectMember'),
                        style: context.text.titleSmall.copyWith(
                          color: hc.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        context.tr('maps.groupTitle'),
                        style: context.text.displayMedium.copyWith(
                          color: hc.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('maps.membersRegistered', {
                          'count': members.length.toString(),
                        }),
                        style: context.text.captionSmall.copyWith(
                          color: hc.accentText,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCircularHeaderButton(
                      context: context,
                      icon: Icons.search_rounded,
                      tooltip: _isSearchOpen
                          ? context.tr('maps.closeSearch')
                          : context.tr('maps.searchMember'),
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
                      tooltip: context.tr('maps.closeDialog'),
                      onTap: () => _dismissWithAnimation(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar: Unified styling (no color clash / belang
          if (_isSearchOpen) ...[
            const SizedBox(height: 8),
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: hc.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: hc.border, width: 1.0),
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
                      color: hc.textSecondary,
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
                        style: context.text.bodyMedium.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: hc.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr('maps.searchNameOrStatus'),
                          hintStyle: context.text.bodyMedium.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: hc.textTertiary,
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
                          color: hc.textSecondary,
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
    final hc = context.hc;
    final isDark = hc.isDark;
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 28, color: hc.textMuted),
            const SizedBox(height: 6),
            Text(
              context.tr('maps.noMatchingMembers'),
              style: context.text.bodyMedium.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: hc.textMuted,
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
                ? getMemberDistanceText!(m) ??
                      context.tr('maps.locationUnavailable')
                : (m.hasLocation
                      ? context.tr('maps.locationActive')
                      : context.tr('maps.locationUnavailable'));
            final isPendamping = m.isPendamping;
            final locStatus = m.getLocationStatus();
            final isOnline = locStatus == 'Online';
            final initial = m.name.trim().isNotEmpty
                ? m.name.trim()[0].toUpperCase()
                : (isPendamping ? 'P' : 'J');

            // Unified Color Configuration (Same clean card for all members
            final cardBg = hc.surface;
            final cardBorder = hc.border;
            final cardTextColor = hc.textPrimary;
            final cardSubtextColor = hc.textMuted;
            final cardDistanceColor = hc.textPrimary;
            final cardDistanceIconColor = hc.accent;
            final roleBgColor = isPendamping
                ? hc.accent.withValues(alpha: isDark ? 0.25 : 0.15)
                : hc.success.withValues(alpha: isDark ? 0.2 : 0.1);
            final roleBorderColor = isPendamping
                ? hc.accent.withValues(alpha: isDark ? 0.45 : 0.35)
                : hc.success.withValues(alpha: 0.28);
            final roleTextColor = isPendamping
                ? (isDark ? hc.accent : hc.primary)
                : hc.success;
            final arrowBtnBg = hc.surfaceSubtle;
            final arrowBtnBorder = hc.border;
            final arrowBtnIconColor = hc.textPrimary;
            final String displayStatus;
            if (!m.hasLocation || m.locationUpdatedAt == null) {
              displayStatus = context.tr('maps.locationUnavailable');
            } else {
              final seconds = DateTime.now()
                  .difference(m.locationUpdatedAt!)
                  .inSeconds;
              if (seconds <= 30) {
                displayStatus = 'Online';
              } else if (seconds <= 120) {
                displayStatus = context.tr('maps.lastSeenSecondsAgo', {
                  'seconds': seconds.toString(),
                });
              } else {
                displayStatus = context.tr('maps.notUpdated');
              }
            }

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
                      // Top Row: Avatar on Left, Member Name on Right
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
                                              ? [hc.surfaceSubtle, hc.surface]
                                              : [hc.primary, hc.primaryDark])
                                        : (isDark
                                              ? [hc.surfaceSubtle, hc.surface]
                                              : [hc.surfaceSubtle, hc.canvas]),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: isPendamping
                                        ? hc.accent
                                        : (isDark
                                              ? hc.border
                                              : hc.borderSubtle),
                                    width: 1.1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isPendamping
                                    ? Icon(
                                        Icons.shield_rounded,
                                        size: 17,
                                        color: isDark
                                            ? hc.accent
                                            : Colors.white,
                                      )
                                    : Text(
                                        initial,
                                        style: context.text.titleSmall.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? hc.textPrimary
                                              : hc.primary,
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
                                        ? hc.success
                                        : (m.hasLocation
                                              ? hc.warning
                                              : hc.border),
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

                          // Member Name (bold, 2 lines max, legible
                          Expanded(
                            child: Text(
                              m.name,
                              style: context.text.titleSmall.copyWith(
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

                      // Middle: Role Badge Pill
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
                          isPendamping
                              ? '👑 ${context.tr('maps.rolePetugas')}'
                              : context.tr('maps.roleJamaah'),
                          style: context.text.labelSmall.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: roleTextColor,
                          ),
                        ),
                      ),

                      // Bottom Row: Distance & Status on Left, Diagonal Arrow on Right
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Left side: Distance & Location Status on 2 separate lines (Never truncated!
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
                                        style: context.text.labelSmall.copyWith(
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
                                          ? hc.success
                                          : cardSubtextColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        displayStatus,
                                        style: context.text.labelSmall.copyWith(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: isOnline
                                              ? hc.success
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

                          // Right side: Circular Diagonal Arrow Button
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

  // 3. LEGACY JAMAAH CARD FALLBACK

  Widget _buildLegacyJamaahCard(BuildContext context) {
    final hc = context.hc;
    final isDark = hc.isDark;
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
                  color: hc.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: hc.accent.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  Icons.elderly_rounded,
                  color: isDark ? hc.accent : hc.primary,
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
                      style: context.text.titleMedium.copyWith(
                        color: hc.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${jamaah.shortLabel} • ${jamaah.distance >= 1000 ? '${(jamaah.distance / 1000).toStringAsFixed(jamaah.distance >= 100000 ? 0 : 1)}km' : '${jamaah.distance.toInt()}m'}',
                      style: context.text.bodySmall.copyWith(
                        color: hc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: hc.textMuted,
                onPressed: () => _dismissWithAnimation(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNavigate,
                icon: Icon(
                  Icons.directions_walk_rounded,
                  size: 20,
                  color: isDark ? hc.canvas : hc.accent,
                ),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.tr('maps.startNavigation'),
                    style: context.text.labelLarge.copyWith(
                      color: isDark ? hc.canvas : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? hc.accent : hc.primary,
                  foregroundColor: isDark ? hc.canvas : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    side: BorderSide(
                      color: isDark
                          ? hc.accent
                          : hc.accent.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
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
