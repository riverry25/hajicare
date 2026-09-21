'use strict';

const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {BackendError} = require('./src/errors');
const room = require('./src/room_operations');
const sos = require('./src/sos_operations');
const profile = require('./src/profile_operations');
const notification = require('./src/notification_operations');

initializeApp();
const db = getFirestore();
const adminAuth = getAuth();
const common = {region: 'asia-southeast2', timeoutSeconds: 120};

function callable(operation, options = {}) {
  return onCall({...common, ...options}, async (request) => {
    try {
      return await operation(request.auth, request.data || {});
    } catch (error) {
      if (error instanceof BackendError) {
        throw new HttpsError(error.code, error.message, error.details);
      }
      console.error('Unhandled callable error', error);
      throw new HttpsError('internal', 'Terjadi kesalahan pada server.');
    }
  });
}

exports.ensureUserProfile = callable((auth, data) =>
  profile.ensureUserProfile(db, auth, data));
exports.reviewPendampingAccess = callable((auth, data) =>
  profile.reviewPendampingAccess(db, adminAuth, auth, data));
exports.createRoom = callable((auth, data) => room.createRoom(db, auth, data));
exports.joinRoomByCode = callable((auth, data) => room.joinRoomByCode(db, auth, data));
exports.leaveRoom = callable((auth, data) => room.leaveRoom(db, auth, data));
exports.updateRoomSettings = callable((auth, data) =>
  room.updateRoomSettings(db, auth, data));
exports.removeJamaah = callable((auth, data) => room.removeJamaah(db, auth, data));
exports.inviteJamaah = callable((auth, data) => room.inviteJamaah(db, auth, data));
exports.respondInvitation = callable((auth, data) =>
  room.respondInvitation(db, auth, data));
exports.deleteRoom = callable((auth, data) => room.deleteRoom(db, auth, data), {
  timeoutSeconds: 540,
  memory: '512MiB',
});
exports.triggerSos = callable((auth, data) => sos.triggerSos(db, auth, data));
exports.transitionSos = callable((auth, data) => sos.transitionSos(db, auth, data));
exports.sendNotification = callable((auth, data) =>
  notification.sendNotification(db, auth, data));
exports.sendPickupRequest = callable((auth, data) =>
  notification.sendPickupRequest(db, auth, data));
exports.sendCompanionMessage = callable((auth, data) =>
  notification.sendCompanionMessage(db, auth, data));
