import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_translations.dart';
import '../../../core/theme/theme_context.dart';
import '../models/assistance_request_model.dart';
import 'companion_contact_sheet.dart';

/// Reassuring banner displayed on the Jamaah's dashboard whenever
/// they have an active assistance request in progress.
class JamaahActiveAssistanceBanner extends StatelessWidget {
  final AssistanceRequestModel request;
  final bool isDark;

  const JamaahActiveAssistanceBanner({
    super.key,
    required this.request,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = request.status.badgeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.hc.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.hc.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: context.hc.warning.withValues(
              alpha: context.hc.isDark ? 0.2 : 0.08,
            ),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.hc.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  request.type.icon,
                  color: context.hc.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('dashboard.assistanceInProgress'),
                      style: TextStyle(
                        color: context.hc.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.type.title,
                      style: TextStyle(
                        color: context.hc.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      request.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.hc.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.hc.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.near_me_rounded,
                  size: 16,
                  color: context.hc.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.humanLocation,
                    style: TextStyle(
                      color: context.hc.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                Get.bottomSheet<void>(
                  CompanionContactSheet(
                    roomId: request.roomId,
                    pendampings: const [],
                    state: Get.find(),
                  ),
                  isScrollControlled: true,
                  ignoreSafeArea: false,
                  enableDrag: false,
                );
              },
              icon: const Icon(Icons.track_changes_rounded, size: 18),
              label: Text(
                context.tr('dashboard.viewAssistanceStatus'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.hc.primary,
                foregroundColor: context.hc.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
