import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/pill_button.dart';
import '../controllers/login_controller.dart';
import '../controllers/register_controller.dart';
import '../widgets/forgot_password_sheet.dart';

class LoginScreen extends StatefulWidget {
  final int initialTab;

  const LoginScreen({super.key, this.initialTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late int _activeTabIndex;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTab.clamp(0, 1);
  }

  void _switchTab(int index) {
    if (_activeTabIndex != index) {
      setState(() {
        _activeTabIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Get.find<LoginController>();
    final registerController = Get.find<RegisterController>();
    final isDark = AppColors.isDark(context);

    // Dominant clean white palette in light mode, elegant warm charcoal in dark mode
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.surfaceWhite;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final cardBorder = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasKeyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
            // Prevent scrolling on login tab when screen space is adequate and keyboard is closed
            final canScroll =
                _activeTabIndex == 1 ||
                hasKeyboard ||
                constraints.maxHeight < 680;

            return SingleChildScrollView(
              physics: canScroll
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ============================================================
                  // TOP HEADER: CURVED ARCH WITH HAJI PHOTO (assets/images/haji.webp)
                  // ============================================================
                  _CurvedArchHeader(isDark: isDark),

                  // ============================================================
                  // WELCOME HEADLINE & SUBTITLE (CLEAN & SPACIOUS)
                  // ============================================================
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenEdgeGutter,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        Text(
                          context.tr('auth.welcomeTitleClean'),
                          textAlign: TextAlign.center,
                          style: AppTypography.displayLarge.copyWith(
                            color: AppColors.textHeadingColor(context),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _activeTabIndex == 0
                                ? context.tr('auth.welcomeSubtitleClean')
                                : context.tr('auth.registerSubtitleClean'),
                            key: ValueKey<int>(_activeTabIndex),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondaryColor(context),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ============================================================
                  // CURVED WHITE CARD CONTAINER WITH SECONDARY BACKGROUND CURVE
                  // (Lower Z-Index curve behind primary form card)
                  // ============================================================
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenEdgeGutter,
                      12,
                      AppSpacing.screenEdgeGutter,
                      AppSpacing.xl,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // ── Lower Z-Index Secondary Curve (Without Image) ────────
                        Positioned(
                          top: -10,
                          left: 6,
                          right: 6,
                          bottom: -6,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceContainer
                                  : AppColors.canvasCream,
                              borderRadius: BorderRadius.circular(38),
                              border: Border.all(
                                color: AppColors.goldPrimary.withValues(
                                  alpha: isDark ? 0.35 : 0.28,
                                ),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.espressoDark.withValues(
                                    alpha: isDark ? 0.22 : 0.05,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Higher Z-Index Primary White Form Card ───────────────
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(AppRadius.xxl),
                            border: Border.all(color: cardBorder, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.espressoDark.withValues(
                                  alpha: isDark ? 0.25 : 0.05,
                                ),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Tab Pill Switcher (Sign In vs Sign Up) ─────────
                              _TabPillSwitcher(
                                selectedIndex: _activeTabIndex,
                                onTabChanged: _switchTab,
                                isDark: isDark,
                              ),

                              const SizedBox(height: 24),

                              // ── Tab Form Views (Animated) ──────────────────────
                              AnimatedCrossFade(
                                firstChild: _SignInForm(
                                  controller: loginController,
                                  onSwitchToRegister: () => _switchTab(1),
                                  isDark: isDark,
                                ),
                                secondChild: _SignUpForm(
                                  controller: registerController,
                                  loginController: loginController,
                                  onSwitchToLogin: () => _switchTab(0),
                                  isDark: isDark,
                                ),
                                crossFadeState: _activeTabIndex == 0
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                duration: const Duration(milliseconds: 250),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// HEADER: SEMICIRCLE / CURVED ARCH CONTAINER WITH REAL HAJI PHOTO
// =============================================================================
class _CurvedArchHeader extends StatelessWidget {
  final bool isDark;

  const _CurvedArchHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const headerHeight = 215.0;

    return SizedBox(
      height: headerHeight,
      width: screenWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ── Curved drop shadow underneath image (replaces border) ──
          CustomPaint(
            size: Size(screenWidth, headerHeight),
            painter: _CurvedArchShadowPainter(isDark: isDark),
          ),

          // ── Semicircle curved photo backdrop (no border) ──
          ClipPath(
            clipper: const _CurvedArchClipper(),
            child: SizedBox(
              height: headerHeight,
              width: screenWidth,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ka'bah & Pilgrims image blending with header curve
                  Image.asset(
                    'assets/images/haji.webp',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.2),
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark
                          ? AppColors.espressoDark
                          : AppColors.canvasCream,
                      child: const Center(
                        child: Icon(
                          Icons.mosque_rounded,
                          color: AppColors.goldPrimary,
                          size: 50,
                        ),
                      ),
                    ),
                  ),

                  // Atmospheric gradient overlay for contrast & elegance
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.05),
                          isDark
                              ? AppColors.darkScaffold.withValues(alpha: 0.55)
                              : Colors.black.withValues(alpha: 0.30),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top-left floating HajiCare circular icon (brand mark only)
          Positioned(
            top: MediaQuery.paddingOf(context).top > 0
                ? MediaQuery.paddingOf(context).top + 8
                : 44,
            left: AppSpacing.screenEdgeGutter,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.88)
                    : Colors.white.withValues(alpha: 0.95),
                border: Border.all(
                  color: AppColors.goldPrimary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2.5),
              child: ClipOval(
                child: Image.asset(
                  'assets/icon.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.mosque_rounded,
                    size: 20,
                    color: AppColors.goldPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvedArchClipper extends CustomClipper<Path> {
  const _CurvedArchClipper();

  static Path getArchPath(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 15);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 70,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  Path getClip(Size size) => getArchPath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CurvedArchShadowPainter extends CustomPainter {
  final bool isDark;

  const _CurvedArchShadowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _CurvedArchClipper.getArchPath(size);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.55)
        : AppColors.espressoDark.withValues(alpha: 0.16);

    // Multi-layered shadow for rich natural depth underneath the curve
    // Layer 1: Ambient soft blur spreading underneath
    final ambientPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawPath(path.shift(const Offset(0, 6)), ambientPaint);

    // Layer 2: Deeper contact shadow right at the curve edge
    final contactPaint = Paint()
      ..color = shadowColor.withValues(alpha: isDark ? 0.35 : 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path.shift(const Offset(0, 2)), contactPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArchShadowPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// =============================================================================
// TAB PILL SWITCHER (Masuk vs Daftar)
// =============================================================================
class _TabPillSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final bool isDark;

  const _TabPillSwitcher({
    required this.selectedIndex,
    required this.onTabChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final pillBg = isDark
        ? AppColors.darkSurfaceContainerHighest
        : const Color(0xFFF4EFEA);

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: pillBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: isDark
              ? AppColors.darkCardBorder
              : AppColors.canvasCreamSubtle,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: context.tr('auth.tabSignIn'),
              isSelected: selectedIndex == 0,
              onTap: () => onTabChanged(0),
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              title: context.tr('auth.tabSignUp'),
              isSelected: selectedIndex == 1,
              onTap: () => onTabChanged(1),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? AppColors.goldPrimary : AppColors.espressoDark;
    final activeText = isDark ? AppColors.espressoDark : Colors.white;
    final inactiveText = isDark
        ? AppColors.darkTextBody.withValues(alpha: 0.7)
        : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.espressoDark.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? activeText : inactiveText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 1: FORM MASUK (SIGN IN)
// =============================================================================
class _SignInForm extends StatelessWidget {
  final LoginController controller;
  final VoidCallback onSwitchToRegister;
  final bool isDark;

  const _SignInForm({
    required this.controller,
    required this.onSwitchToRegister,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        Text(
          context.tr('auth.email'),
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: controller.emailController,
          hintText: context.tr('auth.emailHint'),
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(
            Icons.mail_outline_rounded,
            color: AppColors.tanMedium,
            size: 20,
          ),
        ),

        const SizedBox(height: 14),

        // Password
        Text(
          context.tr('auth.password'),
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        const SizedBox(height: 8),

        Obx(
          () => AppTextField(
            controller: controller.passwordController,
            hintText: context.tr('auth.passwordHint'),
            obscureText: controller.obscurePassword.value,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.tanMedium,
              size: 20,
            ),
            suffixIcon: IconButton(
              splashRadius: 20,
              tooltip: controller.obscurePassword.value
                  ? context.tr('auth.showPassword')
                  : context.tr('auth.hidePassword'),
              icon: Icon(
                controller.obscurePassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textBody,
                size: 20,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Utility Row: Remember Me & Forgot Password
        Row(
          children: [
            Obx(
              () => SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: controller.rememberMe.value,
                  onChanged: (val) => controller.setRememberMe(val ?? true),
                  activeColor: isDark
                      ? AppColors.goldPrimary
                      : AppColors.espressoDark,
                  checkColor: isDark ? AppColors.espressoDark : Colors.white,
                  side: BorderSide(
                    color: isDark ? AppColors.goldLight : AppColors.tanMedium,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    controller.setRememberMe(!controller.rememberMe.value),
                child: Text(
                  context.tr('auth.rememberMe'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => ForgotPasswordSheet.show(
                context,
                initialEmail: controller.emailController.text,
              ),
              child: Text(
                context.tr('auth.forgotPassword'),
                style: AppTypography.captionSmall.copyWith(
                  color: isDark ? AppColors.goldAccent : AppColors.espressoDark,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Login Button
        Obx(
          () => SizedBox(
            height: 48,
            child: PillButton(
              label: controller.isLoading.value
                  ? context.tr('auth.loginLoading')
                  : context.tr('auth.loginBtn'),
              icon: Icons.arrow_forward_rounded,
              color: isDark ? AppColors.goldPrimary : AppColors.espressoDark,
              textColor: isDark
                  ? AppColors.espressoDark
                  : AppColors.surfaceWhite,
              onPressed: controller.isLoading.value ? null : controller.login,
            ),
          ),
        ),

        // Centered Spacing between Login Button and Google Sign-In
        const SizedBox(height: 14),

        // Centered Divider
        _DividerWithText(text: context.tr('auth.orDivider'), isDark: isDark),

        const SizedBox(height: 14),

        // Google Sign-In Button
        _GoogleSignInButton(controller: controller, isDark: isDark),

        const SizedBox(height: 16),

        // Switch to Register link
        Center(
          child: GestureDetector(
            onTap: onSwitchToRegister,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: '${context.tr('auth.noAccount')} ',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
                  children: [
                    TextSpan(
                      text: context.tr('auth.registerNow'),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.goldAccent
                            : AppColors.espressoDark,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: isDark
                            ? AppColors.goldAccent
                            : AppColors.goldPrimary,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 2: FORM DAFTAR (SIGN UP)
// =============================================================================
class _SignUpForm extends StatelessWidget {
  final RegisterController controller;
  final LoginController loginController;
  final VoidCallback onSwitchToLogin;
  final bool isDark;

  const _SignUpForm({
    required this.controller,
    required this.loginController,
    required this.onSwitchToLogin,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Selector (Compact)
        Text(
          context.tr('auth.registerAs'),
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        const SizedBox(height: 8),

        Obx(
          () => Row(
            children: [
              Expanded(
                child: _RoleChoiceCard(
                  title: context.tr('roleJamaah'),
                  subtitle: context.tr('auth.roleHajjUmrah'),
                  icon: Icons.person_outline_rounded,
                  isSelected: controller.selectedRole.value == 'jamaah',
                  onTap: () => controller.setRole('jamaah'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RoleChoiceCard(
                  title: context.tr('auth.roleCompanion'),
                  subtitle: context.tr('auth.roleFamilyMuthawif'),
                  icon: Icons.health_and_safety_outlined,
                  isSelected: controller.selectedRole.value == 'pendamping',
                  onTap: () => controller.setRole('pendamping'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Full Name
        Text(
          context.tr('fullNameLabel'),
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: controller.fullNameController,
          hintText: context.tr('auth.fullNameHint'),
          prefixIcon: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.tanMedium,
            size: 20,
          ),
        ),

        const SizedBox(height: 18),

        // Nomor Porsi / NIK (Optional)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                context.tr('auth.porsiOrNikLabel'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textHeadingColor(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerHighest
                    : AppColors.canvasCream,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                context.tr('common.optional'),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.tanMedium,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: controller.porsiController,
          hintText: context.tr('auth.porsiOrNikHint'),
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(
            Icons.credit_card_outlined,
            color: AppColors.tanMedium,
            size: 20,
          ),
        ),

        const SizedBox(height: 18),

        // Active Email
        Text(
          context.tr('auth.activeEmail'),
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: controller.emailController,
          hintText: context.tr('auth.emailHint'),
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(
            Icons.mail_outline_rounded,
            color: AppColors.tanMedium,
            size: 20,
          ),
        ),

        const SizedBox(height: 18),

        // Password
        Text(
          context.tr('auth.password'),
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textHeadingColor(context),
          ),
        ),
        const SizedBox(height: 8),

        Obx(
          () => AppTextField(
            controller: controller.passwordController,
            hintText: context.tr('auth.passwordMin6Hint'),
            obscureText: controller.obscurePassword.value,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.tanMedium,
              size: 20,
            ),
            suffixIcon: IconButton(
              splashRadius: 20,
              tooltip: controller.obscurePassword.value
                  ? context.tr('auth.showPassword')
                  : context.tr('auth.hidePassword'),
              icon: Icon(
                controller.obscurePassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textBody,
                size: 20,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          context.tr('auth.passwordMin6Desc'),
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.textSecondaryColor(context),
          ),
        ),

        const SizedBox(height: 22),

        // Register Button
        Obx(
          () => SizedBox(
            height: 52,
            child: PillButton(
              label: controller.isLoading.value
                  ? context.tr('auth.registering')
                  : context.tr('auth.createAccountNow'),
              icon: Icons.check_circle_outline_rounded,
              color: isDark ? AppColors.goldPrimary : AppColors.espressoDark,
              textColor: isDark
                  ? AppColors.espressoDark
                  : AppColors.surfaceWhite,
              onPressed: controller.isLoading.value
                  ? null
                  : controller.register,
            ),
          ),
        ),

        // Centered Spacing between Register Button and Google Sign-In
        const SizedBox(height: 20),

        // Centered Divider
        _DividerWithText(text: context.tr('auth.orDivider'), isDark: isDark),

        const SizedBox(height: 20),

        // Google Sign-In Button
        _GoogleSignInButton(controller: loginController, isDark: isDark),

        const SizedBox(height: 22),

        // Switch to Login link
        Center(
          child: GestureDetector(
            onTap: onSwitchToLogin,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: context.tr('auth.alreadyHaveAccount'),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondaryColor(context),
                  ),
                  children: [
                    TextSpan(
                      text: context.tr('auth.loginNow'),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.goldAccent
                            : AppColors.espressoDark,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: isDark
                            ? AppColors.goldAccent
                            : AppColors.goldPrimary,
                        decorationThickness: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// ROLE SELECTION CARD
// =============================================================================
class _RoleChoiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _RoleChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeBorderColor = isDark
        ? AppColors.goldPrimary
        : AppColors.espressoDark;
    final inactiveBorderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.canvasCreamSubtle;
    final activeBg = isDark
        ? AppColors.darkSurfaceContainerHighest
        : AppColors.canvasCream;
    final inactiveBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? activeBorderColor : inactiveBorderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDark ? AppColors.goldPrimary : AppColors.espressoDark)
                  : AppColors.tanMedium,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textHeadingColor(context),
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionSmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: isDark ? AppColors.goldPrimary : AppColors.espressoDark,
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DIVIDER WITH TEXT (VERTICALLY & HORIZONTALLY CENTERED)
// =============================================================================
class _DividerWithText extends StatelessWidget {
  final String text;
  final bool isDark;

  const _DividerWithText({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.canvasCreamSubtle;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Divider(color: dividerColor, height: 1)),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textSecondaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: dividerColor, height: 1)),
        ],
      ),
    );
  }
}

// =============================================================================
// GOOGLE SIGN-IN BUTTON
// =============================================================================
class _GoogleSignInButton extends StatelessWidget {
  final LoginController controller;
  final bool isDark;

  const _GoogleSignInButton({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed:
              controller.isLoading.value || controller.isGoogleLoading.value
              ? null
              : controller.loginWithGoogle,
          style: OutlinedButton.styleFrom(
            backgroundColor: isDark
                ? AppColors.darkSurfaceContainerHighest
                : AppColors.surfaceWhite,
            side: BorderSide(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.canvasCreamSubtle,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          child: controller.isGoogleLoading.value
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: AppColors.goldPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _GoogleLogo(size: 18),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        context.tr('auth.googleSignIn'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textHeadingColor(context),
                          fontWeight: FontWeight.w700,
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

// =============================================================================
// AUTHENTIC GOOGLE LOGO
// =============================================================================
class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24.0, size.height / 24.0);

    // Red (top segment)
    final redPath = Path()
      ..moveTo(12.0, 5.0)
      ..cubicTo(13.85, 5.0, 15.35, 5.68, 16.48, 6.64)
      ..lineTo(20.0, 3.12)
      ..cubicTo(17.85, 1.15, 15.15, 0.0, 12.0, 0.0)
      ..cubicTo(7.45, 0.0, 3.5, 2.65, 1.5, 6.5)
      ..lineTo(5.62, 9.68)
      ..cubicTo(6.62, 6.95, 9.1, 5.0, 12.0, 5.0)
      ..close();
    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));

    // Blue (right segment & crossbar)
    final bluePath = Path()
      ..moveTo(23.6, 12.25)
      ..cubicTo(23.6, 11.45, 23.5, 10.65, 23.35, 9.9)
      ..lineTo(12.0, 9.9)
      ..lineTo(12.0, 14.5)
      ..lineTo(18.5, 14.5)
      ..cubicTo(18.2, 16.0, 17.3, 17.25, 16.0, 18.1)
      ..lineTo(19.9, 21.1)
      ..cubicTo(22.2, 19.0, 23.6, 15.9, 23.6, 12.25)
      ..close();
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));

    // Yellow (left segment)
    final yellowPath = Path()
      ..moveTo(1.5, 6.5)
      ..cubicTo(0.55, 8.4, 0.0, 10.5, 0.0, 12.0)
      ..cubicTo(0.0, 13.5, 0.55, 15.6, 1.5, 17.5)
      ..lineTo(5.62, 14.32)
      ..cubicTo(5.35, 13.55, 5.2, 12.8, 5.2, 12.0)
      ..cubicTo(5.2, 11.2, 5.35, 10.45, 5.62, 9.68)
      ..lineTo(1.5, 6.5)
      ..close();
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));

    // Green (bottom segment)
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.2, 24.0, 17.9, 22.95, 19.9, 21.1)
      ..lineTo(16.0, 18.1)
      ..cubicTo(14.95, 18.8, 13.6, 19.2, 12.0, 19.2)
      ..cubicTo(9.1, 19.2, 6.62, 17.25, 5.62, 14.52)
      ..lineTo(1.5, 17.5)
      ..cubicTo(3.5, 21.35, 7.45, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
