import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class ModalSosScreen extends StatefulWidget {
  const ModalSosScreen({super.key});

  @override
  State<ModalSosScreen> createState() => _ModalSosScreenState();
}

class _ModalSosScreenState extends State<ModalSosScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  int _countdown = 3;
  bool _sosSent = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 3; i >= 0; i--) {
      if (!mounted) return;
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _countdown = i;
        if (i == 0) _sosSent = true;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.espressoDark.withValues(alpha: 0.85),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.surfaceWhite,
                      size: 26,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.espressoDark,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety,
                          color: AppColors.surfaceWhite,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm2),
                      Text(
                        'HajiCare',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sos,
                      color: AppColors.sosEmergency,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // Distance Alert Banner
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenEdgeGutter,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.distanceWarning.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.surfaceWhite.withValues(alpha: 0.6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.distanceWarning.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.espressoDark,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.espressoDark.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.radar,
                        color: AppColors.distanceWarning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.espressoDark,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  'Peringatan Jarak Lansia',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.surfaceWhite,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '215m > 200m',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.sosEmergency,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Jamaah H. Ahmad Dahlan (Ayah) mulai terpisah dari batas aman maktab.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Bottom Modal Sheet (Scroll-Safe)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.goldLight.withValues(alpha: 0.4),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenEdgeGutter,
                    AppSpacing.sm,
                    AppSpacing.screenEdgeGutter,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Header with icon & status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.emergency,
                                  color: AppColors.sosEmergency,
                                  size: 26,
                                ),
                                const SizedBox(width: AppSpacing.sm2),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Konfirmasi Darurat SOS',
                                        style:
                                            AppTypography.titleMedium.copyWith(
                                          color: AppColors.textHeading,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Rombongan 3 - Kelompok B',
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textBody,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.sosEmergency,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'SIAGA TINGGI',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.sosEmergency,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Countdown Card
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.goldLight.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.espressoDark,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_countdown',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: AppColors.accentGoldStar,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kirim Otomatis ke Pendamping',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.espressoDark,
                                    ),
                                  ),
                                  Text(
                                    'Sinyal dikirim jika tidak dibatalkan dalam 3 detik',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textBody,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.espressoDark,
                                side: const BorderSide(color: AppColors.outline),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                'Hentikan',
                                style: AppTypography.captionSmall.copyWith(
                                  color: AppColors.espressoDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Telemetry Grid
                      Row(
                        children: [
                          _buildTelemetryCell(
                            Icons.smartphone,
                            'Aktif',
                            'GPS Ponsel',
                            AppColors.statusPositive,
                          ),
                          const SizedBox(width: AppSpacing.sm2),
                          _buildTelemetryCell(
                            Icons.near_me,
                            '±3 Meter',
                            'Akurasi Posisi',
                            AppColors.secondary,
                          ),
                          const SizedBox(width: AppSpacing.sm2),
                          _buildTelemetryCell(
                            Icons.social_distance,
                            '215 Meter',
                            'Jarak Terkini',
                            AppColors.distanceWarning,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Signal Receivers
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color:
                                AppColors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.cell_tower,
                                  size: 14,
                                  color: AppColors.textBody,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Penerima Sinyal Darurat Langsung:',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.textBody,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildReceiverChip('Siti Aminah (Pendamping)'),
                                _buildReceiverChip('Kontak Keluarga (0812-xxxx)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Main SOS Button
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              boxShadow: [
                                BoxShadow(
                                  color: (_sosSent
                                          ? AppColors.statusPositive
                                          : AppColors.sosEmergency)
                                      .withValues(
                                    alpha: 0.2 +
                                        (0.15 *
                                            (1 - _pulseController.value)),
                                  ),
                                  blurRadius:
                                      16 + (8 * _pulseController.value),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (!_sosSent) {
                                setState(() => _sosSent = true);
                              }
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sinyal SOS telah dikirim. Bantuan sedang dalam perjalanan.',
                                  ),
                                  backgroundColor: AppColors.statusPositive,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _sosSent
                                  ? AppColors.statusPositive
                                  : AppColors.sosEmergency,
                              foregroundColor: AppColors.surfaceWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                side: const BorderSide(
                                  color: AppColors.surfaceWhite,
                                  width: 2,
                                ),
                              ),
                              elevation: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _sosSent
                                      ? Icons.done_all
                                      : Icons.emergency_share,
                                  color: AppColors.surfaceWhite,
                                  size: 24,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  _sosSent
                                      ? 'SOS AKTIF & TERKIRIM'
                                      : 'KIRIM SOS SEKARANG',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.surfaceWhite,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kirim koordinat GPS langsung ke ponsel Pendamping',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textBody,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Secondary action buttons
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightSecondary,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.espressoDark,
                            side: const BorderSide(
                              color: AppColors.goldLight,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.vibration,
                                size: 18,
                                color: AppColors.tanMedium,
                              ),
                              const SizedBox(width: AppSpacing.sm2),
                              Text(
                                'Bunyikan Alarm & Getar Ponsel Jamaah',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.espressoDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm2),
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeightSecondary,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.espressoDark,
                            side: BorderSide(
                              color:
                                  AppColors.sosEmergency.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.call,
                                size: 18,
                                color: AppColors.sosEmergency,
                              ),
                              const SizedBox(width: AppSpacing.sm2),
                              Text(
                                'Hubungi Pusat Tanggap Maktab 48',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.sosEmergency,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildTelemetryCell(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.canvasCream.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.goldLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.espressoDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textBody,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiverChip(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.goldLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.statusPositive,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.espressoDark,
            ),
          ),
        ],
      ),
    );
  }
}
