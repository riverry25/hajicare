import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/admin_room_controller.dart';

/// Dialog for creating a new monitoring room.
/// Designed with the premium HajiCare floating hero card and protruding
/// ribbon action button, matching the profile edit name dialog visual language.
class CreateRoomDialog extends StatefulWidget {
  final AdminRoomController controller;

  const CreateRoomDialog({super.key, required this.controller});

  /// Static helper to display the [CreateRoomDialog].
  static Future<void> show(
    BuildContext context,
    AdminRoomController controller,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CreateRoomDialog(controller: controller),
    );
  }

  @override
  State<CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends State<CreateRoomDialog> {
  late final TextEditingController _nameCtrl;
  String? _inputError;

  static const List<String> _presets = [
    'Maktab 48 Kloter 12',
    'Kloter 05 JKS',
    'Hotel Al Kiswah Lt 4',
    'Rombongan Bimbad A',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.controller.isSubmitting.value) return;
    final input = _nameCtrl.text.trim();
    if (input.isEmpty) {
      setState(() => _inputError = 'Nama rombongan tidak boleh kosong');
      return;
    }
    if (input.length > 100) {
      setState(() => _inputError = 'Nama rombongan maksimal 100 karakter');
      return;
    }
    setState(() => _inputError = null);

    // Call admin controller createRoom which handles Firestore write,
    // pops dialog upon success, and shows AppAlert feedback.
    await widget.controller.createRoom(context, input);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkDialog = AppColors.isDark(context);
    final dialogBg = isDarkDialog
        ? AppColors.darkSurface
        : AppColors.surfaceWhite;
    final headingClr = isDarkDialog
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyClr = isDarkDialog ? AppColors.darkTextBody : AppColors.textBody;

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
            // ── 1. Main Card Body ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(
                top: 28,
                bottom: 12,
                right: 10,
                left: 10,
              ),
              padding: const EdgeInsets.fromLTRB(20, 68, 20, 14),
              decoration: BoxDecoration(
                color: dialogBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkDialog
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.goldLight.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkDialog ? 0.45 : 0.09,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      'Buat Room Pantau Baru',
                      style: AppTypography.titleMedium.copyWith(
                        color: headingClr,
                        fontWeight: FontWeight.w800,
                        fontSize: 17.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      'Masukkan nama kelompok atau maktab. Kode unik 6-karakter akan dibuat otomatis untuk jamaah & pendamping.',
                      style: AppTypography.bodySmall.copyWith(
                        color: bodyClr.withValues(alpha: 0.85),
                        height: 1.35,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Minimalist Underline Text Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          autofocus: true,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          maxLength: 100,
                          onSubmitted: (_) => _submit(),
                          style: TextStyle(
                            color: headingClr,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: context.tr('room.sampleGroupHint'),
                            hintStyle: TextStyle(
                              color: isDarkDialog
                                  ? Colors.white38
                                  : const Color(0xFF9E8E81),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
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
                                color: isDarkDialog
                                    ? AppColors.darkOutlineVariant
                                    : const Color(0xFFD4C7BC),
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkDialog
                                    ? AppColors.darkOutlineVariant
                                    : const Color(0xFFD4C7BC),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkDialog
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
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          onChanged: (_) {
                            if (_inputError != null) {
                              setState(() => _inputError = null);
                            }
                          },
                        ),
                        if (_inputError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _inputError!,
                            style: const TextStyle(
                              color: AppColors.sosEmergency,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Quick suggestion chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _presets.map((preset) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                _nameCtrl.text = preset;
                                if (_inputError != null) {
                                  setState(() => _inputError = null);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkDialog
                                      ? AppColors.goldLight.withValues(
                                          alpha: 0.1,
                                        )
                                      : const Color(0xFFF7F2EB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDarkDialog
                                        ? AppColors.goldLight.withValues(
                                            alpha: 0.25,
                                          )
                                        : AppColors.goldLight.withValues(
                                            alpha: 0.4,
                                          ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  preset,
                                  style: TextStyle(
                                    color: isDarkDialog
                                        ? AppColors.goldLight
                                        : AppColors.espressoDark,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bottom Row: Cancel button on left, space reserved for protruding button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: isDarkDialog
                                ? Colors.white60
                                : const Color(0xFF8C7A6B),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 140,
                        ), // Spacer for protruding button
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Floating Hero Card (Compact header) ───────────────────
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
                    colors: isDarkDialog
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
                    // Ambient Background Circular Glows
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

                    // Center Hero Graphic
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
                                Icons.meeting_room_rounded,
                                color: AppColors.accentGoldStar,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ROOM PEMANTAUAN',
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

            // ── 3. Protruding Ribbon Submit Button ─────────────────────────
            Positioned(
              bottom: 0,
              right: 0,
              child: Obx(() {
                final submitting = widget.controller.isSubmitting.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ribbon fold triangle at the top-right corner
                    Positioned(
                      top: -10,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(10, 10),
                        painter: _RibbonFoldPainter(
                          color: isDarkDialog
                              ? const Color(0xFF140D08)
                              : const Color(0xFF160D07),
                        ),
                      ),
                    ),

                    // Main Pill Submit Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: submitting ? null : _submit,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(5),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: isDarkDialog
                                ? AppColors.darkPrimaryContainer
                                : AppColors.espressoDark,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 13.5,
                          ),
                          child: submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'BUAT ROOM',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter for the 3D folded ribbon corner flap on the protruding submit button.
class _RibbonFoldPainter extends CustomPainter {
  final Color color;
  const _RibbonFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(
        0,
        size.height,
      ) // bottom-left (intersection of card wall & button)
      ..lineTo(size.width, size.height) // bottom-right (top-right of button)
      ..lineTo(0, 0) // top-left (on card wall)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RibbonFoldPainter oldDelegate) =>
      color != oldDelegate.color;
}
