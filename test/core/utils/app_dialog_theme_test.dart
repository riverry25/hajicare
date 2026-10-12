import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/theme/app_breakpoints.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/core/theme/haji_colors.dart';
import 'package:hajicare/core/theme/theme_context.dart';
import 'package:hajicare/core/utils/app_dialog.dart';

void main() {
  testWidgets('AppDialog.success renders with semantic tokens in light theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialog.success(
                    context: context,
                    title: 'Berhasil',
                    message: 'Operasi sukses diselesaikan.',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Operasi sukses diselesaikan.'), findsOneWidget);

    // Verify dialog width is constrained by maxDialogWidth
    final dialogContainer = tester.widget<ConstrainedBox>(
      find.byWidgetPredicate(
        (w) =>
            w is ConstrainedBox &&
            w.constraints.maxWidth == AppBreakpoints.maxDialogWidth,
      ),
    );
    expect(
      dialogContainer.constraints.maxWidth,
      AppBreakpoints.maxDialogWidth,
    );
  });

  testWidgets('AppDialog renders in dark theme without crash or overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialog.error(
                    context: context,
                    title: 'Gagal',
                    message: 'Terjadi kesalahan sistem.',
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Gagal'), findsOneWidget);
    expect(find.text('Terjadi kesalahan sistem.'), findsOneWidget);
  });
}
