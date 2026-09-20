part of 'admin_dashboard_screen.dart';

class _QuickActionButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color cardBg;
  final Color headingColor;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.cardBg,
    required this.headingColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: effectiveBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : AppColors.primary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.20 : 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),

                const SizedBox(width: AppSpacing.sm),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          color: headingColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSmall.copyWith(
                          color: headingColor.withValues(alpha: 0.65),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: headingColor.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Room monitoring card
class _RoomPantauCard extends StatelessWidget {
  final RoomModel room;
  final int jamaahCount;
  final int pendampingCount;
  final int sosCount;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _RoomPantauCard({
    required this.room,
    required this.jamaahCount,
    required this.pendampingCount,
    required this.sosCount,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSos = sosCount > 0;

    final effectiveCardBg = hasSos
        ? (isDark
              ? const Color(0xFF381418)
              : AppColors.errorContainer.withValues(alpha: 0.35))
        : cardBg;

    final borderColor = hasSos
        ? AppColors.sosEmergency.withValues(alpha: 0.65)
        : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder);

    final textColor = hasSos ? AppColors.sosEmergency : headingColor;

    final subtextColor = hasSos
        ? AppColors.sosEmergency
        : bodyColor.withValues(alpha: 0.75);

    final actionIconColor = hasSos
        ? AppColors.sosEmergency
        : (isDark ? AppColors.darkPrimary : AppColors.espressoDark);

    return Container(
      decoration: BoxDecoration(
        color: effectiveCardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: hasSos ? 1.4 : 1.0),
        boxShadow: [
          BoxShadow(
            color:
                (hasSos
                        ? AppColors.sosEmergency
                        : (isDark ? Colors.black : AppColors.espressoDark))
                    .withValues(alpha: isDark ? 0.30 : (hasSos ? 0.12 : 0.04)),
            blurRadius: hasSos ? 16 : 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // ── 3D Concentric Rings Effect (Top-Right) ──
              Positioned(
                top: -36,
                right: -36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ring 4
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (hasSos
                                    ? AppColors.sosEmergency
                                    : (isDark
                                          ? AppColors.goldLight
                                          : AppColors.espressoDark))
                                .withValues(alpha: isDark ? 0.05 : 0.05),
                      ),
                    ),
                    // Ring 3
                    Container(
                      width: 146,
                      height: 146,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (hasSos
                                    ? AppColors.sosEmergency
                                    : (isDark
                                          ? AppColors.goldLight
                                          : AppColors.espressoDark))
                                .withValues(alpha: isDark ? 0.08 : 0.09),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? Colors.black
                                        : (hasSos
                                              ? AppColors.sosEmergency
                                              : AppColors.espressoDark))
                                    .withValues(alpha: isDark ? 0.12 : 0.04),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    // Ring 2
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (hasSos
                                    ? AppColors.sosEmergency
                                    : (isDark
                                          ? AppColors.goldLight
                                          : AppColors.espressoDark))
                                .withValues(alpha: isDark ? 0.12 : 0.14),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isDark
                                        ? Colors.black
                                        : (hasSos
                                              ? AppColors.sosEmergency
                                              : AppColors.espressoDark))
                                    .withValues(alpha: isDark ? 0.15 : 0.06),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    // Ring 1 (Inner core ring)
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (hasSos
                                    ? AppColors.sosEmergency
                                    : (isDark
                                          ? AppColors.goldLight
                                          : AppColors.espressoDark))
                                .withValues(alpha: isDark ? 0.18 : 0.20),
                      ),
                    ),
                    // Center Core 3D Badge (Espresso Theme)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasSos
                            ? AppColors.sosEmergency
                            : (isDark
                                  ? AppColors.espressoMedium
                                  : AppColors.espressoDark),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (hasSos
                                        ? AppColors.sosEmergency
                                        : AppColors.espressoDark)
                                    .withValues(alpha: isDark ? 0.40 : 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          hasSos
                              ? Icons.warning_amber_rounded
                              : (room.isActive
                                    ? Icons.door_sliding_rounded
                                    : Icons.lock_outline_rounded),
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Glossy Curved Specular Highlight (Top-Left) ──
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (isDark ? Colors.white : AppColors.canvasCreamSubtle)
                            .withValues(alpha: isDark ? 0.06 : 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Main Card Content ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Room Name & Status Tag
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (room.isActive
                                                  ? AppColors.statusSafe
                                                  : AppColors.textSecondary)
                                              .withValues(
                                                alpha: isDark ? 0.18 : 0.10,
                                              ),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color:
                                            (room.isActive
                                                    ? AppColors.statusSafe
                                                    : AppColors.textSecondary)
                                                .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: room.isActive
                                                ? (hasSos
                                                      ? AppColors.sosEmergency
                                                      : AppColors.statusSafe)
                                                : AppColors.textSecondary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          room.isActive
                                              ? (hasSos ? 'SOS Aktif' : 'Aktif')
                                              : 'Nonaktif',
                                          style: TextStyle(
                                            color: room.isActive
                                                ? (hasSos
                                                      ? AppColors.sosEmergency
                                                      : AppColors.statusSafe)
                                                : bodyColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kode: ${room.code}',
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Margin for top-right 3D badge
                        const SizedBox(width: 54),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Middle: Room Summary & Stats Pill Row
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _BentoChip(
                          icon: Icons.groups_rounded,
                          label: '$jamaahCount Jamaah',
                          isDark: isDark,
                          textColor: headingColor,
                        ),
                        _BentoChip(
                          icon: Icons.shield_rounded,
                          label: '$pendampingCount Pendamping',
                          isDark: isDark,
                          textColor: headingColor,
                        ),
                        if (hasSos)
                          _BentoChip(
                            icon: Icons.warning_amber_rounded,
                            label: '$sosCount SOS',
                            isDark: isDark,
                            textColor: AppColors.sosEmergency,
                            backgroundColor: AppColors.sosEmergency.withValues(
                              alpha: 0.15,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Bottom: 3 Circular Action Buttons + Right-aligned Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 3 Circular Action Buttons (Reference: Circular white social/action buttons)
                        Row(
                          children: [
                            _CircleActionButton(
                              icon: Icons.copy_rounded,
                              tooltip: 'Salin Kode (${room.code})',
                              isDark: isDark,
                              iconColor: actionIconColor,
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: room.code),
                                );
                                AppAlert.info(
                                  context,
                                  title: 'Kode Disalin',
                                  message:
                                      'Kode rombongan "${room.code}" sudah disalin dan siap ditempel.',
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _CircleActionButton(
                              icon: Icons.qr_code_2_rounded,
                              tooltip: 'Lihat QR Code',
                              isDark: isDark,
                              iconColor: actionIconColor,
                              onTap: () =>
                                  RoomQrDialog.show(context, room: room),
                            ),
                            const SizedBox(width: 8),
                            _CircleActionButton(
                              icon: Icons.radar_rounded,
                              tooltip: 'Pantau Radar',
                              isDark: isDark,
                              iconColor: actionIconColor,
                              onTap: onTap,
                            ),
                          ],
                        ),

                        // Right Action (Reference: "View more v" style)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onTap,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Pantau Ruangan',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.18) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white : iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BentoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color textColor;
  final Color? backgroundColor;

  const _BentoChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            Colors.white.withValues(alpha: isDark ? 0.18 : 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulseIndicator extends StatefulWidget {
  final Color color;
  final bool isDark;

  const _LivePulseIndicator({required this.color, required this.isDark});

  @override
  State<_LivePulseIndicator> createState() => _LivePulseIndicatorState();
}

class _LivePulseIndicatorState extends State<_LivePulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.65 * _pulseAnimation.value,
                ),
                blurRadius: 6 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivityFeedTile extends StatelessWidget {
  final ActivityModel activity;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActivityFeedTile({
    required this.activity,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSos = activity.type == ActivityType.sosActive;

    return Material(
      color: isSos
          ? AppColors.sosEmergency.withValues(alpha: isDark ? 0.12 : 0.05)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: activity.color.withValues(alpha: 0.12),
        highlightColor: activity.color.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge with alert styling
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: activity.color.withValues(alpha: isDark ? 0.20 : 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activity.color.withValues(
                      alpha: isDark ? 0.40 : 0.25,
                    ),
                    width: 1.2,
                  ),
                  boxShadow: isSos
                      ? [
                          BoxShadow(
                            color: AppColors.sosEmergency.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(activity.icon, color: activity.color, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Time & Alert pill
                    Row(
                      children: [
                        if (isSos) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: AppColors.sosEmergency,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: const Text(
                              'DARURAT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            activity.title,
                            style: AppTypography.titleSmall.copyWith(
                              color: isSos
                                  ? (isDark
                                        ? const Color(0xFFFF6B6B)
                                        : AppColors.sosEmergency)
                                  : headingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: bodyColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              activity.timeAgo,
                              style: AppTypography.captionSmall.copyWith(
                                color: bodyColor.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),

                    // Description
                    Text(
                      activity.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: bodyColor,
                        height: 1.38,
                        fontSize: 12.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Context Chips (Room / Actor)
                    if (activity.roomName != null ||
                        activity.userName != null ||
                        activity.role != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (activity.roomName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppColors.darkCardBorder
                                            : AppColors.canvasCreamSubtle)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 11,
                                    color: bodyColor.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activity.roomName!,
                                    style: AppTypography.captionSmall.copyWith(
                                      color: bodyColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (activity.userName != null ||
                              activity.role != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppColors.darkCardBorder
                                            : AppColors.canvasCreamSubtle)
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 11,
                                    color: bodyColor.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${activity.userName ?? ""}${activity.role != null ? " (${activity.role})" : ""}'
                                        .trim(),
                                    style: AppTypography.captionSmall.copyWith(
                                      color: bodyColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing chevron icon
              Padding(
                padding: const EdgeInsets.only(left: 6, top: 2),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: bodyColor.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular gauge painter for the Hero Progress Card (reference: Calorie circular arc)
class _HeroGaugePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final Color dotColor;

  const _HeroGaugePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 7.0;
    final radius = (size.width - strokeWidth) / 2;

    // Track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    const sweepTotal = 2 * math.pi * 0.85; // 85% arc for open meter aesthetic

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // Progress arc
    final activeSweep = sweepTotal * progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      progressPaint,
    );

    // End indicator dot
    final endAngle = startAngle + activeSweep;
    final dotX = center.dx + radius * math.cos(endAngle);
    final dotY = center.dy + radius * math.sin(endAngle);

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dotX, dotY), 4.5, dotPaint);

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(dotX, dotY), 4.5, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _HeroGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.dotColor != dotColor;
  }
}

String _formatMinutesAgo(Duration diff) {
  if (diff.inSeconds < 60) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}
