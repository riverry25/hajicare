import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../controllers/map_controller.dart';

/// Accessible, high-contrast Top Direction Instruction Card for Navigation Mode.
/// Specially optimized for elderly pilgrims with large typography, bold icons,
/// and clear visual contrast.
class NavigationTopCard extends StatelessWidget {
  final MapController mapCtrl;

  const NavigationTopCard({super.key, required this.mapCtrl});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Obx(() {
        final instruction = mapCtrl.nextManeuverInstruction.value.isNotEmpty
            ? mapCtrl.nextManeuverInstruction.value
            : context.tr('maps.keepFollowingRoute');
        final distanceMeters = mapCtrl.nextManeuverDistanceMeters.value;
        final icon = mapCtrl.nextManeuverIcon.value;
        final destName = mapCtrl.destinationTitle.value;
        final isVoiceEnabled = mapCtrl.isVoiceGuidanceEnabled.value;

        return RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.hc.brandDark, context.hc.brand],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: context.hc.accent.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: context.hc.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. Prominent Large Maneuver Icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: context.hc.accent.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.hc.accent.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, size: 32, color: context.hc.accent),
                ),
                const SizedBox(width: 14),

                // 2. Maneuver Distance & Instruction Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Distance or "Lurus"
                      if (distanceMeters != null)
                        Text(
                          DistanceFormatter.format(distanceMeters),
                          style: context.text.headlineSmall.copyWith(
                            color: context.hc.onPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      // Direction text
                      Text(
                        instruction,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium.copyWith(
                          color: context.hc.onPrimary.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      // Destination subtitle
                      if (destName.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 13,
                              color: context.hc.accent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                destName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall.copyWith(
                                  color: context.hc.accent,
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

                // 3. Audio Guidance Toggle
                IconButton(
                  onPressed: () {
                    mapCtrl.isVoiceGuidanceEnabled.toggle();
                  },
                  tooltip: isVoiceEnabled
                      ? context.tr('maps.muteVoice')
                      : context.tr('maps.unmuteVoice'),
                  icon: Icon(
                    isVoiceEnabled
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: isVoiceEnabled
                        ? context.hc.accent
                        : context.hc.onPrimary.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
