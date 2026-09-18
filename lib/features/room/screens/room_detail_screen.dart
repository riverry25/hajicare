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

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminRoomController>();
    final room = (Get.arguments as RoomModel?) ?? controller.selectedRoom.value;

    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.canvasCream;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    if (room == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(title: const Text('Detail Room')),
        body: const Center(child: Text('Data room tidak ditemukan.')),
      );
    }

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
          room.name,
          style: AppTypography.headlineMedium.copyWith(
            color: headingColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenEdgeGutter),
        children: [
          // 1. Room Metadata Card
          AppCard(
            backgroundColor: cardBg,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Informasi Room',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: room.isActive
                              ? AppColors.statusSafe.withValues(alpha: 0.15)
                              : AppColors.espressoDark.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          room.isActive ? 'Aktif' : 'Nonaktif',
                          style: AppTypography.captionSmall.copyWith(
                            color: room.isActive ? AppColors.statusSafe : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Kode Room Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kode Room:', style: AppTypography.bodySmall.copyWith(color: bodyColor)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              room.code,
                              style: AppTypography.titleSmall.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            color: bodyColor,
                            tooltip: 'Salin Kode',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: room.code));
                              AppAlert.info(
                                context,
                                title: 'Kode Disalin',
                                message: 'Kode room ${room.code} berhasil disalin ke clipboard.',
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Created Date Row
                  if (room.createdAt != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dibuat Pada:', style: AppTypography.bodySmall.copyWith(color: bodyColor)),
                        Text(
                          '${room.createdAt!.day}/${room.createdAt!.month}/${room.createdAt!.year}',
                          style: AppTypography.bodySmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Members Section Header
          Obx(() {
            final totalMembers = controller.roomMembers.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Anggota ($totalMembers)',
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.md),

          // 3. Members List
          Obx(() {
            final members = controller.roomMembers;

            if (members.isEmpty) {
              return AppCard(
                backgroundColor: cardBg,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: bodyColor.withValues(alpha: 0.5)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Belum ada anggota yang bergabung',
                          style: AppTypography.bodySmall.copyWith(color: bodyColor),
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
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final RoomModel room;
  final RoomMemberModel member;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;

  const _MemberTile({
    required this.room,
    required this.member,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
  });

  void _handleRemoveJamaah(BuildContext context) {
    AppAlert.confirm(
      context,
      title: 'Keluarkan Jamaah?',
      message: 'Jamaah ini akan dikeluarkan dari room dan fitur yang membutuhkan room akan dinonaktifkan.',
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

    if (member.isPendamping) {
      badgeBg = Colors.blue.withValues(alpha: 0.15);
      badgeTextColor = Colors.blue.shade700;
      roleLabel = 'Pendamping';
    } else if (member.isJamaah) {
      badgeBg = AppColors.statusSafe.withValues(alpha: 0.15);
      badgeTextColor = AppColors.statusSafe;
      roleLabel = 'Jamaah';
    } else {
      badgeBg = AppColors.accentGoldStar.withValues(alpha: 0.15);
      badgeTextColor = AppColors.primaryGold;
      roleLabel = 'Admin';
    }

    final initial = member.name.trim().isNotEmpty ? member.name.trim()[0].toUpperCase() : '?';

    return AppCard(
      backgroundColor: cardBg,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeBg,
          child: Text(
            initial,
            style: TextStyle(color: badgeTextColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          member.name,
          style: AppTypography.titleSmall.copyWith(
            color: headingColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          member.joinedAt != null
              ? 'Bergabung: ${member.joinedAt!.day}/${member.joinedAt!.month}/${member.joinedAt!.year}'
              : 'Baru saja bergabung',
          style: AppTypography.captionSmall.copyWith(color: bodyColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                roleLabel,
                style: AppTypography.captionSmall.copyWith(
                  color: badgeTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (member.isJamaah) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.person_remove_rounded, size: 20),
                color: AppColors.error,
                tooltip: 'Keluarkan dari Room',
                onPressed: () => _handleRemoveJamaah(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
