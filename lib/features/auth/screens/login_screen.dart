import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/locales/app_localizations.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenEdgeGutter,
            AppSpacing.lg,
            AppSpacing.screenEdgeGutter,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============================================================
              // TOP BRAND
              // ============================================================
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.espressoDark,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espressoDark.withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: AppColors.canvasCream,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HajiCare',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.espressoDark,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.tr('appTagline'),
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.tanMedium,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Secure indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.goldLight.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 14,
                          color: AppColors.statusPositive,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Aman',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ============================================================
              // WELCOME / JOURNEY INTRO
              // ============================================================
              Container(
                decoration: BoxDecoration(
                  color: AppColors.espressoDark,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circle
                    Positioned(
                      right: -35,
                      top: -45,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldLight.withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    // Small decorative circle
                    Positioned(
                      right: 35,
                      bottom: -55,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldLight.withValues(alpha: 0.05),
                        ),
                      ),
                    ),

                    Container(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: AppColors.goldLight.withValues(
                                  alpha: 0.20,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: AppColors.accentGoldStar,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Teman Perjalanan Anda',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.canvasCream,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Main heading
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Selamat datang,\n',
                                  style: AppTypography.displayMedium.copyWith(
                                    color: AppColors.canvasCream,
                                    fontWeight: FontWeight.w500,
                                    height: 1.05,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Ahlan wa Sahlan.',
                                  style: AppTypography.displayMedium.copyWith(
                                    color: AppColors.accentGoldStar,
                                    fontWeight: FontWeight.w800,
                                    height: 1.05,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Description
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: Text(
                              'Satu tempat untuk membantu perjalanan ibadah Anda tetap aman, terhubung, dan tenang.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.canvasCream.withValues(
                                  alpha: 0.78,
                                ),
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Mini feature row
                          Row(
                            children: [
                              _WelcomeFeature(
                                icon: Icons.shield_outlined,
                                label: 'Aman',
                              ),
                              const SizedBox(width: 8),
                              _WelcomeFeature(
                                icon: Icons.people_outline_rounded,
                                label: 'Terhubung',
                              ),
                              const SizedBox(width: 8),
                              _WelcomeFeature(
                                icon: Icons.accessibility_new_rounded,
                                label: 'Inklusif',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ============================================================
              // ROLE SECTION
              // ============================================================
              const SizedBox(height: 10),

              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _ModernRoleButton(
                        title: 'Jamaah',
                        subtitle: 'Haji / Umrah',
                        icon: Icons.person_outline_rounded,
                        selected: controller.selectedRole.value == 'jamaah',
                        onTap: () => controller.setRole('jamaah'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: _ModernRoleButton(
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

              const SizedBox(height: 26),

              // ============================================================
              // LOGIN FORM
              // ============================================================
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.055),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form heading
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.canvasCream,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.login_rounded,
                            color: AppColors.espressoDark,
                            size: 19,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Masuk ke akun',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.espressoDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gunakan akun yang sudah terdaftar',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.tanMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ------------------------------------------------------
                    // EMAIL
                    // ------------------------------------------------------
                    Text(
                      'Email',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textHeading,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

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

                    const SizedBox(height: 20),

                    // ------------------------------------------------------
                    // PASSWORD
                    // ------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kata Sandi / PIN',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textHeading,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            // Mekanisme existing tetap bisa
                            // ditambahkan di sini jika controller
                            // memiliki fungsi forgot password.
                          },
                          child: Text(
                            'Lupa kata sandi?',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Obx(
                      () => AppTextField(
                        controller: controller.passwordController,
                        hintText: 'Masukkan PIN / kata sandi',
                        obscureText: controller.obscurePassword.value,
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: AppColors.tanMedium,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          splashRadius: 20,
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

                    // ------------------------------------------------------
                    // REMEMBER ME
                    // ------------------------------------------------------
                    Obx(
                      () => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 42,
                              height: 42,
                              child: Checkbox(
                                value: controller.rememberMe.value,
                                onChanged: (value) =>
                                    controller.setRememberMe(value ?? true),
                                activeColor: AppColors.espressoDark,
                                side: const BorderSide(
                                  color: AppColors.goldLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Ingat saya di perangkat ini',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ------------------------------------------------------
                    // LOGIN BUTTON
                    // ------------------------------------------------------
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        child: PillButton(
                          label: controller.isLoading.value
                              ? 'Memproses...'
                              : (context.tr('btnLogin').isEmpty
                                    ? 'Masuk ke Aplikasi'
                                    : context.tr('btnLogin')),
                          icon: Icons.arrow_forward_rounded,
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.login(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ------------------------------------------------------
                    // DIVIDER
                    // ------------------------------------------------------
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: AppColors.outlineVariant,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.tanMedium,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppColors.outlineVariant,
                            height: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ------------------------------------------------------
                    // WHATSAPP
                    // ------------------------------------------------------
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.canvasCream.withValues(
                            alpha: 0.35,
                          ),
                          side: BorderSide(
                            color: AppColors.goldLight.withValues(alpha: 0.65),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 27,
                              height: 27,
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Masuk Cepat via WhatsApp',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.espressoDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // REGISTER
              // ============================================================
              Center(
                child: GestureDetector(
                  onTap: () {
                    Get.toNamed(AppRoutes.register);
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Belum memiliki akun? ',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textBody,
                      ),
                      children: [
                        TextSpan(
                          text: 'Daftar sekarang',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.espressoDark,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.goldLight,
                            decorationThickness: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ============================================================
              // HELP / TRUST FOOTER
              // ============================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.goldLight.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.canvasCream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.sosEmergency,
                        size: 17,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Butuh bantuan?',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Petugas Maktab siap membantu Anda.',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.tanMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: AppColors.tanMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Security note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.statusPositive,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Data jamaah Anda terlindungi dan aman',
                      textAlign: TextAlign.center,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.tanMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// MODERN ROLE BUTTON
// ==========================================================================

class _ModernRoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModernRoleButton({
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
          padding: const EdgeInsets.all(13),
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
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.surfaceWhite.withValues(alpha: 0.12)
                      : AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? AppColors.canvasCream
                      : AppColors.espressoDark,
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

              const SizedBox(width: 4),

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

class _WelcomeFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WelcomeFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentGoldStar),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.canvasCream.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
