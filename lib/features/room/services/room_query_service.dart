import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/activity_model.dart';
import '../models/room_invitation_model.dart';
import '../models/room_member_model.dart';
import '../models/room_model.dart';

typedef ActivityPage = ({
  List<ActivityModel> items,
  DocumentSnapshot? lastDoc,
  bool hasMore,
});

/// Read-only Firestore access for room and command-center projections.
class RoomQueryService {
  static const int _roomWindow = 200;
  static const int _memberWindow = 500;
  static const int _adminUserWindow = 500;
  static const int _sosWindow = 100;

  final FirebaseFirestore? _providedFirestore;

  RoomQueryService({FirebaseFirestore? firestore})
    : _providedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  Future<RoomModel?> getRoomById(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      return doc.exists ? RoomModel.fromFirestore(doc) : null;
    } catch (error) {
      debugPrint('[RoomQueryService] getRoomById failed: $error');
      return null;
    }
  }

  Stream<RoomModel?> getRoomStream(String roomId) {
    return _firestore.collection('rooms').doc(roomId).snapshots().map((doc) {
      return doc.exists ? RoomModel.fromFirestore(doc) : null;
    });
  }

  Stream<List<RoomModel>> getRoomsStream() {
    return _firestore
        .collection('rooms')
        .orderBy('createdAt', descending: true)
        .limit(_roomWindow)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<RoomMemberModel>> getRoomMembersStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .orderBy('joinedAt')
        .limit(_memberWindow)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomMemberModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<RoomMemberModel>> watchRoomMembers(String roomId) =>
      getRoomMembersStream(roomId);

  Stream<List<RoomInvitationModel>> getPendingInvitationsStream(String uid) {
    return _firestore
        .collection('invitations')
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(RoomInvitationModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Stream<List<ActivityModel>> getRecentActivitiesStream({int limit = 10}) {
    return _firestore
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ActivityModel.fromFirestore)
              .toList(growable: false),
        );
  }

  Future<ActivityPage> getActivitiesPaginated({
    int limit = 10,
    DocumentSnapshot? startAfterDoc,
    String? categoryFilter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('activities')
          .orderBy('timestamp', descending: true);

      switch (categoryFilter) {
        case 'Darurat':
          query = query.where('type', isEqualTo: 'sos_active');
        case 'Kamar':
          query = query.where(
            'type',
            whereIn: const [
              'room_created',
              'room_activated',
              'room_deactivated',
              'room_updated',
            ],
          );
        case 'Anggota':
          query = query.where(
            'type',
            whereIn: const ['member_joined', 'member_left'],
          );
      }

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      final snapshot = await query.limit(limit).get();
      return (
        items: snapshot.docs
            .map(ActivityModel.fromFirestore)
            .toList(growable: false),
        lastDoc: snapshot.docs.lastOrNull,
        hasMore: snapshot.docs.length >= limit,
      );
    } catch (error) {
      debugPrint(
        '[RoomQueryService] activity page failed ($error), using fallback query',
      );
      if (categoryFilter != null && categoryFilter != 'Semua') {
        try {
          Query<Map<String, dynamic>> fallbackQuery = _firestore
              .collection('activities')
              .orderBy('timestamp', descending: true);
          if (startAfterDoc != null) {
            fallbackQuery = fallbackQuery.startAfterDocument(startAfterDoc);
          }
          final snap = await fallbackQuery.limit(limit * 3).get();
          final allItems = snap.docs.map(ActivityModel.fromFirestore).toList();
          final filtered = allItems
              .where((a) {
                if (categoryFilter == 'Darurat') {
                  return a.type == ActivityType.sosActive;
                }
                if (categoryFilter == 'Kamar') {
                  return a.type == ActivityType.roomCreated ||
                      a.type == ActivityType.roomActivated ||
                      a.type == ActivityType.roomDeactivated ||
                      a.type == ActivityType.roomUpdated;
                }
                if (categoryFilter == 'Anggota') {
                  return a.type == ActivityType.memberJoined ||
                      a.type == ActivityType.memberLeft;
                }
                return true;
              })
              .take(limit)
              .toList();

          return (
            items: filtered,
            lastDoc: snap.docs.lastOrNull,
            hasMore: snap.docs.length >= limit * 3,
          );
        } catch (fbError) {
          debugPrint('[RoomQueryService] fallback query also failed: $fbError');
        }
      }
      return (items: <ActivityModel>[], lastDoc: null, hasMore: false);
    }
  }

  Stream<List<Map<String, dynamic>>> getActiveSosEventsStream({
    String? roomId,
  }) {
    final normalizedRoomId = roomId?.trim();
    Query<Map<String, dynamic>> query = _firestore.collection('sos_events');

    // Single-field queries only: served by automatic single-field indexes,
    // avoiding FAILED_PRECONDITION when composite indexes are not deployed.
    if (normalizedRoomId != null && normalizedRoomId.isNotEmpty) {
      query = query.where('roomId', isEqualTo: normalizedRoomId);
    } else {
      query = query.where(
        'status',
        whereIn: const ['active', 'baru', 'direspons'],
      );
    }

    return query.limit(_sosWindow).snapshots().map((snapshot) {
      const activeStatuses = {'active', 'baru', 'direspons'};
      final items = snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
          .where((item) {
            final st = (item['status'] as String?)?.trim().toLowerCase();
            final rId = (item['roomId'] as String?)?.trim();
            if (rId == null || rId.isEmpty) return false;
            return activeStatuses.contains(st);
          })
          .toList();
      items.sort(
        (a, b) => _eventTime(b, const [
          'timestamp',
          'createdAt',
        ]).compareTo(_eventTime(a, const ['timestamp', 'createdAt'])),
      );
      return items;
    });
  }

  Stream<List<Map<String, dynamic>>> getResolvedSosEventsStream({
    int limit = 5,
  }) {
    return _firestore
        .collection('sos_events')
        .where('status', isEqualTo: 'selesai')
        .limit(_sosWindow)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
              .toList();
          items.sort(
            (a, b) =>
                _eventTime(b, const [
                  'resolvedAt',
                  'timestamp',
                  'createdAt',
                ]).compareTo(
                  _eventTime(a, const ['resolvedAt', 'timestamp', 'createdAt']),
                ),
          );
          return items.take(limit).toList(growable: false);
        });
  }

  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .limit(_adminUserWindow)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{'uid': doc.id, ...doc.data()})
              .toList(growable: false),
        );
  }

  Stream<Map<String, int>> getGlobalMemberCountsStream() {
    return _firestore
        .collection('users')
        .limit(_adminUserWindow)
        .snapshots()
        .map((snapshot) {
          var jamaah = 0;
          var pendamping = 0;
          for (final doc in snapshot.docs) {
            switch ((doc.data()['role'] as String?)?.toLowerCase()) {
              case 'jamaah':
                jamaah++;
              case 'pendamping':
                pendamping++;
            }
          }
          return {'jamaah': jamaah, 'pendamping': pendamping};
        });
  }

  Stream<Map<String, Map<String, int>>> getAllRoomMemberBreakdownStream() {
    return _firestore
        .collection('users')
        .limit(_adminUserWindow)
        .snapshots()
        .map((snapshot) {
          final breakdown = <String, Map<String, int>>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final roomId = data['activeRoomId'] as String?;
            if (roomId == null || roomId.isEmpty) continue;

            final counts = breakdown.putIfAbsent(
              roomId,
              () => {'jamaah': 0, 'pendamping': 0, 'sos': 0},
            );
            final role = (data['role'] as String?)?.toLowerCase();
            if (role == 'jamaah' || role == 'pendamping') {
              counts[role!] = (counts[role] ?? 0) + 1;
            }
            if (data['sosActive'] == true) {
              counts['sos'] = (counts['sos'] ?? 0) + 1;
            }
          }
          return breakdown;
        });
  }

  DateTime _eventTime(Map<String, dynamic> event, List<String> keys) {
    for (final key in keys) {
      final value = event[key];
      if (value is Timestamp) return value.toDate();
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
