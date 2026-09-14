import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/models/jamaah_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../services/room_service.dart';

class AddJamaahDialog extends StatefulWidget {
  final String roomId;

  const AddJamaahDialog({super.key, required this.roomId});

  static void show(BuildContext context, String roomId) {
    Get.bottomSheet(
      AddJamaahDialog(roomId: roomId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<AddJamaahDialog> createState() => _AddJamaahDialogState();
}

class _AddJamaahDialogState extends State<AddJamaahDialog> {
  final RoomService _roomService = RoomService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<JamaahData> _allJamaah = [];
  List<JamaahData> _filteredJamaah = [];
  bool _isLoading = true;
  String? _submittingUid;

  @override
  void initState() {
    super.initState();
    _loadAvailableJamaah();
  }

  Future<void> _loadAvailableJamaah() async {
    setState(() => _isLoading = true);
    try {
      final list = await _roomService.getAvailableJamaahList();
      if (mounted) {
        setState(() {
          _allJamaah = list;
          _filteredJamaah = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredJamaah = _allJamaah;
      } else {
        _filteredJamaah = _allJamaah
            .where((j) =>
                j.name.toLowerCase().contains(q) ||
                (j.porsi != null && j.porsi!.toLowerCase().contains(q)))
            .toList();
      }
    });
  }

  Future<void> _addJamaah(JamaahData jamaah) async {
    setState(() => _submittingUid = jamaah.id);
    try {
      await _roomService.addJamaahToRoom(
        roomId: widget.roomId,
        jamaahUid: jamaah.id,
        jamaahName: jamaah.name,
      );

      Get.back(); // Close bottomsheet
      AppAlert.success(
        null,
        title: 'Berhasil Ditambahkan',
        message: '${jamaah.name} telah dimasukkan ke dalam room.',
      );
    } catch (e) {
      AppAlert.error(
        null,
        title: 'Gagal Menambahkan',
        message: '$e',
      );
    } finally {
      if (mounted) {
        setState(() => _submittingUid = null);
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.surfaceWhite;
    final headingColor = isDark ? AppColors.darkTextHeading : AppColors.espressoDark;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGold;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        top: AppSpacing.md,
        left: AppSpacing.screenEdgeGutter,
        right: AppSpacing.screenEdgeGutter,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: bodyColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),

          // Title
          Text(
            'Tambah Jamaah ke Room',
            style: AppTypography.titleMedium.copyWith(
              color: headingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih akun Jamaah yang belum terdaftar di room manapun.',
            style: AppTypography.captionSmall.copyWith(color: bodyColor),
          ),
          const SizedBox(height: AppSpacing.md),

          // Search Field
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            decoration: InputDecoration(
              hintText: 'Cari nama atau nomor porsi...',
              prefixIcon: Icon(Icons.search_rounded, color: bodyColor),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkPrimaryContainer.withValues(alpha: 0.3)
                  : AppColors.canvasCream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // List or Loading
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredJamaah.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 48, color: bodyColor.withValues(alpha: 0.4)),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Tidak ada akun Jamaah yang belum memiliki room.',
                              textAlign: TextAlign.center,
                              style: AppTypography.captionSmall.copyWith(color: bodyColor),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredJamaah.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final jamaah = _filteredJamaah[index];
                          final isSubmitting = _submittingUid == jamaah.id;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: primaryColor.withValues(alpha: 0.15),
                              child: Text(
                                jamaah.shortLabel.isNotEmpty ? jamaah.shortLabel[0] : 'J',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              jamaah.name,
                              style: AppTypography.titleSmall.copyWith(
                                color: headingColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              jamaah.porsi != null && jamaah.porsi!.isNotEmpty
                                  ? 'Porsi: ${jamaah.porsi}'
                                  : 'Akun Jamaah',
                              style: AppTypography.captionSmall.copyWith(color: bodyColor),
                            ),
                            trailing: ElevatedButton(
                              onPressed: isSubmitting ? null : () => _addJamaah(jamaah),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: AppColors.surfaceWhite,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Tambahkan', style: TextStyle(fontSize: 12)),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
