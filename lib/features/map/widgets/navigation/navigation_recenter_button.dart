import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/locales/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/theme_context.dart';
import '../../controllers/map_controller.dart';

/// Floating "Pusatkan Kembali" (Re-center) button.
/// Automatically appears when user pans or drags the map manually in navigation mode
/// and re-engages follow mode when pressed.
class NavigationRecenterButton extends StatelessWidget {
  final MapController mapCtrl;

  const NavigationRecenterButton({super.key, required this.mapCtrl});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Positioned must stay a direct child of the parent Stack, so Obx only
    // wraps the content (avoids "Incorrect use of ParentDataWidget").
    return Positioned(
      bottom: bottomPadding + 330,
      left: 0,
      right: 0,
      child: Obx(() {
        final isVisible = !mapCtrl.isFollowingUser.value;

        return IgnorePointer(
          ignoring: !isVisible,
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Center(
              child: RepaintBoundary(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: mapCtrl.recenterNavigation,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.hc.success,
                            context.hc.success.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: context.hc.onPrimary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.hc.success.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.navigation_rounded,
                            color: context.hc.onPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('maps.recenter'),
                            style: TextStyle(
                              color: context.hc.onPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
