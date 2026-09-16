import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = AppColors.scaffoldColor(context);
    final headingColor = AppColors.textHeadingColor(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppColors.cardBgColor(context),
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: headingColor, size: 20),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Notifikasi & Bantuan',
            style: AppTypography.headlineMd.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppColors.goldPrimary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: headingColor,
            unselectedLabelColor: AppColors.textSecondaryColor(context),
            labelStyle: AppTypography.titleSm.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: AppTypography.titleSm.copyWith(fontWeight: FontWeight.w500),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Notifikasi'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('FAQ & Bantuan'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildNotificationList(context),
            _buildFaqList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      children: [
        // Section: Hari ini
        _buildSectionHeader(context, 'HARI INI', Icons.today_rounded),
        const SizedBox(height: AppSpacing.sm),
        _buildNotificationCard(
          context: context,
          category: 'PERINGATAN CUACA',
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFE65100),
          title: 'Himbauan Gelombang Panas Makkah',
          message:
              'Suhu di sekitar Masjidil Haram mencapai 45°C. Jamaah diimbau memperbanyak minum air zamzam, memakai payung, dan menghindari paparan langsung.',
          time: '10:00 AM',
          isUnread: true,
        ),
        _buildNotificationCard(
          context: context,
          category: 'JADWAL KLOTER',
          icon: Icons.directions_bus_rounded,
          iconColor: AppColors.goldDark,
          title: 'Jadwal Bus Shalawat Rute Syisyah',
          message:
              'Bus Shalawat rute nomor 3 (Syisyah - Terminal Syib Amir) beroperasi normal dengan interval tiap 10 menit.',
          time: '08:30 AM',
          isUnread: false,
        ),

        const SizedBox(height: AppSpacing.lg),

        // Section: Kemarin
        _buildSectionHeader(context, 'KEMARIN', Icons.history_rounded),
        const SizedBox(height: AppSpacing.sm),
        _buildNotificationCard(
          context: context,
          category: 'STATUS SISTEM',
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.statusPositive,
          title: 'Gelang Pintar Terhubung',
          message:
              'Perangkat gelang pemantau Anda berhasil disinkronkan dengan aplikasi Pendamping Room Maktab 48.',
          time: 'Kemarin, 14:20',
          isUnread: false,
        ),
        _buildNotificationCard(
          context: context,
          category: 'PANDUAN IBADAH',
          icon: Icons.menu_book_rounded,
          iconColor: const Color(0xFF0D7C66),
          title: 'Materi Manasik Tambahan Siap Dibaca',
          message:
              'Doa-doa tawaf dan sa\'i serta tips menjaga stamina selama di Mina telah ditambahkan ke panduan.',
          time: 'Kemarin, 09:15',
          isUnread: false,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondaryColor(context)),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.labelPill.copyWith(
            color: AppColors.textSecondaryColor(context),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String category,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.cardBgColor(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isUnread
              ? AppColors.goldPrimary.withValues(alpha: 0.6)
              : AppColors.cardBorderColor(context),
          width: isUnread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unread Accent Bar
              Container(
                width: 5,
                color: isUnread ? AppColors.goldPrimary : Colors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular Icon Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: iconColor.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Category Badge + Time Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: iconColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    category,
                                    style: AppTypography.captionSmall.copyWith(
                                      color: iconColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 12,
                                      color: AppColors.textSecondaryColor(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      time,
                                      style: AppTypography.captionSmall.copyWith(
                                        color: AppColors.textSecondaryColor(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (isUnread) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppColors.goldPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Title
                            Text(
                              title,
                              style: AppTypography.titleSm.copyWith(
                                color: headingColor,
                                fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Message body (friendly for seniors)
                            Text(
                              message,
                              style: AppTypography.bodySmall.copyWith(
                                color: bodyColor,
                                height: 1.45,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildFaqList(BuildContext context) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      children: [
        // Friendly Elderly-Oriented Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.goldPrimary.withValues(alpha: 0.12),
                AppColors.cardBgColor(context),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.goldDark,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Panduan & Bantuan',
                      style: AppTypography.titleSm.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ketuk salah satu pertanyaan di bawah untuk membaca panduan praktis dan jelas.',
                      style: AppTypography.captionSmall.copyWith(
                        color: bodyColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // FAQ Items
        _buildFaqItem(
          context: context,
          icon: Icons.emergency_rounded,
          question: 'Bagaimana cara menggunakan tombol SOS darurat?',
          answer:
              'Tekan dan tahan tombol SOS berwarna merah di dashboard selama 3 detik. Aplikasi akan mengirimkan sinyal bahaya dan koordinat GPS akurat Anda secara real-time ke smartphone pendamping dan posko maktab.',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.watch_rounded,
          question: 'Apakah gelang pintar tahan terhadap air?',
          answer:
              'Ya, gelang pintar dirancang dengan sertifikasi tahan air aman digunakan saat berwudhu, mandi, maupun terkena keringat. Namun harap tidak dipakai saat berenang atau menyelam dalam air bertekanan tinggi.',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.map_rounded,
          question: 'Bagaimana jika saya terpisah dari rombongan?',
          answer:
              'Jangan panik. Tetap di tempat aman yang mudah terlihat. Buka menu Peta Interaktif untuk melihat jalur menuju posko/tenda, atau tekan tombol Hubungi Pendamping agar pendamping langsung melihat posisi Anda di peta.',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.currency_exchange_rounded,
          question: 'Bagaimana cara mengecek uang Riyal dengan kamera?',
          answer:
              'Pilih menu Deteksi Uang Riyal di dashboard. Arahkan kamera ke lembaran uang kertas SAR Arab Saudi secara mendatar di bawah pencahayaan cukup. Aplikasi akan menyebutkan nominal uang secara otomatis lewat suara.',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.translate_rounded,
          question: 'Cara mengganti bahasa atau memperbesar teks?',
          answer:
              'Buka menu Profil di pojok kanan bawah. Anda dapat mengatur Ukuran Teks (Normal, Besar, Sangat Besar) untuk memudahkan membaca, serta memilih Bahasa (Indonesia, Arab, Inggris).',
        ),

        const SizedBox(height: AppSpacing.xl),

        // Emergency Footer
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_in_talk_rounded, color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Hotline Maktab Indonesia: 800-119-999',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required IconData icon,
    required String question,
    required String answer,
  }) {
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.cardBorderColor(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.goldDark, size: 20),
          ),
          title: Text(
            question,
            style: AppTypography.titleSm.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          iconColor: AppColors.goldPrimary,
          collapsedIconColor: AppColors.textSecondaryColor(context),
          childrenPadding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                answer,
                style: AppTypography.bodySmall.copyWith(
                  color: bodyColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
