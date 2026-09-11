import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// An animated pulsing dot widget indicating live/active status.
/// Used in map headers and dashboard status indicators.
///
/// Example usage:
/// ```dart
/// Row(children: [
///   const AnimatedPingDot(),
///   const SizedBox(width: 6),
///   Text('Pelacakan Aktif'),
/// ])
/// ```
class AnimatedPingDot extends StatefulWidget {
  /// The size of the dot (outer pulse ring is slightly larger).
  final double size;

  /// The color of the dot and pulse ring.
  final Color color;

  const AnimatedPingDot({
    super.key,
    this.size = 10,
    this.color = AppColors.statusPositive,
  });

  @override
  State<AnimatedPingDot> createState() => _AnimatedPingDotState();
}

class _AnimatedPingDotState extends State<AnimatedPingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: widget.size * (1 + _controller.value * 0.5),
                height: widget.size * (1 + _controller.value * 0.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(
                    alpha: (1 - _controller.value) * 0.5,
                  ),
                ),
              );
            },
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
