import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import 'package:vibration/vibration.dart';

class PendampingSosBanner extends StatelessWidget {
  final HajiCareState state;
  final Future<void> Function(String jamaahId)? onDismissSos;

  const PendampingSosBanner({
    super.key,
    required this.state,
    this.onDismissSos,
  });

  @override
  Widget build(BuildContext context) {
    if (state.anySosActive) {
      return _buildActiveSos(context);
    }
    return _buildStandbySos(context);
  }

  Widget _buildActiveSos(BuildContext context) {
    Vibration.vibrate();

    String sosName = 'Jamaah';
    String sosUserId = '';
    String? sosEventId;
    String? roomInfo;

    if (state.activeSosEvents.isNotEmpty) {
      final firstSos = state.activeSosEvents.first;
      sosName = (firstSos['userName'] as String?)?.trim().isNotEmpty == true
          ? (firstSos['userName'] as String).trim()
          : 'Jamaah';
      sosUserId =
          firstSos['userId'] as String? ??
          firstSos['jamaahId'] as String? ??
          '';
      sosEventId = firstSos['id'] as String?;
      final rName = (firstSos['roomName'] as String?)?.trim();
      if (rName != null && rName.isNotEmpty) {
        roomInfo = rName;
      }
    } else {
      final sosJamaah = state.jamaahList.firstWhere(
        (j) => j.sosActive,
        orElse: () => state.jamaahList.first,
      );
      sosName = sosJamaah.name;
      sosUserId = sosJamaah.id;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.sosEmergency,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.sosEmergency.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.tr('sosEmergencyActive'),
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (roomInfo != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              roomInfo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sosName ${context.tr('sosNeedsImmediateHelp')}',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.modalSos),
                    icon: const Icon(
                      Icons.location_searching_rounded,
                      size: 18,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.sosEmergency,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 0,
                    ),
                    label: const Text(
                      'Tinjau Darurat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      if (onDismissSos != null && sosUserId.isNotEmpty) {
                        onDismissSos!(sosUserId);
                      } else {
                        state.dismissSos(sosUserId, eventId: sosEventId);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    child: Text(
                      context.tr('endSos'),
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandbySos(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      borderColor: isDark
          ? AppColors.darkCardBorder
          : AppColors.lightCardBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.canvasCream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: isDark ? AppColors.goldLight : AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        context.tr('sosStatusStandby'),
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.secondaryContainer.withValues(
                                alpha: 0.6,
                              ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        context.tr('sosStandbyBadge'),
                        style: AppTypography.captionSmall.copyWith(
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr('sosStandbyDesc'),
                  style: AppTypography.bodySmall.copyWith(color: bodyColor),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _buildSmallBtn(
                      icon: Icons.volume_up_rounded,
                      label: context.tr('testAlarmSignal'),
                      bg: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream,
                      fg: isDark ? AppColors.goldLight : AppColors.espressoDark,
                      outline: false,
                      onTap: () => _handleTestAlarm(context),
                    ),
                    _buildSmallBtn(
                      icon: Icons.call_rounded,
                      label: context.tr('responseCenter'),
                      bg: Colors.transparent,
                      fg: AppColors.sosEmergency,
                      outline: true,
                      borderColor: AppColors.sosEmergency.withValues(
                        alpha: 0.4,
                      ),
                      onTap: () => _handleResponseCenter(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTestAlarm(BuildContext context) async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);

    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        Vibration.vibrate(pattern: [0, 300, 150, 300, 150, 400]);
      }
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final isDark = AppColors.isDark(ctx);
        return Dialog(
          backgroundColor: isDark
              ? AppColors.darkSurface
              : AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accentGoldStar.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.goldPrimary,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Uji Sinyal Alarm Berjalan',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.espressoDark,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Uji bunyi dan getar pada ponsel ini sudah selesai.',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      try {
                        Vibration.cancel();
                      } catch (_) {}
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Selesai Uji Coba',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espressoDark,
                      foregroundColor: AppColors.surfaceWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      try {
        Vibration.cancel();
      } catch (_) {}
    });
  }

  void _handleResponseCenter(BuildContext context) {
    HapticFeedback.selectionClick();
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
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
                    color: isDark
                        ? AppColors.darkOutline
                        : AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.sosEmergency.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.phone_in_talk_rounded,
                        color: AppColors.sosEmergency,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pusat Tanggap Darurat',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Akses cepat nomor darurat & pemantauan krisis',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildHotlineCard(
                ctx,
                title: 'Hotline Krisis Kemenag RI',
                number: '800-119-999',
                icon: Icons.support_agent_rounded,
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
              ),
              const SizedBox(height: 10),
              _buildHotlineCard(
                ctx,
                title: 'Ambulans Arab Saudi (Red Crescent)',
                number: '997',
                icon: Icons.medical_services_rounded,
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
              ),
              const SizedBox(height: 10),
              _buildHotlineCard(
                ctx,
                title: 'Polisi Darurat Arab Saudi',
                number: '911',
                icon: Icons.local_police_rounded,
                isDark: isDark,
                headingColor: headingColor,
                bodyColor: bodyColor,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Get.toNamed(AppRoutes.modalSos);
                  },
                  icon: const Icon(Icons.emergency_rounded, size: 20),
                  label: const Text(
                    'Buka Panel Darurat SOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sosEmergency,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHotlineCard(
    BuildContext context, {
    required String title,
    required String number,
    required IconData icon,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.espressoDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.sosEmergency,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: number));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nomor $number sudah disalin.'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.copy_rounded,
                    size: 14,
                    color: AppColors.espressoDark,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Salin',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.espressoDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBtn({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required bool outline,
    Color? borderColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: outline
                ? Border.all(color: borderColor ?? fg, width: 1.2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
