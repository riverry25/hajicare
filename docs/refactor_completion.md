# HajiCare Refactor & Security Completion Report

Tanggal verifikasi: 19 September 2026.

## Hasil

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter analyze` | 0 issue |
| `dart fix --dry-run` | Tidak ada perbaikan otomatis |
| `flutter test` | 137/137 lulus |
| Debug APK | Berhasil |
| Release APK | Berhasil, sengaja unsigned tanpa keystore privat |

## Perbaikan utama

- Firestore rules diperketat berdasarkan identitas, custom claim admin,
  keanggotaan room, kepemilikan dokumen, dan allowlist field yang boleh berubah.
- Pembacaan SOS pengguna biasa dibatasi ke room aktif; admin tetap memperoleh
  tampilan global.
- Pembuatan event SOS dan pembaruan status user/member dilakukan dalam satu
  atomic batch melalui `SosService`.
- `RoomService`, `NotificationService`, `HajiCareController`,
  `NotificationController`, dan `AppStartupController` mendukung dependency
  injection/lazy Firebase sehingga lebih mudah diuji dan tidak menginisialisasi
  Firebase secara prematur.
- Google Sign-In dimigrasikan ke API versi 7.
- Dependensi utama diperbarui; paket tidak terpakai `provider` dan
  `awesome_dialog` dihapus.
- Mock repository yang tidak pernah dipakai dihapus.
- Key CARTO yang diberikan pemilik proyek dipakai sebagai default dan dapat
  dioverride melalui `--dart-define=CARTO_API_KEY=...` tanpa mengedit source.
- Script seed admin tidak lagi menyimpan password/OAuth credential. Password
  masuk melalui environment variable dan admin memperoleh custom claim.
- Release signing tidak lagi menggunakan debug certificate.
- Overflow marker peta dan inisialisasi controller saat build diperbaiki.

## Batasan tooling Android

Flutter 3.47 memberi warning migrasi Built-in Kotlin untuk
`firebase_auth`, `firebase_core`, `flutter_tts`, dan `ultralytics_yolo`.
Percobaan mengaktifkan Built-in Kotlin membuktikan `flutter_tts` 4.2.5 masih
menerapkan `kotlin-android` tanpa kondisi dan menyebabkan build gagal. Karena
itu proyek memakai mode kompatibilitas resmi:

```properties
android.builtInKotlin=false
android.newDsl=false
```

Warning tersebut berasal dari dependensi/tooling upstream, bukan analyzer Dart.
Jangan menyembunyikannya dengan skip flag atau memodifikasi Pub cache. Ulangi
migrasi setelah seluruh plugin di atas merilis dukungan Built-in Kotlin.

## Langkah operasional wajib

1. Jalankan seed admin agar akun admin memiliki custom claim terbaru.
2. Deploy `firestore.rules` dan `firestore.indexes.json`.
3. Buat upload keystore dan isi `android/key.properties` sebelum distribusi.
4. Uji rules dengan Firebase Emulator Suite di lingkungan yang memiliki Node.js
   dan Firebase CLI; keduanya tidak tersedia pada mesin audit ini.
5. Ganti `com.example.hajicare` hanya bersamaan dengan pembuatan Firebase Android
   app baru dan `google-services.json` yang sesuai.

## Peta arsitektur ringkas

- `lib/core`: bootstrap, routing, state global, theme, konfigurasi, dan widget
  lintas fitur.
- `lib/features/auth`: login, registrasi, reset password, Google Sign-In.
- `lib/features/room`: room, anggota, undangan, aktivitas, respons SOS.
- `lib/features/sos`: penulisan SOS atomik.
- `lib/features/map`: GPS, marker anggota, POI OSM, pencarian, dan routing.
- `lib/features/notification`: notifikasi Firestore dan undangan realtime.
- `lib/features/prayer`: waktu salat dan kiblat.
- `lib/features/translator` dan `communication`: terjemahan serta bantuan
  komunikasi.
- `lib/features/money`: deteksi uang SAR berbasis YOLO.
- `lib/features/smartband`: integrasi BLE.
- `lib/features/profile`: profil, kesehatan, dan kontak darurat.
