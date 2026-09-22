import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../presentation/dashboard_typography.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../notification/services/notification_service.dart';

enum CompanionContactKind { message, info }

/// Elder-friendly composer for contacting one or every pendamping in a room.
class CompanionContactSheet extends StatefulWidget {
  const CompanionContactSheet({
    super.key,
    required this.roomId,
    required this.pendampings,
    required this.state,
    this.notificationService,
  });

  final String roomId;
  final List<RoomMemberModel> pendampings;
  final HajiCareController state;
  final NotificationService? notificationService;

  @override
  State<CompanionContactSheet> createState() => _CompanionContactSheetState();
}

class _CompanionContactSheetState extends State<CompanionContactSheet> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  CompanionContactKind _kind = CompanionContactKind.message;
  bool _sendToAll = false;
  bool _includeLocation = false;
  bool _isFindingLocation = false;
  bool _isSending = false;
  String? _selectedPendampingUid;

  NotificationService get _notificationService =>
      widget.notificationService ?? NotificationService();

  List<String> get _quickMessages => [
    context.tr('dashboard.quickMessageCallMe'),
    context.tr('dashboard.quickMessageWaiting'),
    context.tr('dashboard.quickMessageSeparated'),
    context.tr('dashboard.quickMessagePickup'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _selectKind(CompanionContactKind kind) {
    HapticFeedback.selectionClick();
    setState(() {
      _kind = kind;
      if (kind == CompanionContactKind.info) {
        _sendToAll = true;
        _selectedPendampingUid = null;
      }
    });
  }

  Future<void> _toggleLocation() async {
    if (_includeLocation) {
      setState(() => _includeLocation = false);
      HapticFeedback.selectionClick();
      return;
    }

    if (widget.state.myCurrentPosition.value == null) {
      setState(() => _isFindingLocation = true);
      final found = await widget.state.refreshLocation();
      if (!mounted) return;
      setState(() {
        _isFindingLocation = false;
        _includeLocation =
            found && widget.state.myCurrentPosition.value != null;
      });
      if (!_includeLocation) {
        AppAlert.warning(
          context,
          title: context.tr('dashboard.locationNotFound'),
          message: context.tr('dashboard.enableGpsAccess'),
        );
      }
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _includeLocation = true);
  }

  Future<void> _send() async {
    if (_isSending || !_formKey.currentState!.validate()) return;
    final sendToAll = _kind == CompanionContactKind.info || _sendToAll;
    if (!sendToAll && _selectedPendampingUid == null) {
      AppAlert.warning(
        context,
        title: context.tr('dashboard.selectCompanion'),
        message: context.tr('dashboard.selectRecipientWarning'),
      );
      return;
    }

    setState(() => _isSending = true);
    final position = widget.state.myCurrentPosition.value;
    try {
      final recipientCount = await _notificationService.sendCompanionMessage(
        roomId: widget.roomId,
        message: _messageController.text.trim(),
        sendToAll: sendToAll,
        kind: _kind == CompanionContactKind.info ? 'info' : 'message',
        pendampingUid: sendToAll ? null : _selectedPendampingUid,
        latitude: _includeLocation ? position?.latitude : null,
        longitude: _includeLocation ? position?.longitude : null,
      );
      if (!mounted) return;
      Get.back();
      AppAlert.success(
        context,
        title: _kind == CompanionContactKind.info
            ? context.tr('dashboard.infoSent')
            : context.tr('dashboard.messageSent'),
        message: context.tr('dashboard.messageSentDesc', {
          'count': recipientCount,
          'location': _includeLocation
              ? context.tr('dashboard.withYourLocation')
              : '',
        }),
      );
    } catch (error) {
      if (!mounted) return;
      AppAlert.error(
        context,
        title: context.tr('dashboard.sendFailed'),
        message: UserFeedbackMessage.from(
          error,
          fallback: context.tr('dashboard.messageSendFallback'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Container(
        key: const Key('companion_contact_sheet'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.80,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.cardPadding,
            12,
            AppSpacing.cardPadding,
            AppSpacing.cardPadding + bottomInset,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                _buildHeader(headingColor, bodyColor),
                const SizedBox(height: 20),
                Text(
                  context.tr('dashboard.whatToSend'),
                  style: DashboardTypography.labelLarge.copyWith(
                    color: headingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _kindCard(
                        kind: CompanionContactKind.message,
                        icon: Icons.chat_bubble_rounded,
                        title: context.tr('dashboard.sendMessage'),
                        subtitle: context.tr('dashboard.sendMessageSub'),
                        isDark: isDark,
                        headingColor: headingColor,
                        bodyColor: bodyColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _kindCard(
                        kind: CompanionContactKind.info,
                        icon: Icons.campaign_rounded,
                        title: context.tr('dashboard.giveInfo'),
                        subtitle: context.tr('dashboard.giveInfoSub'),
                        isDark: isDark,
                        headingColor: headingColor,
                        bodyColor: bodyColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _buildRecipientSection(isDark, headingColor, bodyColor),
                const SizedBox(height: 22),
                Text(
                  context.tr('dashboard.writeMessage'),
                  style: DashboardTypography.labelLarge.copyWith(
                    color: headingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('companion_message_field'),
                  controller: _messageController,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: headingColor, fontSize: 17),
                  decoration: InputDecoration(
                    hintText: context.tr('dashboard.messageSampleHint'),
                    hintStyle: TextStyle(
                      color: bodyColor.withValues(alpha: 0.68),
                      fontSize: 15,
                      height: 1.35,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.darkSurfaceContainer
                        : AppColors.canvasCream,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.lightCardBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.lightCardBorder,
                      ),
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? context.tr('dashboard.writeMessageFirst')
                      : null,
                ),
                if (_kind == CompanionContactKind.message) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.tr('dashboard.quickMessages'),
                    style: TextStyle(
                      color: bodyColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickMessages
                        .map(
                          (message) => ActionChip(
                            label: Text(message),
                            avatar: const Icon(Icons.add_rounded, size: 18),
                            onPressed: () {
                              _messageController.text = message;
                              _messageController.selection =
                                  TextSelection.collapsed(
                                    offset: message.length,
                                  );
                              setState(() {});
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 22),
                _buildLocationButton(isDark, headingColor, bodyColor),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    key: const Key('companion_send_button'),
                    onPressed: _isSending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64A19),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? AppColors.darkSurfaceContainer
                          : const Color(0xFFE0DDDA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 23),
                    label: Text(
                      _isSending
                          ? context.tr('dashboard.sending')
                          : _kind == CompanionContactKind.info
                          ? context.tr('dashboard.sendAllCompanions')
                          : _sendToAll
                          ? context.tr('dashboard.sendAllCompanions')
                          : context.tr('dashboard.sendMessage'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _isSending ? null : Get.back,
                    child: Text(context.tr('cancel')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color headingColor, Color bodyColor) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE64A19).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            color: Color(0xFFE64A19),
            size: 32,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('dashboard.contactCompanion'),
                style: DashboardTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.tr('dashboard.contactCompanionSub'),
                style: TextStyle(color: bodyColor, fontSize: 14, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kindCard({
    required CompanionContactKind kind,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
  }) {
    final selected = _kind == kind;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: InkWell(
        key: Key('companion_kind_${kind.name}'),
        onTap: () => _selectKind(kind),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE64A19).withValues(alpha: isDark ? 0.22 : 0.1)
                : (isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE64A19)
                  : (isDark
                        ? AppColors.darkCardBorder
                        : AppColors.lightCardBorder),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? const Color(0xFFE64A19) : bodyColor,
                    size: 25,
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFFE64A19),
                      size: 22,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  color: headingColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: bodyColor, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipientSection(
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    if (_kind == CompanionContactKind.info) {
      return _recipientSummary(
        icon: Icons.groups_rounded,
        title: context.tr('dashboard.recipientAllCompanions'),
        subtitle: context.tr('dashboard.companionsInGroup', {
          'count': widget.pendampings.length,
        }),
        isDark: isDark,
        headingColor: headingColor,
        bodyColor: bodyColor,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('dashboard.sendToWhom'),
          style: DashboardTypography.labelLarge.copyWith(
            color: headingColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.canvasCream,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.lightCardBorder,
            ),
          ),
          child: RadioGroup<bool>(
            groupValue: _sendToAll,
            onChanged: _isSending
                ? (_) {}
                : (value) => setState(() => _sendToAll = value ?? false),
            child: Column(
              children: [
                RadioListTile<bool>(
                  key: const Key('recipient_one'),
                  value: false,
                  title: Text(
                    context.tr('dashboard.oneCompanion'),
                    style: TextStyle(
                      color: headingColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('dashboard.chooseCompanionName'),
                    style: TextStyle(color: bodyColor, fontSize: 13),
                  ),
                  secondary: const Icon(Icons.person_rounded),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                Divider(height: 1, color: bodyColor.withValues(alpha: 0.18)),
                RadioListTile<bool>(
                  key: const Key('recipient_all'),
                  value: true,
                  title: Text(
                    context.tr('dashboard.allCompanions'),
                    style: TextStyle(
                      color: headingColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    context.tr('dashboard.allCompanionsReceive', {
                      'count': widget.pendampings.length,
                    }),
                    style: TextStyle(color: bodyColor, fontSize: 13),
                  ),
                  secondary: const Icon(Icons.groups_rounded),
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
              ],
            ),
          ),
        ),
        if (!_sendToAll) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: const Key('companion_recipient_dropdown'),
            initialValue: _selectedPendampingUid,
            isExpanded: true,
            dropdownColor: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.surfaceWhite,
            style: TextStyle(color: headingColor, fontSize: 17),
            decoration: InputDecoration(
              labelText: context.tr('dashboard.companionName'),
              hintText: context.tr('dashboard.tapToSelect'),
              prefixIcon: const Icon(Icons.support_agent_rounded, size: 27),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.surfaceWhite,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            items: widget.pendampings
                .map(
                  (pendamping) => DropdownMenuItem(
                    value: pendamping.uid,
                    child: Text(
                      pendamping.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _isSending
                ? null
                : (value) => setState(() => _selectedPendampingUid = value),
            validator: (value) {
              if (_kind == CompanionContactKind.message &&
                  !_sendToAll &&
                  value == null) {
                return context.tr('dashboard.chooseCompanionValidation');
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _recipientSummary({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusSafe.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.statusSafe.withValues(alpha: 0.48)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.statusSafe, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: bodyColor, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.statusSafe,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton(
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final position = widget.state.myCurrentPosition.value;
    final hasGps = position != null;
    final active = _includeLocation && hasGps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('dashboard.shareLocationOptional'),
          style: DashboardTypography.labelLarge.copyWith(
            color: headingColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          toggled: active,
          label: active
              ? context.tr('dashboard.locationIncluded')
              : context.tr('dashboard.locationNotIncluded'),
          child: InkWell(
            key: const Key('companion_location_button'),
            onTap: _isFindingLocation || _isSending ? null : _toggleLocation,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 104),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.statusSafe.withValues(
                        alpha: isDark ? 0.18 : 0.09,
                      )
                    : (isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.canvasCream),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? AppColors.statusSafe
                      : const Color(0xFFE64A19),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color:
                          (active
                                  ? AppColors.statusSafe
                                  : const Color(0xFFE64A19))
                              .withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: _isFindingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(15),
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Icon(
                            active
                                ? Icons.location_on_rounded
                                : Icons.add_location_alt_rounded,
                            color: active
                                ? AppColors.statusSafe
                                : const Color(0xFFE64A19),
                            size: 31,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isFindingLocation
                              ? context.tr('dashboard.findingLocation')
                              : active
                              ? context.tr('dashboard.locationWillBeSent')
                              : context.tr('dashboard.tapToSendLocation'),
                          style: TextStyle(
                            color: headingColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          active
                              ? context.tr('dashboard.gpsPointWillBeSent')
                              : hasGps
                              ? context.tr('dashboard.gpsFoundNotIncluded')
                              : context.tr('dashboard.enableGpsAccess'),
                          style: TextStyle(
                            color: bodyColor,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.statusSafe
                          : bodyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      active
                          ? context.tr('dashboard.activeUpper')
                          : context.tr('dashboard.offUpper'),
                      style: TextStyle(
                        color: active ? Colors.white : bodyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 15, color: bodyColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                context.tr('dashboard.locationOnlyWhenActive'),
                style: TextStyle(color: bodyColor, fontSize: 12.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
