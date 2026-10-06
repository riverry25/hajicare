import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../map/controllers/map_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../models/assistance_request_model.dart';
import '../services/assistance_request_service.dart';

/// Card displayed on Pendamping Dashboard when a pilgrim in the group
/// requested assistance (e.g. Tersesat, Terpisah, Butuh Penjemputan).
class PendampingAssistanceCard extends StatelessWidget {
  final AssistanceRequestModel request;
  final bool isDark;

  const PendampingAssistanceCard({
    super.key,
    required this.request,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final service = AssistanceRequestService.instance;

    return Obx(() {
      final currentReq = service.activeRequest.value ?? request;
      final isOnTheWay = currentReq.status == AssistanceStatus.onTheWay;

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : const Color(0xFFFFF7F2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE64A19).withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFE64A19,
              ).withValues(alpha: isDark ? 0.25 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Notifikasi Bantuan + Waktu
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE64A19).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: Color(0xFFE64A19),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Bantuan dari ',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF5D4037),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              currentReq.jamaahName,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2E1C12),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentReq.type.title} · ${currentReq.timeFormatted}',
                        style: const TextStyle(
                          color: Color(0xFFE64A19),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOnTheWay
                        ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                        : const Color(0xFFE64A19).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isOnTheWay ? 'Menuju Lokasi' : 'Baru Masuk',
                    style: TextStyle(
                      color: isOnTheWay
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE64A19),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),

            // Message snippet if present
            if (currentReq.message.isNotEmpty &&
                currentReq.message != currentReq.type.title) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"${currentReq.message}"',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF5D4037),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Location and Destination Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : const Color(0xFFE0DDDA),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentReq.humanLocation,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF2E1C12),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (currentReq.targetHotel.isNotEmpty) ...[
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.hotel_rounded,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tujuan: ${currentReq.targetHotel}${currentReq.targetRoom != null && currentReq.targetRoom!.isNotEmpty ? ' (Kamar ${currentReq.targetRoom})' : ''}',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF5D4037),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _openJamaahLocationOnMap(context, currentReq);
                    },
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: const Text(
                      'Lihat Lokasi',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE64A19),
                      side: const BorderSide(
                        color: Color(0xFFE64A19),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!isOnTheWay) {
                        _handleHeadingToLocation(context, currentReq, service);
                      } else {
                        _confirmCompleteRequest(context, currentReq, service);
                      }
                    },
                    icon: Icon(
                      isOnTheWay
                          ? Icons.check_circle_rounded
                          : Icons.directions_run_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isOnTheWay ? 'Selesaikan' : 'Saya Menuju Lokasi',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOnTheWay
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE64A19),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _handleHeadingToLocation(
    BuildContext context,
    AssistanceRequestModel req,
    AssistanceRequestService service,
  ) async {
    HapticFeedback.mediumImpact();

    String companionName = 'Pendamping';
    String? companionUid;
    if (Get.isRegistered<HajiCareController>()) {
      final state = Get.find<HajiCareController>();
      if (state.self.name.isNotEmpty) {
        companionName = state.self.name;
      }
      companionUid = state.self.id;
    }

    service.dispatchCompanionToLocation(
      requestId: req.id,
      companionName: companionName,
      companionUid: companionUid,
    );

    Get.snackbar(
      'Menuju Lokasi',
      'Status diperbarui: Anda sedang menuju ke lokasi ${req.jamaahName}',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: const Color(0xFF1B120B),
      colorText: Colors.white,
      icon: const Icon(Icons.directions_run_rounded, color: Color(0xFFE64A19)),
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
    );

    _openJamaahLocationOnMap(context, req, autoRoute: true);
  }

  void _confirmCompleteRequest(
    BuildContext context,
    AssistanceRequestModel req,
    AssistanceRequestService service,
  ) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Selesaikan Bantuan?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Apakah Anda sudah bertemu dengan ${req.jamaahName} dan bantuan penjemputan telah selesai?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              service.completeRequest(requestId: req.id);
              AppAlert.success(
                context,
                title: 'Bantuan Selesai',
                message: 'Bantuan untuk ${req.jamaahName} telah diselesaikan.',
              );
            },
            child: const Text(
              'Ya, Selesai',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _openJamaahLocationOnMap(
    BuildContext context,
    AssistanceRequestModel req, {
    bool autoRoute = false,
  }) {
    if (req.latitude == null || req.longitude == null) {
      AppAlert.warning(
        context,
        title: 'Koordinat Tidak Tersedia',
        message:
            'Jamaah ${req.jamaahName} tidak membagikan koordinat GPS. Lokasi perkiraan: ${req.humanLocation}',
      );
      return;
    }

    final mapCtrl = Get.isRegistered<MapController>()
        ? Get.find<MapController>()
        : Get.put(MapController());

    mapCtrl.focusOnAssistanceRequest(req, autoRoute: autoRoute);

    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changeTab(1);
    } else {
      Get.toNamed(AppRoutes.interactiveMap);
    }
  }
}
