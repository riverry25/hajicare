import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/haji_dialog_hero_header.dart';
import '../../../core/widgets/haji_dialog_ribbon_button.dart';
import '../../../core/widgets/haji_transparent_dialog.dart';
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
    final isDarkDialog = context.hc.isDark;
    final dialogBg = context.hc.surface;
    final headingClr = context.hc.textPrimary;
    final bodyClr = context.hc.textSecondary;

    return HajiTransparentDialog(
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
                border: Border.all(color: context.hc.borderSubtle, width: 1),
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
                      style: context.text.titleMedium.copyWith(
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
                      style: context.text.bodySmall.copyWith(
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
                                  : context.hc.textTertiary,
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
                            style: TextStyle(
                              color: context.hc.error,
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
                                      ? context.hc.surfaceSand
                                      : context.hc.surfaceSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: context.hc.borderSubtle,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  preset,
                                  style: TextStyle(
                                    color: context.hc.textPrimary,
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
                            foregroundColor: bodyClr,
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

            // ── 2. Floating Hero Card ────────────────────────────────────
            const Positioned(
              top: 0,
              left: 22,
              right: 22,
              child: HajiDialogHeroHeader(
                icon: Icons.meeting_room_rounded,
                title: 'ROOM PEMANTAUAN',
              ),
            ),

            // ── 3. Protruding Ribbon Submit Button ─────────────────────────
            Positioned(
              bottom: 0,
              right: 0,
              child: Obx(() {
                final submitting = widget.controller.isSubmitting.value;
                return HajiDialogRibbonButton(
                  label: 'BUAT ROOM',
                  isLoading: submitting,
                  onPressed: _submit,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
