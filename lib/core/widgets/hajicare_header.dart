import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Reusable, accessible, and premium header component for HajiCare screens.
///
/// Implements [PreferredSizeWidget] so it can be used directly as [Scaffold.appBar].
/// Designed to follow the HajiCare design system with:
/// - Consistent branded icon presentation (circular emblem with gold/espresso tint)
/// - Clear typography hierarchy (Title + optional Subtitle)
/// - Flexible leading (hamburger menu, back button, or none)
/// - Flexible actions with comfortable tap targets (minimum 48dp)
/// - Automatic theme adaptability for Light and Dark modes
class HajiCareHeader extends StatelessWidget implements PreferredSizeWidget {
  /// Primary title text of the page.
  final String title;

  /// Optional subtitle explaining the section purpose.
  final String? subtitle;

  /// Icon displayed in the circular emblem next to the title.
  final IconData? icon;

  /// Optional image asset path for the circular emblem. Defaults to 'assets/icon.jpeg'.
  final String? imageAsset;

  /// Whether to use the app image logo instead of a vector icon. Defaults to true when icon is null or Icons.mosque_rounded.
  final bool? useAppLogo;

  /// Optional custom leading widget. If specified, overrides [showBackButton].
  final Widget? leading;

  /// Whether to show a standardized back button.
  final bool showBackButton;

  /// Callback when the back button is pressed. Defaults to [Get.back].
  final VoidCallback? onBack;

  /// Trailing action widgets (e.g., notification, SOS, GPS refresh).
  final List<Widget>? actions;

  /// Optional bottom widget (e.g., TabBar).
  final PreferredSizeWidget? bottom;

  /// Custom height if needed. Defaults to 72dp when subtitle is present, or 64dp otherwise.
  final double? height;

  /// Background color override. Defaults to [AppColors.scaffoldColor].
  final Color? backgroundColor;

  /// Optional custom widget to replace the default title column.
  final Widget? titleWidget;

  const HajiCareHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.imageAsset,
    this.useAppLogo,
    this.leading,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.bottom,
    this.height,
    this.backgroundColor,
    this.titleWidget,
  });

  @override
  Size get preferredSize {
    final effectiveHeight =
        height ?? (subtitle != null && subtitle!.isNotEmpty ? 72.0 : 64.0);
    return Size.fromHeight(
      effectiveHeight + (bottom?.preferredSize.height ?? 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final headingColor = AppColors.textHeadingColor(context);
    final bodyColor = AppColors.textBodyColor(context);
    final scaffoldBg = backgroundColor ?? AppColors.scaffoldColor(context);

    // Determine leading widget
    Widget? effectiveLeading;
    if (leading != null) {
      effectiveLeading = leading;
    } else if (showBackButton) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: headingColor,
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: onBack ?? () => Get.back(),
      );
    }

    final hasLeading = effectiveLeading != null;
    final showLogoImage =
        (useAppLogo ??
            (icon == null ||
                icon == Icons.mosque_rounded ||
                icon == Icons.mosque)) &&
        !hasLeading;

    return AppBar(
      backgroundColor: scaffoldBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: effectiveLeading,
      titleSpacing: hasLeading ? 0 : AppSpacing.screenEdgeGutter,
      title:
          titleWidget ??
          Row(
            children: [
              if (showLogoImage) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      imageAsset ?? 'assets/icon.jpeg',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          icon ?? Icons.mosque_rounded,
                          color: isDark
                              ? AppColors.goldLight
                              : AppColors.accentGoldStar,
                          size: 19,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryContainer
                        : AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isDark
                        ? AppColors.goldLight
                        : AppColors.accentGoldStar,
                    size: 19,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleLarge.copyWith(
                        color: headingColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: bodyColor.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
      actions: actions,
      bottom: bottom,
    );
  }
}
