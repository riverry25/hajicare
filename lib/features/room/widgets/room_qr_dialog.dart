import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/room_model.dart';

/// Modal dialog that displays a high-resolution QR code and copy/share actions for a Room.
class RoomQrDialog extends StatelessWidget {
  final RoomModel room;
  final bool isSheetMode;

  const RoomQrDialog({
    super.key,
    required this.room,
    this.isSheetMode = false,
  });

  /// Displays the QR Code dialog for the given [room].
  static Future<void> show(BuildContext context, {required RoomModel room}) {
    HapticFeedback.lightImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RoomQrDialog(room: room),
    );
  }

  /// Displays the QR Code bottom sheet for the given [room].
  static Future<void> showBottomSheet(BuildContext context, {required RoomModel room}) {
    HapticFeedback.lightImpact();
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdgeGutter,
              vertical: AppSpacing.lg,
            ),
            child: RoomQrDialog(room: room, isSheetMode: true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isSheetMode) ...[
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: bodyColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],

        // ── Header Row ────────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(Icons.qr_code_2_rounded, color: primaryColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.name,
                    style: AppTypography.titleMedium.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
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
                        room.isActive ? 'Room Aktif Dipantau' : 'Room Nonaktif',
                        style: AppTypography.captionSmall.copyWith(
                          color: room.isActive ? AppColors.statusSafe : bodyColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 22),
              color: bodyColor.withValues(alpha: 0.7),
              tooltip: 'Tutup',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Divider(
          height: 1,
          color: isDark ? AppColors.darkCardBorder : AppColors.canvasCreamSubtle,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Scan Instruction ──────────────────────────────────────────────────
        Text(
          'Pindai QR Code ini menggunakan aplikasi Jamaah atau Pendamping untuk langsung bergabung.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: bodyColor.withValues(alpha: 0.85),
            height: 1.35,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── QR Code Frame ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            width: 195,
            height: 195,
            child: QrImageView(
              data: room.code,
              version: QrVersions.auto,
              size: 195,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: isDark ? const Color(0xFF1B1813) : const Color(0xFF2D241E),
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: isDark ? const Color(0xFF1B1813) : const Color(0xFF2D241E),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Room Code Badge (Tap to Copy) ──────────────────────────────────────
        InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            Clipboard.setData(ClipboardData(text: room.code));
            AppAlert.success(
              context,
              title: 'Kode Disalin',
              message: 'Kode room "${room.code}" berhasil disalin.',
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key_rounded, size: 18, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  room.code,
                  style: AppTypography.titleLarge.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.copy_rounded, size: 14, color: primaryColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ketuk kode di atas untuk menyalin cepat',
          style: AppTypography.captionSmall.copyWith(
            color: bodyColor.withValues(alpha: 0.65),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Action Buttons ────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.share_rounded, size: 17),
                label: const Text(
                  'Bagikan Teks',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final shareText = "Assalamu'alaikum, bergabunglah ke rombongan '${room.name}' di aplikasi HajiCare.\n\nKode Room: ${room.code}\n\nMasukkan kode tersebut pada menu 'Gabung Room' di aplikasi HajiCare.";
                  Clipboard.setData(ClipboardData(text: shareText));
                  AppAlert.success(
                    context,
                    title: 'Teks Undangan Disalin',
                    message: 'Format teks undangan berhasil disalin ke clipboard untuk dibagikan ke WhatsApp / grup.',
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark ? AppColors.darkOnPrimary : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 1,
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text(
                  'Selesai',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ],
    );

    if (isSheetMode) {
      return content;
    }

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : primaryColor.withValues(alpha: 0.25),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: content,
          ),
        ),
      ),
    );
  }
}
