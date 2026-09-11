import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pill_button.dart';

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
      body: Column(
        children: [
          // Top AppBar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.surfaceWhite, size: 26),
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
                          child: const Icon(Icons.health_and_safety, color: AppColors.surfaceWhite, size: 16),
                        ),
                        const SizedBox(width: 6),
                        Text('HajiCare', style: AppTypography.headlineMd.copyWith(color: AppColors.surfaceWhite, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sos, color: AppColors.sosEmergency, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Distance Alert Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spaceSm),
              decoration: BoxDecoration(
                color: AppColors.distanceWarning.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                border: Border.all(color: AppColors.surfaceWhite.withValues(alpha: 0.6)),
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
                    width: 44,
                    height: 44,
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
                    child: const Icon(Icons.radar, color: AppColors.distanceWarning, size: 26),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.espressoDark,
                                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                              ),
                              child: Text(
                                'Peringatan Jarak Lansia',
                                style: AppTypography.captionBold.copyWith(color: AppColors.surfaceWhite, fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceWhite.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '215m > 200m',
                                style: AppTypography.captionBold.copyWith(color: AppColors.sosEmergency, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jamaah H. Ahmad Dahlan (Ayah) mulai terpisah dari batas aman maktab rombongan.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.espressoDark, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.espressoDark,
                      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                    ),
                    child: Text('Lacak', style: AppTypography.captionBold.copyWith(color: AppColors.surfaceWhite, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bottom Sheet
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusSheet)),
              border: Border(top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.4))),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDark.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppConstants.spaceLg, AppConstants.spaceXs, AppConstants.spaceLg, AppConstants.spaceLg),
                  child: Column(
                    children: [
                      // Header with icon & status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.emergency, color: AppColors.sosEmergency, size: 26),
                              const SizedBox(width: AppConstants.spaceXs),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Konfirmasi Darurat SOS', style: AppTypography.headlineMd.copyWith(color: AppColors.textHeading, fontWeight: FontWeight.w800)),
                                  Text('Grup Perjalanan: Rombongan 3 - Kelompok B', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.sosEmergency,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('SIAGA TINGGI', style: AppTypography.captionBold.copyWith(color: AppColors.sosEmergency)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spaceSm),

                      // Countdown Card
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spaceSm),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.espressoDark,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$_countdown',
                                  style: AppTypography.headlineMd.copyWith(color: AppColors.accentGoldStar, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppConstants.spaceSm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Kirim Otomatis ke Pendamping', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                                  Text(
                                    'Sinyal darurat dikirim jika tidak dibatalkan dalam 3 detik',
                                    style: AppTypography.caption.copyWith(color: AppColors.textBody),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.espressoDark,
                                side: const BorderSide(color: AppColors.outline),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusPill)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: Text('Hentikan', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceSm),

                      // Telemetry Grid
                      Row(
                        children: [
                          _buildTelemetryCell(Icons.smartphone, 'Aktif', 'GPS Ponsel', AppColors.statusPositive),
                          const SizedBox(width: AppConstants.spaceXs),
                          _buildTelemetryCell(Icons.near_me, '±3 Meter', 'Akurasi Posisi', AppColors.secondary),
                          const SizedBox(width: AppConstants.spaceXs),
                          _buildTelemetryCell(Icons.social_distance, '215 Meter', 'Jarak Terkini', AppColors.distanceWarning),
                        ],
                      ),
                      const SizedBox(height: AppConstants.spaceSm),

                      // Signal Receivers
                      Container(
                        padding: const EdgeInsets.all(AppConstants.spaceXs),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceBright,
                          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.cell_tower, size: 14, color: AppColors.textBody),
                                const SizedBox(width: 4),
                                Text('Penerima Sinyal Darurat Langsung:', style: AppTypography.captionBold.copyWith(color: AppColors.textBody, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildReceiverChip('Siti Aminah (Pendamping Utama)'),
                                _buildReceiverChip('Kontak Darurat Keluarga (0812-xxxx)'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceMd),

                      // Main SOS Button
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                              boxShadow: [
                                BoxShadow(
                                  color: (_sosSent ? AppColors.statusPositive : AppColors.sosEmergency)
                                      .withValues(alpha: 0.2 + (0.15 * (1 - _pulseController.value))),
                                  blurRadius: 16 + (8 * _pulseController.value),
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                        child: ElevatedButton(
                          onPressed: () {
                            if (!_sosSent) {
                              setState(() => _sosSent = true);
                            }
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sinyal SOS telah dikirim. Bantuan sedang dalam perjalanan.'),
                                backgroundColor: AppColors.statusPositive,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _sosSent ? AppColors.statusPositive : AppColors.sosEmergency,
                            foregroundColor: AppColors.surfaceWhite,
                            minimumSize: const Size.fromHeight(64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                              side: const BorderSide(color: AppColors.surfaceWhite, width: 2),
                            ),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _sosSent ? Icons.done_all : Icons.emergency_share,
                                  color: AppColors.surfaceWhite,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: AppConstants.spaceSm),
                              Text(
                                _sosSent ? 'SOS AKTIF & TERKIRIM' : 'KIRIM SOS SEKARANG',
                                style: AppTypography.headlineMd.copyWith(
                                  color: AppColors.surfaceWhite,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kirim koordinat GPS langsung ke ponsel Pendamping',
                        style: AppTypography.caption.copyWith(color: AppColors.textBody),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConstants.spaceSm),

                      // Secondary actions
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.espressoDark,
                          side: const BorderSide(color: AppColors.goldLight, width: 2),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusPill)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.vibration, size: 20, color: AppColors.tanMedium),
                            const SizedBox(width: AppConstants.spaceXs),
                            Text('Bunyikan Alarm & Getar Ponsel Jamaah', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.spaceXs),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.espressoDark,
                          side: BorderSide(color: AppColors.sosEmergency.withValues(alpha: 0.3)),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusPill)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call, size: 20, color: AppColors.sosEmergency),
                            const SizedBox(width: AppConstants.spaceXs),
                            Text('Hubungi Pusat Tanggap Maktab 48', style: AppTypography.labelPill.copyWith(color: AppColors.sosEmergency)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCell(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spaceXs),
        decoration: BoxDecoration(
          color: AppColors.canvasCream.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 4),
                Text(value, style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark)),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.caption.copyWith(color: AppColors.textBody, fontSize: 10)),
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
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.4)),
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
            style: AppTypography.caption.copyWith(color: AppColors.espressoDark, fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
