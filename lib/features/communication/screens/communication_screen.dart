import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/bottom_nav_bar.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  late FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _tts.setLanguage('ar-SA');
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _speak(String text) {
    _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 1,
        title: Text(
          'Komunikasi Cepat',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenEdgeGutter,
          vertical: AppSpacing.md,
        ),
        children: [
          Text(
            'Tekan tombol suara untuk memutar rekaman bahasa Arab',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textBody),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          _buildCategoryHeader('Darurat & Kesehatan'),
          _buildPhraseCard(
            'Tolong, saya butuh dokter',
            'Musa\'adah, ahtaju tabiban',
            'مساعدة، أحتاج طبيباً',
            true,
          ),
          _buildPhraseCard(
            'Saya merasa sakit',
            'Ana mareed',
            'أنا مريض',
            false,
          ),
          _buildPhraseCard(
            'Dimana rumah sakit?',
            'Ayna al-mustashfa?',
            'أين المستشفى؟',
            false,
          ),

          const SizedBox(height: AppSpacing.md),
          _buildCategoryHeader('Arah & Lokasi'),
          _buildPhraseCard(
            'Saya tersesat',
            'Ana dae\'e',
            'أنا ضائع',
            true,
          ),
          _buildPhraseCard(
            'Dimana pintu keluar?',
            'Ayna al-makhraj?',
            'أين المخرج؟',
            false,
          ),

          const SizedBox(height: AppSpacing.md),
          _buildCategoryHeader('Umum'),
          _buildPhraseCard(
            'Boleh minta air?',
            'Mumaakin maa\'?',
            'ممكن ماء؟',
            false,
          ),
          _buildPhraseCard(
            'Terima kasih',
            'Shukran',
            'شكراً',
            false,
          ),
          const SizedBox(height: AppConstants.space3xl),
        ],
      ),
      bottomNavigationBar: const HajiCareBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.espressoDark,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhraseCard(
    String indo,
    String transliteration,
    String arabic,
    bool isUrgent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.errorContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isUrgent
              ? AppColors.sosEmergency.withValues(alpha: 0.3)
              : AppColors.canvasCreamSubtle,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
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
                  style: AppTypography.displayMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.espressoDark,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: AppSpacing.sm2),
                Text(
                  indo,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.espressoDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  transliteration,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textBody,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color:
                  isUrgent ? AppColors.sosEmergency : AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: () => _speak(arabic),
            ),
          ),
        ],
      ),
    );
  }
}
