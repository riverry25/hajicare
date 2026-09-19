import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/services/app_alert_service.dart';

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
          title: 'Perubahan Disimpan',
          message: 'Pengaturan room "$name" berhasil diperbarui.',
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
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final room = _room;

    final underline = UnderlineInputBorder(
      borderSide: BorderSide(
        color: isDark
            ? AppColors.darkOutlineVariant
            : AppColors.lightCardBorder,
        width: 1.4,
      ),
    );
    final underlineFocus = UnderlineInputBorder(
      borderSide: BorderSide(
        color: isDark ? AppColors.goldLight : AppColors.espressoDark,
        width: 2,
      ),
    );
    const underlineErr = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.sosEmergency, width: 1.8),
    );

    InputDecoration dec({
      required String label,
      required String hint,
      String? suffix,
      Widget? prefix,
    }) => InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: bodyColor.withValues(alpha: 0.75),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        color: bodyColor.withValues(alpha: 0.4),
        fontSize: 14,
      ),
      suffixText: suffix,
      suffixStyle: TextStyle(
        color: bodyColor.withValues(alpha: 0.6),
        fontSize: 13,
      ),
      prefixIcon: prefix,
      prefixIconColor: isDark
          ? AppColors.goldLight.withValues(alpha: 0.7)
          : AppColors.tanMedium,
      filled: false,
      border: underline,
      enabledBorder: underline,
      focusedBorder: underlineFocus,
      errorBorder: underlineErr,
      focusedErrorBorder: underlineErr,
      contentPadding: const EdgeInsets.only(bottom: 8, top: 4),
      errorStyle: const TextStyle(fontSize: 11, color: AppColors.sosEmergency),
      isDense: true,
    );

    return Scaffold(
      backgroundColor: AppColors.scaffoldColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldColor(context),
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
              'EDIT ROOM',
              style: TextStyle(
                color: isDark ? AppColors.goldLight : AppColors.espressoDark,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            Text(
              room?.name ?? 'Edit Room',
              style: TextStyle(
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
                  color: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.canvasCream,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? AppColors.goldLight.withValues(alpha: 0.3)
                        : AppColors.goldLight.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  room.code,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.goldLight
                        : AppColors.espressoDark,
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
              enabled: !_isSaving,
              style: TextStyle(
                color: headingColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: dec(
                label: 'Nama Room / Rombongan *',
                hint: 'Contoh: Rombongan Maktab 48 Kloter 12',
                prefix: const Icon(Icons.meeting_room_outlined, size: 20),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama room tidak boleh kosong'
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
                    enabled: !_isSaving,
                    style: TextStyle(
                      color: headingColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: dec(
                      label: context.tr('maktabLabelShort'),
                      hint: '48',
                      prefix: const Icon(Icons.apartment_rounded, size: 19),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: dec(
                      label: context.tr('kloterLabelShort'),
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
              style: TextStyle(
                color: headingColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: dec(
                label: 'Batas Radius Aman *',
                hint: '200',
                suffix: 'meter',
                prefix: const Icon(Icons.radar_rounded, size: 20),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Radius aman wajib diisi';
                }
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) {
                  return 'Masukkan angka positif lebih dari 0';
                }
                return null;
              },
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sosEmergency.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: AppColors.sosEmergency,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.sosEmergency,
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
                  backgroundColor: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.espressoDark,
                  foregroundColor: isDark
                      ? AppColors.goldLight
                      : AppColors.surfaceWhite,
                  disabledBackgroundColor: AppColors.espressoDark.withValues(
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
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.surfaceWhite,
                        ),
                      )
                    : const Text(
                        'SIMPAN PERUBAHAN',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.5,
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
