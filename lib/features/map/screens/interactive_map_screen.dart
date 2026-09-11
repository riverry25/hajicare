import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/state/hajicare_state.dart';
import 'package:provider/provider.dart';

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

  final List<_FilterChip> _filters = [
    _FilterChip('Jamaah (Ayah)', Icons.person_pin_circle, true),
    _FilterChip('Semua', null, false),
    _FilterChip('Toilet & Wudhu', Icons.wc, false),
    _FilterChip('Posko Medis PPIH', Icons.medical_services, false),
    _FilterChip('Tenda Maktab 48', Icons.holiday_village, false),
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
          _buildTopHeader(state),

          // Right-side floating controls
          _buildFloatingControls(),

          // Bottom Sheet
          _buildBottomSheet(state),
        ],
      ),
      bottomNavigationBar: HajiCareBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildTopHeader(HajiCareState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 4,
          left: AppConstants.spaceMd,
          right: AppConstants.spaceMd,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.canvasCream.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top row: Live Tracking Badge + SOS Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceSm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espressoDark.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _AnimatedPingDot(),
                      const SizedBox(width: 6),
                      Text(
                        'Pelacakan Aktif',
                        style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark),
                      ),
                      Text(
                        ' • GPS 3m',
                        style: AppTypography.caption.copyWith(color: AppColors.textBody),
                      ),
                    ],
                  ),
                ),
                // SOS Button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.sosEmergency,
                      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sosEmergency.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sos, color: AppColors.surfaceWhite, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'SOS',
                          style: AppTypography.captionBold.copyWith(color: AppColors.surfaceWhite),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Search Bar
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(alpha: 0.04),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: AppConstants.spaceMd),
                    child: Icon(Icons.search, color: AppColors.tanMedium, size: 22),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cari toilet, tenda maktab, posko medis...',
                      style: AppTypography.bodySm.copyWith(color: AppColors.textBody),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.mic, color: AppColors.tanMedium, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Filter Chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppConstants.spaceXs),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = index == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryContainer : AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                        border: isSelected
                            ? null
                            : Border.all(color: AppColors.goldLight.withValues(alpha: 0.7)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.espressoDark.withValues(alpha: 0.04),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (filter.icon != null) ...[
                            Icon(
                              filter.icon,
                              size: 15,
                              color: isSelected
                                  ? AppColors.surfaceWhite
                                  : (filter.label.contains('Medis')
                                      ? AppColors.sosEmergency
                                      : AppColors.tanMedium),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            filter.label,
                            style: (isSelected ? AppTypography.captionBold : AppTypography.caption).copyWith(
                              color: isSelected ? AppColors.surfaceWhite : AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCanvas(HajiCareState state) {
    return Positioned.fill(
      child: Container(
        color: AppColors.canvasCreamSubtle,
        child: CustomPaint(
          painter: _MinaMapPainter(),
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
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.statusPositive,
                    fontSize: 10,
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
                    borderRadius: BorderRadius.circular(AppConstants.radiusPill),
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
                      const Icon(Icons.directions_walk, size: 12, color: AppColors.accentGoldStar),
                      const SizedBox(width: 4),
                      Text(
                        '120m • 2 menit jalan',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.surfaceWhite,
                          fontSize: 10,
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
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
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
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.surfaceWhite,
                  fontSize: 10,
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
                child: const Icon(Icons.navigation, color: AppColors.surfaceWhite, size: 11),
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
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
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
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.espressoDark,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.battery_5_bar, size: 12, color: AppColors.statusPositive),
              Text(
                '92%',
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.statusPositive,
                  fontSize: 10,
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
              style: AppTypography.caption.copyWith(
                color: isEmergency ? AppColors.sosEmergency : AppColors.textBody,
                fontSize: 10,
                fontWeight: isEmergency ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      right: AppConstants.spaceMd,
      top: MediaQuery.of(context).padding.top + 158,
      child: Column(
        children: [
          _buildControlButton(Icons.explore, color: AppColors.accentGoldStar, label: 'Kiblat'),
          const SizedBox(height: 10),
          _buildControlButton(Icons.my_location, color: AppColors.primary, label: 'Pusatkan'),
          const SizedBox(height: 10),
          _buildControlButton(Icons.layers, color: AppColors.tanMedium, label: 'Peta'),
          const SizedBox(height: 10),
          _buildControlButton(
            Icons.ring_volume,
            color: AppColors.onSecondaryContainer,
            label: 'Gelang',
            bgColor: AppColors.secondaryContainer,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, {
    required Color color,
    required String label,
    Color bgColor = AppColors.surfaceWhite,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: color),
      ),
    );
  }

  Widget _buildBottomSheet(HajiCareState state) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusCard)),
          border: Border(
            top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.espressoDark.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spaceLg),
              child: Column(
                children: [
                  // Pilgrim Identity Row
                  Row(
                    children: [
                      // Avatar
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.canvasCream,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.goldLight),
                            ),
                            child: const Icon(Icons.elderly, color: AppColors.tanMedium, size: 32),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: AppColors.statusPositive,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surfaceWhite, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Name & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'H. Ahmad Dahlan',
                                  style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryContainer,
                                    borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                                  ),
                                  child: Text(
                                    'Ayah',
                                    style: AppTypography.captionBold.copyWith(
                                      color: AppColors.onSecondaryContainer,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.check_circle, size: 15, color: AppColors.statusPositive),
                                const SizedBox(width: 4),
                                Text(
                                  'Dalam Radius Aman (120m)',
                                  style: AppTypography.bodySm.copyWith(color: AppColors.textBody),
                                ),
                                Text(
                                  ' • Baru saja',
                                  style: AppTypography.caption.copyWith(color: AppColors.outlineVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Call button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.canvasCream,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.espressoDark.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call, color: AppColors.tanMedium, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.spaceMd),

                  // Status Metrics Bar
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.canvasCream.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                      border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetric(Icons.watch, 'Baterai Gelang', '92% • Aktif', AppColors.statusPositive),
                        ),
                        Container(width: 1, height: 32, color: AppColors.goldLight.withValues(alpha: 0.4)),
                        Expanded(
                          child: _buildMetric(Icons.favorite, 'Detak Jantung', '78 bpm • Normal', AppColors.sosEmergency),
                        ),
                        Container(width: 1, height: 32, color: AppColors.goldLight.withValues(alpha: 0.4)),
                        Expanded(
                          child: _buildMetric(Icons.holiday_village, 'Maktab', 'Maktab 48 Mina', AppColors.tanMedium),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceMd),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Navigasi ke Jamaah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.espressoDark,
                            foregroundColor: AppColors.onPrimary,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spaceSm),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.canvasCream,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.goldLight),
                        ),
                        child: const Icon(Icons.share_location, color: AppColors.espressoDark, size: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption.copyWith(color: AppColors.textBody, fontSize: 10)),
                Text(value, style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the Mina tent city map background
class _MinaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base map color
    final basePaint = Paint()..color = const Color(0xFFEFE5D5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    // Tent blocks
    final tentPaint = Paint()
      ..color = const Color(0xFFE8DEC9)
      ..style = PaintingStyle.fill;
    final tentBorderPaint = Paint()
      ..color = const Color(0xFFDACDB5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Draw tent sectors
    _drawRoundedRect(canvas, 20, 80, 160, 140, tentPaint, tentBorderPaint);
    _drawRoundedRect(canvas, 230, 70, 170, 160, tentPaint, tentBorderPaint);
    _drawRoundedRect(canvas, 20, 270, 140, 190, tentPaint, tentBorderPaint);
    _drawRoundedRect(canvas, 250, 280, 150, 180, tentPaint, tentBorderPaint);
    _drawRoundedRect(canvas, 40, 500, 340, 130, tentPaint, tentBorderPaint);

    // Pedestrian boulevards
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round;
    final roadDashPaint = Paint()
      ..color = const Color(0xFFD8C3A5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Main boulevard East-West
    final pathEW = Path()
      ..moveTo(0, 245)
      ..quadraticBezierTo(size.width / 2, 235, size.width, 255);
    canvas.drawPath(pathEW, roadPaint);
    canvas.drawPath(pathEW, roadDashPaint);

    // North-South walkway
    final pathNS = Path()
      ..moveTo(200, 0)
      ..lineTo(195, size.height);
    canvas.drawPath(pathNS, roadPaint..strokeWidth = 22);
    canvas.drawPath(pathNS, roadDashPaint);

    // Secondary alleys
    final smallRoadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(90, 240), const Offset(90, 460), smallRoadPaint);
    canvas.drawLine(const Offset(310, 250), const Offset(310, 480), smallRoadPaint);

    // Walking path (dashed) from companion to jamaah
    final walkPathPaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final walkPath = Path()
      ..moveTo(145, 405)
      ..lineTo(200, 405)
      ..lineTo(202, 290)
      ..lineTo(250, 280);
    canvas.drawPath(walkPath, walkPathPaint);

    final walkAccentPaint = Paint()
      ..color = const Color(0xFFD4A857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(walkPath, walkAccentPaint);
  }

  void _drawRoundedRect(Canvas canvas, double x, double y, double w, double h, Paint fill, Paint stroke) {
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(8));
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);

    // Cross pattern inside (tent lines)
    final crossPaint = Paint()
      ..color = const Color(0xFFDACDB5).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (double i = x; i < x + w; i += 34) {
      for (double j = y; j < y + h; j += 34) {
        canvas.drawLine(Offset(i, j), Offset(i + 28, j + 28), crossPaint);
        canvas.drawLine(Offset(i + 28, j), Offset(i, j + 28), crossPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedPingDot extends StatefulWidget {
  @override
  State<_AnimatedPingDot> createState() => _AnimatedPingDotState();
}

class _AnimatedPingDotState extends State<_AnimatedPingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 10 * (1 + _controller.value * 0.5),
                height: 10 * (1 + _controller.value * 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.statusPositive.withValues(alpha: (1 - _controller.value) * 0.5),
                ),
              );
            },
          ),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.statusPositive,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip {
  final String label;
  final IconData? icon;
  final bool isDefault;
  const _FilterChip(this.label, this.icon, this.isDefault);
}
