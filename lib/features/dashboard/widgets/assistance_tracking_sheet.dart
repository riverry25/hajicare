import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/dashboard_controller.dart';
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
    final hc = context.hc;
    final isDark = hc.isDark;
    final headingColor = hc.textPrimary;
    final bodyColor = hc.textSecondary;

    return Obx(() {
      final current = service.activeRequest.value ?? request;
      final isCompleted = current.status == AssistanceStatus.completed;

      return Container(
        key: const Key('assistance_tracking_sheet'),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: hc.surface,
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
              _buildHeader(context, current, isDark, headingColor, bodyColor),
              const SizedBox(height: 20),

              // Status Lifecycle Progress Timeline
              _buildLifecycleTimeline(
                context,
                current,
                isDark,
                headingColor,
                bodyColor,
              ),
              const SizedBox(height: 20),

              // Detail Bantuan Card
              _buildRequestDetailsCard(
                context,
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
                        if (Get.isRegistered<DashboardController>()) {
                          Get.find<DashboardController>().changeTab(1);
                        } else {
                          Get.toNamed(AppRoutes.interactiveMap);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: isDark ? hc.borderStrong : hc.borderSubtle,
                        ),
                        foregroundColor: isDark ? hc.textPrimary : headingColor,
                      ),
                      icon: Icon(
                        Icons.map_rounded,
                        size: 20,
                        color: isDark ? hc.accent : hc.primary,
                      ),
                      label: Text(
                        context.tr('viewOnMap'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
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
                          foregroundColor: hc.danger,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: hc.danger.withValues(
                              alpha: isDark ? 0.6 : 0.4,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        label: Text(
                          context.tr('assistanceCancelAction'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(
    BuildContext context,
    AssistanceRequestModel current,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final hc = context.hc;
    final isDone = current.status == AssistanceStatus.completed;
    final isEnRoute = current.status == AssistanceStatus.onTheWay;

    final Color badgeColor = isDone
        ? hc.success
        : isEnRoute
        ? hc.info
        : (isDark ? hc.accent : hc.primary);

    final IconData badgeIcon = isDone
        ? Icons.check_circle_rounded
        : isEnRoute
        ? Icons.directions_walk_rounded
        : Icons.notifications_active_rounded;

    final String titleText = isDone
        ? context.tr('assistanceTrackingTitleDone')
        : isEnRoute
        ? context.tr('assistanceTrackingTitleEnRoute')
        : context.tr('assistanceTrackingTitleSent');

    final String subtitleText = isDone
        ? context.tr('assistanceTrackingSubDone')
        : isEnRoute
        ? context.tr('assistanceTrackingSubEnRoute')
        : context.tr('assistanceTrackingSubSent');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: isDark ? 0.22 : 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: badgeColor.withValues(alpha: isDark ? 0.5 : 0.35),
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
                  color: isDark ? hc.textSecondary : bodyColor,
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
    BuildContext context,
    AssistanceRequestModel current,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final hc = context.hc;
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
        color: isDark ? hc.surfaceSubtle : hc.surfaceSand,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? hc.borderStrong : hc.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 20,
                color: isDark ? hc.accent : hc.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('assistanceStatusRequestHeader'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark
                      ? hc.textSecondary
                      : headingColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _timelineStep(
            title: context.tr('assistanceRequestSent'),
            time: _formatTime(current.createdAt),
            isDone: step1Active,
            isCurrent: status == AssistanceStatus.sent,
            headingColor: headingColor,
            bodyColor: isDark ? hc.textSecondary : bodyColor,
            stepColor: step1Active && status != AssistanceStatus.sent
                ? hc.success
                : (status == AssistanceStatus.sent
                      ? (isDark ? hc.accent : hc.primary)
                      : (isDark
                            ? hc.borderStrong
                            : bodyColor.withValues(alpha: 0.4))),
            timeColor: status == AssistanceStatus.sent
                ? (isDark ? hc.accent : hc.primary)
                : (isDark
                      ? hc.textSecondary
                      : bodyColor.withValues(alpha: 0.7)),
          ),
          _timelineConnector(
            step2Active,
            hc.success,
            isDark ? hc.border : hc.borderSubtle,
          ),
          _timelineStep(
            title: context.tr('assistanceTimelineAccepted'),
            time: current.acknowledgedAt != null
                ? _formatTime(current.acknowledgedAt!)
                : (step2Active
                      ? context.tr('assistanceStatusConfirmed')
                      : context.tr('assistanceStatusWaitingResponse')),
            isDone: step2Active,
            isCurrent: status == AssistanceStatus.acknowledged,
            headingColor: headingColor,
            bodyColor: isDark ? hc.textSecondary : bodyColor,
            stepColor: step2Active && status != AssistanceStatus.acknowledged
                ? hc.success
                : (status == AssistanceStatus.acknowledged
                      ? (isDark ? hc.accent : hc.primary)
                      : (isDark
                            ? hc.borderStrong
                            : bodyColor.withValues(alpha: 0.4))),
            timeColor: status == AssistanceStatus.acknowledged
                ? (isDark ? hc.accent : hc.primary)
                : (isDark
                      ? hc.textSecondary
                      : bodyColor.withValues(alpha: 0.7)),
          ),
          _timelineConnector(
            step3Active,
            hc.success,
            isDark ? hc.border : hc.borderSubtle,
          ),
          _timelineStep(
            title: context.tr('assistanceTimelineEnRoute'),
            time: current.onTheWayAt != null
                ? _formatTime(current.onTheWayAt!)
                : (step3Active
                      ? context.tr('assistanceStatusInTransit')
                      : context.tr('assistanceStatusPreparing')),
            isDone: step3Active,
            isCurrent: status == AssistanceStatus.onTheWay,
            headingColor: headingColor,
            bodyColor: isDark ? hc.textSecondary : bodyColor,
            stepColor: step3Active && status != AssistanceStatus.onTheWay
                ? hc.success
                : (status == AssistanceStatus.onTheWay
                      ? (isDark ? hc.accent : hc.primary)
                      : (isDark
                            ? hc.borderStrong
                            : bodyColor.withValues(alpha: 0.4))),
            timeColor: status == AssistanceStatus.onTheWay
                ? (isDark ? hc.accent : hc.primary)
                : (isDark
                      ? hc.textSecondary
                      : bodyColor.withValues(alpha: 0.7)),
          ),
          _timelineConnector(
            step4Active,
            hc.success,
            isDark ? hc.border : hc.borderSubtle,
          ),
          _timelineStep(
            title: context.tr('assistanceTimelineFinished'),
            time: current.completedAt != null
                ? _formatTime(current.completedAt!)
                : (step4Active
                      ? context.tr('assistanceStatusFinished')
                      : context.tr('assistanceStatusNotFinished')),
            isDone: step4Active,
            isCurrent: status == AssistanceStatus.completed,
            headingColor: headingColor,
            bodyColor: isDark ? hc.textSecondary : bodyColor,
            stepColor: step4Active
                ? hc.success
                : (isDark ? hc.borderStrong : bodyColor.withValues(alpha: 0.4)),
            timeColor: status == AssistanceStatus.completed
                ? (isDark ? hc.accent : hc.primary)
                : (isDark
                      ? hc.textSecondary
                      : bodyColor.withValues(alpha: 0.7)),
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
    required Color stepColor,
    required Color timeColor,
    bool isLast = false,
  }) {
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
            color: timeColor,
          ),
        ),
      ],
    );
  }

  Widget _timelineConnector(
    bool isActive,
    Color activeColor,
    Color inactiveColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      width: 2,
      height: 14,
      color: isActive ? activeColor : inactiveColor,
    );
  }

  Widget _buildRequestDetailsCard(
    BuildContext context,
    AssistanceRequestModel current,
    bool isDark,
    Color headingColor,
    Color bodyColor,
  ) {
    final hc = context.hc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? hc.surfaceSubtle : hc.surfaceSand,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? hc.borderStrong : hc.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                current.type.icon,
                size: 22,
                color: isDark ? hc.accent : hc.primary,
              ),
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
          Divider(height: 1, color: isDark ? hc.border : hc.borderSubtle),
          const SizedBox(height: 12),
          _infoRow(
            icon: Icons.place_rounded,
            label: context.tr('assistanceYourLocation'),
            value: current.humanReadableLocation,
            iconColor: isDark ? hc.accent : hc.primary,
            headingColor: headingColor,
            bodyColor: isDark ? hc.textSecondary : bodyColor,
          ),
          const SizedBox(height: 10),
          _infoRow(
            icon: Icons.hotel_rounded,
            label: context.tr('assistanceYourDestination'),
            value:
                '${current.targetHotel}${current.targetRoom != null ? " • ${current.targetRoom}" : ""}',
            iconColor: isDark ? hc.accentText : hc.sandDark,
            headingColor: headingColor,
            bodyColor: isDark ? hc.textSecondary : bodyColor,
          ),
          if (current.message.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoRow(
              icon: Icons.chat_bubble_outline_rounded,
              label: context.tr('assistanceAdditionalMessage'),
              value: current.message,
              iconColor: hc.info,
              headingColor: headingColor,
              bodyColor: isDark ? hc.textSecondary : bodyColor,
            ),
          ],
          const SizedBox(height: 10),
          _infoRow(
            icon: Icons.support_agent_rounded,
            label: context.tr('assistanceRecipientLabel'),
            value: current.sendToAll
                ? context.tr('assistanceAllGroupCompanions')
                : (current.assignedPendampingName ??
                      context.tr('dashboard.officerFallback')),
            iconColor: hc.success,
            headingColor: headingColor,
            bodyColor: isDark ? hc.textSecondary : bodyColor,
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
    final hc = context.hc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? hc.successContainer : const Color(0xFFF0F9F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hc.success.withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            context.tr('assistanceAreYouWithCompanion'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFD4EED9) : headingColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('assistancePressBelowIfMet'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? const Color(0xFFA5CEAE) : bodyColor,
            ),
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
                  title: context.tr('assistanceConfirmDoneTitle'),
                  message: context.tr('assistanceConfirmDoneDesc'),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: hc.success,
                foregroundColor: isDark ? hc.onSuccess : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 24),
              label: Text(
                context.tr('assistanceFoundButton'),
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
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
    final hc = context.hc;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? hc.successContainer : const Color(0xFFF0F9F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: hc.success, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: hc.success, size: 40),
          const SizedBox(height: 8),
          Text(
            context.tr('assistanceConfirmDoneTitle'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFD4EED9) : headingColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('assistanceCompletedSafeBanner'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFA5CEAE) : hc.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              AssistanceRequestService.instance.clearActiveRequest();
              Get.back();
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark ? hc.accentText : hc.primary,
            ),
            child: Text(
              context.tr('close'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, AssistanceRequestService service) {
    AppAlert.confirm(
      context,
      title: context.tr('assistanceCancelPromptTitle'),
      message: context.tr('assistanceCancelPromptDesc'),
      confirmText: context.tr('assistanceYesCancel'),
      cancelText: context.tr('assistanceBack'),
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
