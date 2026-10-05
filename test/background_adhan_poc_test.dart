import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/background_alarm_poc_service.dart';
import 'package:adhan_foreground_service/adhan_foreground_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Background Adhan Audio POC Tests', () {
    test('BackgroundAlarmPocService constants are verified', () {
      expect(BackgroundAlarmPocService.pocAlarmId, 99999);
      expect(BackgroundAlarmPocService.pocAdhanAlarmId, 88888);
    });

    test(
      'AdhanForegroundService invokes native channel with correct arguments',
      () async {
        final List<MethodCall> methodCalls = [];

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.hajicare/adhan_native_service'),
              (MethodCall methodCall) async {
                methodCalls.add(methodCall);
                if (methodCall.method == 'startAdhanService') {
                  return true;
                } else if (methodCall.method == 'stopAdhanService') {
                  return true;
                } else if (methodCall.method == 'isServiceRunning') {
                  return true;
                }
                return null;
              },
            );

        final startResult = await AdhanForegroundService.startAdhan(
          prayerName: 'Dzuhur Test',
          isSubuh: false,
        );
        expect(startResult, isTrue);
        expect(methodCalls.length, 1);
        expect(methodCalls.first.method, 'startAdhanService');
        expect(methodCalls.first.arguments, {
          'prayerName': 'Dzuhur Test',
          'isSubuh': false,
        });

        final isRunning = await AdhanForegroundService.isRunning();
        expect(isRunning, isTrue);

        final stopResult = await AdhanForegroundService.stopAdhan();
        expect(stopResult, isTrue);
        expect(methodCalls.last.method, 'stopAdhanService');

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('com.hajicare/adhan_native_service'),
              null,
            );
      },
    );
  });
}
