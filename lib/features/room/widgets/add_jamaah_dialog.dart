import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
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
    final currentName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
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

      AppDialog.success(
        title: 'Undangan Terkirim',
        message:
            'Undangan telah berhasil dikirim ke "$email". Jamaah akan menerima notifikasi untuk menerima atau menolak.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      AppDialog.error(
        context: context,
        title: 'Gagal Mengirim Undangan',
        message: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── Main Card Body (Below floating hero) ─────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 36),
              padding: const EdgeInsets.fromLTRB(22, 102, 22, 22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.09),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        'Undang Jamaah',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      Text(
                        'Undangan akan dikirimkan ke akun Jamaah. Jamaah harus sudah memiliki akun di HajiCare dan dapat menerima atau menolak undangan ini.',
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.85),
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Email Input Field
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofocus: false,
                        enabled: !_isSubmitting,
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Email Jamaah',
                          labelStyle: TextStyle(
                            color: bodyColor.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                          hintText: 'contoh: jamaah@hajicare.com',
                          hintStyle: TextStyle(
                            color: bodyColor.withValues(alpha: 0.4),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            color: primaryColor,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.darkSurfaceContainer
                              : AppColors.canvasCream.withValues(alpha: 0.45),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : AppColors.goldLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : AppColors.goldLight.withValues(alpha: 0.6),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 1.8,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Colors.redAccent,
                              width: 1.8,
                            ),
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
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          // Batal
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkOutlineVariant
                                      : AppColors.goldLight.withValues(
                                          alpha: 0.8,
                                        ),
                                ),
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: Text(
                                context.tr('cancel').isEmpty
                                    ? 'Batal'
                                    : context.tr('cancel'),
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textBody,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Kirim Undangan
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                minimumSize: const Size(0, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
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

            // ── Floating Hero Card (Protruding at top, like Image 2) ────────
            Positioned(
              top: 0,
              left: 18,
              right: 18,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF38251A), const Color(0xFF1F140D)]
                        : [AppColors.espressoDark, const Color(0xFF563B2A)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Ambient Background Circular Glows
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -25,
                      left: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    // Center Hero Graphic
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.22,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.6,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppColors.goldAccent,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.3,
                                ),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'UNDANG JAMAAH',
                              style: TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top-right Close Button
                    if (!_isSubmitting)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
