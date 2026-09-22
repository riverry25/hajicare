import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/models/filter_chip_item.dart';
import 'package:hajicare/features/map/widgets/map_top_header.dart';

void main() {
  group('MapTopHeader Widget Tests', () {
    final testFilters = [
      FilterChipItem(label: 'Semua', icon: Icons.tune_rounded),
      FilterChipItem(label: 'Jamaah', icon: Icons.person_rounded),
      FilterChipItem(
        label: 'Posko Medis',
        icon: Icons.medical_services_rounded,
      ),
    ];

    testWidgets(
      'Renders Google Maps style floating header with transparent layout',
      (tester) async {
        int selectedIndex = 0;
        bool sosPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppTranslations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FallbackMaterialLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
            ],
            home: Scaffold(
              body: Stack(
                children: [
                  MapTopHeader(
                    filters: testFilters,
                    selectedFilter: selectedIndex,
                    onFilterSelected: (idx) => selectedIndex = idx,
                    onSosPressed: () => sosPressed = true,
                    gpsAccuracy: 12.0,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Check search hint
        expect(
          find.text('Cari maktab, posko medis, atau tenda...'),
          findsOneWidget,
        );

        // Check Google Maps style Pin icon and Mic icon
        expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
        expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

        // Check GPS status pill
        expect(find.text('GPS ±12m'), findsOneWidget);

        // Check SOS button
        expect(find.text('SOS'), findsOneWidget);
        await tester.tap(find.text('SOS'));
        expect(sosPressed, isTrue);

        // Check filter chips
        expect(find.text('Semua'), findsOneWidget);
        expect(find.text('Jamaah'), findsOneWidget);
        expect(find.text('Posko Medis'), findsOneWidget);

        // Tap on 'Posko Medis' chip
        await tester.tap(find.text('Posko Medis'));
        expect(selectedIndex, 2);
      },
    );

    testWidgets(
      'Fires onSearchFocused when search field is tapped or focused while empty',
      (tester) async {
        bool searchFocused = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  MapTopHeader(
                    filters: testFilters,
                    selectedFilter: 0,
                    onFilterSelected: (_) {},
                    onSosPressed: () {},
                    onSearchFocused: () => searchFocused = true,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byType(TextField));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(searchFocused, isTrue);
      },
    );
  });
}
