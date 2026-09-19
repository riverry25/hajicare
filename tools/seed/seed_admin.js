/**
 * Idempotent development utility for creating the HajiCare administrator.
 *
 * Required environment variable:
 *   HAJICARE_ADMIN_PASSWORD
 *
 * Authentication uses either tools/seed/service-account.json (local only) or
 * Google Application Default Credentials. No OAuth token or password is read
 * from a developer-specific configuration file.
 */

'use strict';

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const ADMIN_EMAIL = process.env.HAJICARE_ADMIN_EMAIL || 'admin@hajicare.test';
const ADMIN_PASSWORD = process.env.HAJICARE_ADMIN_PASSWORD;
const ADMIN_NAME = process.env.HAJICARE_ADMIN_NAME || 'Administrator HajiCare';
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'hajicare-e6497';
const SERVICE_ACCOUNT_PATH = path.join(__dirname, 'service-account.json');

function initializeAdmin() {
  const credential = fs.existsSync(SERVICE_ACCOUNT_PATH)
    ? admin.credential.cert(require(SERVICE_ACCOUNT_PATH))
    : admin.credential.applicationDefault();

  admin.initializeApp({credential, projectId: PROJECT_ID});
  return {auth: admin.auth(), firestore: admin.firestore()};
}

async function upsertAuthUser(auth) {
  try {
    const existing = await auth.getUserByEmail(ADMIN_EMAIL);
    await auth.updateUser(existing.uid, {
      password: ADMIN_PASSWORD,
      displayName: ADMIN_NAME,
      emailVerified: true,
    });
    return existing.uid;
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    const created = await auth.createUser({
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
      displayName: ADMIN_NAME,
      emailVerified: true,
    });
    return created.uid;
  }
}

async function seedAdmin() {
  if (!ADMIN_PASSWORD || ADMIN_PASSWORD.length < 12) {
    throw new Error(
      'Set HAJICARE_ADMIN_PASSWORD dengan minimal 12 karakter sebelum menjalankan seed.',
    );
  }

  const {auth, firestore} = initializeAdmin();
  const uid = await upsertAuthUser(auth);

  // Security rules trust this server-issued claim, not the writable profile.
  await auth.setCustomUserClaims(uid, {role: 'admin'});

  const userRef = firestore.collection('users').doc(uid);
  const existing = await userRef.get();
  await userRef.set(
    {
      name: ADMIN_NAME,
      displayName: ADMIN_NAME,
      email: ADMIN_EMAIL,
      role: 'admin',
      activeRoomId: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...(!existing.exists
        ? {createdAt: admin.firestore.FieldValue.serverTimestamp()}
        : {}),
    },
    {merge: true},
  );

  console.log(`Admin ready: ${ADMIN_EMAIL} (${uid})`);
}

seedAdmin()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Admin seed failed:', error.message || error);
    process.exit(1);
  });
