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
import '../../room/widgets/jamaah_detail_sheet.dart';

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
    final state = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
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
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.surfaceVariant,
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
                final currentRadius =
                    state?.safeRadiusMeters.value.toInt() ?? 200;
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
                        selectedColor: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.goldLight,
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
                      selectedColor: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.goldLight,
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
                  style: AppTypography.titleMedium.copyWith(
                    color: headingColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 250',
                    hintStyle: AppTypography.captionSmall.copyWith(
                      color: bodyColor,
                    ),
                    suffixText: 'meter',
                    suffixStyle: AppTypography.caption.copyWith(
                      color: bodyColor,
                    ),
                    errorText: customError.value.isEmpty
                        ? null
                        : customError.value,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.goldLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.espressoDark,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1.5,
                      ),
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
                    foregroundColor: isDark
                        ? AppColors.darkPrimary
                        : AppColors.surfaceWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: () async {
                    final text = customCtrl.text.trim();
                    if (text.isEmpty) {
                      customError.value =
                          'Masukkan angka radius terlebih dahulu.';
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
                        message:
                            'Batas aman berhasil diatur menjadi $parsed meter dan tersinkron ke semua anggota room.',
                      );
                    }
                  },
                  child: Text(
                    'Terapkan Radius',
                    style: AppTypography.labelLarge.copyWith(
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.surfaceWhite,
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
      final roomId = state.activeRoomId.value ?? '';
      final roomName = state.activeRoom.value?.name ?? 'Room Pemantauan';
      final roomCode = state.activeRoom.value?.code ?? '';

      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBgColor(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.cardBorderColor(context),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.espressoDark)
                  .withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 18,
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
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.darkSurfaceContainerHigh,
                          AppColors.darkSurfaceContainerHighest,
                        ]
                      : [AppColors.espressoDark, AppColors.primaryContainer],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.espressoDark)
                        .withValues(alpha: isDark ? 0.35 : 0.22),
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
                          waveColor: hasSignal
                              ? (jamaah.tier == DistanceTier.aman
                                    ? AppColors.goldLight
                                    : (jamaah.tier == DistanceTier.waspada
                                          ? AppColors.distanceWarning
                                          : AppColors.sosEmergency))
                              : AppColors.tanLight,
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
                          // Top Row: Radar Active Pill & Floating Status Emblem (Photo 2)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Left: Radar Active Chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: AppColors.goldLight.withValues(
                                      alpha: 0.35,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedPingDot(
                                      color: hasSignal
                                          ? AppColors.accentGoldStar
                                          : AppColors.outlineVariant,
                                      size: 7,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'RADAR AKTIF',
                                      style: TextStyle(
                                        color: AppColors.goldLight,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Right: Floating Glassmorphic Status Emblem in ripple center
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (hasSignal
                                              ? jamaah.tier.color
                                              : AppColors.outline)
                                          .withValues(alpha: 0.26),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color:
                                        (hasSignal
                                                ? jamaah.tier.color
                                                : AppColors.outline)
                                            .withValues(alpha: 0.55),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (hasSignal
                                                  ? jamaah.tier.color
                                                  : Colors.black)
                                              .withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasSignal
                                          ? jamaah.tier.icon
                                          : Icons.hourglass_top_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      hasSignal
                                          ? _localizedTierLabel(
                                              context,
                                              jamaah.tier,
                                            ).toUpperCase()
                                          : 'MENUNGGU',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                    color: hasSignal
                                        ? jamaah.tier.color
                                        : AppColors.goldLight,
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (hasSignal
                                                  ? jamaah.tier.color
                                                  : AppColors.espressoDark)
                                              .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                    ),
                                  ],
                                  gradient: const LinearGradient(
                                    colors: [
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
                                            color: jamaah.isGpsActive
                                                ? AppColors.statusSafe
                                                : AppColors.error,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    (jamaah.isGpsActive
                                                            ? AppColors
                                                                  .statusSafe
                                                            : AppColors.error)
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
                                            jamaah.isGpsActive
                                                ? 'GPS Terkoneksi • Sinyal Stabil'
                                                : 'GPS Terputus • Menunggu Sinyal',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w500,
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
                  // Distance Number + Safe Limit Capsule
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  hasSignal
                                      ? _formatDistanceValue(jamaah.distance)
                                      : '--',
                                  style: AppTypography.displayLarge.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: hasSignal
                                        ? jamaah.tier.color
                                        : headingColor,
                                    height: 1.1,
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
                                  style: AppTypography.titleMedium.copyWith(
                                    color: bodyColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Jarak Real-Time Saat Ini',
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Safe Limit Capsule
                      Container(
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
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.75),
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
                      color: hasSignal
                          ? jamaah.tier.color
                          : AppColors.tanMedium,
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
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.6),
                          fontSize: 10.5,
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: hasSignal
                                ? (jamaah.distance <= safeRadius
                                      ? AppColors.statusSafe.withValues(
                                          alpha: isDark ? 0.2 : 0.1,
                                        )
                                      : AppColors.sosEmergency.withValues(
                                          alpha: isDark ? 0.2 : 0.1,
                                        ))
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
                                        ? (isDark
                                              ? const Color(0xFF81C784)
                                              : const Color(0xFF2E7D32))
                                        : (isDark
                                              ? const Color(0xFFE57373)
                                              : AppColors.sosEmergency))
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

            // ── Device & Sync Telemetry Tiles ────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
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
                                jamaah.isGpsActive ? 'GPS Aktif' : 'GPS Mati',
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
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
                                _formatTimestamp(jamaah.locationUpdatedAt),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Bottom Action Bar (Photo 2 Circular Quick-Actions + Photo 1 Pill Action) ─
            Row(
              children: [
                // Circular Button 1: Adjust Safe Radius (Photo 2)
                Material(
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
                ),
                const SizedBox(width: 8),

                // Circular Button 2: Jamaah Details Sheet (Photo 2)
                Material(
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
                ),
                const SizedBox(width: 10),

                // Primary Action Button (Photo 1)
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onTrackMap?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.espressoDark,
                        foregroundColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.surfaceWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        elevation: 2,
                        shadowColor:
                            (isDark ? Colors.black : AppColors.espressoDark)
                                .withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.near_me_rounded, size: 17),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              context.tr('trackOnInteractiveMap'),
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.surfaceWhite,
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
                  ),
                ),
              ],
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
