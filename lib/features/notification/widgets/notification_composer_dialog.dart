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
  final _targetUserIdController = TextEditingController();

  final NotificationService _notificationService = NotificationService();

  late String _selectedScope;
  String _selectedType = 'announcement'; // 'announcement', 'urgent', 'info'
  String? _selectedTargetUserId;
  String? _selectedTargetUserName;
  String? _selectedRoomId;
  String? _selectedRoomName;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<HajiCareController>();
    final isAdmin = controller.role == UserRole.admin;

    // Determine initial scope
    if (widget.initialScope != null) {
      _selectedScope = widget.initialScope!;
    } else {
      _selectedScope = isAdmin ? 'global' : 'room';
    }

    _selectedTargetUserId = widget.initialTargetUserId;
    _selectedTargetUserName = widget.initialTargetUserName;
    if (_selectedTargetUserId != null) {
      _targetUserIdController.text = _selectedTargetUserId!;
    }

    _selectedRoomId = widget.initialRoomId ?? controller.activeRoomId.value;
    _selectedRoomName =
        widget.initialRoomName ?? controller.activeRoom.value?.name;

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
    _targetUserIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

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
        : (isAdmin ? 'Admin Pusat' : 'Pendamping Room');

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
        targetUserId: _selectedScope == 'user'
            ? (_selectedTargetUserId ?? _targetUserIdController.text.trim())
            : null,
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
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;
    final controller = Get.find<HajiCareController>();
    final isAdmin = controller.role == UserRole.admin;

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.surfaceVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.campaign_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Notifikasi',
                          style: AppTypography.titleMedium.copyWith(
                            color: headingColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isAdmin
                              ? 'Kirim pengumuman resmi'
                              : 'Kirim pesan ke jamaah dalam rombongan',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: bodyColor,
                    onPressed: _isSending
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Scope Selection Section
                      Text(
                        'Pilih Penerima',
                        style: AppTypography.bodySmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildScopeChips(isAdmin, primaryColor, isDark),
                      const SizedBox(height: AppSpacing.md),

                      // Dynamic Scope Inputs
                      _buildDynamicScopeInput(
                        isAdmin,
                        controller,
                        isDark,
                        primaryColor,
                        headingColor,
                        bodyColor,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Notification Type
                      Text(
                        'Kategori Notifikasi',
                        style: AppTypography.bodySmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTypeChips(primaryColor, isDark),
                      const SizedBox(height: AppSpacing.md),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: headingColor),
                        decoration: InputDecoration(
                          labelText: 'Judul Notifikasi *',
                          hintText: 'Contoh: Kumpul di Lobi Hotel Pukul 14.00',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          prefixIcon: const Icon(Icons.title_rounded, size: 20),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Judul wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Message Field
                      TextFormField(
                        controller: _messageController,
                        maxLines: 4,
                        maxLength: 500,
                        style: TextStyle(color: headingColor),
                        decoration: InputDecoration(
                          labelText: 'Isi Pesan *',
                          hintText:
                              'Tuliskan informasi lengkap yang perlu diketahui oleh jamaah...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Pesan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Live Preview Section
                      Text(
                        'Pratinjau Tampilan Jamaah',
                        style: AppTypography.bodySmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
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
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.surfaceVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: bodyColor,
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: _isSending
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      onPressed: _isSending ? null : _handleSend,
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _isSending ? 'Mengirim...' : 'Kirim Notifikasi',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildScopeChips(bool isAdmin, Color primaryColor, bool isDark) {
    final availableScopes = isAdmin
        ? [
            {
              'key': 'global',
              'label': 'Semua Jamaah',
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
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                scope['icon'] as IconData,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextBody : AppColors.textBody),
              ),
              const SizedBox(width: 6),
              Text(
                scope['label'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
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
          onSelected: (selected) {
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
        return ChoiceChip(
          label: Text(
            t['label'] as String,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextBody : AppColors.textBody),
            ),
          ),
          selected: isSelected,
          selectedColor: color,
          backgroundColor: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceVariant,
          onSelected: (selected) {
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
                  'Notifikasi ini akan disiarkan ke SELURUH jamaah yang terdaftar dalam sistem.',
                  style: AppTypography.captionSmall.copyWith(
                    color: headingColor,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'maktab':
        return TextFormField(
          controller: _maktabController,
          style: TextStyle(color: headingColor),
          decoration: InputDecoration(
            labelText: 'Nomor / Nama Maktab *',
            hintText: 'Contoh: Maktab 112 atau Mina 4',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
          ),
          validator: (v) =>
              (_selectedScope == 'maktab' && (v == null || v.trim().isEmpty))
              ? 'Maktab wajib diisi'
              : null,
        );

      case 'kloter':
        return TextFormField(
          controller: _kloterController,
          style: TextStyle(color: headingColor),
          decoration: InputDecoration(
            labelText: 'Kode / Nama Kloter *',
            hintText: 'Contoh: JKG-01, SOC-12',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            prefixIcon: const Icon(Icons.groups_rounded, size: 20),
          ),
          validator: (v) =>
              (_selectedScope == 'kloter' && (v == null || v.trim().isEmpty))
              ? 'Kloter wajib diisi'
              : null,
        );

      case 'room':
        if (!isAdmin) {
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
                        'Notifikasi dikirim ke seluruh jamaah di dalam room ini.',
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
          // Admin can specify Room ID or select
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
            builder: (context, snapshot) {
              final rooms = snapshot.data?.docs ?? [];
              return DropdownButtonFormField<String>(
                initialValue: rooms.any((d) => d.id == _selectedRoomId)
                    ? _selectedRoomId
                    : null,
                dropdownColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceWhite,
                decoration: InputDecoration(
                  labelText: 'Pilih rombongan tujuan *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  prefixIcon: const Icon(Icons.meeting_room_rounded, size: 20),
                ),
                items: rooms.map((doc) {
                  final data = doc.data();
                  final name = data['name'] ?? 'Room ${doc.id}';
                  final code = data['code'] ?? '';
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text(
                      '$name ($code)',
                      style: TextStyle(color: headingColor),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedRoomId = val;
                    final match = rooms.firstWhereOrNull((d) => d.id == val);
                    _selectedRoomName = match?.data()['name'] as String?;
                  });
                },
                validator: (v) =>
                    (_selectedScope == 'room' && (v == null || v.isEmpty))
                    ? 'Pilih rombongan tujuan'
                    : null,
              );
            },
          );
        }

      case 'user':
        if (!isAdmin) {
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
                          'Pilih satu jamaah dari rombongan',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
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

          return DropdownButtonFormField<String>(
            initialValue: members.any((j) => j.id == _selectedTargetUserId)
                ? _selectedTargetUserId
                : null,
            dropdownColor: isDark
                ? AppColors.darkSurfaceContainer
                : AppColors.surfaceWhite,
            decoration: InputDecoration(
              labelText: 'Pilih Jamaah Target *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
            items: members.map((j) {
              return DropdownMenuItem<String>(
                value: j.id,
                child: Text(j.name, style: TextStyle(color: headingColor)),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedTargetUserId = val;
                final match = members.firstWhereOrNull((j) => j.id == val);
                _selectedTargetUserName = match?.name;
              });
            },
            validator: (v) =>
                (_selectedScope == 'user' && (v == null || v.isEmpty))
                ? 'Jamaah target wajib dipilih'
                : null,
          );
        } else {
          // Admin targets specific user via ID or lookup
          return TextFormField(
            controller: _targetUserIdController,
            style: TextStyle(color: headingColor),
            decoration: InputDecoration(
              labelText: 'UID Jamaah / User *',
              hintText: 'Masukkan User UID target',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              prefixIcon: const Icon(Icons.person_rounded, size: 20),
            ),
            validator: (v) =>
                (_selectedScope == 'user' && (v == null || v.trim().isEmpty))
                ? 'Target User ID wajib diisi'
                : null,
          );
        }

      default:
        return const SizedBox.shrink();
    }
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
    String scopeLabel = _selectedScope.toUpperCase();
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
      scopeLabel = 'ROOM';
    } else {
      badgeColor = AppColors.statusSafe;
      scopeLabel = 'LANGSUNG';
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
