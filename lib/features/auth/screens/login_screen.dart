import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
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
              // TOP BRAND HEADER
              // ============================================================
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.espressoDark,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.goldPrimary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espressoDark.withValues(alpha: 0.16),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icon.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.mosque_rounded,
                              color: AppColors.goldPrimary,
                              size: 24,
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HajiCare',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.textHeadingColor(context),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.tr('appTagline'),
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.tanMedium,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Security status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBgColor(context),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          size: 15,
                          color: AppColors.statusPositive,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Aman & Resmi',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.statusPositive,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ============================================================
              // WELCOME / JOURNEY INTRO BANNER
              // ============================================================
              Container(
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
                      color: AppColors.espressoDark.withValues(alpha: 0.20),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative ambient circles
                    Positioned(
                      right: -30,
                      top: -40,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      bottom: -50,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.05),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Luxury badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 14,
                                  color: AppColors.goldPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Teman Perjalanan Jamaah',
                                  style: AppTypography.captionSmall.copyWith(
                                    color: AppColors.canvasCream,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
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
                                    height: 1.1,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Ahlan wa Sahlan.',
                                  style: AppTypography.displayMedium.copyWith(
                                    color: AppColors.goldPrimary,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Description
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Text(
                              'Satu tempat untuk mendampingi perjalanan ibadah Anda tetap aman, terhubung, dan khusyuk.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.canvasCream.withValues(
                                  alpha: 0.85,
                                ),
                                height: 1.45,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Mini feature tags
                          Row(
                            children: const [
                              _WelcomeFeature(
                                icon: Icons.shield_outlined,
                                label: 'Aman',
                              ),
                              SizedBox(width: 8),
                              _WelcomeFeature(
                                icon: Icons.people_outline_rounded,
                                label: 'Terhubung',
                              ),
                              SizedBox(width: 8),
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

              const SizedBox(height: 24),

              // ============================================================
              // LOGIN FORM CARD
              // ============================================================
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.cardBgColor(context),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.cardBorderColor(context)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
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
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.canvasCream,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.login_rounded,
                            color: AppColors.espressoDark,
                            size: 21,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Masuk ke Akun',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.textHeadingColor(context),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gunakan email yang sudah terdaftar',
                              style: AppTypography.captionSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // EMAIL FIELD
                    Text(
                      'Email',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textHeadingColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),

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

                    const SizedBox(height: 18),

                    // PASSWORD FIELD
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kata Sandi / PIN',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textHeadingColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            // Forgot password hook
                          },
                          child: Text(
                            'Lupa kata sandi?',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

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

                    const SizedBox(height: 6),

                    // REMEMBER ME
                    Obx(
                      () => Row(
                        children: [
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: Checkbox(
                              value: controller.rememberMe.value,
                              onChanged: (value) =>
                                  controller.setRememberMe(value ?? true),
                              activeColor: AppColors.espressoDark,
                              side: const BorderSide(
                                color: AppColors.goldLight,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => controller.setRememberMe(
                              !controller.rememberMe.value,
                            ),
                            child: Text(
                              'Ingat saya di perangkat ini',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textBodyColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // LOGIN BUTTON
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: PillButton(
                          label: controller.isLoading.value
                              ? 'Memproses Masuk...'
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

                    // DIVIDER
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppColors.cardBorderColor(context),
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'atau',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.tanMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppColors.cardBorderColor(context),
                            height: 1,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // GOOGLE SIGN-IN
                    Obx(
                      () => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () => controller.loginWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.canvasCream.withValues(
                              alpha: 0.35,
                            ),
                            side: BorderSide(
                              color: AppColors.cardBorderColor(context),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                          child: controller.isGoogleLoading.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.goldPrimary,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _GoogleLogo(size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Masuk dengan Google',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.espressoDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ============================================================
              // REGISTER REDIRECTION LINK
              // ============================================================
              Center(
                child: GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.register),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Belum memiliki akun? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textBodyColor(context),
                        ),
                        children: [
                          TextSpan(
                            text: 'Daftar sekarang',
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

              const SizedBox(height: 16),

              // ============================================================
              // HELP / SUPPORT BANNER
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
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.canvasCream,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.sosEmergency,
                        size: 19,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Butuh bantuan masuk?',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textHeadingColor(context),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Petugas Maktab & Pos Kesehatan siap memandu.',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.tanMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Security footer note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.statusPositive,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Kerahasiaan data jamaah terenkripsi dan terlindungi',
                      textAlign: TextAlign.center,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.tanMedium,
                        fontWeight: FontWeight.w500,
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

class _WelcomeFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _WelcomeFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.goldPrimary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.canvasCream,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    // Red (top segment)
    final redPath = Path()
      ..moveTo(12.0, 5.0)
      ..cubicTo(13.85, 5.0, 15.35, 5.68, 16.48, 6.64)
      ..lineTo(20.0, 3.12)
      ..cubicTo(17.85, 1.15, 15.15, 0.0, 12.0, 0.0)
      ..cubicTo(7.45, 0.0, 3.5, 2.65, 1.5, 6.5)
      ..lineTo(5.62, 9.68)
      ..cubicTo(6.62, 6.95, 9.1, 5.0, 12.0, 5.0)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));

    // Blue (right segment & crossbar)
    final bluePath = Path()
      ..moveTo(23.6, 12.25)
      ..cubicTo(23.6, 11.45, 23.5, 10.65, 23.35, 9.9)
      ..lineTo(12.0, 9.9)
      ..lineTo(12.0, 14.5)
      ..lineTo(18.5, 14.5)
      ..cubicTo(18.2, 16.0, 17.3, 17.25, 16.0, 18.1)
      ..lineTo(19.9, 21.1)
      ..cubicTo(22.2, 19.0, 23.6, 15.9, 23.6, 12.25)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));

    // Yellow (left segment)
    final yellowPath = Path()
      ..moveTo(1.5, 6.5)
      ..cubicTo(0.55, 8.4, 0.0, 10.5, 0.0, 12.0)
      ..cubicTo(0.0, 13.5, 0.55, 15.6, 1.5, 17.5)
      ..lineTo(5.62, 14.32)
      ..cubicTo(5.35, 13.55, 5.2, 12.8, 5.2, 12.0)
      ..cubicTo(5.2, 11.2, 5.35, 10.45, 5.62, 9.68)
      ..lineTo(1.5, 6.5)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // Green (bottom segment)
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.2, 24.0, 17.9, 22.95, 19.9, 21.1)
      ..lineTo(16.0, 18.1)
      ..cubicTo(14.95, 18.8, 13.6, 19.2, 12.0, 19.2)
      ..cubicTo(9.1, 19.2, 6.62, 17.25, 5.62, 14.52)
      ..lineTo(1.5, 17.5)
      ..cubicTo(3.5, 21.35, 7.45, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
