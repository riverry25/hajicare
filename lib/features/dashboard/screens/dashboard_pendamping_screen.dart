import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/state/hajicare_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../widgets/pendamping_greeting_header.dart';
import '../widgets/pendamping_jamaah_selector.dart';
import '../widgets/pendamping_radar_card.dart';
import '../widgets/pendamping_sos_banner.dart';

class DashboardPendampingScreen extends StatefulWidget {
  const DashboardPendampingScreen({super.key});

  @override
  State<DashboardPendampingScreen> createState() =>
      _DashboardPendampingScreenState();
}

class _DashboardPendampingScreenState extends State<DashboardPendampingScreen> {
  int _currentIndex = 0;
  int _selectedJamaahIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HajiCareState>();
    final selectedJamaah = state.jamaahList[_selectedJamaahIndex];

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
                color: AppColors.espressoDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mosque,
                color: AppColors.surfaceWhite,
                size: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.sm2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HajiCare',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.espressoDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'PENDAMPING',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.tanMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.espressoDark,
                ),
                onPressed: () => Navigator.of(context).pushNamed('/notification'),
              ),
              if (state.anySosActive)
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
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldLight, width: 2),
              ),
              child: const Icon(Icons.person, color: AppColors.tanMedium),
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
          PendampingGreetingHeader(state: state),
          const SizedBox(height: AppSpacing.lg),
          if (state.anyJamaahSeparated) _buildSeparatedBanner(state),
          PendampingJamaahSelector(
            state: state,
            selectedIndex: _selectedJamaahIndex,
            onSelected: (idx) {
              setState(() {
                _selectedJamaahIndex = idx;
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          PendampingRadarCard(
            jamaah: selectedJamaah,
            onTrackMap: () => Navigator.of(context).pushNamed('/map'),
          ),
          const SizedBox(height: AppSpacing.lg),
          PendampingSosBanner(state: state),
          const SizedBox(height: AppSpacing.lg),
          _buildMapCard(context),
          const SizedBox(height: AppSpacing.lg),
          _buildFeatureGrid(context),
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

  Widget _buildSeparatedBanner(HajiCareState state) {
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
              'Peringatan: ${state.separatedJamaahName} berada di luar radius aman (Terlalu jauh).',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.sosEmergency,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore, color: AppColors.tanMedium, size: 20),
                  const SizedBox(width: AppSpacing.sm2),
                  Text(
                    'Posisi Lapangan Real-Time',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.espressoDark,
                    ),
                  ),
                ],
              ),
              Text(
                'Area Mina Sektor 3',
                style: AppTypography.caption.copyWith(color: AppColors.textBody),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            onTap: () => Navigator.of(context).pushNamed('/map'),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.canvasCreamSubtle,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.goldLight.withValues(alpha: 0.6),
                ),
              ),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.map, size: 48, color: AppColors.tanMedium),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.open_in_full,
                            size: 16,
                            color: AppColors.espressoDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Buka Navigasi Penuh & Jalur Evakuasi',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.espressoDark,
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
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, color: AppColors.tanMedium, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Rute: Jalur Khusus Lansia King Fahd',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
              Text(
                'Tenda Maktab 48',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.espressoDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {
        'title': 'Peta Terpadu Sektor',
        'subtitle': 'Posko medis & jalur evakuasi',
        'icon': Icons.map,
        'route': '/map',
      },
      {
        'title': 'Jamaah & Gelang',
        'subtitle': 'Status baterai & sensor nadi',
        'icon': Icons.devices_other,
        'route': null,
      },
      {
        'title': 'Jadwal & Agenda',
        'subtitle': 'Waktu Jamarat & titik kumpul',
        'icon': Icons.event_note,
        'route': '/prayer',
      },
      {
        'title': 'Kontak Petugas Maktab',
        'subtitle': 'Akses instan layanan darurat',
        'icon': Icons.contact_phone,
        'route': '/communication',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Layanan Pendamping',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            final ratio = cardWidth < 170 ? 1.05 : 1.15;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final item = features[index];
                return AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  onTap: item['route'] != null
                      ? () => Navigator.of(context).pushNamed(item['route'] as String)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.canvasCream,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: AppColors.espressoDark,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.espressoDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textBody,
                              fontWeight: FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
