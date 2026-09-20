'use strict';

const {FieldValue} = require('firebase-admin/firestore');
const {BackendError} = require('./errors');
const {isAdmin, requireAuth, requireRoomManager, roleFromAuth} = require('./authorization');
const {optionalString, requiredString} = require('./validators');

const CLIENT_TYPES = new Set(['announcement', 'urgent', 'info']);
const ADMIN_SCOPES = new Set(['global', 'maktab', 'kloter', 'room', 'user']);
const PENDAMPING_SCOPES = new Set(['room', 'user']);

function chunks(items, size) {
  const result = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }
  return result;
}

async function sendNotification(db, auth, data) {
  requireAuth(auth);
  const role = roleFromAuth(auth);
  if (role !== 'admin' && role !== 'pendamping') {
    throw new BackendError('permission-denied', 'Akses pengirim notifikasi diperlukan.');
  }
  const title = requiredString(data?.title, 'Judul', 80);
  const message = requiredString(data?.message, 'Pesan', 500);
  const type = String(data?.type || 'info').toLowerCase();
  const scope = String(data?.scope || '').toLowerCase();
  if (!CLIENT_TYPES.has(type)) {
    throw new BackendError('invalid-argument', 'Tipe notifikasi tidak valid.');
  }
  const allowedScopes = role === 'admin' ? ADMIN_SCOPES : PENDAMPING_SCOPES;
  if (!allowedScopes.has(scope)) {
    throw new BackendError('permission-denied', 'Cakupan notifikasi tidak diizinkan.');
  }

  const roomId = optionalString(data?.roomId, 'ID rombongan', 128);
  const targetUid = optionalString(data?.userId, 'UID tujuan', 128);
  const scopeValue = optionalString(data?.scopeValue, 'Nilai cakupan', 100);
  let targetIds = [];

  if (scope === 'room' || role === 'pendamping') {
    if (!roomId) throw new BackendError('invalid-argument', 'Rombongan wajib dipilih.');
    let roomMembers;
    await db.runTransaction(async (transaction) => {
      await requireRoomManager(transaction, db, roomId, auth);
      roomMembers = await transaction.get(
        db.collection('rooms').doc(roomId).collection('members'),
      );
    });
    const memberIds = new Set(roomMembers.docs.map((doc) => doc.id));
    if (scope === 'user') {
      if (!targetUid || !memberIds.has(targetUid)) {
        throw new BackendError('permission-denied', 'Penerima bukan anggota rombongan Anda.');
      }
      targetIds = [targetUid];
    } else {
      targetIds = [...memberIds];
    }
  } else if (scope === 'user') {
    if (!targetUid) throw new BackendError('invalid-argument', 'Penerima wajib dipilih.');
    targetIds = [targetUid];
  } else if (scope === 'maktab' || scope === 'kloter') {
    if (!scopeValue) throw new BackendError('invalid-argument', 'Nilai cakupan wajib diisi.');
    const snapshot = await db.collection('users').where(scope, '==', scopeValue).get();
    targetIds = snapshot.docs.map((doc) => doc.id);
  } else {
    const snapshot = await db.collection('users').select().get();
    targetIds = snapshot.docs.map((doc) => doc.id);
  }

  const senderSnapshot = await db.collection('users').doc(auth.uid).get();
  const sender = senderSnapshot.data() || {};
  const uniqueTargets = [...new Set(targetIds)].filter(
    (uid) => uid && uid !== auth.uid,
  );
  const notificationId = db.collection('notifications').doc().id;
  for (const targetChunk of chunks(uniqueTargets, 400)) {
    const batch = db.batch();
    for (const uid of targetChunk) {
      const reference = db.collection('notifications').doc();
      batch.set(reference, {
        notificationId,
        recipientId: uid,
        title,
        message,
        type,
        scope,
        targetUserId: scope === 'user' ? uid : null,
        targetRoomId: roomId || null,
        targetMaktab: scope === 'maktab' ? scopeValue : null,
        targetKloter: scope === 'kloter' ? scopeValue : null,
        senderId: auth.uid,
        senderName: sender.name || sender.displayName || 'Haji Care',
        senderRole: role,
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
  return {notificationId, recipientCount: uniqueTargets.length};
}

module.exports = {sendNotification};
