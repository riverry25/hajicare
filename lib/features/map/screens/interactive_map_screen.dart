import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/filter_chip_item.dart';
import '../../../core/state/hajicare_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../widgets/map_bottom_sheet.dart';
import '../widgets/map_floating_controls.dart';
import '../widgets/map_top_header.dart';
import '../widgets/mina_map_painter.dart';

class InteractiveMapScreen extends StatefulWidget {
  const InteractiveMapScreen({super.key});

  @override
  State<InteractiveMapScreen> createState() => _InteractiveMapScreenState();
}

class _InteractiveMapScreenState extends State<InteractiveMapScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 1;
  int _selectedFilter = 0;
  late AnimationController _pulseController;
  late AnimationController _compassController;

  final List<FilterChipItem> _filters = const [
    FilterChipItem(
      label: 'Jamaah (Ayah)',
      icon: Icons.person_pin_circle,
      isDefault: true,
    ),
    FilterChipItem(label: 'Semua'),
    FilterChipItem(label: 'Toilet & Wudhu', icon: Icons.wc),
    FilterChipItem(label: 'Posko Medis PPIH', icon: Icons.medical_services),
    FilterChipItem(label: 'Tenda Maktab 48', icon: Icons.holiday_village),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _compassController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _compassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HajiCareState>();

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: Stack(
        children: [
          // Map Canvas
          _buildMapCanvas(state),

          // Top Header
          MapTopHeader(
            filters: _filters,
            selectedFilter: _selectedFilter,
            onFilterSelected: (index) => setState(() => _selectedFilter = index),
            onSosPressed: () => Navigator.of(context).pushNamed('/sos-modal'),
          ),

          // Right-side floating controls
          MapFloatingControls(
            onCompassTap: () {},
            onLocationTap: () {},
            onLayersTap: () {},
            onBandTap: () {},
          ),

          // Bottom Sheet
          MapBottomSheet(
            state: state,
            onNavigate: () {},
            onShareLocation: () {},
            onCall: () {},
          ),
        ],
      ),
      bottomNavigationBar: HajiCareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildMapCanvas(HajiCareState state) {
    return Positioned.fill(
      child: Container(
        color: AppColors.canvasCreamSubtle,
        child: CustomPaint(
          painter: const MinaMapPainter(),
          child: Stack(
            children: [
              // Safe Radius Circle
              Positioned(
                left: 60,
                top: 280,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.statusPositive.withValues(alpha: 0.06),
                        border: Border.all(
                          color: AppColors.statusPositive.withValues(alpha: 0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignCenter,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // "BATAS RADIUS AMAN" label
              Positioned(
                left: 85,
                top: 520,
                child: Text(
                  'BATAS RADIUS AMAN (200m)',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.statusPositive,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Companion Marker (Anda)
              Positioned(
                left: 110,
                top: 360,
                child: _buildCompanionMarker(),
              ),

              // Jamaah Marker (H. Ahmad Dahlan)
              Positioned(
                left: 220,
                top: 230,
                child: _buildJamaahMarker(state),
              ),

              // Distance Route Pill
              Positioned(
                left: 150,
                top: 310,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.espressoDark,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espressoDark.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.directions_walk,
                        size: 12,
                        color: AppColors.accentGoldStar,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '120m • 2 menit jalan',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.surfaceWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Facility Marker: Toilet
              _buildFacilityMarker(
                left: 55,
                top: 170,
                icon: Icons.wc,
                label: 'Toilet 45m',
                iconColor: AppColors.tanMedium,
              ),

              // Facility Marker: Posko Medis
              _buildFacilityMarker(
                left: 300,
                top: 165,
                icon: Icons.medical_services,
                label: 'Pos Medis 110m',
                iconColor: AppColors.sosEmergency,
                isEmergency: true,
              ),

              // Facility Marker: Pos Pantau
              _buildFacilityMarker(
                left: 70,
                top: 480,
                icon: Icons.flag,
                label: 'Pos Pantau 80m',
                iconColor: AppColors.accentGoldStar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanionMarker() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.espressoDark,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.espressoDark.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
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
                'Anda (Tenda Maktab 48)',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.surfaceWhite,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.espressoDark, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: AppColors.tanMedium, size: 28),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.espressoDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceWhite, width: 1),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: AppColors.surfaceWhite,
                  size: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJamaahMarker(HajiCareState state) {
    return Column(
      children: [
        // Callout Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.tanMedium, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.espressoDark.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.elderly, size: 14, color: AppColors.distanceWarning),
              const SizedBox(width: 4),
              Text(
                'H. Ahmad (Ayah) • 120m',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.espressoDark,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.battery_5_bar,
                size: 12,
                color: AppColors.statusPositive,
              ),
              const SizedBox(width: 2),
              Text(
                '92%',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.statusPositive,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Radar Pulse + Avatar
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Pulse rings
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale1 = 1.0 + (_pulseController.value * 0.6);
                final opacity1 = (1.0 - _pulseController.value) * 0.4;
                return Container(
                  width: 64 * scale1,
                  height: 64 * scale1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGoldStar.withValues(alpha: opacity1),
                  ),
                );
              },
            ),
            // Pin Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.distanceWarning, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.elderly, color: AppColors.tanMedium, size: 30),
            ),
            // Check badge
            Positioned(
              bottom: -4,
              right: -4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.statusPositive,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceWhite, width: 2),
                ),
                child: const Icon(Icons.check, color: AppColors.surfaceWhite, size: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFacilityMarker({
    required double left,
    required double top,
    required IconData icon,
    required String label,
    required Color iconColor,
    bool isEmergency = false,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
              border: Border.all(
                color: isEmergency ? AppColors.errorContainer : AppColors.goldLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDark.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDark.withValues(alpha: 0.05),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text(
              label,
              style: AppTypography.captionSmall.copyWith(
                color: isEmergency ? AppColors.sosEmergency : AppColors.textBody,
                fontWeight: isEmergency ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
