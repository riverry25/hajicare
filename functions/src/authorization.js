'use strict';

const {BackendError} = require('./errors');

function requireAuth(auth) {
  if (!auth || typeof auth.uid !== 'string' || !auth.uid) {
    throw new BackendError('unauthenticated', 'Silakan masuk kembali.');
  }
  return auth;
}

function roleFromAuth(auth) {
  requireAuth(auth);
  const claimedRole = String(auth.token?.role || '').toLowerCase();
  if (claimedRole === 'admin' || claimedRole === 'pendamping') {
    return claimedRole;
  }
  return 'jamaah';
}

function isAdmin(auth) {
  return roleFromAuth(auth) === 'admin';
}

async function getRequired(transaction, reference, message) {
  const snapshot = await transaction.get(reference);
  if (!snapshot.exists) {
    throw new BackendError('not-found', message);
  }
  return snapshot;
}

async function requireRoomManager(transaction, db, roomId, auth, options = {}) {
  requireAuth(auth);
  const roomRef = db.collection('rooms').doc(roomId);
  const roomSnapshot = await getRequired(
    transaction,
    roomRef,
    'Rombongan tidak ditemukan.',
  );
  const room = roomSnapshot.data();

  if (options.requireActive !== false &&
      (room.isActive !== true || room.status === 'deleting')) {
    throw new BackendError('failed-precondition', 'Rombongan tidak aktif.');
  }

  if (isAdmin(auth)) {
    return {roomRef, roomSnapshot, room, memberSnapshot: null};
  }
  if (roleFromAuth(auth) !== 'pendamping') {
    throw new BackendError('permission-denied', 'Akses pendamping diperlukan.');
  }

  const memberRef = roomRef.collection('members').doc(auth.uid);
  const memberSnapshot = await transaction.get(memberRef);
  const managerIds = Array.isArray(room.pendampingIds)
    ? room.pendampingIds.map(String)
    : [];
  const listedAsManager = room.pendampingId === auth.uid || managerIds.includes(auth.uid);
  if (!memberSnapshot.exists ||
      memberSnapshot.data().role !== 'pendamping' ||
      !listedAsManager) {
    throw new BackendError(
      'permission-denied',
      'Anda bukan pendamping aktif untuk rombongan ini.',
    );
  }
  return {roomRef, roomSnapshot, room, memberSnapshot};
}

module.exports = {
  getRequired,
  isAdmin,
  requireAuth,
  requireRoomManager,
  roleFromAuth,
};
