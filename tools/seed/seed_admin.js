/**
 * seed_admin.js — Dev/testing utility (IDEMPOTENT)
 *
 * Mendukung 2 metode autentikasi server-side:
 *   1. Service Account JSON: tools/seed/service-account.json
 *   2. Firebase CLI credentials (otomatis terdeteksi jika sudah login via `firebase login`)
 *
 * Jalankan:
 *   cd tools/seed
 *   node seed_admin.js
 */

'use strict';

const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');
const os    = require('os');

// ─── Config ───────────────────────────────────────────────────────────────────
const ADMIN_EMAIL    = 'admin@hajicare.test';
const ADMIN_PASSWORD = 'HajiCareAdmin2026!';
const ADMIN_NAME     = 'Administrator HajiCare';
const PROJECT_ID     = 'hajicare-e6497';
const SA_PATH        = path.join(__dirname, 'service-account.json');

// ─── Auth Detection & Init ───────────────────────────────────────────────────
async function resolveAuth() {
  // Opsi 1: Service Account JSON
  if (fs.existsSync(SA_PATH)) {
    console.log('🔑  Menggunakan Service Account JSON:', SA_PATH);
    const cert = require(SA_PATH);
    admin.initializeApp({
      credential: admin.credential.cert(cert),
      projectId: PROJECT_ID,
    });
    return { mode: 'service_account', db: admin.firestore() };
  }

  // Opsi 2: Firebase CLI OAuth Token
  const cliConfigPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (fs.existsSync(cliConfigPath)) {
    console.log('🔑  Service Account JSON tidak ditemukan. Menggunakan kredensial Firebase CLI yang aktif...');
    const cfg = JSON.parse(fs.readFileSync(cliConfigPath, 'utf8'));
    let accessToken = cfg.tokens?.access_token;
    const expiresAt = cfg.tokens?.expires_at || 0;

    // Refresh jika hampir kadaluarsa
    if (!accessToken || Date.now() >= expiresAt - 60000) {
      console.log('🔄  Access token kadaluarsa, merefresh token...');
      const refreshToken = cfg.tokens?.refresh_token;
      if (!refreshToken) {
        throw new Error('Refresh token Firebase CLI tidak ditemukan. Jalankan `firebase login`.');
      }
      const res = await fetch('https://oauth2.googleapis.com/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
          client_secret: 'j9iVZfY8kkCEFUPaAeJY0nCh',
          refresh_token: refreshToken,
          grant_type: 'refresh_token',
        }),
      });
      const refreshData = await res.json();
      if (!refreshData.access_token) {
        throw new Error('Gagal merefresh access token: ' + JSON.stringify(refreshData));
      }
      accessToken = refreshData.access_token;
      cfg.tokens.access_token = accessToken;
      cfg.tokens.expires_at = Date.now() + (refreshData.expires_in * 1000);
      fs.writeFileSync(cliConfigPath, JSON.stringify(cfg, null, 2), 'utf8');
      console.log('✅  Access token berhasil diperbarui.');
    }

    admin.initializeApp({
      credential: {
        getAccessToken: async () => ({
          access_token: accessToken,
          expires_in: Math.max(60, Math.floor((cfg.tokens.expires_at - Date.now()) / 1000)),
        }),
      },
      projectId: PROJECT_ID,
    });

    return { mode: 'cli_token', token: accessToken };
  }

  throw new Error(
    'Kredensial tidak ditemukan!\n' +
    'Solusi:\n' +
    '1. Jalankan `firebase login` di terminal, ATAU\n' +
    '2. Simpan Service Account JSON di tools/seed/service-account.json'
  );
}

