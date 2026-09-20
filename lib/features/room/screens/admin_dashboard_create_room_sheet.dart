part of 'admin_dashboard_screen.dart';

extension _AdminDashboardCreateRoomSheet on _AdminDashboardHome {
  void _showCreateRoomSheet(
    BuildContext context,
    AdminRoomController controller,
  ) {
    final textCtrl = TextEditingController();
    final isDark = AppColors.isDark(context);
    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bodyColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.add_business_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Room Pantau Baru',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: headingColor,
                          ),
                        ),
                        Text(
                          'Kelompok / Maktab / Rombongan',
                          style: AppTypography.captionSmall.copyWith(
                            color: bodyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Masukkan nama kelompok atau maktab. Kode unik 6-karakter akan di-generate otomatis untuk dibagikan ke jamaah & pendamping.',
                style: AppTypography.bodySmall.copyWith(
                  color: bodyColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: textCtrl,
                autofocus: true,
                style: TextStyle(color: headingColor),
                decoration: InputDecoration(
                  labelText: 'Nama Kelompok / Room',
                  hintText: 'Misal: Maktab 48 Kloter 12',
                  hintStyle: TextStyle(color: bodyColor.withValues(alpha: 0.5)),
                  prefixIcon: Icon(
                    Icons.meeting_room_rounded,
                    color: primaryColor,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.canvasCream.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.canvasCreamSubtle,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkOutlineVariant
                          : AppColors.canvasCreamSubtle,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: primaryColor, width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Obx(() {
                final submitting = controller.isSubmitting.value;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark
                          ? AppColors.darkOnPrimary
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      elevation: 2,
                    ),
                    onPressed: submitting
                        ? null
                        : () => controller.createRoom(context, textCtrl.text),
                    child: submitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: isDark
                                  ? AppColors.darkOnPrimary
                                  : Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Simpan & Buat Room',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Active rooms bottom sheet
}
