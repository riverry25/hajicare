# Laporan Audit Performa & Bottleneck Aplikasi HajiCare
**Tanggal Audit:** 14 Oktober 2026  
**Peran:** Principal Flutter Performance Engineer  
**Status Proyek:** Tahap 1 Selesai — Audit & Pemetaan Bottleneck Lengkap  

---

## Ringkasan Eksekutif (*Executive Summary*)

Audit performa menyeluruh telah dilakukan pada seluruh basis kode `lib/`, aset di `assets/`, serta konfigurasi dependensi dan build di `pubspec.yaml` dan `android/app/build.gradle.kts`.

| Area Evaluasi | Status / Tingkat Keparahan | Temuan Utama |
| :--- | :---: | :--- |
| **1. Unnecessary Rebuilds** | 🔴 **High** | `Obx` membungkus seluruh `Scaffold` dan `SingleChildScrollView` (1800+ baris) di dashboard admin, jamaah, dan pendamping. |
| **2. Scroll & List Performance** | 🔴 **High** | Penggunaan `ListView(children: ...)` statis/non-builder pada daftar notifikasi dan doa, menyebabkan instansiasi massal di memori. |
| **3. Image & Memory Leaks** | 🟠 **Medium** | Kebocoran `TextEditingController` tanpa `dispose()` di sheet kurs uang, serta seluruh `Image.asset` belum memakai `cacheWidth`/`cacheHeight`. |
| **4. Main Thread Blocking** | 🟠 **Medium** | `jsonDecode` payload Overpass OSM & GeoJSON rute serta pra-proses sekuens 48-frame BISINDO berjalan di UI thread. |
| **5. Expensive Rendering** | 🔴 **High** | `Opacity` widget berjalan setiap frame (60fps) di dalam `AnimatedBuilder` sparkline/ping dot (`saveLayer` overhead), serta `IntrinsicHeight` di setiap item list notifikasi. |
| **6. App Size & Dependencies** | 🟡 **Medium** | Total aset mencapai 49.5 MB (TFLite 9.8MB, audio adzan 9.4MB, video sign language 20MB); dependensi ganda `dio` + `http`. |

---

## 1. Unnecessary Rebuilds (Scope State Terlalu Luas & Monolithic Widgets)

