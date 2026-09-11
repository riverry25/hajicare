import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../widgets/auth_role_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedRole = 'jamaah';
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdgeGutter,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Logo & Branding
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldLight, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espressoDark.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.mosque,
                            color: AppColors.goldLight,
                            size: 32,
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.accentGoldStar,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'HajiCare',
                    style: AppTypography.displayLarge.copyWith(
                      color: AppColors.espressoDark,
                    ),
                  ),
                  Text(
                    'Pendamping Keselamatan & Aksesibilitas',
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.tanMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Hero Greeting
              AppCard(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(
                          alpha: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.spa,
                            color: AppColors.secondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Panduan Suci & Aman',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Ahlan wa Sahlan',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.espressoDark,
                      ),
                    ),
                    Text(
                      'Masuk ke Akun Anda',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Silakan masuk untuk terhubung dengan keluarga dan pendamping ibadah di Tanah Suci.',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Role Selector Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Peran Anda',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.espressoDark,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.touch_app,
                        size: 12,
                        color: AppColors.tanMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ketuk salah satu',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.tanMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AuthRoleCard(
                      roleId: 'jamaah',
                      title: 'Jamaah',
                      description:
                          'Saya Jamaah Haji/Umrah yang membutuhkan navigasi dan pendampingan',
                      icon: Icons.person,
                      isSelected: _selectedRole == 'jamaah',
                      onTap: () => setState(() => _selectedRole = 'jamaah'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AuthRoleCard(
                      roleId: 'pendamping',
                      title: 'Pendamping',
                      description:
                          'Keluarga atau muthawif yang memantau keselamatan jamaah',
                      icon: Icons.health_and_safety,
                      isSelected: _selectedRole == 'pendamping',
                      onTap: () => setState(() => _selectedRole = 'pendamping'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Form
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppTextField(
                      label: 'Nomor WhatsApp atau Email',
                      hintText: '812 3456 7890',
                      isPhone: true,
                      phonePrefix: '+62',
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.statusPositive,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Gunakan nomor WhatsApp aktif untuk menerima kode verifikasi cepat',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kata Sandi / PIN Keamanan',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.espressoDark,
                          ),
                        ),
                        Text(
                          'Lupa Kata Sandi?',
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.secondary,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.goldLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      hintText: 'Masukkan PIN / Kata Sandi',
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.textBody,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? true;
                            });
                          },
                          activeColor: AppColors.statusPositive,
                          side: const BorderSide(color: AppColors.goldLight),
                        ),
                        Text(
                          'Ingat Saya di Perangkat Ini',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textHeading,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    PillButton(
                      label: 'Masuk ke Aplikasi',
                      icon: Icons.login,
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(
                          _selectedRole == 'jamaah'
                              ? '/dashboard_jamaah'
                              : '/dashboard_pendamping',
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Divider(color: AppColors.outlineVariant),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              'atau gunakan kemudahan',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textBody,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: AppColors.outlineVariant),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.goldLight,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'Masuk Cepat via WhatsApp',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.espressoDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Footer
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed('/register');
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'Belum memiliki akun? ',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textBody,
                          ),
                          children: [
                            TextSpan(
                              text: 'Daftar Akun Baru',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.espressoDark,
                                decoration: TextDecoration.underline,
                                decorationColor: AppColors.goldLight,
                                decorationThickness: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvasCreamSubtle,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.contact_support,
                            color: AppColors.sosEmergency,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Butuh Bantuan Petugas Maktab?',
                            style: AppTypography.captionSmall.copyWith(
                              color: AppColors.espressoDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: AppColors.statusPositive,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Privasi Data Jamaah Terlindungi & Aman',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.tanMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
