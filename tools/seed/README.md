# HajiCare — Admin Seed Script

Utility untuk membuat atau memverifikasi akun **ADMIN** dev/testing di Firebase.

## Akun Admin Dev
* **Email**: `admin@hajicare.test`
* **Password**: `HajiCareAdmin2026!`
* **Display Name**: `Administrator HajiCare`
* **Role**: `admin`
* **Path Firestore**: `users/{UID}`
* **Karakteristik**: Bebas dari kewajiban `activeRoomId` dan langsung diarahkan ke `/admin/dashboard`.

---

## Autentikasi yang Didukung

Script `seed_admin.js` mendukung 2 metode autentikasi secara otomatis:

1. **Firebase CLI (Rekomendasi / Otomatis)**:
   Jika Anda sudah login via `firebase login` di terminal, script akan mendeteksi token OAuth lokal dan mengeksekusi pembuatan akun secara otomatis.

2. **Service Account JSON**:
   Simpan file service account key dari Firebase Console sebagai:
   `tools/seed/service-account.json`

---

## Cara Menjalankan

```bash
cd tools/seed
npm install
node seed_admin.js
```

Script bersifat **IDEMPOTENT** (aman dijalankan berkali-kali). Jika akun sudah ada, password dan data Firestore akan di-refresh tanpa membuat duplikat.
