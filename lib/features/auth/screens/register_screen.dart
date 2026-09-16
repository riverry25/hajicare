import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../controllers/register_controller.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdgeGutter,
            AppSpacing.md,
            AppSpacing.screenEdgeGutter,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================================
              // TOP APP BAR
              // ============================================================
              Row(
                children: [
                  _BackButton(onTap: () => Get.back()),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Akun HajiCare',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.textHeadingColor(context),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Lengkapi data untuk memulai perjalanan Anda',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.tanMedium,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Verified badge
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.cardBgColor(context),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColors.cardBorderColor(context),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espressoDark.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.statusPositive,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // INTRO BANNER
              // ============================================================
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.espressoDark, Color(0xFF22160E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.16),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.goldPrimary,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teman Perjalanan Ibadah Anda',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.canvasCream,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Daftar sekali untuk mendapatkan pengalaman HajiCare yang aman, terpantau, dan inklusif.',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.canvasCream.withValues(
                                alpha: 0.85,
                              ),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ============================================================
              // ROLE SELECTION SECTION
              // ============================================================
              _SectionHeader(
                icon: Icons.people_outline_rounded,
                title: 'Saya mendaftar sebagai',
                subtitle: 'Pilih peran yang paling sesuai dengan Anda',
              ),

              const SizedBox(height: AppSpacing.md),

              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _RegisterRoleCard(
                        title: 'Jamaah',
                        subtitle: 'Haji & Umrah',
                        icon: Icons.person_outline_rounded,
                        selected: controller.selectedRole.value == 'jamaah',
                        onTap: () => controller.setRole('jamaah'),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    Expanded(
                      child: _RegisterRoleCard(
                        title: 'Pendamping',
                        subtitle: 'Keluarga / Muthawif',
                        icon: Icons.health_and_safety_outlined,
                        selected: controller.selectedRole.value == 'pendamping',
                        onTap: () => controller.setRole('pendamping'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ============================================================
              // IDENTITY FORM SECTION
              // ============================================================
              _SectionHeader(
                icon: Icons.badge_outlined,
                title: 'Data Diri',
                subtitle: 'Gunakan data sesuai identitas resmi Anda',
              ),

              const SizedBox(height: AppSpacing.md),

              _FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Nama Lengkap', required: true),

                    const SizedBox(height: 8),

                    AppTextField(
                      controller: controller.fullNameController,
                      hintText: 'Contoh: Ahmad Dahlan',
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: _FieldLabel(
                            label: 'Nomor Porsi Haji / NIK',
                            required: false,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.canvasCream,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Text(
                            'Opsional',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.tanMedium,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    AppTextField(
                      controller: controller.porsiController,
                      hintText: 'Masukkan nomor porsi atau NIK',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(
                        Icons.credit_card_outlined,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: AppColors.tanMedium,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Data ini membantu HajiCare mengaitkan rombongan dan maktab secara akurat.',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ============================================================
              // ACCOUNT FORM SECTION
              // ============================================================
              _SectionHeader(
                icon: Icons.lock_outline_rounded,
                title: 'Informasi Akun',
                subtitle: 'Gunakan email aktif dan kata sandi yang aman',
              ),

              const SizedBox(height: AppSpacing.md),

              _FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Email Aktif', required: true),

                    const SizedBox(height: 8),

                    AppTextField(
                      controller: controller.emailController,
                      hintText: 'nama@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const _FieldLabel(label: 'Kata Sandi', required: true),

                    const SizedBox(height: 8),

                    Obx(
                      () => AppTextField(
                        controller: controller.passwordController,
                        hintText: 'Minimal 6 karakter',
                        obscureText: controller.obscurePassword.value,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.tanMedium,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          tooltip: controller.obscurePassword.value
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textBody,
                            size: 20,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 15,
                          color: AppColors.statusPositive,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Gunakan kombinasi minimal 6 karakter agar akun tetap aman.',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ============================================================
              // REGISTER BUTTON
              // ============================================================
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: PillButton(
                    label: controller.isLoading.value
                        ? 'Mendaftarkan Akun...'
                        : 'Buat Akun Sekarang',
                    icon: controller.isLoading.value
                        ? null
                        : Icons.arrow_forward_rounded,
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.register,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ============================================================
              // SECURITY PRIVACY NOTE
              // ============================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBgColor(context).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.cardBorderColor(context)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.statusPositive,
                      size: 18,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Informasi pribadi Anda terenkripsi dan hanya digunakan untuk kebutuhan navigasi & keselamatan ibadah.',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // LOGIN REDIRECTION LINK
              // ============================================================
              Center(
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Sudah memiliki akun? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textBodyColor(context),
                        ),
                        children: [
                          TextSpan(
                            text: 'Masuk sekarang',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.goldPrimary,
                              decorationThickness: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Bottom Brandmark
              Center(
                child: Text(
                  'HajiCare • Aman • Terhubung • Khusyuk',
                  textAlign: TextAlign.center,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.tanMedium.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BACK BUTTON
// ============================================================================

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.cardBgColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: AppColors.espressoDark.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.espressoDark,
            size: 21,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.cardBgColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorderColor(context)),
          ),
          child: Icon(icon, color: AppColors.espressoDark, size: 20),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textHeadingColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// FORM CARD
// ============================================================================

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor(context),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.cardBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ============================================================================
// FIELD LABEL
// ============================================================================

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, required this.required});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textHeadingColor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.sosEmergency,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// REGISTER ROLE CARD
// ============================================================================

class _RegisterRoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RegisterRoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.espressoDark
                : AppColors.cardBgColor(context),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: selected
                  ? AppColors.goldPrimary
                  : AppColors.cardBorderColor(context),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.surfaceWhite.withValues(alpha: 0.12)
                      : AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(13),
                  border: selected
                      ? Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.35),
                        )
                      : null,
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.goldPrimary
                      : AppColors.espressoDark,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium.copyWith(
                        color: selected
                            ? AppColors.surfaceWhite
                            : AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(
                        color: selected
                            ? AppColors.canvasCream.withValues(alpha: 0.78)
                            : AppColors.tanMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.goldPrimary : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.goldPrimary
                        : AppColors.cardBorderColor(context),
                    width: 1.8,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.espressoDark,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
