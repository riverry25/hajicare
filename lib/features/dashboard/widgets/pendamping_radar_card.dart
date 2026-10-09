import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/state/hajicare_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../presentation/dashboard_typography.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import '../../../../core/widgets/app_card.dart';
import '../../room/widgets/jamaah_detail_sheet.dart';
import 'adjust_safe_radius_dialog.dart';

class PendampingRadarCard extends StatelessWidget {
  final JamaahData jamaah;
  final VoidCallback? onTrackMap;

  const PendampingRadarCard({super.key, required this.jamaah, this.onTrackMap});

  String _localizedTierLabel(BuildContext context, DistanceTier tier) {
    switch (tier) {
      case DistanceTier.aman:
        return context.tr('statusSafe');
      case DistanceTier.waspada:
        return context.tr('statusWarning');
      case DistanceTier.terlalujJauh:
        return context.tr('statusDanger');
    }
  }

  String _formatTimestamp(BuildContext context, DateTime? dt) {
    if (dt == null) return context.tr('dashboard.waiting');
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return context.tr('dashboard.justNow');
    if (diff.inMinutes < 60) {
      return context.tr('dashboard.minutesAgo', {'minutes': diff.inMinutes});
    }
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDistanceValue(double distanceMeters) {
    if (distanceMeters >= 100000) {
      // >= 100 km (e.g. 7858 km)
      return (distanceMeters / 1000).toStringAsFixed(0);
    } else if (distanceMeters >= 1000) {
      // 1 km - 99.9 km (e.g. 1.2 km or 12.5 km)
      final km = distanceMeters / 1000;
      return km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    } else {
      return distanceMeters.toInt().toString();
    }
  }

  String _formatDistanceUnit(BuildContext context, double distanceMeters) {
    return distanceMeters >= 1000 ? 'km' : context.tr('meterUnit');
  }

  void _showRadiusSheet(BuildContext context) {
    AdjustSafeRadiusDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final hasActiveRoom =
          state?.activeRoomId.value != null &&
          state!.activeRoomId.value!.isNotEmpty;

      if (!hasActiveRoom) {
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          borderColor: isDark
              ? AppColors.darkCardBorder
              : AppColors.goldLight.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.canvasCream,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('dashboard.pilgrimRadar'),
                          style: DashboardTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr('dashboard.pilgrimRadarNeedsRoom'),
                          style: DashboardTypography.bodySmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.joinRoom),
                  icon: const Icon(Icons.meeting_room_outlined, size: 20),
                  label: Text(
                    context.tr('dashboard.createOrJoinRoom'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.espressoDark,
                    foregroundColor: isDark
                        ? AppColors.darkPrimary
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      final safeRadius = state.safeRadiusMeters.value;
      // GPS signal is only considered valid if we have a real coordinate AND isGpsActive flag.
      final hasSignal = jamaah.currentLocation != null && jamaah.isGpsActive;
      final hasSosEvent = state.activeSosEvents.any(
        (e) =>
            e['userId'] == jamaah.id ||
            e['jamaahId'] == jamaah.id ||
            e['userName'] == jamaah.name,
      );
      final isSos = jamaah.sosActive || hasSosEvent;
      final roomId = state.activeRoomId.value ?? '';
      final roomName =
          state.activeRoom.value?.capitalizedName ??
          context.tr('dashboard.monitoringRoom');
      final roomCode = state.activeRoom.value?.code ?? '';

      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBgColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSos
                ? AppColors.sosEmergency.withValues(alpha: 0.7)
                : AppColors.cardBorderColor(context),
            width: isSos ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSos
                  ? AppColors.sosEmergency.withValues(
                      alpha: isDark ? 0.25 : 0.15,
                    )
                  : (isDark ? Colors.black : AppColors.espressoDark).withValues(
                      alpha: isDark ? 0.35 : 0.08,
                    ),
              blurRadius: isSos ? 22 : 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Floating 3D Radar Wave Header (Ref 1 Elevated Header + Ref 2 Concentric Ripples) ─
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isSos
                    ? const LinearGradient(
                        colors: [Color(0xFF5C1010), Color(0xFF380808)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: isDark
                            ? [
                                AppColors.darkSurfaceContainerHigh,
                                AppColors.darkSurfaceContainerHighest,
                              ]
                            : [
                                AppColors.espressoDark,
                                AppColors.primaryContainer,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                border: isSos
                    ? Border.all(
                        color: AppColors.sosEmergency.withValues(alpha: 0.6),
                        width: 1.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color:
                        (isSos
                                ? AppColors.sosEmergency
                                : (isDark
                                      ? Colors.black
                                      : AppColors.espressoDark))
                            .withValues(
                              alpha: isSos ? 0.35 : (isDark ? 0.35 : 0.22),
                            ),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Concentric 3D Radar Ripple Waves (Photo 2)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RadarWavesPainter(
                          waveColor: isSos
                              ? AppColors.sosEmergency
                              : (hasSignal
                                    ? (jamaah.tier == DistanceTier.aman
                                          ? AppColors.goldLight
                                          : (jamaah.tier == DistanceTier.waspada
                                                ? AppColors.distanceWarning
                                                : AppColors.sosEmergency))
                                    : AppColors.tanLight),
                          centerFraction: const Offset(0.85, 0.28),
                        ),
                      ),
                    ),

                    // Subtle Glassmorphic Sheen
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(
                                alpha: isDark ? 0.07 : 0.12,
                              ),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),

                    // Content inside Floating Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Row: Radar Active Pill & Floating Status Emblem (Photo 2 - Dynamic Text Scale Responsive)
                          LayoutBuilder(
                            builder: (context, headerConstraints) {
                              final textScale = MediaQuery.textScalerOf(
                                context,
                              ).scale(1);
                              final bool mustWrapHeader =
                                  textScale > 1.12 ||
                                  headerConstraints.maxWidth < 315;

                              final radarActiveChip = Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSos
                                      ? AppColors.sosEmergency.withValues(
                                          alpha: 0.25,
                                        )
                                      : Colors.black.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: isSos
                                        ? AppColors.sosEmergency.withValues(
                                            alpha: 0.6,
                                          )
                                        : AppColors.goldLight.withValues(
                                            alpha: 0.35,
                                          ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedPingDot(
                                      color: isSos
                                          ? AppColors.sosEmergency
                                          : (hasSignal
                                                ? AppColors.accentGoldStar
                                                : AppColors.outlineVariant),
                                      size: 7,
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        isSos
                                            ? 'RADAR SOS'
                                            : context.tr(
                                                'dashboard.radarActive',
                                              ),
                                        style: TextStyle(
                                          color: isSos
                                              ? const Color(0xFFFF8A80)
                                              : AppColors.goldLight,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.9,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              final statusChip = Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isSos
                                      ? AppColors.sosEmergency.withValues(
                                          alpha: 0.4,
                                        )
                                      : (hasSignal
                                                ? jamaah.tier.color
                                                : AppColors.outline)
                                            .withValues(alpha: 0.26),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: isSos
                                        ? AppColors.sosEmergency
                                        : (hasSignal
                                                  ? jamaah.tier.color
                                                  : AppColors.outline)
                                              .withValues(alpha: 0.55),
                                    width: isSos ? 1.5 : 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSos
                                          ? AppColors.sosEmergency.withValues(
                                              alpha: 0.5,
                                            )
                                          : (hasSignal
                                                    ? jamaah.tier.color
                                                    : Colors.black)
                                                .withValues(alpha: 0.25),
                                      blurRadius: isSos ? 12 : 8,
                                      spreadRadius: isSos ? 1 : 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSos
                                          ? Icons.warning_amber_rounded
                                          : (hasSignal
                                                ? jamaah.tier.icon
                                                : Icons.hourglass_top_rounded),
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        isSos
                                            ? 'DARURAT SOS'
                                            : (hasSignal
                                                  ? _localizedTierLabel(
                                                      context,
                                                      jamaah.tier,
                                                    ).toUpperCase()
                                                  : context.tr(
                                                      'dashboard.waitingUpper',
                                                    )),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (mustWrapHeader) {
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [radarActiveChip, statusChip],
                                );
                              }

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  radarActiveChip,
                                  const SizedBox(width: 8),
                                  Flexible(child: statusChip),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // Pilgrim Identity Row
                          Row(
                            children: [
                              // Avatar circle with tier-colored halo ring
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSos
                                        ? AppColors.sosEmergency
                                        : (hasSignal
                                              ? jamaah.tier.color
                                              : AppColors.goldLight),
                                    width: isSos ? 2.5 : 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSos
                                          ? AppColors.sosEmergency.withValues(
                                              alpha: 0.6,
                                            )
                                          : (hasSignal
                                                    ? jamaah.tier.color
                                                    : AppColors.espressoDark)
                                                .withValues(alpha: 0.35),
                                      blurRadius: isSos ? 12 : 8,
                                      spreadRadius: isSos ? 1 : 0,
                                    ),
                                  ],
                                  gradient: LinearGradient(
                                    colors: isSos
                                        ? const [
                                            Color(0xFFD32F2F),
                                            Color(0xFFB71C1C),
                                          ]
                                        : const [
                                            AppColors.espressoDark,
                                            AppColors.primaryContainer,
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  jamaah.name.trim().isNotEmpty
                                      ? jamaah.name.trim()[0].toUpperCase()
                                      : 'J',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      jamaah.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6.5,
                                          height: 6.5,
                                          decoration: BoxDecoration(
                                            color: isSos
                                                ? AppColors.sosEmergency
                                                : (jamaah.isGpsActive
                                                      ? AppColors.statusSafe
                                                      : AppColors.error),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (isSos
                                                            ? AppColors
                                                                  .sosEmergency
                                                            : (jamaah.isGpsActive
                                                                  ? AppColors
                                                                        .statusSafe
                                                                  : AppColors
                                                                        .error))
                                                        .withValues(alpha: 0.6),
                                                blurRadius: 4,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            isSos
                                                ? context.tr(
                                                    'dashboard.sosSignalActive',
                                                  )
                                                : (jamaah.isGpsActive
                                                      ? context.tr(
                                                          'dashboard.gpsStable',
                                                        )
                                                      : context.tr(
                                                          'dashboard.gpsDisconnected',
                                                        )),
                                            style: TextStyle(
                                              color: isSos
                                                  ? const Color(0xFFFF8A80)
                                                  : Colors.white.withValues(
                                                      alpha: 0.85,
                                                    ),
                                              fontSize: 11.5,
                                              fontWeight: isSos
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Hero Distance & Safe Radius Container ────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.canvasCream.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Distance Number + Safe Limit Capsule (Text Scale Responsive)
                  LayoutBuilder(
                    builder: (context, distConstraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final bool isTightOrLarge =
                          textScale > 1.25 || distConstraints.maxWidth < 285;

                      final distanceColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    hasSignal
                                        ? _formatDistanceValue(jamaah.distance)
                                        : '--',
                                    style: DashboardTypography.displayLarge
                                        .copyWith(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: isSos
                                              ? AppColors.sosEmergency
                                              : (hasSignal
                                                    ? jamaah.tier.color
                                                    : headingColor),
                                          height: 1.1,
                                        ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasSignal
                                    ? _formatDistanceUnit(
                                        context,
                                        jamaah.distance,
                                      )
                                    : context.tr('meterUnit'),
                                style: DashboardTypography.titleMedium.copyWith(
                                  color: bodyColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.tr('dashboard.realtimeDistance'),
                            style: DashboardTypography.captionSmall.copyWith(
                              color: bodyColor.withValues(alpha: 0.75),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );

                      final safeLimitCapsule = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkOutlineVariant
                                : AppColors.espressoDark.withValues(
                                    alpha: 0.08,
                                  ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.tr('maxLimit'),
                              style: DashboardTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.75),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              safeRadius >= 1000
                                  ? '${_formatDistanceValue(safeRadius)} ${_formatDistanceUnit(context, safeRadius)}'
                                  : '${safeRadius.toInt()} ${context.tr('meterUnit')}',
                              style: DashboardTypography.labelLarge.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (isTightOrLarge) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            distanceColumn,
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: safeLimitCapsule,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: distanceColumn),
                          const SizedBox(width: 8),
                          safeLimitCapsule,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Progress / Range Indicator Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: hasSignal
                          ? (jamaah.distance / safeRadius).clamp(0.0, 1.0)
                          : 0.0,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceContainerHighest
                          : AppColors.canvasCreamSubtle,
                      color: isSos
                          ? AppColors.sosEmergency
                          : (hasSignal
                                ? jamaah.tier.color
                                : AppColors.tanMedium),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Range Context Tags
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0 m',
                        style: DashboardTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.6),
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSos
                                  ? AppColors.sosEmergency.withValues(
                                      alpha: isDark ? 0.25 : 0.15,
                                    )
                                  : (hasSignal
                                        ? (jamaah.distance <= safeRadius
                                              ? AppColors.statusSafe.withValues(
                                                  alpha: isDark ? 0.2 : 0.1,
                                                )
                                              : AppColors.sosEmergency
                                                    .withValues(
                                                      alpha: isDark ? 0.2 : 0.1,
                                                    ))
                                        : bodyColor.withValues(alpha: 0.08)),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: isSos
                                  ? Border.all(
                                      color: AppColors.sosEmergency.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Text(
                              isSos
                                  ? '🚨 Butuh Pertolongan Segera (SOS)'
                                  : (hasSignal
                                        ? (jamaah.distance <= safeRadius
                                              ? '${((jamaah.distance / safeRadius) * 100).toInt()}% ${context.tr('fromRadiusLimit')}'
                                              : context.tr(
                                                  'dashboard.outsideSafeRadius',
                                                ))
                                        : context.tr('dashboard.waitingGps')),
                              style: DashboardTypography.captionSmall.copyWith(
                                fontSize: 10.5,
                                color: isSos
                                    ? (isDark
                                          ? const Color(0xFFFF8A80)
                                          : AppColors.sosEmergency)
                                    : (hasSignal
                                          ? (jamaah.distance <= safeRadius
                                                ? (isDark
                                                      ? const Color(0xFF81C784)
                                                      : const Color(0xFF2E7D32))
                                                : (isDark
                                                      ? const Color(0xFFE57373)
                                                      : AppColors.sosEmergency))
                                          : bodyColor),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        safeRadius >= 1000
                            ? '${_formatDistanceValue(safeRadius)} km'
                            : '${safeRadius.toInt()} m',
                        style: DashboardTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.6),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Device & Sync Telemetry Tiles (Text Scale Responsive) ────────────────
            LayoutBuilder(
              builder: (context, telemConstraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final bool stackTelemetry =
                    textScale > 1.25 || telemConstraints.maxWidth < 285;

                final smartBandTile = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.espressoDark.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color:
                              (jamaah.isGpsActive
                                      ? AppColors.statusSafe
                                      : AppColors.error)
                                  .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.watch_rounded,
                          color: jamaah.isGpsActive
                              ? AppColors.statusSafe
                              : AppColors.error,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('smartBand'),
                              style: TextStyle(
                                fontSize: 10,
                                color: bodyColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              jamaah.isGpsActive
                                  ? context.tr('dashboard.gpsActive')
                                  : context.tr('dashboard.gpsInactive'),
                              style: TextStyle(
                                color: jamaah.isGpsActive
                                    ? (isDark
                                          ? const Color(0xFF81C784)
                                          : const Color(0xFF2E7D32))
                                    : AppColors.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                final lastSyncTile = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.espressoDark.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.tanMedium.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.tanMedium,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('lastSync'),
                              style: TextStyle(
                                fontSize: 10,
                                color: bodyColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatTimestamp(
                                context,
                                jamaah.locationUpdatedAt,
                              ),
                              style: TextStyle(
                                color: headingColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                if (stackTelemetry) {
                  return Column(
                    children: [
                      smartBandTile,
                      const SizedBox(height: 8),
                      lastSyncTile,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: smartBandTile),
                    const SizedBox(width: 8),
                    Expanded(child: lastSyncTile),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // ── Bottom Action Bar (Photo 2 Circular Quick-Actions + Photo 1 Pill Action) ─
            LayoutBuilder(
              builder: (context, actionConstraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final bool stackActions =
                    textScale > 1.35 || actionConstraints.maxWidth < 290;

                final quickRadiusBtn = Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showRadiusSheet(context);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceWhite,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.goldLight.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.06,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),
                  ),
                );

                final quickMemberBtn = Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      JamaahDetailSheet.show(
                        context,
                        jamaah: jamaah,
                        roomId: roomId,
                        roomName: roomName,
                        roomCode: roomCode,
                      );
                    },
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceWhite,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkOutlineVariant
                              : AppColors.goldLight.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.25 : 0.06,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.espressoDark,
                        size: 20,
                      ),
                    ),
                  ),
                );

                final primaryActionBtn = ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 46),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onTrackMap?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSos
                          ? AppColors.sosEmergency
                          : (isDark
                                ? AppColors.darkPrimaryContainer
                                : AppColors.espressoDark),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: isSos ? 3 : 2,
                      shadowColor:
                          (isSos
                                  ? AppColors.sosEmergency
                                  : (isDark
                                        ? Colors.black
                                        : AppColors.espressoDark))
                              .withValues(alpha: isSos ? 0.45 : 0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSos
                              ? Icons.emergency_rounded
                              : Icons.near_me_rounded,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isSos
                                ? context.tr('dashboard.trackEmergencyOnMap')
                                : context.tr('trackOnInteractiveMap'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 15),
                      ],
                    ),
                  ),
                );

                if (stackActions) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          quickRadiusBtn,
                          const SizedBox(width: 12),
                          quickMemberBtn,
                        ],
                      ),
                      const SizedBox(height: 10),
                      primaryActionBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    quickRadiusBtn,
                    const SizedBox(width: 8),
                    quickMemberBtn,
                    const SizedBox(width: 10),
                    Expanded(child: primaryActionBtn),
                  ],
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

/// Concentric 3D Radar Wave Painter inspired by Reference 2 (UIVERSE 3D UI)
class _RadarWavesPainter extends CustomPainter {
  final Color waveColor;
  final Offset centerFraction;

  _RadarWavesPainter({
    required this.waveColor,
    this.centerFraction = const Offset(0.85, 0.28),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * centerFraction.dx,
      size.height * centerFraction.dy,
    );

    final radii = [30.0, 58.0, 92.0, 134.0, 184.0, 244.0];
    final strokeOpacities = [0.26, 0.18, 0.12, 0.08, 0.05, 0.025];
    final fillOpacities = [0.08, 0.04, 0.02, 0.0, 0.0, 0.0];

    for (int i = 0; i < radii.length; i++) {
      if (fillOpacities[i] > 0) {
        final fillPaint = Paint()
          ..color = waveColor.withValues(alpha: fillOpacities[i])
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radii[i], fillPaint);
      }

      final strokePaint = Paint()
        ..color = waveColor.withValues(alpha: strokeOpacities[i])
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 2.2 : 1.2;
      canvas.drawCircle(center, radii[i], strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavesPainter oldDelegate) =>
      oldDelegate.waveColor != waveColor ||
      oldDelegate.centerFraction != centerFraction;
}
