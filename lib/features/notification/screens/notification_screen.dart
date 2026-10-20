import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../models/notification_model.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_composer_dialog.dart';
import '../../../core/routes/app_routes.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final text = context.text;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colors.canvas,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          scrolledUnderElevation: 1,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Notifikasi & Bantuan',
            style: text.titleLarge.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          actions: [
            Obx(() {
              if (!Get.isRegistered<NotificationController>()) {
                return const SizedBox.shrink();
              }
              final ctrl = Get.find<NotificationController>();
              final unread = ctrl.unreadCount.value;
              final hasNotifs = ctrl.notifications.isNotEmpty;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tandai semua dibaca
                  if (unread > 0)
                    IconButton(
                      icon: Icon(
                        Icons.done_all_rounded,
                        color: colors.accentText,
                        size: 22,
                      ),
                      tooltip: 'Tandai Semua Dibaca',
                      onPressed: () => ctrl.markAllAsRead(),
                    ),
                  // Hapus semua notifikasi (soft-delete per user
                  if (hasNotifs)
                    IconButton(
                      icon: Icon(
                        Icons.delete_sweep_rounded,
                        color: colors.accentText,
                        size: 22,
                      ),
                      tooltip: 'Hapus Semua Notifikasi',
                      onPressed: () => _showClearAllDialog(context, ctrl),
                    ),
                ],
              );
            }),
            if (Get.isRegistered<HajiCareController>() &&
                (Get.find<HajiCareController>().role == UserRole.admin ||
                    Get.find<HajiCareController>().role == UserRole.pendamping))
              IconButton(
                icon: Icon(Icons.campaign_rounded, color: colors.accentText),
                tooltip: 'Buat Notifikasi',
                onPressed: () => NotificationComposerDialog.show(context),
              ),
          ],
          // Tab labels are structural chrome (fixed-width tab bar).
          // Disable text scaling so the icon+text rows never overflow.
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight - 8),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: MediaQuery.textScalerOf(
                  context,
                ).clamp(maxScaleFactor: 1.15),
              ),
              child: TabBar(
                indicatorColor: colors.accent,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: colors.textPrimary,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: text.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: text.titleSmall.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Notifikasi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Obx(() {
                          if (!Get.isRegistered<NotificationController>()) {
                            return const SizedBox.shrink();
                          }
                          final count =
                              Get.find<NotificationController>()
                                  .unreadCount
                                  .value +
                              Get.find<NotificationController>()
                                  .pendingInvitations
                                  .length;
                          if (count > 0) {
                            return Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.danger,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                  const Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.help_outline_rounded, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'FAQ & Bantuan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: ResponsiveCenter(
          maxWidth: AppBreakpoints.maxTabletContentWidth,
          child: TabBarView(
            children: [_buildNotificationTab(context), _buildFaqList(context)],
          ),
        ),
      ),
    );
  }

  /// Tampilkan bottom-sheet konfirmasi sebelum menghapus semua notifikasi.
  /// Penghapusan bersifat soft-delete per-user: notifikasi hanya hilang dari
  /// daftar USER INI; pengguna lain yang belum menghapus tetap melihatnya.
  void _showClearAllDialog(BuildContext context, NotificationController ctrl) {
    final colors = context.hc;
    final text = context.text;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxSheetWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.dangerContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_sweep_rounded,
                color: colors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            // Judul
            Text(
              'Hapus Semua Notifikasi?',
              style: text.headlineSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // Keterangan
            Text(
              'Semua notifikasi akan dihapus dari daftar Anda.\n'
              'Pengguna lain yang menerima notifikasi yang sama tidak akan terpengaruh.',
              style: text.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // Tombol aksi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.danger,
                      foregroundColor: colors.onDanger,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ctrl.clearAllNotifications();
                    },
                    child: const Text(
                      'Hapus Semua',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTab(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final colors = context.hc;

    return Obx(() {
      final invitations = controller.pendingInvitations;
      final pendingInvitationIds = invitations.map((item) => item.id).toSet();
      final realNotifs = controller.notifications
          .where(
            (item) =>
                item.relatedId == null ||
                !pendingInvitationIds.contains(item.relatedId),
          )
          .toList(growable: false);

      if (controller.isLoading.value &&
          realNotifs.isEmpty &&
          invitations.isEmpty) {
        return Center(child: CircularProgressIndicator(color: colors.accent));
      }

      if (realNotifs.isEmpty && invitations.isEmpty) {
        return _buildEmptyState(context);
      }

      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            sliver: SliverMainAxisGroup(
              slivers: [
                // 1. Pending Room Invitations Section
                if (invitations.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildSectionHeader(
                        context,
                        'UNDANGAN ROOM MASUK (${invitations.length})',
                        Icons.mark_email_unread_rounded,
                        color: colors.accentText,
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: invitations.length,
                    itemBuilder: (context, i) =>
                        _buildInvitationCard(context, invitations[i]),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.md),
                  ),
                ],

                // 2. Real Firestore Notifications Section
                if (realNotifs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _buildSectionHeader(
                        context,
                        'NOTIFIKASI TERKINI',
                        Icons.notifications_active_rounded,
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: realNotifs.length,
                    itemBuilder: (context, i) => RepaintBoundary(
                      child: _buildFirestoreNotificationCard(
                        context,
                        realNotifs[i],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.hc;
    final text = context.text;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 40,
                  color: colors.accent,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.tr('notification.emptyNotifications'),
              style: text.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Semua pemberitahuan dan informasi penting rombongan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: text.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(BuildContext context, RoomInvitationModel inv) {
    final controller = Get.find<NotificationController>();
    final colors = context.hc;
    final text = context.text;
    final isProcessing = controller.processingInvitations.contains(inv.id);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.6),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.group_add_rounded,
                    color: colors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'UNDANGAN ROOM BARU',
                          style: text.labelSmall.copyWith(
                            color: colors.accentText,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        inv.roomName,
                        style: text.titleMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pendamping "${inv.fromUserName}" mengundang Anda untuk bergabung ke dalam room pemantauan jamaah.',
              style: text.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.surfaceSand,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Kode Room: ${inv.roomCode}',
                style: text.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Buttons (Terima & Tolak
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.danger,
                      side: BorderSide(
                        color: colors.danger.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      minimumSize: const Size(0, 42),
                    ),
                    onPressed: isProcessing
                        ? null
                        : () => controller.rejectInvitation(
                            context: context,
                            invitation: inv,
                          ),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      minimumSize: const Size(0, 42),
                      elevation: 0,
                    ),
                    onPressed: isProcessing
                        ? null
                        : () => controller.acceptInvitation(
                            context: context,
                            invitation: inv,
                          ),
                    child: isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Terima Undangan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirestoreNotificationCard(
    BuildContext context,
    AppNotificationModel notif,
  ) {
    final colors = context.hc;
    IconData icon = Icons.notifications_rounded;
    Color iconColor = colors.accent;
    String category = notif.type.replaceAll('_', ' ').toUpperCase();
    final latitude = (notif.metadata?['latitude'] as num?)?.toDouble();
    final longitude = (notif.metadata?['longitude'] as num?)?.toDouble();
    final hasSharedLocation = latitude != null && longitude != null;

    if (notif.isRoomRemoved) {
      icon = Icons.person_remove_rounded;
      iconColor = colors.danger;
      category = 'DIKELUARKAN DARI ROOM';
    } else if (notif.isRoomDeleted) {
      icon = Icons.delete_forever_rounded;
      iconColor = colors.danger;
      category = 'ROMBONGAN DIHAPUS';
    } else if (notif.isMemberLeft) {
      icon = Icons.person_remove_outlined;
      iconColor = colors.warning;
      category = 'JAMAAH KELUAR';
    } else if (notif.isRoomJoined) {
      icon = Icons.check_circle_outline_rounded;
      iconColor = colors.success;
      category = 'UNDANGAN DITERIMA';
    } else if (notif.isPickupRequest) {
      icon = Icons.hail_rounded;
      iconColor = colors.warning;
      category = 'PERMINTAAN JEMPUT';
    } else if (notif.isCompanionInfo) {
      icon = Icons.campaign_rounded;
      iconColor = colors.accent;
      category = 'INFORMASI JAMAAH';
    } else if (notif.isCompanionMessage) {
      icon = Icons.chat_bubble_rounded;
      iconColor = colors.success;
      category = 'PESAN JAMAAH';
    } else if (notif.isAnnouncement) {
      icon = Icons.campaign_rounded;
      iconColor = colors.accent;
      final scopeStr = notif.scope?.trim().toUpperCase();
      category = scopeStr != null && scopeStr.isNotEmpty
          ? 'PENGUMUMAN $scopeStr'
          : 'PENGUMUMAN';
    } else if (notif.type == 'sos_alert') {
      icon = Icons.emergency_rounded;
      iconColor = colors.danger;
      category = 'SOS DARURAT';
    } else if (notif.type == 'room_invitation') {
      icon = Icons.mail_outline_rounded;
      iconColor = colors.accent;
      category = 'UNDANGAN ROOM';
    }

    return Dismissible(
      key: Key('notif_${notif.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.danger,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        if (Get.isRegistered<NotificationController>()) {
          Get.find<NotificationController>().deleteNotification(notif.id);
        }
      },
      child: _buildNotificationCard(
        context: context,
        category: category,
        icon: icon,
        iconColor: iconColor,
        title: notif.title,
        message: notif.message,
        time: notif.createdAt != null
            ? '${notif.createdAt!.hour.toString().padLeft(2, '0')}:${notif.createdAt!.minute.toString().padLeft(2, '0')}'
            : 'Baru saja',
        isUnread: !notif.isRead,
        onLocationTap: hasSharedLocation
            ? () => _openSharedLocation(context, latitude, longitude)
            : null,
        onTap: () {
          if (!notif.isRead && Get.isRegistered<NotificationController>()) {
            Get.find<NotificationController>().markNotificationRead(notif.id);
          }
          if (notif.isSosAlert) {
            Get.toNamed(AppRoutes.modalSos);
          }
        },
      ),
    );
  }

  Future<void> _openSharedLocation(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      AppAlert.error(
        context,
        title: context.tr('notification.mapOpenFailed'),
        message: 'Pastikan aplikasi peta tersedia, lalu coba lagi.',
      );
    }
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    Color? color,
  }) {
    final colors = context.hc;
    final text = context.text;
    final effectiveColor = color ?? colors.textSecondary;
    return Row(
      children: [
        Icon(icon, size: 14, color: effectiveColor),
        const SizedBox(width: 6),
        Text(
          title,
          style: text.labelSmall.copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required String category,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
    VoidCallback? onTap,
    VoidCallback? onLocationTap,
  }) {
    final colors = context.hc;
    final text = context.text;
    final isDark = context.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isUnread
                    ? colors.accent.withValues(alpha: 0.6)
                    : colors.border,
                width: isUnread ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? colors.shadow.withValues(alpha: 0.2)
                      : colors.shadow.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md + 5,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Circular Icon Avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: iconColor.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(icon, color: iconColor, size: 22),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row: Category Badge + Time Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: text.labelSmall.copyWith(
                                        color: iconColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        time,
                                        style: text.labelSmall.copyWith(
                                          color: colors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (isUnread) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: colors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Text(
                                title,
                                style: text.titleSmall.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: isUnread
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Message body
                              Text(
                                message,
                                style: text.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                              if (onLocationTap != null) ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: OutlinedButton.icon(
                                    key: const Key(
                                      'notification_open_location_button',
                                    ),
                                    onPressed: onLocationTap,
                                    icon: const Icon(
                                      Icons.location_on_rounded,
                                      size: 21,
                                    ),
                                    label: const Text(
                                      'Buka Lokasi Jamaah',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.success,
                                      side: BorderSide(
                                        color: colors.success,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnread)
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      width: 5,
                      child: ColoredBox(color: colors.accent),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqList(BuildContext context) {
    final colors = context.hc;
    final text = context.text;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primaryContainer, colors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: colors.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Panduan & Bantuan',
                      style: text.titleSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ketuk salah satu pertanyaan di bawah untuk membaca panduan praktis dan jelas.',
                      style: text.labelSmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // FAQ Items
        _buildFaqItem(
          context: context,
          icon: Icons.meeting_room_rounded,
          question: 'Bagaimana cara bergabung ke Room Pemantauan?',
          answer:
              'Jamaah dapat bergabung dengan dua cara: (1) Meminta pendamping untuk mengirimkan undangan via email lalu menerima undangan di tab Notifikasi ini, atau (2) Meminta 6 digit kode room dari pendamping lalu memasukkannya melalui menu "Gabung Room".',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.emergency_rounded,
          question: 'Bagaimana cara menggunakan tombol SOS darurat?',
          answer:
              'Pastikan Anda telah bergabung ke dalam Room. Tekan dan tahan tombol SOS berwarna merah di dashboard selama 3 detik. Aplikasi akan mengirimkan sinyal bahaya dan koordinat GPS akurat Anda secara real-time ke smartphone pendamping.',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.watch_rounded,
          question: 'Apakah gelang pintar tahan terhadap air?',
          answer:
              'Ya, gelang pintar dirancang dengan sertifikasi tahan air aman digunakan saat berwudhu, mandi, maupun terkena keringat. Namun harap tidak dipakai saat berenang atau menyelam dalam air bertekanan tinggi.',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.map_rounded,
          question: 'Bagaimana jika saya terpisah dari rombongan?',
          answer:
              'Jangan panik. Tetap di tempat aman yang mudah terlihat. Buka menu Peta Interaktif untuk melihat jalur menuju posko/tenda, atau tekan tombol Hubungi Pendamping agar pendamping langsung melihat posisi Anda di peta.',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.currency_exchange_rounded,
          question: 'Bagaimana cara mengecek uang Riyal dengan kamera?',
          answer:
              'Pilih menu Deteksi Uang Riyal di dashboard. Arahkan kamera ke lembaran uang kertas SAR Arab Saudi secara mendatar di bawah pencahayaan cukup. Aplikasi akan menyebutkan nominal uang secara otomatis lewat suara.',
        ),
        _buildFaqItem(
          context: context,
          icon: Icons.translate_rounded,
          question: 'Cara mengganti bahasa atau memperbesar teks?',
          answer:
              'Buka menu Profil di pojok kanan bawah. Anda dapat mengatur Ukuran Teks (Normal, Besar, Sangat Besar) untuk memudahkan membaca, serta memilih Bahasa (Indonesia, Arab, Inggris).',
        ),

        const SizedBox(height: AppSpacing.xl),

        // Emergency Footer
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.dangerContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: colors.danger.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_in_talk_rounded,
                  color: colors.danger,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hotline Maktab Indonesia: 800-119-999',
                  style: text.labelSmall.copyWith(
                    color: colors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required IconData icon,
    required String question,
    required String answer,
  }) {
    final colors = context.hc;
    final text = context.text;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: colors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colors.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: colors.primaryContainer,
            highlightColor: colors.surfaceSand,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: colors.accent, size: 20),
            ),
            title: Text(
              question,
              style: text.titleSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            iconColor: colors.accent,
            collapsedIconColor: colors.textSecondary,
            childrenPadding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  answer,
                  style: text.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
