import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/filter_chip_item.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/hajicare_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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
            bottom: 8,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? Colors.black : Colors.white)
                    .withValues(alpha: isDark ? 0.35 : 0.20),
                Colors.transparent,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── ROW 1: FLOATING STATUS & HUB (GPS BADGE, ROOM INFO, SOS) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
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
              ),

              const SizedBox(height: 8),

              // ── ROW 2: GOOGLE MAPS STYLE FLOATING SEARCH BAR ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSearchBar(context, isDark),
              ),

              const SizedBox(height: 9),

              // ── ROW 3: FLOATING CATEGORY & ROLE FILTER CHIPS ──
              _buildFilterChips(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ROW 1 WIDGETS (FLOATING OVER MAP)
  // ===========================================================================

  Widget _buildGpsStatusPill(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFDADCE0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF3C4043),
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
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isDark
                  ? AppColors.goldPrimary.withValues(alpha: 0.50)
                  : AppColors.goldPrimary.withValues(alpha: 0.40),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.30 : 0.08,
                ),
                blurRadius: 6,
                offset: const Offset(0, 2),
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
                        style: TextStyle(
                          color: isDark
                              ? AppColors.goldPrimary
                              : AppColors.espressoDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text: ' • $summaryText',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF5F6368),
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
                style: const TextStyle(
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
  // ROW 2: GOOGLE MAPS STYLE FLOATING SEARCH BAR
  // ===========================================================================

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    String displayName = 'Jamaah';
    String? photoUrl;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        displayName = user.displayName ?? 'Jamaah';
        photoUrl = user.photoURL;
      }
    } catch (_) {}
    final initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H';

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFE8EAED),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Multi-color Google Maps style Location Pin Icon
          Container(
            margin: const EdgeInsets.only(left: 14, right: 10),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Color(0xFFEA4335), // Google Red
                  Color(0xFFFBBC05), // Google Yellow
                  Color(0xFF34A853), // Google Green
                  Color(0xFF4285F4), // Google Blue
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(bounds),
              child: const Icon(
                Icons.location_on_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),

          // Search Location Text Field
          Expanded(
            child: TextField(
              controller: _effectiveSearchCtrl,
              onChanged: widget.onSearchChanged,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF202124),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search Location...',
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.45)
                      : const Color(0xFF5F6368),
                  fontSize: 14,
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
              color: isDark ? Colors.white70 : const Color(0xFF5F6368),
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Hapus Pencarian',
              onPressed: () {
                _effectiveSearchCtrl.clear();
                widget.onClearSearch?.call();
                widget.onSearchChanged?.call('');
              },
            ),

          // Google Maps Blue Voice Search Button
          IconButton(
            icon: const Icon(
              Icons.mic_rounded,
              size: 22,
              color: Color(0xFF1A73E8), // Google Maps Blue
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

          // Google Maps User Profile Avatar
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.profile),
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10, left: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFF8C6D23)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipOval(
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            initialLetter,
                            style: const TextStyle(
                              color: Color(0xFF1E140A),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initialLetter,
                          style: const TextStyle(
                            color: Color(0xFF1E140A),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
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

  // ===========================================================================
  // ROW 3: FLOATING CATEGORY & ROLE FILTER CHIPS
  // ===========================================================================

  Widget _buildFilterChips(BuildContext context, bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                  horizontal: 13,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? const Color(0xFF1E3A5F)
                            : const Color(0xFFE8F0FE)) // Google Maps active soft blue pill
                      : (isDark
                            ? AppColors.darkSurface
                            : Colors.white), // Floating pure white pill
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected
                        ? (isDark
                              ? const Color(0xFF8AB4F8)
                              : const Color(0xFF1A73E8))
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFDADCE0)),
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter.icon != null) ...[
                      Icon(
                        filter.icon,
                        size: 15,
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF8AB4F8)
                                  : const Color(0xFF1A73E8))
                            : _getCategoryIconColor(filter.label, isDark),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      filter.label,
                      style: TextStyle(
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF8AB4F8)
                                  : const Color(0xFF1A73E8))
                            : (isDark
                                  ? Colors.white
                                  : const Color(0xFF3C4043)),
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12.5,
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

  Color _getCategoryIconColor(String label, bool isDark) {
    switch (label.toLowerCase()) {
      case 'semua':
        return const Color(0xFF1A73E8); // Google Blue
      case 'jamaah':
        return const Color(0xFF1E8E3E); // Google Green
      case 'pendamping':
        return const Color(0xFFD4AF37); // Warm Gold
      case 'posko medis':
        return const Color(0xFFD93025); // Google Red
      case 'toilet & wudhu':
        return const Color(0xFF129990); // Cyan / Teal
      case 'maktab':
        return const Color(0xFFE37400); // Amber / Orange
      case 'pos pantau':
        return const Color(0xFF9334E6); // Purple
      default:
        return isDark ? Colors.white70 : const Color(0xFF5F6368);
    }
  }
}
