import 'package:flutter/material.dart';

class AppDurations {
  AppDurations._();

  // Subtle durations suitable for elderly / calm interactions (150 - 300ms)
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);

  // Standard curves
  static const Curve standardCurve = Curves.easeInOut;
  static const Curve gentleCurve = Curves.easeOutCubic;
  static const Curve decelerateCurve = Curves.decelerate;

  /// Returns Duration.zero if the platform or user has requested reduced motion
  static Duration adaptive(BuildContext context, Duration baseDuration) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableAnimations) {
      return Duration.zero;
    }
    return baseDuration;
  }
}
