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
import 'add_jamaah_dialog.dart';

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

      final roomName = room?.name ?? 'Room Pemantauan';
      final roomCode = room?.code ?? '';

      return AppCard(
        backgroundColor: cardBg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon + Room Name + Member Count Chip
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.meeting_room_rounded, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roomName,
                          style: AppTypography.titleSmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          isPendamping
                              ? '$jamaahCount Jamaah terpantau di room ini'
                              : 'Pendamping: ${state.pendampingName.value}',
                          style: AppTypography.captionSmall.copyWith(color: bodyColor),
                        ),
                      ],
                    ),
                  ),
                  if (roomCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            roomCode,
                            style: AppTypography.captionSmall.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: roomCode));
                              AppAlert.info(
                                context,
                                title: 'Kode Disalin',
                                message: 'Kode room $roomCode berhasil disalin ke clipboard.',
                              );
                            },
                            child: Icon(Icons.copy_rounded, size: 14, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              // Action button for Pendamping: "Tambah Jamaah"
              if (isPendamping && roomId != null && roomId.isNotEmpty) ...[
                const Divider(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => AddJamaahDialog.show(context, roomId),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('Tambah Jamaah ke Room'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }
}
