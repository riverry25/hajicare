import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/filter_chip_item.dart';
import '../../../../core/state/hajicare_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import 'map_voice_search_sheet.dart';

class MapTopHeader extends StatefulWidget {
  final List<FilterChipItem> filters;
  final int selectedFilter;
  final ValueChanged<int> onFilterSelected;
  final VoidCallback onSosPressed;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearSearch;
  final TextEditingController? searchController;
  final bool isLiveTracking;
  final double gpsAccuracy;
  final String? roomName;
  final String? memberSummary;
  final String? nearestInfo;
  final VoidCallback? onRoomTap;

  const MapTopHeader({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.onSosPressed,
    this.onSearchChanged,
    this.onClearSearch,
    this.searchController,
    this.isLiveTracking = false,
    this.gpsAccuracy = 0.0,
    this.roomName,
    this.memberSummary,
    this.nearestInfo,
    this.onRoomTap,
  });

  @override
  State<MapTopHeader> createState() => _MapTopHeaderState();
}

class _MapTopHeaderState extends State<MapTopHeader> {
  TextEditingController? _internalSearchCtrl;
  TextEditingController get _effectiveSearchCtrl =>
      widget.searchController ?? (_internalSearchCtrl ??= TextEditingController());
  bool _hasSearchText = false;

