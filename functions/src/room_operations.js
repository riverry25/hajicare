'use strict';

const crypto = require('crypto');
const {FieldValue} = require('firebase-admin/firestore');
const {BackendError} = require('./errors');
const {
  getRequired,
  isAdmin,
  requireAuth,
  requireRoomManager,
  roleFromAuth,
} = require('./authorization');
const {
  normalizedEmail,
  optionalString,
  requiredString,
  safeRadius,
  titleCase,
} = require('./validators');

const ROOM_CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const MAX_PENDAMPING = 5;

function generateRoomCode(length = 6) {
  let result = '';
  for (let index = 0; index < length; index += 1) {
    result += ROOM_CODE_CHARS[crypto.randomInt(ROOM_CODE_CHARS.length)];
  }
  return result;
}

function profileName(profile, fallback) {
  const candidate = profile.name || profile.displayName || fallback;
  return requiredString(String(candidate || ''), 'Nama pengguna', 100);
}

async function logActivity(db, payload) {
  await db.collection('activities').add({
    ...payload,
    timestamp: FieldValue.serverTimestamp(),
  });
}

async function createRoom(db, auth, data) {
  requireAuth(auth);
  const role = roleFromAuth(auth);
  if (role !== 'admin' && role !== 'pendamping') {
    throw new BackendError('permission-denied', 'Hanya pengelola yang dapat membuat rombongan.');
  }

  const name = titleCase(requiredString(data?.name, 'Nama rombongan', 100));
  const maktab = optionalString(data?.maktab, 'Maktab', 60);
  const kloter = optionalString(data?.kloter, 'Kloter', 60);
  const userRef = db.collection('users').doc(auth.uid);
  const roomRef = db.collection('rooms').doc();

  for (let attempt = 0; attempt < 12; attempt += 1) {
    const code = generateRoomCode(attempt >= 10 ? 8 : 6);
    const codeRef = db.collection('roomCodes').doc(code);
    try {
      let creatorName = role === 'admin' ? 'Administrator HajiCare' : 'Pendamping';
      await db.runTransaction(async (transaction) => {
        const codeSnapshot = await transaction.get(codeRef);
        if (codeSnapshot.exists) {
          throw new BackendError('already-exists', 'Kode rombongan sudah digunakan.');
        }

        const userSnapshot = await getRequired(
          transaction,
          userRef,
          'Profil pengguna belum tersedia.',
        );
        const profile = userSnapshot.data();
        creatorName = profileName(profile, auth.token?.name || auth.token?.email);

        if (role === 'pendamping') {
          if (profile.role !== 'pendamping') {
            throw new BackendError(
              'permission-denied',
              'Status pendamping belum disetujui.',
            );
          }
          const activeRoomId = String(profile.activeRoomId || '').trim();
          if (activeRoomId) {
            throw new BackendError(
              'failed-precondition',
              'Anda sudah berada dalam rombongan lain.',
            );
          }
        }

        const roomPayload = {
          name,
          code,
          createdBy: auth.uid,
          createdByRole: role,
          pendampingId: role === 'pendamping' ? auth.uid : null,
          pendampingIds: role === 'pendamping' ? [auth.uid] : [],
          safeRadius: 200,
          createdAt: FieldValue.serverTimestamp(),
          isActive: true,
          status: 'active',
          memberCount: role === 'pendamping' ? 1 : 0,
          ...(maktab ? {maktab} : {}),
          ...(kloter ? {kloter} : {}),
        };
        transaction.create(roomRef, roomPayload);
        transaction.create(codeRef, {
          roomId: roomRef.id,
          createdAt: FieldValue.serverTimestamp(),
        });

        if (role === 'pendamping') {
          transaction.create(roomRef.collection('members').doc(auth.uid), {
            uid: auth.uid,
            name: creatorName,
            role: 'pendamping',
            joinedAt: FieldValue.serverTimestamp(),
          });
          transaction.update(userRef, {
            activeRoomId: roomRef.id,
            ...(maktab ? {maktab} : {}),
            ...(kloter ? {kloter} : {}),
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
      });

      await logActivity(db, {
        type: 'room_created',
        title: 'Room Dibuat',
        description: `Room "${name}" berhasil dibuat.`,
        roomId: roomRef.id,
        roomName: name,
        userId: auth.uid,
        userName: creatorName,
        role,
      });
      return {roomId: roomRef.id, code};
    } catch (error) {
      if (error instanceof BackendError && error.code === 'already-exists') {
        continue;
      }
      throw error;
    }
  }
  throw new BackendError('resource-exhausted', 'Belum dapat membuat kode rombongan unik.');
}

async function joinRoomByCode(db, auth, data) {
  requireAuth(auth);
  const code = requiredString(data?.roomCode, 'Kode rombongan', 8).toUpperCase();
  if (!/^[A-HJ-NP-Z2-9]{6,8}$/.test(code)) {
    throw new BackendError('invalid-argument', 'Format kode rombongan tidak valid.');
  }

  const role = roleFromAuth(auth);
  if (role === 'admin') {
    throw new BackendError('failed-precondition', 'Administrator tidak bergabung sebagai anggota room.');
  }

  const codeRef = db.collection('roomCodes').doc(code);
  const userRef = db.collection('users').doc(auth.uid);
  let result;

  await db.runTransaction(async (transaction) => {
    const codeSnapshot = await getRequired(
      transaction,
      codeRef,
      'Kode rombongan tidak ditemukan.',
    );
    const roomId = String(codeSnapshot.data().roomId || '');
    const roomRef = db.collection('rooms').doc(roomId);
    const roomSnapshot = await getRequired(
      transaction,
      roomRef,
      'Rombongan tidak ditemukan.',
    );
    const userSnapshot = await getRequired(
      transaction,
      userRef,
      'Profil pengguna belum tersedia.',
    );
    const room = roomSnapshot.data();
    const profile = userSnapshot.data();

    if (room.isActive !== true || room.status === 'deleting') {
      throw new BackendError('failed-precondition', 'Rombongan tidak aktif.');
    }
    if (String(profile.activeRoomId || '').trim()) {
      throw new BackendError('failed-precondition', 'Anda sudah berada dalam rombongan lain.');
    }
    if (role === 'pendamping' && profile.role !== 'pendamping') {
      throw new BackendError('permission-denied', 'Status pendamping belum disetujui.');
    }
    if (role === 'jamaah' && profile.role !== 'jamaah') {
      throw new BackendError('failed-precondition', 'Profil pengguna tidak valid.');
    }

    const memberRef = roomRef.collection('members').doc(auth.uid);
    const memberSnapshot = await transaction.get(memberRef);
    if (memberSnapshot.exists) {
      throw new BackendError('already-exists', 'Membership lama masih tercatat. Hubungi pengelola.');
    }

    let pendampingIds = Array.isArray(room.pendampingIds)
      ? room.pendampingIds.map(String)
      : [];
    if (role === 'pendamping') {
      const pendampingQuery = roomRef
        .collection('members')
        .where('role', '==', 'pendamping');
      const pendampingSnapshot = await transaction.get(pendampingQuery);
      if (pendampingSnapshot.size >= MAX_PENDAMPING) {
        throw new BackendError(
          'resource-exhausted',
          `Rombongan sudah memiliki ${MAX_PENDAMPING} pendamping.`,
        );
      }
      pendampingIds = [...new Set([...pendampingIds, auth.uid])];
    }

    const memberName = profileName(profile, auth.token?.name || auth.token?.email);
    transaction.create(memberRef, {
      uid: auth.uid,
      name: memberName,
      role,
      joinedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(userRef, {
      activeRoomId: roomId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(roomRef, {
      memberCount: Number(room.memberCount || 0) + 1,
      ...(role === 'pendamping'
        ? {
            pendampingIds,
            pendampingId: room.pendampingId || auth.uid,
          }
        : {}),
      updatedAt: FieldValue.serverTimestamp(),
    });
    result = {roomId, roomName: room.name, role, memberName};
  });

  await logActivity(db, {
    type: 'member_joined',
    title: result.role === 'pendamping' ? 'Pendamping Bergabung' : 'Jamaah Bergabung',
    description: `${result.memberName} bergabung ke ${result.roomName}.`,
    roomId: result.roomId,
    roomName: result.roomName,
    userId: auth.uid,
    userName: result.memberName,
    role: result.role,
  });
  return {roomId: result.roomId};
}

async function leaveRoom(db, auth, data) {
  requireAuth(auth);
  const roomId = requiredString(data?.roomId, 'Room ID', 128);
  const userRef = db.collection('users').doc(auth.uid);
  const roomRef = db.collection('rooms').doc(roomId);
  let activity;

  await db.runTransaction(async (transaction) => {
    const roomSnapshot = await getRequired(transaction, roomRef, 'Rombongan tidak ditemukan.');
    const userSnapshot = await getRequired(transaction, userRef, 'Profil pengguna tidak ditemukan.');
    const memberRef = roomRef.collection('members').doc(auth.uid);
    const memberSnapshot = await getRequired(
      transaction,
      memberRef,
      'Anda bukan anggota rombongan ini.',
    );
    const room = roomSnapshot.data();
    const member = memberSnapshot.data();

    if (String(userSnapshot.data().activeRoomId || '') !== roomId) {
      throw new BackendError('failed-precondition', 'Membership pengguna tidak konsisten.');
    }
    const activeSosSnapshot = await transaction.get(
      db.collection('active_sos').doc(auth.uid),
    );
    if (activeSosSnapshot.exists) {
      throw new BackendError(
        'failed-precondition',
        'Akhiri status SOS sebelum keluar dari rombongan.',
      );
    }

    const updates = {
      memberCount: Math.max(0, Number(room.memberCount || 1) - 1),
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (member.role === 'pendamping') {
      const currentIds = Array.isArray(room.pendampingIds)
        ? room.pendampingIds.map(String)
        : [];
      const remainingIds = currentIds.filter((uid) => uid !== auth.uid);
      updates.pendampingIds = remainingIds;
      if (room.pendampingId === auth.uid) {
        updates.pendampingId = remainingIds[0] || null;
      }
    }

    transaction.delete(memberRef);
    transaction.update(userRef, {
      activeRoomId: null,
      sosActive: false,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(roomRef, updates);
    activity = {
      roomName: room.name,
      userName: member.name,
      role: member.role,
    };
  });

  await logActivity(db, {
    type: 'member_left',
    title: activity.role === 'pendamping' ? 'Pendamping Keluar' : 'Jamaah Keluar',
    description: `${activity.userName} keluar dari ${activity.roomName}.`,
    roomId,
    roomName: activity.roomName,
    userId: auth.uid,
    userName: activity.userName,
    role: activity.role,
  });
  return {roomId};
}

async function updateRoomSettings(db, auth, data) {
  requireAuth(auth);
  const roomId = requiredString(data?.roomId, 'Room ID', 128);
  const updates = {};
  if (data?.name != null) {
    updates.name = titleCase(requiredString(data.name, 'Nama rombongan', 100));
  }
  if (data?.maktab !== undefined) {
    updates.maktab = optionalString(data.maktab, 'Maktab', 60);
  }
  if (data?.kloter !== undefined) {
    updates.kloter = optionalString(data.kloter, 'Kloter', 60);
  }
  if (data?.safeRadius != null) {
    updates.safeRadius = safeRadius(data.safeRadius);
  }
  if (data?.isActive != null) {
    if (!isAdmin(auth) || typeof data.isActive !== 'boolean') {
      throw new BackendError('permission-denied', 'Hanya admin yang dapat mengubah status room.');
    }
    updates.isActive = data.isActive;
    updates.status = data.isActive ? 'active' : 'inactive';
  }
  if (Object.keys(updates).length === 0) return {roomId};

  await db.runTransaction(async (transaction) => {
    const authorization = await requireRoomManager(
      transaction,
      db,
      roomId,
      auth,
      {requireActive: false},
    );
    if (!isAdmin(auth) && authorization.room.createdBy !== auth.uid) {
      throw new BackendError(
        'permission-denied',
        'Hanya pembuat rombongan yang dapat mengubah pengaturannya.',
      );
    }
    transaction.update(authorization.roomRef, {
      ...updates,
      updatedAt: FieldValue.serverTimestamp(),
    });
    if (!isAdmin(auth) && (updates.maktab !== undefined || updates.kloter !== undefined)) {
      transaction.update(db.collection('users').doc(auth.uid), {
        ...(updates.maktab !== undefined ? {maktab: updates.maktab} : {}),
        ...(updates.kloter !== undefined ? {kloter: updates.kloter} : {}),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
  });
  return {roomId};
}

async function removeJamaah(db, auth, data) {
  requireAuth(auth);
  const roomId = requiredString(data?.roomId, 'Room ID', 128);
  const jamaahUid = requiredString(data?.jamaahUid, 'Jamaah UID', 128);
  if (jamaahUid === auth.uid) {
    throw new BackendError('invalid-argument', 'Gunakan operasi keluar room untuk akun sendiri.');
  }

  await db.runTransaction(async (transaction) => {
    const authorization = await requireRoomManager(transaction, db, roomId, auth);
    const memberRef = authorization.roomRef.collection('members').doc(jamaahUid);
    const memberSnapshot = await getRequired(
      transaction,
      memberRef,
      'Jamaah tidak ditemukan dalam rombongan.',
    );
    if (memberSnapshot.data().role !== 'jamaah') {
      throw new BackendError('permission-denied', 'Target bukan anggota jamaah.');
    }
    const activeSosSnapshot = await transaction.get(db.collection('active_sos').doc(jamaahUid));
    if (activeSosSnapshot.exists) {
      throw new BackendError(
        'failed-precondition',
        'Selesaikan SOS jamaah sebelum mengeluarkannya.',
      );
    }
    const userRef = db.collection('users').doc(jamaahUid);
    const userSnapshot = await transaction.get(userRef);

    transaction.delete(memberRef);
    if (userSnapshot.exists && userSnapshot.data().activeRoomId === roomId) {
      transaction.update(userRef, {
        activeRoomId: null,
        sosActive: false,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    transaction.update(authorization.roomRef, {
      memberCount: Math.max(0, Number(authorization.room.memberCount || 1) - 1),
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(db.collection('notifications').doc(), {
      title: 'Dikeluarkan dari Rombongan',
      message: `Anda telah dikeluarkan dari rombongan "${authorization.room.name}".`,
      type: 'room_removed',
      recipientId: jamaahUid,
      senderId: auth.uid,
      senderRole: roleFromAuth(auth),
      targetRoomId: roomId,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return {roomId, jamaahUid};
}

async function inviteJamaah(db, auth, data) {
  requireAuth(auth);
  const roomId = requiredString(data?.roomId, 'Room ID', 128);
  const email = normalizedEmail(data?.email);
  let targets = await db
    .collection('users')
    .where('normalizedEmail', '==', email)
    .limit(2)
    .get();
  if (targets.empty) {
    targets = await db
      .collection('users')
      .where('email', '==', email)
      .limit(2)
      .get();
  }
  if (targets.empty) {
    throw new BackendError('not-found', 'Akun jamaah dengan email tersebut tidak ditemukan.');
  }
  if (targets.size > 1) {
    throw new BackendError('failed-precondition', 'Terdapat data email duplikat. Hubungi admin.');
  }

  const target = targets.docs[0];
  if (target.id === auth.uid) {
    throw new BackendError('invalid-argument', 'Anda tidak dapat mengundang akun sendiri.');
  }
  const invitationId = `${roomId}_${target.id}`;
  const invitationRef = db.collection('invitations').doc(invitationId);
  const notificationRef = db.collection('notifications').doc(`invitation_${invitationId}`);

  await db.runTransaction(async (transaction) => {
    const authorization = await requireRoomManager(transaction, db, roomId, auth);
    const targetSnapshot = await getRequired(
      transaction,
      target.ref,
      'Akun jamaah tidak ditemukan.',
    );
    const existingInvitation = await transaction.get(invitationRef);
    const targetData = targetSnapshot.data();
    if (targetData.role !== 'jamaah' || String(targetData.activeRoomId || '').trim()) {
      throw new BackendError('failed-precondition', 'Jamaah sudah berada dalam rombongan lain.');
    }
    if (existingInvitation.exists && existingInvitation.data().status === 'pending') {
      throw new BackendError('already-exists', 'Undangan aktif sudah dikirim kepada jamaah ini.');
    }

    const senderSnapshot = await getRequired(
      transaction,
      db.collection('users').doc(auth.uid),
      'Profil pengirim tidak ditemukan.',
    );
    const senderName = profileName(senderSnapshot.data(), auth.token?.name || auth.token?.email);
    const targetName = profileName(targetData, email.split('@')[0]);
    transaction.set(invitationRef, {
      roomId,
      roomName: authorization.room.name,
      roomCode: authorization.room.code,
      fromUserId: auth.uid,
      fromUserName: senderName,
      toUserId: target.id,
      toUserName: targetName,
      toEmail: email,
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
    });
    transaction.set(notificationRef, {
      title: 'Undangan Rombongan',
      message: `${senderName} mengundang Anda bergabung ke "${authorization.room.name}".`,
      type: 'room_invitation',
      recipientId: target.id,
      senderId: auth.uid,
      senderRole: roleFromAuth(auth),
      senderName,
      targetRoomId: roomId,
      relatedId: invitationId,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return {invitationId};
}

async function respondInvitation(db, auth, data) {
  requireAuth(auth);
  const invitationId = requiredString(data?.invitationId, 'Invitation ID', 256);
  const action = requiredString(data?.action, 'Respons undangan', 16).toLowerCase();
  if (action !== 'accept' && action !== 'reject') {
    throw new BackendError('invalid-argument', 'Respons undangan tidak dikenal.');
  }
  const invitationRef = db.collection('invitations').doc(invitationId);
  let result;

  await db.runTransaction(async (transaction) => {
    const invitationSnapshot = await getRequired(
      transaction,
      invitationRef,
      'Undangan tidak ditemukan.',
    );
    const invitation = invitationSnapshot.data();
    if (invitation.toUserId !== auth.uid) {
      throw new BackendError('permission-denied', 'Undangan bukan untuk akun ini.');
    }
    if (invitation.status !== 'pending') {
      throw new BackendError('failed-precondition', 'Undangan sudah tidak berlaku.');
    }
    if (action === 'reject') {
      transaction.update(invitationRef, {
        status: 'rejected',
        respondedAt: FieldValue.serverTimestamp(),
      });
      transaction.set(
        db.collection('notifications').doc(`invitation_${invitationId}`),
        {isRead: true},
        {merge: true},
      );
      result = {status: 'rejected'};
      return;
    }

    const roomId = String(invitation.roomId || '');
    const roomRef = db.collection('rooms').doc(roomId);
    const roomSnapshot = await transaction.get(roomRef);
    if (!roomSnapshot.exists ||
        roomSnapshot.data().isActive !== true ||
        roomSnapshot.data().status === 'deleting') {
      transaction.update(invitationRef, {
        status: 'expired',
        expiredReason: 'room_unavailable',
        expiredAt: FieldValue.serverTimestamp(),
      });
      result = {status: 'expired', roomId};
      return;
    }

    const userRef = db.collection('users').doc(auth.uid);
    const userSnapshot = await getRequired(transaction, userRef, 'Profil pengguna tidak ditemukan.');
    const profile = userSnapshot.data();
    if (profile.role !== 'jamaah' || String(profile.activeRoomId || '').trim()) {
      throw new BackendError('failed-precondition', 'Akun sudah berada dalam rombongan lain.');
    }
    const memberRef = roomRef.collection('members').doc(auth.uid);
    const memberSnapshot = await transaction.get(memberRef);
    if (memberSnapshot.exists) {
      throw new BackendError('already-exists', 'Membership lama masih tercatat.');
    }

    transaction.create(memberRef, {
      uid: auth.uid,
      name: profileName(profile, auth.token?.name || auth.token?.email),
      role: 'jamaah',
      joinedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(userRef, {
      activeRoomId: roomId,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(roomRef, {
      memberCount: Number(roomSnapshot.data().memberCount || 0) + 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.update(invitationRef, {
      status: 'accepted',
      respondedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(
      db.collection('notifications').doc(`invitation_${invitationId}`),
      {isRead: true},
      {merge: true},
    );
    result = {status: 'accepted', roomId};
  });
  return result;
}

async function deleteRoom(db, auth, data) {
  requireAuth(auth);
  const roomId = requiredString(data?.roomId, 'Room ID', 128);
  const roomRef = db.collection('rooms').doc(roomId);
  let roomData;

  await db.runTransaction(async (transaction) => {
    const roomSnapshot = await getRequired(transaction, roomRef, 'Rombongan tidak ditemukan.');
    const room = roomSnapshot.data();
    if (room.status === 'deleting' && room.deleteRequestedBy === auth.uid) {
      roomData = room;
      return;
    }
    const authorization = await requireRoomManager(
      transaction,
      db,
      roomId,
      auth,
      {requireActive: false},
    );
    if (!isAdmin(auth) && authorization.room.createdBy !== auth.uid) {
      throw new BackendError('permission-denied', 'Hanya pembuat room yang dapat menghapusnya.');
    }
    const activeSos = await transaction.get(
      db.collection('active_sos').where('roomId', '==', roomId).limit(1),
    );
    if (!activeSos.empty) {
      throw new BackendError(
        'failed-precondition',
        'Selesaikan semua SOS aktif sebelum menghapus rombongan.',
      );
    }
    roomData = authorization.room;
    transaction.update(roomRef, {
      isActive: false,
      status: 'deleting',
      deleteRequestedBy: auth.uid,
      deleteRequestedAt: FieldValue.serverTimestamp(),
    });
  });

  while (true) {
    const members = await roomRef.collection('members').limit(100).get();
    if (members.empty) break;
    await db.runTransaction(async (transaction) => {
      const memberUsers = [];
      for (const member of members.docs) {
        const userRef = db.collection('users').doc(member.id);
        const userSnapshot = await transaction.get(userRef);
        memberUsers.push({member, userRef, userSnapshot});
      }
      for (const {member, userRef, userSnapshot} of memberUsers) {
        if (userSnapshot.exists && userSnapshot.data().activeRoomId === roomId) {
          transaction.update(userRef, {
            activeRoomId: null,
            sosActive: false,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }
        if (member.data().role === 'jamaah') {
          transaction.set(db.collection('notifications').doc(), {
            title: 'Rombongan Dihapus',
            message: `Rombongan "${roomData.name}" sudah dihapus oleh pengelola.`,
            type: 'room_deleted',
            recipientId: member.id,
            senderId: auth.uid,
            senderRole: roleFromAuth(auth),
            targetRoomId: roomId,
            isRead: false,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        transaction.delete(member.ref);
      }
    });
  }

  while (true) {
    const invitations = await db
      .collection('invitations')
      .where('roomId', '==', roomId)
      .where('status', '==', 'pending')
      .limit(300)
      .get();
    if (invitations.empty) break;
    const batch = db.batch();
    for (const invitation of invitations.docs) {
      batch.update(invitation.ref, {
        status: 'expired',
        expiredReason: 'room_deleted',
        expiredAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  const finalBatch = db.batch();
  if (roomData.code) {
    finalBatch.delete(db.collection('roomCodes').doc(String(roomData.code).toUpperCase()));
  }
  finalBatch.delete(roomRef);
  await finalBatch.commit();
  await logActivity(db, {
    type: 'room_deactivated',
    title: 'Room Dihapus',
    description: `Room "${roomData.name}" telah dihapus beserta membership aktifnya.`,
    roomId,
    roomName: roomData.name,
    userId: auth.uid,
    role: roleFromAuth(auth),
  });
  return {roomId, deleted: true};
}

module.exports = {
  MAX_PENDAMPING,
  createRoom,
  deleteRoom,
  generateRoomCode,
  inviteJamaah,
  joinRoomByCode,
  leaveRoom,
  removeJamaah,
  respondInvitation,
  updateRoomSettings,
};
