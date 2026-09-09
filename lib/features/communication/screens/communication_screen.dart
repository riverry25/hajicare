import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 1,
        title: Text('Komunikasi Cepat', style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        children: [
          Text(
            'Tekan tombol suara untuk memutar rekaman bahasa Arab',
            style: AppTypography.bodyMd.copyWith(color: AppColors.textBody),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spaceLg),
          
          _buildCategoryHeader('Darurat & Kesehatan'),
          _buildPhraseCard('Tolong, saya butuh dokter', 'Musa\'adah, ahtaju tabiban', 'مساعدة، أحتاج طبيباً', true),
          _buildPhraseCard('Saya merasa sakit', 'Ana mareed', 'أنا مريض', false),
          _buildPhraseCard('Dimana rumah sakit?', 'Ayna al-mustashfa?', 'أين المستشفى؟', false),
          
          const SizedBox(height: AppConstants.spaceMd),
          _buildCategoryHeader('Arah & Lokasi'),
          _buildPhraseCard('Saya tersesat', 'Ana dae\'e', 'أنا ضائع', true),
          _buildPhraseCard('Dimana pintu keluar?', 'Ayna al-makhraj?', 'أين المخرج؟', false),
          
          const SizedBox(height: AppConstants.spaceMd),
          _buildCategoryHeader('Umum'),
          _buildPhraseCard('Boleh minta air?', 'Mumaakin maa\'?', 'ممكن ماء؟', false),
          _buildPhraseCard('Terima kasih', 'Shukran', 'شكراً', false),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
      child: Text(title, style: AppTypography.titleSm.copyWith(color: AppColors.espressoDark)),
    );
  }

  Widget _buildPhraseCard(String indo, String transliteration, String arabic, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceSm),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.errorContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusCard),
        border: Border.all(color: isUrgent ? AppColors.sosEmergency.withOpacity(0.3) : AppColors.canvasCreamSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  arabic,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.espressoDark),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: AppConstants.spaceXs),
                Text(indo, style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
                Text(transliteration, style: AppTypography.caption.copyWith(color: AppColors.textBody, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          Container(
            decoration: BoxDecoration(
              color: isUrgent ? AppColors.sosEmergency : AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
