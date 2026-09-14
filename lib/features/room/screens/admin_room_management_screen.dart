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
import '../controllers/admin_room_controller.dart';
import '../models/room_model.dart';

class AdminRoomManagementScreen extends StatelessWidget {
  const AdminRoomManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AdminRoomController());
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    final searchController = TextEditingController(text: controller.searchQuery.value);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: Icon(Icons.arrow_back_rounded, color: headingColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Kelola Room Pantau',
          style: AppTypography.headlineMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRoomSheet(context, controller),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Room Baru', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ── Search & Filter Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenEdgeGutter),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  onChanged: (val) => controller.searchQuery.value = val,
                  decoration: InputDecoration(
                    hintText: 'Cari nama room atau kode...',
                    prefixIcon: Icon(Icons.search_rounded, color: bodyColor),
                    suffixIcon: Obx(() {
                      if (controller.searchQuery.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            searchController.clear();
                            controller.searchQuery.value = '';
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Filter Tabs (Semua / Aktif / Nonaktif)
                Obx(() {
                  final activeFilter = controller.statusFilter.value;
                  final allCount = controller.rooms.length;
                  final activeCount = controller.activeRoomsCount;
                  final inactiveCount = controller.inactiveRoomsCount;

                  return Row(
                    children: [
                      _FilterTab(
                        label: 'Semua ($allCount)',
                        isSelected: activeFilter == 'all',
                        primaryColor: primaryColor,
                        cardBg: cardBg,
                        headingColor: headingColor,
                        bodyColor: bodyColor,
                        onTap: () => controller.statusFilter.value = 'all',
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'Aktif ($activeCount)',
                        isSelected: activeFilter == 'active',
                        primaryColor: primaryColor,
                        cardBg: cardBg,
                        headingColor: headingColor,
                        bodyColor: bodyColor,
                        onTap: () => controller.statusFilter.value = 'active',
                      ),
                      const SizedBox(width: 8),
                      _FilterTab(
                        label: 'Nonaktif ($inactiveCount)',
                        isSelected: activeFilter == 'inactive',
                        primaryColor: primaryColor,
                        cardBg: cardBg,
                        headingColor: headingColor,
                        bodyColor: bodyColor,
                        onTap: () => controller.statusFilter.value = 'inactive',
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Room List or Empty State ───────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.rooms.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              final displayedRooms = controller.filteredRooms;

              if (displayedRooms.isEmpty) {
                final isSearching = controller.searchQuery.value.isNotEmpty || controller.statusFilter.value != 'all';

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSearching ? Icons.search_off_rounded : Icons.meeting_room_outlined,
                          size: 64,
                          color: bodyColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          isSearching ? 'Room Tidak Ditemukan' : 'Belum ada Room Pantau',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isSearching
                              ? 'Coba gunakan kata kunci lain atau ubah filter status.'
                              : 'Klik tombol "Buat Room Baru" di bawah untuk memulai.',
                          textAlign: TextAlign.center,
                          style: AppTypography.captionSmall.copyWith(color: bodyColor),
                        ),
                        if (!isSearching) ...[
                          const SizedBox(height: AppSpacing.lg),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(160, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Buat Room', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => _showCreateRoomSheet(context, controller),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenEdgeGutter,
                  AppSpacing.xs,
                  AppSpacing.screenEdgeGutter,
                  90,
                ),
                itemCount: displayedRooms.length,
                itemBuilder: (context, index) {
                  final room = displayedRooms[index];
                  final jamaahCount = controller.getRoomJamaahCount(room.id);
                  final pendampingCount = controller.getRoomPendampingCount(room.id);
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
                    onTap: () {
                      controller.selectedRoom.value = room;
                      controller.subscribeToRoomMembers(room.id);
                      Get.toNamed(AppRoutes.roomDetail, arguments: room);
                    },
                    onEditName: () => _showEditNameSheet(context, controller, room),
                    onToggleStatus: () => controller.promptToggleRoomStatus(context, room),
                    onDelete: () => controller.promptDeleteRoom(context, room),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Create Room Sheet ──────────────────────────────────────────────────────
  void _showCreateRoomSheet(BuildContext context, AdminRoomController controller) {
    final textCtrl = TextEditingController();
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
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
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Buat Room Pantau Baru',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextHeading : AppColors.espressoDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nama kelompok atau rombongan. Kode room 6 karakter di-generate otomatis.',
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: textCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nama Kelompok / Room',
                  hintText: 'Contoh: Maktab 48 Kloter 12',
                  prefixIcon: const Icon(Icons.meeting_room_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(() {
                final submitting = controller.isSubmitting.value;
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: 0,
                    ),
                    onPressed: submitting ? null : () => controller.createRoom(context, textCtrl.text),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Buat Room Pantau',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                );
              }),
            ],
          ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
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
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ubah Nama Room',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextHeading : AppColors.espressoDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: textCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nama Room Baru',
                  prefixIcon: const Icon(Icons.edit_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGold,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    controller.updateRoomName(context, room.id, textCtrl.text);
                  },
                  child: const Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Supporting Widgets ────────────────────────────────────────────────────────

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isSelected ? primaryColor : cardBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isSelected ? primaryColor : bodyColor.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: isSelected ? Colors.white : headingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomManagementCard extends StatelessWidget {
  final RoomModel room;
  final int jamaahCount;
  final int pendampingCount;
  final int sosCount;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onEditName;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _RoomManagementCard({
    required this.room,
    required this.jamaahCount,
    required this.pendampingCount,
    required this.sosCount,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.primaryColor,
    required this.onTap,
    required this.onEditName,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasSos = sosCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm + 4),
      child: AppCard(
        backgroundColor: cardBg,
        borderColor: hasSos ? AppColors.sosEmergency.withValues(alpha: 0.5) : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Room Name + Status Badge + Popup Menu
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (room.isActive ? AppColors.statusSafe : AppColors.textSecondary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            room.isActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                            size: 12,
                            color: room.isActive ? AppColors.statusSafe : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            room.isActive ? 'Aktif' : 'Nonaktif',
                            style: AppTypography.captionSmall.copyWith(
                              color: room.isActive ? AppColors.statusSafe : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: bodyColor),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      onSelected: (val) {
                        if (val == 'edit') onEditName();
                        if (val == 'status') onToggleStatus();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18),
                              SizedBox(width: 10),
                              Text('Ubah Nama'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(
                                room.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(room.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              SizedBox(width: 10),
                              Text('Hapus Room', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Room Code + One-Tap Copy
                Row(
                  children: [
                    Text('Kode: ', style: AppTypography.captionSmall.copyWith(color: bodyColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        room.code,
                        style: AppTypography.labelMedium.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: primaryColor,
                      tooltip: 'Salin Kode',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: room.code));
                        AppAlert.info(
                          context,
                          title: 'Kode Disalin',
                          message: 'Kode room "${room.code}" disalin ke clipboard.',
                        );
                      },
                    ),
                    const Spacer(),
                    Text(
                      room.createdAt != null
                          ? 'Dibuat: ${room.createdAt!.day}/${room.createdAt!.month}/${room.createdAt!.year}'
                          : '',
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Metrics Badges (Jamaah, Pendamping, SOS)
                Row(
                  children: [
                    _BadgeMetric(
                      icon: Icons.groups_rounded,
                      count: jamaahCount,
                      label: 'Jamaah',
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 8),
                    _BadgeMetric(
                      icon: Icons.health_and_safety_rounded,
                      count: pendampingCount,
                      label: 'Pendamping',
                      color: const Color(0xFF1976D2),
                    ),
                    if (hasSos) ...[
                      const SizedBox(width: 8),
                      _BadgeMetric(
                        icon: Icons.warning_rounded,
                        count: sosCount,
                        label: 'SOS',
                        color: AppColors.sosEmergency,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'Detail Member',
                          style: AppTypography.captionSmall.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: primaryColor),
                      ],
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

class _BadgeMetric extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _BadgeMetric({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
