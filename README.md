# HajiCare: Ekosistem Cerdas Pendamping & Monitoring Jamaah Haji / Umrah

<div align="center">

![HajiCare Hero Banner](assets/images/haji.webp)

### *Inovasi Terpadu Berbasis IoT Smartband, Edge AI Aksesibilitas, dan Pemantauan Geospasial Real-Time untuk Jamaah Haji dan Lansia*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase%20Cloud-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![TensorFlow Lite](https://img.shields.io/badge/AI%2FML-TensorFlow%20Lite-FF6F00?logo=tensorflow&logoColor=white)](https://www.tensorflow.org/lite)
[![Hardware](https://img.shields.io/badge/IoT-ESP32--S3%20BLE%205.0-E7352C?logo=espressif&logoColor=white)](https://www.espressif.com)
[![License](https://img.shields.io/badge/License-MIT-success.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen.svg)](#)

</div>

---

## 📌 Ringkasan Eksekutif (Executive Summary)

Ibadah Haji dan Umrah merupakan ibadah fisik yang melibatkan lebih dari **2,5 juta jamaah dari seluruh penjuru dunia** di satu kawasan geografis yang padat (Makkah, Madinah, Mina, Arafah, Muzdalifah). Mayoritas jamaah Indonesia tergolong **lanjut usia (lansia)** dan sebagian memiliki **disabilitas sensorik (rungu/wicara/netra)**.

Tantangan di lapangan meliputi:
1. **Risiko Tersesat**: Jamaah terpisah dari rombongan di tengah lautan jutaan manusia tanpa koneksi internet yang stabil.
2. **Kondisi Kesehatan Kritis**: Suhu ekstrem gurun pasir (>45°C) memicu dehidrasi mendadak, kelelahan fisik, hingga serangan jantung (*heatstroke* dan henti jantung mendadak).
3. **Keterbatasan Komunikasi & Aksesibilitas**: Hambatan bahasa antara jamaah Indonesia/disabilitas rungu dengan petugas lokal Arab Saudi, serta kesulitan mengenali nominal mata uang Riyal (SAR).
4. **Keterlambatan Penanganan Darurat**: Ketiadaan tombol panik yang terhubung langsung secara real-time ke posko pendamping dan tim medis.

**HajiCare** hadir sebagai solusi komprehensif yang mengintegrasikan **aplikasi mobile cerdas** dengan **gelang pintar (IoT Smartband)** untuk mendampingi jamaah secara preventif, adaptif, dan responsif.

---

## 🌟 4 Pilar Solusi Inovatif

<div align="center">

</div>

### 1. ⌚ Smart IoT Wearable (Gelang Pintar ESP32-S3)
Gelang pintar nirkabel berdaya rendah (*Bluetooth Low Energy / BLE 5.0*) yang dikenakan oleh jamaah di pergelangan tangan:
- **Detak Jantung & SpO2 (Sensor MAX30102)**: Memantau denyut nadi dan saturasi oksigen secara berkala untuk deteksi dini aritmia dan hipoksia.
- **Suhu Tubuh Inframerah (Sensor MLX90614)**: Mengukur suhu tubuh akurat tanpa kontak langsung guna mendeteksi gejala *heat exhaustion* sebelum terjadi *heatstroke*.
- **Deteksi Jatuh & Akselerometer (Sensor MPU6050)**: Mendeteksi benturan atau kondisi jatuh tiba-tiba pada jamaah lansia secara otomatis.
- **Tombol Darurat Fisik (Hardware SOS Button)**: Tombol taktil yang dapat ditekan jamaah saat darurat tanpa perlu membuka smartphone.

### 2. 🤖 Edge AI & Aksesibilitas Disabilitas (Bekerja 100% Offline)
Solusi kecerdasan buatan terpasang (*on-device AI*) yang berjalan langsung di HP jamaah tanpa bergantung pada sinyal internet:
- **Penerjemah Bahasa Isyarat Dua Arah (BISINDO & SIBI)**:
  - *Sign-to-Text*: Kamera mengenali gerakan bahasa isyarat melalui ekstraksi titik koordinat (*MediaPipe Landmark*) dan inferensi *Recurrent Neural Network (Motion GRU)*.
  - *Text-to-Sign*: Mengonversi teks atau perintah suara petugas menjadi video animasi bahasa isyarat beresolusi tinggi yang telah tersimpan di memori perangkat.
- **Pendeteksi Nominal Uang Cerdas (Saudi Riyal & Rupiah)**:
  - Menggunakan model *MobileNet / YOLO TFLite* untuk mengenali nominal uang kertas dan koin Riyal (SAR) maupun Rupiah (IDR).
  - Dilengkapi konversi suara otomatis (*Text-to-Speech*) dan estimasi kurs real-time, melindungi jamaah dari salah bayar atau penipuan.

### 3. 📍 Smart Room & Radar Geospasial Real-Time
- **Sistem Kamar & Rombongan (Room Grouping)**: Jamaah dan pendamping terhubung dalam satu *Room* privat via kode unik atau pemindaian QR Code.
- **Radar Pendamping Terdekat**: Menghitung jarak geospasial real-time antara jamaah dan petugas terdekat.
- **Geofencing & Dynamic Safe Radius**: Sistem otomatis memberi peringatan getar dan notifikasi audio jika jamaah keluar dari radius aman yang ditentukan pendamping (misal: radius 100 meter saat di Masjidil Haram).

### 4. 🕋 Pendamping Ibadah Digital & Penanganan Darurat
- **Panduan Manasik & Doa Interaktif**: Alur tahapan haji dari Ihram, Thawaf, Sa'i, Wukuf, hingga Tahallul dengan teks Arab, transliterasi, arti, dan audio panduan.
- **Waktu Shalat & Adzan Akurat**: Perhitungan hisab posisi lintang/bujur Makkah & Madinah dengan alarm adzan latar belakang yang andal.
- **Kompas Kiblat Astrolabe**: Navigasi arah Ka'bah berbasis sensor giroskop dan magnetik kompas ponsel.
- **Sistem Tanggap Darurat (Emergency SOS Dispatch)**: Satu sentuhan tombol SOS memancarkan sinyal darurat, titik koordinat GPS, serta histori tanda vital jamaah ke seluruh dashboard pendamping di area tersebut.

---

## 🏗️ Arsitektur Sistem

Berikut adalah alur komunikasi data antara perangkat fisik jamaah, smartphone, cloud database, dan dashboard pendamping:

```mermaid
graph TD
    subgraph IoT_Wearable [Smartband ESP32-S3]
        S1[Sensor MAX30102 - Detak Jantung/SpO2]
        S2[Sensor MLX90614 - Suhu Tubuh]
        S3[Sensor MPU6050 - Deteksi Jatuh]
        S4[Tombol SOS Fisik]
    end

    subgraph Mobile_Client [HajiCare Mobile App - Flutter]
        BLE[Bluetooth Low Energy 5.0 Engine]
        AI1[Edge AI BISINDO/SIBI - MediaPipe + GRU]
        AI2[Edge AI Deteksi Uang - TFLite]
        MAP[Engine Navigasi & Radar Geospasial]
        AUDIO[Service Adzan & Suara Latar Belakang]
    end

    subgraph Cloud_Infrastructure [Firebase Cloud Platform]
        AUTH[Firebase Authentication]
        DB[(Cloud Firestore Realtime Sync)]
        CF[Cloud Functions Backend]
        CHECK[Firebase App Check - Play Integrity]
    end

    subgraph Companion_Dashboard [Dashboard Petugas / Pendamping]
        D1[Monitoring Radar Posisi Jamaah]
        D2[Peringatan Darurat SOS & Jatuh]
        D3[Telemetri Vital Jamaah Berisiko]
    end

    IoT_Wearable -->|Koneksi BLE Realtime| BLE
    BLE --> Mobile_Client
    Mobile_Client -->|Sinkronisasi Data Aman| DB
    Mobile_Client -->|Autentikasi & Guard| AUTH
    DB <-->|Event Triggers & Validasi| CF
    DB -->|Realtime Stream Listener| Companion_Dashboard
```

---

## 💻 Spesifikasi Teknologi (Tech Stack)

| Komponen | Teknologi | Keterangan |
| :--- | :--- | :--- |
| **Framework Utama** | Flutter 3.x & Dart 3.x | Multiplatform dengan rendering performa tinggi 60 FPS |
| **Manajemen State** | GetX (Reactive Architecture) | Arsitektur reaktif bersih memisahkan UI, logika bisnis, dan data |
| **Edge Machine Learning** | TensorFlow Lite (`tflite_flutter`) | Model GRU terkuantisasi (float16) untuk efisiensi memori & daya |
| **Penglihatan Komputer** | MediaPipe Holistic Landmarks | Ekstraksi 543 koordinat gerak tangan, tubuh, dan wajah |
| **IoT & Komunikasi Nirkabel** | `flutter_blue_plus` (BLE 5.0) | Protokol transmisi biner karakteristik kustom GATT ESP32 |
| **Peta & Geospasial** | `flutter_map`, OpenStreetMap | Navigasi peta vektor interaktif dengan caching offline |
| **Cloud Database** | Cloud Firestore & Firebase Auth | Sinkronisasi data real-time latensi rendah dengan aturan keamanan ketat |
| **Keamanan Aplikasi** | Firebase App Check & Keystore | Proteksi integritas aplikasi dan enkripsi lokal data sensitif |

---

## 📋 Prasyarat Sistem (Prerequisites)

Sebelum menjalankan aplikasi, pastikan perangkat pengembangan Anda telah terinstal:

1. **Git** (versi terbaru)
2. **Flutter SDK** (versi `^3.11.1` atau lebih baru)
   ```bash
   flutter --version
   ```
3. **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart
4. **Java Development Kit (JDK 17)**
5. **Perangkat Fisik Android**:
   - OS Android 8.0 (Oreo / API 26) ke atas.
   - Mendukung Bluetooth Low Energy (BLE) dan GPS Lokasi.

---

## 🚀 Panduan Instalasi Langkah Demi Langkah (Step-by-Step)

### 1. Kloning Repositori
Buka terminal dan unduh repositori HajiCare ke komputer lokal Anda:
```bash
git clone https://github.com/riverry25/hajicare.git
cd hajicare
```

### 2. Unduh Dependensi Proyek
Jalankan perintah berikut untuk mengunduh seluruh dependensi Flutter yang didefinisikan pada `pubspec.yaml`:
```bash
flutter pub get
```

### 3. Konfigurasi Firebase (Opsi Default / Kustom)
Aplikasi HajiCare telah dilengkapi template konfigurasi Firebase:
- File `lib/firebase_options.example.dart` tersedia sebagai panduan.
- Untuk menghubungkan ke project Firebase Anda sendiri:
  ```bash
  # Instal FlutterFire CLI jika belum tersedia
  dart pub global activate flutterfire_cli

  # Konfigurasikan project
  flutterfire configure
  ```

### 4. Pengecekan Kualitas Kode
Pastikan seluruh file kode dalam kondisi optimal tanpa peringatan atau kesalahan sintaks:
```bash
flutter analyze
```
*(Hasil verifikasi harus menampilkan `No issues found!`)*

### 5. Menjalankan Aplikasi pada Perangkat
Hubungkan smartphone Android Anda via kabel USB (pastikan *USB Debugging* aktif), kemudian jalankan:
```bash
# Menjalankan dalam mode Debug
flutter run

# Atau menjalankan dalam performa rilis maksimal (Recommended untuk demo)
flutter run --release
```

---

## 📁 Struktur Direktori Proyek

Arsitektur folder dirancang menggunakan prinsip **Clean Architecture & Feature-First**:

```text
hajicare/
├── android/                   # Konfigurasi native Android, Gradle, dan izin perangkat
├── assets/                    # Asset gambar, ikon, audio adzan, dan font tipografi
│   ├── audio/                 # Rekaman audio adzan subuh dan reguler
│   ├── images/                # Banner dan aset grafis ilustrasi
│   ├── models/                # Model TFLite offline (BISINDO, SIBI, Deteksi Uang)
│   └── sign_language/         # Video kamus bahasa isyarat terkompresi lokal
├── lib/
│   ├── core/                  # Utilitas global, tema, rute, lokalisasi, dan service inti
│   │   ├── constants/         # Konstanta konfigurasi sistem
│   │   ├── locales/           # Terjemahan multibahasa (Indonesia, Jawa, Sunda, Inggris)
│   │   ├── routes/            # Pengaturan navigasi rute halaman
│   │   ├── services/          # Service adzan, alarm background, geocoding, audio TTS
│   │   └── theme/             # Token desain White Sand, warna, ukuran, dan tipografi
│   ├── features/              # Modul fungsional independen (Feature-Driven Structure)
│   │   ├── auth/              # Otentikasi jamaah & pendamping (Email/Google Sign-In)
│   │   ├── communication/     # Modul komunikasi cepat & gestur
│   │   ├── dashboard/         # Dashboard jamaah dan dashboard radar pendamping
│   │   ├── hajj_dua/          # Kumpulan doa haji dan umrah terstruktur
│   │   ├── map/               # Navigasi peta geospasial dan POI posko haji
│   │   ├── money/             # Deteksi nominal mata uang real-time (SAR/IDR)
│   │   ├── prayer/            # Jadwal shalat akurat dan kompas kiblat
│   │   ├── room/              # Manajemen room rombongan dan pembagian anggota
│   │   ├── sign_language/     # Penerjemah bahasa isyarat SIBI dan BISINDO
│   │   ├── smartband/         # Integrasi BLE dan telemetri sensor gelang pintar
│   │   └── sos/               # Sistem tombol panik darurat dan dispatching
│   ├── firebase_options.dart  # Konfigurasi platform Firebase
│   └── main.dart              # Titik masuk utama aplikasi (Entrypoint)
└── packages/                  # Sub-package kustom (Adhan Foreground Background Service)
```

---

## ♿ Aksesibilitas & Kenyamanan Pengguna

HajiCare dirancang dengan prinsip **Inklusivitas Penuh (Accessibility by Design)**:
- **Dukungan Skala Huruf Dinamis**: Ukuran teks dapat dibesarkan hingga 200% bagi jamaah lanjut usia tanpa merusak tata letak antarmuka (*no text clipping*).
- **Rasio Kontras Tinggi**: Seluruh palet warna mematuhi standar kontras warna internasional (*WCAG AAA*) untuk memastikan keterbacaan di bawah terik matahari Makkah.
- **Multibahasa Daerah**: Mendukung Bahasa Indonesia, Bahasa Jawa, Bahasa Sunda, dan Bahasa Inggris untuk mempermudah jamaah dari berbagai daerah di tanah air.

---

## 🛡️ Keamanan & Privasi Data

- **Firebase App Check**: Menjaga backend dari akses tidak sah melalui pengujian keaslian perangkat via Google Play Integrity API.
- **Enkripsi Keystore Lokal**: Kredensial dan data sesi disimpan menggunakan enkripsi tingkat perangkat keras (*Android Keystore*).
- **Privasi Riwayat Medis**: Data telemetri detak jantung dan suhu hanya disiarkan kepada pendamping resmi dalam satu rombongan tertutup (*Private Room*).

---

## 👥 Tim Pengembang & Inovator

Proyek ini dikembangkan dengan dedikasi untuk memajukan pelayanan jamaah haji dan umrah Indonesia:

- **Ketua Tim / Lead Developer**: Fadli & Tim Pengembang HajiCare
- **Institusi**: Indonesia
- **Tahun Pengembangan**: 2026

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE). Seluruh kode sumber terbuka untuk kepentingan riset, inovasi akademik, dan pelayanan kemanusiaan.

<div align="center">

**HajiCare** — *Melayani dengan Hati, Menjaga Setiap Langkah Tamu Ilahi.*

</div>
