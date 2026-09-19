import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/services/app_alert_service.dart';

/// Modal dialog for editing room parameters (Name, Maktab, Kloter, Safe Radius).
/// Only available to the creator of the room (or admin).
///
/// Layout: Dialog + Column(mainAxisSize: min) — no SingleChildScrollView needed.
/// The form content height (~400px) is well below any modern phone screen,
/// so scroll is unnecessary and removing it eliminates all unbounded-height errors.
class EditRoomDialog extends StatefulWidget {
  final RoomModel room;

  const EditRoomDialog({
    super.key,
    required this.room,
  });

  static Future<bool?> show(BuildContext context, RoomModel room) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => EditRoomDialog(room: room),
    );
  }

  @override
  State<EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _maktabController;
  late final TextEditingController _kloterController;
  late final TextEditingController _radiusController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final state =
        Get.isRegistered<HajiCareController>() ? Get.find<HajiCareController>() : null;
    final currentRoom = state?.activeRoom.value ?? widget.room;
    _nameController = TextEditingController(text: currentRoom.name);
    _maktabController = TextEditingController(text: currentRoom.maktab ?? '');
    _kloterController = TextEditingController(text: currentRoom.kloter ?? '');
    _radiusController = TextEditingController(
      text: currentRoom.safeRadius > 0
          ? currentRoom.safeRadius.toStringAsFixed(0)
          : '200',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maktabController.dispose();
    _kloterController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final trimmedName = _nameController.text.trim();
    final trimmedMaktab = _maktabController.text.trim();
    final trimmedKloter = _kloterController.text.trim();
    final radiusVal = double.tryParse(_radiusController.text.trim());

    if (radiusVal == null || radiusVal <= 0) {
      setState(() {
        _errorMessage = 'Radius aman harus bernilai angka positif lebih dari 0 meter.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final state = Get.find<HajiCareController>();
      await state.updateCurrentRoomSettings(
        name: trimmedName,
        maktab: trimmedMaktab,
        kloter: trimmedKloter,
        safeRadius: radiusVal,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        AppAlert.success(
          context,
          title: 'Perubahan Disimpan',
          message: 'Pengaturan room "$trimmedName" berhasil diperbarui.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    // Underline-only borders — subscribe-card reference
    final underlineBorder = UnderlineInputBorder(
      borderSide: BorderSide(
        color: isDark ? AppColors.darkOutlineVariant : AppColors.lightCardBorder,
        width: 1.4,
      ),
    );
    final underlineFocused = UnderlineInputBorder(
      borderSide: BorderSide(
        color: isDark ? AppColors.goldLight : AppColors.espressoDark,
        width: 2,
      ),
    );
    const underlineError = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.sosEmergency, width: 1.8),
    );

    InputDecoration fieldDecoration({
      required String label,
      required String hint,
      String? suffixText,
      Widget? prefixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: bodyColor.withValues(alpha: 0.75),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        hintText: hint,
        hintStyle: TextStyle(color: bodyColor.withValues(alpha: 0.4), fontSize: 14),
        suffixText: suffixText,
        suffixStyle: TextStyle(color: bodyColor.withValues(alpha: 0.6), fontSize: 13),
        prefixIcon: prefixIcon,
        prefixIconColor:
            isDark ? AppColors.goldLight.withValues(alpha: 0.7) : AppColors.tanMedium,
        filled: false,
        border: underlineBorder,
        enabledBorder: underlineBorder,
        focusedBorder: underlineFocused,
        errorBorder: underlineError,
        focusedErrorBorder: underlineError,
        contentPadding: const EdgeInsets.only(bottom: 8, top: 4),
        errorStyle: const TextStyle(fontSize: 11, color: AppColors.sosEmergency),
        isDense: true,
      );
    }

    // ── ROOT: Dialog + Column(mainAxisSize: min) ─────────────────────────────
    // This is the simplest layout that works reliably.
    // Dialog constrains width (minWidth~maxWidth) but lets Column determine height.
    // Column(mainAxisSize: min) shrinks to exactly fit its children — no scroll needed.
    // ────────────────────────────────────────────────────────────────────────
    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? AppColors.darkOutlineVariant : AppColors.lightCardBorder,
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 32),
      elevation: isDark ? 16 : 8,
      shadowColor: AppColors.espressoDark.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,  // ← shrink to content, no overflow
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // ── Header: EDIT ROOM label + name + close ───────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'EDIT ROOM',
                          style: TextStyle(
                            color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.room.name,
                          style: TextStyle(
                            color: headingColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _isSaving ? null : () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.canvasCreamSubtle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 17,
                        color: bodyColor.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Room Code Badge ─────────────────────────────────────────
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: bodyColor.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kode: ',
                    style: TextStyle(
                      color: bodyColor.withValues(alpha: 0.65),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryContainer
                          : AppColors.canvasCream,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isDark
                            ? AppColors.goldLight.withValues(alpha: 0.3)
                            : AppColors.goldLight.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      widget.room.code,
                      style: TextStyle(
                        color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkOutlineVariant : AppColors.lightCardBorder,
              ),
              const SizedBox(height: 16),

              // ── Nama Room ───────────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                style: TextStyle(
                  color: headingColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: fieldDecoration(
                  label: 'Nama Room / Rombongan *',
                  hint: 'Contoh: Rombongan Maktab 48 Kloter 12',
                  prefixIcon: const Icon(Icons.meeting_room_outlined, size: 18),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Nama room tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Maktab & Kloter ─────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maktabController,
                      enabled: !_isSaving,
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: fieldDecoration(
                        label: context.tr('maktabLabelShort'),
                        hint: '48',
                        prefixIcon: const Icon(Icons.apartment_rounded, size: 17),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      controller: _kloterController,
                      enabled: !_isSaving,
                      style: TextStyle(
                        color: headingColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: fieldDecoration(
                        label: context.tr('kloterLabelShort'),
                        hint: '14 JKS',
                        prefixIcon: const Icon(Icons.flight_takeoff_rounded, size: 17),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Radius Aman ─────────────────────────────────────────────
              TextFormField(
                controller: _radiusController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: TextStyle(
                  color: headingColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
                decoration: fieldDecoration(
                  label: 'Batas Radius Aman *',
                  hint: '200',
                  suffixText: 'meter',
                  prefixIcon: const Icon(Icons.radar_rounded, size: 18),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Radius aman wajib diisi';
                  }
                  final numVal = double.tryParse(val.trim());
                  if (numVal == null || numVal <= 0) {
                    return 'Masukkan angka positif lebih dari 0 meter';
                  }
                  return null;
                },
              ),

              // ── Error Message ───────────────────────────────────────────
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 13,
                      color: AppColors.sosEmergency,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.sosEmergency,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // ── Action Buttons: Batal (text) ← → SIMPAN (pill) ──────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: bodyColor.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),

                  // Prominent espresso pill — subscribe-card reference
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _handleSave();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkPrimaryContainer
                            : AppColors.espressoDark,
                        foregroundColor: isDark
                            ? AppColors.goldLight
                            : AppColors.surfaceWhite,
                        disabledBackgroundColor:
                            AppColors.espressoDark.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        elevation: 3,
                        shadowColor: AppColors.espressoDark.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(horizontal: 26),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? AppColors.goldLight
                                    : AppColors.surfaceWhite,
                              ),
                            )
                          : const Text(
                              'SIMPAN',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                letterSpacing: 1.6,
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
    );
  }
}