### 1.1 `Obx` Membungkus Seluruh `Scaffold` & `SingleChildScrollView`
- **File:** [`lib/features/room/screens/admin_dashboard_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/room/screens/admin_dashboard_screen.dart#L53)  
  - **Baris 53:** `child: Obx(() { return Scaffold(...); })`  
  - **Baris 69 & 256:** Terdapat nested `Obx` di `bottomNavigationBar` dan `body`.  
  - **Dampak:** Setiap perubahan indeks tab atau status room menyebabkan *full-screen rebuild* dari seluruh `Scaffold` beserta seluruh widget anaknya.  
  - **Rekomendasi:** Pindahkan `Obx` hanya membungkus `IndexedStack` dan widget yang secara spesifik membutuhkan nilai `currentIndex`.

- **File:** [`lib/features/dashboard/screens/dashboard_jamaah_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/dashboard/screens/dashboard_jamaah_screen.dart#L117)  
  - **Baris 117:** `child: Obx(() { final jamaah = state.self; return SingleChildScrollView(...); })`  
  - **Dampak:** Setiap pembaruan data jamaah (koordinat GPS, baterai smartband, status room) merekonstruksi seluruh hierarki scroll view berukuran ratusan widget.  
  - **Rekomendasi:** Letakkan `Obx` granular di kartu/teks individual yang membutuhkan nilai `state.self`.

- **File:** [`lib/features/dashboard/screens/dashboard_pendamping_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/dashboard/screens/dashboard_pendamping_screen.dart#L124)  
  - **Baris 124:** `child: Obx(() => SingleChildScrollView(... child: Column(children: [_hero(...), _body(...)])))`  
  - **Dampak:** File sebesar 1872 baris ini dibungkus dalam satu `Obx` raksasa. Reaktivitas GetX memicu *tree rebuilding* dari hero section hingga daftar jamaah.  
  - **Rekomendasi:** Hapus `Obx` pembungkus scroll view dan andalkan `Obx` lokal yang sudah tersedia di sub-widgetnya.

### 1.2 Widget Raksasa Monolitik (>1000 Baris) dengan Inline Helper Methods
Fungsi pembantu privat (`Widget _buildCard()`, `Widget _buildRow()`) tidak memiliki batasan elemen (*element boundary*). Ketika parent rebuild, seluruh fungsi ini dijalankan ulang dan mengalokasikan objek baru di memory/GC:
- [`lib/features/room/screens/room_detail_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/room/screens/room_detail_screen.dart) (4011 baris)
- [`lib/features/dashboard/screens/dashboard_jamaah_sections.dart`](file:///c:/fadli/project/hajicare/lib/features/dashboard/screens/dashboard_jamaah_sections.dart) (2883 baris)
- [`lib/features/money/screens/money_recognition_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/money/screens/money_recognition_screen.dart) (2706 baris)
- [`lib/features/prayer/screens/prayer_times_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/prayer/screens/prayer_times_screen.dart) (2130 baris)
- [`lib/features/sign_language/screens/sign_language_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/sign_language/screens/sign_language_screen.dart) (1973 baris)

---

## 2. Scroll & List Performance (Virtualisasi Viewport & Slivers)

### 2.1 Eager-Rendered `ListView(children: [...])` untuk Data Dinamis
Penggunaan konstruktor bawaan `ListView(children: ...)` memaksa Flutter menginstansiasi dan me-layout seluruh item sekaligus, terlepas dari apakah item tersebut terlihat di layar atau tidak:

- **File:** [`lib/features/notification/screens/notification_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/notification/screens/notification_screen.dart#L343)  
  - **Baris 343:** `return ListView(children: [...invitations.map(...), ...realNotifs.map(...)])`  
  - **Dampak:** Jika pengguna memiliki 50+ notifikasi, 50 kartu notifikasi beserta aset, format tanggal, dan listener dibuat di memori secara serentak.  
  - **Solusi:** Migrasi ke `ListView.builder` atau `CustomScrollView` dengan `SliverList.separated`.

- **File:** [`lib/features/hajj_dua/presentation/screens/hajj_dua_category_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/hajj_dua/presentation/screens/hajj_dua_category_screen.dart#L169)  
  - **Baris 169 & 241:** `ListView(children: [..., ...filteredDuas.map((dua) => DuaCard(...))])`  
  - **Dampak:** Setiap doa memiliki teks Arab kompleks, transliterasi, terjemahan, dan audio player controller yang diinstansiasi secara *eager*.  
  - **Solusi:** Ganti menjadi `CustomScrollView` dengan `SliverToBoxAdapter` untuk panduan dan `SliverList.builder` untuk doa.

- **File:** [`lib/features/hajj_dua/presentation/screens/hajj_dua_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/hajj_dua/presentation/screens/hajj_dua_screen.dart#L177)  
  - **Baris 177:** `ListView(children: [...])` merender seluruh kategori dan hasil pencarian sekaligus.

### 2.2 `SingleChildScrollView` + `Column` pada Data Dinamis
- **File:** [`lib/features/room/widgets/jamaah_detail_sheet.dart`](file:///c:/fadli/project/hajicare/lib/features/room/widgets/jamaah_detail_sheet.dart#L479) (Baris 479 & 1063)
- **File:** [`lib/features/room/screens/admin_room_management_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/room/screens/admin_room_management_screen.dart#L610) (Baris 610, 751, 1004)

---

## 3. Image & Memory Leaks (Dispose Lifecycle & Cache Bounds)

### 3.1 Memory Leak: Undisposed Controller
- **File:** [`lib/features/money/screens/money_recognition_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/money/screens/money_recognition_screen.dart#L2143)  
  - **Baris 2143:** `final TextEditingController rateController = TextEditingController(...);` diinstansiasi di dalam `_showExchangeRateSheet()` tanpa memanggil `.dispose()` pada penutupan bottom sheet (`.whenComplete(...)` tidak dipasang).  
  - **Dampak:** Setiap kali pengguna membuka dialog ubah kurs uang, controller baru tertinggal di memori.  
  - **Perbaikan:** Tambahkan `.whenComplete(rateController.dispose)` pada pemanggilan `showModalBottomSheet`.

### 3.2 Dekode Gambar Tanpa `cacheWidth` / `cacheHeight`
Flutter secara default mendekode resolusi asli file gambar ke memori bitmap (RGBA, 4 byte per piksel). Menampilkan gambar 1024x1024 pada kotak 36x36 tanpa `cacheWidth` menghabiskan ~4.1 MB RAM yang seharusnya hanya membutuhkan ~10 KB:
- **File:** [`lib/core/widgets/hajicare_header.dart`](file:///c:/fadli/project/hajicare/lib/core/widgets/hajicare_header.dart#L133)  
  - `Image.asset(imageAsset ?? 'assets/icon.jpeg', width: 36, height: 36)` ➔ Harus diberi `cacheWidth: 72, cacheHeight: 72`.
- **File:** [`lib/features/auth/screens/login_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/auth/screens/login_screen.dart#L238)  
  - Baris 238 & 295: `Image.asset` tanpa batas cache.
- **File:** [`lib/features/onboarding/screens/onboarding_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/onboarding/screens/onboarding_screen.dart#L58)
- **File:** [`lib/features/profile/screens/about_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/profile/screens/about_screen.dart#L157)  
  - Baris 157 & 449: `Image.asset` logo dan sponsor.
- **File:** [`lib/features/room/screens/admin_dashboard_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/room/screens/admin_dashboard_screen.dart#L133)

*(Catatan Positif: `map_top_header.dart:521` dan `sos_companion_scanning_screen.dart:1348` sudah benar menerapkan `cacheWidth: 120/140`)*.

---

## 4. Main Thread Blocking (UI Jank & Operasi Berat)

### 4.1 Parsing JSON Berat di UI Thread (Main Isolate)
- **File:** [`lib/features/map/services/poi_service.dart`](file:///c:/fadli/project/hajicare/lib/features/map/services/poi_service.dart#L85)  
  - **Baris 85:** `final json = jsonDecode(response.body);`  
  - Respon API Overpass OpenStreetMap (hotel, masjid, posko) berisi ratusan node geospasial (ratusan KB hingga beberapa MB). Eksekusi `jsonDecode` sinkron memblokir rendering UI selama puluhan milidetik.  
  - **Solusi:** Gunakan `Isolate.run(() => jsonDecode(response.body))` atau `compute()`.

- **File:** [`lib/features/map/services/route_service.dart`](file:///c:/fadli/project/hajicare/lib/features/map/services/route_service.dart#L97)  
  - **Baris 97 & 214:** Parsing rute OSRM/ORS GeoJSON polylines yang panjang berjalan di thread utama.

- **File:** [`lib/features/sign_language/services/sign_language_repository.dart`](file:///c:/fadli/project/hajicare/lib/features/sign_language/services/sign_language_repository.dart#L149)  
  - **Baris 149 & 168:** Parsing katalog kamus isyarat dan paket offline di UI thread.

### 4.2 Pra-Pemrosesan Matriks 48-Frame BISINDO di UI Thread
- **File:** [`lib/features/sign_language/services/bisindo_inference_service.dart`](file:///c:/fadli/project/hajicare/lib/features/sign_language/services/bisindo_inference_service.dart#L306)  
  - **Baris 306-325:** Fungsi `_predictSequence` melakukan normalisasi landmark 543 titik x 48 frame (`BisindoPreprocessor.processFrame`) secara sinkron setiap kali stream kamera mengirimkan pose baru.  
  - **Solusi:** Pindahkan kalkulasi matriks frame ke background isolate menggunakan `compute()`.

---

## 5. Expensive Rendering (GPU Layer Offscreen & Double Layout Pass)

### 5.1 `Opacity` Widget Berjalan Setiap Tick Animasi (60fps Stutter)
Widget `Opacity` memaksa compositing layer terpisah (`saveLayer`) yang mahal di GPU. Ketika digunakan di dalam `AnimatedBuilder`, Flutter mengalokasikan dan me-render buffer offscreen 60 kali per detik:

- **File:** [`lib/features/dashboard/widgets/distance_sparkline_widget.dart`](file:///c:/fadli/project/hajicare/lib/features/dashboard/widgets/distance_sparkline_widget.dart#L121)  
  - **Baris 121:**  
    ```dart
    return Opacity(
      opacity: opacity,
      child: CustomPaint(painter: _DistanceWavePainter(...)),
    );
    ```  
  - **Solusi:** Hapus widget `Opacity`. Teruskan `opacity` langsung ke `_DistanceWavePainter` dan terapkan pada warna kuas: `waveColor.withValues(alpha: waveColor.a * opacity)`.

- **File:** [`lib/features/dashboard/widgets/mini_sparkline_button.dart`](file:///c:/fadli/project/hajicare/lib/features/dashboard/widgets/mini_sparkline_button.dart#L144)  
  - **Baris 144:** Penggunaan identik di dalam `AnimatedBuilder` 60fps.  
  - **Solusi:** Hapus `Opacity` dan atur alpha langsung pada `_SparklineWavePainter`.

- **File:** [`lib/core/widgets/animated_ping_dot.dart`](file:///c:/fadli/project/hajicare/lib/core/widgets/animated_ping_dot.dart#L64)  
  - **Baris 64:** `Opacity` pada animasi pulsing ping dot. Dapat digantikan dengan `effectiveColor.withValues(alpha: effectiveColor.a * _opacityAnimation.value)`.

### 5.2 `IntrinsicHeight` Memaksa Pengukuran Dua Kali (*Double Layout Pass*)
`IntrinsicHeight` memicu algoritma layout spekulatif $O(N^2)$:
- **File:** [`lib/features/notification/screens/notification_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/notification/screens/notification_screen.dart#L796)  
  - **Baris 796:** Digunakan di setiap kartu notifikasi hanya untuk membuat bar penanda belum dibaca (5px) membentang secara vertikal.  
  - **Solusi:** Ganti dengan `Border(left: BorderSide(...))` pada dekorasi `Container` atau `Stack` dengan `Positioned(top: 0, bottom: 0, left: 0)`.
- **File:** [`lib/core/utils/app_dialog.dart`](file:///c:/fadli/project/hajicare/lib/core/utils/app_dialog.dart#L293)
- **File:** [`lib/features/room/widgets/active_room_card.dart`](file:///c:/fadli/project/hajicare/lib/features/room/widgets/active_room_card.dart#L718)
- **File:** [`lib/features/sos/screens/sos_alert_detail_screen.dart`](file:///c:/fadli/project/hajicare/lib/features/sos/screens/sos_alert_detail_screen.dart#L935)
- **File:** [`lib/features/dashboard/widgets/hajj_schedule_guide_sheet.dart`](file:///c:/fadli/project/hajicare/lib/features/dashboard/widgets/hajj_schedule_guide_sheet.dart#L797)

---

## 6. App Size & Dependencies (Ukuran Unduhan & Konfigurasi Rilis)

### 6.1 Distribusi Berat Aset (Total 49.5 MB)
1. `assets/models/money_recognition.tflite` — **9.86 MB**  
   - Model float32 unquantized. Dengan post-training quantization FP16 atau INT8, ukurannya dapat dipangkas menjadi ~2.5 - 4.9 MB.
2. `assets/audio/adzan_subuh.mp3` (**5.59 MB**) & `adzan_regular.mp3` (**3.84 MB**) — **Total 9.43 MB**  
   - Bitrate audio MP3 sangat tinggi (320kbps). Mengonversi ke AAC/M4A 64kbps atau Opus dapat menghemat ~7.5 MB tanpa penurunan kualitas suara vokal.
3. `assets/sign_language/offline/` — **20.2 MB**  
   - Terdiri dari 23 video klip `.mp4` kamus bahasa isyarat. Sebaiknya dijadikan paket unduhan *on-demand* (*Dynamic Feature Delivery* atau download saat pertama dibuka).

### 6.2 Dependensi Duplikat
- Proyek menyertakan **`dio: ^5.7.0`** (hanya dipakai di 2 file bahasa isyarat) dan **`http: ^1.6.0`** (dipakai di 4 file map/geocoding/currency).  
- **Rekomendasi:** Standarisasi ke salah satu client (misal: Dio dengan interceptor atau standard `http`) untuk mengurangi footprint binary engine.

### 6.3 Konfigurasi Build Android
- `android/app/build.gradle.kts` sudah mengaktifkan `isMinifyEnabled = true` dan `isShrinkResources = true` (R8 optimal).
- Proyek mengonfigurasi 3 ABI (`arm64-v8a`, `armeabi-v7a`, `x86_64`). Membangun APK tunggal standar menghasilkan file gemuk (>80 MB) karena menggabungkan pustaka C++ OpenCV, YOLO, dan TFLite untuk ketiga arsitektur.
- **Rekomendasi Rilis:** Wajib menggunakan `flutter build appbundle` (AAB) atau `flutter build apk --split-per-abi` untuk memotong ukuran unduhan pengguna hingga ~60% (~25-30 MB per perangkat).

---

## Rencana Eksekusi Bertahap (Tahap 2)

### Batch 1: High Impact & Low Risk (Target Eksekusi Pertama)
1. **Perbaikan Memory Leak:** Pasang `.whenComplete(rateController.dispose)` di `money_recognition_screen.dart`.
2. **Eliminasi GPU `saveLayer` Overhead:** Hapus widget `Opacity` di `distance_sparkline_widget.dart` dan `mini_sparkline_button.dart`, ganti dengan direct alpha blending di CustomPainter.
3. **Optimasi Image Decoding:** Berikan `cacheWidth` dan `cacheHeight` pada seluruh pemanggilan `Image.asset` (`hajicare_header.dart`, `login_screen.dart`, dll).
4. **Penyempitan Scope Rebuild:** Koreksi `Obx` di `admin_dashboard_screen.dart` agar hanya membungkus `IndexedStack` dan bukan seluruh `Scaffold`.
5. **Verifikasi:** Jalankan `flutter analyze` dan tes unit/widget untuk memastikan zero regression.

### Batch 2: Medium Impact & Low/Medium Risk
1. **Virtualisasi Notifikasi & Doa:** Ubah `ListView` non-builder di `notification_screen.dart` dan `hajj_dua_category_screen.dart` menjadi builder/sliver.
2. **Penghapusan `IntrinsicHeight`:** Ganti penanda aksen bar di `notification_screen.dart` menggunakan `Border` dekorasi tanpa double layout pass.

### Batch 3: High Impact & Architectural (Memerlukan Konfirmasi)
1. Pemindahan parsing Overpass & rute ke `Isolate.run()`.
2. Pemisahan aset video offline sign language ke download cache on-demand.

---

## Log Eksekusi & Hasil Pengujian

### Status Batch 1 (High Impact & Low Risk) — SELESAI ✅
- [x] Memory leak controller dibersihkan via `.whenComplete(rateController.dispose)`.
- [x] Overhead `saveLayer` GPU dihilangkan pada sparkline dan ping dot dengan modulasi alpha langsung pada `CustomPainter` dan `BoxDecoration`.
- [x] Resolusi decode `Image.asset` dibatasi dengan `cacheWidth` dan `cacheHeight` di seluruh aplikasi.
- [x] Scope rebuild `Obx` dipersempit pada admin dashboard (hanya membungkus `IndexedStack`).
- **Verifikasi:** `flutter analyze` 0 issues, 37 test lolos.

### Status Batch 2 (Virtualisasi & Layout Refactor) — SELESAI ✅
- [x] `notification_screen.dart`: `IntrinsicHeight` dihilangkan sepenuhnya menggunakan `Stack` terklip yang mempertahankan ketebalan bar 5px, border-radius, dan padding identik 100%.
- [x] `notification_screen.dart`: `ListView` statis diganti dengan `CustomScrollView` dan `SliverList.builder` dengan lazy instantiation dan `RepaintBoundary`.
- [x] `hajj_dua_category_screen.dart`: Eager `.map(...)` diganti dengan `CustomScrollView` + `SliverList.builder` dengan lazy rendering dan `RepaintBoundary` pada `DuaCard`.
- **Verifikasi:** `flutter analyze` 0 issues, 23 test doa & notifikasi lolos.

### Status Batch 3 (Main Thread Offloading / Isolate) — SELESAI ✅
- [x] `poi_service.dart`: Parsing payload Overpass OSM dan sorting geospasial dipindahkan ke background thread dengan `Isolate.run()`.
- [x] `route_service.dart`: Parsing GeoJSON ORS & OSRM dipindahkan ke background thread dengan `Isolate.run()`.
- **Verifikasi:** `flutter analyze` 0 issues, 17 test rute & POI lolos, 16 test navigasi & map lolos.
