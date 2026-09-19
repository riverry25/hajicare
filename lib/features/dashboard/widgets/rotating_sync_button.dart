import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A circular button that rotates smoothly when tapped to sync/refresh data.
class RotatingSyncButton extends StatefulWidget {
  final Future<void> Function() onSync;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  const RotatingSyncButton({
    super.key,
    required this.onSync,
    this.size = 44.0,
    this.iconSize = 22.0,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<RotatingSyncButton> createState() => _RotatingSyncButtonState();
}

class _RotatingSyncButtonState extends State<RotatingSyncButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    HapticFeedback.lightImpact();

    // Start continuous spinning
    _animController.repeat();

    try {
      // Guarantee at least 850ms spin so the rotation animation is clearly appreciated
      await Future.wait([
        widget.onSync(),
        Future.delayed(const Duration(milliseconds: 850)),
      ]);
    } finally {
      if (mounted) {
        // Smoothly finish the revolution to 1.0 (pointing upright)
        _animController.stop();
        await _animController.animateTo(
          1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
        if (mounted) {
          _animController.reset();
          setState(() => _isSyncing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _isSyncing ? null : _handleTap,
          child: Center(
            child: RotationTransition(
              turns: _animController,
              child: Icon(
                Icons.sync_rounded,
                color: widget.iconColor ?? Colors.white,
                size: widget.iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
