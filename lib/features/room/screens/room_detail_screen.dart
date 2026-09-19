import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/admin_room_controller.dart';
import '../services/room_service.dart';
import '../widgets/room_qr_dialog.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final RoomService _roomService = RoomService();
  AdminRoomController? _adminController;

  RoomModel? _room;
  bool _isLoadingRoom = true;
  bool _isLoadingMembers = true;

  List<RoomMemberModel> _allMembers = [];
  StreamSubscription<RoomModel?>? _roomSub;
  StreamSubscription<List<RoomMemberModel>>? _membersSub;

  // Search & Filter State
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String _selectedFilter = 'Semua'; // 'Semua' | 'Jamaah' | 'Pendamping'

  // Pagination State
  int _currentPage = 1;
  int _limitPerPage = 8; // Default limit per page
  static const List<int> _availableLimits = [5, 8, 15];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    if (Get.isRegistered<AdminRoomController>()) {
      _adminController = Get.find<AdminRoomController>();
    }

    _resolveInitialRoom();

    // Start subscriptions safely after initial frame to prevent markNeedsBuild during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startSubscriptions();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }

  void _resolveInitialRoom() {
    final hajiCare = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;

    final resolvedRoom = (Get.arguments as RoomModel?) ??
        _adminController?.selectedRoom.value ??
        hajiCare?.activeRoom.value;

    if (resolvedRoom != null) {
      _room = resolvedRoom;
      _isLoadingRoom = false;
    } else {
      final roomId = hajiCare?.activeRoomId.value ?? hajiCare?.cachedRoomId;
      _isLoadingRoom = (roomId != null && roomId.isNotEmpty);
    }
  }

  void _startSubscriptions() {
    final hajiCare = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;

    final roomId = _room?.id ??
        hajiCare?.activeRoomId.value ??
        hajiCare?.cachedRoomId;

    if (roomId != null && roomId.isNotEmpty) {
      _subscribeToRoom(roomId);
      _subscribeToMembers(roomId);
    } else {
      if (mounted) {
        setState(() {
          _isLoadingRoom = false;
          _isLoadingMembers = false;
        });
      }
    }
  }

  void _subscribeToRoom(String roomId) {
    _roomSub?.cancel();
    _roomSub = _roomService.getRoomStream(roomId).listen((roomData) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (roomData != null) {
            _room = roomData;
          }
          _isLoadingRoom = false;
        });
      });
    }, onError: (e) {
      debugPrint('[RoomDetailScreen] Error listening to room: $e');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoadingRoom = false;
          });
        }
      });
    });
  }

  void _subscribeToMembers(String roomId) {
    _membersSub?.cancel();
    _membersSub = _roomService.getRoomMembersStream(roomId).listen((members) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _allMembers = members;
          _isLoadingMembers = false;

          final maxPages = _totalPages;
          if (_currentPage > maxPages) {
            _currentPage = maxPages.clamp(1, 999);
          }
        });

        // Sync with AdminRoomController safely if present
        if (_adminController != null) {
          _adminController!.roomMembers.value = members;
        }
      });
    }, onError: (e) {
      debugPrint('[RoomDetailScreen] Error listening to members: $e');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isLoadingMembers = false;
          });
        }
      });
    });
  }

  // ── Computed Getters ────────────────────────────────────────────────────────
  List<RoomMemberModel> get _filteredMembers {
    return _allMembers.where((m) {
      if (_selectedFilter == 'Jamaah' && !m.isJamaah) return false;
      if (_selectedFilter == 'Pendamping' && !m.isPendamping) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatches = m.name.toLowerCase().contains(q);
        final roleMatches = m.role.toLowerCase().contains(q);
        return nameMatches || roleMatches;
      }

      return true;
    }).toList();
  }

  int get _totalPages {
    final count = _filteredMembers.length;
    if (count == 0) return 1;
    return (count / _limitPerPage).ceil();
  }

  List<RoomMemberModel> get _pagedMembers {
    final list = _filteredMembers;
    final start = (_currentPage - 1) * _limitPerPage;
    if (start >= list.length) return [];
    final end = (start + _limitPerPage).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get _totalCount => _allMembers.length;
  int get _jamaahCount => _allMembers.where((m) => m.isJamaah).length;
  int get _pendampingCount => _allMembers.where((m) => m.isPendamping).length;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  bool _canManageMembers() {
    final hajiCare = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final isJamaah = hajiCare?.role == UserRole.jamaah;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isAdmin = hajiCare?.role == UserRole.admin;
    final isCreator = _room != null && _room!.createdBy == currentUid;

    return !isJamaah && (isAdmin || isCreator);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    // Loading State
    if (_isLoadingRoom && _room == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: headingColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Detail Room',
            style: AppTypography.headlineMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    // Room Not Found State
    if (_room == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: scaffoldBg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: headingColor),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Detail Room',
            style: AppTypography.headlineMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.room_preferences_outlined,
                    size: 38,
                    color: bodyColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Data Room Tidak Ditemukan',
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Anda belum tergabung dalam room manapun atau data room sedang tidak dapat dimuat.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final room = _room!;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: headingColor),
          tooltip: 'Kembali',
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.name,
              style: AppTypography.headlineMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Kode: ${room.code}',
              style: AppTypography.captionSmall.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(Icons.qr_code_2_rounded, color: primaryColor, size: 20),
            ),
            tooltip: 'Tampilkan QR Code Room',
            onPressed: () => RoomQrDialog.show(context, room: room),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          _subscribeToRoom(room.id);
          _subscribeToMembers(room.id);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            // ── 1. Hero Room Information Card ─────────────────────────────────
            AppCard(
              backgroundColor: cardBg,
              borderColor: isDark
                  ? AppColors.darkCardBorder
                  : primaryColor.withValues(alpha: 0.25),
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.card),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.15),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(Icons.meeting_room_rounded, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.sm + 2),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Informasi Ruang Pantau',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: headingColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                                Text(
                                  'Grup Maktab / Delegasi',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: bodyColor.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (room.isActive ? AppColors.statusSafe : bodyColor)
                                .withValues(alpha: isDark ? 0.20 : 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: (room.isActive ? AppColors.statusSafe : bodyColor)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: room.isActive ? AppColors.statusSafe : AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                room.isActive ? 'Aktif' : 'Nonaktif',
                                style: AppTypography.captionSmall.copyWith(
                                  color: room.isActive ? AppColors.statusSafe : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.key_rounded, size: 16, color: primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Kode Room:',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: bodyColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: room.code));
                                AppAlert.success(
                                  context,
                                  title: 'Kode Disalin',
                                  message: 'Kode room "${room.code}" berhasil disalin.',
                                );
                              },
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.10),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      room.code,
                                      style: AppTypography.titleSmall.copyWith(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.5,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.copy_rounded, size: 14, color: primaryColor),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        if ((room.maktab != null && room.maktab!.isNotEmpty) ||
                            (room.kloter != null && room.kloter!.isNotEmpty)) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (room.maktab != null && room.maktab!.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.hotel_rounded, size: 15, color: bodyColor.withValues(alpha: 0.7)),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Maktab: ${room.maktab}',
                                      style: AppTypography.captionSmall.copyWith(
                                        color: headingColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              if (room.kloter != null && room.kloter!.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(Icons.flight_takeoff_rounded, size: 15, color: bodyColor.withValues(alpha: 0.7)),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Kloter: ${room.kloter}',
                                      style: AppTypography.captionSmall.copyWith(
                                        color: headingColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 10),

                        if (room.createdAt != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.event_note_rounded, size: 16, color: bodyColor.withValues(alpha: 0.7)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Dibuat Pada:',
                                    style: AppTypography.bodySmall.copyWith(color: bodyColor),
                                  ),
                                ],
                              ),
                              Text(
                                _formatDate(room.createdAt),
                                style: AppTypography.bodySmall.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: AppSpacing.md),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                            label: const Text(
                              'Lihat & Bagikan QR Code Room',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                            onPressed: () => RoomQrDialog.show(context, room: room),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Member Breakdown Stat Strip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle)
                          .withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppRadius.card),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatSummaryItem(
                          label: 'Total Anggota',
                          value: '$_totalCount',
                          color: headingColor,
                          icon: Icons.groups_rounded,
                        ),
                        Container(
                          height: 28,
                          width: 1,
                          color: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
                        ),
                        _buildStatSummaryItem(
                          label: 'Jamaah',
                          value: '$_jamaahCount',
                          color: AppColors.emeraldIslamic,
                          icon: Icons.person_rounded,
                        ),
                        Container(
                          height: 28,
                          width: 1,
                          color: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
                        ),
                        _buildStatSummaryItem(
                          label: 'Pendamping',
                          value: '$_pendampingCount',
                          color: const Color(0xFF1D4ED8),
                          icon: Icons.health_and_safety_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2. Search Bar & Filter Chips ──────────────────────────────────
            _buildSearchAndFilters(context, cardBg, headingColor, bodyColor, primaryColor, isDark),

            const SizedBox(height: AppSpacing.md),

            // ── 3. Pagination Summary & Limit Selector ────────────────────────
            _buildPaginationHeader(headingColor, bodyColor, primaryColor, isDark),

            const SizedBox(height: AppSpacing.sm),

            // ── 4. Members List (Paginated) ───────────────────────────────────
            _buildMembersList(context, room, cardBg, headingColor, bodyColor, primaryColor, isDark),

            const SizedBox(height: AppSpacing.md),

            // ── 5. Pagination Footer Navigation ───────────────────────────────
            if (_filteredMembers.isNotEmpty)
              _buildPaginationFooter(cardBg, headingColor, bodyColor, primaryColor, isDark),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SEARCH & FILTER CHIPS WIDGET
  // ===========================================================================
  Widget _buildSearchAndFilters(
    BuildContext context,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 20,
                color: _searchQuery.isNotEmpty
                    ? primaryColor
                    : bodyColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: AppTypography.bodyMedium.copyWith(
                    color: headingColor,
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau peran anggota...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: bodyColor.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: bodyColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChipItem(
                label: 'Semua',
                count: _totalCount,
                isSelected: _selectedFilter == 'Semua',
                activeColor: primaryColor,
                headingColor: headingColor,
                bodyColor: bodyColor,
                cardBg: cardBg,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Semua';
                    _currentPage = 1;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChipItem(
                label: 'Jamaah',
                count: _jamaahCount,
                isSelected: _selectedFilter == 'Jamaah',
                activeColor: AppColors.emeraldIslamic,
                headingColor: headingColor,
                bodyColor: bodyColor,
                cardBg: cardBg,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Jamaah';
                    _currentPage = 1;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChipItem(
                label: 'Pendamping',
                count: _pendampingCount,
                isSelected: _selectedFilter == 'Pendamping',
                activeColor: const Color(0xFF1D4ED8),
                headingColor: headingColor,
                bodyColor: bodyColor,
                cardBg: cardBg,
                isDark: isDark,
                onTap: () {
                  setState(() {
                    _selectedFilter = 'Pendamping';
                    _currentPage = 1;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChipItem({
    required String label,
    required int count,
    required bool isSelected,
    required Color activeColor,
    required Color headingColor,
    required Color bodyColor,
    required Color cardBg,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.25 : 0.12)
                : cardBg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? AppColors.darkOutlineVariant
                      : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : headingColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: isDark ? 0.40 : 0.20)
                      : bodyColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? activeColor : bodyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PAGINATION HEADER (SUMMARY & LIMIT CHIPS)
  // ===========================================================================
  Widget _buildPaginationHeader(
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
    bool isDark,
  ) {
    final total = _filteredMembers.length;
    final start = total == 0 ? 0 : (_currentPage - 1) * _limitPerPage + 1;
    final end = (start + _limitPerPage - 1).clamp(0, total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          total == 0
              ? 'Tidak ada anggota'
              : 'Menampilkan $start-$end dari $total anggota',
          style: AppTypography.captionSmall.copyWith(
            color: bodyColor.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Limit:',
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            ..._availableLimits.map((lim) {
              final isCurrentLimit = _limitPerPage == lim;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _limitPerPage = lim;
                    _currentPage = 1;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCurrentLimit
                        ? primaryColor.withValues(alpha: isDark ? 0.25 : 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isCurrentLimit
                          ? primaryColor
                          : bodyColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '$lim',
                    style: TextStyle(
                      color: isCurrentLimit ? primaryColor : bodyColor,
                      fontSize: 10.5,
                      fontWeight: isCurrentLimit ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // MEMBERS LIST (PAGINATED)
  // ===========================================================================
  Widget _buildMembersList(
    BuildContext context,
    RoomModel room,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
    bool isDark,
  ) {
    if (_isLoadingMembers) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    final pagedList = _pagedMembers;

    if (pagedList.isEmpty) {
      if (_searchQuery.isNotEmpty || _selectedFilter != 'Semua') {
        return AppCard(
          backgroundColor: cardBg,
          borderColor: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.md,
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 42,
                    color: bodyColor.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tidak Ada Anggota Sesuai Kriteria',
                    style: AppTypography.titleSmall.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Tidak ditemukan anggota dengan kata kunci "$_searchQuery".'
                        : 'Belum ada anggota dengan kategori "$_selectedFilter".',
                    textAlign: TextAlign.center,
                    style: AppTypography.captionSmall.copyWith(
                      color: bodyColor.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedFilter = 'Semua';
                        _currentPage = 1;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset Filter & Pencarian'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return AppCard(
        backgroundColor: cardBg,
        borderColor: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    size: 32,
                    color: primaryColor.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Belum Ada Anggota yang Bergabung',
                  style: AppTypography.titleSmall.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bagikan kode atau QR Code room ini ke jamaah dan pendamping agar dapat segera bergabung.',
                  textAlign: TextAlign.center,
                  style: AppTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.8),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label: const Text('Buka QR Code Room', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => RoomQrDialog.show(context, room: room),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canManage = _canManageMembers();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pagedList.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final member = pagedList[index];
        return _MemberTile(
          room: room,
          member: member,
          cardBg: cardBg,
          headingColor: headingColor,
          bodyColor: bodyColor,
          primaryColor: primaryColor,
          isDark: isDark,
          canManage: canManage,
          onTap: () => _showMemberDetailModal(context, member, room, canManage),
        );
      },
    );
  }

  // ===========================================================================
  // PAGINATION CONTROLS FOOTER
  // ===========================================================================
  Widget _buildPaginationFooter(
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
    bool isDark,
  ) {
    final totalPages = _totalPages;
    if (totalPages <= 1) return const SizedBox.shrink();

    final canGoPrev = _currentPage > 1;
    final canGoNext = _currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: canGoPrev
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            tooltip: 'Halaman Sebelumnya',
            color: headingColor,
            disabledColor: bodyColor.withValues(alpha: 0.25),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Halaman $_currentPage dari $totalPages',
                style: AppTypography.captionSmall.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: canGoNext
                ? () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            tooltip: 'Halaman Berikutnya',
            color: headingColor,
            disabledColor: bodyColor.withValues(alpha: 0.25),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MEMBER DETAIL MODAL SHEET
  // ===========================================================================
  void _showMemberDetailModal(
    BuildContext context,
    RoomMemberModel member,
    RoomModel room,
    bool canManage,
  ) {
    final isDark = AppColors.isDark(context);
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: bodyColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: member.isPendamping
                            ? const Color(0xFF1D4ED8).withValues(alpha: 0.15)
                            : (member.isJamaah
                                ? AppColors.emeraldIslamic.withValues(alpha: 0.15)
                                : primaryColor.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: member.isPendamping
                                ? const Color(0xFF1D4ED8)
                                : (member.isJamaah
                                    ? AppColors.emeraldIslamic
                                    : primaryColor),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: member.isPendamping
                                  ? const Color(0xFF1D4ED8).withValues(alpha: 0.12)
                                  : (member.isJamaah
                                      ? AppColors.emeraldIslamic.withValues(alpha: 0.12)
                                      : primaryColor.withValues(alpha: 0.12)),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              member.role.toUpperCase(),
                              style: TextStyle(
                                color: member.isPendamping
                                    ? const Color(0xFF1D4ED8)
                                    : (member.isJamaah
                                        ? AppColors.emeraldIslamic
                                        : primaryColor),
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildModalInfoTile(
                  icon: Icons.access_time_rounded,
                  label: 'Status Kehadiran',
                  value: member.getLocationStatus(),
                  color: primaryColor,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                ),
                const SizedBox(height: 10),
                _buildModalInfoTile(
                  icon: Icons.calendar_today_rounded,
                  label: 'Tanggal Bergabung',
                  value: member.joinedAt != null ? _formatDate(member.joinedAt) : 'Tidak diketahui',
                  color: primaryColor,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                ),
                if (member.hasLocation) ...[
                  const SizedBox(height: 10),
                  _buildModalInfoTile(
                    icon: Icons.location_on_rounded,
                    label: 'Koordinat Lokasi',
                    value: '${member.latitude!.toStringAsFixed(5)}, ${member.longitude!.toStringAsFixed(5)}',
                    color: primaryColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                  ),
                ],

                const SizedBox(height: 20),

                Row(
                  children: [
                    if (member.hasLocation)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (Get.isRegistered<DashboardController>()) {
                              Get.find<DashboardController>().changeTab(1);
                              Get.back();
                            }
                          },
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text('Lihat di Peta'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (member.hasLocation && canManage && member.isJamaah)
                      const SizedBox(width: 10),
                    if (canManage && member.isJamaah)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleRemoveMember(context, member, room);
                          },
                          icon: const Icon(Icons.person_remove_rounded, size: 16),
                          label: const Text('Keluarkan'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.7),
                fontSize: 10.5,
              ),
            ),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: headingColor,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleRemoveMember(BuildContext context, RoomMemberModel member, RoomModel room) {
    HapticFeedback.mediumImpact();
    AppAlert.confirm(
      context,
      title: 'Keluarkan Jamaah?',
      message: 'Apakah Anda yakin ingin mengeluarkan "${member.name}" dari room pantau ini?',
      confirmText: 'Keluarkan',
      cancelText: 'Batal',
      isDestructive: true,
      onConfirm: () async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          final actorUid = user?.uid ?? 'petugas';
          final actorName = user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!
              : 'Petugas Maktab';

          await _roomService.removeJamaahFromRoom(
            roomId: room.id,
            jamaahUid: member.uid,
            actorUid: actorUid,
            actorRole: 'pendamping',
            actorName: actorName,
          );

          if (context.mounted) {
            AppAlert.success(
              context,
              title: 'Jamaah Dikeluarkan',
              message: '${member.name} berhasil dikeluarkan dari room.',
            );
          }
        } catch (e) {
          if (context.mounted) {
            AppAlert.error(
              context,
              title: 'Gagal Mengeluarkan Jamaah',
              message: e.toString().replaceAll('Exception: ', ''),
            );
          }
        }
      },
    );
  }

  Widget _buildStatSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// MEMBER TILE ITEM
// =============================================================================
class _MemberTile extends StatelessWidget {
  final RoomModel room;
  final RoomMemberModel member;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final Color primaryColor;
  final bool isDark;
  final bool canManage;
  final VoidCallback onTap;

  const _MemberTile({
    required this.room,
    required this.member,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.primaryColor,
    required this.isDark,
    required this.canManage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeBg;
    Color badgeTextColor;
    String roleLabel;
    IconData roleIcon;

    if (member.isPendamping) {
      badgeBg = isDark
          ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
          : const Color(0xFFE0E7FF);
      badgeTextColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8);
      roleLabel = 'Pendamping';
      roleIcon = Icons.health_and_safety_rounded;
    } else if (member.isJamaah) {
      badgeBg = isDark
          ? AppColors.emeraldIslamic.withValues(alpha: 0.25)
          : AppColors.statusSafe.withValues(alpha: 0.12);
      badgeTextColor = isDark ? const Color(0xFF6EE7B7) : AppColors.statusSafe;
      roleLabel = 'Jamaah';
      roleIcon = Icons.person_rounded;
    } else {
      badgeBg = primaryColor.withValues(alpha: isDark ? 0.25 : 0.15);
      badgeTextColor = primaryColor;
      roleLabel = 'Admin';
      roleIcon = Icons.admin_panel_settings_rounded;
    }

    final initial = member.name.trim().isNotEmpty ? member.name.trim()[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: AppCard(
          backgroundColor: cardBg,
          borderColor: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: badgeTextColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      member.name,
                      style: AppTypography.titleSmall.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (member.hasLocation) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.statusPositive,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            member.joinedAt != null
                                ? 'Bergabung: ${member.joinedAt!.day}/${member.joinedAt!.month}/${member.joinedAt!.year}'
                                : 'Baru saja bergabung',
                            style: AppTypography.captionSmall.copyWith(
                              color: bodyColor.withValues(alpha: 0.70),
                              fontSize: 10.5,
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
              const SizedBox(width: AppSpacing.xs),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: badgeTextColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(roleIcon, size: 12, color: badgeTextColor),
                    const SizedBox(width: 4),
                    Text(
                      roleLabel,
                      style: AppTypography.captionSmall.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: bodyColor.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
