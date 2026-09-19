import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_translations.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/services/app_alert_service.dart';
import '../../../../core/state/hajicare_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

class PendampingRadarCard extends StatelessWidget {
  final JamaahData jamaah;
  final VoidCallback? onTrackMap;

  const PendampingRadarCard({
    super.key,
    required this.jamaah,
    this.onTrackMap,
  });

  AppStatusType _mapStatusType(DistanceTier tier) {
    switch (tier) {
      case DistanceTier.aman:
        return AppStatusType.safe;
      case DistanceTier.waspada:
        return AppStatusType.warning;
      case DistanceTier.terlalujJauh:
        return AppStatusType.danger;
    }
  }

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

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return 'Menunggu...';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 30) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
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
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final state = Get.isRegistered<HajiCareController>() ? Get.find<HajiCareController>() : null;
    const presetRadii = [50, 100, 150, 200, 300, 500];

    // Custom input controller pre-filled with current radius
    final customCtrl = TextEditingController(
      text: state?.safeRadiusMeters.value.toInt().toString() ?? '200',
    );
    final customError = ''.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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
              Text(
                'Atur Radius Batas Aman Jamaah',
                style: AppTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Peringatan getar & notifikasi akan aktif jika jamaah berada di luar radius ini.',
                style: AppTypography.captionSmall.copyWith(color: bodyColor),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Preset chips ─────────────────────────────────────────────
              Text(
                'Pilih Preset',
                style: AppTypography.caption.copyWith(
                  color: bodyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Obx(() {
                final currentRadius = state?.safeRadiusMeters.value.toInt() ?? 200;
                final isCustom = !presetRadii.contains(currentRadius);
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ...presetRadii.map((r) {
                      final isSelected = r == currentRadius;
                      return ChoiceChip(
                        label: Text('$r m'),
                        selected: isSelected,
                        selectedColor: isDark ? AppColors.darkPrimaryContainer : AppColors.goldLight,
                        onSelected: (_) {
                          state?.setSafeRadius(r.toDouble());
                          customCtrl.text = r.toString();
                          customError.value = '';
                        },
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: isCustom,
                      selectedColor: isDark ? AppColors.darkPrimaryContainer : AppColors.goldLight,
                      onSelected: (_) {
                        // Focus the text field
                      },
                    ),
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.md),

              // ── Custom input field ────────────────────────────────────────
              Text(
                'Atau masukkan radius sendiri (meter)',
                style: AppTypography.caption.copyWith(
                  color: bodyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Obx(() {
                return TextField(
                  controller: customCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppTypography.titleMedium.copyWith(color: headingColor),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 250',
                    hintStyle: AppTypography.captionSmall.copyWith(color: bodyColor),
                    suffixText: 'meter',
                    suffixStyle: AppTypography.caption.copyWith(color: bodyColor),
                    errorText: customError.value.isEmpty ? null : customError.value,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkOutlineVariant : AppColors.goldLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkPrimary : AppColors.espressoDark,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream.withValues(alpha: 0.5),
                  ),
                  onChanged: (val) {
                    customError.value = '';
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0 && parsed <= 5000) {
                      state?.setSafeRadius(parsed.toDouble());
                    }
                  },
                );
              }),
              const SizedBox(height: AppSpacing.lg),

              // ── Apply button ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeightPrimary,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.primaryContainer,
                    foregroundColor: isDark ? AppColors.darkPrimary : AppColors.surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: () async {
                    final text = customCtrl.text.trim();
                    if (text.isEmpty) {
                      customError.value = 'Masukkan angka radius terlebih dahulu.';
                      return;
                    }
                    final parsed = int.tryParse(text);
                    if (parsed == null || parsed <= 0) {
                      customError.value = 'Radius harus lebih dari 0.';
                      return;
                    }
                    if (parsed > 5000) {
                      customError.value = 'Radius maksimum adalah 5000 meter.';
                      return;
                    }
                    await state?.setSafeRadius(parsed.toDouble());
                    Get.back();
                    if (context.mounted) {
                      AppAlert.success(
                        context,
                        title: 'Radius Diperbarui',
                        message: 'Batas aman berhasil diatur menjadi $parsed meter dan tersinkron ke semua anggota room.',
                      );
                    }
                  },
                  child: Text(
                    'Terapkan Radius',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark ? AppColors.darkPrimary : AppColors.surfaceWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.isRegistered<HajiCareController>() ? Get.find<HajiCareController>() : null;
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final hasActiveRoom = state?.activeRoomId.value != null && state!.activeRoomId.value!.isNotEmpty;

      if (!hasActiveRoom) {
        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          borderColor: isDark ? AppColors.darkCardBorder : AppColors.goldLight.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkPrimaryContainer : AppColors.canvasCream,
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
                          'Radar Pemantauan Jamaah',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Fitur pemantauan jarak real-time, batas radius aman, dan tracking jamaah memerlukan Room aktif.',
                          style: AppTypography.bodySmall.copyWith(
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
                  label: const Text(
                    'Buat / Gabung Room untuk Mengaktifkan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primaryGold,
                    foregroundColor: Colors.white,
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
      // Distance alone is NOT a reliable indicator — it can be huge when using default coords.
      final hasSignal = jamaah.currentLocation != null && jamaah.isGpsActive;

      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row (Radar icon, Name, Status Badge) ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
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
                          Icons.radar_rounded,
                          color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    context.tr('radarJamaahDistance'),
                                    style: AppTypography.captionSmall.copyWith(
                                      color: bodyColor.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                AnimatedPingDot(
                                  color: hasSignal ? jamaah.tier.color : AppColors.outline,
                                  size: 8,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              jamaah.name,
                              style: AppTypography.titleMedium.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppStatusBadge(
                  label: hasSignal ? _localizedTierLabel(context, jamaah.tier) : 'Menunggu',
                  statusType: hasSignal ? _mapStatusType(jamaah.tier) : AppStatusType.warning,
                  icon: hasSignal ? jamaah.tier.icon : Icons.hourglass_top_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Hero Distance & Radius Container ───────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.canvasCream.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant
                      : AppColors.goldLight.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Distance Number + Safe Limit Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Distance Value & Unit
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  hasSignal ? _formatDistanceValue(jamaah.distance) : '--',
                                  style: AppTypography.displayLarge.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: hasSignal ? jamaah.tier.color : bodyColor,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  hasSignal ? _formatDistanceUnit(context, jamaah.distance) : context.tr('meterUnit'),
                                  style: AppTypography.titleMedium.copyWith(
                                    color: bodyColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jarak Real-Time Saat Ini',
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Safe Limit Capsule
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkOutlineVariant
                                : AppColors.espressoDark.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              context.tr('maxLimit'),
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.8),
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              safeRadius >= 1000
                                  ? '${_formatDistanceValue(safeRadius)} ${_formatDistanceUnit(context, safeRadius)}'
                                  : '${safeRadius.toInt()} ${context.tr('meterUnit')}',
                              style: AppTypography.labelLarge.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

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
                      color: hasSignal ? jamaah.tier.color : AppColors.tanMedium,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Range Context Tags (Never overflows)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '0 m',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.6),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: hasSignal
                                ? (jamaah.distance <= safeRadius
                                    ? AppColors.statusSafe.withValues(alpha: isDark ? 0.2 : 0.1)
                                    : AppColors.sosEmergency.withValues(alpha: isDark ? 0.2 : 0.1))
                                : bodyColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            hasSignal
                                ? (jamaah.distance <= safeRadius
                                    ? '${((jamaah.distance / safeRadius) * 100).toInt()}% ${context.tr('fromRadiusLimit')}'
                                    : 'Di luar radius aman')
                                : 'Menunggu GPS...',
                            style: AppTypography.captionSmall.copyWith(
                              fontSize: 10.5,
                              color: hasSignal
                                  ? (jamaah.distance <= safeRadius
                                      ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                                      : (isDark ? const Color(0xFFE57373) : AppColors.sosEmergency))
                                  : bodyColor,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Text(
                        safeRadius >= 1000
                            ? '${_formatDistanceValue(safeRadius)} km'
                            : '${safeRadius.toInt()} m',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Device & Sync Status Row (Clean Tiles) ──────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.espressoDark.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (jamaah.isGpsActive ? AppColors.statusSafe : AppColors.error)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.watch_rounded,
                            color: jamaah.isGpsActive ? AppColors.statusSafe : AppColors.error,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('smartBand'),
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 10,
                                  color: bodyColor.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                jamaah.isGpsActive ? 'GPS Terhubung' : 'GPS Terputus',
                                style: AppTypography.captionSmall.copyWith(
                                  color: jamaah.isGpsActive ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32)) : AppColors.error,
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
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.espressoDark.withValues(alpha: 0.06),
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
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('lastSync'),
                                style: AppTypography.captionSmall.copyWith(
                                  fontSize: 10,
                                  color: bodyColor.withValues(alpha: 0.7),
                                ),
                              ),
                              Text(
                                _formatTimestamp(jamaah.locationUpdatedAt),
                                style: AppTypography.captionSmall.copyWith(
                                  color: headingColor,
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Primary Action: Track on Map ────────────────────────────────
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.buttonHeightPrimary,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTrackMap,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm2,
                    ),
                    backgroundColor: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.espressoDark,
                    foregroundColor: isDark
                        ? AppColors.darkPrimary
                        : AppColors.surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    elevation: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.near_me_rounded, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          context.tr('trackOnInteractiveMap'),
                          style: AppTypography.labelLarge.copyWith(
                            color: isDark ? AppColors.darkPrimary : AppColors.surfaceWhite,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs + 2),

            // ── Secondary Action: Adjust Safe Radius ────────────────────────
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.buttonHeightSecondary,
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showRadiusSheet(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: headingColor,
                    side: BorderSide(
                      color: isDark ? AppColors.darkOutlineVariant : AppColors.goldLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.tune_rounded, size: 16, color: AppColors.tanMedium),
                      const SizedBox(width: AppSpacing.sm2),
                      Flexible(
                        child: Text(
                          'Atur Batas Radius Aman (${safeRadius.toInt()}m)',
                          style: AppTypography.labelLarge.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
