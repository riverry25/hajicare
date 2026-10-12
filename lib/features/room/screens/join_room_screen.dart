import '../../../core/locales/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/join_room_controller.dart';
import '../widgets/qr_scanner_dialog.dart';

class JoinRoomScreen extends StatelessWidget {
  const JoinRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<JoinRoomController>();
    final hc = context.hc;
    final text = context.text;

    return Scaffold(
      backgroundColor: hc.canvas,
      appBar: AppBar(
        backgroundColor: hc.canvas,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: hc.textPrimary,
            size: 20,
          ),
          onPressed: () {
            if (controller.isSyncing.value) return;
            if (Navigator.of(context).canPop()) {
              Get.back();
            } else {
              controller.selectedMode.value == 0
                  ? Get.offAllNamed('/dashboard_pendamping')
                  : (controller.isPendamping
                        ? Get.offAllNamed('/dashboard_pendamping')
                        : Get.offAllNamed('/dashboard_jamaah'));
            }
          },
        ),
        title: Obx(
          () => Text(
            controller.isSyncing.value
                ? context.tr('room.syncing')
                : (controller.isPendamping
                      ? context.tr('profileRoomMonitoring')
                      : context.tr('room.joinRoomTitle')),
            style: text.titleMedium.copyWith(
              color: hc.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenEdgeGutter,
              vertical: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Hero Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            hc.brand.withValues(alpha: 0.15),
                            hc.brand.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: hc.border, width: 2),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.meeting_room_rounded,
                          size: 38,
                          color: hc.brand,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Header Title & Subtitle
                  Obx(() {
                    if (controller.isSyncing.value) {
                      return Column(
                        children: [
                          Text(
                            context.tr('room.syncingRoomData'),
                            textAlign: TextAlign.center,
                            style: text.headlineMedium.copyWith(
                              color: hc.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            context.tr('room.syncingPleaseWait'),
                            textAlign: TextAlign.center,
                            style: text.bodySmall.copyWith(
                              color: hc.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      );
                    }
                    final isCreating =
                        controller.isPendamping &&
                        controller.selectedMode.value == 0;
                    return Column(
                      children: [
                        Text(
                          isCreating
                              ? context.tr('roomCreateNew')
                              : context.tr('room.joinRoomTitle'),
                          textAlign: TextAlign.center,
                          style: text.headlineMedium.copyWith(
                            color: hc.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          isCreating
                              ? context.tr('roomCreateSubtitle')
                              : context.tr('roomJoinSubtitle'),
                          textAlign: TextAlign.center,
                          style: text.bodySmall.copyWith(
                            color: hc.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: AppSpacing.lg),

                  // Mode Switcher for Pendamping
                  if (controller.isPendamping) ...[
                    Obx(() {
                      if (controller.isSyncing.value) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: hc.surfaceSand,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: hc.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ModeTabButton(
                                label: context.tr('room.createRoomBtn'),
                                icon: Icons.add_business_rounded,
                                isSelected: controller.selectedMode.value == 0,
                                onTap: () => controller.selectedMode.value = 0,
                              ),
                            ),
                            Expanded(
                              child: _ModeTabButton(
                                label: context.tr('room.joinRoomTitle'),
                                icon: Icons.login_rounded,
                                isSelected: controller.selectedMode.value == 1,
                                onTap: () => controller.selectedMode.value = 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Main Form Card
                  AppCard(
                    backgroundColor: hc.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Obx(() {
                        if (controller.isSyncing.value) {
                          return _buildSyncingSkeleton(context, controller);
                        }
                        if (controller.isPendamping &&
                            controller.selectedMode.value == 0) {
                          return _buildCreateRoomForm(context, controller);
                        } else {
                          return _buildJoinRoomForm(context, controller);
                        }
                      }),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Bottom Info & Switch Account
                  Obx(() {
                    if (controller.isSyncing.value) {
                      return const SizedBox.shrink();
                    }
                    return Center(
                      child: TextButton.icon(
                        onPressed: () => controller.switchAccount(),
                        icon: Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: hc.textSecondary,
                        ),
                        label: Text(
                          context.tr('roomSwitchAccount'),
                          style: text.bodySmall.copyWith(
                            color: hc.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateRoomForm(
    BuildContext context,
    JoinRoomController controller,
  ) {
    final hc = context.hc;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room Name Field
        Text(
          context.tr('roomNameRequired'),
          style: text.labelMedium.copyWith(
            color: hc.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.createRoomNameController,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          style: text.bodyMedium.copyWith(color: hc.textPrimary),
          decoration: InputDecoration(
            hintText: context.tr('roomNameHint'),
            hintStyle: text.bodyMedium.copyWith(color: hc.textTertiary),
            prefixIcon: Icon(Icons.groups_rounded, color: hc.brand, size: 20),
            filled: true,
            fillColor: hc.surfaceSand.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.brand, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Maktab Field
        Text(
          context.tr('roomMaktabOptional'),
          style: text.labelMedium.copyWith(
            color: hc.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.createMaktabController,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          style: text.bodyMedium.copyWith(color: hc.textPrimary),
          decoration: InputDecoration(
            hintText: context.tr('roomMaktabHint'),
            hintStyle: text.bodyMedium.copyWith(color: hc.textTertiary),
            prefixIcon: Icon(Icons.hotel_rounded, color: hc.brand, size: 20),
            filled: true,
            fillColor: hc.surfaceSand.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.brand, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Kloter Field
        Text(
          context.tr('roomKloterOptional'),
          style: text.labelMedium.copyWith(
            color: hc.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.createKloterController,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          style: text.bodyMedium.copyWith(color: hc.textPrimary),
          decoration: InputDecoration(
            hintText: context.tr('roomKloterHint'),
            hintStyle: text.bodyMedium.copyWith(color: hc.textTertiary),
            prefixIcon: Icon(
              Icons.flight_takeoff_rounded,
              color: hc.brand,
              size: 20,
            ),
            filled: true,
            fillColor: hc.surfaceSand.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.brand, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Submit Button
        Obx(
          () => SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.createRoom(),
              icon: controller.isLoading.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: hc.onPrimary,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text(
                controller.isLoading.value
                    ? context.tr('roomCreating')
                    : context.tr('roomCreateNow'),
                style: text.labelLarge.copyWith(
                  color: hc.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hc.brand,
                foregroundColor: hc.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinRoomForm(
    BuildContext context,
    JoinRoomController controller,
  ) {
    final hc = context.hc;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // QR Code Scanner Action Button
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : () async {
                    final scannedCode = await QrScannerDialog.show(context);
                    if (scannedCode != null && scannedCode.isNotEmpty) {
                      controller.joinRoom(scannedCode);
                    }
                  },
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 22),
            label: Text(
              context.tr('roomScanCompanionQr'),
              style: text.labelLarge.copyWith(
                color: hc.brand,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: hc.brand,
              side: BorderSide(color: hc.brand, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Divider with "ATAU KODE MANUAL"
        Row(
          children: [
            Expanded(child: Divider(color: hc.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.tr('roomOrManualCode'),
                style: text.captionSmall.copyWith(
                  color: hc.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            Expanded(child: Divider(color: hc.border)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        Text(
          context.tr('roomCodeLengthLabel'),
          style: text.labelMedium.copyWith(
            color: hc.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller.roomCodeController,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'[A-HJ-NP-Za-hj-np-z2-9]'),
            ),
            UpperCaseTextFormatter(),
          ],
          textAlign: TextAlign.center,
          style: text.headlineMedium.copyWith(
            color: hc.brand,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'KODE6',
            hintStyle: text.headlineMedium.copyWith(
              color: hc.textTertiary.withValues(alpha: 0.5),
              letterSpacing: 8,
            ),
            filled: true,
            fillColor: hc.surfaceSand.withValues(alpha: 0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: hc.brand, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Submit Button
        Obx(
          () => SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: controller.isLoading.value
                  ? null
                  : () => controller.joinRoom(),
              icon: controller.isLoading.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: hc.onPrimary,
                      ),
                    )
                  : const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                controller.isLoading.value
                    ? context.tr('roomJoiningProcessing')
                    : context.tr('room.joinRoomTitle'),
                style: text.labelLarge.copyWith(
                  color: hc.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hc.brand,
                foregroundColor: hc.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncingSkeleton(
    BuildContext context,
    JoinRoomController controller,
  ) {
    final hc = context.hc;
    final text = context.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Rotating Sync Progress Header
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hc.brand.withValues(alpha: 0.12),
              border: Border.all(color: hc.border, width: 1.5),
            ),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(hc.brand),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Real-time status text
        Obx(
          () => Text(
            controller.syncStatus.value.isNotEmpty
                ? controller.syncStatus.value
                : context.tr('room.syncingRoomData'),
            textAlign: TextAlign.center,
            style: text.titleMedium.copyWith(
              color: hc.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.tr('room.syncingPleaseWait'),
          textAlign: TextAlign.center,
          style: text.bodySmall.copyWith(color: hc.textSecondary, height: 1.35),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Shimmering Preview Container
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: hc.surfaceSand,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: hc.border, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: hc.brand.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      size: 18,
                      color: hc.brand,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: hc.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 90,
                          height: 10,
                          decoration: BoxDecoration(
                            color: hc.border.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  backgroundColor: hc.border.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(hc.brand),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hc = context.hc;
    final text = context.text;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? hc.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? hc.onPrimary : hc.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: text.labelLarge.copyWith(
                color: isSelected ? hc.onPrimary : hc.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
