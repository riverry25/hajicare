import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/routes/app_routes.dart';
import 'add_jamaah_dialog.dart';
import 'edit_room_dialog.dart';
import 'jamaah_detail_sheet.dart';

class ActiveRoomCard extends StatelessWidget {
  final bool isPendamping;

  const ActiveRoomCard({
    super.key,
    required this.isPendamping,
  });

  @override
  Widget build(BuildContext context) {
    final state = Get.find<HajiCareController>();
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Obx(() {
      final room = state.activeRoom.value;
      final roomId = state.activeRoomId.value;
      final members = state.activeRoomMembers;
      final jamaahCount = isPendamping ? state.jamaahList.length : members.length;
      final currentUid = state.currentUid;
      final isCreator = isPendamping && room != null && (currentUid == room.createdBy || state.role == UserRole.admin);

      final hasRoom = roomId != null && roomId.isNotEmpty;
      final roomName = room?.name ?? (hasRoom ? 'Room Pemantauan' : 'Belum Ada Room');
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
                          isPendamping ? 'Belum Ada Room Aktif' : 'Belum Terhubung ke Room',
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? AppColors.espressoDark : AppColors.surfaceWhite,
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: primaryColor,
                      foregroundColor: isDark ? AppColors.espressoDark : AppColors.surfaceWhite,
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
            topRight: Radius.circular(52), // Signature modern curved top-right corner
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
                              color: isDark ? AppColors.goldLight : AppColors.primaryGold,
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
                                      color: isDark ? AppColors.goldLight : AppColors.primaryGold,
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
                                        color: (isDark ? AppColors.goldLight : AppColors.primaryGold).withValues(alpha: isDark ? 0.25 : 0.14),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Aktif',
                                        style: TextStyle(
                                          color: isDark ? AppColors.goldLight : AppColors.goldDark,
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
                              color: isDark ? AppColors.darkSecondary : AppColors.tanMedium,
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
                                      color: isDark ? AppColors.darkSecondary : AppColors.tanMedium,
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
                                        color: AppColors.statusSafe.withValues(alpha: isDark ? 0.25 : 0.12),
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
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  size: 14,
                                  color: isDark ? AppColors.goldLight : AppColors.primaryGold,
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
                                Icon(Icons.edit_note_rounded, size: 20, color: headingColor),
                                const SizedBox(width: 10),
                                Text('Edit Room', style: TextStyle(color: headingColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 8),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.sosEmergency),
                                SizedBox(width: 10),
                                Text('Hapus Room', style: TextStyle(color: AppColors.sosEmergency, fontWeight: FontWeight.w600)),
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

            // ── Bottom Row: 3 Horizontal Metrics with Mini Progress Bars ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Col 1: Kode Room
                Expanded(
                  child: _buildRoomLinearMetric(
                    context: context,
                    title: 'Kode Room',
                    progress: 0.9,
                    barColor: isDark ? AppColors.goldLight : AppColors.primaryGold,
                    isDark: isDark,
                    headingColor: headingColor,
                    valueWidget: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: roomCode));
                        AppAlert.info(
                          context,
                          title: 'Kode Disalin',
                          message: 'Kode room $roomCode berhasil disalin.',
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              roomCode.isNotEmpty ? roomCode : '-',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.copy_rounded,
                            size: 11.5,
                            color: isDark ? AppColors.goldLight : AppColors.primaryGold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Col 2: Radius Radar
                Expanded(
                  child: _buildRoomLinearMetric(
                    context: context,
                    title: 'Radius Radar',
                    progress: 0.75,
                    barColor: isDark ? AppColors.darkSecondary : AppColors.tanMedium,
                    isDark: isDark,
                    headingColor: headingColor,
                    valueWidget: Text(
                      '${room?.safeRadius.toInt() ?? 200} m Aman',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Col 3: Monitoring
                Expanded(
                  child: _buildRoomLinearMetric(
                    context: context,
                    title: 'Monitoring',
                    progress: 1.0,
                    barColor: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
                    isDark: isDark,
                    headingColor: headingColor,
                    valueWidget: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.statusSafe,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Real-time',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusSafe,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: const Text(
                        'Undang Jamaah',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        backgroundColor: primaryColor,
                        foregroundColor: isDark ? AppColors.espressoDark : Colors.white,
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
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                        Get.toNamed(AppRoutes.roomDetail);
                      },
                      icon: const Icon(Icons.meeting_room_rounded, size: 16),
                      label: const Text(
                        'Detail Room',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 15,
                    color: AppColors.statusSafe,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Monitoring aktif bersama pendamping secara realtime.',
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                        fontWeight: FontWeight.w600,
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
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.goldLight : AppColors.goldPrimary;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.goldLight.withValues(alpha: 0.3),
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.qr_code_2_rounded, color: primaryColor, size: 22),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                roomName,
                                style: AppTypography.titleMedium.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Kode & QR Room',
                                style: AppTypography.captionSmall.copyWith(color: bodyColor),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: bodyColor,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Pindai QR Code atau masukkan 6 karakter kode untuk bergabung ke room:',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(color: bodyColor, height: 1.35),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // QR Code Container with fixed dimensions
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 180,
                        height: 180,
                        child: QrImageView(
                          data: roomCode,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Room Code Badge with Copy button
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: roomCode));
                        AppAlert.success(context, title: 'Disalin', message: 'Kode room $roomCode berhasil disalin.');
                      },
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              roomCode,
                              style: AppTypography.titleLarge.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.copy_rounded, size: 18, color: primaryColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ketuk untuk menyalin kode',
                      style: AppTypography.captionSmall.copyWith(color: bodyColor),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                      color: isDark ? AppColors.darkOutlineVariant : AppColors.surfaceVariant,
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
                          style: AppTypography.captionSmall.copyWith(color: bodyColor),
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
                          Icon(Icons.people_outline_rounded, size: 48, color: bodyColor.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada jamaah di room ini',
                            style: AppTypography.bodyMedium.copyWith(color: bodyColor),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              AddJamaahDialog.show(context, roomId);
                            },
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
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
                        final initial = j.name.trim().isNotEmpty ? j.name.trim()[0].toUpperCase() : 'J';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: j.tier.color.withValues(alpha: 0.15),
                            child: Text(
                              initial,
                              style: TextStyle(color: j.tier.color, fontWeight: FontWeight.bold),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.sosEmergency,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SOS',
                                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
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
                                style: AppTypography.captionSmall.copyWith(color: bodyColor),
                              ),
                            ],
                          ),
                          trailing: Icon(Icons.chevron_right_rounded, color: bodyColor),
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
                onPressed: isDeleting ? null : () => Navigator.of(dialogCtx).pop(),
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
                              title: 'Room Dihapus',
                              message: 'Room "${room.name}" telah berhasil dihapus.',
                            );
                          }
                        } catch (e) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isDeleting = false);
                          }
                          if (context.mounted) {
                            AppAlert.error(
                              context,
                              title: 'Gagal Menghapus',
                              message: e.toString().replaceFirst('Exception: ', ''),
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

  // ── Linear Metric Column Helper (Bottom Row of Room Card) ─────────────────
  Widget _buildRoomLinearMetric({
    required BuildContext context,
    required String title,
    required Widget valueWidget,
    required double progress,
    required Color barColor,
    required bool isDark,
    required Color headingColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: headingColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 4.5,
            backgroundColor: barColor.withValues(alpha: isDark ? 0.2 : 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        valueWidget,
      ],
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
