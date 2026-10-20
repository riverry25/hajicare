import '../../../core/locales/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../../core/widgets/haji_dialog_hero_header.dart';
import '../../../core/widgets/haji_dialog_ribbon_button.dart';
import '../../../core/widgets/haji_transparent_dialog.dart';
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
      setState(() => _inputError = context.tr('room.emptyRoomName'));
      return;
    }

    final maktab = _maktabCtrl.text.trim();
    final kloter = _kloterCtrl.text.trim();
    final radius = double.tryParse(_radiusCtrl.text.trim());

    if (name.length > 100 || maktab.length > 60 || kloter.length > 60) {
      setState(() => _inputError = context.tr('room.fieldLengthLimit'));
      return;
    }

    if (radius == null || radius <= 0 || radius > 10000) {
      setState(() => _inputError = context.tr('room.safeRadiusInvalidRange'));
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
          title: context.tr('room.changesSaved'),
          message: context.tr('room.roomSettingsUpdatedDesc', {'name': name}),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _inputError = UserFeedbackMessage.from(
            e,
            fallback: context.tr('room.roomSettingsSaveFailedFallback'),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkDialog = context.hc.isDark;
    final dialogBg = context.hc.surface;
    final headingClr = context.hc.textPrimary;
    final bodyClr = context.hc.textSecondary;

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
                color: isDarkDialog ? Colors.white38 : context.hc.textTertiary,
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
                          ? context.hc.sand
                          : context.hc.brandDark,
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 26,
                minHeight: 26,
              ),
              filled: false,
              contentPadding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: context.hc.border, width: 1.2),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.hc.border, width: 1.2),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.hc.brand, width: 1.8),
              ),
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.hc.error, width: 1.4),
              ),
              focusedErrorBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.hc.error, width: 1.8),
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      );
    }

    return HajiTransparentDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 640),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // 1. Main Card Body
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('room.editRoomSettingsTitle'),
                        style: context.text.titleMedium.copyWith(
                          color: headingClr,
                          fontWeight: FontWeight.w800,
                          fontSize: 17.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('room.editRoomSettingsDesc'),
                        style: context.text.bodySmall.copyWith(
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
                            color: context.hc.surfaceSand,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: context.hc.borderSubtle),
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
                                context.tr('room.codePrefix'),
                                style: TextStyle(
                                  color: bodyClr,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                widget.room.code,
                                style: TextStyle(
                                  color: context.hc.brand,
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
                        label: context.tr('room.roomNameField'),
                        hint: context.tr('room.sampleMaktab10'),
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
                              label: context.tr('room.maktab'),
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
                              label: context.tr('room.kloter'),
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
                        label: context.tr('room.safeRadiusLimit'),
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
                          style: TextStyle(
                            color: context.hc.error,
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
                              foregroundColor: bodyClr,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(false),
                            child: Text(
                              context.tr('common.cancel'),
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

            // 2. Floating Hero Card
            Positioned(
              top: 0,
              left: 22,
              right: 22,
              child: HajiDialogHeroHeader(
                icon: Icons.meeting_room_rounded,
                title: context.tr('room.groupSettingsHeader'),
              ),
            ),

            // 3. Protruding Ribbon Submit Button
            Positioned(
              bottom: 0,
              right: 0,
              child: HajiDialogRibbonButton(
                label: context.tr('common.save').toUpperCase(),
                isLoading: _isSaving,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _handleSave();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
