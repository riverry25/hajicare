import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../../core/widgets/ribbon_fold_painter.dart';
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
      setState(() => _inputError = 'Isi nama rombongan terlebih dahulu.');
      return;
    }

    final maktab = _maktabCtrl.text.trim();
    final kloter = _kloterCtrl.text.trim();
    final radius = double.tryParse(_radiusCtrl.text.trim());

    if (name.length > 100 || maktab.length > 60 || kloter.length > 60) {
      setState(
        () => _inputError =
            'Nama maksimal 100 karakter; maktab dan kloter maksimal 60 karakter.',
      );
      return;
    }

    if (radius == null || radius <= 0 || radius > 10000) {
      setState(
        () => _inputError = 'Jarak aman harus antara 1 dan 10.000 meter.',
      );
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
          title: 'Perubahan Disimpan',
          message: 'Pengaturan rombongan "$name" sudah diperbarui.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _inputError = UserFeedbackMessage.from(
            e,
            fallback: 'Perubahan belum dapat disimpan. Silakan coba lagi.',
          );
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

    Widget buildUnderlineInput({
      required String label,
      required TextEditingController controller,
      String? hint,
      String? suffix,
      IconData? prefixIcon,
      TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters,
      TextCapitalization textCapitalization = TextCapitalization.none,
      ValueChanged<String>? onChanged,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: headingClr,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          TextFormField(
            controller: controller,
            enabled: !_isSaving,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            style: TextStyle(
              color: headingClr,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: isDarkDialog ? Colors.white38 : const Color(0xFF9E8E81),
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: bodyClr.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      size: 17,
                      color: isDarkDialog
                          ? AppColors.goldLight.withValues(alpha: 0.7)
                          : AppColors.espressoDark.withValues(alpha: 0.6),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 26,
                minHeight: 26,
              ),
              filled: false,
              contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
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
            ),
            onChanged: onChanged,
          ),
        ],
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 640),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ubah Pengaturan Room',
                        style: AppTypography.titleMedium.copyWith(
                          color: headingClr,
                          fontWeight: FontWeight.w800,
                          fontSize: 17.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Perbarui nama room, nomor maktab, nomor kloter, atau batas radius aman.',
                        style: AppTypography.bodySmall.copyWith(
                          color: bodyClr.withValues(alpha: 0.85),
                          height: 1.35,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Room Code Badge
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkDialog
                                ? AppColors.darkPrimaryContainer.withValues(
                                    alpha: 0.5,
                                  )
                                : AppColors.canvasCream,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: AppColors.goldPrimary.withValues(
                                alpha: 0.35,
                              ),
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
                                'Kode: ',
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
                      const SizedBox(height: 14),

                      // Field: Nama Room
                      buildUnderlineInput(
                        label: 'Nama Room / Rombongan *',
                        hint: 'Contoh: Rombongan Maktab 10',
                        controller: _nameCtrl,
                        prefixIcon: Icons.meeting_room_outlined,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(100),
                        ],
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) {
                          if (_inputError != null) {
                            setState(() => _inputError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Row: Maktab & Kloter
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: buildUnderlineInput(
                              label: context.tr('maktabLabelShort'),
                              hint: '10 / Maktab 10',
                              controller: _maktabCtrl,
                              prefixIcon: Icons.apartment_rounded,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(60),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: buildUnderlineInput(
                              label: context.tr('kloterLabelShort'),
                              hint: '14 JKS',
                              controller: _kloterCtrl,
                              prefixIcon: Icons.flight_takeoff_rounded,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(60),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Field: Radius Aman
                      buildUnderlineInput(
                        label: 'Batas Radius Aman (Meter) *',
                        hint: '200',
                        suffix: 'meter',
                        controller: _radiusCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        prefixIcon: Icons.radar_rounded,
                        onChanged: (_) {
                          if (_inputError != null) {
                            setState(() => _inputError = null);
                          }
                        },
                      ),

                      if (_inputError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _inputError!,
                          style: const TextStyle(
                            color: AppColors.sosEmergency,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Bottom Row
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
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(false),
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
                                Icons.meeting_room_rounded,
                                color: AppColors.accentGoldStar,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'PENGATURAN ROMBONGAN',
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
                        color: isDarkDialog
                            ? const Color(0xFF140D08)
                            : const Color(0xFF160D07),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _handleSave();
                            },
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
                          horizontal: 28,
                          vertical: 13.5,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SIMPAN',
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
