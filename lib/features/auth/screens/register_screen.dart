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
      backgroundColor: AppColors.canvasCream,
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
              // HEADER
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
                          'Buat akun HajiCare',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.espressoDark,
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

                  // Secure indicator
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.statusPositive,
                      size: 19,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ============================================================
              // INTRO
              // ============================================================
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.espressoDark,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.14),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accentGoldStar,
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teman perjalanan ibadah Anda',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.canvasCream,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Daftar sekali untuk mendapatkan pengalaman HajiCare yang lebih personal, aman, dan inklusif.',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.canvasCream.withValues(
                                alpha: 0.72,
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
              // ROLE SECTION
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
                        subtitle: 'Haji / Umrah',
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
              // IDENTITY FORM
              // ============================================================
              _SectionHeader(
                icon: Icons.badge_outlined,
                title: 'Data diri',
                subtitle: 'Gunakan data sesuai identitas Anda',
              ),

              const SizedBox(height: AppSpacing.md),

              _FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Nama Lengkap', required: true),

                    const SizedBox(height: 7),

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
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.canvasCream,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Opsional',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.tanMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    AppTextField(
                      controller: controller.porsiController,
                      hintText: 'Masukkan nomor porsi / NIK',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(
                        Icons.credit_card_outlined,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: 9),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.tanMedium,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Data ini membantu HajiCare memberikan layanan yang lebih sesuai.',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.tanMedium,
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
              // ACCOUNT FORM
              // ============================================================
              _SectionHeader(
                icon: Icons.lock_outline_rounded,
                title: 'Informasi akun',
                subtitle: 'Gunakan email dan kata sandi yang aktif',
              ),

              const SizedBox(height: AppSpacing.md),

              _FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(label: 'Email Aktif', required: true),

                    const SizedBox(height: 7),

                    AppTextField(
                      controller: controller.emailController,
                      hintText: 'email@contoh.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    _FieldLabel(label: 'Kata Sandi', required: true),

                    const SizedBox(height: 7),

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

                    const SizedBox(height: 9),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 14,
                          color: AppColors.statusPositive,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Gunakan minimal 6 karakter agar akun tetap aman.',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.tanMedium,
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
                () => PillButton(
                  label: controller.isLoading.value
                      ? 'Mendaftarkan akun...'
                      : 'Buat Akun',
                  icon: controller.isLoading.value
                      ? null
                      : Icons.arrow_forward_rounded,
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.register,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ============================================================
              // SECURITY NOTE
              // ============================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.statusPositive,
                      size: 17,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Informasi pribadi Anda digunakan untuk kebutuhan layanan HajiCare dan dijaga dengan aman.',
                        textAlign: TextAlign.center,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.tanMedium,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ============================================================
              // LOGIN LINK
              // ============================================================
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Sudah memiliki akun? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Masuk sekarang',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.espressoDark,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.goldLight,
                          decorationThickness: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Bottom breathing room
              Center(
                child: Text(
                  'HajiCare • Aman • Terhubung • Inklusif',
                  textAlign: TextAlign.center,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.tanMedium.withValues(alpha: 0.75),
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
        borderRadius: BorderRadius.circular(13),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.goldLight.withValues(alpha: 0.22),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.espressoDark,
            size: 20,
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: AppColors.goldLight.withValues(alpha: 0.20),
            ),
          ),
          child: Icon(icon, color: AppColors.espressoDark, size: 18),
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
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.espressoDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.tanMedium,
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
      padding: const EdgeInsets.fromLTRB(18, 19, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.055),
            blurRadius: 24,
            offset: const Offset(0, 9),
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
              color: AppColors.textHeading,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.sosEmergency,
              fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.espressoDark : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? AppColors.espressoDark
                  : AppColors.goldLight.withValues(alpha: 0.28),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.14),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? AppColors.canvasCream
                      : AppColors.espressoDark,
                  size: 20,
                ),
              ),

              const SizedBox(width: 9),

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
                            : AppColors.espressoDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionSmall.copyWith(
                        color: selected
                            ? AppColors.canvasCream.withValues(alpha: 0.72)
                            : AppColors.tanMedium,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? AppColors.accentGoldStar
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.accentGoldStar
                        : AppColors.goldLight,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white,
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
