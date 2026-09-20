'use strict';

const {FieldValue} = require('firebase-admin/firestore');
const {BackendError} = require('./errors');
const {isAdmin, requireAuth, roleFromAuth} = require('./authorization');
const {normalizedEmail, optionalString, requiredString} = require('./validators');

const REQUESTABLE_ROLES = new Set(['jamaah', 'pendamping']);

function publicProfile(snapshot) {
  const data = snapshot.data() || {};
  return {
    uid: snapshot.id,
    role: data.role || 'jamaah',
    pendampingApprovalStatus: data.pendampingApprovalStatus || null,
  };
}

async function ensureUserProfile(db, auth, data) {
  requireAuth(auth);
  const userRef = db.collection('users').doc(auth.uid);
  const requestedRole = String(data?.requestedRole || 'jamaah').toLowerCase();
  if (!REQUESTABLE_ROLES.has(requestedRole)) {
    throw new BackendError('invalid-argument', 'Peran yang diminta tidak valid.');
  }

  const trustedRole = roleFromAuth(auth);
  const email = normalizedEmail(auth.token?.email || '');
  const requestedName = optionalString(data?.name, 'Nama', 100);
  const requestedPorsi = optionalString(data?.nomorPorsi, 'Nomor porsi', 50);
  const requestedPhoto = optionalString(data?.photoUrl, 'URL foto', 600);

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const existing = snapshot.data() || {};
    const actualRole = trustedRole === 'admin' || trustedRole === 'pendamping'
      ? trustedRole
      : 'jamaah';
    const approvalStatus = actualRole === 'pendamping'
      ? 'approved'
      : requestedRole === 'pendamping'
        ? (existing.pendampingApprovalStatus === 'rejected' ? 'pending' :
          (existing.pendampingApprovalStatus || 'pending'))
        : null;

    const profile = {
      uid: auth.uid,
      email,
      normalizedEmail: email,
      role: actualRole,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (!snapshot.exists) profile.createdAt = FieldValue.serverTimestamp();
    if (requestedName) profile.name = requestedName;
    if (requestedPorsi) profile.porsi = requestedPorsi;
    if (requestedPhoto) profile.photoUrl = requestedPhoto;
    if (approvalStatus) {
      profile.requestedRole = requestedRole;
      profile.pendampingApprovalStatus = approvalStatus;
    } else {
      profile.requestedRole = FieldValue.delete();
      profile.pendampingApprovalStatus = FieldValue.delete();
    }
    transaction.set(userRef, profile, {merge: true});
  });

  const result = await userRef.get();
  return publicProfile(result);
}

async function reviewPendampingAccess(db, authAdmin, auth, data) {
  requireAuth(auth);
  if (!isAdmin(auth)) {
    throw new BackendError('permission-denied', 'Hanya admin yang dapat meninjau akses pendamping.');
  }
  const uid = requiredString(data?.uid, 'UID pengguna', 128);
  const approved = data?.approved === true;
  const userRef = db.collection('users').doc(uid);
  const userRecord = await authAdmin.getUser(uid);
  const existingClaims = userRecord.customClaims || {};
  const nextClaims = {...existingClaims};
  if (approved) nextClaims.role = 'pendamping';
  else if (nextClaims.role === 'pendamping') delete nextClaims.role;

  await authAdmin.setCustomUserClaims(uid, nextClaims);
  await userRef.set({
    role: approved ? 'pendamping' : 'jamaah',
    requestedRole: 'pendamping',
    pendampingApprovalStatus: approved ? 'approved' : 'rejected',
    reviewedBy: auth.uid,
    reviewedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {uid, approved};
}

module.exports = {ensureUserProfile, reviewPendampingAccess};
