import 'package:flutter/material.dart';
import '../theme/theme_context.dart';

/// An animated pulsing dot widget indicating live/active status.
/// Used in map headers and dashboard status indicators.
class AnimatedPingDot extends StatefulWidget {
  /// The size of the dot (outer pulse ring is slightly larger).
  final double size;

  /// The optional color override. Defaults to [context.hc.success].
  final Color? color;

  const AnimatedPingDot({super.key, this.size = 10, this.color});

  @override
  State<AnimatedPingDot> createState() => _AnimatedPingDotState();
}

class _AnimatedPingDotState extends State<AnimatedPingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? context.hc.success;

    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveColor,
                ),
              ),
            ),
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
