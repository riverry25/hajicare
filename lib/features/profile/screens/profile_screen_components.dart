part of 'profile_screen.dart';

class _ProfileHeader extends StatelessWidget {
  final ProfileController controller;
  final HajiCareController? state;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final bool isDark;

  const _ProfileHeader({
    required this.controller,
    required this.state,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final porsiText = context.tr('profilePassportCountry');
    final roleLabel = state?.role == UserRole.pendamping
        ? context.tr('auth.rolePendamping')
        : context.tr('auth.roleJamaah');
    final kloterStr = state?.effectiveKloter;
    final maktabStr = state?.effectiveMaktab;

    const double bannerHeight = 104.0;
    const double bannerProtrude = 34.0;

    return Padding(
      padding: const EdgeInsets.only(top: bannerProtrude),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── 1. Main Card Container ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              20,
              (bannerHeight - bannerProtrude) + 18,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colors.border,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.35)
                      : colors.primary.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Name
                Obx(
                  () => Text(
                    controller.displayName.value.isNotEmpty
                        ? controller.displayName.value
                        : context.tr('profile.defaultUser'),
                    style: context.text.titleLarge.copyWith(
                      color: headingColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),

                // Email
                if (controller.safeEmail.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 14,
                        color: bodyColor.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          controller.safeEmail,
                          style: context.text.bodySmall.copyWith(
                            color: bodyColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 14),

                // Tag Chips Row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _TagChip(
                      icon: Icons.badge_rounded,
                      label: porsiText,
                      isDark: isDark,
                      isPrimary: false,
                    ),
                    if (kloterStr != null &&
                        kloterStr.isNotEmpty &&
                        kloterStr != '-')
                      _TagChip(
                        icon: Icons.flight_takeoff_rounded,
                        label: kloterStr.toLowerCase().startsWith('kloter')
                            ? kloterStr
                            : context.tr('profileKloter', {
                                'kloter': kloterStr,
                              }),
                        isDark: isDark,
                        isPrimary: false,
                      ),
                    if (maktabStr != null &&
                        maktabStr.isNotEmpty &&
                        maktabStr != '-')
                      _TagChip(
                        icon: Icons.hotel_rounded,
                        label: maktabStr.toLowerCase().startsWith('maktab')
                            ? maktabStr
                            : context.tr('profileMaktab', {
                                'maktab': maktabStr,
                              }),
                        isDark: isDark,
                        isPrimary: false,
                      ),
                  ],
                ),

                const SizedBox(height: 18),

                // Action Button: "Ubah Profil"
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showEditNameDialog(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [colors.accent, colors.accentText]
                                : [colors.primary, colors.primaryContainer],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? colors.accent
                                      : colors.primary)
                                  .withValues(alpha: 0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 16,
                              color: isDark ? colors.onPrimary : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('profile.editProfile'),
                              style: context.text.labelMedium.copyWith(
                                color: isDark ? colors.onPrimary : Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── 2. Elevated Floating Top Banner ──────────────────────────
          Positioned(
            top: -bannerProtrude,
            left: 12,
            right: 12,
            height: bannerHeight,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          colors.surfaceSand,
                          colors.surfaceSubtle,
                          colors.surface,
                        ]
                      : [
                          colors.primary,
                          colors.primaryContainer,
                          colors.borderStrong,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : colors.primary)
                        .withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 3D Concentric Ripples in top-right
                  Positioned(
                    top: -45,
                    right: -45,
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 210,
                            height: 210,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 160,
                            height: 160,
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
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Glossy Glass Arc Highlight across top
                  Positioned(
                    top: -50,
                    left: -30,
                    right: -30,
                    height: 110,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.elliptical(260, 90),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.16),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Content inside Banner: Avatar + Greeting + Top-Right Glassmorphic Badge
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar with Camera icon & gold border
                        Obx(
                          () => _InitialsAvatar(
                            initials: controller.initials,
                            isDark: isDark,
                            onCameraTap: () => _showEditNameDialog(context),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title / Greeting beside Avatar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: colors.accent,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.tr('profilePilgrimCard'),
                                    style: context.text.labelSmall.copyWith(
                                      color: colors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Obx(
                                () => Text(
                                  controller.displayName.value.isNotEmpty
                                      ? controller.displayName.value
                                      : context.tr('profile.defaultUser'),
                                  style: context.text.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Top-Right Glassmorphic Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                              width: 1.1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: colors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                roleLabel,
                                style: context.text.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (dialogCtx) => _EditNameDialog(
        controller: controller,
        isDark: context.isDark,
      ),
    );
  }
}

class _EditNameDialog extends StatefulWidget {
  final ProfileController controller;
  final bool isDark;

  const _EditNameDialog({required this.controller, required this.isDark});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _nameCtrl;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.controller.displayName.value,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.controller.isSavingName.value) return;
    final input = _nameCtrl.text.trim();
    if (input.isEmpty) {
      setState(() => _inputError = context.tr('profile.nameCannotBeEmpty'));
      return;
    }
    setState(() => _inputError = null);

    try {
      await widget.controller.updateDisplayName(input);
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      final rootCtx = Get.context;
      if (rootCtx != null && rootCtx.mounted) {
        AppAlert.success(
          rootCtx,
          title: rootCtx.tr('profile.nameChangedSuccess'),
          message: rootCtx.tr('profile.nameChangedSuccessDesc', {
            'name': input,
          }),
        );
      }
    } catch (_) {
      if (mounted) {
        AppAlert.error(
          context,
          title: context.tr('profile.nameChangedError'),
          message: context.tr('medical.saveErrorMsg'),
          okText: context.tr('common.tryAgain'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDarkDialog = widget.isDark;
    final dialogBg = colors.surface;
    final headingClr = colors.textPrimary;
    final bodyClr = colors.textSecondary;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // ── 1. Main Card Body ─────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(
                top: 28,
                bottom: 12,
                right: 10,
                left: 10,
              ),
              padding: const EdgeInsets.fromLTRB(20, 68, 20, 14),
              decoration: BoxDecoration(
                color: dialogBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkDialog
                      ? Colors.white.withValues(alpha: 0.1)
                      : colors.border,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDarkDialog ? 0.45 : 0.09,
                    ),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      context.tr('profileEditNameTitle'),
                      style: context.text.titleMedium.copyWith(
                        color: headingClr,
                        fontWeight: FontWeight.w800,
                        fontSize: 17.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      context.tr('profileEditNameDesc'),
                      style: context.text.bodySmall.copyWith(
                        color: bodyClr.withValues(alpha: 0.85),
                        height: 1.35,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Minimalist Underline Text Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          autofocus: true,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          maxLength: 50,
                          style: context.text.bodyMedium.copyWith(
                            color: headingClr,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: context.tr('profile.yourFullName'),
                            hintStyle: context.text.bodyMedium.copyWith(
                              color: colors.textTertiary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                            ),
                            filled: false,
                            contentPadding: const EdgeInsets.fromLTRB(
                              0,
                              6,
                              0,
                              2,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: colors.border,
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: colors.border,
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: isDarkDialog
                                    ? colors.accent
                                    : colors.primary,
                                width: 1.8,
                              ),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: colors.danger,
                                width: 1.4,
                              ),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: colors.danger,
                                width: 1.8,
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                          ),
                          onChanged: (_) {
                            if (_inputError != null) {
                              setState(() => _inputError = null);
                            }
                          },
                        ),
                        if (_inputError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _inputError!,
                            style: context.text.labelSmall.copyWith(
                              color: colors.danger,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Bottom Row: Cancel button on left, space reserved for protruding button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: isDarkDialog
                                ? Colors.white60
                                : colors.textSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(
                            context.tr('cancel').isEmpty
                                ? 'Batal'
                                : context.tr('cancel'),
                            style: context.text.labelLarge.copyWith(
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 135,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. Floating Hero Card ────────────────────────────────────
            Positioned(
              top: 0,
              left: 22,
              right: 22,
              height: 86,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkDialog
                        ? [colors.surfaceSand, colors.surface]
                        : [colors.primary, colors.primaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Ambient Background Circular Glows
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.accent.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -15,
                      child: Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.accent.withValues(alpha: 0.08),
                        ),
                      ),
                    ),

                    // Center Hero Graphic
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  colors.accent.withValues(alpha: 0.25),
                                  colors.accent.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: colors.accent.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.edit_rounded,
                                color: colors.accent,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('profileUserIdentityBadge'),
                            style: context.text.labelSmall.copyWith(
                              color: colors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── 3. Protruding Ribbon Submit Button ───────────────────────
            Positioned(
              bottom: 0,
              right: 0,
              child: Obx(() {
                final saving = widget.controller.isSavingName.value;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ribbon fold triangle at the top-right corner
                    Positioned(
                      top: -10,
                      right: 0,
                      child: CustomPaint(
                        size: const Size(10, 10),
                        painter: _RibbonFoldPainter(
                          color: isDarkDialog
                              ? const Color(0xFF140D08)
                              : const Color(0xFF160D07),
                        ),
                      ),
                    ),

                    // Main Pill Submit Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: saving ? null : _submit,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(5),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: isDarkDialog
                                ? colors.primary
                                : colors.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 13.5,
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  context.tr('save').toUpperCase(),
                                  style: context.text.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    letterSpacing: 2.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter for the 3D folded ribbon corner flap on the protruding submit button
class _RibbonFoldPainter extends CustomPainter {
  final Color color;
  const _RibbonFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(
        0,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RibbonFoldPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ── Initials Avatar with Edit Badge ──────────────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final bool isDark;
  final VoidCallback? onCameraTap;

  const _InitialsAvatar({
    required this.initials,
    required this.isDark,
    this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    return GestureDetector(
      onTap: onCameraTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        colors.surfaceSand,
                        colors.surfaceSubtle,
                      ]
                    : [colors.primary, colors.primaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: colors.accent, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: context.text.headlineMedium.copyWith(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? colors.surface : Colors.white,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.edit_rounded, size: 11, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isPrimary;

  const _TagChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final bg = isPrimary
        ? (isDark
              ? colors.surfaceSand
              : colors.primary)
        : (isDark ? colors.surfaceSubtle : colors.surfaceSubtle);
    final borderColor = isPrimary
        ? colors.accent
        : colors.border;
    final textColor = isPrimary
        ? (isDark ? colors.accent : Colors.white)
        : colors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.text.labelSmall.copyWith(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Group ────────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Color cardBg;
  final List<Widget> children;

  const _SettingsGroup({
    required this.title,
    required this.titleColor,
    required this.cardBg,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6, top: 4),
          child: Text(
            title.toUpperCase(),
            style: context.text.labelSmall.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final Color cardBg;
  final Color headingColor;
  final Color bodyColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailingLabel,
    required this.cardBg,
    required this.headingColor,
    required this.bodyColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDark = context.isDark;
    return Semantics(
      button: true,
      label: '$label${trailingLabel != null ? ': $trailingLabel' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.surfaceSand
                      : colors.surfaceSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.border,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDark ? colors.accent : colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyMedium.copyWith(
                    color: headingColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailingLabel != null) ...[
                Text(
                  trailingLabel!,
                  style: context.text.labelSmall.copyWith(
                    color: isDark ? colors.accent : colors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: colors.accent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Thin Divider ──────────────────────────────────────────────────────────────

class _DividerThin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 58,
      color: context.hc.border,
    );
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final String label;
  const _LogoutButton({required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        height: 52,
        child: OutlinedButton.icon(
          onPressed: () {
            AppDialog.confirm(
              context: context,
              title: label,
              message: context.tr('profile.logoutConfirm'),
              confirmText: context.tr('profile.logoutConfirmAction'),
              cancelText: context.tr('common.cancel'),
              confirmColor: colors.danger,
              isDestructive: true,
              onConfirm: () async {
                await Get.find<AppStartupController>().signOut();
              },
            );
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: colors.danger.withValues(alpha: 0.4),
              width: 1.2,
            ),
            backgroundColor: colors.danger.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          icon: Icon(
            Icons.logout_rounded,
            size: 18,
            color: colors.danger,
          ),
          label: Text(
            label,
            style: context.text.labelLarge.copyWith(
              color: colors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Picker Option ─────────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? trailingHint;
  final bool isSelected;
  final VoidCallback onTap;

  const _PickerOption({
    this.icon,
    required this.label,
    this.trailingHint,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final isDark = context.isDark;
    final activeColor = isDark ? colors.accent : colors.primary;
    final textColor = colors.textPrimary;
    final selectedBg = isDark
        ? colors.surfaceSand
        : colors.primary.withValues(alpha: 0.07);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.touchTargetMin + 4,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppSizes.iconMd,
                  color: isSelected ? activeColor : textColor,
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodyLarge.copyWith(
                    color: isSelected ? activeColor : textColor,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              if (trailingHint != null) ...[
                Text(
                  trailingHint!,
                  style: context.text.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: activeColor, size: 22)
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.border,
                      width: 1.8,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
