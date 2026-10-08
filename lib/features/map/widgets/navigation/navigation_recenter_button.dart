import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_radius.dart';
import '../../controllers/map_controller.dart';

/// Floating "Pusatkan Kembali" (Re-center) button.
/// Automatically appears when user pans or drags the map manually in navigation mode,
/// and re-engages follow mode when pressed.
class NavigationRecenterButton extends StatelessWidget {
  final MapController mapCtrl;

  const NavigationRecenterButton({super.key, required this.mapCtrl});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Obx(() {
      final isFollowing = mapCtrl.isFollowingUser.value;
      if (isFollowing) return const SizedBox.shrink();

      return Positioned(
        bottom: bottomPadding + 300,
        left: 0,
        right: 0,
        child: AnimatedOpacity(
          opacity: !isFollowing ? 1.0 : 0.0,
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF22C55E), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pusatkan Kembali',
                          style: TextStyle(
                            color: Colors.white,
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
    });
  }
}
