import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pill_button.dart';

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
            horizontal: AppConstants.spaceMd,
            vertical: AppConstants.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                          color: AppColors.espressoDark.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.mosque, color: AppColors.goldLight, size: 32),
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
                            child: const Icon(Icons.verified_user, color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.spaceSm),
                  Text(
                    'HajiCare',
                    style: AppTypography.displayHero.copyWith(color: AppColors.espressoDark),
                  ),
                  Text(
                    'Pendamping Keselamatan & Aksesibilitas',
                    style: AppTypography.captionBold.copyWith(color: AppColors.tanMedium),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceLg),

              // Hero Greeting
              Container(
                padding: const EdgeInsets.all(AppConstants.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: AppColors.canvasCreamSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.spa, color: AppColors.secondary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Panduan Suci & Aman',
                            style: AppTypography.captionBold.copyWith(color: AppColors.secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceXs),
                    Text(
                      'Ahlan wa Sahlan',
                      style: AppTypography.headlineLg.copyWith(color: AppColors.espressoDark),
                    ),
                    Text(
                      'Masuk ke Akun Anda',
                      style: AppTypography.titleSm.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Silakan masuk untuk terhubung dengan keluarga dan pendamping ibadah di Tanah Suci.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(color: AppColors.textBody),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),

              // Role Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pilih Peran Anda', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                  Row(
                    children: [
                      const Icon(Icons.touch_app, size: 12, color: AppColors.tanMedium),
                      const SizedBox(width: 4),
                      Text('Ketuk salah satu', style: AppTypography.caption.copyWith(color: AppColors.tanMedium)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spaceXs),
              Row(
                children: [
                  Expanded(child: _buildRoleCard('jamaah', 'Jamaah', 'Saya Jamaah Haji/Umrah yang membutuhkan navigasi', Icons.person)),
                  const SizedBox(width: AppConstants.spaceSm),
                  Expanded(child: _buildRoleCard('pendamping', 'Pendamping', 'Keluarga atau muthawif yang memantau keselamatan jamaah', Icons.shield)),
                ],
              ),
              const SizedBox(height: AppConstants.spaceMd),

              // Form
              Container(
                padding: const EdgeInsets.all(AppConstants.spaceMd),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  border: Border.all(color: AppColors.canvasCreamSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nomor WhatsApp atau Email', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                    const SizedBox(height: AppConstants.spaceXs),
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                        border: Border.all(color: AppColors.goldLight, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm),
                            decoration: BoxDecoration(
                              color: AppColors.canvasCreamSubtle.withOpacity(0.7),
                              border: Border.all(color: AppColors.goldLight, width: 1),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppConstants.radiusPill)),
                            ),
                            child: Row(
                              children: [
                                Text('🇮🇩 +62', style: AppTypography.titleSm.copyWith(fontWeight: FontWeight.bold)),
                                const Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: '812 3456 7890',
                                contentPadding: EdgeInsets.symmetric(horizontal: AppConstants.spaceSm),
                                fillColor: Colors.transparent,
                                filled: true,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(right: AppConstants.spaceSm),
                            child: Icon(Icons.chat, color: AppColors.tanMedium, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.statusPositive, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Gunakan nomor WhatsApp aktif untuk menerima kode verifikasi cepat',
                            style: AppTypography.caption.copyWith(color: AppColors.textBody),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceMd),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kata Sandi / PIN Keamanan', style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
                        Text('Lupa Kata Sandi?', style: AppTypography.captionBold.copyWith(color: AppColors.secondary, decoration: TextDecoration.underline, decorationColor: AppColors.goldLight)),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spaceXs),
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                        border: Border.all(color: AppColors.goldLight, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: AppConstants.spaceSm),
                            child: Icon(Icons.lock, color: AppColors.tanMedium, size: 20),
                          ),
                          Expanded(
                            child: TextFormField(
                              obscureText: _obscurePassword,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: 'Masukkan PIN / Kata Sandi',
                                contentPadding: EdgeInsets.symmetric(horizontal: AppConstants.spaceSm),
                                fillColor: Colors.transparent,
                                filled: true,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: AppColors.textBody,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ],
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
                        Text('Ingat Saya di Perangkat Ini', style: AppTypography.bodyMd.copyWith(color: AppColors.textHeading)),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spaceXs),
                    PillButton(
                      label: 'Masuk ke Aplikasi',
                      icon: Icons.login,
                      onPressed: () {
                        // Demo navigation
                        Navigator.of(context).pushReplacementNamed(
                          _selectedRole == 'jamaah' ? '/dashboard_jamaah' : '/dashboard_pendamping'
                        );
                      },
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceSm),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.outlineVariant)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm),
                            child: Text('atau gunakan kemudahan', style: AppTypography.caption.copyWith(color: AppColors.textBody)),
                          ),
                          const Expanded(child: Divider(color: AppColors.outlineVariant)),
                        ],
                      ),
                    ),

                    PillButton(
                      label: 'Masuk Cepat via WhatsApp',
                      onPressed: () {},
                      isOutline: true,
                      color: AppColors.goldLight,
                      textColor: AppColors.espressoDark,
                      icon: Icons.chat, // Assume WhatsApp icon or standard chat
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),
              
              // Footer
              Center(
                child: Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Belum memiliki akun? ',
                        style: AppTypography.bodyMd.copyWith(color: AppColors.textBody),
                        children: [
                          TextSpan(
                            text: 'Daftar Akun Baru',
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.espressoDark,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.goldLight,
                              decorationThickness: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceSm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.canvasCreamSubtle,
                        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.contact_support, color: AppColors.sosEmergency, size: 16),
                          const SizedBox(width: 6),
                          Text('Butuh Bantuan Petugas Maktab?', style: AppTypography.captionBold.copyWith(color: AppColors.espressoDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.spaceSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, color: AppColors.statusPositive, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Privasi Data Jamaah Terlindungi & Aman Sesuai Regulasi Kemenag & MoH KSA',
                            style: AppTypography.caption.copyWith(color: AppColors.tanMedium),
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

  Widget _buildRoleCard(String roleId, String title, String desc, IconData icon) {
    bool isSelected = _selectedRole == roleId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleId;
        });
      },
      child: Container(
        height: 156,
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.espressoDark : AppColors.outlineVariant.withOpacity(0.6),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ]
              : [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondaryContainer : AppColors.canvasCream,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.espressoDark),
                ),
                const SizedBox(height: AppConstants.spaceXs),
                Text(title, style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark)),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    desc,
                    style: AppTypography.caption.copyWith(color: AppColors.textBody),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
