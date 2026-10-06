import 'dart:async';
import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../presentation/dashboard_typography.dart';
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

    String sosName = context.tr('room.roleJamaah');
    String sosUserId = '';
    String? sosEventId;
    String? roomInfo;

    if (state.activeSosEvents.isNotEmpty) {
      final firstSos = state.activeSosEvents.first;
      sosName = (firstSos['userName'] as String?)?.trim().isNotEmpty == true
          ? (firstSos['userName'] as String).trim()
          : context.tr('room.roleJamaah');
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
                          style: DashboardTypography.titleMedium.copyWith(
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
                      style: DashboardTypography.bodySmall.copyWith(
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
                    label: Text(
                      context.tr('dashboard.reviewEmergency'),
                      style: const TextStyle(
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
                      style: DashboardTypography.labelLarge.copyWith(
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
                        style: DashboardTypography.titleMedium.copyWith(
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
                        style: DashboardTypography.captionSmall.copyWith(
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
                  style: DashboardTypography.bodySmall.copyWith(
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallBtn(
                        icon: Icons.volume_up_rounded,
                        label: context.tr('testAlarmSignal'),
                        bg: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.canvasCream,
                        fg: isDark
                            ? AppColors.goldLight
                            : AppColors.espressoDark,
                        outline: false,
                        onTap: () => _handleTestAlarm(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildSmallBtn(
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
    final isDark = AppColors.isDark(context);
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AlarmTestDialog(isDark: isDark),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uji sinyal alarm selesai. Sirene & getar berfungsi normal.',
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (context.mounted) {
        Clipboard.setData(ClipboardData(text: cleanPhone));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nomor $cleanPhone telah disalin ke clipboard.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
      isScrollControlled: true,
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
          child: SingleChildScrollView(
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
                            context.tr('dashboard.emergencyResponseCenter'),
                            style: DashboardTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('dashboard.emergencyResponseCenterSub'),
                            style: DashboardTypography.captionSmall.copyWith(
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
                  title: context.tr('dashboard.hotlineKemenag'),
                  subtitle: 'Layanan Pengaduan & Bantuan Jamaah RI',
                  number: '800-119-999',
                  icon: Icons.support_agent_rounded,
                  isDark: isDark,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                ),
                const SizedBox(height: 10),
                _buildHotlineCard(
                  ctx,
                  title: context.tr('dashboard.redCrescent'),
                  subtitle: 'Gawat Darurat Medis & Ambulans',
                  number: '997',
                  icon: Icons.medical_services_rounded,
                  isDark: isDark,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                ),
                const SizedBox(height: 10),
                _buildHotlineCard(
                  ctx,
                  title: context.tr('dashboard.saudiPolice'),
                  subtitle: 'Kepolisian & Pertolongan Darurat Umum',
                  number: '911',
                  icon: Icons.local_police_rounded,
                  isDark: isDark,
                  headingColor: headingColor,
                  bodyColor: bodyColor,
                ),
                const SizedBox(height: 10),
                _buildHotlineCard(
                  ctx,
                  title: 'KKHI Makkah / Madinah',
                  subtitle: 'Balai Kesehatan & Pengobatan Haji RI',
                  number: '+966 12 542 0000',
                  icon: Icons.local_hospital_rounded,
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
                    label: Text(
                      context.tr('dashboard.openEmergencyPanel'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
      ),
    );
  }

  Widget _buildHotlineCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String number,
    required IconData icon,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _makePhoneCall(context, number),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.canvasCream,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark
                  ? AppColors.darkOutlineVariant
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.sosEmergency.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, size: 20, color: AppColors.sosEmergency),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: bodyColor.withValues(alpha: 0.75),
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
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
              // Call direct button
              IconButton(
                tooltip: 'Panggil',
                icon: const Icon(
                  Icons.phone_forwarded_rounded,
                  color: AppColors.statusSafe,
                  size: 21,
                ),
                onPressed: () => _makePhoneCall(context, number),
              ),
              // Copy button
              IconButton(
                tooltip: context.tr('dashboard.copy'),
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: bodyColor.withValues(alpha: 0.8),
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: number));
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr('dashboard.numberCopied', {
                          'number': number,
                        }),
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: outline
                ? Border.all(color: borderColor ?? fg, width: 1.2)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: DashboardTypography.caption.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmTestDialog extends StatefulWidget {
  final bool isDark;
  const _AlarmTestDialog({required this.isDark});

  @override
  State<_AlarmTestDialog> createState() => _AlarmTestDialogState();
}

class _AlarmTestDialogState extends State<_AlarmTestDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;
  Timer? _soundTimer;
  Timer? _durationTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _startAlarmTest();
  }

  void _startAlarmTest() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);

    try {
      Vibration.hasVibrator().then((hasVib) {
        if (hasVib == true && mounted) {
          Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 500], repeat: 0);
        }
      });
    } catch (_) {}

    _soundTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    });

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  void _stopAlarmTest() {
    _soundTimer?.cancel();
    _soundTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    _pulseAnim.stop();
    try {
      Vibration.cancel();
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopAlarmTest();
    _pulseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Dialog(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
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
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.15).animate(
                CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.sosEmergency.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.sosEmergency.withValues(alpha: 0.6),
                    width: 2.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.sosEmergency,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('dashboard.alarmTestRunning'),
              style: DashboardTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.darkTextHeading
                    : AppColors.espressoDark,
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sosEmergency.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.sosEmergency,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sirene & Getar Aktif (${_secondsElapsed.toString().padLeft(2, '0')}s)',
                    style: const TextStyle(
                      color: AppColors.sosEmergency,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('dashboard.alarmTestDone'),
              style: DashboardTypography.bodySmall.copyWith(
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
                  _stopAlarmTest();
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.stop_circle_rounded, size: 18),
                label: Text(
                  context.tr('dashboard.finishTest'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
  }
}
