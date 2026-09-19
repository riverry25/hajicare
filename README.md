# HajiCare

HajiCare adalah aplikasi Flutter untuk membantu jamaah dan pendamping selama
ibadah haji. Fitur utamanya meliputi room jamaah, pelacakan lokasi, SOS,
navigasi/POI, jadwal salat, komunikasi, penerjemah, pengenalan uang SAR,
smartband, profil kesehatan, dan notifikasi.

## Menjalankan proyek

Persyaratan yang telah diverifikasi:

- Flutter 3.47.2 / Dart 3.13.2
- JDK 17
- Android SDK 36

```powershell
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=ORS_API_KEY=your_optional_key --dart-define=CARTO_API_KEY=your_carto_key
```

`ORS_API_KEY` bersifat opsional. Tanpa key, fitur rute memakai fallback OSRM.
`CARTO_API_KEY` dapat dipakai untuk mengganti key basemap bawaan saat build.
Jangan menyimpan service account, password, token privat, atau keystore di
repository.

## Firebase

Konfigurasi client Firebase berada di `lib/firebase_options.dart` dan
`android/app/google-services.json`. Firestore memakai `firestore.rules` dan
`firestore.indexes.json` dari repository ini.

Deploy rules dan index setelah login Firebase CLI:

```powershell
firebase deploy --only firestore:rules,firestore:indexes
```

Hak admin ditentukan oleh Firebase Auth custom claim `role=admin`, bukan oleh
field profil yang bisa ditulis client. Gunakan petunjuk aman di
`tools/seed/README.md` untuk membuat atau memperbarui akun admin.

## Release Android

Build release tidak pernah memakai debug key. Salin
`android/key.properties.example` menjadi `android/key.properties`, isi dengan
keystore privat, lalu jalankan:

```powershell
flutter build appbundle --release
```

Tanpa `key.properties`, Gradle sengaja menghasilkan artifact release unsigned.
File keystore dan `key.properties` sudah diabaikan oleh Git.

## Pemeriksaan kualitas

Baseline hasil refactor tersedia di `docs/refactor_completion.md`. Perintah
utama sebelum merge:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```
