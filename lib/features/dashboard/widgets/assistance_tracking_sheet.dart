import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../map/controllers/map_controller.dart';
import '../models/assistance_request_model.dart';
import '../presentation/dashboard_typography.dart';
import '../services/assistance_request_service.dart';

/// Bottom sheet view displaying real-time assistance request lifecycle tracking:
/// Terkirim -> Diterima Pendamping -> Sedang Menuju Lokasi -> Selesai.
class AssistanceTrackingSheet extends StatelessWidget {
  final AssistanceRequestModel request;
  final VoidCallback? onCompleted;
  final VoidCallback? onBack;

  const AssistanceTrackingSheet({
    super.key,
    required this.request,
    this.onCompleted,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final service = AssistanceRequestService.instance;
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);

    return Obx(() {
      final current = service.activeRequest.value ?? request;
      final isCompleted = current.status == AssistanceStatus.completed;

      return Container(
        key: const Key('assistance_tracking_sheet'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.cardPadding,
            16,
            AppSpacing.cardPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Status
              _buildHeader(current, isDark, headingColor, bodyColor),
              const SizedBox(height: 20),

              // Status Lifecycle Progress Timeline
              _buildLifecycleTimeline(current, isDark, headingColor, bodyColor),
              const SizedBox(height: 20),

              // Detail Bantuan Card
              _buildRequestDetailsCard(
                current,
                isDark,
                headingColor,
                bodyColor,
              ),
              const SizedBox(height: 22),

              // Selesaikan Request: "Apakah Anda sudah bersama pendamping?"
              if (!isCompleted) ...[
                _buildCompletionSection(
                  context,
                  service,
                  current,
                  isDark,
                  headingColor,
                  bodyColor,
                ),
                const SizedBox(height: 18),
              ] else ...[
                _buildCompletedSuccessBanner(context, isDark, headingColor),
                const SizedBox(height: 18),
              ],

              // Actions: Lihat Lokasi di Peta & Hubungi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('tracking_view_location_button'),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Get.back();
                        if (Get.isRegistered<MapController>()) {
                          Get.toNamed(AppRoutes.interactiveMap);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkCardBorder
                              : const Color(0xFFD7CCC8),
                        ),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 20),
                      label: const Text(
                        'Lihat di Peta',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isCompleted)
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('tracking_cancel_button'),
                        onPressed: () => _confirmCancel(context, service),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          foregroundColor: AppColors.sosEmergency,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: AppColors.sosEmergency.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: const Text(
                          'Batalkan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),

              // Demo / Simulator Pendamping baris pembantu
              if (!isCompleted) ...[
                const SizedBox(height: 24),
                _buildCompanionSimulatorToolbar(
                  service,
                  current,
                  isDark,
                  bodyColor,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(
    AssistanceRequestModel current,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final isDone = current.status == AssistanceStatus.completed;
    final isEnRoute = current.status == AssistanceStatus.onTheWay;

    final Color badgeColor = isDone
        ? const Color(0xFF16A34A)
        : isEnRoute
        ? const Color(0xFF0284C7)
        : const Color(0xFFE64A19);

    final IconData badgeIcon = isDone
        ? Icons.check_circle_rounded
        : isEnRoute
        ? Icons.directions_walk_rounded
        : Icons.notifications_active_rounded;

    final String titleText = isDone
        ? 'Bantuan Telah Selesai'
        : isEnRoute
        ? 'Pendamping Menuju Lokasi'
        : 'Permintaan Bantuan Terkirim';

    final String subtitleText = isDone
        ? 'Alhamdulillah, Anda sudah terhubung dengan pendamping.'
        : isEnRoute
        ? 'Pendamping sedang bergerak ke tempat Anda. Tetap di posisi.'
        : 'Pendamping Anda telah diberi tahu. Tetap tenang dan tunggu di lokasi.';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Icon(badgeIcon, color: badgeColor, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleText,
                style: DashboardTypography.titleMedium.copyWith(
                  color: headingColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitleText,
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifecycleTimeline(
    AssistanceRequestModel current,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final status = current.status;

    final bool step1Active = true;
    final bool step2Active =
        status == AssistanceStatus.acknowledged ||
        status == AssistanceStatus.onTheWay ||
        status == AssistanceStatus.completed;
    final bool step3Active =
        status == AssistanceStatus.onTheWay ||
        status == AssistanceStatus.completed;
    final bool step4Active = status == AssistanceStatus.completed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.canvasCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 20,
                color: Color(0xFFE64A19),
              ),
              const SizedBox(width: 8),
              Text(
                'STATUS PERMINTAAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: headingColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _timelineStep(
            title: 'Permintaan terkirim',
            time: _formatTime(current.createdAt),
            isDone: step1Active,
            isCurrent: status == AssistanceStatus.sent,
            headingColor: headingColor,
            bodyColor: bodyColor,
          ),
          _timelineConnector(step2Active),
          _timelineStep(
            title: 'Diterima pendamping',
            time: current.acknowledgedAt != null
                ? _formatTime(current.acknowledgedAt!)
                : (step2Active ? 'Dikonfirmasi' : 'Menunggu respons'),
            isDone: step2Active,
            isCurrent: status == AssistanceStatus.acknowledged,
            headingColor: headingColor,
            bodyColor: bodyColor,
          ),
          _timelineConnector(step3Active),
          _timelineStep(
            title: 'Pendamping menuju lokasi',
            time: current.onTheWayAt != null
                ? _formatTime(current.onTheWayAt!)
                : (step3Active ? 'Dalam perjalanan' : 'Menunggu persiapan'),
            isDone: step3Active,
            isCurrent: status == AssistanceStatus.onTheWay,
            headingColor: headingColor,
            bodyColor: bodyColor,
          ),
          _timelineConnector(step4Active),
          _timelineStep(
            title: 'Bantuan selesai',
            time: current.completedAt != null
                ? _formatTime(current.completedAt!)
                : (step4Active ? 'Selesai' : 'Belum selesai'),
            isDone: step4Active,
            isCurrent: status == AssistanceStatus.completed,
            headingColor: headingColor,
            bodyColor: bodyColor,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required String time,
    required bool isDone,
    required bool isCurrent,
    required Color headingColor,
    required Color bodyColor,
    bool isLast = false,
  }) {
    final Color stepColor = isDone
        ? const Color(0xFF16A34A)
        : (isCurrent
              ? const Color(0xFFE64A19)
              : bodyColor.withValues(alpha: 0.4));

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: stepColor.withValues(
              alpha: isDone || isCurrent ? 0.15 : 0.08,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: stepColor, width: 2),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check_rounded, size: 16, color: stepColor)
                : Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCurrent ? stepColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: isCurrent || isDone
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: isDone || isCurrent
                  ? headingColor
                  : bodyColor.withValues(alpha: 0.6),
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isCurrent
                ? const Color(0xFFE64A19)
                : bodyColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _timelineConnector(bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      width: 2,
      height: 14,
      color: isActive
          ? const Color(0xFF16A34A)
          : Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _buildRequestDetailsCard(
    AssistanceRequestModel current,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceContainer : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(current.type.icon, size: 22, color: const Color(0xFFE64A19)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  current.type.title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: headingColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: bodyColor.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.place_rounded,
            label: 'Lokasi Anda',
            value: current.humanReadableLocation,
            iconColor: const Color(0xFFE64A19),
            headingColor: headingColor,
            bodyColor: bodyColor,
          ),
          const SizedBox(height: 10),
          _infoRow(
            icon: Icons.hotel_rounded,
            label: 'Tujuan Hotel',
            value:
                '${current.targetHotel}${current.targetRoom != null ? " • ${current.targetRoom}" : ""}',
            iconColor: const Color(0xFF8E24AA),
            headingColor: headingColor,
            bodyColor: bodyColor,
          ),
          if (current.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Pesan Tambahan',
              value: current.message,
              iconColor: const Color(0xFF0284C7),
              headingColor: headingColor,
              bodyColor: bodyColor,
            ),
          ],
          const SizedBox(height: 10),
          _infoRow(
            icon: Icons.support_agent_rounded,
            label: 'Penerima Bantuan',
            value: current.sendToAll
                ? 'Semua Pendamping Rombongan'
                : (current.assignedPendampingName ?? 'Pendamping'),
            iconColor: const Color(0xFF16A34A),
            headingColor: headingColor,
            bodyColor: bodyColor,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required Color headingColor,
    required Color bodyColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: bodyColor.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: headingColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionSection(
    BuildContext context,
    AssistanceRequestService service,
    AssistanceRequestModel current,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF16A34A).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Apakah Anda sudah bersama pendamping?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: headingColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tekan tombol di bawah jika Anda sudah bertemu dengan pendamping.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: bodyColor),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              key: const Key('tracking_complete_button'),
              onPressed: () {
                HapticFeedback.heavyImpact();
                service.completeRequest();
                onCompleted?.call();
                AppAlert.success(
                  context,
                  title: 'Bantuan Selesai',
                  message:
                      'Anda sudah terhubung dengan pendamping. Berbagi lokasi dihentikan.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 24),
              label: const Text(
                'Ya, Saya Sudah Ditemukan',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedSuccessBanner(
    BuildContext context,
    bool isDark,
    Color headingColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Bantuan Selesai',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: headingColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Anda sudah aman bersama pendamping. Berbagi lokasi dihentikan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              AssistanceRequestService.instance.clearActiveRequest();
              Get.back();
            },
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionSimulatorToolbar(
    AssistanceRequestService service,
    AssistanceRequestModel current,
    bool isDark,
    Color bodyColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.developer_mode_rounded,
                size: 15,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Text(
                'SIMULASI RESPON PENDAMPING (TEST FLOW)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: bodyColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                key: const Key('sim_acknowledge_button'),
                avatar: const Icon(Icons.mark_email_read_rounded, size: 16),
                label: const Text(
                  'Pendamping Terima',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  service.acknowledgeRequest();
                },
              ),
              ActionChip(
                key: const Key('sim_on_the_way_button'),
                avatar: const Icon(Icons.directions_run_rounded, size: 16),
                label: const Text(
                  'Menuju Lokasi',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  service.dispatchCompanionToLocation();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, AssistanceRequestService service) {
    AppAlert.confirm(
      context,
      title: 'Batalkan Permintaan?',
      message: 'Apakah Anda yakin ingin membatalkan permintaan bantuan ini?',
      confirmText: 'Ya, Batalkan',
      cancelText: 'Kembali',
      isDestructive: true,
      onConfirm: () {
        service.cancelRequest();
        Get.back();
      },
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
