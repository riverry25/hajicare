import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class DashboardPendampingScreen extends StatefulWidget {
  const DashboardPendampingScreen({super.key});

  @override
  State<DashboardPendampingScreen> createState() => _DashboardPendampingScreenState();
}

class _DashboardPendampingScreenState extends State<DashboardPendampingScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.mosque, color: AppColors.surfaceWhite, size: 16),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HajiCare',
                  style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark, fontWeight: FontWeight.w800),
                ),
                Text(
                  'PENDAMPING',
                  style: AppTypography.captionBold.copyWith(color: AppColors.tanMedium, fontSize: 10),
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
                icon: const Icon(Icons.notifications, color: AppColors.espressoDark),
                onPressed: () {},
              ),
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
            padding: const EdgeInsets.only(right: AppConstants.spaceMd),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldLight, width: 2),
              ),
              child: const Icon(Icons.person, color: AppColors.tanMedium), // Profile placeholder
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        children: [
          _buildGreeting(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildJamaahSelector(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildRadarCard(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildSosStandbyBanner(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildMapCard(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildFeatureGrid(),
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

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.onSecondaryContainer, size: 14),
                  const SizedBox(width: 4),
                  Text('Mode Pendamping Aktif', style: AppTypography.captionBold.copyWith(color: AppColors.onSecondaryContainer)),
                ],
              ),
            ),
            Text('Kloter 14 JKS • Maktab 48', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
          ],
        ),
        const SizedBox(height: AppConstants.spaceXs),
        Text('Assalamu’alaikum, Siti', style: AppTypography.headlineLg.copyWith(color: AppColors.espressoDark)),
        Text('Pantau keselamatan dan pergerakan jamaah binaan Anda secara real-time.', style: AppTypography.bodySm.copyWith(color: AppColors.textBody)),
      ],
    );
  }

  Widget _buildJamaahSelector() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Jamaah Dipantau (2)', style: AppTypography.titleSm.copyWith(color: AppColors.espressoDark)),
            Text('Sinkron Gelang Pintar', style: AppTypography.caption.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: AppConstants.spaceXs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildJamaahPill('H. Ahmad Dahlan (Ayah)', '120m', true),
              const SizedBox(width: AppConstants.spaceXs),
              _buildJamaahPill('Hj. Siti Fatimah (Ibu)', '85m', false),
              const SizedBox(width: AppConstants.spaceXs),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tanMedium, width: 2, style: BorderStyle.none),
                  // Draw dashed conceptually with styling, using solid for now
                ),
                child: const Icon(Icons.person_add, color: AppColors.tanMedium),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJamaahPill(String name, String distance, bool isActive) {
    return Container(
      padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4, right: AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceWhite : AppColors.surfaceWhite.withOpacity(0.75),
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(
          color: isActive ? AppColors.espressoDark : AppColors.goldLight,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive ? [
          BoxShadow(color: AppColors.espressoDark.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
        ] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldLight),
              color: AppColors.canvasCream,
            ),
            child: const Icon(Icons.person, color: AppColors.textBody), // Profile placeholder
          ),
          const SizedBox(width: AppConstants.spaceXs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.labelPill.copyWith(color: isActive ? AppColors.espressoDark : AppColors.textHeading)),
              Row(
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
                    'Terhubung • $distance',
                    style: AppTypography.captionBold.copyWith(
                      color: isActive ? AppColors.statusPositive : AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.canvasCreamSubtle),
        boxShadow: [
          BoxShadow(color: AppColors.espressoDark.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.canvasCream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radar, color: AppColors.espressoDark, size: 24),
                  ),
                  const SizedBox(width: AppConstants.spaceXs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('RADAR JARAK JAMAAH', style: AppTypography.captionBold.copyWith(color: AppColors.textBody)),
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.statusPositive, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                      Text('H. Ahmad Dahlan', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusPositive.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.statusPositive, size: 14),
                    const SizedBox(width: 4),
                    Text('Dalam Radius Aman', style: AppTypography.captionBold.copyWith(color: AppColors.statusPositive, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Container(
            padding: const EdgeInsets.all(AppConstants.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.canvasCream.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: AppColors.goldLight.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('120', style: AppTypography.displayHero.copyWith(color: AppColors.espressoDark)),
                        const SizedBox(width: 4),
                        Text('meter', style: AppTypography.headlineMd.copyWith(color: AppColors.textBody)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Batas Maksimal', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                        Text('200 meter', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceSm),
                LinearProgressIndicator(
                  value: 0.6,
                  backgroundColor: AppColors.surfaceWhite,
                  color: AppColors.statusPositive,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0m (Dekat)', style: AppTypography.caption.copyWith(color: AppColors.textBody, fontSize: 11)),
                    Text('60% dari radius batas', style: AppTypography.caption.copyWith(color: AppColors.espressoDark, fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('200m (Peringatan)', style: AppTypography.caption.copyWith(color: AppColors.textBody, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          const Divider(color: AppColors.canvasCreamSubtle),
          const SizedBox(height: AppConstants.spaceXs),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.watch, color: AppColors.tanMedium, size: 18),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gelang Pintar', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                        Text('Baterai 92% • GPS Aktif', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.tanMedium, size: 18),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Terakhir Sinkron', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                        Text('15 detik yang lalu', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceMd),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.espressoDark,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.near_me, size: 20),
                const SizedBox(width: AppConstants.spaceXs),
                const Text('Lacak di Peta Interaktif'),
                const SizedBox(width: AppConstants.spaceXs),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXs),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.espressoDark,
              side: const BorderSide(color: AppColors.goldLight),
              minimumSize: const Size.fromHeight(40),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.tune, size: 16, color: AppColors.tanMedium),
                const SizedBox(width: 4),
                Text('Atur Batas Radius Aman (200m)', style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosStandbyBanner() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.distanceWarning.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: AppColors.espressoDark.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -16, top: -16, bottom: -16,
            child: Container(width: 6, color: AppColors.distanceWarning),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 4), // Offset for the left border
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.distanceWarning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, color: AppColors.distanceWarning),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status Darurat & SOS: Siaga', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                          ),
                          child: Text('STANDBY', style: AppTypography.captionBold.copyWith(color: AppColors.onSecondaryContainer, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alarm getar & nada kencang otomatis berbunyi jika tombol gelang ditekan atau jarak jamaah melebihi 200m.',
                      style: AppTypography.bodySm.copyWith(color: AppColors.textBody),
                    ),
                    const SizedBox(height: AppConstants.spaceSm),
                    Row(
                      children: [
                        _buildSmallBtn(Icons.volume_up, 'Uji Sinyal Alarm', AppColors.canvasCream, AppColors.espressoDark, false),
                        const SizedBox(width: AppConstants.spaceXs),
                        _buildSmallBtn(Icons.call, 'Pusat Tanggap', Colors.transparent, AppColors.sosEmergency, true, borderColor: AppColors.sosEmergency.withOpacity(0.3)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallBtn(IconData icon, String label, Color bg, Color fg, bool outline, {Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: outline ? Border.all(color: borderColor ?? fg) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.captionBold.copyWith(color: fg)),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.canvasCreamSubtle),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore, color: AppColors.tanMedium, size: 20),
                  const SizedBox(width: AppConstants.spaceXs),
                  Text('Posisi Lapangan Real-Time', style: AppTypography.titleSm.copyWith(color: AppColors.espressoDark)),
                ],
              ),
              Text('Area Mina Sektor 3', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
            ],
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Container(
            height: 176,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.canvasCreamSubtle,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: AppColors.goldLight.withOpacity(0.6)),
            ),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.map, size: 48, color: AppColors.tanMedium)),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.open_in_full, size: 16, color: AppColors.espressoDark),
                        const SizedBox(width: 6),
                        Text('Buka Navigasi Penuh & Jalur Evakuasi', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.route, color: AppColors.tanMedium, size: 14),
                  const SizedBox(width: 4),
                  Text('Rute: Jalur Khusus Lansia King Fahd', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                ],
              ),
              Text('Tenda Maktab 48', style: AppTypography.caption.copyWith(color: AppColors.espressoDark, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Menu Layanan Pendamping', style: AppTypography.titleSm.copyWith(color: AppColors.espressoDark)),
        const SizedBox(height: AppConstants.spaceXs),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.spaceSm,
          mainAxisSpacing: AppConstants.spaceSm,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard('Peta Terpadu Sektor', 'Posko medis & jalur evakuasi', Icons.map),
            _buildFeatureCard('Jamaah & Gelang', 'Status baterai & sensor nadi', Icons.devices_other),
            _buildFeatureCard('Jadwal & Agenda', 'Waktu Jamarat & titik kumpul', Icons.event_note),
            _buildFeatureCard('Kontak Petugas Maktab', 'Akses instan layanan darurat', Icons.contact_phone),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.canvasCreamSubtle),
      ),
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
            child: Icon(icon, color: AppColors.espressoDark),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(color: AppColors.textBody, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
