import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class JamaahServiceGrid extends StatelessWidget {
  const JamaahServiceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'Peta & Arah',
        'subtitle': 'Toilet, Wudhu, Tenda Mina & Sektor',
        'icon': Icons.near_me,
        'route': '/map',
      },
      {
        'title': 'Pindai Uang Riyal',
        'subtitle': 'Deteksi Nominal Kertas & Suara',
        'icon': Icons.photo_camera,
        'route': '/money',
      },
      {
        'title': 'Komunikasi Cepat',
        'subtitle': 'Frasa Arab: Tolong, Sakit, Air',
        'icon': Icons.record_voice_over,
        'route': '/communication',
      },
      {
        'title': 'Gelang Pintar',
        'subtitle': 'GPS & Detak Jantung Terhubung',
        'icon': Icons.watch,
        'route': null,
      },
      {
        'title': 'Doa & Manasik',
        'subtitle': 'Doa Tawaf, Sai Huruf Besar + Audio',
        'icon': Icons.menu_book,
        'route': null,
      },
      {
        'title': 'Panggilan Petugas',
        'subtitle': 'Telepon Pos Maktab & Kloter',
        'icon': Icons.phone_in_talk,
        'route': null,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Layanan Jamaah Mandiri',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.espressoDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Sentuh Mudah',
              style: AppTypography.caption.copyWith(
                color: AppColors.tanMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive aspect ratio based on width to prevent overflow
            final double cardWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            final double ratio = cardWidth < 170 ? 0.95 : 1.05;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: ratio,
              ),
              itemBuilder: (context, index) {
                final item = services[index];
                return _buildServiceCard(
                  context: context,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  icon: item['icon'] as IconData,
                  route: item['route'] as String?,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String? route,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: route != null ? () => Navigator.of(context).pushNamed(route) : null,
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
            child: Icon(icon, color: AppColors.espressoDark, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textHeading,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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
  }
}
