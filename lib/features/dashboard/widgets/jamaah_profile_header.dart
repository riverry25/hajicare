import 'package:flutter/material.dart';
import '../../../../core/state/hajicare_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/animated_ping_dot.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_badge.dart';

class JamaahProfileHeader extends StatelessWidget {
  final HajiCareState state;

  const JamaahProfileHeader({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.tanMedium.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'H. Ahmad Dahlan',
                            style: AppTypography.titleLarge.copyWith(
                              color: AppColors.espressoDark,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppColors.statusPositive,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kloter 14 JKS • Maktab 48, Mina',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textBody,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.format_size, color: AppColors.espressoDark),
                onPressed: () {},
                tooltip: 'Ubah Ukuran Teks',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.statusPositive.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const AnimatedPingDot(
                  color: AppColors.statusPositive,
                  size: 10,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'Terhubung: ',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.espressoDark,
                      ),
                      children: [
                        TextSpan(
                          text: state.pendampingName,
                          style: AppTypography.captionSmall.copyWith(
                            color: AppColors.textHeading,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const AppStatusBadge(
                  label: 'Aktif',
                  statusType: AppStatusType.safe,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
