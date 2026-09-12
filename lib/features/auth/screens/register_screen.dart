import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../widgets/auth_role_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _porsiCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'jamaah';

  Future<void> _register() async {
    debugPrint('[Register] Starting register process...');

    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua kolom wajib (Nama, Email, Password)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      debugPrint('[Register] Calling createUserWithEmailAndPassword...');
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      debugPrint('[Register] Auth success! UID: ${cred.user?.uid}');

      if (cred.user != null) {
        debugPrint('[Register] Writing user data to Firestore...');
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'name': _nameCtrl.text.trim(),
          'porsi': _porsiCtrl.text.trim(),
          'role': _selectedRole,
          'distance': 0.0,
          'sosActive': false,
          'separatedMode': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[Register] Firestore write success!');

        if (mounted) {
          debugPrint('[Register] Navigating to Dashboard (role: $_selectedRole)...');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi Berhasil!')),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            _selectedRole == 'jamaah'
                ? AppRoutes.dashboardJamaah
                : AppRoutes.dashboardPendamping,
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('[Register] FirebaseAuthException: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Auth: ${e.message ?? e.code}')),
        );
      }
    } catch (e) {
      debugPrint('[Register] General Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('[Register] Process finished.');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _porsiCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasCream,
      appBar: AppBar(
        backgroundColor: AppColors.canvasCream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.espressoDark),
          onPressed: () => Navigator.pop(context),
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
              Row(
                children: [
                  Expanded(
                    child: AuthRoleCard(
                      roleId: 'jamaah',
                      title: 'Jamaah',
                      description: 'Saya melaksanakan ibadah Haji/Umrah',
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
                      description: 'Keluarga atau muthawif yang memantau',
                      icon: Icons.health_and_safety,
                      isSelected: _selectedRole == 'pendamping',
                      onTap: () => setState(() => _selectedRole = 'pendamping'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _nameCtrl,
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
                      controller: _porsiCtrl,
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
                      controller: _emailCtrl,
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

                    AppTextField(
                      controller: _passwordCtrl,
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

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : PillButton(
                            label: 'Daftar Sekarang',
                            icon: Icons.person_add,
                            onPressed: _register,
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

