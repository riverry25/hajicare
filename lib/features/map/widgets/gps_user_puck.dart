import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/theme_context.dart';
import '../controllers/map_controller.dart';

/// Google Maps-style dynamic GPS user location puck.
/// Features
/// 1. Smooth 360° rotation following device compass (when stationary) & travel heading (when walking).
/// 2. Iconic directional beam / cone of light (field of view) radiating forward when stationary.
/// 3. Sharp, high-contrast navigation chevron arrow when walking/moving.
/// 4. Shortest-path unwrapped angle calculation preventing 0°/360° spin-around.
class GpsUserPuck extends StatefulWidget {
  final MapController mapCtrl;
  final bool isNavigating;

  const GpsUserPuck({
    super.key,
    required this.mapCtrl,
    this.isNavigating = false,
  });

  @override
  State<GpsUserPuck> createState() => _GpsUserPuckState();
}

class _GpsUserPuckState extends State<GpsUserPuck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Unwrapped continuous angle tracking to avoid spinning backward around North (359° -> 1°
  double _currentContinuousAngle = 0.0;
  double _lastRawHeading = 0.0;
  bool _hasInitialHeading = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Calculates the shortest angular difference (-180° to +180°
  double _shortestAngleDiff(double from, double to) {
    return (to - from + 540.0) % 360.0 - 180.0;
  }

  double _getContinuousAngle(double rawHeading) {
    if (!_hasInitialHeading) {
      _hasInitialHeading = true;
      _currentContinuousAngle = rawHeading;
      _lastRawHeading = rawHeading;
      return _currentContinuousAngle;
    }

    final diff = _shortestAngleDiff(_lastRawHeading, rawHeading);
    _currentContinuousAngle += diff;
    _lastRawHeading = rawHeading;
    return _currentContinuousAngle;
  }

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final isDark = hc.isDark;
    final primaryColor = widget.isNavigating
        ? const Color(0xFF22C55E) // Vibrant emerald in navigation mode
        : hc.primary; // Elegant brand espresso/accent in browsing mode
    final beamColor = widget.isNavigating ? const Color(0xFF22C55E) : hc.accent;

    return Obx(() {
      final rawHeading = widget.mapCtrl.userHeading.value;
      final isMoving = widget.mapCtrl.isUserMoving.value;
      final targetContinuousAngle = _getContinuousAngle(rawHeading);

      return TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: _currentContinuousAngle,
          end: targetContinuousAngle,
        ),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, animatedHeading, child) {
          final radAngle = animatedHeading * (math.pi / 180.0);

          return SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // 1. Directional Flashlight Beam / Cone of Light (Google Maps signature
                // Visible when stationary or moving slowly, pointing where user faces
                Transform.rotate(
                  angle: radAngle,
                  child: CustomPaint(
                    size: const Size(84, 84),
                    painter: _DirectionalBeamPainter(
                      beamColor: beamColor,
                      isMoving: isMoving,
                    ),
                  ),
                ),

                // 2. Subtle ambient pulsing aura around puck
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, _) {
                    final scale = 1.0 + (_pulseAnim.value * 0.16);
                    final alpha = isMoving
                        ? 0.12
                        : (0.16 - (_pulseAnim.value * 0.08));

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(
                            alpha: alpha.clamp(0.04, 0.25),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 3. Crisp white outer ring with drop shadow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.18,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),

                // 4. Vibrant core puck with dynamic directional chevron / center dot
                Transform.rotate(
                  angle: radAngle,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          widget.isNavigating
                              ? const Color(0xFF15803D)
                              : (isDark
                                    ? const Color(0xFF2C1E16)
                                    : const Color(0xFF24160C)),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: Center(
                      child: isMoving
                          // Sharp navigation chevron arrow when moving/walking
                          ? const Icon(
                              Icons.navigation_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          // Subtle forward-pointing directional tip when standing still
                          : CustomPaint(
                              size: const Size(10, 10),
                              painter: _StationaryPointerPainter(
                                pointerColor: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

/// Custom painter for Google Maps-style directional flashlight beam (field of view cone
class _DirectionalBeamPainter extends CustomPainter {
  final Color beamColor;
  final bool isMoving;

  const _DirectionalBeamPainter({
    required this.beamColor,
    required this.isMoving,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isMoving) return; // Beam fades out into sharp arrow when walking

    final center = Offset(size.width / 2, size.height / 2);
    const radius = 42.0;
    // 55 degree arc fanning forward (top is -90 degrees in Flutter canvas coordinates
    const sweepAngle = 55.0 * (math.pi / 180.0);
    const startAngle = -math.pi / 2 - (sweepAngle / 2);

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          beamColor.withValues(alpha: 0.38),
          beamColor.withValues(alpha: 0.16),
          beamColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DirectionalBeamPainter oldDelegate) {
    return oldDelegate.beamColor != beamColor ||
        oldDelegate.isMoving != isMoving;
  }
}

/// Subtle forward pointer tip inside the puck when stationary
class _StationaryPointerPainter extends CustomPainter {
  final Color pointerColor;

  const _StationaryPointerPainter({required this.pointerColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pointerColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height * 0.75)
      ..lineTo(size.width / 2, size.height * 0.55)
      ..lineTo(0, size.height * 0.75)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StationaryPointerPainter oldDelegate) {
    return oldDelegate.pointerColor != pointerColor;
  }
}
