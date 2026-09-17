import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../state/hajicare_controller.dart';
import 'app_routes.dart';

/// GetMiddleware enforcing:
/// 1. Authentication requirement
/// 2. Role-based route protection ('admin', 'pendamping', 'jamaah')
/// 3. Mandatory activeRoomId verification before dashboard access
class RoleAndRoomGuard extends GetMiddleware {
  final List<String>? allowedRoles;
  final bool requiresActiveRoom;
  final bool redirectIfHasRoom;

  RoleAndRoomGuard({
    this.allowedRoles,
    this.requiresActiveRoom = false,
    this.redirectIfHasRoom = false,
    int? priority,
  }) : super(priority: priority ?? 1);

  @override
  RouteSettings? redirect(String? route) {
    // 1. Verify Firebase Auth session
    User? currentUser;
    try {
      currentUser = FirebaseAuth.instance.currentUser;
    } catch (_) {
      currentUser = null;
    }

    if (currentUser == null) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (!Get.isRegistered<HajiCareController>()) {
      return null;
    }

    final state = Get.find<HajiCareController>();
    final roleStr = state.role == UserRole.admin
        ? 'admin'
        : (state.role == UserRole.pendamping ? 'pendamping' : 'jamaah');

    // 2. Check active room using in-memory state or local persistent cache fallback
    final currentRoomId = (state.activeRoomId.value != null && state.activeRoomId.value!.trim().isNotEmpty)
        ? state.activeRoomId.value!.trim()
        : (state.cachedRoomId != null && state.cachedRoomId!.trim().isNotEmpty
            ? state.cachedRoomId!.trim()
            : null);
    final hasActiveRoom = currentRoomId != null && currentRoomId.isNotEmpty;

    // Self-healing: if cached room ID exists but reactive RxnString was temporarily null, restore it
    if (state.activeRoomId.value == null && hasActiveRoom) {
      state.activeRoomId.value = currentRoomId;
    }

    // 3. Role-based access control
    if (allowedRoles != null && !allowedRoles!.contains(roleStr)) {
      if (state.role == UserRole.admin) {
        return const RouteSettings(name: AppRoutes.adminDashboard);
      } else if (state.role == UserRole.pendamping) {
        return RouteSettings(
          name: !hasActiveRoom ? AppRoutes.joinRoom : AppRoutes.dashboardPendamping,
        );
      } else {
        return RouteSettings(
          name: !hasActiveRoom ? AppRoutes.joinRoom : AppRoutes.dashboardJamaah,
        );
      }
    }

    // 4. Mandatory active room check
    if (requiresActiveRoom && !hasActiveRoom) {
      return const RouteSettings(name: AppRoutes.joinRoom);
    }

    // 5. If user already has an active room and navigates to Join Room, send to dashboard
    if (redirectIfHasRoom && hasActiveRoom) {
      if (state.role == UserRole.pendamping) {
        return const RouteSettings(name: AppRoutes.dashboardPendamping);
      } else if (state.role == UserRole.jamaah) {
        return const RouteSettings(name: AppRoutes.dashboardJamaah);
      }
    }

    return null;
  }
}
