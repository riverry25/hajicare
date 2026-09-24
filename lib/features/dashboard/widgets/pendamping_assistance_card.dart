import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/routes/app_routes.dart';
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
    final isOnTheWay = request.status == AssistanceStatus.onTheWay;

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
                            request.jamaahName,
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
                      '${request.type.title} · ${request.timeFormatted}',
                      style: TextStyle(
                        color: const Color(0xFFE64A19),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
          if (request.message.isNotEmpty &&
              request.message != request.type.title) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"${request.message}"',
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
                        request.humanLocation,
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
                if (request.targetHotel.isNotEmpty) ...[
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
                          'Tujuan: ${request.targetHotel}${request.targetRoom != null && request.targetRoom!.isNotEmpty ? ' (Kamar ${request.targetRoom})' : ''}',
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
                    _openJamaahLocationOnMap(request);
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
                    HapticFeedback.mediumImpact();
                    if (!isOnTheWay) {
                      service.dispatchCompanionToLocation(
                        companionName: 'Pendamping',
                      );
                    } else {
                      service.completeRequest();
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
  }

  void _openJamaahLocationOnMap(AssistanceRequestModel req) {
    if (Get.isRegistered<MapController>()) {
      final mapCtrl = Get.find<MapController>();
      if (req.latitude != null && req.longitude != null) {
        mapCtrl.flutterMapController.move(
          LatLng(req.latitude!, req.longitude!),
          17.0,
        );
      }
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changeTab(1);
    } else {
      Get.toNamed(AppRoutes.interactiveMap);
    }
  }
}
