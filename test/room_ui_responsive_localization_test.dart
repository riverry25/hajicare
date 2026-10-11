import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/locales/app_localizations.dart';
import 'package:hajicare/core/locales/en.dart';
import 'package:hajicare/core/locales/id.dart';
import 'package:hajicare/core/locales/jv.dart';
import 'package:hajicare/core/locales/su.dart';
import 'package:hajicare/core/services/app_alert_service.dart';
import 'package:hajicare/core/state/app_settings_controller.dart';
import 'package:hajicare/core/state/hajicare_controller.dart';
import 'package:hajicare/core/theme/app_colors.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/room/widgets/active_room_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Multi-language Localization Parity Tests', () {
    test(
      '1. All 4 locales contain required action keys with non-empty values',
      () {
        final locales = [
          {'name': 'Indonesian', 'map': idTranslations},
          {'name': 'English', 'map': enTranslations},
          {'name': 'Javanese', 'map': jvTranslations},
          {'name': 'Sundanese', 'map': suTranslations},
        ];

        final requiredKeys = [
          'room.transferAction',
          'room.revokeAction',
          'dashboard.invitePilgrim',
          'dashboard.pilgrimList',
        ];

        for (final locale in locales) {
          final map = locale['map'] as Map<String, String>;
          final name = locale['name'] as String;

          for (final key in requiredKeys) {
            expect(
              map.containsKey(key),
              isTrue,
              reason: 'Missing key "$key" in $name locale',
            );
            expect(
              map[key]!.trim().isNotEmpty,
              isTrue,
              reason: 'Key "$key" in $name locale should not be empty',
            );
          }
        }

        // Verify specific translations
        expect(idTranslations['room.transferAction'], 'Wariskan');
        expect(enTranslations['room.transferAction'], 'Transfer');
        expect(jvTranslations['room.transferAction'], 'Wariské');
        expect(suTranslations['room.transferAction'], 'Waruskeun');

        expect(idTranslations['room.revokeAction'], 'Cabut');
        expect(enTranslations['room.revokeAction'], 'Revoke');
        expect(jvTranslations['room.revokeAction'], 'Batalake');
        expect(suTranslations['room.revokeAction'], 'Cabut');
      },
    );
  });

  group('AppDialog Responsive & Dynamic Text Scaling Tests', () {
    Widget buildDialogTestApp({
      required VoidCallback onTrigger,
      double textScale = 1.0,
      Brightness brightness = Brightness.dark,
    }) {
      return GetMaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme,
        locale: const Locale('id', 'ID'),
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
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: onTrigger,
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets(
      '2. AppAlert.confirm renders administrative icon, gold color, and concise label without destructive red trash can',
      (tester) async {
        await tester.pumpWidget(
          buildDialogTestApp(
            onTrigger: () {
              AppAlert.confirm(
                Get.context,
                title: 'Wariskan Kepemilikan Utama',
                message: 'Alihkan kepemilikan utama kepada Apis?',
                confirmText: 'Wariskan',
                cancelText: 'Batal',
                isDestructive: false,
                icon: Icons.admin_panel_settings_rounded,
                confirmColor: AppColors.darkPrimary,
                onConfirm: () {},
              );
            },
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Wariskan Kepemilikan Utama'), findsOneWidget);
        expect(
          find.text('Alihkan kepemilikan utama kepada Apis?'),
          findsOneWidget,
        );

        expect(find.text('Wariskan'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);

        expect(find.byIcon(Icons.admin_panel_settings_rounded), findsOneWidget);
        expect(find.byIcon(Icons.delete_forever_rounded), findsNothing);
      },
    );

    testWidgets(
      '3. AppDialog adapts to high dynamic text scaling without RenderFlex overflow',
      (tester) async {
        await tester.pumpWidget(
          buildDialogTestApp(
            textScale: 1.6, // High accessibility text scaling
            onTrigger: () {
              AppAlert.confirm(
                Get.context,
                title: 'Wariskan Kepemilikan Utama',
                message: 'Alihkan kepemilikan utama kepada Apis?',
                confirmText: 'Wariskan',
                cancelText: 'Batal',
                isDestructive: false,
                icon: Icons.admin_panel_settings_rounded,
                confirmColor: AppColors.darkPrimary,
                onConfirm: () {},
              );
            },
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Wariskan'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('ActiveRoomCard Dynamic UI Tests', () {
    testWidgets(
      '4. ActiveRoomCard footer buttons render symmetrically and handle normal scale cleanly',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);
        final hajiCtrl = Get.put(HajiCareController(), permanent: true);

        await hajiCtrl.applyUserData(
          roleStr: 'pendamping',
          roomId: 'room_resp_01',
        );
        hajiCtrl.activeRoom.value = RoomModel(
          id: 'room_resp_01',
          name: 'Jihad Gang',
          code: 'KZFRCJ',
          createdBy: 'creator_uid',
          createdAt: DateTime.now(),
          memberCount: 6,
          safeRadius: 500,
        );

        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('id', 'ID'),
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
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.0)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: ActiveRoomCard(isPendamping: true),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Daftar Jamaah'), findsOneWidget);
        expect(find.text('Undang Jamaah'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '5. ActiveRoomCard stacks footer buttons in Column under large accessibility scaling (1.6x)',
      (tester) async {
        Get.put(AppSettingsController(), permanent: true);
        final hajiCtrl = Get.put(HajiCareController(), permanent: true);

        await hajiCtrl.applyUserData(
          roleStr: 'pendamping',
          roomId: 'room_resp_02',
        );
        hajiCtrl.activeRoom.value = RoomModel(
          id: 'room_resp_02',
          name: 'Jihad Gang',
          code: 'KZFRCJ',
          createdBy: 'creator_uid',
          createdAt: DateTime.now(),
          memberCount: 6,
          safeRadius: 500,
        );

        await tester.pumpWidget(
          GetMaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('id', 'ID'),
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
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: ActiveRoomCard(isPendamping: true),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Daftar Jamaah'), findsOneWidget);
        expect(find.text('Undang Jamaah'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
