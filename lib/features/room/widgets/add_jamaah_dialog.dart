import '../../../core/locales/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../../core/widgets/haji_dialog_hero_header.dart';
import '../../../core/widgets/haji_dialog_ribbon_button.dart';
import '../../../core/widgets/haji_transparent_dialog.dart';
import '../services/room_service.dart';

/// Modern centered modal dialog for Pendamping to add a Jamaah by registered email.
class AddJamaahDialog extends StatefulWidget {
  final String roomId;

  const AddJamaahDialog({super.key, required this.roomId});

  /// Shows the centered modern dialog.
  static Future<void> show(BuildContext context, String roomId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
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
        title: context.tr('room.invitationSent'),
        message:
            'Undangan sudah dikirim ke "$email". Jamaah dapat menerima atau menolak undangan tersebut.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      AppDialog.error(
        context: context,
        title: context.tr('room.invitationFailed'),
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
    final isDark = context.hc.isDark;
    final cardBg = context.hc.surface;
    final headingColor = context.hc.textPrimary;
    final bodyColor = context.hc.textSecondary;

    return PopScope(
      canPop: !_isSubmitting,
      child: HajiTransparentDialog(
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
                  border: Border.all(color: context.hc.borderSubtle, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.45 : 0.09,
                      ),
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
                          style: context.text.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 17.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Undangan akan dikirimkan langsung ke akun email Jamaah yang terdaftar di HajiCare.',
                          style: context.text.bodySmall.copyWith(
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
                            hintText: context.tr('room.sampleEmailHint'),
                            hintStyle: TextStyle(
                              color: isDark
                                  ? Colors.white38
                                  : context.hc.textTertiary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              size: 17,
                              color: isDark
                                  ? context.hc.accent
                                  : context.hc.brandDark,
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 26,
                              minHeight: 26,
                            ),
                            filled: false,
                            contentPadding: const EdgeInsets.fromLTRB(
                              0,
                              6,
                              0,
                              2,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: context.hc.border,
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: context.hc.border,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: context.hc.brand,
                                width: 1.8,
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: context.hc.error,
                                width: 1.4,
                              ),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: context.hc.error,
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
                                foregroundColor: bodyColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
              const Positioned(
                top: 0,
                left: 22,
                right: 22,
                child: HajiDialogHeroHeader(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'UNDANG JAMAAH',
                ),
              ),

              // ── 3. Protruding Ribbon Submit Button ──
              Positioned(
                bottom: 0,
                right: 0,
                child: HajiDialogRibbonButton(
                  label: 'KIRIM',
                  isLoading: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
