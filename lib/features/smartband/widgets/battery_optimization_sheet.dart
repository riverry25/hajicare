import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../services/smartband_foreground_service.dart';

/// Modal bottom sheet ramah lansia untuk memandu jemaah mengaktifkan mode latar belakang 24/7
/// dan mengecualikan aplikasi dari penghemat baterai sistem (Doze Mode / MIUI / HyperOS).
class BatteryOptimizationSheet extends StatefulWidget {
  const BatteryOptimizationSheet({super.key});

  /// Tampilkan modal panduan optimasi baterai
  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BatteryOptimizationSheet(),
    );
  }

  @override
  State<BatteryOptimizationSheet> createState() =>
      _BatteryOptimizationSheetState();
}

class _BatteryOptimizationSheetState extends State<BatteryOptimizationSheet> {
  bool _isIgnored = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final ignored = await SmartbandForegroundService.isBatteryOptimizationIgnored();
    if (mounted) {
      setState(() {
        _isIgnored = ignored;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRequestPermission() async {
    HapticFeedback.mediumImpact();
    await SmartbandForegroundService.requestDisableBatteryOptimization();
    // Beri jeda sejenak untuk pengguna menyetujui prompt dialog Android
    await Future.delayed(const Duration(seconds: 1));
    await _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;

    return Container(
      decoration: BoxDecoration(
        color: hc.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: hc.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header Ikon & Judul
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isIgnored
                      ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                      : hc.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isIgnored
                      ? Icons.check_circle_rounded
                      : Icons.battery_charging_full_rounded,
                  color: _isIgnored ? const Color(0xFF22C55E) : hc.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koneksi Gelang 24/7 di Saku',
                      style: context.text.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: hc.textPrimary,
                      ),
                    ),
                    Text(
                      _isLoading
                          ? 'Memeriksa status...'
                          : (_isIgnored
                              ? 'Status: Aktif 24/7 (Siaga Penuh)'
                              : 'Status: Dibatasi Penghemat Daya'),
                      style: context.text.labelSmall.copyWith(
                        color: _isIgnored
                            ? const Color(0xFF22C55E)
                            : hc.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Penjelasan Manfaat
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: hc.canvas,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: hc.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBenefitItem(
                  context,
                  icon: Icons.bluetooth_connected_rounded,
                  title: 'Gelang Tetap Terhubung Saat Layar Mati',
                  desc: 'Sensor detak jantung, GPS, dan deteksi jatuh tetap dimonitor meskipun HP di saku.',
                ),
                const SizedBox(height: 10),
                _buildBenefitItem(
                  context,
                  icon: Icons.mic_rounded,
                  title: 'AI Assistant Siaga via Mic Gelang',
                  desc: 'Klik 2x tombol gelang kapan saja untuk bicara ke AI; jawaban langsung tampil di layar gelang.',
                ),
                const SizedBox(height: 10),
                _buildBenefitItem(
                  context,
                  icon: Icons.volume_off_rounded,
                  title: 'Senyap di Saku',
                  desc: 'Suara speaker HP otomatis dibisukan saat layar terkunci agar tidak mengagetkan jemaah.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tips Khusus Xiaomi/Redmi (HyperOS / MIUI)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Khusus HP Xiaomi/Redmi: Pastikan opsi "Mulai Otomatis" (Autostart) juga diaktifkan di setelan aplikasi.',
                    style: context.text.labelSmall.copyWith(
                      color: hc.textPrimary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tombol Aksi 1-Klik
          if (!_isIgnored)
            ElevatedButton.icon(
              onPressed: _handleRequestPermission,
              icon: const Icon(Icons.flash_on_rounded),
              label: const Text(
                'Izinkan Jalan 24/7 (Tanpa Batasan)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hc.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded, color: Color(0xFF22C55E)),
              label: const Text(
                'Sudah Aktif 24/7 • Tutup',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: hc.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String desc,
  }) {
    final hc = context.hc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: hc.accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: hc.textPrimary,
                ),
              ),
              Text(
                desc,
                style: context.text.labelSmall.copyWith(
                  color: hc.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

