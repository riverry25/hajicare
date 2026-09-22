import '../../../core/locales/app_translations.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/app_alert_service.dart';
import '../../../core/state/hajicare_controller.dart';
import '../../../core/utils/user_feedback_message.dart';
import '../../room/services/room_service.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

/// Centralized, reactive GetX Controller for Notifications & Invitations.
/// Manages exactly ONE realtime stream per user to prevent duplicate subscriptions
/// and eliminate Firestore watchstream target errors.
class NotificationController extends GetxController {
  NotificationController({
    NotificationService? notificationService,
    RoomService? roomService,
    FirebaseAuth? firebaseAuth,
  }) : _notificationService = notificationService ?? NotificationService(),
       _roomService = roomService ?? RoomService(),
       _providedFirebaseAuth = firebaseAuth;

  final NotificationService _notificationService;
  final RoomService _roomService;
  final FirebaseAuth? _providedFirebaseAuth;

  FirebaseAuth get _firebaseAuth =>
      _providedFirebaseAuth ?? FirebaseAuth.instance;

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
  bool _hasReceivedInitialNotificationSnapshot = false;

  @override
  void onInit() {
    super.onInit();
    try {
      _authSub = _firebaseAuth.authStateChanges().listen((user) {
        if (user != null) {
          startListening(user.uid);
        } else {
          stopListening();
        }
      });

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) startListening(currentUser.uid);
    } on FirebaseException catch (error) {
      // Allows isolated widget tests to create the controller without a
      // configured Firebase app. Production initializes Firebase in main().
      debugPrint(
        '[NotificationController] Firebase Auth is unavailable: $error',
      );
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
    _hasReceivedInitialNotificationSnapshot = false;
    isLoading.value = true;
    debugPrint(
      '[NotificationController] Subscribing realtime listeners for uid: $uid',
    );

    // 1. Notifications Stream
    _notifSub = _notificationService
        .getUserNotificationsStream(uid)
        .listen(
          (items) {
            final knownIds = notifications.map((item) => item.id).toSet();
            final incomingMessages = _hasReceivedInitialNotificationSnapshot
                ? items
                      .where(
                        (item) =>
                            !knownIds.contains(item.id) &&
                            (item.isCompanionMessage || item.isCompanionInfo),
                      )
                      .toList(growable: false)
                : const <AppNotificationModel>[];
            notifications.assignAll(items);
            unreadCount.value = items.where((n) => !n.isRead).length;
            _hasReceivedInitialNotificationSnapshot = true;
            isLoading.value = false;
            debugPrint(
              '[NotificationController] Received ${items.length} notifications (${unreadCount.value} unread)',
            );
            if (incomingMessages.isNotEmpty) {
              _showIncomingMessageAlert(incomingMessages.first);
            }
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
    _hasReceivedInitialNotificationSnapshot = false;
    notifications.clear();
    pendingInvitations.clear();
    unreadCount.value = 0;
    isLoading.value = false;
  }

  void _showIncomingMessageAlert(AppNotificationModel notification) {
    if (Get.context == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.context == null) return;
      Get.snackbar(
        notification.isCompanionInfo
            ? 'Informasi Baru dari Jamaah'
            : 'Pesan Baru dari Jamaah',
        '${notification.senderName ?? 'Jamaah'}: ${notification.message}',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(14),
        borderRadius: 16,
        duration: const Duration(seconds: 5),
        icon: Icon(
          notification.isCompanionInfo
              ? Icons.campaign_rounded
              : Icons.chat_bubble_rounded,
          color: Colors.white,
        ),
        colorText: Colors.white,
        backgroundColor: const Color(0xFF3A2518),
        mainButton: TextButton(
          onPressed: () => Get.toNamed(AppRoutes.notification),
          child: const Text(
            'BUKA',
            style: TextStyle(
              color: Color(0xFFFFD180),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    });
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
    final uid = _currentListeningUid ?? _firebaseAuth.currentUser?.uid;
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
    if (processingInvitations.contains(invitation.id)) return;
    final user = _firebaseAuth.currentUser;
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

      _removeResolvedInvitation(invitation.id);
      await _notificationService.deleteNotificationsForInvitation(
        invitationId: invitation.id,
        uid: user.uid,
        roomId: invitation.roomId,
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
          title: AppTranslations.tr('notification.invitationAccepted'),
          message:
              'Anda sudah bergabung dengan rombongan “${invitation.roomName}”.',
        );
      }
    } catch (e) {
      if (e is StaleInvitationException) {
        _removeResolvedInvitation(invitation.id);
      }
      if (context.mounted) {
        if (e is StaleInvitationException) {
          AppDialog.warning(
            context: context,
            title: AppTranslations.tr('notification.invitationInvalid'),
            message: 'Rombongan ini sudah tidak tersedia.',
          );
        } else {
          AppDialog.error(
            context: context,
            title: AppTranslations.tr('notification.joinFailed'),
            message: UserFeedbackMessage.from(
              e,
              fallback: 'Undangan belum dapat diterima. Silakan coba lagi.',
            ),
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
    if (processingInvitations.contains(invitation.id)) return;
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    processingInvitations.add(invitation.id);

    try {
      await _roomService.rejectInvitation(
        invitationId: invitation.id,
        uid: user.uid,
      );

      _removeResolvedInvitation(invitation.id);
      await _notificationService.deleteNotificationsForInvitation(
        invitationId: invitation.id,
        uid: user.uid,
        roomId: invitation.roomId,
      );

      if (context.mounted) {
        AppDialog.info(
          context: context,
          title: AppTranslations.tr('notification.invitationRejected'),
          message:
              'Anda tidak bergabung dengan rombongan “${invitation.roomName}”.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppDialog.error(
          context: context,
          title: AppTranslations.tr('notification.choiceNotSaved'),
          message: UserFeedbackMessage.from(
            e,
            fallback: 'Pilihan belum dapat disimpan. Silakan coba lagi.',
          ),
        );
      }
    } finally {
      processingInvitations.remove(invitation.id);
    }
  }

  /// Deletes a specific notification from both local list and Firestore.
  Future<void> deleteNotification(String notificationId) async {
    notifications.removeWhere((item) => item.id == notificationId);
    unreadCount.value = notifications.where((item) => !item.isRead).length;
    await _notificationService.deleteNotification(notificationId);
  }

  /// Soft-deletes ALL notifications for the current user.
  ///
  /// Best-practice pattern: each Firestore document gets the current user's
  /// uid appended to its `deletedBy` array field. The realtime stream already
  /// filters those documents out, so other users who have not cleared their
  /// list will continue to see every notification unaffected.
  Future<void> clearAllNotifications() async {
    final uid = _currentListeningUid ?? _firebaseAuth.currentUser?.uid;
    if (uid == null) return;

    // Optimistic local clear so the UI responds instantly.
    notifications.clear();
    unreadCount.value = 0;

    await _notificationService.clearAllNotificationsForUser(uid);
  }

  void _removeResolvedInvitation(String invitationId) {
    pendingInvitations.removeWhere((item) => item.id == invitationId);
    notifications.removeWhere(
      (item) =>
          item.id == 'invitation_$invitationId' ||
          item.relatedId == invitationId ||
          (item.isRoomInvitation && item.relatedId == invitationId),
    );
    unreadCount.value = notifications.where((item) => !item.isRead).length;
  }

  @override
  void onClose() {
    _authSub?.cancel();
    stopListening();
    super.onClose();
  }
}
