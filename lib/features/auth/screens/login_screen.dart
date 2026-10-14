import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/locales/app_localizations.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTab.clamp(0, 1);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    if (_activeTabIndex != index) {
      setState(() {
        _activeTabIndex = index;
      });
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginController = Get.find<LoginController>();
    final registerController = Get.find<RegisterController>();
    final colors = context.hc;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        top: false,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = MediaQuery.paddingOf(context).bottom;
            const topHeaderHeight = 215.0; // Header arch height
            const welcomeSectionHeight = 85.0; // Padding, titles, and spacing
            const topSpacing = 30.0;
            const totalTopHeight =
                topHeaderHeight + welcomeSectionHeight + topSpacing;
            final minSheetHeight = (constraints.maxHeight - totalTopHeight)
                .clamp(0.0, double.infinity);

            return SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ResponsiveCenter(
                maxWidth: AppBreakpoints.maxFormWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOP HEADER: CURVED ARCH WITH HAJI PHOTO
                    _CurvedArchHeader(colors: colors),

                    // WELCOME HEADLINE & SUBTITLE
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenEdgeGutter,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            context.tr('auth.welcomeTitleClean'),
                            textAlign: TextAlign.center,
                            style: context.text.displayLarge.copyWith(
                              color: colors.textPrimary,
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
                              style: context.text.bodySmall.copyWith(
                                color: colors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // SHEET-STYLE FORM CONTAINER
                    // Sizes dynamically to its active tab content (compact on Sign In,
                    // expanding on Register), while minSheetHeight ensures it touches
                    // the bottom of the screen gracefully on resting viewports.
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minSheetHeight),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(36),
                          ),
                          border: Border(
                            top: BorderSide(color: colors.border, width: 1.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow,
                              blurRadius: 24,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(
                          24,
                          26,
                          24,
                          bottomPadding + 28,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tab Pill Switcher (Sign In vs Sign Up)
                            _TabPillSwitcher(
                              selectedIndex: _activeTabIndex,
                              onTabChanged: _switchTab,
                              colors: colors,
                            ),

                            const SizedBox(height: 24),

                            // Tab Form Views (Animated)
                            AnimatedCrossFade(
                              firstChild: _SignInForm(
                                controller: loginController,
                                onSwitchToRegister: () => _switchTab(1),
                                colors: colors,
                              ),
                              secondChild: _SignUpForm(
                                controller: registerController,
                                loginController: loginController,
                                onSwitchToLogin: () => _switchTab(0),
                                colors: colors,
                              ),
                              crossFadeState: _activeTabIndex == 0
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              duration: const Duration(milliseconds: 250),
                              sizeCurve: Curves.easeInOut,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
  final HajiColors colors;

  const _CurvedArchHeader({required this.colors});

  @override
  Widget build(BuildContext context) {
    const headerHeight = 215.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        return SizedBox(
          height: headerHeight,
          width: screenWidth,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              CustomPaint(
                size: Size(screenWidth, headerHeight),
                painter: _CurvedArchShadowPainter(colors: colors),
              ),
              ClipPath(
                clipper: const _CurvedArchClipper(),
                child: SizedBox(
                  height: headerHeight,
                  width: screenWidth,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/haji.webp',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.2),
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colors.canvas,
                          child: Center(
                            child: Icon(
                              Icons.mosque_rounded,
                              color: colors.primary,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.05),
                              colors.canvas.withValues(alpha: 0.50),
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
                    color: colors.surface.withValues(alpha: 0.92),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
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
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.mosque_rounded,
                        size: 20,
                        color: colors.accent,
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
  final HajiColors colors;

  const _CurvedArchShadowPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _CurvedArchClipper.getArchPath(size);
    final shadowColor = colors.shadow;

    final ambientPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    canvas.drawPath(path.shift(const Offset(0, 6)), ambientPaint);

    final contactPaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path.shift(const Offset(0, 2)), contactPaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedArchShadowPainter oldDelegate) => false;
}

// =============================================================================
// TAB PILL SWITCHER (Masuk vs Daftar)
// =============================================================================
class _TabPillSwitcher extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final HajiColors colors;

  const _TabPillSwitcher({
    required this.selectedIndex,
    required this.onTabChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceSand,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: context.tr('auth.tabSignIn'),
              isSelected: selectedIndex == 0,
              onTap: () => onTabChanged(0),
              colors: colors,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              title: context.tr('auth.tabSignUp'),
              isSelected: selectedIndex == 1,
              onTap: () => onTabChanged(1),
              colors: colors,
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
  final HajiColors colors;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = colors.primary;
    final activeText = colors.onPrimary;
    final inactiveText = colors.textSecondary;

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
                    color: colors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: context.text.bodySmall.copyWith(
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
  final HajiColors colors;

  const _SignInForm({
    required this.controller,
    required this.onSwitchToRegister,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email
        Text(
          context.tr('auth.email'),
          style: context.text.labelLarge.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: controller.emailController,
          hintText: context.tr('auth.emailHint'),
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            color: colors.accent,
            size: 20,
          ),
        ),

        const SizedBox(height: 14),

        // Password
        Text(
          context.tr('auth.password'),
          style: context.text.labelLarge.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 8),

        Obx(
          () => AppTextField(
            controller: controller.passwordController,
            hintText: context.tr('auth.passwordHint'),
            obscureText: controller.obscurePassword.value,
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: colors.accent,
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
                color: colors.textSecondary,
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
                  activeColor: colors.primary,
                  checkColor: colors.onPrimary,
                  side: BorderSide(color: colors.borderStrong, width: 1.5),
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
                  style: context.text.labelSmall.copyWith(
                    color: colors.textSecondary,
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
                style: context.text.labelSmall.copyWith(
                  color: colors.accentText,
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
              color: colors.primary,
              textColor: colors.onPrimary,
              onPressed: controller.isLoading.value ? null : controller.login,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Centered Divider
        _DividerWithText(text: context.tr('auth.orDivider'), colors: colors),

        const SizedBox(height: 14),

        // Google Sign-In Button
        _GoogleSignInButton(controller: controller, colors: colors),

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
                  style: context.text.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: context.tr('auth.registerNow'),
                      style: context.text.bodySmall.copyWith(
                        color: colors.accentText,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.accent,
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
  final HajiColors colors;

  const _SignUpForm({
    required this.controller,
    required this.loginController,
    required this.onSwitchToLogin,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Selector (Compact)
        Text(
          context.tr('auth.registerAs'),
          style: context.text.labelLarge.copyWith(color: colors.textPrimary),
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
                  colors: colors,
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
                  colors: colors,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Full Name
        Text(
          context.tr('fullNameLabel'),
          style: context.text.labelLarge.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: controller.fullNameController,
          hintText: context.tr('auth.fullNameHint'),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: colors.accent,
            size: 20,
          ),
        ),

        const SizedBox(height: 18),

        // NIK (Nomor Induk Kependudukan - Optional)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                context.tr('auth.nikLabel'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceSand,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                context.tr('common.optional'),
                style: context.text.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: controller.nikController,
          hintText: context.tr('auth.nikHint'),
          keyboardType: TextInputType.number,
          prefixIcon: Icon(
            Icons.badge_outlined,
            color: colors.accent,
            size: 20,
          ),
        ),

        const SizedBox(height: 18),

        // Active Email
        Text(
          context.tr('auth.activeEmail'),
          style: context.text.labelLarge.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 8),

        AppTextField(
          controller: controller.emailController,
          hintText: context.tr('auth.emailHint'),
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            color: colors.accent,
            size: 20,
          ),
        ),

        const SizedBox(height: 18),

        // Password
        Text(
          context.tr('auth.password'),
          style: context.text.labelLarge.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: 8),

        Obx(
          () => AppTextField(
            controller: controller.passwordController,
            hintText: context.tr('auth.passwordMin6Hint'),
            obscureText: controller.obscurePassword.value,
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: colors.accent,
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
                color: colors.textSecondary,
                size: 20,
              ),
              onPressed: controller.togglePasswordVisibility,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          context.tr('auth.passwordMin6Desc'),
          style: context.text.labelSmall.copyWith(color: colors.textSecondary),
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
              color: colors.primary,
              textColor: colors.onPrimary,
              onPressed: controller.isLoading.value
                  ? null
                  : controller.register,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Centered Divider
        _DividerWithText(text: context.tr('auth.orDivider'), colors: colors),

        const SizedBox(height: 20),

        // Google Sign-In Button
        _GoogleSignInButton(controller: loginController, colors: colors),

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
                  style: context.text.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: context.tr('auth.loginNow'),
                      style: context.text.bodySmall.copyWith(
                        color: colors.accentText,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                        decorationColor: colors.accent,
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
  final HajiColors colors;

  const _RoleChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final activeBorderColor = colors.primary;
    final inactiveBorderColor = colors.border;
    final activeBg = colors.primaryContainer.withValues(alpha: 0.35);
    final inactiveBg = colors.surface;

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
              color: isSelected ? colors.primary : colors.accent,
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
                    style: context.text.labelSmall.copyWith(
                      color: colors.textPrimary,
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
                    style: context.text.labelSmall.copyWith(
                      fontSize: 10,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 16, color: colors.primary),
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
  final HajiColors colors;

  const _DividerWithText({required this.text, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Divider(color: colors.border, height: 1)),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(child: Divider(color: colors.border, height: 1)),
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
  final HajiColors colors;

  const _GoogleSignInButton({required this.controller, required this.colors});

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
            backgroundColor: colors.surface,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          child: controller.isGoogleLoading.value
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: colors.primary,
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
                        style: context.text.bodySmall.copyWith(
                          color: colors.textPrimary,
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
