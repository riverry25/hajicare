import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.canvasCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espressoDark),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Daftar Akun Baru',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.espressoDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenEdgeGutter,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppTextField(
                      label: 'Nama Lengkap (Sesuai Paspor)',
                      hintText: 'Contoh: Ahmad Dahlan',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const AppTextField(
                      label: 'Nomor Porsi Haji / NIK',
                      hintText: '13 digit nomor porsi',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icon(
                        Icons.credit_card,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const AppTextField(
                      label: 'Nomor WhatsApp Aktif',
                      hintText: '812 3456 7890',
                      isPhone: true,
                      phonePrefix: '+62',
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Buat PIN / Kata Sandi',
                      hintText: 'Min. 6 digit angka/huruf',
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
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
                    const SizedBox(height: AppSpacing.xl),

                    PillButton(
                      label: 'Daftar Sekarang',
                      icon: Icons.person_add,
                      onPressed: () {
                        Get.back();
                      },
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
