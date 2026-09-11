import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  int _currentIndex = 2; // Jadwal is index 2

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 1,
        title: Text(
          'Jadwal Sholat & Kiblat',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdgeGutter,
          vertical: AppSpacing.md,
        ),
        child: Column(
          children: [
            // Current Location & Time (Overflow Protected)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.canvasCreamSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.tanMedium,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Makkah Al-Mukarramah',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.espressoDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '14 Dzulhijjah 1445 H',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Next Prayer Hero
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'WAKTU SHOLAT BERIKUTNYA',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.goldLight,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm2),
                  Text(
                    'Ashar',
                    style: AppTypography.heroNumberLarge.copyWith(
                      color: AppColors.surfaceWhite,
                    ),
                  ),
                  Text(
                    '15:42 AST',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Waktu tersisa: 48 Menit 12 Detik',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.surfaceWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Kiblat Compass
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Arah Kiblat',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.espressoDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '294° Barat Laut',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.statusPositive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldLight, width: 4),
                      color: AppColors.canvasCream,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.explore,
                          size: 90,
                          color: AppColors.primaryContainer,
                        ),
                        Positioned(
                          top: 10,
                          child: Text(
                            'U',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Ponsel Anda telah mengarah ke Kiblat',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.statusPositive,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Full Day Schedule
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jadwal Hari Ini',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.espressoDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.date_range, color: AppColors.tanMedium),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.canvasCreamSubtle),
                  _buildPrayerRow('Imsak', '04:42', false),
                  _buildPrayerRow('Subuh', '04:52', false),
                  _buildPrayerRow('Terbit', '06:12', false),
                  _buildPrayerRow('Dzuhur', '12:28', false),
                  _buildPrayerRow('Ashar', '15:42', true),
                  _buildPrayerRow('Maghrib', '18:35', false),
                  _buildPrayerRow('Isya', '20:05', false),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space3xl),
          ],
        ),
      ),
      bottomNavigationBar: HajiCareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildPrayerRow(String name, String time, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.secondaryContainer.withValues(alpha: 0.4)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: AppColors.canvasCreamSubtle.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isActive)
                const Icon(
                  Icons.volume_up,
                  size: 16,
                  color: AppColors.secondary,
                )
              else
                const SizedBox(width: 16),
              const SizedBox(width: 12),
              Text(
                name,
                style: AppTypography.bodyMedium.copyWith(
                  color: isActive
                      ? AppColors.espressoDark
                      : AppColors.textHeading,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: AppTypography.bodyMedium.copyWith(
              color: isActive
                  ? AppColors.espressoDark
                  : AppColors.textHeading,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
