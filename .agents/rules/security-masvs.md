# OWASP MASVS (Mobile Application Security Verification Standard) - HajiCare Rules

## Overview
Dokumen ini merupakan panduan dan standar kepatuhan keamanan mobile OWASP MASVS (v2.0) yang diterapkan pada arsitektur aplikasi HajiCare (Flutter & Firebase). Seluruh pengembangan fitur, perbaikan kode, dan integrasi backend wajib mematuhi standar berikut.

---

## V1: Storage & Privacy (Penyimpanan & Privasi Data)
1. **Enkripsi Kredensial & Sesi (MASVS-STORAGE-1):**
   - Dilarang menyimpan token autentikasi, API secrets, token sesi, atau data kredensial sensitif dalam `SharedPreferences` biasa atau plain SQLite.
   - Gunakan `flutter_secure_storage` yang didukung oleh Android Keystore (EncryptedSharedPreferences) dan iOS Keychain.
2. **Pencegahan Kebocoran Backup ADB (MASVS-STORAGE-2):**
   - Atribut `android:allowBackup="false"` dan `android:fullBackupContent="false"` wajib dikonfigurasikan pada `AndroidManifest.xml` untuk mencegah ekstraksi data aplikasi melalui kabel USB debugging.
3. **Pencegahan Hardcoded Secrets (MASVS-STORAGE-3):**
   - Dilarang keras menaruh API private keys, service account credentials, atau App Check debug tokens di dalam kode sumber repositori.
   - Gunakan environment variables atau proxy backend yang aman.
4. **Perlindungan Data PII (Personally Identifiable Information):**
   - Data medis jamaah (golongan darah, riwayat alergi, penyakit), nomor NIK, nomor porsi haji, dan nomor paspor tidak boleh disimpan secara terbuka atau dapat dibaca oleh pengguna asing tanpa otorisasi.

---

## V2: Cryptography (Kriptografi)
1. **Algoritma Modern & Standar Industri (MASVS-CRYPTO-1):**
   - Gunakan AES-GCM (256-bit) untuk enkripsi simetris data at rest.
   - Gunakan RSA (minimal 2048-bit, disarankan 4096-bit dengan OAEP padding) atau kurva eliptik (ECDSA P-256) untuk asimetris.
   - Dilarang menggunakan algoritma usang atau insecure: DES, 3DES, RC4, MD5, SHA-1, atau AES dalam mode ECB.
2. **Manajemen Kunci Perangkat Keras (MASVS-CRYPTO-2):**
   - Operasi pembangkitan dan penyimpanan kunci privat harus memanfaatkan hardware security module (Android TEE/StrongBox dan iOS Secure Enclave).

---

## V3: Authentication & Authorization (Autentikasi & Otorisasi)
1. **Zero-Trust Server-Side Enforcement (MASVS-AUTH-1):**
   - Logika izin (authorization) di client controller hanyalah pembantu UX. Keamanan mutlak WAJIB divalidasi di sisi server melalui **Firebase Security Rules** (`firestore.rules` dan `storage.rules`).
2. **Pencegahan Eskalasi Peran (Privilege Escalation):**
   - Pengguna dilarang mengubah perannya sendiri (`role`) pada dokumen `users/{uid}` atau subkoleksi `members/{memberUid}` melalui operasi `update`.
   - Peran `admin`, `pendamping`, atau `petugas` tidak boleh dapat di-assign sendiri secara bebas oleh client.
3. **Validasi Kepemilikan & Scope (Ownership & Scoping):**
   - Semua mutasi dokumen sensitif (profil jamaah, pemicuan darurat SOS, pengiriman pesan pendamping) wajib mencocokkan `request.auth.uid == userId`.
   - Data rombongan (lokasi anggota, nomor kamar) hanya boleh diakses oleh anggota yang terdaftar dalam rombongan tersebut (`isRoomMember(roomId)`).

---

## V4: Network Communication (Komunikasi Jaringan)
1. **Pencegahan Cleartext Traffic (MASVS-NETWORK-1):**
   - Wajib menonaktifkan lalu lintas HTTP tidak terenkripsi (`android:usesCleartextTraffic="false"`).
   - Terapkan konfigurasi `network_security_config.xml` untuk menegakkan TLS 1.2/1.3 pada semua endpoint.
2. **Attestation Permintaan Backend (MASVS-NETWORK-2):**
   - Gunakan **Firebase App Check** dengan **Play Integrity** (Android) dan **DeviceCheck** (iOS) untuk memastikan setiap request API berasal dari build aplikasi resmi, bukan dari skrip bot atau modifikasi emulator.

---

## V5: Platform Interaction (Interaksi Platform)
1. **Pencegahan Task Hijacking (StrandHogg) (MASVS-PLATFORM-1):**
   - Konfigurasikan `android:taskAffinity=""` pada aktivitas utama (`MainActivity`) untuk memblokir teknik task hijacking (StrandHogg 1.0 & 2.0).
2. **Pengelolaan Izin Minimal (Principle of Least Privilege):**
   - Hanya deklarasikan izin yang benar-benar dibutuhkan oleh fungsionalitas aplikasi.
   - Tangani penolakan izin secara graceful tanpa menyebabkan crash pada runtime.
3. **Sanitasi Deep Links & Intent Filters:**
   - Validasi skema URL dan parameter data sebelum memproses navigasi berbasis deep link.

---

## V6: Code Quality & Build Settings (Kualitas Kode & Konfigurasi Build)
1. **Minifikasi & Obfuscation Produksi (MASVS-CODE-1):**
   - Build rilis Android wajib mengaktifkan R8/ProGuard (`isMinifyEnabled = true`, `isShrinkResources = true`).
   - Kompilasi Flutter release wajib menyertakan flag obfuscation simbol:
     `flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols`
2. **Validasi & Sanitasi Masukan (Input Validation):**
   - Seluruh input teks dari pengguna (nama rombongan, kode room, form profil, keluhan kesehatan) harus disanitasi dari null byte, karakter kontrol tersembunyi, dan tag skrip berbahaya sebelum dikirim ke basis data.
   - Enforce batas panjang karakter (string length constraints) pada setiap input form dan skema Firestore untuk mencegah eksploitasi Resource Exhaustion / Denial of Service.
