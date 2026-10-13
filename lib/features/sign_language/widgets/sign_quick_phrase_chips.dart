import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/theme_context.dart';
import '../controllers/text_to_sign_controller.dart';

/// Deretan chip frasa cepat yang disesuaikan dengan bahasa isyarat aktif.
class SignQuickPhraseChips extends StatelessWidget {
  final TextToSignController controller;

  const SignQuickPhraseChips({super.key, required this.controller});

  static const List<String> sibiPhrases = [
    'Masjid',
    'Bantu',
    'Dokter',
    'Obat',
    'Sakit',
    'Makan',
    'Minum',
    'Hilang',
    'Sesat',
    'Tolong bantu saya',
  ];

  static const List<String> bisindoPhrases = [
    'Halo',
    'Apa Kabar',
    'Terima Kasih',
    'Dimana',
    'Siapa',
    'Baik',
    'Air',
    'Mandi',
    'A',
    'B',
    'J',
    'L',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.hc;
    final textTheme = context.text;

    return Obx(() {
      final lang = controller.selectedLanguage.value;
      final phrases = lang == 'sibi' ? sibiPhrases : bisindoPhrases;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: phrases.map((text) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(text),
                backgroundColor: colors.surfaceSand,
                labelStyle: textTheme.labelSmall.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  side: BorderSide(color: colors.border),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.dismissSuggestions();
                  controller.searchFocusNode.unfocus();
                  controller.textController.text = text;
                  controller.textController.selection =
                      TextSelection.fromPosition(
                        TextPosition(offset: text.length),
                      );
                  controller.searchSign(text, force: true);
                },
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}
