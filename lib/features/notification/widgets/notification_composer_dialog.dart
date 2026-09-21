import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../services/notification_service.dart';

/// Interactive modal dialog for Admin and Pendamping to compose and send notifications
/// tailored to their authority scopes.
class NotificationComposerDialog extends StatefulWidget {
  final String? initialScope;
  final String? initialTargetUserId;
  final String? initialTargetUserName;
  final String? initialRoomId;
  final String? initialRoomName;

  const NotificationComposerDialog({
    super.key,
    this.initialScope,
    this.initialTargetUserId,
    this.initialTargetUserName,
    this.initialRoomId,
    this.initialRoomName,
  });

  /// Shows the composer dialog.
  static Future<void> show(
    BuildContext context, {
    String? initialScope,
    String? initialTargetUserId,
    String? initialTargetUserName,
    String? initialRoomId,
    String? initialRoomName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      useSafeArea: true,
      builder: (ctx) => NotificationComposerDialog(
        initialScope: initialScope,
        initialTargetUserId: initialTargetUserId,
        initialTargetUserName: initialTargetUserName,
        initialRoomId: initialRoomId,
        initialRoomName: initialRoomName,
      ),
    );
  }

  @override
  State<NotificationComposerDialog> createState() =>
      _NotificationComposerDialogState();
}

