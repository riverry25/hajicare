import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/models/jamaah_data.dart';
import 'package:hajicare/features/dashboard/widgets/mini_sparkline_button.dart';

void main() {
  group('MiniSparklineButton Widget Tests', () {
    testWidgets('Renders MiniSparklineButton with wave painter and tooltip', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiniSparklineButton(
                tooltip: 'Sinkronisasi Data Rombongan & Lokasi',
                onSync: () async {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(MiniSparklineButton), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('Tapping MiniSparklineButton triggers onSync callback', (
      tester,
    ) async {
      bool synced = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MiniSparklineButton(
                onSync: () async {
                  synced = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MiniSparklineButton));
      await tester.pump();

      expect(synced, isTrue);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'MiniSparklineButton renders with jamaahList with all safe members',
      (tester) async {
        final jamaahList = [
          JamaahData(
            id: 'j1',
            name: 'Ahmad',
            shortLabel: 'Ahmad',
            distance: 30,
          ),
          JamaahData(id: 'j2', name: 'Budi', shortLabel: 'Budi', distance: 50),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MiniSparklineButton(
                  onSync: () async {},
                  jamaahList: jamaahList,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(MiniSparklineButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'MiniSparklineButton renders with jamaahList with danger members',
      (tester) async {
        final jamaahList = [
          JamaahData(
            id: 'j1',
            name: 'Ahmad',
            shortLabel: 'Ahmad',
            distance: 600,
          ),
          JamaahData(id: 'j2', name: 'Budi', shortLabel: 'Budi', distance: 800),
        ];

        for (final j in jamaahList) {
          j.tier = DistanceTier.terlalujJauh;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MiniSparklineButton(
                  onSync: () async {},
                  jamaahList: jamaahList,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(MiniSparklineButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
