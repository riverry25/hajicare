import '../models/jamaah_data.dart';

abstract class AuthRepository {
  Future<bool> login(String phoneNumber, String password, UserRole role);
  Future<bool> register(
    String fullName,
    String phoneNumber,
    String password,
    UserRole role,
  );
  Future<void> logout();
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<bool> login(String phoneNumber, String password, UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<bool> register(
    String fullName,
    String phoneNumber,
    String password,
    UserRole role,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