// ─── Firestore Document Upsert ───────────────────────────────────────────────
async function upsertFirestoreUser(authMode, uid) {
  const docPath = `users/${uid}`;

  if (authMode.mode === 'service_account') {
    const db = authMode.db;
    const ref = db.collection('users').doc(uid);
    const snap = await ref.get();
    const data = {
      name: ADMIN_NAME,
      email: ADMIN_EMAIL,
      role: 'admin',
      activeRoomId: null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (!snap.exists) {
      data.createdAt = admin.firestore.FieldValue.serverTimestamp();
    }
    await ref.set(data, { merge: true });
    console.log(`✅  Firestore: ${docPath} (via Firestore SDK)`);
  } else {
    // Via Firestore REST API
    const token = authMode.token;
    const getUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`;
    const getRes = await fetch(getUrl, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const isNew = getRes.status === 404;
    const nowIso = new Date().toISOString();

    let patchUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}?updateMask.fieldPaths=name&updateMask.fieldPaths=email&updateMask.fieldPaths=role&updateMask.fieldPaths=activeRoomId&updateMask.fieldPaths=updatedAt`;
    const fields = {
      name: { stringValue: ADMIN_NAME },
      email: { stringValue: ADMIN_EMAIL },
      role: { stringValue: 'admin' },
      activeRoomId: { nullValue: null },
      updatedAt: { timestampValue: nowIso },
    };

    if (isNew) {
      patchUrl += '&updateMask.fieldPaths=createdAt';
      fields.createdAt = { timestampValue: nowIso };
    }

    const patchRes = await fetch(patchUrl, {
      method: 'PATCH',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ fields }),
    });

    if (!patchRes.ok) {
      const errText = await patchRes.text();
      throw new Error(`Gagal menulis dokumen Firestore users/${uid}: ${patchRes.status} ${errText}`);
    }

    console.log(`✅  Firestore: ${docPath} (via Firestore REST API)`);
  }
}

// ─── Main Execution ───────────────────────────────────────────────────────────
async function seedAdmin() {
  console.log('\n🌱  HajiCare Admin Seed — Project:', PROJECT_ID);
  console.log('═'.repeat(55));

  const authMode = await resolveAuth();
  const auth = admin.auth();

  let uid;
  let created = false;

  // Step 1: Cek / buat akun Firebase Auth
  try {
    const existing = await auth.getUserByEmail(ADMIN_EMAIL);
    uid = existing.uid;
    console.log('✅  Auth: Akun sudah ada, UID =', uid);
    await auth.updateUser(uid, {
      password: ADMIN_PASSWORD,
      displayName: ADMIN_NAME,
      emailVerified: true,
    });
    console.log('    ↳ Password & displayName di-refresh');
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      const u = await auth.createUser({
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        displayName: ADMIN_NAME,
        emailVerified: true,
      });
      uid = u.uid;
      created = true;
      console.log('✅  Auth: Akun BARU dibuat, UID =', uid);
    } else {
      throw err;
    }
  }

  // Step 2: Set custom user claims
  try {
    await auth.setCustomUserClaims(uid, { role: 'admin' });
    console.log('✅  Custom Claims: { role: "admin" }');
  } catch (claimErr) {
    console.warn('⚠️   Custom claims peringatan (dilewati):', claimErr.message);
  }

  // Step 3: Upsert dokumen users/{uid} di Firestore
  await upsertFirestoreUser(authMode, uid);

  // Summary
  console.log('\n' + '═'.repeat(55));
  console.log('🎉  SELESAI —', created ? 'AKUN BERHASIL DIBUAT' : 'AKUN DIPERBARUI & DIVERIFIKASI');
  console.log('  Email       :', ADMIN_EMAIL);
  console.log('  Password    :', ADMIN_PASSWORD);
  console.log('  UID         :', uid);
  console.log('  Firestore   : users/' + uid);
  console.log('  Role        : admin  (Langsung ke /admin/dashboard)');
  console.log('═'.repeat(55) + '\n');

  process.exit(0);
}

seedAdmin().catch(err => {
  console.error('\n❌  GAGAL:', err.message || err);
  process.exit(1);
});
