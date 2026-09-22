import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ribbon_fold_painter.dart';
import '../models/room_model.dart';

/// Modal dialog that displays a high-resolution QR code and copy/share actions for a Room.
class RoomQrDialog extends StatelessWidget {
  final RoomModel? room;
  final String? roomName;
  final String? roomCode;
  final bool? isActive;
  final bool isSheetMode;

  const RoomQrDialog({
    super.key,
    this.room,
    this.roomName,
    this.roomCode,
    this.isActive,
    this.isSheetMode = false,
  });

  String get effectiveRoomName =>
      room?.capitalizedName ??
      (roomName != null && roomName!.isNotEmpty
          ? roomName!
          : 'Room Pemantauan');

  String get effectiveRoomCode => room?.code ?? (roomCode ?? '');

  bool get effectiveIsActive => room?.isActive ?? (isActive ?? true);

  /// Displays the QR Code dialog for the given [room].
  static Future<void> show(BuildContext context, {required RoomModel room}) {
    HapticFeedback.lightImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RoomQrDialog(room: room),
    );
  }

  /// Displays the QR Code dialog using explicit room name and code.
  static Future<void> showDetails(
    BuildContext context, {
    required String roomName,
    required String roomCode,
    bool isActive = true,
  }) {
    HapticFeedback.lightImpact();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RoomQrDialog(
        roomName: roomName,
        roomCode: roomCode,
        isActive: isActive,
      ),
    );
  }

  /// Displays the QR Code bottom sheet for the given [room].
  static Future<void> showBottomSheet(
    BuildContext context, {
    required RoomModel room,
  }) {
    HapticFeedback.lightImpact();
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
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

  void _copyCode(BuildContext context) {
    HapticFeedback.mediumImpact();
    Clipboard.setData(ClipboardData(text: effectiveRoomCode));
    AppAlert.success(
      context,
      title: context.tr('room.codeCopied'),
      message: 'Kode rombongan "$effectiveRoomCode" sudah disalin.',
    );
  }

  void _shareText(BuildContext context) {
    HapticFeedback.lightImpact();
    final shareText =
        "Assalamu'alaikum, bergabunglah ke rombongan '$effectiveRoomName' di aplikasi HajiCare.\n\nKode rombongan: $effectiveRoomCode\n\nMasukkan kode tersebut pada menu 'Gabung Rombongan' di aplikasi HajiCare.";
    Clipboard.setData(ClipboardData(text: shareText));
    AppAlert.success(
      context,
      title: context.tr('room.invitationCopied'),
      message:
          'Teks undangan sudah disalin dan siap ditempel ke WhatsApp atau grup.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    // ── Bottom Sheet Mode ──────────────────────────────────────────────────
    if (isSheetMode) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                child: Icon(
                  Icons.qr_code_2_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      effectiveRoomName,
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
                            color: effectiveIsActive
                                ? AppColors.statusSafe
                                : AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          effectiveIsActive
                              ? 'Room Aktif Dipantau'
                              : 'Room Nonaktif',
                          style: AppTypography.captionSmall.copyWith(
                            color: effectiveIsActive
                                ? AppColors.statusSafe
                                : bodyColor.withValues(alpha: 0.7),
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
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.canvasCreamSubtle,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Pindai QR Code ini menggunakan aplikasi Jamaah atau Pendamping untuk langsung bergabung.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: bodyColor.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.canvasCreamSubtle,
                width: 1.5,
              ),
            ),
            child: SizedBox(
              width: 190,
              height: 190,
              child: QrImageView(
                data: effectiveRoomCode,
                version: QrVersions.auto,
                size: 190,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF2D241E),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF2D241E),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InkWell(
            onTap: () => _copyCode(context),
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
                    effectiveRoomCode,
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
                    child: Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: primaryColor,
                    ),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(
                      color: primaryColor.withValues(alpha: 0.5),
                    ),
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
                  onPressed: () => _shareText(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: isDark
                        ? AppColors.darkOnPrimary
                        : Colors.white,
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
    }

    // ── Dialog Mode (Adaptive Floating Design matching Reference Image) ────
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390, maxHeight: 630),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── 1. Main Card Body ──
            Container(
              margin: const EdgeInsets.only(
                top: 28,
                bottom: 12,
                right: 10,
                left: 10,
              ),
              padding: const EdgeInsets.fromLTRB(20, 68, 20, 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.09),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Name (Left-aligned, matching reference design)
                    Text(
                      effectiveRoomName,
                      style: AppTypography.titleMedium.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    // Room subtitle instruction (Left-aligned, matching reference design)
                    Text(
                      'Pindai QR atau bagikan kode untuk bergabung ke rombongan jamaah ini.',
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF7A6B5D),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // QR Code Frame (Centered)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.canvasCreamSubtle,
                            width: 1.5,
                          ),
                        ),
                        child: SizedBox(
                          width: 170,
                          height: 170,
                          child: QrImageView(
                            data: effectiveRoomCode,
                            version: QrVersions.auto,
                            size: 170,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF2D241E),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF2D241E),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Room Code Tap-to-Copy Pill (Centered)
                    Center(
                      child: InkWell(
                        onTap: () => _copyCode(context),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(
                              alpha: isDark ? 0.20 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.key_rounded,
                                size: 16,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                effectiveRoomCode,
                                style: AppTypography.titleLarge.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 3,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.copy_rounded,
                                size: 14,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Ketuk kode di atas untuk menyalin cepat',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.65),
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bottom Row: Close text button on left, space reserved for protruding button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white60
                                : const Color(0xFF8C7A6B),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 135),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Floating Hero Card (Compact header) ──
            Positioned(
              top: 0,
              left: 22,
              right: 22,
              height: 86,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF38251A), const Color(0xFF1F140D)]
                        : [AppColors.espressoDark, const Color(0xFF563B2A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -15,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.goldPrimary.withValues(alpha: 0.25),
                                  AppColors.goldPrimary.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.qr_code_2_rounded,
                                color: AppColors.accentGoldStar,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'KODE & QR ROMBONGAN',
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Protruding Ribbon Action Button (No shadow) ──
            Positioned(
              bottom: 0,
              right: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -10,
                    right: 0,
                    child: CustomPaint(
                      size: const Size(10, 10),
                      painter: RibbonFoldPainter(
                        color: isDark
                            ? const Color(0xFF140D08)
                            : const Color(0xFF160D07),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _shareText(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(5),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.espressoDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 13.5,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.share_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'BAGIKAN',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