class _NotificationComposerDialogState
    extends State<NotificationComposerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _maktabController = TextEditingController();
  final _kloterController = TextEditingController();

  final NotificationService _notificationService = NotificationService();

  late String _selectedScope;
  String _selectedType = 'announcement'; // 'announcement', 'urgent', 'info'
  String? _selectedTargetUserId;
  String? _selectedTargetUserName;
  String? _selectedRoomId;
  String? _selectedRoomName;

  bool _isSending = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _usersStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _roomsStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _roomMembersStream;
  String? _roomMembersStreamRoomId;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _boundedUsersStream =>
      _usersStream ??= FirebaseFirestore.instance
          .collection('users')
          .limit(500)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> get _boundedRoomsStream =>
      _roomsStream ??= FirebaseFirestore.instance
          .collection('rooms')
          .limit(200)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _boundedRoomMembersStream(
    String roomId,
  ) {
    if (_roomMembersStream == null || _roomMembersStreamRoomId != roomId) {
      _roomMembersStreamRoomId = roomId;
      _roomMembersStream = FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('members')
          .limit(500)
          .snapshots();
    }
    return _roomMembersStream!;
  }

  @override
  void initState() {
    super.initState();
    final controller = Get.find<HajiCareController>();
    final isAdmin = controller.role == UserRole.admin;

    const adminScopes = {'global', 'maktab', 'kloter', 'room', 'user'};
    const pendampingScopes = {'room', 'user'};
    final allowedScopes = isAdmin ? adminScopes : pendampingScopes;
    final requestedScope = widget.initialScope?.trim().toLowerCase();
    _selectedScope =
        requestedScope != null && allowedScopes.contains(requestedScope)
        ? requestedScope
        : (isAdmin ? 'global' : 'room');

    _selectedTargetUserId = widget.initialTargetUserId;
    _selectedTargetUserName = widget.initialTargetUserName;

    _selectedRoomId = widget.initialRoomId ?? controller.activeRoomId.value;
    _selectedRoomName =
        widget.initialRoomName ?? controller.activeRoom.value?.name;

    if ((_selectedRoomId == null || _selectedRoomId!.isEmpty) && !isAdmin) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance
            .collection('rooms')
            .where('pendampingId', isEqualTo: user.uid)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get()
            .then((snap) {
              if (snap.docs.isNotEmpty &&
                  mounted &&
                  (_selectedRoomId == null || _selectedRoomId!.isEmpty)) {
                setState(() {
                  _selectedRoomId = snap.docs.first.id;
                  _selectedRoomName = snap.docs.first.data()['name'] as String?;
                });
              }
            })
            .catchError((_) {});
      }
    }

    // Listen to updates for live preview
    _titleController.addListener(() => setState(() {}));
    _messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _maktabController.dispose();
    _kloterController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (_isSending) return;
    if (!_formKey.currentState!.validate()) return;

    String? targetMessage;
    if ((_selectedScope == 'room' || _selectedScope == 'user') &&
        (_selectedRoomId == null || _selectedRoomId!.isEmpty)) {
      targetMessage = 'Pilih rombongan tujuan terlebih dahulu.';
    } else if (_selectedScope == 'user' &&
        (_selectedTargetUserId == null || _selectedTargetUserId!.isEmpty)) {
      targetMessage = 'Pilih nama jamaah yang akan menerima pesan.';
    } else if (_selectedScope == 'maktab' &&
        _maktabController.text.trim().isEmpty) {
      targetMessage = 'Pilih maktab tujuan terlebih dahulu.';
    } else if (_selectedScope == 'kloter' &&
        _kloterController.text.trim().isEmpty) {
      targetMessage = 'Pilih kloter tujuan terlebih dahulu.';
    }
    if (targetMessage != null) {
      AppAlert.warning(
        context,
        title: 'Penerima Belum Dipilih',
        message: targetMessage,
      );
      return;
    }

    final controller = Get.find<HajiCareController>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppAlert.error(
        context,
        title: 'Silakan Masuk Kembali',
        message: 'Waktu masuk Anda sudah berakhir. Silakan masuk kembali.',
      );
      return;
    }

    final isAdmin = controller.role == UserRole.admin;
    final senderRole = isAdmin ? 'admin' : 'pendamping';
    final senderName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!
        : (isAdmin ? 'Admin Pusat' : 'Pendamping Rombongan');

    setState(() => _isSending = true);

    try {
      final recipientCount = await _notificationService.sendNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        senderUid: user.uid,
        senderRole: senderRole,
        senderName: senderName,
        scope: _selectedScope,
        type: _selectedType,
        targetUserId: _selectedScope == 'user' ? _selectedTargetUserId : null,
        targetRoomId: (_selectedScope == 'room' || _selectedScope == 'user')
            ? _selectedRoomId
            : null,
        targetMaktab: _selectedScope == 'maktab'
            ? _maktabController.text.trim()
            : null,
        targetKloter: _selectedScope == 'kloter'
            ? _kloterController.text.trim()
            : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      AppDialog.success(
        title: 'Pesan Terkirim',
        message: 'Pesan sudah dikirim kepada $recipientCount orang.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      AppDialog.error(
        context: context,
        title: 'Pesan Belum Terkirim',
        message: UserFeedbackMessage.from(
          e,
          fallback: 'Pesan belum terkirim. Periksa isinya, lalu coba lagi.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final primaryColor = isDark ? AppColors.goldLight : AppColors.goldPrimary;
    final controller = Get.find<HajiCareController>();
    final isAdmin = controller.role == UserRole.admin;
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height -
        media.viewInsets.bottom -
        media.padding.vertical -
        24;
    final maxDialogHeight = availableHeight.clamp(280.0, 760.0).toDouble();
    final horizontalInset = media.size.width < 360 ? 8.0 : 16.0;

    return PopScope(
      canPop: !_isSending,
      child: Dialog(
        key: const Key('notification_composer_dialog'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(
          horizontal: horizontalInset,
          vertical: 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: maxDialogHeight,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 34, left: 4, right: 4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppColors.goldLight.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.45 : 0.18,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const SizedBox(height: 70),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const Key('notification_composer_scroll'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Buat Notifikasi',
                                style: AppTypography.titleMedium.copyWith(
                                  color: headingColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isAdmin
                                    ? 'Sampaikan informasi resmi kepada penerima yang Anda pilih.'
                                    : 'Sampaikan informasi penting kepada jamaah dalam rombongan Anda.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: bodyColor,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildSectionTitle(
                                icon: Icons.people_alt_outlined,
                                title: 'Pilih Penerima',
                                headingColor: headingColor,
                              ),
                              const SizedBox(height: 10),
                              _buildScopeChips(isAdmin, primaryColor, isDark),
                              const SizedBox(height: AppSpacing.md),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: KeyedSubtree(
                                  key: ValueKey(_selectedScope),
                                  child: _buildDynamicScopeInput(
                                    isAdmin,
                                    controller,
                                    isDark,
                                    primaryColor,
                                    headingColor,
                                    bodyColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              _buildSectionTitle(
                                icon: Icons.label_outline_rounded,
                                title: 'Kategori Pesan',
                                headingColor: headingColor,
                              ),
                              const SizedBox(height: 10),
                              _buildTypeChips(primaryColor, isDark),
                              const SizedBox(height: AppSpacing.xl),
                              _buildSectionTitle(
                                icon: Icons.edit_note_rounded,
                                title: 'Tulis Pesan',
                                headingColor: headingColor,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                key: const Key('notification_title_field'),
                                controller: _titleController,
                                enabled: !_isSending,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                maxLength: 80,
                                style: TextStyle(
                                  color: headingColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _underlineInputDecoration(
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                  hintText: 'Misalnya: Waktu Berkumpul',
                                ).copyWith(counterText: ''),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Isi judul pesan terlebih dahulu.'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                key: const Key('notification_message_field'),
                                controller: _messageController,
                                enabled: !_isSending,
                                minLines: 4,
                                maxLines: 7,
                                maxLength: 500,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.newline,
                                style: TextStyle(color: headingColor),
                                decoration: _outlinedInputDecoration(
                                  isDark: isDark,
                                  primaryColor: primaryColor,
                                  labelText: 'Isi pesan *',
                                  hintText:
                                      'Tuliskan waktu, lokasi, dan arahan dengan jelas.',
                                  alignLabelWithHint: true,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Isi pesan terlebih dahulu.'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              _buildPreviewDisclosure(
                                isDark: isDark,
                                primaryColor: primaryColor,
                                headingColor: headingColor,
                                bodyColor: bodyColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildFooter(
                      isDark: isDark,
                      primaryColor: primaryColor,
                      headingColor: headingColor,
                      bodyColor: bodyColor,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 18,
                right: 18,
                height: 96,
                child: _buildHeroHeader(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  onClose: _isSending
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader({
    required bool isDark,
    required Color primaryColor,
    required VoidCallback? onClose,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF3B281C), const Color(0xFF21160F)]
              : [AppColors.espressoDark, const Color(0xFF5B3C28)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.48),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.espressoDark.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            Positioned(right: -22, top: -28, child: _buildHeaderGlow(86, 0.13)),
            Positioned(
              left: -20,
              bottom: -34,
              child: _buildHeaderGlow(78, 0.08),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.16),
                      border: Border.all(
                        color: AppColors.goldPrimary.withValues(alpha: 0.55),
                      ),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: AppColors.goldAccent,
                      size: 23,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'PESAN UNTUK JAMAAH',
                    style: TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                tooltip: 'Tutup',
                onPressed: onClose,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                iconSize: 21,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderGlow(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.goldPrimary.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Color headingColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 19, color: headingColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _underlineInputDecoration({
    required bool isDark,
    required Color primaryColor,
    required String hintText,
  }) {
    final idleColor = isDark ? AppColors.darkOutline : const Color(0xFFD1C2B5);
    return InputDecoration(
      labelText: 'Judul pesan *',
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? Colors.white54 : AppColors.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: idleColor, width: 1.2),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.sosEmergency, width: 1.4),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.sosEmergency, width: 2),
      ),
    );
  }

  InputDecoration _outlinedInputDecoration({
    required bool isDark,
    required Color primaryColor,
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    final borderColor = isDark
        ? AppColors.darkOutline
        : AppColors.outlineVariant;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 21),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: primaryColor, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildPreviewDisclosure({
    required bool isDark,
    required Color primaryColor,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          key: const Key('notification_preview_expansion'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 4),
          leading: Icon(
            Icons.visibility_outlined,
            color: primaryColor,
            size: 21,
          ),
          title: Text(
            'Lihat tampilan pesan',
            style: AppTypography.bodySmall.copyWith(
              color: headingColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            'Pratinjau yang akan dilihat jamaah',
            style: AppTypography.captionSmall.copyWith(color: bodyColor),
          ),
          children: [
            _buildLivePreviewCard(
              context,
              isDark,
              primaryColor,
              headingColor,
              bodyColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter({
    required bool isDark,
    required Color primaryColor,
    required Color headingColor,
    required Color bodyColor,
  }) {
    final dividerColor = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant.withValues(alpha: 0.65);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final stackButtons = constraints.maxWidth < 330 || textScale > 1.35;
          final cancelButton = OutlinedButton(
            key: const Key('notification_cancel_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: bodyColor,
              minimumSize: const Size(0, 50),
              side: BorderSide(color: dividerColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: _isSending ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          );
          final sendButton = ElevatedButton.icon(
            key: const Key('notification_send_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.goldPrimary,
              foregroundColor: isDark ? headingColor : Colors.white,
              disabledBackgroundColor: primaryColor.withValues(alpha: 0.45),
              minimumSize: const Size(0, 50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: _isSending ? null : _handleSend,
            icon: _isSending
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 19),
            label: Text(
              _isSending ? 'Sedang Mengirim...' : 'Kirim Notifikasi',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );

          if (stackButtons) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [sendButton, const SizedBox(height: 8), cancelButton],
            );
          }
          return Row(
            children: [
              Expanded(child: cancelButton),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: sendButton),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScopeChips(bool isAdmin, Color primaryColor, bool isDark) {
    final availableScopes = isAdmin
        ? [
            {
              'key': 'global',
              'label': 'Semua Pengguna',
              'icon': Icons.public_rounded,
            },
            {
              'key': 'maktab',
              'label': 'Maktab',
              'icon': Icons.apartment_rounded,
            },
            {'key': 'kloter', 'label': 'Kloter', 'icon': Icons.groups_rounded},
            {
              'key': 'room',
              'label': 'Satu Rombongan',
              'icon': Icons.meeting_room_outlined,
            },
            {
              'key': 'user',
              'label': 'Satu Jamaah',
              'icon': Icons.person_rounded,
            },
          ]
        : [
            {
              'key': 'room',
              'label': 'Semua di Rombongan',
              'icon': Icons.meeting_room_outlined,
            },
            {
              'key': 'user',
              'label': 'Jamaah Tertentu',
              'icon': Icons.person_rounded,
            },
          ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableScopes.map((scope) {
        final isSelected = _selectedScope == scope['key'];
        final selectedContentColor =
            ThemeData.estimateBrightnessForColor(primaryColor) ==
                Brightness.dark
            ? Colors.white
            : AppColors.espressoDark;
        return ChoiceChip(
          showCheckmark: false,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                scope['icon'] as IconData,
                size: 15,
                color: isSelected
                    ? selectedContentColor
                    : (isDark ? AppColors.darkTextBody : AppColors.textBody),
              ),
              const SizedBox(width: 6),
              Text(
                scope['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? selectedContentColor
                      : (isDark ? AppColors.darkTextBody : AppColors.textBody),
                ),
              ),
            ],
          ),
          selected: isSelected,
          selectedColor: primaryColor,
          backgroundColor: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceVariant,
          onSelected: _isSending
              ? null
              : (selected) {
                  if (selected) {
                    setState(() => _selectedScope = scope['key'] as String);
                  }
                },
        );
      }).toList(),
    );
  }

  Widget _buildTypeChips(Color primaryColor, bool isDark) {
    final types = [
      {'key': 'announcement', 'label': 'Pengumuman', 'color': primaryColor},
      {
        'key': 'urgent',
        'label': 'Penting / Mendesak',
        'color': AppColors.statusCaution,
      },
      {'key': 'info', 'label': 'Informasi', 'color': AppColors.statusSafe},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final isSelected = _selectedType == t['key'];
        final color = t['color'] as Color;
        final selectedContentColor =
            ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : AppColors.espressoDark;
        return ChoiceChip(
          showCheckmark: false,
          label: Text(
            t['label'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? selectedContentColor
                  : (isDark ? AppColors.darkTextBody : AppColors.textBody),
            ),
          ),
          selected: isSelected,
          selectedColor: color,
          backgroundColor: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceVariant,
          onSelected: _isSending
              ? null
              : (selected) {
                  if (selected) {
                    setState(() => _selectedType = t['key'] as String);
                  }
                },
        );
      }).toList(),
    );
  }

  Widget _buildDynamicScopeInput(
    bool isAdmin,
    HajiCareController controller,
    bool isDark,
    Color primaryColor,
    Color headingColor,
    Color bodyColor,
  ) {
    switch (_selectedScope) {
      case 'global':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusSafe.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.statusSafe.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.statusSafe,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pesan akan dikirim kepada semua pengguna yang terdaftar. Periksa kembali isinya sebelum mengirim.',
                  style: AppTypography.captionSmall.copyWith(
                    color: headingColor,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'maktab':
        return _buildGroupPicker(
          field: 'maktab',
          label: 'Pilih maktab tujuan *',
          emptyMessage: 'Belum ada maktab yang dapat dipilih.',
          controller: _maktabController,
          icon: Icons.apartment_rounded,
          isDark: isDark,
          primaryColor: primaryColor,
          headingColor: headingColor,
          bodyColor: bodyColor,
        );

      case 'kloter':
        return _buildGroupPicker(
          field: 'kloter',
          label: 'Pilih kloter tujuan *',
          emptyMessage: 'Belum ada kloter yang dapat dipilih.',
          controller: _kloterController,
          icon: Icons.groups_rounded,
          isDark: isDark,
          primaryColor: primaryColor,
          headingColor: headingColor,
          bodyColor: bodyColor,
        );

      case 'room':
        if (!isAdmin) {
          if (_selectedRoomId == null || _selectedRoomId!.isEmpty) {
            return _buildDataStateCard(
              icon: Icons.info_outline_rounded,
              message:
                  'Anda belum terhubung ke rombongan. Hubungkan rombongan sebelum mengirim pesan.',
              isDark: isDark,
              primaryColor: primaryColor,
              bodyColor: bodyColor,
            );
          }
          // Pendamping is locked to active room
          final rName =
              _selectedRoomName ??
              controller.activeRoom.value?.name ??
              'Rombongan Anda';
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.canvasCream,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.meeting_room_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rombongan tujuan: $rName',
                        style: AppTypography.bodySmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pesan dikirim ke seluruh jamaah dalam rombongan ini.',
                        style: AppTypography.captionSmall.copyWith(
                          color: bodyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return _buildAdminRoomPicker(
            isDark: isDark,
            primaryColor: primaryColor,
            headingColor: headingColor,
            bodyColor: bodyColor,
          );
        }

      case 'user':
        if (!isAdmin) {
          if (_selectedRoomId == null || _selectedRoomId!.isEmpty) {
            return _buildDataStateCard(
              icon: Icons.info_outline_rounded,
              message:
                  'Anda belum terhubung ke rombongan. Hubungkan rombongan untuk memilih jamaah.',
              isDark: isDark,
              primaryColor: primaryColor,
              bodyColor: bodyColor,
            );
          }
          // Pendamping picks from current room's Jamaah
          final members = controller.jamaahList;
          if (_selectedTargetUserId != null &&
              _selectedTargetUserName != null) {
            // Already pre-targeted from detail sheet
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.canvasCream,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: primaryColor,
                    child: Text(
                      _selectedTargetUserName!.isNotEmpty
                          ? _selectedTargetUserName![0].toUpperCase()
                          : 'J',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedTargetUserName!,
                          style: AppTypography.bodySmall.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pesan hanya dikirim kepada jamaah ini.',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _isSending
                        ? null
                        : () {
                            setState(() {
                              _selectedTargetUserId = null;
                              _selectedTargetUserName = null;
                            });
                          },
                    child: const Text('Ganti', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          }

          if (members.isEmpty) {
            return _buildDataStateCard(
              icon: Icons.person_off_outlined,
              message: 'Belum ada jamaah dalam rombongan ini.',
              isDark: isDark,
              primaryColor: primaryColor,
              bodyColor: bodyColor,
            );
          }

          return DropdownButtonFormField<String>(
            initialValue: members.any((j) => j.id == _selectedTargetUserId)
                ? _selectedTargetUserId
                : null,
            dropdownColor: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.surfaceWhite,
            isExpanded: true,
            decoration: _outlinedInputDecoration(
              isDark: isDark,
              primaryColor: primaryColor,
              labelText: 'Pilih nama jamaah *',
              prefixIcon: Icons.person_outline_rounded,
            ),
            items: members.map((j) {
              return DropdownMenuItem<String>(
                value: j.id,
                child: Text(
                  j.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: headingColor),
                ),
              );
            }).toList(),
            onChanged: _isSending
                ? null
                : (val) {
                    setState(() {
                      _selectedTargetUserId = val;
                      final match = members.firstWhereOrNull(
                        (j) => j.id == val,
                      );
                      _selectedTargetUserName = match?.name;
                    });
                  },
            validator: (v) =>
                (_selectedScope == 'user' && (v == null || v.isEmpty))
                ? 'Pilih nama jamaah terlebih dahulu.'
                : null,
          );
        } else {
          return _buildAdminUserPicker(
            isDark: isDark,
            primaryColor: primaryColor,
            headingColor: headingColor,
            bodyColor: bodyColor,
          );
        }

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGroupPicker({
    required String field,
    required String label,
    required String emptyMessage,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _boundedUsersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildDataStateCard(
            icon: Icons.wifi_off_rounded,
            message: 'Daftar tujuan belum dapat dimuat. Coba lagi sebentar.',
            isDark: isDark,
            primaryColor: primaryColor,
            bodyColor: bodyColor,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingField('Memuat daftar tujuan...', bodyColor);
        }

        final values =
            snapshot.data?.docs
                .map((doc) => doc.data()[field]?.toString().trim() ?? '')
                .where((value) => value.isNotEmpty)
                .toSet()
                .toList() ??
            <String>[];
        values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        if (values.isEmpty) {
          return _buildDataStateCard(
            icon: Icons.info_outline_rounded,
            message: emptyMessage,
            isDark: isDark,
            primaryColor: primaryColor,
            bodyColor: bodyColor,
          );
        }

        final selectedValue = values.contains(controller.text)
            ? controller.text
            : null;
        return DropdownButtonFormField<String>(
          key: ValueKey('$field-${values.join('|')}'),
          initialValue: selectedValue,
          isExpanded: true,
          dropdownColor: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceWhite,
          decoration: _outlinedInputDecoration(
            isDark: isDark,
            primaryColor: primaryColor,
            labelText: label,
            prefixIcon: icon,
          ),
          items: values
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: headingColor),
                  ),
                ),
              )
              .toList(),
          onChanged: _isSending
              ? null
              : (value) {
                  setState(() => controller.text = value ?? '');
                },
          validator: (value) => value == null || value.isEmpty
              ? 'Pilih tujuan pesan terlebih dahulu.'
              : null,
        );
      },
    );
  }

  Widget _buildAdminRoomPicker({
    required bool isDark,
    required Color primaryColor,
    required Color headingColor,
    required Color bodyColor,
    bool resetTargetUserOnChange = true,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _boundedRoomsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildDataStateCard(
            icon: Icons.wifi_off_rounded,
            message: 'Daftar rombongan belum dapat dimuat. Coba lagi sebentar.',
            isDark: isDark,
            primaryColor: primaryColor,
            bodyColor: bodyColor,
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return _buildLoadingField('Memuat daftar rombongan...', bodyColor);
        }

        final rooms =
            (snapshot.data?.docs ?? [])
                .where((doc) => doc.data()['isActive'] != false)
                .toList()
              ..sort((a, b) {
                final aName = a.data()['name']?.toString() ?? '';
                final bName = b.data()['name']?.toString() ?? '';
                return aName.toLowerCase().compareTo(bName.toLowerCase());
              });
        if (rooms.isEmpty) {
          return _buildDataStateCard(
            icon: Icons.meeting_room_outlined,
            message: 'Belum ada rombongan aktif yang dapat dipilih.',
            isDark: isDark,
            primaryColor: primaryColor,
            bodyColor: bodyColor,
          );
        }

        final selectedValue = rooms.any((doc) => doc.id == _selectedRoomId)
            ? _selectedRoomId
            : null;
        return DropdownButtonFormField<String>(
          key: ValueKey('room-${rooms.map((doc) => doc.id).join('|')}'),
          initialValue: selectedValue,
          isExpanded: true,
          dropdownColor: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceWhite,
          decoration: _outlinedInputDecoration(
            isDark: isDark,
            primaryColor: primaryColor,
            labelText: 'Pilih rombongan tujuan *',
            prefixIcon: Icons.meeting_room_rounded,
          ),
          items: rooms.map((doc) {
            final data = doc.data();
            final name = data['name']?.toString().trim();
            final code = data['code']?.toString().trim();
            final displayName = name == null || name.isEmpty
                ? 'Rombongan'
                : name;
            final displayText = code == null || code.isEmpty
                ? displayName
                : '$displayName • $code';
            return DropdownMenuItem<String>(
              value: doc.id,
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: headingColor),
              ),
            );
          }).toList(),
          onChanged: _isSending
              ? null
              : (value) {
                  setState(() {
                    _selectedRoomId = value;
                    final match = rooms.firstWhereOrNull(
                      (doc) => doc.id == value,
                    );
                    _selectedRoomName = match?.data()['name']?.toString();
                    if (resetTargetUserOnChange) {
                      _selectedTargetUserId = null;
                      _selectedTargetUserName = null;
                    }
                  });
                },
          validator: (value) => value == null || value.isEmpty
              ? 'Pilih rombongan tujuan terlebih dahulu.'
              : null,
        );
      },
    );
  }

  Widget _buildAdminUserPicker({
    required bool isDark,
    required Color primaryColor,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAdminRoomPicker(
          isDark: isDark,
          primaryColor: primaryColor,
          headingColor: headingColor,
          bodyColor: bodyColor,
        ),
        const SizedBox(height: 12),
        if (_selectedRoomId == null || _selectedRoomId!.isEmpty)
          _buildDataStateCard(
            icon: Icons.touch_app_rounded,
            message: 'Pilih rombongan lebih dulu untuk melihat nama jamaah.',
            isDark: isDark,
            primaryColor: primaryColor,
            bodyColor: bodyColor,
          )
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _boundedRoomMembersStream(_selectedRoomId!),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildDataStateCard(
                  icon: Icons.wifi_off_rounded,
                  message:
                      'Daftar jamaah belum dapat dimuat. Coba lagi sebentar.',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  bodyColor: bodyColor,
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return _buildLoadingField('Memuat daftar jamaah...', bodyColor);
              }

              final members =
                  (snapshot.data?.docs ?? []).where((doc) {
                    final role = doc.data()['role']?.toString().toLowerCase();
                    return role == null || role.isEmpty || role == 'jamaah';
                  }).toList()..sort((a, b) {
                    final aName = a.data()['name']?.toString() ?? '';
                    final bName = b.data()['name']?.toString() ?? '';
                    return aName.toLowerCase().compareTo(bName.toLowerCase());
                  });
              if (members.isEmpty) {
                return _buildDataStateCard(
                  icon: Icons.person_off_outlined,
                  message: 'Belum ada jamaah dalam rombongan ini.',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  bodyColor: bodyColor,
                );
              }

              final selectedValue =
                  members.any((doc) => doc.id == _selectedTargetUserId)
                  ? _selectedTargetUserId
                  : null;
              return DropdownButtonFormField<String>(
                key: ValueKey(
                  'member-$_selectedRoomId-${members.map((doc) => doc.id).join('|')}',
                ),
                initialValue: selectedValue,
                isExpanded: true,
                dropdownColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceWhite,
                decoration: _outlinedInputDecoration(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  labelText: 'Pilih nama jamaah *',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                items: members.map((doc) {
                  final name = doc.data()['name']?.toString().trim();
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      name == null || name.isEmpty ? 'Jamaah' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: headingColor),
                    ),
                  );
                }).toList(),
                onChanged: _isSending
                    ? null
                    : (value) {
                        setState(() {
                          _selectedTargetUserId = value;
                          final match = members.firstWhereOrNull(
                            (doc) => doc.id == value,
                          );
                          _selectedTargetUserName = match
                              ?.data()['name']
                              ?.toString();
                        });
                      },
                validator: (value) => value == null || value.isEmpty
                    ? 'Pilih nama jamaah terlebih dahulu.'
                    : null,
              );
            },
          ),
      ],
    );
  }

  Widget _buildLoadingField(String message, Color bodyColor) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(color: bodyColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStateCard({
    required IconData icon,
    required String message,
    required bool isDark,
    required Color primaryColor,
    required Color bodyColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.canvasCream.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: primaryColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: bodyColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCard(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color headingColor,
    Color bodyColor,
  ) {
    final titleText = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Judul Notifikasi Anda';
    final messageText = _messageController.text.trim().isNotEmpty
        ? _messageController.text.trim()
        : 'Isi ringkasan notifikasi akan tampil di sini seperti yang dilihat jamaah.';

    Color badgeColor;
    String scopeLabel = 'SEMUA PENGGUNA';
    if (_selectedScope == 'global') {
      badgeColor = primaryColor;
    } else if (_selectedScope == 'maktab') {
      badgeColor = AppColors.statusCaution;
      scopeLabel =
          'MAKTAB ${_maktabController.text.trim().isNotEmpty ? _maktabController.text.trim() : ""}';
    } else if (_selectedScope == 'kloter') {
      badgeColor = AppColors.statusCaution;
      scopeLabel =
          'KLOTER ${_kloterController.text.trim().isNotEmpty ? _kloterController.text.trim() : ""}';
    } else if (_selectedScope == 'room') {
      badgeColor = primaryColor;
      scopeLabel = 'ROMBONGAN';
    } else {
      badgeColor = AppColors.statusSafe;
      scopeLabel = 'PRIBADI';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? AppColors.darkOutlineVariant
              : AppColors.surfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  scopeLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Baru saja',
                style: AppTypography.captionSmall.copyWith(
                  color: bodyColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            titleText,
            style: AppTypography.bodyMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            messageText,
            style: AppTypography.bodySmall.copyWith(
              color: bodyColor,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
