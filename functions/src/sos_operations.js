'use strict';

const {FieldValue, GeoPoint} = require('firebase-admin/firestore');
const {BackendError} = require('./errors');
const {
  getRequired,
  requireAuth,
  requireRoomManager,
} = require('./authorization');
const {requiredString} = require('./validators');

const ACTIVE_SOS_STATUSES = new Set(['active', 'baru', 'direspons']);

function parseLocation(value) {
  if (value == null) return null;
  if (typeof value !== 'object' ||
      typeof value.latitude !== 'number' ||
      typeof value.longitude !== 'number' ||
      !Number.isFinite(value.latitude) ||
      !Number.isFinite(value.longitude) ||
      value.latitude < -90 || value.latitude > 90 ||
      value.longitude < -180 || value.longitude > 180) {
    throw new BackendError('invalid-argument', 'Koordinat lokasi tidak valid.');
  }
  return new GeoPoint(value.latitude, value.longitude);
}

async function triggerSos(db, auth, data) {
  requireAuth(auth);
  const pointerRef = db.collection('active_sos').doc(auth.uid);
  const userRef = db.collection('users').doc(auth.uid);
  const eventRef = db.collection('sos_events').doc();
  const location = parseLocation(data?.location);
  let result;

  await db.runTransaction(async (transaction) => {
    const userSnapshot = await getRequired(
      transaction,
      userRef,
      'Profil pengguna tidak ditemukan.',
    );
    const user = userSnapshot.data();
    const roomId = String(user.activeRoomId || '').trim();
    if (!roomId) {
      throw new BackendError('failed-precondition', 'Anda belum bergabung dengan rombongan.');
    }

    const roomRef = db.collection('rooms').doc(roomId);
    const memberRef = roomRef.collection('members').doc(auth.uid);
    const roomSnapshot = await getRequired(transaction, roomRef, 'Rombongan tidak ditemukan.');
    const memberSnapshot = await getRequired(
      transaction,
      memberRef,
      'Membership rombongan tidak ditemukan.',
    );
    const pointerSnapshot = await transaction.get(pointerRef);
    const room = roomSnapshot.data();
    const member = memberSnapshot.data();
    if (room.isActive !== true || room.status === 'deleting') {
      throw new BackendError('failed-precondition', 'Rombongan tidak aktif.');
    }
    if (member.role !== 'jamaah') {
      throw new BackendError('permission-denied', 'SOS jamaah tidak tersedia untuk role ini.');
    }

    if (pointerSnapshot.exists) {
      const eventId = String(pointerSnapshot.data().eventId || '');
      if (eventId) {
        const existingEvent = await transaction.get(db.collection('sos_events').doc(eventId));
        if (existingEvent.exists && ACTIVE_SOS_STATUSES.has(existingEvent.data().status)) {
          result = {eventId, duplicate: true};
          return;
        }
      }
      transaction.delete(pointerRef);
    }

    const userName = requiredString(
      String(member.name || user.name || user.displayName || 'Jamaah'),
      'Nama jamaah',
      100,
    );
    transaction.create(eventRef, {
      userId: auth.uid,
      jamaahId: auth.uid,
      userName,
      roomId,
      roomName: requiredString(String(room.name || 'Rombongan'), 'Nama room', 100),
      status: 'active',
      timestamp: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      ...(location ? {location} : {}),
    });
    transaction.set(pointerRef, {
      eventId: eventRef.id,
      roomId,
      status: 'active',
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.update(userRef, {
      sosActive: true,
      sosTime: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(memberRef, {sosActive: true});
    result = {eventId: eventRef.id, duplicate: false};
  });
  return result;
}

async function transitionSos(db, auth, data) {
  requireAuth(auth);
  const action = requiredString(data?.action, 'Aksi SOS', 16).toLowerCase();
  if (!['cancel', 'respond', 'resolve'].includes(action)) {
    throw new BackendError('invalid-argument', 'Aksi SOS tidak dikenal.');
  }
  const requestedEventId = data?.eventId == null
    ? null
    : requiredString(data.eventId, 'SOS event ID', 128);
  const ownerHint = data?.userId == null
    ? (action === 'cancel' ? auth.uid : null)
    : requiredString(data.userId, 'UID jamaah', 128);
  if (!requestedEventId && !ownerHint) {
    throw new BackendError('invalid-argument', 'SOS event atau jamaah wajib dipilih.');
  }
  let result;

  await db.runTransaction(async (transaction) => {
    let eventId = requestedEventId;
    let eventRef;
    let eventSnapshot;
    let pointerRef;
    let pointerSnapshot;
    if (!eventId) {
      pointerRef = db.collection('active_sos').doc(ownerHint);
      pointerSnapshot = await transaction.get(pointerRef);
      if (!pointerSnapshot.exists) {
        throw new BackendError('not-found', 'SOS aktif tidak ditemukan.');
      }
      eventId = requiredString(pointerSnapshot.data().eventId, 'SOS event ID', 128);
      eventRef = db.collection('sos_events').doc(eventId);
      eventSnapshot = await getRequired(transaction, eventRef, 'SOS tidak ditemukan.');
    } else {
      eventRef = db.collection('sos_events').doc(eventId);
      eventSnapshot = await getRequired(transaction, eventRef, 'SOS tidak ditemukan.');
    }
    const event = eventSnapshot.data();
    const currentStatus = String(event.status || '').toLowerCase();
    const roomId = String(event.roomId || '');
    const ownerUid = String(event.userId || event.jamaahId || '');
    if (!pointerRef) {
      pointerRef = db.collection('active_sos').doc(ownerUid);
      pointerSnapshot = await transaction.get(pointerRef);
    }
    if (ownerHint && ownerHint !== ownerUid) {
      throw new BackendError('failed-precondition', 'Pointer SOS tidak konsisten.');
    }
    const userRef = db.collection('users').doc(ownerUid);
    const memberRef = db.collection('rooms').doc(roomId).collection('members').doc(ownerUid);

    if (action === 'cancel') {
      if (auth.uid !== ownerUid) {
        throw new BackendError('permission-denied', 'Hanya pemilik SOS yang dapat membatalkan.');
      }
      if (currentStatus !== 'active' && currentStatus !== 'baru') {
        throw new BackendError(
          'failed-precondition',
          'SOS hanya dapat dibatalkan sebelum direspons.',
        );
      }
      transaction.update(eventRef, {
        status: 'cancelled',
        cancelledAt: FieldValue.serverTimestamp(),
        cancelledBy: auth.uid,
      });
      if (pointerSnapshot.exists && pointerSnapshot.data().eventId === eventId) {
        transaction.delete(pointerRef);
      }
      transaction.set(userRef, {
        sosActive: false,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      transaction.set(memberRef, {sosActive: false}, {merge: true});
      result = {eventId, status: 'cancelled'};
      return;
    }

    const authorization = await requireRoomManager(transaction, db, roomId, auth);
    const actorSnapshot = await getRequired(
      transaction,
      db.collection('users').doc(auth.uid),
      'Profil pendamping tidak ditemukan.',
    );
    const actor = actorSnapshot.data();
    const actorName = String(actor.name || actor.displayName || 'Pendamping').trim();

    if (action === 'respond') {
      if (currentStatus !== 'active' && currentStatus !== 'baru') {
        throw new BackendError('failed-precondition', 'SOS sudah direspons atau diselesaikan.');
      }
      transaction.update(eventRef, {
        status: 'direspons',
        respondedAt: FieldValue.serverTimestamp(),
        respondedBy: auth.uid,
        respondedByName: actorName,
      });
      if (pointerSnapshot.exists && pointerSnapshot.data().eventId === eventId) {
        transaction.update(pointerRef, {status: 'direspons'});
      }
      result = {eventId, status: 'direspons', roomId: authorization.roomRef.id};
      return;
    }

    if (!['active', 'baru', 'direspons'].includes(currentStatus)) {
      throw new BackendError('failed-precondition', 'SOS sudah selesai atau dibatalkan.');
    }
    transaction.update(eventRef, {
      status: 'selesai',
      resolvedAt: FieldValue.serverTimestamp(),
      resolvedBy: auth.uid,
    });
    if (pointerSnapshot.exists && pointerSnapshot.data().eventId === eventId) {
      transaction.delete(pointerRef);
    }
    transaction.set(userRef, {
      sosActive: false,
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
    transaction.set(memberRef, {sosActive: false}, {merge: true});
    result = {eventId, status: 'selesai', roomId: authorization.roomRef.id};
  });
  return result;
}

module.exports = {
  ACTIVE_SOS_STATUSES,
  transitionSos,
  triggerSos,
};
