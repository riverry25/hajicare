import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class DashboardJamaahScreen extends StatefulWidget {
  const DashboardJamaahScreen({super.key});

  @override
  State<DashboardJamaahScreen> createState() => _DashboardJamaahScreenState();
}

class _DashboardJamaahScreenState extends State<DashboardJamaahScreen> {
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
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mosque, color: AppColors.accentGoldStar, size: 16),
            ),
            const SizedBox(width: 6),
            Text(
              'HajiCare',
              style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark, fontWeight: FontWeight.w800),
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
            child: CircleAvatar(
              backgroundColor: AppColors.errorContainer,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.sos, color: AppColors.sosEmergency, size: 24),
                padding: EdgeInsets.zero,
                onPressed: () {
                  // Show modal SOS
                  Navigator.of(context).pushNamed('/modal_sos');
                },
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildDistanceStatus(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildSosButton(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildPrayerTimes(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildFeatureGrid(),
          const SizedBox(height: AppConstants.spaceMd),
          _buildTipsBanner(),
          const SizedBox(height: AppConstants.space3xl), // Bottom nav padding
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

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.tanMedium.withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.account_circle, color: AppColors.primary, size: 36),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('H. Ahmad Dahlan', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: AppColors.statusPositive, size: 16),
                      ],
                    ),
                    Text(
                      'Kloter 14 JKS • Maktab 48, Mina',
                      style: AppTypography.caption.copyWith(color: AppColors.textBody),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.format_size, color: AppColors.espressoDark),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppConstants.radiusPill),
              border: Border.all(color: AppColors.statusPositive.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.statusPositive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Terhubung: ',
                      style: AppTypography.caption.copyWith(color: AppColors.espressoDark),
                      children: [
                        TextSpan(
                          text: 'Siti Aminah (Putri)',
                          style: AppTypography.captionBold.copyWith(color: AppColors.textHeading),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusPositive.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  ),
                  child: Text(
                    'Aktif',
                    style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceStatus() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.radar, color: AppColors.espressoDark),
              ),
              const SizedBox(width: AppConstants.spaceXs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status Jarak ke Pendamping', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('120', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 4),
                        Text('meter', style: AppTypography.bodySm.copyWith(color: AppColors.textBody, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusPositive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  border: Border.all(color: AppColors.statusPositive.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.statusPositive, size: 14),
                    const SizedBox(width: 4),
                    Text('Radius Aman', style: AppTypography.captionBold.copyWith(color: AppColors.statusPositive, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceSm),
          LinearProgressIndicator(
            value: 0.6, // 120 / 200
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.statusPositive,
            minHeight: 10,
            borderRadius: BorderRadius.circular(AppConstants.radiusPill),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.pin_drop, color: AppColors.tanMedium, size: 16),
                  const SizedBox(width: 6),
                  Text('Lihat Posisi Pendamping di Peta', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                ],
              ),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.espressoDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSosButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed('/modal_sos');
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusCard),
          border: Border.all(color: AppColors.sosEmergency.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.sosEmergency.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm, vertical: AppConstants.spaceSm),
              decoration: BoxDecoration(
                color: AppColors.sosEmergency,
                borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sosEmergency.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emergency_share, color: AppColors.surfaceWhite, size: 30),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TOMBOL DARURAT SOS', style: AppTypography.headlineMd.copyWith(color: AppColors.surfaceWhite, fontWeight: FontWeight.w800)),
                        Text('Tekan Langsung Saat Butuh Pertolongan', style: AppTypography.caption.copyWith(color: AppColors.surfaceWhite.withOpacity(0.9))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTypography.bodySm.copyWith(color: AppColors.textHeading),
                children: [
                  const TextSpan(text: 'Sinyal GPS darurat akan seketika diteruskan ke '),
                  TextSpan(text: 'Petugas Maktab 48', style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.bold, color: AppColors.espressoDark)),
                  const TextSpan(text: ' dan '),
                  TextSpan(text: 'Pendamping Keluarga.', style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.bold, color: AppColors.espressoDark)),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.spaceXs),
            const Divider(color: AppColors.outlineVariant),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.sosEmergency,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Respons Cepat 24 Jam • Sektor Khusus Masjidil Haram',
                  style: AppTypography.caption.copyWith(color: AppColors.textBody, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimes() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.goldLight.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.tanMedium, size: 20),
                  const SizedBox(width: 8),
                  Text('JADWAL SHOLAT MAKKAH', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  border: Border.all(color: AppColors.goldLight.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.explore, color: AppColors.accentGoldStar, size: 14),
                    const SizedBox(width: 4),
                    Text('Kiblat 294°', style: AppTypography.caption.copyWith(color: AppColors.textHeading, fontWeight: FontWeight.w600, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Container(
            padding: const EdgeInsets.all(AppConstants.spaceSm),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite.withOpacity(0.7),
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waktu Sholat Berikutnya', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('Ashar', style: AppTypography.headlineLg.copyWith(color: AppColors.espressoDark, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Text('15:42 AST', style: AppTypography.titleSm.copyWith(color: AppColors.tanMedium, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  ),
                  child: Text('Dalam 48 menit', style: AppTypography.captionBold.copyWith(color: AppColors.surfaceWhite, fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPrayerMiniTime('Subuh', '04:52', false),
              _buildPrayerMiniTime('Dzuhur', '12:28', false),
              _buildPrayerMiniTime('Ashar', '15:42', true),
              _buildPrayerMiniTime('Maghrib', '18:35', false),
              _buildPrayerMiniTime('Isya', '20:05', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerMiniTime(String name, String time, bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryContainer : AppColors.surfaceWhite.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: isActive ? Border.all(color: AppColors.goldLight) : Border.all(color: Colors.transparent),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.primaryContainer.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Text(
              name,
              style: AppTypography.caption.copyWith(
                color: isActive ? AppColors.accentGoldStar : AppColors.textBody,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            Text(
              time,
              style: AppTypography.captionBold.copyWith(
                color: isActive ? AppColors.surfaceWhite : AppColors.textHeading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Layanan Jamaah Mandiri', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
            Text('Sentuh Mudah', style: AppTypography.caption.copyWith(color: AppColors.tanMedium, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: AppConstants.spaceXs),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: AppConstants.spaceSm,
          mainAxisSpacing: AppConstants.spaceSm,
          childAspectRatio: 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildFeatureCard('Peta & Arah', 'Toilet, Wudhu, Tenda Mina & Sektor', Icons.near_me),
            _buildFeatureCard('Pindai Uang Riyal', 'Deteksi Nominal Kertas & Suara', Icons.photo_camera),
            _buildFeatureCard('Komunikasi Cepat', 'Frasa Arab: Tolong, Sakit, Air', Icons.record_voice_over),
            _buildFeatureCard('Gelang Pintar', 'GPS & Detak Jantung Terhubung', Icons.watch),
            _buildFeatureCard('Doa & Manasik', 'Doa Tawaf, Sai Huruf Besar + Audio', Icons.menu_book),
            _buildFeatureCard('Panggilan Petugas', 'Telepon Pos Maktab & Kloter', Icons.phone_in_talk),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
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
                style: AppTypography.titleSm.copyWith(color: AppColors.textHeading, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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

  Widget _buildTipsBanner() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: AppColors.secondaryContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.tanMedium.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb, color: AppColors.espressoDark),
          ),
          const SizedBox(width: AppConstants.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HIMBAUAN PETUGAS SEKTOR', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark)),
                const SizedBox(height: 2),
                Text(
                  'Tetap bersama rombongan saat menuju jamarat. Pastikan botol air minum terisi penuh dan kenakan selalu gelang identitas Anda.',
                  style: AppTypography.bodySm.copyWith(color: AppColors.textHeading),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
