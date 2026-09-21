'use strict';

const fs = require('node:fs');
const path = require('node:path');
const {after, before, beforeEach, test} = require('node:test');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
} = require('firebase/firestore');

const projectId = 'hajicare-test';
let environment;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
    },
  });
});

beforeEach(async () => {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', 'manager'), {
      role: 'pendamping', activeRoomId: 'room-a', name: 'Manager',
    });
    await setDoc(doc(db, 'users', 'jamaah'), {
      role: 'jamaah', activeRoomId: 'room-a', name: 'Jamaah',
    });
    await setDoc(doc(db, 'users', 'attacker'), {
      role: 'jamaah', activeRoomId: null, name: 'Attacker',
    });
    await setDoc(doc(db, 'users', 'outsider'), {
      role: 'jamaah', activeRoomId: 'room-b', name: 'Outsider',
    });
    await setDoc(doc(db, 'rooms', 'room-a'), {
      name: 'Room A', code: 'ABC234', createdBy: 'manager',
      pendampingIds: ['manager'], isActive: true,
    });
    await setDoc(doc(db, 'rooms', 'room-a', 'members', 'manager'), {
      uid: 'manager', role: 'pendamping', name: 'Manager',
    });
    await setDoc(doc(db, 'rooms', 'room-a', 'members', 'jamaah'), {
      uid: 'jamaah', role: 'jamaah', name: 'Jamaah',
    });
    await setDoc(doc(db, 'notifications', 'n1'), {
      recipientId: 'jamaah', title: 'Pesan', isRead: false,
    });
  });
});

after(async () => environment.cleanup());

test('profile role cannot self-escalate', async () => {
  const db = environment.authenticatedContext('attacker').firestore();
  await assertFails(updateDoc(doc(db, 'users', 'attacker'), {role: 'admin'}));
});

test('client cannot create membership or take over manager arrays', async () => {
  const db = environment.authenticatedContext('attacker').firestore();
  await assertFails(setDoc(doc(db, 'rooms', 'room-a', 'members', 'attacker'), {
    uid: 'attacker', role: 'pendamping', name: 'Attacker',
  }));
  await assertFails(updateDoc(doc(db, 'rooms', 'room-a'), {
    pendampingIds: ['manager', 'attacker'],
  }));
});

test('signed-in outsider cannot enumerate or read a room', async () => {
  const db = environment.authenticatedContext('outsider').firestore();
  await assertFails(getDoc(doc(db, 'rooms', 'room-a')));
});

test('room membership does not expose another full private profile', async () => {
  const db = environment.authenticatedContext('manager', {role: 'pendamping'}).firestore();
  await assertFails(getDoc(doc(db, 'users', 'jamaah')));
  await assertSucceeds(getDoc(doc(db, 'rooms', 'room-a', 'members', 'jamaah')));
});

test('client cannot forge SOS writes', async () => {
  const db = environment.authenticatedContext('jamaah').firestore();
  await assertFails(setDoc(doc(db, 'sos_events', 'forged'), {
    userId: 'jamaah', jamaahId: 'jamaah', roomId: 'room-a', status: 'active',
  }));
});

test('member can broadcast only their location fields', async () => {
  const db = environment.authenticatedContext('jamaah').firestore();
  await assertSucceeds(updateDoc(doc(db, 'rooms', 'room-a', 'members', 'jamaah'), {
    currentLocation: {latitude: -6.2, longitude: 106.8},
  }));
  await assertFails(updateDoc(doc(db, 'rooms', 'room-a', 'members', 'jamaah'), {
    role: 'pendamping',
  }));
});

test('notification recipient may mark read but may not alter content', async () => {
  const db = environment.authenticatedContext('jamaah').firestore();
  await assertSucceeds(updateDoc(doc(db, 'notifications', 'n1'), {isRead: true}));
  await assertFails(updateDoc(doc(db, 'notifications', 'n1'), {title: 'Forged'}));
});

test('client cannot bypass room validation for pickup requests', async () => {
  const db = environment.authenticatedContext('jamaah').firestore();
  await assertFails(setDoc(doc(db, 'notifications', 'forged-pickup'), {
    recipientId: 'manager',
    senderId: 'jamaah',
    targetRoomId: 'room-a',
    type: 'pickup_request',
    title: 'Permintaan Jemput',
    message: 'Jemput saya',
    isRead: false,
  }));
});

test('jamaah may directly notify a pendamping in the same room', async () => {
  const db = environment.authenticatedContext('jamaah').firestore();
  for (const type of ['companion_info', 'companion_message']) {
    await assertSucceeds(setDoc(doc(db, 'notifications', `valid-${type}`), {
      recipientId: 'manager',
      senderId: 'jamaah',
      senderName: 'Jamaah',
      senderRole: 'jamaah',
      targetRoomId: 'room-a',
      targetUserId: 'manager',
      scope: type == 'companion_info' ? 'all_companions' : 'user',
      title: 'Pesan dari Jamaah',
      message: 'Mohon bantuan pendamping.',
      type,
      isRead: false,
    }));
  }
});

test('direct pendamping notification rejects outsiders and invalid recipients', async () => {
  const validShape = {
    recipientId: 'manager',
    senderId: 'attacker',
    senderName: 'Attacker',
    senderRole: 'jamaah',
    targetRoomId: 'room-a',
    targetUserId: 'manager',
    scope: 'user',
    title: 'Pesan dari Attacker',
    message: 'Pesan tidak sah',
    type: 'companion_message',
    isRead: false,
  };
  const outsiderDb = environment.authenticatedContext('attacker').firestore();
  await assertFails(setDoc(
    doc(outsiderDb, 'notifications', 'outsider-message'),
    validShape,
  ));

  const jamaahDb = environment.authenticatedContext('jamaah').firestore();
  await assertFails(setDoc(doc(jamaahDb, 'notifications', 'wrong-target'), {
    ...validShape,
    senderId: 'jamaah',
    recipientId: 'jamaah',
    targetUserId: 'jamaah',
  }));
});
