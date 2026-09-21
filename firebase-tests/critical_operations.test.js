'use strict';

const {after, before, beforeEach, test} = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const {createRequire} = require('node:module');
// Use the exact Admin SDK instance used by the operation modules so sentinel
// values (serverTimestamp/GeoPoint) share the same prototypes.
const functionsRequire = createRequire(path.join(__dirname, '..', 'functions', 'package.json'));
const {initializeApp, deleteApp} = functionsRequire('firebase-admin/app');
const {getFirestore} = functionsRequire('firebase-admin/firestore');
const room = require('../functions/src/room_operations');
const sos = require('../functions/src/sos_operations');

let app;
let db;
const manager = {uid: 'manager', token: {role: 'pendamping', email: 'manager@test.dev'}};
const jamaah = {uid: 'jamaah', token: {email: 'jamaah@test.dev'}};

before(() => {
  app = initializeApp({projectId: 'hajicare-test'}, 'critical-operations');
  db = getFirestore(app);
});

beforeEach(async () => {
  const collections = await db.listCollections();
  await Promise.all(collections.map((collection) => db.recursiveDelete(collection)));
  await db.collection('users').doc('manager').set({
    name: 'Manager', email: 'manager@test.dev', normalizedEmail: 'manager@test.dev',
    role: 'pendamping', activeRoomId: null,
  });
  await db.collection('users').doc('jamaah').set({
    name: 'Jamaah', email: 'jamaah@test.dev', normalizedEmail: 'jamaah@test.dev',
    role: 'jamaah', activeRoomId: null,
  });
});

after(async () => deleteApp(app));

test('concurrent join cannot create duplicate membership', async () => {
  const created = await room.createRoom(db, manager, {name: 'room aman'});
  const attempts = await Promise.allSettled([
    room.joinRoomByCode(db, jamaah, {roomCode: created.code}),
    room.joinRoomByCode(db, jamaah, {roomCode: created.code}),
  ]);
  assert.equal(attempts.filter((item) => item.status === 'fulfilled').length, 1);
  const members = await db.collection('rooms').doc(created.roomId).collection('members').get();
  assert.equal(members.docs.filter((doc) => doc.id === 'jamaah').length, 1);
});

test('double SOS trigger creates one active event and owner can cancel it', async () => {
  const created = await room.createRoom(db, manager, {name: 'room aman'});
  await room.joinRoomByCode(db, jamaah, {roomCode: created.code});
  const results = await Promise.all([
    sos.triggerSos(db, jamaah, {}),
    sos.triggerSos(db, jamaah, {}),
  ]);
  assert.equal(new Set(results.map((item) => item.eventId)).size, 1);
  assert.equal((await db.collection('sos_events').get()).size, 1);

  const cancelled = await sos.transitionSos(db, jamaah, {
    eventId: results[0].eventId, action: 'cancel',
  });
  assert.equal(cancelled.status, 'cancelled');
  assert.equal((await db.collection('active_sos').doc('jamaah').get()).exists, false);
});

test('room manager can respond and resolve exact SOS transitions', async () => {
  const created = await room.createRoom(db, manager, {name: 'room aman'});
  await room.joinRoomByCode(db, jamaah, {roomCode: created.code});
  const event = await sos.triggerSos(db, jamaah, {});
  assert.equal((await sos.transitionSos(db, manager, {
    eventId: event.eventId, action: 'respond',
  })).status, 'direspons');
  assert.equal((await sos.transitionSos(db, manager, {
    eventId: event.eventId, action: 'resolve',
  })).status, 'selesai');
  await assert.rejects(
    sos.transitionSos(db, jamaah, {eventId: event.eventId, action: 'cancel'}),
    (error) => error.code === 'failed-precondition',
  );
});

test('unrelated user cannot transition another user SOS', async () => {
  const created = await room.createRoom(db, manager, {name: 'room aman'});
  await room.joinRoomByCode(db, jamaah, {roomCode: created.code});
  const event = await sos.triggerSos(db, jamaah, {});
  const attacker = {uid: 'attacker', token: {email: 'attacker@test.dev'}};
  await assert.rejects(
    sos.transitionSos(db, attacker, {eventId: event.eventId, action: 'resolve'}),
    (error) => error.code === 'permission-denied',
  );
});

test('accepting an invitation to a deleted room expires safely', async () => {
  const created = await room.createRoom(db, manager, {name: 'room aman'});
  const invitation = await room.inviteJamaah(db, manager, {
    roomId: created.roomId, email: 'jamaah@test.dev',
  });
  await room.deleteRoom(db, manager, {roomId: created.roomId});
  const result = await room.respondInvitation(db, jamaah, {
    invitationId: invitation.invitationId, action: 'accept',
  }).catch((error) => error);
  assert.ok(result.code === 'failed-precondition' || result.status === 'expired');
  const snapshot = await db.collection('invitations').doc(invitation.invitationId).get();
  assert.equal(snapshot.data().status, 'expired');
  const notification = await db.collection('notifications')
    .doc(`invitation_${invitation.invitationId}`).get();
  assert.equal(notification.exists, false);
});

test('accepting an invitation removes its notification', async () => {
  const created = await room.createRoom(db, manager, {name: 'room aman'});
  const invitation = await room.inviteJamaah(db, manager, {
    roomId: created.roomId, email: 'jamaah@test.dev',
  });
  const notificationRef = db.collection('notifications')
    .doc(`invitation_${invitation.invitationId}`);
  assert.equal((await notificationRef.get()).exists, true);

  const result = await room.respondInvitation(db, jamaah, {
    invitationId: invitation.invitationId, action: 'accept',
  });

  assert.equal(result.status, 'accepted');
  assert.equal((await notificationRef.get()).exists, false);
  const successNotification = await db.collection('notifications')
    .doc(`invitation_accepted_${invitation.invitationId}`).get();
  assert.equal(successNotification.exists, true);
  assert.equal(successNotification.data().recipientId, jamaah.uid);
  assert.equal(successNotification.data().type, 'room_joined');
  assert.equal(successNotification.data().title, 'Berhasil Menerima Undangan');
});

test('rejecting an invitation removes its notification', async () => {
  const created = await room.createRoom(db, manager, {name: 'room aman'});
  const invitation = await room.inviteJamaah(db, manager, {
    roomId: created.roomId, email: 'jamaah@test.dev',
  });
  const notificationRef = db.collection('notifications')
    .doc(`invitation_${invitation.invitationId}`);
  assert.equal((await notificationRef.get()).exists, true);

  const result = await room.respondInvitation(db, jamaah, {
    invitationId: invitation.invitationId, action: 'reject',
  });

  assert.equal(result.status, 'rejected');
  assert.equal((await notificationRef.get()).exists, false);
});
