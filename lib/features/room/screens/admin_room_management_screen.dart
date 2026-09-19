import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/hajicare_header.dart';
import '../controllers/admin_room_controller.dart';
import '../models/room_model.dart';
import '../widgets/room_qr_dialog.dart';

class AdminRoomManagementScreen extends StatefulWidget {
  const AdminRoomManagementScreen({super.key});

  @override
  State<AdminRoomManagementScreen> createState() =>
      _AdminRoomManagementScreenState();
}

class _AdminRoomManagementScreenState extends State<AdminRoomManagementScreen> {
  late final AdminRoomController controller;
  late final TextEditingController _searchController;
  String _statusFilter = 'all'; // 'all', 'active', 'inactive', 'sos'
  String _sortBy = 'newest'; // 'newest', 'name', 'jamaah', 'sos'

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminRoomController>()
        ? Get.find<AdminRoomController>()
        : Get.put(AdminRoomController());
    _searchController = TextEditingController(
      text: controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RoomModel> _getProcessedRooms() {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = controller.rooms.where((room) {
      final matchesSearch =
          query.isEmpty ||
          room.name.toLowerCase().contains(query) ||
          room.code.toLowerCase().contains(query);

      final sosCount = controller.getRoomSosCount(room.id);
      final matchesFilter =
          _statusFilter == 'all' ||
          (_statusFilter == 'active' && room.isActive) ||
          (_statusFilter == 'inactive' && !room.isActive) ||
          (_statusFilter == 'sos' && sosCount > 0);

      return matchesSearch && matchesFilter;
    }).toList();

    switch (_sortBy) {
      case 'name':
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'jamaah':
        filtered.sort((a, b) {
          final countA = controller.getRoomJamaahCount(a.id);
          final countB = controller.getRoomJamaahCount(b.id);
          return countB.compareTo(countA);
        });
        break;
      case 'sos':
        filtered.sort((a, b) {
          final countA = controller.getRoomSosCount(a.id);
          final countB = controller.getRoomSosCount(b.id);
          return countB.compareTo(countA);
        });
        break;
      case 'newest':
      default:
        filtered.sort((a, b) {
          final timeA = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: HajiCareHeader(
        title: 'Kelola Room Pantau',
        subtitle: 'Delegasi & Monitoring Maktab Jamaah',
        icon: Icons.meeting_room_rounded,
        showBackButton: true,
        actions: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: Icon(Icons.sync_rounded, color: headingColor),
            tooltip: 'Sinkronisasi Stream Data',
            onPressed: () {
              HapticFeedback.lightImpact();
              controller.subscribeToAllStreams();
              AppAlert.info(
                context,
                title: 'Menyinkronkan',
                message: 'Memperbarui data kamar dan anggota secara realtime.',
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showCreateRoomSheet(context, controller);
        },
        backgroundColor: primaryColor,
        foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Buat Room Baru',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          controller.subscribeToAllStreams();
          await Future.delayed(const Duration(milliseconds: 600));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── 1. KPI Overview Summary Card ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenEdgeGutter,
                  AppSpacing.sm,
                  AppSpacing.screenEdgeGutter,
                  AppSpacing.sm,
                ),
                child: _buildOverviewHeader(
                  context,
                  isDark,
                  cardBg,
                  headingColor,
                  bodyColor,
                  primaryColor,
                ),
              ),
            ),

            // ── 2. Search, Filter Chips & Sort Controls ──────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenEdgeGutter,
                ),
                child: Column(
                  children: [
                    _buildSearchBar(
                      context,
                      isDark,
                      cardBg,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildFilterAndSortRow(
                      context,
                      isDark,
                      cardBg,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                  ],
                ),
              ),
            ),

            // ── 3. Room List or Dedicated Empty State ────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenEdgeGutter,
                0,
                AppSpacing.screenEdgeGutter,
                100, // Space for FAB
              ),
              sliver: Obx(() {
                if (controller.isLoading.value && controller.rooms.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryColor),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Memuat data room pantau...',
                            style: AppTypography.bodySmall.copyWith(
                              color: bodyColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final displayedRooms = _getProcessedRooms();

                if (displayedRooms.isEmpty) {
                  final isSearching =
                      _searchController.text.isNotEmpty ||
                      _statusFilter != 'all';
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(
                      context,
                      isSearching,
                      isDark,
                      cardBg,
                      headingColor,
                      bodyColor,
                      primaryColor,
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final room = displayedRooms[index];
                    final jamaahCount = controller.getRoomJamaahCount(room.id);
                    final pendampingCount = controller.getRoomPendampingCount(
                      room.id,
                    );
                    final sosCount = controller.getRoomSosCount(room.id);

                    return _RoomManagementCard(
                      room: room,
                      jamaahCount: jamaahCount,
                      pendampingCount: pendampingCount,
                      sosCount: sosCount,
                      cardBg: cardBg,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                      primaryColor: primaryColor,
                      isDark: isDark,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.selectedRoom.value = room;
                        controller.subscribeToRoomMembers(room.id);
                        Get.toNamed(AppRoutes.roomDetail, arguments: room);
                      },
                      onOpenActions: () =>
                          _showRoomActionSheet(context, controller, room),
                    );
                  }, childCount: displayedRooms.length),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. KPI Overview Summary Card ───────────────────────────────────────────
  Widget _buildOverviewHeader(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    return Obx(() {
      final totalRooms = controller.rooms.length;
      final activeRooms = controller.activeRoomsCount;
      final totalJamaah = controller.totalJamaah.value;
      final totalPendamping = controller.totalPendamping.value;
      final sosCount = controller.activeSosCount.value;

      return Column(
        children: [
          AppCard(
            backgroundColor: cardBg,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryMetricItem(
                    label: 'Total Room',
                    value: '$totalRooms',
                    caption: '$activeRooms Aktif',
                    icon: Icons.meeting_room_outlined,
                    iconColor: primaryColor,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.canvasCreamSubtle,
                ),
                Expanded(
                  child: _buildSummaryMetricItem(
                    label: 'Jamaah Pantau',
                    value: '$totalJamaah',
                    caption: 'Terdaftar',
                    icon: Icons.groups_rounded,
                    iconColor: AppColors.emeraldIslamic,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.canvasCreamSubtle,
                ),
                Expanded(
                  child: _buildSummaryMetricItem(
                    label: 'Pendamping',
                    value: '$totalPendamping',
                    caption: 'Bertugas',
                    icon: Icons.health_and_safety_rounded,
                    iconColor: AppColors.primaryGold,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          if (sosCount > 0) ...[
            const SizedBox(height: AppSpacing.xs + 2),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _statusFilter = 'sos');
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sosEmergency.withValues(
                    alpha: isDark ? 0.20 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.sosEmergency.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.sosEmergency,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peringatan: Ada $sosCount panggilan darurat SOS pada room aktif!',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'Lihat',
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.sosEmergency,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.sosEmergency,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSummaryMetricItem({
    required String label,
    required String value,
    required String caption,
    required IconData icon,
    required Color iconColor,
    required Color headingColor,
    required Color bodyColor,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: bodyColor.withValues(alpha: 0.8),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: headingColor,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        Text(
          caption,
          style: AppTypography.captionSmall.copyWith(
            color: bodyColor.withValues(alpha: 0.65),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ── 2. Search Bar ──────────────────────────────────────────────────────────
  Widget _buildSearchBar(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.canvasCreamSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primary).withValues(
              alpha: 0.04,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: AppTypography.bodyMedium.copyWith(
          color: headingColor,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (val) {
          controller.searchQuery.value = val;
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Cari nama room atau 6-digit kode...',
          hintStyle: AppTypography.bodySmall.copyWith(
            color: bodyColor.withValues(alpha: 0.55),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: bodyColor.withValues(alpha: 0.6),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  color: bodyColor.withValues(alpha: 0.7),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _searchController.clear();
                    controller.searchQuery.value = '';
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ── 3. Filter Tabs & Sort Row ──────────────────────────────────────────────
  Widget _buildFilterAndSortRow(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    return Obx(() {
      final allCount = controller.rooms.length;
      final activeCount = controller.activeRoomsCount;
      final inactiveCount = controller.inactiveRoomsCount;
      final sosCount = controller.activeSosCount.value;

      return Row(
        children: [
          // Filter Chips Scrollable
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _FilterChipItem(
                    label: 'Semua ($allCount)',
                    isSelected: _statusFilter == 'all',
                    activeColor: primaryColor,
                    headingColor: headingColor,
                    cardBg: cardBg,
                    isDark: isDark,
                    onTap: () => setState(() => _statusFilter = 'all'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChipItem(
                    label: 'Aktif ($activeCount)',
                    isSelected: _statusFilter == 'active',
                    activeColor: AppColors.statusSafe,
                    headingColor: headingColor,
                    cardBg: cardBg,
                    isDark: isDark,
                    indicatorColor: AppColors.statusSafe,
                    onTap: () => setState(() => _statusFilter = 'active'),
                  ),
                  const SizedBox(width: 6),
                  _FilterChipItem(
                    label: 'Nonaktif ($inactiveCount)',
                    isSelected: _statusFilter == 'inactive',
                    activeColor: bodyColor,
                    headingColor: headingColor,
                    cardBg: cardBg,
                    isDark: isDark,
                    onTap: () => setState(() => _statusFilter = 'inactive'),
                  ),
                  if (sosCount > 0) ...[
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: '🚨 SOS ($sosCount)',
                      isSelected: _statusFilter == 'sos',
                      activeColor: AppColors.sosEmergency,
                      headingColor: headingColor,
                      cardBg: cardBg,
                      isDark: isDark,
                      indicatorColor: AppColors.sosEmergency,
                      onTap: () => setState(() => _statusFilter = 'sos'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Sort Button
          InkWell(
            onTap: () => _showSortSheet(
              context,
              isDark,
              cardBg,
              headingColor,
              bodyColor,
              primaryColor,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.canvasCreamSubtle,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_rounded, size: 15, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    _sortLabel(_sortBy),
                    style: AppTypography.captionSmall.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  String _sortLabel(String sort) {
    switch (sort) {
      case 'name':
        return 'Nama A-Z';
      case 'jamaah':
        return 'Jamaah';
      case 'sos':
        return 'Prioritas SOS';
      case 'newest':
      default:
        return 'Terbaru';
    }
  }

  // ── Sort Sheet ─────────────────────────────────────────────────────────────
  void _showSortSheet(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: bodyColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Urutkan Daftar Room',
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSortOption(
                  'newest',
                  'Terbaru Dibuat',
                  Icons.schedule_rounded,
                  primaryColor,
                  headingColor,
                  ctx,
                ),
                _buildSortOption(
                  'name',
                  'Nama Room (A - Z)',
                  Icons.sort_by_alpha_rounded,
                  primaryColor,
                  headingColor,
                  ctx,
                ),
                _buildSortOption(
                  'jamaah',
                  'Jamaah Terbanyak',
                  Icons.groups_rounded,
                  primaryColor,
                  headingColor,
                  ctx,
                ),
                _buildSortOption(
                  'sos',
                  'Paling Prioritas (Ada SOS)',
                  Icons.warning_rounded,
                  primaryColor,
                  headingColor,
                  ctx,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortOption(
    String value,
    String label,
    IconData icon,
    Color primaryColor,
    Color headingColor,
    BuildContext ctx,
  ) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryColor : headingColor.withValues(alpha: 0.6),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? primaryColor : headingColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: primaryColor)
          : null,
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(ctx);
        setState(() => _sortBy = value);
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(
    BuildContext context,
    bool isSearching,
    bool isDark,
    Color cardBg,
    Color headingColor,
    Color bodyColor,
    Color primaryColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isSearching ? primaryColor : AppColors.statusSafe)
                    .withValues(alpha: isDark ? 0.20 : 0.12),
                border: Border.all(
                  color: (isSearching ? primaryColor : AppColors.statusSafe)
                      .withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  isSearching
                      ? Icons.search_off_rounded
                      : Icons.roofing_rounded,
                  size: 36,
                  color: isSearching ? primaryColor : AppColors.statusSafe,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isSearching ? 'Room Tidak Ditemukan' : 'Belum Ada Room Pantau',
              style: AppTypography.titleMedium.copyWith(
                color: headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Tidak ada kamar atau kode yang cocok dengan kata kunci atau filter terpilih.'
                  : 'Buat ruang pantau maktab atau rombongan pertama Anda untuk mulai memantau jamaah.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: bodyColor.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isSearching)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Reset Filter & Pencarian',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _searchController.clear();
                  controller.searchQuery.value = '';
                  setState(() {
                    _statusFilter = 'all';
                    _sortBy = 'newest';
                  });
                },
              )
            else
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark
                      ? AppColors.darkOnPrimary
                      : Colors.white,
                  minimumSize: const Size(180, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Buat Room Baru',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _showCreateRoomSheet(context, controller),
              ),
          ],
        ),
      ),
    );
  }

  // ── Create Room Sheet ──────────────────────────────────────────────────────
  void _showCreateRoomSheet(
    BuildContext context,
    AdminRoomController controller,
  ) {
    final textCtrl = TextEditingController();
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    final presetSuggestions = [
      'Maktab 48 Kloter 12',
      'Kloter 05 JKS',
      'Hotel Al Kiswah Lt 4',
      'Rombongan Bimbad A',
      'Kamar Lansia Khusus',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.md,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: bodyColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(
                            alpha: isDark ? 0.20 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.add_business_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm + 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buat Room Pantau Baru',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            Text(
                              'Kelompok, Maktab, atau Rombongan Jamaah',
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Nama Kelompok / Room',
                    style: AppTypography.captionSmall.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: textCtrl,
                    autofocus: true,
                    style: AppTypography.bodyMedium.copyWith(
                      color: headingColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Misal: Maktab 48 Kloter 12',
                      hintStyle: TextStyle(
                        color: bodyColor.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.meeting_room_outlined,
                        color: primaryColor,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkScaffold.withValues(alpha: 0.6)
                          : AppColors.canvasCream.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.canvasCreamSubtle,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : AppColors.canvasCreamSubtle,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Preset suggestions
                  Text(
                    'Inspirasi Cepat:',
                    style: AppTypography.captionSmall.copyWith(
                      color: bodyColor.withValues(alpha: 0.7),
                      fontSize: 10.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: presetSuggestions.map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(preset),
                            labelStyle: AppTypography.captionSmall.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                            ),
                            backgroundColor: primaryColor.withValues(
                              alpha: isDark ? 0.15 : 0.08,
                            ),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.25),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            onPressed: () {
                              textCtrl.text = preset;
                              setSheetState(() {});
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Informative Box
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.darkCardBorder
                                  : AppColors.canvasCreamSubtle)
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kode unik 6 karakter (misal: "MKT482") akan di-generate otomatis oleh sistem untuk dibagikan ke pendamping & jamaah.',
                            style: AppTypography.captionSmall.copyWith(
                              color: bodyColor.withValues(alpha: 0.85),
                              height: 1.35,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  Obx(() {
                    final submitting = controller.isSubmitting.value;
                    return SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark
                              ? AppColors.darkOnPrimary
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          elevation: 2,
                        ),
                        onPressed: submitting
                            ? null
                            : () =>
                                  controller.createRoom(context, textCtrl.text),
                        child: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Buat Ruang Pantau',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Edit Name Sheet ────────────────────────────────────────────────────────
  void _showEditNameSheet(
    BuildContext context,
    AdminRoomController controller,
    RoomModel room,
  ) {
    final textCtrl = TextEditingController(text: room.name);
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ubah Nama Room',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: headingColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kode room "${room.code}" tetap tidak berubah.',
                style: AppTypography.captionSmall.copyWith(color: bodyColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: textCtrl,
                autofocus: true,
                style: AppTypography.bodyMedium.copyWith(color: headingColor),
                decoration: InputDecoration(
                  labelText: 'Nama Room Baru',
                  prefixIcon: Icon(Icons.edit_rounded, color: primaryColor),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkScaffold.withValues(alpha: 0.6)
                      : AppColors.canvasCream.withValues(alpha: 0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.canvasCreamSubtle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark
                        ? AppColors.darkOnPrimary
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    elevation: 1,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    controller.updateRoomName(context, room.id, textCtrl.text);
                  },
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Room Actions Bottom Sheet ──────────────────────────────────────────────
  void _showRoomActionSheet(
    BuildContext context,
    AdminRoomController controller,
    RoomModel room,
  ) {
    HapticFeedback.lightImpact();
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: bodyColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Header Room Badge
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.meeting_room_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Kode: ${room.code} • ${room.isActive ? "Aktif Dipantau" : "Nonaktif"}',
                            style: AppTypography.captionSmall.copyWith(
                              color: bodyColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.canvasCreamSubtle,
                ),
                const SizedBox(height: AppSpacing.xs),

                _ActionItemTile(
                  icon: Icons.open_in_new_rounded,
                  title: 'Buka Ruang Pantau & Anggota',
                  subtitle: 'Pantau posisi live jamaah dan pendamping',
                  color: primaryColor,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.selectedRoom.value = room;
                    controller.subscribeToRoomMembers(room.id);
                    Get.toNamed(AppRoutes.roomDetail, arguments: room);
                  },
                ),
                _ActionItemTile(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Lihat QR Code Room',
                  subtitle:
                      'Tampilkan QR Code untuk dipindai jamaah/pendamping',
                  color: primaryColor,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    RoomQrDialog.show(context, room: room);
                  },
                ),
                _ActionItemTile(
                  icon: Icons.copy_rounded,
                  title: 'Salin Kode Undangan (${room.code})',
                  subtitle: 'Bagikan kode ke jamaah agar dapat bergabung',
                  color: headingColor,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: room.code));
                    AppAlert.info(
                      context,
                      title: 'Kode Disalin',
                      message:
                          'Kode rombongan "${room.code}" sudah disalin dan siap ditempel.',
                    );
                  },
                ),
                _ActionItemTile(
                  icon: Icons.edit_outlined,
                  title: 'Ubah Nama Ruang',
                  subtitle: 'Perbarui label maktab atau kelompok',
                  color: headingColor,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditNameSheet(context, controller, room);
                  },
                ),
                _ActionItemTile(
                  icon: room.isActive
                      ? Icons.pause_circle_outline_rounded
                      : Icons.play_circle_outline_rounded,
                  title: room.isActive
                      ? 'Nonaktifkan Sementara'
                      : 'Aktifkan Kembali',
                  subtitle: room.isActive
                      ? 'Anggota tidak dapat check-in selama nonaktif'
                      : 'Buka akses check-in anggota',
                  color: room.isActive
                      ? AppColors.distanceWarning
                      : AppColors.statusSafe,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.promptToggleRoomStatus(context, room);
                  },
                ),
                _ActionItemTile(
                  icon: Icons.delete_outline_rounded,
                  title: 'Hapus Ruang Pantau',
                  subtitle: 'Hapus permanen room dan daftar delegasi anggota',
                  color: AppColors.error,
                  headingColor: AppColors.error,
                  bodyColor: bodyColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    controller.promptDeleteRoom(context, room);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Action Item Tile ─────────────────────────────────────────────────────────
class _ActionItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color headingColor;
  final Color bodyColor;
  final VoidCallback onTap;

  const _ActionItemTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.headingColor,
    required this.bodyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTypography.titleSmall.copyWith(
          color: headingColor,
          fontWeight: FontWeight.bold,
          fontSize: 13.5,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.captionSmall.copyWith(
          color: bodyColor.withValues(alpha: 0.7),
          fontSize: 11,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ── Filter Chip Item ─────────────────────────────────────────────────────────
class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color headingColor;
  final Color cardBg;
  final bool isDark;
  final Color? indicatorColor;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.headingColor,
    required this.cardBg,
    required this.isDark,
    this.indicatorColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: isDark ? 0.24 : 0.14)
              : cardBg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark
                      ? AppColors.darkCardBorder
                      : AppColors.canvasCreamSubtle),
            width: isSelected ? 1.4 : 0.9,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (indicatorColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: isSelected
                    ? activeColor
                    : headingColor.withValues(alpha: 0.8),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Room Management Card ─────────────────────────────────────────────────────
class _RoomManagementCard extends StatelessWidget {
  final RoomModel room;
  final int jamaahCount;
  final int pendampingCount;
  final int sosCount;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onOpenActions;

  const _RoomManagementCard({
    required this.room,
    required this.jamaahCount,
    required this.pendampingCount,
    required this.sosCount,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
    required this.onOpenActions,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasSos = sosCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: AppCard(
        backgroundColor: cardBg,
        borderColor: hasSos
            ? AppColors.sosEmergency.withValues(alpha: 0.6)
            : (isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle),
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Emblem + Room Name + Status Badge + Actions Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emblem
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: hasSos
                            ? AppColors.sosEmergency.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              )
                            : (room.isActive
                                  ? AppColors.statusSafe.withValues(
                                      alpha: isDark ? 0.18 : 0.10,
                                    )
                                  : bodyColor.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: hasSos
                              ? AppColors.sosEmergency.withValues(alpha: 0.4)
                              : (room.isActive
                                    ? AppColors.statusSafe.withValues(
                                        alpha: 0.25,
                                      )
                                    : bodyColor.withValues(alpha: 0.15)),
                        ),
                      ),
                      child: Icon(
                        hasSos
                            ? Icons.warning_rounded
                            : (room.isActive
                                  ? Icons.roofing_rounded
                                  : Icons.meeting_room_outlined),
                        color: hasSos
                            ? AppColors.sosEmergency
                            : (room.isActive
                                  ? AppColors.statusSafe
                                  : bodyColor.withValues(alpha: 0.7)),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm + 4),

                    // Room Title & Metadata
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  room.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: headingColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Status pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (room.isActive
                                              ? AppColors.statusSafe
                                              : bodyColor)
                                          .withValues(
                                            alpha: isDark ? 0.20 : 0.12,
                                          ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: room.isActive
                                            ? AppColors.statusSafe
                                            : bodyColor.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      room.isActive ? 'Aktif' : 'Nonaktif',
                                      style: AppTypography.captionSmall
                                          .copyWith(
                                            color: room.isActive
                                                ? AppColors.statusSafe
                                                : bodyColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Dibuat: ${_formatDate(room.createdAt)}',
                            style: AppTypography.captionSmall.copyWith(
                              color: bodyColor.withValues(alpha: 0.65),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick More Actions Button
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded),
                      color: bodyColor.withValues(alpha: 0.75),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      tooltip: 'Opsi Room',
                      onPressed: onOpenActions,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm + 2),

                // Middle: Room Code + One-Tap Copy Strip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isDark
                                ? AppColors.darkCardBorder
                                : AppColors.canvasCreamSubtle)
                            .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, size: 14, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        'Kode Room: ',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.85),
                          fontSize: 11.5,
                        ),
                      ),
                      Text(
                        room.code,
                        style: AppTypography.titleSmall.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => RoomQrDialog.show(context, room: room),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 13,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'QR',
                                style: AppTypography.captionSmall.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: room.code));
                          AppAlert.info(
                            context,
                            title: 'Kode Disalin',
                            message:
                                'Kode rombongan "${room.code}" sudah disalin dan siap ditempel.',
                          );
                        },
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Salin',
                                style: AppTypography.captionSmall.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm + 2),

                // Bottom: Metric Badges & Enter Room CTA
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Jamaah Count Pill
                          _MetricBadgePill(
                            icon: Icons.groups_rounded,
                            count: jamaahCount,
                            label: 'Jamaah',
                            color: AppColors.emeraldIslamic,
                            isDark: isDark,
                          ),
                          // Pendamping Count Pill
                          _MetricBadgePill(
                            icon: Icons.health_and_safety_rounded,
                            count: pendampingCount,
                            label: 'Pendamping',
                            color: primaryColor,
                            isDark: isDark,
                          ),
                          if (hasSos)
                            _MetricBadgePill(
                              icon: Icons.warning_rounded,
                              count: sosCount,
                              label: 'SOS',
                              color: AppColors.sosEmergency,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Enter Room Action
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Pantau Room',
                            style: AppTypography.captionSmall.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 10.5,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Metric Badge Pill ────────────────────────────────────────────────────────
class _MetricBadgePill extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;
  final bool isDark;

  const _MetricBadgePill({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: AppTypography.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
