import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_role_card.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RegisterController>();

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
              // Role selection
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: AuthRoleCard(
                        roleId: 'jamaah',
                        title: 'Jamaah',
                        description: 'Saya melaksanakan ibadah Haji/Umrah',
                        icon: Icons.person,
                        isSelected: controller.selectedRole.value == 'jamaah',
                        onTap: () => controller.setRole('jamaah'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AuthRoleCard(
                        roleId: 'pendamping',
                        title: 'Pendamping',
                        description: 'Keluarga atau muthawif yang memantau',
                        icon: Icons.health_and_safety,
                        isSelected: controller.selectedRole.value == 'pendamping',
                        onTap: () => controller.setRole('pendamping'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: controller.fullNameController,
                      label: 'Nama Lengkap (Sesuai Paspor)',
                      hintText: 'Contoh: Ahmad Dahlan',
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: controller.porsiController,
                      label: 'Nomor Porsi Haji / NIK (Opsional)',
                      hintText: '13 digit nomor porsi',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(
                        Icons.credit_card,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      controller: controller.emailController,
                      label: 'Email Aktif',
                      hintText: 'email@contoh.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppColors.tanMedium,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Obx(
                      () => AppTextField(
                        controller: controller.passwordController,
                        label: 'Buat PIN / Kata Sandi',
                        hintText: 'Min. 6 digit angka/huruf',
                        obscureText: controller.obscurePassword.value,
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppColors.tanMedium,
                          size: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.textBody,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Obx(
                      () => PillButton(
                        label: controller.isLoading.value
                            ? 'Mendaftarkan...'
                            : 'Daftar Sekarang',
                        icon: Icons.person_add,
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.register(),
                      ),
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

