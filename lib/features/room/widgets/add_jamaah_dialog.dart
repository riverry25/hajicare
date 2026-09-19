import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../../core/widgets/ribbon_fold_painter.dart';
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
            'Undangan sudah dikirim ke "$email". Jamaah dapat menerima atau menolak undangan tersebut.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      AppDialog.error(
        context: context,
        title: 'Undangan Belum Terkirim',
        message: UserFeedbackMessage.from(
          e,
          fallback:
              'Periksa kembali email jamaah, lalu kirim undangan sekali lagi.',
        ),
        okText: 'Coba Lagi',
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390, maxHeight: 560),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── 1. Main Card Body ──
            Container(
              margin: const EdgeInsets.only(
                top: 28,
                bottom: 12,
                right: 10,
                left: 10,
              ),
              padding: const EdgeInsets.fromLTRB(20, 68, 20, 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.09),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
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
                      Text(
                        'Undang Jamaah',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 17.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Undangan akan dikirimkan langsung ke akun email Jamaah yang terdaftar di HajiCare.',
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor.withValues(alpha: 0.85),
                          height: 1.35,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Underline Input
                      Text(
                        'Email Jamaah',
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isSubmitting,
                        style: TextStyle(
                          color: headingColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'contoh: jamaah@gmail.com',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF9E8E81),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.mail_outline_rounded,
                            size: 17,
                            color: isDark
                                ? AppColors.goldLight.withValues(alpha: 0.7)
                                : AppColors.espressoDark.withValues(alpha: 0.6),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 26,
                            minHeight: 26,
                          ),
                          filled: false,
                          contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : const Color(0xFFD4C7BC),
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkOutlineVariant
                                  : const Color(0xFFD4C7BC),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.goldLight
                                  : AppColors.espressoDark,
                              width: 1.8,
                            ),
                          ),
                          errorBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.sosEmergency,
                              width: 1.4,
                            ),
                          ),
                          focusedErrorBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.sosEmergency,
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
                      const SizedBox(height: 18),

                      // Bottom Row: Cancel button on left, space reserved for protruding button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white60
                                  : const Color(0xFF8C7A6B),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              context.tr('cancel').isEmpty
                                  ? 'Batal'
                                  : context.tr('cancel'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 135),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 2. Floating Hero Card ──
            Positioned(
              top: 0,
              left: 22,
              right: 22,
              height: 86,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF38251A), const Color(0xFF1F140D)]
                        : [AppColors.espressoDark, const Color(0xFF563B2A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.goldPrimary.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espressoDark.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -15,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.goldPrimary.withValues(alpha: 0.25),
                                  AppColors.goldPrimary.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_add_alt_1_rounded,
                                color: AppColors.accentGoldStar,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'UNDANG JAMAAH',
                            style: TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Protruding Ribbon Submit Button (No shadow) ──
            Positioned(
              bottom: 0,
              right: 0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -10,
                    right: 0,
                    child: CustomPaint(
                      size: const Size(10, 10),
                      painter: RibbonFoldPainter(
                        color: isDark
                            ? const Color(0xFF140D08)
                            : const Color(0xFF160D07),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSubmitting ? null : _handleSubmit,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(5),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkPrimaryContainer
                              : AppColors.espressoDark,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(5),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 13.5,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'KIRIM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 2.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
