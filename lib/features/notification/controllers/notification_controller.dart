import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../room/services/room_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Centralized, reactive GetX Controller for Notifications & Invitations.
/// Manages exactly ONE realtime stream per user to prevent duplicate subscriptions
/// and eliminate Firestore watchstream target errors.
class NotificationController extends GetxController {
  final NotificationService _notificationService = NotificationService();
  final RoomService _roomService = RoomService();

  // ── Reactive State ──────────────────────────────────────────────────────────
  final notifications = <AppNotificationModel>[].obs;
  final pendingInvitations = <RoomInvitationModel>[].obs;
  final isLoading = false.obs;
  final unreadCount = 0.obs;
  final processingInvitations = <String>{}.obs;

  StreamSubscription<List<AppNotificationModel>>? _notifSub;
  StreamSubscription<List<RoomInvitationModel>>? _invitationSub;
  StreamSubscription<User?>? _authSub;
  String? _currentListeningUid;

  @override
  void onInit() {
    super.onInit();
    // Automatically attach to FirebaseAuth state
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        startListening(user.uid);
      } else {
        stopListening();
      }
    });

    // If a user is already authenticated on startup, start listening immediately
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      startListening(currentUser.uid);
    }
  }

  /// Starts listening to notifications and pending invitations for [uid].
  /// Guarded against duplicate subscriptions for the same user.
  void startListening(String uid) {
    if (_currentListeningUid == uid && _notifSub != null) {
      debugPrint(
        '[NotificationController] Already actively listening for uid: $uid (skipping duplicate)',
      );
      return;
    }

    stopListening();
    _currentListeningUid = uid;
    isLoading.value = true;
    debugPrint(
      '[NotificationController] Subscribing realtime listeners for uid: $uid',
    );

    // 1. Notifications Stream
    _notifSub = _notificationService
        .getUserNotificationsStream(uid)
        .listen(
          (items) {
            notifications.assignAll(items);
            unreadCount.value = items.where((n) => !n.isRead).length;
            isLoading.value = false;
            debugPrint(
              '[NotificationController] Received ${items.length} notifications (${unreadCount.value} unread)',
            );
          },
          onError: (err) {
            isLoading.value = false;
            debugPrint(
              '[NotificationController] Notification listener error: $err',
            );
          },
        );

    // 2. Pending Invitations Stream
    _invitationSub = _roomService
        .getPendingInvitationsStream(uid)
        .listen(
          (invs) {
            pendingInvitations.assignAll(invs);
            debugPrint(
              '[NotificationController] Received ${invs.length} pending invitations',
            );
          },
          onError: (err) {
            debugPrint(
              '[NotificationController] Invitation listener error: $err',
            );
          },
        );
  }

  /// Cleanly closes active subscriptions and resets state.
  void stopListening() {
    _notifSub?.cancel();
    _notifSub = null;
    _invitationSub?.cancel();
    _invitationSub = null;
    _currentListeningUid = null;
    notifications.clear();
    pendingInvitations.clear();
    unreadCount.value = 0;
    isLoading.value = false;
  }

  // ── Notification Actions ───────────────────────────────────────────────────

  /// Marks a specific notification as read.
  Future<void> markNotificationRead(String notificationId) async {
    // Optimistic local update
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !notifications[index].isRead) {
      final old = notifications[index];
      notifications[index] = AppNotificationModel(
        id: old.id,
        recipientId: old.recipientId,
        type: old.type,
        title: old.title,
        message: old.message,
        relatedId: old.relatedId,
        senderId: old.senderId,
        senderRole: old.senderRole,
        senderName: old.senderName,
        scope: old.scope,
        targetUserId: old.targetUserId,
        targetRoomId: old.targetRoomId,
        targetMaktab: old.targetMaktab,
        targetKloter: old.targetKloter,
        isRead: true,
        createdAt: old.createdAt,
        metadata: old.metadata,
      );
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    }

    await _notificationService.markNotificationRead(notificationId);
  }

  /// Marks all unread notifications as read.
  Future<void> markAllAsRead() async {
    final uid = _currentListeningUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Optimistic update
    notifications.assignAll(
      notifications.map((n) {
        if (n.isRead) return n;
        return AppNotificationModel(
          id: n.id,
          recipientId: n.recipientId,
          type: n.type,
          title: n.title,
          message: n.message,
          relatedId: n.relatedId,
          senderId: n.senderId,
          senderRole: n.senderRole,
          senderName: n.senderName,
          scope: n.scope,
          targetUserId: n.targetUserId,
          targetRoomId: n.targetRoomId,
          targetMaktab: n.targetMaktab,
          targetKloter: n.targetKloter,
          isRead: true,
          createdAt: n.createdAt,
          metadata: n.metadata,
        );
      }).toList(),
    );
    unreadCount.value = 0;

    await _notificationService.markAllAsRead(uid);
  }

  // ── Invitation Actions ─────────────────────────────────────────────────────

  /// Accepts a pending room invitation.
  Future<void> acceptInvitation({
    required BuildContext context,
    required RoomInvitationModel invitation,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userName =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : 'Jamaah';

    processingInvitations.add(invitation.id);

    try {
      final roomId = await _roomService.acceptInvitation(
        invitationId: invitation.id,
        uid: user.uid,
        userName: userName,
      );

      if (Get.isRegistered<HajiCareController>()) {
        final ctrl = Get.find<HajiCareController>();
        await ctrl.applyUserData(
          roleStr: 'jamaah',
          roomId: roomId,
          name: userName,
        );
      }

      if (context.mounted) {
        AppDialog.success(
          context: context,
          title: 'Undangan Diterima!',
          message:
              'Anda telah berhasil bergabung ke dalam room "${invitation.roomName}".',
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (e is StaleInvitationException) {
          AppDialog.warning(
            context: context,
            title: 'Undangan Tidak Berlaku',
            message: 'Room yang mengirim undangan ini sudah tidak tersedia.',
          );
        } else {
          AppDialog.error(
            context: context,
            title: 'Gagal Menerima Undangan',
            message: e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    } finally {
      processingInvitations.remove(invitation.id);
    }
  }

  /// Rejects a pending room invitation.
  Future<void> rejectInvitation({
    required BuildContext context,
    required RoomInvitationModel invitation,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    processingInvitations.add(invitation.id);

    try {
      await _roomService.rejectInvitation(
        invitationId: invitation.id,
        uid: user.uid,
      );

      if (context.mounted) {
        AppDialog.info(
          context: context,
          title: 'Undangan Ditolak',
          message:
              'Anda menolak undangan untuk bergabung ke room "${invitation.roomName}".',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppDialog.error(
          context: context,
          title: 'Gagal Menolak Undangan',
          message: e.toString().replaceAll('Exception: ', ''),
        );
      }
    } finally {
      processingInvitations.remove(invitation.id);
    }
  }

  @override
  void onClose() {
    _authSub?.cancel();
    stopListening();
    super.onClose();
  }
}
