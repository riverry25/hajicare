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
import '../../../core/widgets/app_card.dart';
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
        if (isPendamping) {
          // Pendamping without Room: Two clear, separate buttons (Buat Room / Gabung Room)
          return AppCard(
            backgroundColor: cardBg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.lock_outline_rounded, color: AppColors.statusWarning, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Belum Memiliki Room',
                              style: AppTypography.titleSmall.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Buat room baru atau gabung ke room yang sudah ada untuk mengaktifkan radar monitoring jamaah.',
                              style: AppTypography.captionSmall.copyWith(color: bodyColor, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Get.toNamed('/join_room');
                          },
                          icon: const Icon(Icons.login_rounded, size: 16),
                          label: const Text('Gabung Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.toNamed('/join_room');
                          },
                          icon: const Icon(Icons.add_business_rounded, size: 16),
                          label: const Text('Buat Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: isDark ? AppColors.espressoDark : AppColors.surfaceWhite,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else {
          // Jamaah without Room: Locked state with CTA
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            backgroundColor: cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.statusWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: AppColors.statusWarning, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Belum Terhubung ke Room',
                            style: AppTypography.titleSmall.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gabung room untuk mengaktifkan monitoring pendamping dan darurat SOS.',
                            style: AppTypography.captionSmall.copyWith(color: bodyColor, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/join_room'),
                    icon: const Icon(Icons.login_rounded, size: 16),
                    label: const Text('Gabung Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark ? AppColors.espressoDark : AppColors.surfaceWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }

      // ── Connected State (Memiliki Room Aktif) ──────────────────────────────
      return AppCard(
        backgroundColor: cardBg,
        borderRadius: 20,
        borderColor: isDark
            ? AppColors.darkOutlineVariant
            : AppColors.goldLight.withValues(alpha: 0.35),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.espressoDark.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header Row: Room Emblem + Title & Inline Code + QR/Menu Actions ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Room Emblem
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer.withValues(alpha: 0.5)
                        : AppColors.canvasCream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.goldLight.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: isDark ? AppColors.goldLight : AppColors.primaryGold,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                // Title & Subtitle with Inline Room Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        roomName,
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6.5,
                            height: 6.5,
                            decoration: const BoxDecoration(
                              color: AppColors.statusSafe,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              isPendamping
                                  ? '$jamaahCount Jamaah'
                                  : 'Pendamping: ${state.pendampingName.value}',
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (roomCode.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: bodyColor.withValues(alpha: 0.4),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: roomCode));
                                AppAlert.info(
                                  context,
                                  title: 'Kode Disalin',
                                  message: 'Kode room $roomCode berhasil disalin ke clipboard.',
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurfaceContainerHigh
                                      : AppColors.canvasCream,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkOutlineVariant
                                        : AppColors.goldLight.withValues(alpha: 0.6),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      roomCode,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.goldLight
                                            : AppColors.espressoDark,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                        letterSpacing: 1.0,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 11,
                                      color: isDark
                                          ? AppColors.goldLight
                                          : AppColors.tanMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Quick Actions: QR & Menu
                if (roomCode.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showQrModal(context, roomName, roomCode);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 36,
                      height: 36,
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
                        Icons.qr_code_2_rounded,
                        color: headingColor,
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (isCreator) ...[
                  PopupMenuButton<String>(
                    icon: Container(
                      width: 36,
                      height: 36,
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
                        Icons.more_horiz_rounded,
                        color: headingColor,
                        size: 19,
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

            // ── Action Buttons (For Pendamping) ──
            if (isPendamping && roomId.isNotEmpty) ...[
              const SizedBox(height: 14),
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
                      icon: Icon(
                        Icons.people_alt_rounded,
                        size: 17,
                        color: headingColor,
                      ),
                      label: Text(
                        'Daftar Jamaah',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: headingColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.goldLight.withValues(alpha: 0.8),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainer.withValues(alpha: 0.4)
                            : AppColors.canvasCream.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => AddJamaahDialog.show(context, roomId),
                      icon: Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 17,
                        color: isDark ? AppColors.espressoDark : Colors.white,
                      ),
                      label: Text(
                        'Undang Jamaah',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? AppColors.espressoDark : Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── Info Note for Jamaah ──
            if (!isPendamping && roomId.isNotEmpty) ...[
              const SizedBox(height: 10),
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
                        color: AppColors.statusSafe,
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
}
