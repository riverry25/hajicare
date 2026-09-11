import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3; // Profil is index 3

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.canvasCream,
        elevation: 0,
        title: Text('Profil & Pengaturan', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppConstants.radiusCard),
              border: Border.all(color: AppColors.canvasCreamSubtle),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDark.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.goldLight, width: 2),
                      ),
                      child: const Icon(Icons.account_circle, color: AppColors.primaryContainer, size: 60),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.espressoDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: AppColors.surfaceWhite, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceMd),
                Text('H. Ahmad Dahlan', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
                Text('Jamaah • Kloter 14 JKS', style: AppTypography.bodyMd.copyWith(color: AppColors.textBody)),
                const SizedBox(height: AppConstants.spaceMd),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                  ),
                  child: Text('Gelang Pintar Terhubung (Baterai 92%)', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spaceLg),

          // Settings Options
          _buildSettingsGroup('Data & Sinkronisasi', [
            _buildListTile(Icons.medical_information, 'Data Medis & Riwayat'),
            _buildListTile(Icons.link, 'Kelola Pendamping'),
          ]),
          
          _buildSettingsGroup('Aksesibilitas', [
            _buildListTile(Icons.text_increase, 'Ukuran Teks', trailing: 'Besar'),
            _buildListTile(Icons.contrast, 'Kontras Tinggi', isSwitch: true),
            _buildListTile(Icons.volume_up, 'Pembaca Layar (VoiceOver)', isSwitch: true),
          ]),
          
          _buildSettingsGroup('Lainnya', [
            _buildListTile(Icons.language, 'Bahasa', trailing: 'Indonesia'),
            _buildListTile(Icons.help_outline, 'Pusat Bantuan & FAQ'),
            _buildListTile(Icons.info_outline, 'Tentang Aplikasi', trailing: 'v1.0.0'),
          ]),
          
          const SizedBox(height: AppConstants.spaceLg),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorContainer,
              foregroundColor: AppColors.error,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusPill)),
            ),
            child: const Text('Keluar (Log Out)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppConstants.spaceSm, bottom: AppConstants.spaceXs, top: AppConstants.spaceMd),
          child: Text(title, style: AppTypography.labelPill.copyWith(color: AppColors.textBody)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppConstants.radiusCard),
            border: Border.all(color: AppColors.canvasCreamSubtle),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, {String? trailing, bool isSwitch = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.canvasCream,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.espressoDark, size: 20),
      ),
      title: Text(title, style: AppTypography.bodyMd.copyWith(color: AppColors.espressoDark)),
      trailing: isSwitch
          ? Switch(
              value: false, // Static for now
              onChanged: (val) {},
              activeThumbColor: AppColors.statusPositive,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailing != null)
                  Text(trailing, style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                if (trailing != null) const SizedBox(width: AppConstants.spaceXs),
                const Icon(Icons.chevron_right, color: AppColors.tanMedium),
              ],
            ),
      onTap: () {},
    );
  }
}
