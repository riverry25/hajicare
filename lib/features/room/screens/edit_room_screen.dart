import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/utils/user_feedback_message.dart';

/// Simple full-screen edit room form.
/// Uses normal screen navigation (Get.toNamed) instead of dialogs/modals,
/// completely avoiding MediaQuery/layout conflicts.
class EditRoomScreen extends StatefulWidget {
  const EditRoomScreen({super.key});

  @override
  State<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends State<EditRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _maktabController;
  late final TextEditingController _kloterController;
  late final TextEditingController _radiusController;

  bool _isSaving = false;
  String? _errorMessage;

  RoomModel? get _room {
    final hc = Get.find<HajiCareController>();
    final arg = Get.arguments;
    return hc.activeRoom.value ?? (arg is RoomModel ? arg : null);
  }

  @override
  void initState() {
    super.initState();
    final hc = Get.find<HajiCareController>();
    final arg = Get.arguments;
    final room = hc.activeRoom.value ?? (arg is RoomModel ? arg : null);
    _nameController = TextEditingController(text: room?.name ?? '');
    _maktabController = TextEditingController(text: room?.maktab ?? '');
    _kloterController = TextEditingController(text: room?.kloter ?? '');
    _radiusController = TextEditingController(
      text: (room?.safeRadius ?? 0) > 0
          ? room!.safeRadius.toStringAsFixed(0)
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

    final name = _nameController.text.trim();
    final maktab = _maktabController.text.trim();
    final kloter = _kloterController.text.trim();
    final radius = double.tryParse(_radiusController.text.trim());

    if (radius == null || radius <= 0) {
      setState(
        () => _errorMessage =
            'Radius aman harus bernilai angka positif lebih dari 0 meter.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await Get.find<HajiCareController>().updateCurrentRoomSettings(
        name: name,
        maktab: maktab,
        kloter: kloter,
        safeRadius: radius,
      );
      if (mounted) {
        Get.back(result: true);
        AppAlert.success(
          context,
          title: context.tr('room.changesSaved'),
          message: 'Pengaturan rombongan "$name" sudah diperbarui.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = UserFeedbackMessage.from(
            e,
            fallback: 'Perubahan belum dapat disimpan. Silakan coba lagi.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headingColor = context.hc.textPrimary;
    final bodyColor = context.hc.textSecondary;
    final room = _room;

    final underline = UnderlineInputBorder(
      borderSide: BorderSide(color: context.hc.border, width: 1.4),
    );
    final underlineFocus = UnderlineInputBorder(
      borderSide: BorderSide(color: context.hc.brand, width: 2),
    );
    final underlineErr = UnderlineInputBorder(
      borderSide: BorderSide(color: context.hc.danger, width: 1.8),
    );

    InputDecoration dec({
      required String label,
      required String hint,
      String? suffix,
      Widget? prefix,
    }) => InputDecoration(
      labelText: label,
      labelStyle: context.text.labelSmall.copyWith(
        color: bodyColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintText: hint,
      hintStyle: context.text.bodyMedium.copyWith(
        color: context.hc.textTertiary,
        fontSize: 14,
      ),
      suffixText: suffix,
      suffixStyle: context.text.captionMedium.copyWith(
        color: bodyColor,
        fontSize: 13,
      ),
      prefixIcon: prefix,
      prefixIconColor: context.hc.accent,
      filled: false,
      border: underline,
      enabledBorder: underline,
      focusedBorder: underlineFocus,
      errorBorder: underlineErr,
      focusedErrorBorder: underlineErr,
      contentPadding: const EdgeInsets.only(bottom: 8, top: 4),
      errorStyle: context.text.captionSmall.copyWith(
        fontSize: 11,
        color: context.hc.danger,
      ),
      isDense: true,
    );

    return Scaffold(
      backgroundColor: context.hc.canvas,
      appBar: AppBar(
        backgroundColor: context.hc.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _isSaving ? null : () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('room.editRoom').toUpperCase(),
              style: context.text.captionSmall.copyWith(
                color: context.hc.accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            Text(
              room?.name ?? context.tr('room.editRoom'),
              style: context.text.titleMedium.copyWith(
                color: headingColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (room != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.hc.surfaceSand,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.hc.border),
                ),
                child: Text(
                  room.code,
                  style: TextStyle(
                    color: context.hc.brand,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Nama Room
            TextFormField(
              controller: _nameController,
              inputFormatters: [LengthLimitingTextInputFormatter(100)],
              enabled: !_isSaving,
              style: context.text.bodyMedium.copyWith(
                color: headingColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: dec(
                label: context.tr('room.roomNameField'),
                hint: context.tr('room.sampleRoomName'),
                prefix: const Icon(Icons.meeting_room_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.tr('room.emptyRoomName')
                  : v.trim().length > 100
                  ? context.tr('room.nameMax100')
                  : null,
            ),
            const SizedBox(height: 24),

            // Maktab & Kloter
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maktabController,
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    enabled: !_isSaving,
                    style: context.text.bodyMedium.copyWith(
                      color: headingColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: dec(
                      label: context.tr('room.maktab'),
                      hint: '48',
                      prefix: const Icon(Icons.apartment_rounded, size: 19),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    controller: _kloterController,
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    enabled: !_isSaving,
                    style: context.text.bodyMedium.copyWith(
                      color: headingColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: dec(
                      label: context.tr('room.kloter'),
                      hint: '14 JKS',
                      prefix: const Icon(
                        Icons.flight_takeoff_rounded,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Radius Aman
            TextFormField(
              controller: _radiusController,
              enabled: !_isSaving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: context.text.bodyMedium.copyWith(
                color: headingColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: dec(
                label: context.tr('room.safeRadiusLimit'),
                hint: '200',
                suffix: 'meter',
                prefix: const Icon(Icons.radar_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return context.tr('room.safeRadiusRequired');
                }
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0 || n > 10000) {
                  return context.tr('room.safeRadiusInvalidRange');
                }
                return null;
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.hc.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: context.hc.danger,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: context.text.captionMedium.copyWith(
                          fontSize: 12,
                          color: context.hc.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),

            // Tombol Simpan
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        _handleSave();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.hc.brand,
                  foregroundColor: context.hc.onPrimary,
                  disabledBackgroundColor: context.hc.brand.withValues(
                    alpha: 0.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: context.hc.onPrimary,
                        ),
                      )
                    : Text(
                        context.tr('common.save'),
                        style: context.text.labelLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.5,
                          color: context.hc.onPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
