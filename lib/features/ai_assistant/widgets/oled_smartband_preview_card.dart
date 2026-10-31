import 'package:flutter/material.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../models/oled_display_state.dart';
import '../models/sensor_context.dart';
import '../services/oled_text_formatter.dart';

/// Widget **OLED Smartband Live Preview (SSD1306 128x64)** dengan indikator
/// titik LED hijau yang menyala saat payload `"AI:<teks>"` dikirim ke gelang.
class OledSmartbandPreviewCard extends StatelessWidget {
  const OledSmartbandPreviewCard({
    super.key,
    required this.oledState,
    required this.isLedActive,
    required this.bleStatus,
    required this.heartRateBpm,
  });

  final OledDisplayState oledState;
  final bool isLedActive;
  final SmartbandLinkStatus bleStatus;
  final int heartRateBpm;

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final cleanText = OledTextFormatter.sanitize(oledState.text);
    final payload =
        oledState.payload ?? OledTextFormatter.buildPayload(cleanText);
    final lines = OledTextFormatter.wrap(
      cleanText.isEmpty ? context.tr('ai.oledReadyDefault') : cleanText,
      width: OledTextFormatter.charsPerLine,
    );
    final isBleConnected = bleStatus == SmartbandLinkStatus.connected;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hc.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: hc.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris judul modul & indikator LED hijau
            Row(
              children: [
                const Icon(
                  Icons.watch_rounded,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.tr('ai.oledCardTitle'),
                    style: context.text.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: hc.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _GreenLedIndicator(isActive: isLedActive),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Bezel & Layar Monokrom SSD1306 128x64
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF05080B),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isLedActive
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF2B3640),
                  width: 1.6,
                ),
                boxShadow: [
                  if (isLedActive)
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.22),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris kuning/biru atas khas modul Dual-Color SSD1306
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          isBleConnected
                              ? 'HCG-001 BLE:ON HR:${heartRateBpm > 0 ? heartRateBpm : "--"}'
                              : 'HCG-001 BLE:OFF HR:--',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFACC15),
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${cleanText.length}/${OledTextFormatter.maxLength}c',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(height: 1, color: Color(0xFF1E293B)),
                  ),
                  // Area Piksel Monokrom Putih 128x48
                   ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final line in lines.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              line,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13.5,
                                height: 1.25,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF8FAFC),
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Footer Payload BLE RX
            Row(
              children: [
                Icon(
                  oledState.isDeliveredToBand
                      ? Icons.bluetooth_connected_rounded
                      : Icons.visibility_rounded,
                  size: 14,
                  color: oledState.isDeliveredToBand
                      ? hc.success
                      : hc.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Payload RX: "$payload"',
                    style: context.text.labelSmall.copyWith(
                      fontFamily: 'monospace',
                      color: hc.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: (oledState.isDeliveredToBand
                            ? hc.success
                            : hc.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    oledState.isDeliveredToBand
                        ? context.tr('ai.oledDeliveredBle')
                        : context.tr('ai.oledDisconnectedBle'),
                    style: context.text.labelSmall.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: oledState.isDeliveredToBand
                          ? hc.success
                          : hc.primary,
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
}

class _GreenLedIndicator extends StatelessWidget {
  const _GreenLedIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    const activeGreen = Color(0xFF22C55E);
    const idleGreen = Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isActive ? activeGreen : idleGreen).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: (isActive ? activeGreen : idleGreen).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: isActive ? activeGreen : idleGreen,
              shape: BoxShape.circle,
              boxShadow: [
                if (isActive)
                  const BoxShadow(
                    color: activeGreen,
                    blurRadius: 8,
                    spreadRadius: 1.5,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'LED ON' : 'LED IDLE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isActive ? activeGreen : context.hc.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