  void _onSearchTextChanged() {
    final hasText = _effectiveSearchCtrl.text.trim().isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() {
        _hasSearchText = hasText;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _effectiveSearchCtrl.addListener(_onSearchTextChanged);
    _hasSearchText = _effectiveSearchCtrl.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(MapTopHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController?.removeListener(_onSearchTextChanged);
      _effectiveSearchCtrl.addListener(_onSearchTextChanged);
      _hasSearchText = _effectiveSearchCtrl.text.trim().isNotEmpty;
    }
  }

  @override
  void dispose() {
    _effectiveSearchCtrl.removeListener(_onSearchTextChanged);
    _internalSearchCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final topSafeArea = MediaQuery.of(context).padding.top;
    final hasRoom =
        widget.roomName != null && widget.roomName!.trim().isNotEmpty;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: Container(
          padding: EdgeInsets.only(
            top: topSafeArea + 6,
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface.withValues(alpha: 0.95)
                : AppColors.canvasCream.withValues(alpha: 0.97),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.espressoDark.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── ROW 1: STATUS & HUB ROW (GPS BADGE, ROOM INFO, SOS) ──
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    // GPS Tracking Status Pill
                    _buildGpsStatusPill(isDark),

                    const SizedBox(width: 8),

                    // Contextual Active Room Pill (if in a room)
                    if (hasRoom)
                      Expanded(child: _buildRoomHubPill(context, isDark))
                    else
                      const Spacer(),

                    const SizedBox(width: 8),

                    // Emergency SOS Quick Button
                    _buildSosButton(),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── ROW 2: SLEEK INTERACTIVE SEARCH BAR ──
              _buildSearchBar(context, isDark),

              const SizedBox(height: 8),

              // ── ROW 3: CATEGORY & ROLE FILTER CHIPS ──
              _buildFilterChips(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ROW 1 WIDGETS
  // ===========================================================================

  Widget _buildGpsStatusPill(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : AppColors.goldLight.withValues(alpha: 0.40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnimatedPingDot(color: AppColors.statusPositive, size: 7),
          const SizedBox(width: 6),
          Text(
            widget.gpsAccuracy > 0
                ? 'GPS ±${widget.gpsAccuracy.round()}m'
                : 'GPS Aktif',
            style: AppTypography.captionSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextHeading
                  : AppColors.espressoDark,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomHubPill(BuildContext context, bool isDark) {
    final summaryText =
        widget.nearestInfo != null && widget.nearestInfo!.isNotEmpty
        ? widget.nearestInfo!
        : (widget.memberSummary != null && widget.memberSummary!.isNotEmpty
              ? widget.memberSummary!.split('·').first.trim()
              : 'Terhubung');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onRoomTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.goldPrimary.withValues(alpha: 0.14)
                : AppColors.goldLight.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isDark
                  ? AppColors.goldPrimary.withValues(alpha: 0.40)
                  : AppColors.goldPrimary.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldPrimary.withValues(
                  alpha: isDark ? 0.08 : 0.05,
                ),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.meeting_room_rounded,
                size: 13,
                color: isDark ? AppColors.goldPrimary : AppColors.espressoDark,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: widget.roomName!,
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.espressoDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text: ' • $summaryText',
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark ? Colors.white70 : AppColors.textBody,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: isDark ? AppColors.goldPrimary : AppColors.espressoDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSosButton() {
    int activeCount = 0;
    if (Get.isRegistered<HajiCareController>()) {
      activeCount = Get.find<HajiCareController>().activeSosCount.value;
    }

    final hasActiveSos = activeCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onSosPressed,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: hasActiveSos
                  ? const [Color(0xFFFF1744), Color(0xFFD50000)]
                  : const [Color(0xFFE53935), Color(0xFFC62828)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: (hasActiveSos ? const Color(0xFFFF1744) : const Color(0xFFE53935))
                    .withValues(alpha: hasActiveSos ? 0.65 : 0.38),
                blurRadius: hasActiveSos ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emergency_rounded,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                hasActiveSos ? 'SOS ($activeCount)' : 'SOS',
                style: AppTypography.captionSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ROW 2: SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.92)
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.goldLight.withValues(alpha: 0.40),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Icon(
            Icons.search_rounded,
            color: isDark ? primaryColor : headingColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _effectiveSearchCtrl,
              onChanged: widget.onSearchChanged,
              style: AppTypography.bodySmall.copyWith(
                color: headingColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari lokasi, posko, maktab...',
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : AppColors.textMuted,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_hasSearchText)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: isDark ? Colors.white70 : AppColors.textMuted,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              tooltip: 'Hapus Pencarian',
              onPressed: () {
                _effectiveSearchCtrl.clear();
                widget.onClearSearch?.call();
                widget.onSearchChanged?.call('');
              },
            ),
          // Google Maps Voice Search Button
          IconButton(
            icon: Icon(
              Icons.mic_rounded,
              size: 20,
              color: primaryColor,
            ),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Pencarian Suara',
            onPressed: () async {
              final voiceQuery = await MapVoiceSearchSheet.show(context);
              if (voiceQuery != null && voiceQuery.trim().isNotEmpty) {
                _effectiveSearchCtrl.text = voiceQuery.trim();
                widget.onSearchChanged?.call(voiceQuery.trim());
              }
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  // ===========================================================================
  // ROW 3: FILTER CHIPS
  // ===========================================================================

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final filter = widget.filters[index];
          final isSelected = index == widget.selectedFilter;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => widget.onFilterSelected(index),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? AppColors.goldPrimary
                            : AppColors.espressoDark)
                      : (isDark
                            ? AppColors.darkSurfaceContainer.withValues(
                                alpha: 0.70,
                              )
                            : AppColors.surfaceWhite),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                              ? AppColors.goldPrimary
                              : AppColors.goldPrimary.withValues(alpha: 0.6))
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.goldLight.withValues(alpha: 0.35)),
                    width: isSelected ? 1.2 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                (isDark
                                        ? AppColors.goldPrimary
                                        : AppColors.espressoDark)
                                    .withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.12 : 0.02,
                            ),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter.icon != null) ...[
                      Icon(
                        filter.icon,
                        size: 14,
                        color: isSelected
                            ? (isDark
                                  ? AppColors.espressoDark
                                  : AppColors.goldPrimary)
                            : (isDark
                                  ? AppColors.darkTextBody
                                  : AppColors.espressoDark.withValues(
                                      alpha: 0.7,
                                    )),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      filter.label,
                      style: AppTypography.captionSmall.copyWith(
                        color: isSelected
                            ? (isDark ? AppColors.espressoDark : Colors.white)
                            : (isDark
                                  ? Colors.white70
                                  : AppColors.espressoDark),
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
