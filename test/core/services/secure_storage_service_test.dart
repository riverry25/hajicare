import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hajicare/core/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService Encrypted Persistence Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('saves and reads encrypted rememberMe preference', () async {
      final service = SecureStorageService.instance;
      await service.setRememberMe(false);
      final readVal = await service.isRememberMe();
      expect(readVal, isFalse);

      await service.setRememberMe(true);
      final readVal2 = await service.isRememberMe();
      expect(readVal2, isTrue);
    });

    test('saves and reads encrypted activeRoomId', () async {
      final service = SecureStorageService.instance;
      await service.setActiveRoomId('ROOM-1234');
      final savedRoom = await service.getActiveRoomId();
      expect(savedRoom, equals('ROOM-1234'));

      await service.setActiveRoomId(null);
      final clearedRoom = await service.getActiveRoomId();
      expect(clearedRoom, isNull);
    });

    test('saves and reads encrypted userRole', () async {
      final service = SecureStorageService.instance;
      await service.setUserRole('pendamping');
      final role = await service.getUserRole();
      expect(role, equals('pendamping'));
    });

    test('clearAuthSession removes sensitive keys', () async {
      final service = SecureStorageService.instance;
      await service.setActiveRoomId('ROOM-999');
      await service.setUserRole('jamaah');
      await service.write(
        SecureStorageService.keyAuthToken,
        'secret_token_jwt',
      );

      await service.clearAuthSession();

      expect(await service.getActiveRoomId(), isNull);
      expect(await service.getUserRole(), isNull);
      expect(await service.read(SecureStorageService.keyAuthToken), isNull);
    });
  });
}
