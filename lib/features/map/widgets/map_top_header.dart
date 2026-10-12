import '../../../core/locales/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/filter_chip_item.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/hajicare_controller.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import 'map_voice_search_sheet.dart';

class MapTopHeader extends StatefulWidget {
  final List<FilterChipItem> filters;
  final int selectedFilter;
  final ValueChanged<int> onFilterSelected;
  final VoidCallback onSosPressed;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClearSearch;
  final VoidCallback? onSearchFocused;
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
    this.onSearchFocused,
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
  final FocusNode _focusNode = FocusNode();
  TextEditingController? _internalSearchCtrl;
  TextEditingController get _effectiveSearchCtrl =>
      widget.searchController ??
      (_internalSearchCtrl ??= TextEditingController());
  bool _hasSearchText = false;

  void _onSearchTextChanged() {
    final hasText = _effectiveSearchCtrl.text.trim().isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() {
        _hasSearchText = hasText;
      });
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _effectiveSearchCtrl.text.trim().isEmpty) {
      widget.onSearchFocused?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
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
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _effectiveSearchCtrl.removeListener(_onSearchTextChanged);
    _internalSearchCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.hc.isDark;
    final topSafeArea = MediaQuery.of(context).padding.top;
    final hasRoom =
        widget.roomName != null && widget.roomName!.trim().isNotEmpty;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: RepaintBoundary(
        child: Container(
          padding: EdgeInsets.only(top: topSafeArea + 6, bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (isDark ? Colors.black : context.hc.canvas).withValues(
                  alpha: isDark ? 0.35 : 0.20,
                ),
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
                      _buildGpsStatusPill(context, isDark),

                      const SizedBox(width: 8),

                      // Contextual Active Room Pill (if in a room)
                      if (hasRoom)
                        Expanded(child: _buildRoomHubPill(context, isDark))
                      else
                        const Spacer(),

                      const SizedBox(width: 8),

                      // Emergency SOS Quick Button
                      Get.isRegistered<HajiCareController>()
                          ? Obx(() => _buildSosButton(context))
                          : _buildSosButton(context),
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

  Widget _buildGpsStatusPill(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.hc.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.hc.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: context.hc.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedPingDot(color: context.hc.success, size: 7),
          const SizedBox(width: 6),
          Text(
            widget.gpsAccuracy > 0
                ? 'GPS ±${widget.gpsAccuracy.round()}m'
                : context.tr('maps.gpsActive'),
            style: TextStyle(
              color: context.hc.textPrimary,
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
              : context.tr('room.connected'));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onRoomTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.hc.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: context.hc.accent.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.hc.shadow,
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
                color: context.hc.accent,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: widget.roomName!,
                        style: TextStyle(
                          color: context.hc.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      TextSpan(
                        text: ' • $summaryText',
                        style: TextStyle(
                          color: context.hc.textSecondary,
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
                color: context.hc.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSosButton(BuildContext context) {
    int activeCount = 0;
    bool anyActive = false;
    if (Get.isRegistered<HajiCareController>()) {
      final ctrl = Get.find<HajiCareController>();
      activeCount = ctrl.activeSosCount.value;
      anyActive = ctrl.anySosActive;
    }

    final hasActiveSos = activeCount > 0 || anyActive;

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
                  ? [context.hc.danger, context.hc.dangerDark]
                  : [
                      context.hc.brand.withValues(alpha: 0.85),
                      context.hc.brandDark.withValues(alpha: 0.95),
                    ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: hasActiveSos
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.22),
              width: hasActiveSos ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasActiveSos
                    ? Icons.warning_amber_rounded
                    : Icons.emergency_rounded,
                color: hasActiveSos ? Colors.white : Colors.white70,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                hasActiveSos
                    ? (activeCount > 0
                          ? 'SOS ($activeCount)'
                          : 'SOS ${context.tr("sosActiveBadge")}')
                    : 'SOS',
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
    String displayName = context.tr('maps.pilgrims');
    String? photoUrl;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        displayName = user.displayName ?? context.tr('maps.pilgrims');
        photoUrl = user.photoURL;
      }
    } catch (_) {}
    final initialLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'H';

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: context.hc.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.hc.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: context.hc.shadow,
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Elegant Brand/Accent Location Pin Icon
          Container(
            margin: const EdgeInsets.only(left: 14, right: 10),
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  context.hc.brand,
                  context.hc.accent,
                  context.hc.success,
                  context.hc.info,
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
              focusNode: _focusNode,
              onTap: () {
                if (_effectiveSearchCtrl.text.trim().isEmpty) {
                  widget.onSearchFocused?.call();
                }
              },
              onChanged: widget.onSearchChanged,
              style: TextStyle(
                color: context.hc.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: context.tr('maps.searchPlaceholder'),
                hintStyle: TextStyle(
                  color: context.hc.textTertiary,
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
              color: context.hc.textSecondary,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: context.tr('maps.clearSearch'),
              onPressed: () {
                _effectiveSearchCtrl.clear();
                widget.onClearSearch?.call();
                widget.onSearchChanged?.call('');
              },
            ),

          // Voice Search Button
          IconButton(
            icon: Icon(Icons.mic_rounded, size: 22, color: context.hc.brand),
            splashRadius: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: context.tr('maps.voiceSearchTitle'),
            onPressed: () async {
              final voiceQuery = await MapVoiceSearchSheet.show(context);
              if (voiceQuery != null && voiceQuery.trim().isNotEmpty) {
                _effectiveSearchCtrl.text = voiceQuery.trim();
                widget.onSearchChanged?.call(voiceQuery.trim());
              }
            },
          ),

          // User Profile Avatar
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.profile),
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10, left: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    context.hc.accent,
                    context.hc.accent.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: context.hc.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: context.hc.shadow,
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
                            style: TextStyle(
                              color: context.hc.onPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initialLetter,
                          style: TextStyle(
                            color: context.hc.onPrimary,
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
                      ? context.hc.brand.withValues(alpha: isDark ? 0.25 : 0.12)
                      : context.hc.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isSelected ? context.hc.brand : context.hc.border,
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
                            ? context.hc.brand
                            : _getCategoryIconColor(
                                context,
                                filter.label,
                                isDark,
                              ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      filter.label,
                      style: TextStyle(
                        color: isSelected
                            ? context.hc.brand
                            : context.hc.textPrimary,
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

  Color _getCategoryIconColor(BuildContext context, String label, bool isDark) {
    switch (label.toLowerCase()) {
      case 'semua':
        return context.hc.brand;
      case 'jamaah':
        return context.hc.success;
      case 'pendamping':
        return context.hc.accent;
      case 'posko medis':
        return context.hc.danger;
      case 'toilet & wudhu':
        return context.hc.info;
      case 'maktab':
        return context.hc.warning;
      case 'pos pantau':
        return context.hc.accent;
      default:
        return context.hc.textSecondary;
    }
  }
}
