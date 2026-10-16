import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/services/adhan_audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_context.dart';
import '../../prayer/controllers/prayer_times_controller.dart';

/// Responsive, accessible banner displayed at the top of the Jamaah & Pendamping Dashboards
/// whenever an Adhan alarm is actively sounding.
///
/// Features:
/// 1. Adheres to `flutter-build-responsive-layout` with `LayoutBuilder` and flexible breakpoints.
/// 2. Provides a prominent, senior-friendly "Matikan Adzan" button with >= 48px touch target.
/// 3. Instantly silences audio across both native Android Foreground Service and Flutter players.
class ActiveAdhanDashboardBanner extends StatefulWidget {
  const ActiveAdhanDashboardBanner({super.key});

  @override
  State<ActiveAdhanDashboardBanner> createState() =>
      _ActiveAdhanDashboardBannerState();
}

class _ActiveAdhanDashboardBannerState extends State<ActiveAdhanDashboardBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDark = context.isDark;

    return Obx(() {
      final prayerCtrl = Get.isRegistered<PrayerTimesController>()
          ? Get.find<PrayerTimesController>()
          : null;
      final adhanService = Get.isRegistered<AdhanAudioService>()
          ? Get.find<AdhanAudioService>()
          : AdhanAudioService.instance;

      final isPlaying =
          prayerCtrl?.isAdhanPlaying.value ??
          adhanService?.isPlaying.value ??
          false;

      if (!isPlaying) {
        return const SizedBox.shrink();
      }

      final rawPrayerName =
          prayerCtrl?.playingPrayerName.value.isNotEmpty == true
          ? prayerCtrl!.playingPrayerName.value
          : (adhanService?.currentPrayerName.value ?? '');
      final prayerName = rawPrayerName.isNotEmpty
          ? context.localizedPrayerName(rawPrayerName)
          : 'Waktu Salat';

      return LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 360;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF1A3528), Color(0xFF14281E)]
                    : const [AppColors.emeraldLight, Color(0xFFD6EAE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.islamic.withValues(alpha: isDark ? 0.6 : 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.islamic.withValues(alpha: isDark ? 0.35 : 0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _buildAnimatedIcon(colors),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextContent(
                              context,
                              prayerName,
                              colors,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStopButton(
                        context,
                        prayerCtrl,
                        adhanService,
                        colors,
                        fullWidth: true,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      _buildAnimatedIcon(colors),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextContent(
                          context,
                          prayerName,
                          colors,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildStopButton(
                        context,
                        prayerCtrl,
                        adhanService,
                        colors,
                        fullWidth: false,
                      ),
                    ],
                  ),
          );
        },
      );
    });
  }

  Widget _buildAnimatedIcon(dynamic colors) {
    return ScaleTransition(
      scale: _pulseScale,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.islamic.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.volume_up_rounded, color: colors.islamic, size: 24),
      ),
    );
  }

  Widget _buildTextContent(
    BuildContext context,
    String prayerName,
    dynamic colors,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Adzan $prayerName Berkumandang',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? colors.textPrimary : colors.islamic,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Suara adzan sedang diputar',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark
                ? colors.textSecondary
                : colors.islamic.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStopButton(
    BuildContext context,
    PrayerTimesController? prayerCtrl,
    AdhanAudioService? adhanService,
    dynamic colors, {
    required bool fullWidth,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.heavyImpact();
          prayerCtrl?.stopAdhan();
          adhanService?.stopAdhan();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.symmetric(
            horizontal: fullWidth ? 16 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: colors.danger,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors.danger.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.volume_off_rounded, color: colors.onDanger, size: 18),
              const SizedBox(width: 6),
              Text(
                'Matikan Adzan',
                style: TextStyle(
                  color: colors.onDanger,
                  fontSize: 13,
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
