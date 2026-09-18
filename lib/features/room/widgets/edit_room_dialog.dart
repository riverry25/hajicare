import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/locales/app_translations.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/app_alert_service.dart';

/// Modal dialog for editing room parameters (Name, Maktab, Kloter, Safe Radius).
/// Only available to the creator of the room (or admin).
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
    final state = Get.isRegistered<HajiCareController>() ? Get.find<HajiCareController>() : null;
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
    final cardBg = AppColors.cardBgColor(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.goldPrimary;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        side: BorderSide(color: AppColors.cardBorderColor(context)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(Icons.edit_note_rounded, color: primaryColor, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Pengaturan Room',
                            style: AppTypography.titleMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Perbarui rincian rombongan & radius pantau',
                            style: AppTypography.captionSmall.copyWith(color: bodyColor),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Readonly Info: Kode Room Unik
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.cardBorderColor(context)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kode Room (Terkunci)',
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          widget.room.code,
                          style: AppTypography.bodyMedium.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Nama Room
                Text(
                  'Nama Room / Rombongan *',
                  style: AppTypography.labelMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  style: TextStyle(color: headingColor),
                  decoration: InputDecoration(
                    hintText: 'Contoh: Rombongan Maktab 48 Kloter 12',
                    prefixIcon: const Icon(Icons.meeting_room_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama room tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Row Maktab & Kloter
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Maktab
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('maktabLabelShort'),
                            style: AppTypography.labelMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _maktabController,
                            enabled: !_isSaving,
                            style: TextStyle(color: headingColor),
                            decoration: InputDecoration(
                              hintText: 'Misal: 48',
                              prefixIcon: const Icon(Icons.apartment_rounded, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Kloter
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('kloterLabelShort'),
                            style: AppTypography.labelMedium.copyWith(
                              color: headingColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _kloterController,
                            enabled: !_isSaving,
                            style: TextStyle(color: headingColor),
                            decoration: InputDecoration(
                              hintText: 'Misal: 14 JKS',
                              prefixIcon: const Icon(Icons.flight_takeoff_rounded, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Radius Aman (safeRadius)
                Text(
                  'Batas Radius Aman (Meter) *',
                  style: AppTypography.labelMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Batas jarak maksimal jamaah sebelum peringatan waspada/bahaya aktif.',
                  style: AppTypography.captionSmall.copyWith(color: bodyColor),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _radiusController,
                  enabled: !_isSaving,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: TextStyle(color: headingColor),
                  decoration: InputDecoration(
                    hintText: 'Contoh: 200',
                    suffixText: 'meter',
                    prefixIcon: const Icon(Icons.radar_rounded, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

                if (_errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorMessage!,
                    style: AppTypography.caption.copyWith(color: AppColors.sosEmergency),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: bodyColor,
                          side: BorderSide(color: AppColors.cardBorderColor(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? AppColors.espressoDark : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
