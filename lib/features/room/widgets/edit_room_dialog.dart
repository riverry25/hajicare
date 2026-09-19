import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../controllers/admin_room_controller.dart';
import '../services/room_service.dart';

/// Modern centered modal dialog for Pendamping / Admin to edit Room settings.
/// Structured following the exact logic and pattern of _showEditNameDialog in ProfileScreen.
class EditRoomDialog extends StatefulWidget {
  final RoomModel room;

  const EditRoomDialog({super.key, required this.room});

  /// Displays the dialog following the exact showDialog pattern from ProfileScreen.
  static Future<bool?> show(BuildContext context, RoomModel room) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => EditRoomDialog(room: room),
    );
  }

  @override
  State<EditRoomDialog> createState() => _EditRoomDialogState();
}

class _EditRoomDialogState extends State<EditRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _maktabCtrl;
  late final TextEditingController _kloterCtrl;
  late final TextEditingController _radiusCtrl;

  bool _isSaving = false;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    final hc = Get.isRegistered<HajiCareController>()
        ? Get.find<HajiCareController>()
        : null;
    final r =
        (hc?.activeRoom.value != null &&
            hc!.activeRoom.value!.id == widget.room.id)
        ? hc.activeRoom.value!
        : widget.room;

    _nameCtrl = TextEditingController(text: r.name);
    _maktabCtrl = TextEditingController(text: r.maktab ?? '');
    _kloterCtrl = TextEditingController(text: r.kloter ?? '');
    _radiusCtrl = TextEditingController(
      text: r.safeRadius > 0 ? r.safeRadius.toStringAsFixed(0) : '200',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maktabCtrl.dispose();
    _kloterCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _inputError = 'Nama room tidak boleh kosong');
      return;
    }

    final maktab = _maktabCtrl.text.trim();
    final kloter = _kloterCtrl.text.trim();
    final radius = double.tryParse(_radiusCtrl.text.trim());

    if (radius == null || radius <= 0) {
      setState(() => _inputError = 'Radius aman harus angka positif (> 0 m)');
      return;
    }

    setState(() {
      _isSaving = true;
      _inputError = null;
    });

    try {
      final hc = Get.isRegistered<HajiCareController>()
          ? Get.find<HajiCareController>()
          : null;

      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final role = hc?.role == UserRole.admin ? 'admin' : 'pendamping';

      // 1. Commit update to Firestore
      await RoomService().updateRoomSettings(
        roomId: widget.room.id,
        currentUserId: currentUid,
        userRole: role,
        name: name,
        maktab: maktab,
        kloter: kloter,
        safeRadius: radius,
      );

      // 2. Synchronously update HajiCareController reactive state across all pages
      if (hc != null) {
        final isCurrentRoom =
            (hc.activeRoomId.value == widget.room.id) ||
            (hc.activeRoom.value?.id == widget.room.id);
        if (isCurrentRoom) {
          final updatedRoom = (hc.activeRoom.value ?? widget.room).copyWith(
            name: name,
            maktab: maktab,
            kloter: kloter,
            safeRadius: radius,
          );
          hc.activeRoom.value = updatedRoom;
          hc.activeRoom.refresh();

          if (maktab.isNotEmpty) {
            hc.pendampingMaktab.value = maktab;
            hc.pendampingMaktab.refresh();
          }
          if (kloter.isNotEmpty) {
            hc.pendampingKloter.value = kloter;
            hc.pendampingKloter.refresh();
          }
          if (radius > 0) {
            hc.safeRadiusMeters.value = radius;
            hc.safeRadiusMeters.refresh();
          }
        }
      }

      // 3. Synchronously update AdminRoomController if active
      if (Get.isRegistered<AdminRoomController>()) {
        final adminCtrl = Get.find<AdminRoomController>();
        final idx = adminCtrl.rooms.indexWhere((r) => r.id == widget.room.id);
        if (idx != -1) {
          adminCtrl.rooms[idx] = adminCtrl.rooms[idx].copyWith(
            name: name,
            maktab: maktab,
            kloter: kloter,
            safeRadius: radius,
          );
          adminCtrl.rooms.refresh();
        }
        if (adminCtrl.selectedRoom.value?.id == widget.room.id) {
          adminCtrl.selectedRoom.value = adminCtrl.selectedRoom.value!.copyWith(
            name: name,
            maktab: maktab,
            kloter: kloter,
            safeRadius: radius,
          );
          adminCtrl.selectedRoom.refresh();
        }
      }

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }

      if (mounted) {
        AppAlert.success(
          context,
          title: 'Berhasil',
          message: 'Pengaturan room "$name" berhasil diperbarui.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _inputError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
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
    final borderClr = isDarkDialog
        ? AppColors.darkOutlineVariant
        : AppColors.cardBorderColor(context);

    // Borderless text field decoration as requested
    InputDecoration inputDec({
      required String label,
      String? hint,
      String? suffix,
      Widget? prefixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: bodyClr, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(
          color: bodyClr.withValues(alpha: 0.4),
          fontSize: 13,
        ),
        suffixText: suffix,
        suffixStyle: TextStyle(
          color: bodyClr.withValues(alpha: 0.7),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: isDarkDialog
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCream,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        // No borders on the text field as requested
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.goldPrimary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.sosEmergency,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(
            color: AppColors.sosEmergency,
            width: 1.5,
          ),
        ),
        prefixIcon: prefixIcon,
      );
    }

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: AppColors.goldPrimary.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenEdgeGutter,
        vertical: 24,
      ),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Center Icon Badge (exact style from ProfileScreen)
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.goldPrimary.withValues(alpha: 0.22),
                            AppColors.goldPrimary.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.45),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.meeting_room_rounded,
                        color: AppColors.goldPrimary,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Title & Subtitle
                  Text(
                    'Ubah Pengaturan Room',
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge.copyWith(
                      color: headingClr,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Perbarui nama room, nomor maktab, nomor kloter, atau batas radius aman rombongan.',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: bodyClr,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Room Code Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkDialog
                            ? AppColors.darkPrimaryContainer.withValues(
                                alpha: 0.5,
                              )
                            : AppColors.canvasCream,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.goldPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 12,
                            color: bodyClr,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Kode Room: ',
                            style: TextStyle(
                              color: bodyClr,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.room.code,
                            style: const TextStyle(
                              color: AppColors.goldPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Field: Nama Room
                  TextFormField(
                    controller: _nameCtrl,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.words,
                    style: AppTypography.bodyLarge.copyWith(
                      color: headingClr,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: inputDec(
                      label: 'Nama Room / Rombongan *',
                      hint: 'Contoh: Rombongan Maktab 10',
                      prefixIcon: const Icon(
                        Icons.meeting_room_outlined,
                        color: AppColors.goldPrimary,
                        size: 20,
                      ),
                    ),
                    onChanged: (_) {
                      if (_inputError != null) {
                        setState(() => _inputError = null);
                      }
                    },
                  ),
                  const SizedBox(height: 14),

                  // Field: Maktab & Kloter side by side
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _maktabCtrl,
                          enabled: !_isSaving,
                          style: AppTypography.bodyMedium.copyWith(
                            color: headingClr,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: inputDec(
                            label: context.tr('maktabLabelShort'),
                            hint: '10 / Maktab 10',
                            prefixIcon: const Icon(
                              Icons.apartment_rounded,
                              color: AppColors.goldPrimary,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _kloterCtrl,
                          enabled: !_isSaving,
                          style: AppTypography.bodyMedium.copyWith(
                            color: headingClr,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: inputDec(
                            label: context.tr('kloterLabelShort'),
                            hint: '14 JKS',
                            prefixIcon: const Icon(
                              Icons.flight_takeoff_rounded,
                              color: AppColors.goldPrimary,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Field: Radius Aman
                  TextFormField(
                    controller: _radiusCtrl,
                    enabled: !_isSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: AppTypography.bodyMedium.copyWith(
                      color: headingClr,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: inputDec(
                      label: 'Batas Radius Aman (Meter) *',
                      hint: '200',
                      suffix: 'meter',
                      prefixIcon: const Icon(
                        Icons.radar_rounded,
                        color: AppColors.goldPrimary,
                        size: 20,
                      ),
                    ),
                    onChanged: (_) {
                      if (_inputError != null) {
                        setState(() => _inputError = null);
                      }
                    },
                  ),

                  // Error notice if any
                  if (_inputError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.sosEmergency.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.sosEmergency.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: AppColors.sosEmergency,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _inputError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.sosEmergency,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  // Actions: Batal & Simpan (exact layout from ProfileScreen)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderClr),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: isDarkDialog
                                    ? AppColors.darkTextBody
                                    : AppColors.espressoDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _handleSave();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkDialog
                                  ? AppColors.darkPrimaryContainer
                                  : AppColors.espressoDark,
                              foregroundColor: isDarkDialog
                                  ? AppColors.goldLight
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
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
      ),
    );
  }
}
