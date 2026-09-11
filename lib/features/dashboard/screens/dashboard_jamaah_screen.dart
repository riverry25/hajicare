import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/state/hajicare_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../widgets/jamaah_distance_card.dart';
import '../widgets/jamaah_prayer_card.dart';
import '../widgets/jamaah_profile_header.dart';
import '../widgets/jamaah_service_grid.dart';
import '../widgets/jamaah_sos_banner.dart';

class DashboardJamaahScreen extends StatefulWidget {
  const DashboardJamaahScreen({super.key});

  @override
  State<DashboardJamaahScreen> createState() => _DashboardJamaahScreenState();
}

class _DashboardJamaahScreenState extends State<DashboardJamaahScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HajiCareState>();
    final jamaah = state.self;

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.canvasCream,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.espressoDark),
          onPressed: () {},
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mosque,
                color: AppColors.accentGoldStar,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm2),
            Text(
              'HajiCare',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.espressoDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.espressoDark),
                onPressed: () => Navigator.of(context).pushNamed('/notification'),
              ),
              if (jamaah.separatedMode)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.canvasCream, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: CircleAvatar(
              backgroundColor: AppColors.errorContainer,
              radius: 18,
              child: IconButton(
                icon: const Icon(Icons.sos, color: AppColors.sosEmergency, size: 20),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pushNamed('/sos-modal'),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdgeGutter,
          vertical: AppSpacing.sm,
        ),
        children: [
          if (jamaah.separatedMode) _buildSeparatedBanner(context),
          JamaahProfileHeader(state: state),
          const SizedBox(height: AppSpacing.lg),
          JamaahDistanceCard(
            jamaah: jamaah,
            onViewMap: () => Navigator.of(context).pushNamed('/map'),
          ),
          const SizedBox(height: AppSpacing.lg),
          JamaahSosBanner(state: state),
          const SizedBox(height: AppSpacing.lg),
          const JamaahPrayerCard(),
          const SizedBox(height: AppSpacing.lg),
          const JamaahServiceGrid(),
          const SizedBox(height: AppSpacing.lg),
          _buildTipsBanner(),
          const SizedBox(height: AppConstants.space3xl),
        ],
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

  Widget _buildSeparatedBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.sosEmergency.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.sosEmergency),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Kemungkinan terpisah dari pendamping! Tetap tenang di tempat Anda.',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.sosEmergency,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tanMedium.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: AppColors.espressoDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HIMBAUAN PETUGAS SEKTOR',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.espressoDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tetap bersama rombongan saat menuju jamarat. Pastikan botol air minum terisi penuh dan kenakan selalu gelang identitas Anda.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textHeading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
