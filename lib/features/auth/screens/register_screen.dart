import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/app_constants.dart';
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Daftar Akun Baru',
          style: AppTypography.headlineMd.copyWith(color: AppColors.espressoDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceMd,
            vertical: AppConstants.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                    _buildLabel('Nama Lengkap (Sesuai Paspor)'),
                    _buildTextField(hint: 'Contoh: Ahmad Dahlan', icon: Icons.person_outline),
                    const SizedBox(height: AppConstants.spaceMd),

                    _buildLabel('Nomor Porsi Haji / NIK'),
                    _buildTextField(hint: '13 digit nomor porsi', icon: Icons.credit_card, isNumber: true),
                    const SizedBox(height: AppConstants.spaceMd),

                    _buildLabel('Nomor WhatsApp Aktif'),
                    _buildPhoneField(),
                    const SizedBox(height: AppConstants.spaceMd),

                    _buildLabel('Buat PIN / Kata Sandi'),
                    _buildPasswordField(),
                    const SizedBox(height: AppConstants.spaceMd),

                    PillButton(
                      label: 'Daftar Sekarang',
                      icon: Icons.person_add,
                      onPressed: () {
                        // Demo logic
                        Navigator.of(context).pop();
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceXs),
      child: Text(text, style: AppTypography.labelPill.copyWith(color: AppColors.espressoDark)),
    );
  }

  Widget _buildTextField({required String hint, required IconData icon, bool isNumber = false}) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusPill),
        border: Border.all(color: AppColors.goldLight, width: 2),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppConstants.spaceSm),
            child: Icon(icon, color: AppColors.tanMedium, size: 20),
          ),
          Expanded(
            child: TextFormField(
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm),
                fillColor: Colors.transparent,
                filled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
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
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: '812 3456 7890',
                hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm),
                fillColor: Colors.transparent,
                filled: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
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
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: 'Min. 6 digit angka/huruf',
                hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.outline),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm),
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
    );
  }
}
