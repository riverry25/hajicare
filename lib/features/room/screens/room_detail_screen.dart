import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/admin_room_controller.dart';
import '../models/room_member_model.dart';
import '../models/room_model.dart';
import '../services/room_service.dart';
import '../widgets/room_qr_dialog.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late final AdminRoomController controller;
  RoomModel? _room;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AdminRoomController>()
        ? Get.find<AdminRoomController>()
        : Get.put(AdminRoomController());

    _room = (Get.arguments as RoomModel?) ?? controller.selectedRoom.value;
    if (_room != null) {
      controller.subscribeToRoomMembers(_room!.id);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final room = _room ?? controller.selectedRoom.value;

    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    if (room == null) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.room_preferences_outlined, size: 48, color: bodyColor.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Data room tidak ditemukan.',
                style: AppTypography.bodyMedium.copyWith(color: bodyColor),
              ),
            ],
          ),
        ),
      );
    }

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
          // ── Header QR Code Action ──────────────────────────────────────────
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
          controller.subscribeToRoomMembers(room.id);
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
                  // Top Banner with Emblem & Status
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
                        // Status Pill with live indicator
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
                        // Room Code Row
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
                        const SizedBox(height: 10),

                        // Created Date Row
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

                        // ── Dedicated "Tampilkan QR Code" Action Button ──────────
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
                              elevation: 2,
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

                  // ── Member Breakdown Summary Pill Strip ─────────────────────
                  Obx(() {
                    final members = controller.roomMembers;
                    final total = members.length;
                    final jamaahCount = members.where((m) => m.isJamaah).length;
                    final pendampingCount = members.where((m) => m.isPendamping).length;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle)
                            .withValues(alpha: 0.3),
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
                            value: '$total',
                            color: headingColor,
                            icon: Icons.people_alt_rounded,
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
                          ),
                          _buildStatSummaryItem(
                            label: 'Jamaah',
                            value: '$jamaahCount',
                            color: AppColors.emeraldIslamic,
                            icon: Icons.person_rounded,
                          ),
                          Container(
                            height: 24,
                            width: 1,
                            color: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
                          ),
                          _buildStatSummaryItem(
                            label: 'Pendamping',
                            value: '$pendampingCount',
                            color: primaryColor,
                            icon: Icons.health_and_safety_rounded,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── 2. Members Section Header ─────────────────────────────────────
            Obx(() {
              final totalMembers = controller.roomMembers.length;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Daftar Anggota',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '$totalMembers Orang',
                          style: AppTypography.captionSmall.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, size: 18, color: bodyColor),
                    tooltip: 'Muat Ulang Anggota',
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.subscribeToRoomMembers(room.id);
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: AppSpacing.sm),

            // ── 3. Members List ───────────────────────────────────────────────
            Obx(() {
              final members = controller.roomMembers;

              if (members.isEmpty) {
                return AppCard(
                  backgroundColor: cardBg,
                  borderColor: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return _MemberTile(
                    room: room,
                    member: member,
                    cardBg: cardBg,
                    headingColor: headingColor,
                    bodyColor: bodyColor,
                    primaryColor: primaryColor,
                    isDark: isDark,
                  );
                },
              );
            }),
            const SizedBox(height: 30),
          ],
        ),
      ),
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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final RoomModel room;
  final RoomMemberModel member;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final Color primaryColor;
  final bool isDark;

  const _MemberTile({
    required this.room,
    required this.member,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.primaryColor,
    required this.isDark,
  });

  void _handleRemoveJamaah(BuildContext context) {
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
          final actorUid = user?.uid ?? 'admin';
          final actorName = user?.displayName?.trim().isNotEmpty == true
              ? user!.displayName!
              : 'Admin Pusat';

          await RoomService().removeJamaahFromRoom(
            roomId: room.id,
            jamaahUid: member.uid,
            actorUid: actorUid,
            actorRole: 'admin',
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

    return AppCard(
      backgroundColor: cardBg,
      borderColor: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          // Squircle Avatar
          Container(
            width: 44,
            height: 44,
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
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),

          // Member Info
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
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  member.joinedAt != null
                      ? 'Bergabung: ${member.joinedAt!.day}/${member.joinedAt!.month}/${member.joinedAt!.year}'
                      : 'Baru saja bergabung',
                  style: AppTypography.captionSmall.copyWith(
                    color: bodyColor.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Role Badge Pill
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
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          // Remove Action for Jamaah
          if (member.isJamaah) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.person_remove_rounded, size: 19),
              color: AppColors.error,
              tooltip: 'Keluarkan dari Room',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _handleRemoveJamaah(context),
            ),
          ],
        ],
      ),
    );
  }
}
