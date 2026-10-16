import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_breakpoints.dart';
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

    final colors = context.hc;
    final isDark = colors.isDark;

    return Positioned(
      top: topPadding + 10,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.maxTabletContentWidth,
          ),
          child: Obx(() {
            final instruction = mapCtrl.nextManeuverInstruction.value.isNotEmpty
                ? mapCtrl.nextManeuverInstruction.value
                : context.tr('maps.keepFollowingRoute');
            final distanceMeters = mapCtrl.nextManeuverDistanceMeters.value;
            final icon = mapCtrl.nextManeuverIcon.value;
            final destName = mapCtrl.destinationTitle.value;
            final isVoiceEnabled = mapCtrl.isVoiceGuidanceEnabled.value;

            // Dedicated gold/accent highlight colors matching Prayer Time card
            final goldAccent = isDark ? const Color(0xFFE5C07B) : colors.accent;
            final goldBorder = isDark
                ? const Color(0xFFD4AF37).withValues(alpha: 0.45)
                : colors.accent.withValues(alpha: 0.40);

            return RepaintBoundary(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  // Gradient exactly matches prayer time header card (luxury espresso / royal primary)
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF26180E),
                            Color(0xFF1C1109),
                            Color(0xFF120A05),
                          ]
                        : [
                            colors.primary,
                            const Color(0xFF2E1C12),
                            const Color(0xFF1E140E),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: goldBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : colors.primary.withValues(alpha: 0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // 3D Concentric Geometric Rings (Top-Right Prayer Time signature motif)
                    Positioned(
                      top: -35,
                      right: -35,
                      child: IgnorePointer(
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.03),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Main Content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          // 1. Prominent Large Maneuver Icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(
                                      0xFFD4AF37,
                                    ).withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: goldBorder, width: 1.5),
                            ),
                            child: Icon(icon, size: 30, color: goldAccent),
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
                                      color: Colors.white,
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
                                    color: Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
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
                                        color: goldAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          destName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.text.bodySmall
                                              .copyWith(
                                                color: goldAccent,
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

                          // 3. Audio Guidance Toggle with Frosted Glass Styling
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.35)
                                    : colors.accent.withValues(alpha: 0.30),
                                width: 1.0,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(21),
                                onTap: () {
                                  mapCtrl.isVoiceGuidanceEnabled.toggle();
                                },
                                child: Center(
                                  child: Icon(
                                    isVoiceEnabled
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    color: isVoiceEnabled
                                        ? goldAccent
                                        : Colors.white.withValues(alpha: 0.5),
                                    size: 22,
                                  ),
                                ),
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
          }),
        ),
      ),
    );
  }
}
