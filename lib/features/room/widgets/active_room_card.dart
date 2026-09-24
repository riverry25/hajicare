import '../../../core/locales/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/user_feedback_message.dart';
import 'add_jamaah_dialog.dart';
import 'edit_room_dialog.dart';
import 'jamaah_detail_sheet.dart';
import 'room_qr_dialog.dart';

class ActiveRoomCard extends StatelessWidget {
  final bool isPendamping;

  const ActiveRoomCard({super.key, required this.isPendamping});

  @override
  Widget build(BuildContext context) {
    final state = Get.find<HajiCareController>();
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Obx(() {
      final room = state.activeRoom.value;
      final roomId = state.activeRoomId.value;
      final members = state.activeRoomMembers;
      final jamaahCount = isPendamping
          ? state.jamaahList.length
          : members.length;
      final currentUid = state.currentUid;
      final isCreator =
          isPendamping &&
          room != null &&
          (currentUid == room.createdBy || state.role == UserRole.admin);

      final hasRoom = roomId != null && roomId.isNotEmpty;
      final roomName =
          room?.name ?? (hasRoom ? 'Room Pemantauan' : 'Belum Ada Room');
      final roomCode = room?.code ?? '';

      // ── Unconnected State (Belum Memiliki Room) ───────────────────────────
      if (!hasRoom) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
              topRight: Radius.circular(48),
            ),
            border: Border.all(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : const Color(0xFFF1F5F9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF1E293B).withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.statusWarning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.meeting_room_rounded,
                      color: AppColors.statusWarning,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPendamping
                              ? 'Belum Ada Room Aktif'
                              : 'Belum Terhubung ke Room',
                          style: TextStyle(
                            color: headingColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPendamping
                              ? 'Buat room baru atau gabung ke room yang sudah ada untuk memantau radar posisi jamaah.'
                              : 'Gabung room untuk mengaktifkan pemantauan lokasi pendamping dan darurat SOS.',
                          style: TextStyle(
                            color: bodyColor,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isPendamping) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.toNamed('/join_room'),
                        icon: const Icon(Icons.login_rounded, size: 16),
                        label: const Text(
                          'Gabung Room',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: primaryColor,
                          side: BorderSide(
                            color: primaryColor.withValues(alpha: 0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.toNamed('/join_room'),
                        icon: const Icon(Icons.add_business_rounded, size: 16),
                        label: const Text(
                          'Buat Room',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: primaryColor,
                          foregroundColor: isDark
                              ? AppColors.espressoDark
                              : AppColors.surfaceWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/join_room'),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text(
                      'Gabung Room Monitoring',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: primaryColor,
                      foregroundColor: isDark
                          ? AppColors.espressoDark
                          : AppColors.surfaceWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      // ── Connected State (Memiliki Room Aktif) ──────────────────────────────
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
            topRight: Radius.circular(
              52,
            ), // Signature modern curved top-right corner
          ),
          border: Border.all(
            color: isDark
                ? AppColors.darkOutlineVariant
                : const Color(0xFFF1F5F9),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.35)
                  : const Color(0xFF1E293B).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Section: Left 2 Stacked Metrics + Right Arc Gauge ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Stacked Room Name & Pendamping Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Room Name / Maktab Item
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 3.5,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.goldLight
                                  : AppColors.primaryGold,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kamar & Maktab',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.meeting_room_rounded,
                                      color: isDark
                                          ? AppColors.goldLight
                                          : AppColors.primaryGold,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        roomName,
                                        style: TextStyle(
                                          color: headingColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isDark
                                                    ? AppColors.goldLight
                                                    : AppColors.primaryGold)
                                                .withValues(
                                                  alpha: isDark ? 0.25 : 0.14,
                                                ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Aktif',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppColors.goldLight
                                              : AppColors.goldDark,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 2. Pendamping Item
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 3.5,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSecondary
                                  : AppColors.tanMedium,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pendamping Maktab',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      color: isDark
                                          ? AppColors.darkSecondary
                                          : AppColors.tanMedium,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        state.pendampingName.value.isNotEmpty
                                            ? state.pendampingName.value
                                            : 'Petugas Maktab',
                                        style: TextStyle(
                                          color: headingColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusSafe.withValues(
                                          alpha: isDark ? 0.25 : 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Siaga',
                                        style: TextStyle(
                                          color: AppColors.statusSafe,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right: Circular Arc Progress Ring Gauge (Member Count + QR trigger)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (roomCode.isNotEmpty) {
                          _showQrModal(context, roomName, roomCode);
                        }
                      },
                      borderRadius: BorderRadius.circular(53),
                      child: SizedBox(
                        width: 106,
                        height: 106,
                        child: CustomPaint(
                          painter: _RoomCapacityGaugePainter(
                            progress: (jamaahCount / 10.0).clamp(0.2, 1.0),
                            trackColor: isDark
                                ? AppColors.darkSurfaceContainerHighest
                                : AppColors.canvasCreamSubtle,
                            arcColor: isDark
                                ? AppColors.goldLight
                                : AppColors.goldPrimary,
                            dotColor: isDark
                                ? AppColors.accentGoldStar
                                : AppColors.goldDark,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$jamaahCount',
                                  style: TextStyle(
                                    color: headingColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isPendamping ? 'Jamaah' : 'Anggota',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceContainer
                                : AppColors.canvasCream,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : AppColors.goldLight.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: headingColor,
                            size: 17,
                          ),
                        ),
                        tooltip: 'Pengaturan Room',
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: AppColors.cardBorderColor(context),
                          ),
                        ),
                        color: cardBg,
                        elevation: 6,
                        onSelected: (action) {
                          if (action == 'edit') {
                            EditRoomDialog.show(context, room);
                          } else if (action == 'delete') {
                            _showDeleteRoomConfirmation(context, state, room);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 20,
                                  color: headingColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Edit Room',
                                  style: TextStyle(
                                    color: headingColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 8),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_forever_rounded,
                                  size: 20,
                                  color: AppColors.sosEmergency,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Hapus Room',
                                  style: TextStyle(
                                    color: AppColors.sosEmergency,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Horizontal Divider Line ─────────────────────────────
            Divider(
              height: 1,
              color: isDark
                  ? AppColors.darkCardBorder
                  : const Color(0xFFE2E8F0),
            ),

            const SizedBox(height: 16),

            // ── Interactive Wavy Statistic: Radius Radar (Replaces Kode Room & linear bars) ──
            _RadarWaveStatisticWidget(
              radius: room?.safeRadius ?? state.safeRadiusMeters.value,
              currentDistance: state.calculatedDistance.value,
              isDark: isDark,
              headingColor: headingColor,
            ),

            const SizedBox(height: 18),

            // ── Action Buttons Footer ───────────────────────────────
            if (isPendamping) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMemberListSheet(
                        context,
                        state: state,
                        roomId: roomId,
                        roomName: roomName,
                        roomCode: roomCode,
                      ),
                      icon: const Icon(Icons.people_alt_rounded, size: 16),
                      label: const Text(
                        'Daftar Jamaah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => AddJamaahDialog.show(context, roomId),
                      icon: const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Undang Jamaah',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: primaryColor,
                        foregroundColor: isDark
                            ? AppColors.espressoDark
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (roomCode.isNotEmpty) {
                          _showQrModal(context, roomName, roomCode);
                        }
                      },
                      icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                      label: const Text(
                        'QR Room',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Get.toNamed(AppRoutes.roomDetail, arguments: room);
                      },
                      icon: const Icon(Icons.meeting_room_rounded, size: 16),
                      label: const Text(
                        'Detail Room',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.espressoDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  void _showQrModal(BuildContext context, String roomName, String roomCode) {
    final state = Get.find<HajiCareController>();
    final room = state.activeRoom.value;
    if (room != null && (room.code == roomCode || roomCode.isEmpty)) {
      RoomQrDialog.show(context, room: room);
    } else {
      RoomQrDialog.showDetails(context, roomName: roomName, roomCode: roomCode);
    }
  }

  void _showMemberListSheet(
    BuildContext context, {
    required HajiCareController state,
    required String roomId,
    required String roomName,
    required String roomCode,
  }) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Obx(() {
          final jamaahList = state.jamaahList;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
            ),
            padding: EdgeInsets.only(
              top: AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: MediaQuery.of(ctx).padding.bottom + AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Jamaah di Room',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${jamaahList.length} Jamaah terdaftar • Ketuk untuk detail / kelola',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: bodyColor,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(height: 16),
                if (jamaahList.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 48,
                            color: bodyColor.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada jamaah di room ini',
                            style: AppTypography.bodyMedium.copyWith(
                              color: bodyColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              AddJamaahDialog.show(context, roomId);
                            },
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 16,
                            ),
                            label: const Text('Undang Jamaah Sekarang'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: jamaahList.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final j = jamaahList[index];
                        final initial = j.name.trim().isNotEmpty
                            ? j.name.trim()[0].toUpperCase()
                            : 'J';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: j.tier.color.withValues(
                              alpha: 0.15,
                            ),
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: j.tier.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  j.name,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: headingColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (j.sosActive) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.sosEmergency,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: j.tier.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${j.tier.label} • ${j.distance.toInt()}m',
                                style: AppTypography.captionSmall.copyWith(
                                  color: bodyColor,
                                ),
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: bodyColor,
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            JamaahDetailSheet.show(
                              context,
                              jamaah: j,
                              roomId: roomId,
                              roomName: roomName,
                              roomCode: roomCode,
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showDeleteRoomConfirmation(
    BuildContext context,
    HajiCareController state,
    RoomModel room,
  ) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.cardBgColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              side: BorderSide(color: AppColors.cardBorderColor(context)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sosEmergency.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.sosEmergency,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hapus Room?',
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apakah Anda yakin ingin menghapus Room "${room.name}" (${room.code})?',
                  style: AppTypography.bodySmall.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Semua Jamaah di dalam Room akan dikeluarkan dan akses mereka ke fitur Room akan dihentikan.',
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.of(dialogCtx).pop(),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sosEmergency,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 0,
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        try {
                          await state.deleteCurrentRoom();
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (context.mounted) {
                            AppAlert.success(
                              context,
                              title: context.tr('room.roomDeleted'),
                              message:
                                  'Rombongan "${room.name}" sudah dihapus.',
                            );
                          }
                        } catch (e) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isDeleting = false);
                          }
                          if (context.mounted) {
                            AppAlert.error(
                              context,
                              title: context.tr('room.deleteFailed'),
                              message: UserFeedbackMessage.from(
                                e,
                                fallback:
                                    'Rombongan belum dapat dihapus. Silakan coba lagi.',
                              ),
                            );
                          }
                        }
                      },
                icon: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.delete_forever_rounded, size: 18),
                label: Text(
                  isDeleting ? 'Menghapus...' : 'Hapus Room',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Circular gauge painter creating a modern arc progress ring for Room capacity & status
class _RoomCapacityGaugePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color trackColor;
  final Color arcColor;
  final Color dotColor;

  const _RoomCapacityGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.42;
    canvas.drawCircle(center, radius, trackPaint);

    // Foreground arc
    final sweepAngle = (2 * math.pi * 0.72) * progress.clamp(0.08, 1.0);
    const startAngle = -math.pi * 0.5; // Starts at 12 o'clock

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // End handle dot
    final endAngle = startAngle + sweepAngle;
    final dotCenter = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    // Outer white dot with border
    final dotOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 5.5, dotOuterPaint);

    // Inner dot
    final dotInnerPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 3.0, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant _RoomCapacityGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.dotColor != dotColor;
  }
}

// ── Interactive Wavy Statistic Widget for Radius Radar ───────────────────────

class _RadarWaveStatisticWidget extends StatefulWidget {
  final double radius;
  final double? currentDistance;
  final bool isDark;
  final Color headingColor;

  const _RadarWaveStatisticWidget({
    required this.radius,
    this.currentDistance,
    required this.isDark,
    required this.headingColor,
  });

  @override
  State<_RadarWaveStatisticWidget> createState() =>
      _RadarWaveStatisticWidgetState();
}

class _RadarWaveStatisticWidgetState extends State<_RadarWaveStatisticWidget>
    with TickerProviderStateMixin {
  late final AnimationController _waveCtrl;
  late final AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _tapCtrl.forward(from: 0.0);
  }

  bool get _isOutOfRadius {
    final dist = widget.currentDistance ?? 0.0;
    if (dist <= 0 || widget.radius <= 0) return false;
    return dist > widget.radius;
  }

  Color get _waveColor {
    if (_isOutOfRadius) {
      return const Color(0xFFEF4444);
    }
    return widget.isDark
        ? const Color(0xFF34D399)
        : const Color(0xFF059669); // Crisp emerald in light mode
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.radius > 0 ? widget.radius : 500.0;
    final isWarning = _isOutOfRadius;
    final waveColor = _waveColor;
    final hasDist =
        widget.currentDistance != null && widget.currentDistance! > 0;
    final displayDist = hasDist ? widget.currentDistance! : effectiveRadius;

    final badgeBg = isWarning
        ? (widget.isDark
              ? const Color(0xFF7F1D1D).withValues(alpha: 0.45)
              : const Color(0xFFFEE2E2))
        : (widget.isDark
              ? const Color(0xFF064E3B).withValues(alpha: 0.45)
              : const Color(0xFFD1FAE5));

    final badgeTextColor = isWarning
        ? const Color(0xFFEF4444)
        : (widget.isDark ? const Color(0xFF34D399) : const Color(0xFF059669));

    final badgeText = isWarning
        ? 'Di Luar Radius'
        : '${effectiveRadius.round()} m Aman';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.radar_rounded,
                  size: 17,
                  color: isWarning
                      ? const Color(0xFFEF4444)
                      : (widget.isDark
                            ? AppColors.darkPrimary
                            : AppColors.primaryGold),
                ),
                const SizedBox(width: 6),
                Text(
                  'Radius Radar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.headingColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: badgeTextColor.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: badgeTextColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Interactive Animated Wave Card (Transparent Background)
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleTap,
              splashColor: waveColor.withValues(alpha: 0.15),
              highlightColor: waveColor.withValues(alpha: 0.06),
              child: Container(
                width: double.infinity,
                height: 78,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.isDark
                        ? AppColors.darkCardBorder
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_waveCtrl, _tapCtrl]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RadarWavePainter(
                        waveColor: waveColor,
                        wavePhase: _waveCtrl.value,
                        tapPhase: _tapCtrl.value,
                        isTapped: _tapCtrl.isAnimating,
                        displayDistance: displayDist,
                        isDark: widget.isDark,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Custom Painter for the Animated Radar Wave ───────────────────────────────

class _RadarWavePainter extends CustomPainter {
  final Color waveColor;
  final double wavePhase;
  final double tapPhase;
  final bool isTapped;
  final double displayDistance;
  final bool isDark;

  const _RadarWavePainter({
    required this.waveColor,
    required this.wavePhase,
    required this.tapPhase,
    required this.isTapped,
    required this.displayDistance,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final breathe = math.sin(wavePhase * 2 * math.pi) * 2.8;
    final ripple = isTapped ? math.sin(tapPhase * 2 * math.pi) * 4.5 : 0.0;

    const midYRatio = 0.52;
    final midY = h * midYRatio;
    final amplitude = h * 0.28;

    final p0 = Offset(
      4,
      (midY + amplitude * 0.5 + breathe * 0.6 + ripple).clamp(
        h * 0.08,
        h * 0.92,
      ),
    );
    final p1 = Offset(
      w * 0.26,
      (midY - amplitude + breathe - ripple * 0.8).clamp(h * 0.08, h * 0.92),
    );
    final p2 = Offset(
      w * 0.50,
      (midY + amplitude * 0.7 - breathe * 0.8 + ripple * 0.5).clamp(
        h * 0.08,
        h * 0.92,
      ),
    );
    final p3 = Offset(
      w * 0.74,
      (midY - amplitude * 0.9 + breathe - ripple * 0.4).clamp(
        h * 0.08,
        h * 0.92,
      ),
    );
    final p4 = Offset(
      w - 6,
      (midY + amplitude * 0.2 + breathe * 0.5).clamp(h * 0.08, h * 0.92),
    );

    final strokePaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waveColor.withValues(alpha: isDark ? 0.35 : 0.18),
          waveColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    final dotGlowPaint = Paint()
      ..color = waveColor.withValues(alpha: isDark ? 0.28 : 0.20)
      ..style = PaintingStyle.fill;

    final wavePath = Path();
    wavePath.moveTo(p0.dx, p0.dy);
    wavePath.cubicTo(w * 0.09, p0.dy, w * 0.17, p1.dy, p1.dx, p1.dy);
    wavePath.cubicTo(w * 0.35, p1.dy, w * 0.43, p2.dy, p2.dx, p2.dy);
    wavePath.cubicTo(w * 0.59, p2.dy, w * 0.67, p3.dy, p3.dx, p3.dy);
    wavePath.cubicTo(w * 0.83, p3.dy, w * 0.91, p4.dy, p4.dx, p4.dy);

    final fillPath = Path()..addPath(wavePath, Offset.zero);
    fillPath.lineTo(p4.dx, h);
    fillPath.lineTo(p0.dx, h);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(wavePath, strokePaint);

    // Glowing dot at the trailing endpoint
    canvas.drawCircle(p4, 5.5, dotGlowPaint);
    canvas.drawCircle(p4, 3.0, dotPaint);

    _drawDistanceLabel(canvas, size);
  }

  void _drawDistanceLabel(Canvas canvas, Size size) {
    final w = size.width;

    String valueText;
    String unitText;
    if (displayDistance <= 0) {
      valueText = '—';
      unitText = '';
    } else if (displayDistance >= 1000) {
      final km = displayDistance / 1000;
      valueText = km >= 10 ? km.round().toString() : km.toStringAsFixed(1);
      unitText = ' km';
    } else {
      valueText = displayDistance.round().toString();
      unitText = ' m';
    }

    final valuePainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: valueText,
            style: TextStyle(
              color: waveColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          TextSpan(
            text: unitText,
            style: TextStyle(
              color: waveColor.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final xPos = w - valuePainter.width - 8;
    const yPos = 4.0;
    valuePainter.paint(canvas, Offset(xPos, yPos));
  }

  @override
  bool shouldRepaint(covariant _RadarWavePainter old) =>
      old.displayDistance != displayDistance ||
      old.wavePhase != wavePhase ||
      old.tapPhase != tapPhase ||
      old.isTapped != isTapped ||
      old.waveColor != waveColor ||
      old.isDark != isDark;
}
