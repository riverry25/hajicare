import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.canvasCream,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceWhite,
          elevation: 1,
          title: Text('Notifikasi & Bantuan', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: AppColors.espressoDark,
            labelColor: AppColors.espressoDark,
            unselectedLabelColor: AppColors.tanMedium,
            tabs: [
              Tab(text: 'Notifikasi'),
              Tab(text: 'FAQ & Bantuan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationList(),
            _buildFaqList(),
          ],
        ),
        bottomNavigationBar: const HajiCareBottomNavBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      children: [
        Text('Hari Ini', style: AppTypography.labelPill.copyWith(color: AppColors.textBody)),
        const SizedBox(height: AppConstants.spaceSm),
        _buildNotificationCard(
          icon: Icons.campaign,
          iconColor: AppColors.primary,
          title: 'Himbauan Gelombang Panas',
          message: 'Suhu di Makkah mencapai 45°C. Perbanyak minum air putih dan hindari sinar matahari langsung.',
          time: '10:00 AM',
          isUnread: true,
        ),
        _buildNotificationCard(
          icon: Icons.directions_bus,
          iconColor: AppColors.secondary,
          title: 'Jadwal Bus Shalawat',
          message: 'Bus rute Syisyah - Masjidil Haram beroperasi normal setiap 10 menit.',
          time: '08:30 AM',
          isUnread: false,
        ),
        const SizedBox(height: AppConstants.spaceLg),
        Text('Kemarin', style: AppTypography.labelPill.copyWith(color: AppColors.textBody)),
        const SizedBox(height: AppConstants.spaceSm),
        _buildNotificationCard(
          icon: Icons.check_circle,
          iconColor: AppColors.statusPositive,
          title: 'Gelang Pintar Terhubung',
          message: 'Gelang Anda telah berhasil disinkronkan dengan aplikasi Pendamping.',
          time: 'Kemarin, 14:20',
          isUnread: false,
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceSm),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.surfaceWhite : AppColors.surfaceWhite.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: isUnread ? AppColors.goldLight : AppColors.canvasCreamSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleSm.copyWith(
                          color: AppColors.espressoDark,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.statusPositive,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTypography.bodySm.copyWith(color: AppColors.textBody)),
                const SizedBox(height: 8),
                Text(time, style: AppTypography.caption.copyWith(color: AppColors.tanMedium)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqList() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      children: [
        _buildFaqItem(
          'Bagaimana cara menggunakan tombol SOS?',
          'Tekan dan tahan tombol SOS merah muda di beranda selama 3 detik. Sinyal dan lokasi GPS Anda akan otomatis terkirim ke pendamping.',
        ),
        _buildFaqItem(
          'Apakah gelang pintar tahan air?',
          'Ya, gelang pintar dirancang tahan air (wudhu, mandi, keringat), tetapi tidak disarankan untuk menyelam dalam air.',
        ),
        _buildFaqItem(
          'Bagaimana jika saya terpisah dari rombongan?',
          'Gunakan fitur Peta Interaktif untuk melihat jalur kembali, atau tekan tombol Panggil Pendamping agar mereka dapat melacak lokasi Anda.',
        ),
        _buildFaqItem(
          'Cara mengganti bahasa aplikasi?',
          'Pergi ke menu Profil & Pengaturan > Lainnya > Bahasa, lalu pilih bahasa yang diinginkan (Indonesia, Arab, atau Inggris).',
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppConstants.spaceSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        side: const BorderSide(color: AppColors.canvasCreamSubtle),
      ),
      child: ExpansionTile(
        title: Text(question, style: AppTypography.titleSm.copyWith(color: AppColors.espressoDark)),
        childrenPadding: const EdgeInsets.only(left: AppConstants.spaceMd, right: AppConstants.spaceMd, bottom: AppConstants.spaceMd),
        children: [
          Text(answer, style: AppTypography.bodyMd.copyWith(color: AppColors.textBody)),
        ],
      ),
    );
  }
}
