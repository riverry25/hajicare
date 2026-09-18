import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../services/room_service.dart';

/// Modern centered modal dialog for Pendamping to add a Jamaah by registered email.
class AddJamaahDialog extends StatefulWidget {
  final String roomId;

  const AddJamaahDialog({super.key, required this.roomId});

  /// Shows the centered modern dialog.
  static Future<void> show(BuildContext context, String roomId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddJamaahDialog(roomId: roomId),
    );
  }

  @override
  State<AddJamaahDialog> createState() => _AddJamaahDialogState();
}

class _AddJamaahDialogState extends State<AddJamaahDialog> {
  final RoomService _roomService = RoomService();
  final TextEditingController _emailCtrl = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? '';
    final currentName = (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : 'Pendamping';
    final email = _emailCtrl.text.trim();

    setState(() => _isSubmitting = true);

    try {
      await _roomService.inviteJamaahByEmail(
        roomId: widget.roomId,
        email: email,
        currentPendampingUid: currentUid,
        currentPendampingName: currentName,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close modal dialog

      AppAlert.success(
        context,
        title: 'Undangan Terkirim',
        message: 'Undangan telah berhasil dikirim ke "$email". Jamaah akan menerima notifikasi untuk menerima atau menolak.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      AppAlert.error(
        context,
        title: 'Gagal Mengirim Undangan',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.goldLight.withValues(alpha: 0.3),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Icon + Title
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Undang Jamaah',
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Kirim undangan ke email jamaah',
                            style: AppTypography.captionSmall.copyWith(
                              color: bodyColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isSubmitting)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: bodyColor,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Informative Hint Text
                Text(
                  'Undangan akan dikirimkan ke akun Jamaah. Jamaah harus sudah memiliki akun di HajiCare dan dapat menerima atau menolak undangan ini.',
                  style: AppTypography.bodySmall.copyWith(
                    color: bodyColor,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Email Input
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Email Jamaah',
                    hintText: 'contoh: ahmad@hajicare.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.darkOutlineVariant : AppColors.goldLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkOutlineVariant
                            : AppColors.goldLight.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email jamaah wajib diisi';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Masukkan format email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          side: BorderSide(
                            color: isDark ? AppColors.darkOutlineVariant : AppColors.goldLight,
                          ),
                        ),
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                        child: Text(
                          context.tr('cancel').isEmpty ? 'Batal' : context.tr('cancel'),
                          style: TextStyle(
                            color: isDark ? Colors.white70 : AppColors.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Kirim Undangan',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
