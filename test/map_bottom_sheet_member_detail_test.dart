import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/state/hajicare_state.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/map/widgets/map_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  Widget buildTestBottomSheet({
    required RoomMemberModel member,
    VoidCallback? onCall,
    VoidCallback? onShareLocation,
    VoidCallback? onNavigate,
    VoidCallback? onClose,
    double? routeDistance,
    int? routeDuration,
  }) {
    final state = Get.put(HajiCareController(), permanent: true);

    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: Scaffold(
        body: Stack(
          children: [
            MapBottomSheet(
              state: state,
              selectedMember: member,
              onCall: onCall,
              onShareLocation: onShareLocation,
              onNavigate: onNavigate,
              onCloseMemberDetail: onClose,
              routeDistanceMeters: routeDistance,
              routeDurationSeconds: routeDuration,
            ),
          ],
        ),
      ),
    );
  }

  group('MapBottomSheet Reference Design Tests', () {
    testWidgets(
      'Renders compact UI: Centered Avatar, Name, Location Update, Condition Status, Quick Actions, and 3 Columns',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        bool closeTriggered = false;

        final member = RoomMemberModel(
          uid: 'devin-01',
          name: 'Devin Onim',
          role: 'jamaah',
          currentLocation: const GeoPoint(-6.2, 106.8),
          locationUpdatedAt: DateTime.now().subtract(
            const Duration(minutes: 5),
          ),
        );

        await tester.pumpWidget(
          buildTestBottomSheet(
            member: member,
            onClose: () => closeTriggered = true,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Member Name is displayed in title
        expect(find.text('Devin Onim'), findsOneWidget);

        // 2. Verify Star rating icons are removed
        expect(find.byIcon(Icons.star_rounded), findsNothing);
        expect(find.byIcon(Icons.star_outline_rounded), findsNothing);

        // 3. Verify Location update info is displayed
        expect(find.textContaining('Update'), findsOneWidget);

        // 4. Verify Health / Safety condition icon (replacing stars)
        expect(find.byIcon(Icons.health_and_safety_rounded), findsOneWidget);
        expect(find.text('Aman'), findsOneWidget);

        // 5. Verify Quick Action Call and Message buttons are removed
        expect(find.byIcon(Icons.phone_rounded), findsNothing);
        expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);

        // 6. Verify 3-Column Stats Box (Kondisi, Movement, Shield)
        expect(find.byIcon(Icons.directions_walk_rounded), findsOneWidget);
        expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

        // 7. Verify Close text button
        final closeBtnFinder = find.text('Tutup');
        expect(closeBtnFinder, findsOneWidget);
        await tester.tap(closeBtnFinder);
        await tester.pumpAndSettle();
        expect(closeTriggered, isTrue);
      },
    );
  });
}
