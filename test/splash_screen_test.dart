import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hajicare/core/routes/app_routes.dart';
import 'package:hajicare/core/state/app_startup_controller.dart';
import 'package:hajicare/core/theme/app_theme.dart';
import 'package:hajicare/features/splash/screens/splash_screen.dart';
import 'package:hajicare/features/splash/widgets/corner_capsules_loader.dart';
import 'package:hajicare/features/splash/widgets/kabbah_hero_widget.dart';
import 'package:lottie/lottie.dart';

class MockAppStartupController extends AppStartupController {
  @override
  Future<String> determineInitialRoute() async {
    return AppRoutes.login;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<AppStartupController>(MockAppStartupController());
  });

  tearDown(() {
    Get.reset();
  });

  group('SplashScreen Widget Tests', () {
    testWidgets('Renders SplashScreen components in Light Mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          getPages: [
            GetPage(name: AppRoutes.splash, page: () => const SizedBox()),
            GetPage(name: AppRoutes.login, page: () => const SizedBox()),
          ],
          home: const SplashScreen(bootstrapDelay: Duration(milliseconds: 50)),
        ),
      );

      // Verify corner loaders exist in top-left and bottom-right
      expect(find.byType(CornerCapsulesLoader), findsNWidgets(2));
      expect(find.byType(KabbahHeroWidget), findsOneWidget);
      expect(find.byType(LottieBuilder), findsOneWidget);

      // Verify brand title and text elements
      expect(
        find.text('رِعَايَةُ الحَجِيجِ وَالمُعْتَمِرِينَ'),
        findsOneWidget,
      );
      expect(find.text('Sahabat Setia & Amanah Ibadah Anda'), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Renders SplashScreen components in Dark Mode', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.darkTheme,
          getPages: [
            GetPage(name: AppRoutes.splash, page: () => const SizedBox()),
            GetPage(name: AppRoutes.login, page: () => const SizedBox()),
          ],
          home: const SplashScreen(bootstrapDelay: Duration(milliseconds: 50)),
        ),
      );

      expect(find.byType(CornerCapsulesLoader), findsNWidgets(2));
      expect(find.byType(KabbahHeroWidget), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('CornerCapsulesLoader animates entrance and shimmer wave', (
      tester,
    ) async {
      final vsync = tester;
      final entranceCtrl = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 900),
      )..forward();

      final shimmerCtrl = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 2200),
      )..repeat();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CornerCapsulesLoader(
                  position: CornerPosition.topLeft,
                  entranceAnim: entranceCtrl,
                  shimmerAnim: shimmerCtrl,
                ),
                CornerCapsulesLoader(
                  position: CornerPosition.bottomRight,
                  entranceAnim: entranceCtrl,
                  shimmerAnim: shimmerCtrl,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CornerCapsulesLoader), findsNWidgets(2));

      // Run the entrance to completion and a few sweep frames.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(entranceCtrl.isCompleted, isTrue);
      expect(tester.takeException(), isNull);

      entranceCtrl.dispose();
      shimmerCtrl.dispose();
    });
  });
}
