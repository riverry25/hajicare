'use strict';

const {FieldValue} = require('firebase-admin/firestore');
const {BackendError} = require('./errors');
const {isAdmin, requireAuth, requireRoomManager, roleFromAuth} = require('./authorization');
const {optionalString, requiredString} = require('./validators');

const CLIENT_TYPES = new Set(['announcement', 'urgent', 'info']);
const ADMIN_SCOPES = new Set(['global', 'maktab', 'kloter', 'room', 'user']);
const PENDAMPING_SCOPES = new Set(['room', 'user']);
const COMPANION_MESSAGE_KINDS = new Set(['info', 'message']);

function chunks(items, size) {
  const result = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }
  return result;
}

async function sendNotification(db, auth, data) {
  requireAuth(auth);
  let role = roleFromAuth(auth);
  if (role !== 'admin' && role !== 'pendamping') {
    const userDoc = await db.collection('users').doc(auth.uid).get();
    const docRole = String(userDoc.data()?.role || '').toLowerCase();
    if (docRole === 'admin' || docRole === 'pendamping' || docRole === 'petugas') {
      role = docRole === 'petugas' ? 'pendamping' : docRole;
    }
  }
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

async function sendPickupRequest(db, auth, data) {
  requireAuth(auth);
  const roomId = requiredString(data?.roomId, 'ID rombongan', 128);
  const pendampingUid = requiredString(
    data?.pendampingUid,
    'Pendamping tujuan',
    128,
  );
  const notes = requiredString(data?.notes, 'Detail lokasi', 300);
  const latitude = data?.latitude;
  const longitude = data?.longitude;
  const hasCoordinates = latitude != null || longitude != null;
  if (hasCoordinates &&
      (typeof latitude !== 'number' || !Number.isFinite(latitude) ||
       typeof longitude !== 'number' || !Number.isFinite(longitude) ||
       latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180)) {
    throw new BackendError('invalid-argument', 'Koordinat lokasi tidak valid.');
  }
  if (pendampingUid === auth.uid) {
    throw new BackendError(
      'invalid-argument',
      'Pendamping tujuan tidak boleh akun Anda sendiri.',
    );
  }

  const roomRef = db.collection('rooms').doc(roomId);
  const jamaahMemberRef = roomRef.collection('members').doc(auth.uid);
  const pendampingMemberRef = roomRef.collection('members').doc(pendampingUid);
  const jamaahProfileRef = db.collection('users').doc(auth.uid);
  const pendampingProfileRef = db.collection('users').doc(pendampingUid);
  const notificationRef = db.collection('notifications').doc();
  let pendampingName;

  await db.runTransaction(async (transaction) => {
    const roomSnapshot = await transaction.get(roomRef);
    if (!roomSnapshot.exists ||
        roomSnapshot.data().isActive !== true ||
        roomSnapshot.data().status === 'deleting') {
      throw new BackendError('failed-precondition', 'Rombongan tidak aktif.');
    }

    const jamaahSnapshot = await transaction.get(jamaahMemberRef);
    if (!jamaahSnapshot.exists ||
        String(jamaahSnapshot.data().role || '').toLowerCase() !== 'jamaah') {
      throw new BackendError(
        'permission-denied',
        'Anda bukan jamaah aktif pada rombongan ini.',
      );
    }

    const pendampingSnapshot = await transaction.get(pendampingMemberRef);
    if (!pendampingSnapshot.exists ||
        String(pendampingSnapshot.data().role || '').toLowerCase() !== 'pendamping') {
      throw new BackendError(
        'permission-denied',
        'Pendamping yang dipilih bukan anggota rombongan yang sama.',
      );
    }

    const jamaahProfileSnapshot = await transaction.get(jamaahProfileRef);
    const pendampingProfileSnapshot = await transaction.get(pendampingProfileRef);
    if (!jamaahProfileSnapshot.exists ||
        String(jamaahProfileSnapshot.data().activeRoomId || '') !== roomId) {
      throw new BackendError(
        'failed-precondition',
        'Rombongan aktif jamaah sudah berubah. Muat ulang halaman.',
      );
    }
    if (!pendampingProfileSnapshot.exists ||
        String(pendampingProfileSnapshot.data().activeRoomId || '') !== roomId) {
      throw new BackendError(
        'failed-precondition',
        'Pendamping yang dipilih sudah tidak aktif di rombongan yang sama.',
      );
    }

    const jamaahName = String(
      jamaahSnapshot.data().name || auth.token?.name || 'Jamaah',
    ).trim();
    pendampingName = String(
      pendampingSnapshot.data().name || 'Pendamping',
    ).trim();
    transaction.create(notificationRef, {
      recipientId: pendampingUid,
      title: `Permintaan Jemput: ${jamaahName}`,
      message: `Jamaah ${jamaahName} meminta bantuan penjemputan di ${notes}.`,
      type: 'pickup_request',
      scope: 'user',
      targetUserId: pendampingUid,
      targetRoomId: roomId,
      senderId: auth.uid,
      senderName: jamaahName,
      senderRole: 'jamaah',
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
      metadata: {
        ...(hasCoordinates ? {latitude, longitude} : {}),
        notes,
        senderName: jamaahName,
        pendampingUid,
      },
    });
  });

  return {
    notificationId: notificationRef.id,
    recipientCount: 1,
    pendampingUid,
    pendampingName,
  };
}

/**
 * Lets an active jamaah contact one or every pendamping in the same room.
 * Recipient discovery and role checks intentionally live on the backend so a
 * modified client cannot message arbitrary users.
 */
async function sendCompanionMessage(db, auth, data) {
  requireAuth(auth);
  const roomId = requiredString(data?.roomId, 'ID rombongan', 128);
  const message = requiredString(data?.message, 'Pesan', 500);
  const kind = String(data?.kind || 'message').toLowerCase();
  if (!COMPANION_MESSAGE_KINDS.has(kind)) {
    throw new BackendError('invalid-argument', 'Jenis pesan tidak valid.');
  }

  const requestedUid = optionalString(
    data?.pendampingUid,
    'Pendamping tujuan',
    128,
  );
  const sendToAll = data?.sendToAll === true || kind === 'info';
  if (!sendToAll && !requestedUid) {
    throw new BackendError('invalid-argument', 'Pendamping tujuan wajib dipilih.');
  }

  const latitude = data?.latitude;
  const longitude = data?.longitude;
  const hasCoordinates = latitude != null || longitude != null;
  if (hasCoordinates &&
      (typeof latitude !== 'number' || !Number.isFinite(latitude) ||
       typeof longitude !== 'number' || !Number.isFinite(longitude) ||
       latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180)) {
    throw new BackendError('invalid-argument', 'Koordinat lokasi tidak valid.');
  }

  const roomRef = db.collection('rooms').doc(roomId);
  const senderMemberRef = roomRef.collection('members').doc(auth.uid);
  const senderProfileRef = db.collection('users').doc(auth.uid);
  let senderName = 'Jamaah';
  let targets = [];

  await db.runTransaction(async (transaction) => {
    const roomSnapshot = await transaction.get(roomRef);
    if (!roomSnapshot.exists ||
        roomSnapshot.data().isActive !== true ||
        roomSnapshot.data().status === 'deleting') {
      throw new BackendError('failed-precondition', 'Rombongan tidak aktif.');
    }

    const senderMemberSnapshot = await transaction.get(senderMemberRef);
    if (!senderMemberSnapshot.exists ||
        String(senderMemberSnapshot.data().role || '').toLowerCase() !== 'jamaah') {
      throw new BackendError(
        'permission-denied',
        'Anda bukan jamaah aktif pada rombongan ini.',
      );
    }

    const senderProfileSnapshot = await transaction.get(senderProfileRef);
    if (!senderProfileSnapshot.exists ||
        String(senderProfileSnapshot.data().activeRoomId || '') !== roomId) {
      throw new BackendError(
        'failed-precondition',
        'Rombongan aktif Anda sudah berubah. Muat ulang halaman.',
      );
    }

    senderName = String(
      senderMemberSnapshot.data().name || auth.token?.name || 'Jamaah',
    ).trim();

    if (sendToAll) {
      const membersSnapshot = await transaction.get(
        roomRef.collection('members'),
      );
      targets = membersSnapshot.docs
        .filter((doc) =>
          String(doc.data().role || '').toLowerCase() === 'pendamping' &&
          doc.id !== auth.uid,
        )
        .map((doc) => ({
          uid: doc.id,
          name: String(doc.data().name || 'Pendamping').trim(),
        }));
    } else {
      if (requestedUid === auth.uid) {
        throw new BackendError('invalid-argument', 'Penerima tidak valid.');
      }
      const targetSnapshot = await transaction.get(
        roomRef.collection('members').doc(requestedUid),
      );
      if (!targetSnapshot.exists ||
          String(targetSnapshot.data().role || '').toLowerCase() !== 'pendamping') {
        throw new BackendError(
          'permission-denied',
          'Pendamping yang dipilih bukan anggota rombongan yang sama.',
        );
      }
      targets = [{
        uid: requestedUid,
        name: String(targetSnapshot.data().name || 'Pendamping').trim(),
      }];
    }
  });

  if (targets.length === 0) {
    throw new BackendError(
      'failed-precondition',
      'Belum ada pendamping aktif di rombongan Anda.',
    );
  }

  const notificationId = db.collection('notifications').doc().id;
  for (const targetChunk of chunks(targets, 400)) {
    const batch = db.batch();
    for (const target of targetChunk) {
      batch.create(db.collection('notifications').doc(), {
        notificationId,
        recipientId: target.uid,
        title: kind === 'info'
          ? `Informasi dari ${senderName}`
          : `Pesan dari ${senderName}`,
        message,
        type: kind === 'info' ? 'companion_info' : 'companion_message',
        scope: sendToAll ? 'all_companions' : 'user',
        targetUserId: sendToAll ? null : target.uid,
        targetRoomId: roomId,
        senderId: auth.uid,
        senderName,
        senderRole: 'jamaah',
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
        metadata: {
          ...(hasCoordinates ? {latitude, longitude} : {}),
          includesLocation: hasCoordinates,
          sendToAll,
        },
      });
    }
    await batch.commit();
  }

  return {
    notificationId,
    recipientCount: targets.length,
    recipientNames: targets.map((target) => target.name),
  };
}

module.exports = {
  sendNotification,
  sendPickupRequest,
  sendCompanionMessage,
};
