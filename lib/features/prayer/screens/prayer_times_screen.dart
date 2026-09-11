import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
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
        title: Text('Jadwal Sholat & Kiblat', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        child: Column(
          children: [
            // Current Location & Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: AppConstants.spaceSm),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                border: Border.all(color: AppColors.canvasCreamSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.tanMedium, size: 20),
                      const SizedBox(width: AppConstants.spaceXs),
                      Text('Makkah Al-Mukarramah', style: AppTypography.titleSm.copyWith(color: AppColors.espressoDark)),
                    ],
                  ),
                  Text('14 Dzulhijjah 1445 H', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Next Prayer Hero
            Container(
              padding: const EdgeInsets.all(AppConstants.spaceLg),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
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
                  Text('WAKTU SHOLAT BERIKUTNYA', style: AppTypography.labelPill.copyWith(color: AppColors.goldLight, letterSpacing: 1.5)),
                  const SizedBox(height: AppConstants.spaceXs),
                  Text('Ashar', style: AppTypography.displayHero.copyWith(color: AppColors.surfaceWhite, fontSize: 40)),
                  Text('15:42 AST', style: AppTypography.headlineLg.copyWith(color: AppColors.goldLight)),
                  const SizedBox(height: AppConstants.spaceMd),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                    ),
                    child: Text('Waktu tersisa: 48 Menit 12 Detik', style: AppTypography.bodyMd.copyWith(color: AppColors.surfaceWhite)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Kiblat Compass Placeholder
            Container(
              padding: const EdgeInsets.all(AppConstants.spaceLg),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: AppColors.canvasCreamSubtle),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Arah Kiblat', style: AppTypography.titleSm.copyWith(color: AppColors.espressoDark)),
                      Text('294° Barat Laut', style: AppTypography.captionBold.copyWith(color: AppColors.statusPositive)),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spaceMd),
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldLight, width: 4),
                      color: AppColors.canvasCream,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.explore, size: 100, color: AppColors.primaryContainer),
                        Positioned(
                          top: 10,
                          child: Text('U', style: AppTypography.labelPill.copyWith(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceMd),
                  Text('Ponsel Anda telah mengarah ke Kiblat', style: AppTypography.caption.copyWith(color: AppColors.statusPositive)),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceMd),

            // Full Day Schedule
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppConstants.radiusCard),
                border: Border.all(color: AppColors.canvasCreamSubtle),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.spaceMd),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Jadwal Hari Ini', style: AppTypography.titleSm.copyWith(color: AppColors.espressoDark)),
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
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: AppConstants.spaceSm),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondaryContainer.withValues(alpha: 0.4) : Colors.transparent,
        border: Border(bottom: BorderSide(color: AppColors.canvasCreamSubtle.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (isActive)
                const Icon(Icons.volume_up, size: 16, color: AppColors.secondary)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 12),
              Text(
                name,
                style: AppTypography.bodyMd.copyWith(
                  color: isActive ? AppColors.espressoDark : AppColors.textHeading,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: AppTypography.bodyLg.copyWith(
              color: isActive ? AppColors.espressoDark : AppColors.textHeading,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
