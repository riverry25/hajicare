import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/theme_context.dart';

/// Animated Ka'bah hero for the splash screen.
/// Renders the vector Lottie composition `assets/lotties/kabbah-animation.json`
/// 888×674, 30 fps, seamless 6 s loop). The composition carries its own
/// animation, so no extra Flutter-side transforms, shaders or glows are used.
class KabbahHeroWidget extends StatelessWidget {
  static const String assetPath = 'assets/lotties/kabbah-animation.json';

  /// Native aspect ratio of the Lottie composition (w / h).
  static const double aspectRatio = 888 / 674;

  final double width;

  const KabbahHeroWidget({super.key, this.width = 240});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: width / aspectRatio,
        child: Lottie.asset(
          assetPath,
          repeat: true,
          fit: BoxFit.contain,
          // Render at the composition's native 30 fps instead of the display
          // refresh rate (60/120 Hz) — halves raster work on a long loop.
          frameRate: FrameRate.composition,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.mosque_rounded,
            size: width * 0.35,
            color: context.hc.accent,
          ),
        ),
      ),
    );
  }
}
