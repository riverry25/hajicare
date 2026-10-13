import '../../../core/locales/app_localizations.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
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
    final hc = context.hc;
    final isDark = hc.isDark;
    final cardBg = hc.surface;
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;
    final primaryColor = hc.brand;

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
          room?.name ??
          (hasRoom
              ? context.tr('dashboard.monitoringRoom')
              : context.tr('dashboard.noRoomYet'));
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
            border: Border.all(color: hc.border, width: 1.2),
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
                      color: hc.warningContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: hc.warning,
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
                              ? context.tr('dashboard.noActiveRoomYet')
                              : context.tr('dashboard.notConnectedToRoom'),
                          style: TextStyle(
                            color: headingColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPendamping
                              ? context.tr('dashboard.companionNoRoomDesc')
                              : context.tr('dashboard.jamaahNoRoomDesc'),
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
                        label: Text(
                          context.tr('room.joinRoomTitle'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          foregroundColor: primaryColor,
                          side: BorderSide(color: hc.border),
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
                        label: Text(
                          context.tr('room.createRoomTitle'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: primaryColor,
                          foregroundColor: hc.onBrand,
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
                    label: Text(
                      context.tr('dashboard.joinMonitoringRoom'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: primaryColor,
                      foregroundColor: hc.onBrand,
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

      // ── Syncing / Skeleton State (Memiliki Room Tapi Data Sedang Dimuat) ───
      if (room == null) {
        return ActiveRoomSkeletonCard(isDark: isDark);
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
          border: Border.all(color: hc.border, width: 1.2),
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
                              color: hc.brand,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('dashboard.roomAndMaktab'),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : hc.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.meeting_room_rounded,
                                      color: hc.brand,
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
                                        color: hc.primaryContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        context.tr('room.active'),
                                        style: TextStyle(
                                          color: hc.primary,
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
                              color: hc.sandDark,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('dashboard.maktabCompanion'),
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : hc.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      color: hc.sandDark,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        state.pendampingName.value.isNotEmpty
                                            ? state.pendampingName.value
                                            : context.tr(
                                                'dashboard.maktabOfficer',
                                              ),
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
                                        color: hc.successContainer,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        context.tr('dashboard.standby'),
                                        style: TextStyle(
                                          color: hc.success,
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
                            trackColor: hc.surfaceSand,
                            arcColor: hc.brand,
                            dotColor: hc.brandAccent,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
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
                                      isPendamping
                                          ? context.tr('room.roleJamaah')
                                          : context.tr('dashboard.members'),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white60
                                            : hc.textSecondary,
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
                      ),
                    ),
                    if (isCreator) ...[
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: hc.surfaceSand,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hc.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: headingColor,
                            size: 17,
                          ),
                        ),
                        tooltip: context.tr('room.groupSettingsBadge'),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(color: hc.borderSubtle),
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
                                  context.tr('room.editRoom'),
                                  style: TextStyle(
                                    color: headingColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 8),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_forever_rounded,
                                  size: 20,
                                  color: hc.danger,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  context.tr('room.deleteRoom'),
                                  style: TextStyle(
                                    color: hc.danger,
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
            Divider(height: 1, color: hc.border),

            const SizedBox(height: 16),

            // ── Interactive Wavy Statistic: Radius Radar (Replaces Kode Room & linear bars) ──
            _RadarWaveStatisticWidget(
              radius: room.safeRadius,
              currentDistance: state.calculatedDistance.value,
              isDark: isDark,
              headingColor: headingColor,
            ),

            const SizedBox(height: 18),

            // ── Action Buttons Footer ───────────────────────────────
            Builder(
              builder: (context) {
                final textScaler = MediaQuery.textScalerOf(context);
                final isLargeScale = textScaler.scale(12) > 16.5;

                final Widget leftBtn;
                final Widget rightBtn;

                if (isPendamping) {
                  leftBtn = OutlinedButton.icon(
                    onPressed: () => _showMemberListSheet(
                      context,
                      state: state,
                      roomId: roomId,
                      roomName: roomName,
                      roomCode: roomCode,
                    ),
                    icon: const Icon(Icons.people_alt_rounded, size: 16),
                    label: Text(
                      context.tr('dashboard.pilgrimList'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: hc.border, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  );

                  rightBtn = ElevatedButton.icon(
                    onPressed: () => AddJamaahDialog.show(context, roomId),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                    label: Text(
                      context.tr('dashboard.invitePilgrim'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 44),
                      backgroundColor: primaryColor,
                      foregroundColor: hc.onBrand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 0,
                    ),
                  );
                } else {
                  leftBtn = OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (roomCode.isNotEmpty) {
                        _showQrModal(context, roomName, roomCode);
                      }
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                    label: Text(
                      context.tr('dashboard.qrRoom'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 44),
                      side: BorderSide(color: hc.border, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  );

                  rightBtn = ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Get.toNamed(AppRoutes.roomDetail, arguments: room);
                    },
                    icon: const Icon(Icons.meeting_room_rounded, size: 16),
                    label: Text(
                      context.tr('room.roomDetailTitle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      minimumSize: const Size(0, 44),
                      backgroundColor: primaryColor,
                      foregroundColor: hc.onBrand,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 0,
                    ),
                  );
                }

                if (isLargeScale) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [leftBtn, const SizedBox(height: 8), rightBtn],
                  );
                }

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: leftBtn),
                      const SizedBox(width: 8),
                      Expanded(child: rightBtn),
                    ],
                  ),
                );
              },
            ),
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
    final hc = context.hc;
    final cardBg = hc.surface;
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;

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
                      color: hc.borderSubtle,
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
                          context.tr('dashboard.pilgrimsInRoom'),
                          style: context.text.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          context.tr('dashboard.pilgrimsRegisteredTapDetail', {
                            'count': '${jamaahList.length}',
                          }),
                          style: context.text.captionSmall.copyWith(
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
                Divider(height: 16, color: hc.borderSubtle),
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
                            context.tr('dashboard.noRegisteredPilgrims'),
                            style: context.text.bodyMedium.copyWith(
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
                            label: Text(context.tr('room.invitePilgrimNow')),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: jamaahList.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: hc.borderSubtle),
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
                                  style: context.text.bodyMedium.copyWith(
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
                                    color: hc.danger,
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
                                style: context.text.captionSmall.copyWith(
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
    final hc = context.hc;
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;

    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: hc.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sheet),
              side: BorderSide(color: hc.borderSubtle),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hc.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: hc.danger,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('room.deleteRoomTitle'),
                    style: context.text.titleMedium.copyWith(
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
                  context.tr('room.deleteRoomDesc', {
                    'name': '${room.name} (${room.code})',
                  }),
                  style: context.text.bodySmall.copyWith(
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
                  context.tr('common.cancel'),
                  style: TextStyle(
                    color: bodyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hc.danger,
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
                              message: context.tr('room.roomDeletedDesc', {
                                'name': room.name,
                              }),
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
                                fallback: context.tr(
                                  'room.deleteFailedFallback',
                                ),
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
                  isDeleting ? '...' : context.tr('room.deleteRoom'),
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

  Color _waveColor(HajiColors hc) {
    if (_isOutOfRadius) {
      return hc.danger;
    }
    return hc.success;
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final effectiveRadius = widget.radius > 0 ? widget.radius : 500.0;
    final isWarning = _isOutOfRadius;
    final waveColor = _waveColor(hc);
    final hasDist =
        widget.currentDistance != null && widget.currentDistance! > 0;
    final displayDist = hasDist ? widget.currentDistance! : effectiveRadius;

    final badgeBg = isWarning
        ? hc.danger.withValues(alpha: widget.isDark ? 0.25 : 0.12)
        : hc.success.withValues(alpha: widget.isDark ? 0.25 : 0.12);

    final badgeTextColor = isWarning ? hc.danger : hc.success;

    final badgeText = isWarning
        ? context.tr('dashboard.outOfRadiusBadge')
        : context.tr('dashboard.metersSafeBadge', {
            'meters': '${effectiveRadius.round()}',
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.radar_rounded,
                    size: 17,
                    color: isWarning ? hc.danger : hc.brand,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      context.tr('room.radarRadius'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.headingColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                        textScaler: MediaQuery.textScalerOf(context),
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
  final TextScaler textScaler;

  const _RadarWavePainter({
    required this.waveColor,
    required this.wavePhase,
    required this.tapPhase,
    required this.isTapped,
    required this.displayDistance,
    required this.isDark,
    required this.textScaler,
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
      textScaler: textScaler,
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
      old.isDark != isDark ||
      old.textScaler != textScaler;
}

/// Shimmering skeleton loading card displayed when room is connected
/// but activeRoom document data is still synchronizing from Firestore.
class ActiveRoomSkeletonCard extends StatefulWidget {
  final bool? isDark;

  const ActiveRoomSkeletonCard({super.key, this.isDark});

  @override
  State<ActiveRoomSkeletonCard> createState() => _ActiveRoomSkeletonCardState();
}

class _ActiveRoomSkeletonCardState extends State<ActiveRoomSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final dark = widget.isDark ?? hc.isDark;
    final cardBg = hc.surface;
    final primaryColor = hc.brand;
    final headingColor = hc.textPrimary;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final shimmerAlpha = 0.25 + (_pulseAnim.value * 0.35);
        final baseShimmerColor = dark
            ? Colors.white.withValues(alpha: shimmerAlpha * 0.3)
            : const Color(0xFFCBD5E1).withValues(alpha: shimmerAlpha);

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
              topRight: Radius.circular(52),
            ),
            border: Border.all(color: hc.borderSubtle, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.black.withValues(alpha: 0.3)
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
              // Top Row: 2 metrics on left + Gauge on right
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room name item placeholder
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 3.5,
                              height: 36,
                              decoration: BoxDecoration(
                                color: hc.brand.withValues(alpha: shimmerAlpha),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: baseShimmerColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        width: 110,
                                        height: 15,
                                        decoration: BoxDecoration(
                                          color: baseShimmerColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 42,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withValues(
                                            alpha: shimmerAlpha * 0.4,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
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
                        // Companion item placeholder
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 3.5,
                              height: 36,
                              decoration: BoxDecoration(
                                color: hc.brandSecondary.withValues(
                                  alpha: shimmerAlpha,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 95,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: baseShimmerColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: baseShimmerColor,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 46,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: hc.success.withValues(
                                            alpha: shimmerAlpha * 0.4,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
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
                  // Circular gauge placeholder
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: baseShimmerColor, width: 4),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                primaryColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            context.tr('room.syncing'),
                            style: TextStyle(
                              color: headingColor.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: hc.borderSubtle),
              const SizedBox(height: 14),
              // Synchronizing message row
              Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    size: 15,
                    color: primaryColor.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('room.syncingPleaseWait'),
                      style: TextStyle(
                        color: headingColor.withValues(alpha: 0.75),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
