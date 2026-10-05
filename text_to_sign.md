Saya sedang mengembangkan project Flutter HajiCare di:

C:\fadli\project\hajicare

HajiCare adalah aplikasi aksesibilitas untuk jamaah haji/umrah, terutama lansia dan penyandang disabilitas.

Project HajiCare SUDAH berjalan dan menggunakan:

* Flutter
* GetX
* Firebase utama
* struktur folder/project existing
* theme/accessibility system existing

TUGAS UTAMA:

Implementasikan fitur TEXT-TO-SIGN LANGUAGE secara nyata di project HajiCare dengan arsitektur HYBRID:

1. Sebagian video berasal dari Flutter bundled assets dan harus tersedia secara offline sejak aplikasi terinstall.
2. Sebagian video berasal dari Firebase Hosting project terpisah.
3. Video remote harus didownload ke persistent local storage sebelum diputar.
4. Setelah berhasil didownload, video remote harus dapat diputar tanpa internet.
5. Metadata remote menggunakan static JSON:
   https://hajicare-sign.web.app/index.json
6. Jangan menggunakan Firebase Cloud Storage.
7. Jangan membuat Firebase.initializeApp() kedua.
8. Jangan membuat Firebase project sign-language kedua di dalam FlutterFire.
9. Firebase sign-language hanya digunakan sebagai static file hosting.
10. Jangan mengubah konfigurasi Firebase utama HajiCare kecuali benar-benar diperlukan.
11. Gunakan GetX existing HajiCare.
12. Jangan merombak arsitektur HajiCare yang sudah ada.

==================================================
A. STRUKTUR ASSET OFFLINE YANG SUDAH ADA
========================================

JANGAN membuat path asset baru jika tidak diperlukan.

Gunakan path existing berikut:

1. BISINDO alfabet J:

C:\fadli\project\hajicare\assets\sign_language\offline\bisindo\alfabet\J.mp4

2. BISINDO alfabet L:

C:\fadli\project\hajicare\assets\sign_language\offline\bisindo\alfabet\L.mp4

3. SIBI kalimat Masjid:

C:\fadli\project\hajicare\assets\sign_language\offline\sibi\kalimat\masjid.mp4

4. SIBI kalimat Bantu:

C:\fadli\project\hajicare\assets\sign_language\offline\sibi\kalimat\bantu.mp4

Gunakan asset tersebut sebagai OFFLINE SOURCE.

Mapping minimal:

BISINDO:

* J → assets/sign_language/offline/bisindo/alfabet/J.mp4
* L → assets/sign_language/offline/bisindo/alfabet/L.mp4

SIBI:

* Masjid → assets/sign_language/offline/sibi/kalimat/masjid.mp4
* Bantu → assets/sign_language/offline/sibi/kalimat/bantu.mp4

Jangan meminta internet untuk bundled asset.

==================================================
B. STRUKTUR FIREBASE HOSTING YANG SUDAH ADA
===========================================

Firebase Hosting project terpisah berada di:

C:\fadli\hajicare-sign

Public directory:

C:\fadli\hajicare-sign\public

Video remote yang SUDAH ADA:

1. BISINDO:
   C:\fadli\hajicare-sign\public\videos\bisindo\l_v1.mp4

2. BISINDO:
   C:\fadli\hajicare-sign\public\videos\bisindo\j_v1.mp4

3. SIBI:
   C:\fadli\hajicare-sign\public\videos\sibi\dokter_v1.mp4

4. SIBI:
   C:\fadli\hajicare-sign\public\videos\sibi\obat_v1.mp4

URL base:

https://hajicare-sign.web.app

Catalog:

https://hajicare-sign.web.app/index.json

Contoh URL:

https://hajicare-sign.web.app/videos/sibi/dokter_v1.mp4

https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4

https://hajicare-sign.web.app/videos/bisindo/l_v1.mp4

https://hajicare-sign.web.app/videos/bisindo/j_v1.mp4

Jangan hardcode URL video di banyak file.

Buat satu configuration:

SignLanguageConfig.baseUrl

value:

https://hajicare-sign.web.app

==================================================
C. ATURAN SOURCE VIDEO
======================

Setiap SignVideoEntry harus dapat mempunyai source:

* asset
* remote
* local_cached

Konsep:

asset:
→ video berasal dari Flutter assets
→ langsung bisa diputar offline

remote:
→ video berada di Firebase Hosting
→ belum tersedia lokal
→ harus didownload

local_cached:
→ sebelumnya berasal dari remote
→ sudah tersimpan di HP
→ putar menggunakan local file
→ tidak perlu internet

Prioritas source:

1. asset
2. local_cached
3. remote download
4. unavailable

Jangan menggunakan network video sebagai playback utama.

==================================================
D. PUBSPEC.YAML
===============

Audit pubspec.yaml terlebih dahulu.

Jika dependency belum ada, gunakan:

* video_player
* dio
* path_provider

Jangan menambahkan dependency lain tanpa alasan teknis yang jelas.

Tambahkan konfigurasi assets untuk:

assets/sign_language/offline/

atau konfigurasi yang paling aman berdasarkan struktur pubspec existing.

Pastikan file-file berikut dikenali Flutter:

assets/sign_language/offline/bisindo/alfabet/J.mp4
assets/sign_language/offline/bisindo/alfabet/L.mp4
assets/sign_language/offline/sibi/kalimat/masjid.mp4
assets/sign_language/offline/sibi/kalimat/bantu.mp4

Jangan menghapus asset configuration existing.

==================================================
E. MODEL DATA
=============

Buat model type-safe, misalnya:

SignVideoEntry

Minimal field:

* id
* language
* type
* label
* aliases
* category
* version
* path
* source

Source dapat berupa:

asset
remote
local_cached

Pertahankan model sederhana dan jangan membuat abstraction berlebihan.

Contoh remote catalog:

{
"id": "sibi_dokter",
"language": "sibi",
"type": "word",
"label": "Dokter",
"aliases": ["dokter"],
"category": "health",
"version": 1,
"path": "videos/sibi/dokter_v1.mp4"
}

==================================================
F. LOCAL ASSET REGISTRY
=======================

Buat registry lokal untuk bundled assets.

Minimal data berikut harus diregistrasikan:

BISINDO J:
id = bisindo_alphabet_j
language = bisindo
type = alphabet
label = J
aliases = ["j"]
category = alphabet
version = 1
source = asset
assetPath = assets/sign_language/offline/bisindo/alfabet/J.mp4

BISINDO L:
id = bisindo_alphabet_l
language = bisindo
type = alphabet
label = L
aliases = ["l"]
category = alphabet
version = 1
source = asset
assetPath = assets/sign_language/offline/bisindo/alfabet/L.mp4

SIBI Masjid:
id = sibi_sentence_masjid
language = sibi
type = phrase
label = Masjid
aliases = ["masjid"]
category = hajj
version = 1
source = asset
assetPath = assets/sign_language/offline/sibi/kalimat/masjid.mp4

SIBI Bantu:
id = sibi_sentence_bantu
language = sibi
type = phrase
label = Bantu
aliases = ["bantu", "tolong bantu"]
category = emergency
version = 1
source = asset
assetPath = assets/sign_language/offline/sibi/kalimat/bantu.mp4

Jangan meminta aplikasi membaca filesystem assets secara dinamis saat runtime untuk menentukan daftar asset.
Buat registry Dart/static catalog agar lookup konsisten.

==================================================
G. REMOTE CATALOG
=================

Remote catalog harus dibaca dari:

https://hajicare-sign.web.app/index.json

Saat online:

1. GET index.json
2. timeout dengan jelas
3. validasi JSON
4. parse menjadi model
5. simpan copy catalog ke persistent application support directory
6. gunakan catalog tersebut untuk lookup berikutnya

Saat offline:

1. jangan memanggil index.json terus-menerus
2. gunakan catalog lokal
3. jika catalog lokal ada, lanjutkan operasi normal
4. jika catalog belum pernah tersedia dan video juga tidak ada sebagai asset, tampilkan status yang ramah

Catalog harus dicache.

Jangan request index.json setiap kali user membuka satu video.

==================================================
H. PERSISTENT LOCAL STORAGE
===========================

Gunakan:

path_provider

Gunakan application support directory:

getApplicationSupportDirectory()

Jangan gunakan getTemporaryDirectory() sebagai tempat utama penyimpanan video.

Target struktur:

Application Support/
└── sign_language/
├── catalog.json
└── videos/
├── sibi/
│   ├── sibi_dokter_v1.mp4
│   └── sibi_obat_v1.mp4
│
└── bisindo/
├── bisindo_j_v1.mp4
└── bisindo_l_v1.mp4

Bundled assets tidak perlu disalin ke cache.

==================================================
I. CACHE IDENTITY
=================

Gunakan kombinasi ID + version.

Contoh:

sibi_dokter_v1.mp4

sibi_obat_v1.mp4

bisindo_j_v1.mp4

bisindo_l_v1.mp4

Jangan menggunakan hanya label sebagai nama cache jika dapat menyebabkan collision.

Jika remote entry berubah:

version 1 → version 2

maka file lokal version 2 harus dianggap sebagai file baru.

Jangan secara diam-diam menggunakan version lama sebagai version baru.

==================================================
J. DOWNLOAD FLOW
================

Saat user meminta remote video:

1. Cari SignVideoEntry.
2. Pastikan source remote.
3. Cek apakah local cached version sudah ada.
4. Jika ada:
   → gunakan file lokal.
5. Jika belum:
   → download dengan Dio.
6. Tampilkan progress.
7. Simpan ke application support directory.
8. Setelah download sukses:
   → cek file exists.
9. Buat VideoPlayerController.file().
10. Inisialisasi.
11. Play.

Jika download gagal:
→ jangan crash
→ tampilkan error yang mudah dimengerti.

Contoh:

"Video belum berhasil diunduh. Periksa koneksi internet dan coba lagi."

Jika offline:

"Video belum tersedia offline. Silakan download saat internet tersedia."

==================================================
K. VIDEO PLAYER
===============

Gunakan video_player.

Asset:
VideoPlayerController.asset(assetPath)

Local cached:
VideoPlayerController.file(File(localPath))

Jangan gunakan network video sebagai source utama.

==================================================
L. TEXT-TO-SIGN SEARCH
======================

Buat service/repository khusus untuk pencarian.

Urutan:

1. Exact phrase
2. Phrase alias
3. Exact word
4. Word alias
5. unmatched

Normalisasi text:

* lowercase
* trim
* normalisasi whitespace
* handle tanda baca dasar

Contoh:

Input:
"Saya sakit"

Harus dapat dicoba dengan:

1. exact phrase "saya sakit"
2. phrase alias
3. jika tidak ditemukan → tokenisasi menjadi candidate words

Tetapi jangan menganggap bahwa semua kalimat Bahasa Indonesia dapat diterjemahkan secara sempurna kata-per-kata.

Gunakan phrase mapping untuk kalimat-kalimat penting HajiCare.

==================================================
M. PHRASE KHUSUS HAJICARE
=========================

Sediakan struktur yang memungkinkan phrase entry:

* Tolong bantu saya
* Saya sakit
* Saya pusing
* Saya butuh dokter
* Saya tersesat
* Saya kehilangan pendamping
* Di mana rumah sakit?
* Di mana toilet?
* Saya ingin berwudhu

Tidak semua phrase tersebut harus langsung mempunyai video.
Buat arsitektur agar nanti mudah ditambahkan dari catalog.

==================================================
N. BAHASA
=========

Sediakan:

SIBI
BISINDO

Filtering WAJIB berdasarkan language.

Jangan mencampur entry SIBI dan BISINDO.

Contoh:

selectedLanguage = SIBI

maka:

bisindo_j
bisindo_l

tidak boleh muncul dalam hasil pencarian.

==================================================
O. GETX
=======

HajiCare sudah menggunakan GetX.

Gunakan:

* GetxController
* Rx
* Obx
* GetX navigation/pattern existing

Jangan memperkenalkan:

* Provider
* BLoC
* Riverpod

hanya untuk fitur ini.

Audit controller existing terlebih dahulu agar tidak membuat controller duplicate.

==================================================
P. STRUKTUR KODE
================

Audit project sebelum membuat file.

Ikuti folder structure existing HajiCare.

Secara konseptual boleh dibuat:

* sign_language_model.dart
* sign_language_repository.dart
* sign_language_cache_service.dart
* sign_language_asset_registry.dart
* sign_language_controller.dart
* text_to_sign_screen.dart
* sign_video_player.dart

Tetapi sesuaikan dengan folder architecture existing.

Jangan membuat duplicate service/controller jika yang setara sudah ada.

==================================================
Q. UI TEXT-TO-SIGN
==================

Buat UI accessible mengikuti UI system existing HajiCare.

Gunakan:

* AppColors existing
* theme existing
* dark mode existing
* text size setting existing
* spacing existing
* typography existing

Requirements:

* tombol besar
* text mudah dibaca
* tidak overflow
* responsive
* accessible
* jangan menggunakan design system baru

Minimal:

TEXT-TO-SIGN

[ Bahasa: SIBI ▼ ]

[ Masukkan teks ]

[ Terjemahkan ]

Hasil:

[ VIDEO ]

[ Play / Pause ]

progress bar

status:

"Offline tersedia"

atau:

"Video perlu diunduh"

Jika remote:
[ Download ]

Setelah download sukses:
[ Play ]

==================================================
R. SOURCE RESOLUTION
====================

Buat satu resolver:

resolveVideoSource(entry)

Aturan:

source = asset
→ asset

source = remote:
→ cek local cache
→ jika ada → local_cached
→ jika tidak → remote download

Jangan menyebarkan logic tersebut ke widget UI.

UI hanya meminta repository/controller:

getVideo(...)
downloadVideo(...)

==================================================
S. DOWNLOAD PACKAGE
===================

Sediakan kemampuan download category.

Contoh:

* emergency
* hajj
* health
* alphabet

Namun:

BUNDLED OFFLINE ASSETS TIDAK BOLEH DIHAPUS.

Download package hanya berlaku untuk remote videos.

Contoh UI:

Download Paket Haji

[ Download ]

Download Paket Darurat

[ Download ]

Tampilkan:

* jumlah video
* progress
* berhasil
* gagal

Jika satu video gagal, jangan menggagalkan seluruh aplikasi.

==================================================
T. CACHE MANAGEMENT
===================

Tambahkan fungsi:

refreshCatalog()
getCachedCatalog()
getVideo()
downloadVideo()
isVideoDownloaded()
deleteDownloadedVideo()
clearDownloadedVideos()
downloadCategory()

Jangan pernah menghapus bundled assets.

clearDownloadedVideos() hanya menghapus file remote yang disimpan lokal.

==================================================
U. OFFLINE BEHAVIOR
===================

HARUS bekerja dalam kondisi:

1. Internet ON
2. Internet OFF
3. Firebase Hosting tidak dapat diakses
4. Remote video sudah pernah didownload
5. Remote video belum pernah didownload
6. Bundled asset tersedia
7. Catalog remote pernah disimpan lokal
8. Catalog remote belum pernah tersedia

Behavior:

Internet ON + asset:
→ play asset
→ jangan request internet

Internet OFF + asset:
→ play asset

Internet ON + remote + belum cache:
→ download
→ cache
→ play local

Internet ON + remote + sudah cache:
→ play local
→ jangan download ulang

Internet OFF + remote + sudah cache:
→ play local

Internet OFF + remote + belum cache:
→ "Video belum tersedia offline"

==================================================
V. NETWORK HANDLING
===================

Jangan hanya bergantung pada ConnectivityResult.

Internet availability harus diverifikasi melalui request nyata.

Gunakan:

* timeout
* Dio exception handling
* graceful error state

Jangan melakukan request berulang tanpa batas.

==================================================
W. CATALOG VERSIONING
=====================

Gunakan:

catalogVersion

dan:

video version

Contoh:

catalogVersion:
1.0.0

video:
version = 1

Jika catalog update:

1.1.0

dan video version:

2

maka aplikasi harus memahami bahwa video baru tersedia.

Jangan mendownload seluruh catalog video hanya karena catalog berubah.

Catalog hanya metadata.

Video didownload on-demand atau melalui download package.

==================================================
X. FIREBASE RESTRICTION
=======================

SANGAT PENTING:

Jangan:

* menambahkan Firebase project kedua ke FlutterFire
* memanggil Firebase.initializeApp() kedua
* menggunakan Firebase Storage
* menggunakan Cloud Functions
* menggunakan Cloud Run
* menggunakan Firestore untuk catalog sign-language
* membuat API backend baru

Sign-language backend hanya:

Firebase Hosting
+
static index.json
+
static video files

Flutter mengaksesnya menggunakan HTTPS.

==================================================
Y. SECURITY
===========

Tidak ada API key/secret untuk static hosting.

Jangan menyimpan:

* UID
* email
* data user
* data room
* data pendamping
* data jamaah

di sign-language hosting.

Sign-language hosting hanya menyimpan public assets dan metadata yang diperlukan untuk text-to-sign.

==================================================
Z. PERFORMANCE
==============

Optimalkan agar cocok untuk HP Android kelas menengah.

Jangan:

* download semua video otomatis ketika aplikasi dibuka
* preload semua video
* initialize banyak video player bersamaan
* request index.json berulang-ulang
* membuat widget terlalu berat

Load satu video sesuai kebutuhan.

Dispose VideoPlayerController dengan benar.

==================================================
AA. KONDISI DATA SAAT INI
=========================

Remote videos yang harus bisa dikenali:

BISINDO:

* J
  URL:
  https://hajicare-sign.web.app/videos/bisindo/j_v1.mp4

* L
  URL:
  https://hajicare-sign.web.app/videos/bisindo/l_v1.mp4

SIBI:

* Dokter
  URL:
  https://hajicare-sign.web.app/videos/sibi/dokter_v1.mp4

* Obat
  URL:
  https://hajicare-sign.web.app/videos/sibi/obat_v1.mp4

Offline assets:

BISINDO:

* J:
  assets/sign_language/offline/bisindo/alfabet/J.mp4

* L:
  assets/sign_language/offline/bisindo/alfabet/L.mp4

SIBI:

* Masjid:
  assets/sign_language/offline/sibi/kalimat/masjid.mp4

* Bantu:
  assets/sign_language/offline/sibi/kalimat/bantu.mp4

PERHATIAN:

Ada BISINDO J dan L yang tersedia dalam dua bentuk:

1. bundled offline asset
2. remote hosting

Jangan menganggap remote J/L harus didownload jika bundled asset sudah tersedia.

Untuk entry yang mempunyai bundled asset dan remote version, priority offline asset adalah:

asset → local cached remote → remote

Namun registry harus tetap dapat mengetahui bahwa remote version juga tersedia untuk sinkronisasi/pengembangan berikutnya.

==================================================
AB. INITIAL CATALOG EXPECTATION
===============================

Pastikan kode mendukung entry seperti:

{
"schemaVersion": 1,
"catalogVersion": "1.0.0",
"updatedAt": "2026-10-05",
"videos": [
{
"id": "sibi_dokter",
"language": "sibi",
"type": "word",
"label": "Dokter",
"aliases": ["dokter"],
"category": "health",
"version": 1,
"path": "videos/sibi/dokter_v1.mp4"
},
{
"id": "sibi_obat",
"language": "sibi",
"type": "word",
"label": "Obat",
"aliases": ["obat"],
"category": "health",
"version": 1,
"path": "videos/sibi/obat_v1.mp4"
},
{
"id": "bisindo_j",
"language": "bisindo",
"type": "alphabet",
"label": "J",
"aliases": ["j"],
"category": "alphabet",
"version": 1,
"path": "videos/bisindo/j_v1.mp4"
},
{
"id": "bisindo_l",
"language": "bisindo",
"type": "alphabet",
"label": "L",
"aliases": ["l"],
"category": "alphabet",
"version": 1,
"path": "videos/bisindo/l_v1.mp4"
}
]
}

Jangan menganggap field type hanya "word".

Support minimal:

* alphabet
* word
* phrase

==================================================
AC. FILE YANG HARUS DIPRIORITASKAN
==================================

Audit existing project dahulu.

Kemudian, bila memang belum tersedia, implementasikan komponen yang diperlukan seperti:

1. SignLanguageConfig
2. SignVideoEntry model
3. SignLanguageCatalog model
4. SignLanguageAssetRegistry
5. SignLanguageCacheService
6. SignLanguageRepository
7. SignLanguageController
8. TextToSignScreen
9. Video player widget/component

Tetapi nama file harus mengikuti pola project existing jika ada pola yang lebih sesuai.

==================================================
AD. JANGAN MEROMBAK EXISTING HAJICARE
=====================================

Jangan menghapus atau mengubah secara tidak perlu:

* Firebase authentication
* room system
* dashboard jamaah
* dashboard pendamping
* prayer system
* map system
* SOS
* profile
* localization
* theme
* bottom navigation
* controller existing

Jangan membuat migration besar.

Implementasi harus bersifat additive.

==================================================
AE. TESTING
===========

Setelah implementasi:

1. flutter pub get
2. flutter analyze
3. jalankan aplikasi Android
4. test SIBI Masjid offline
5. test SIBI Bantu offline
6. test BISINDO J offline
7. test BISINDO L offline
8. test SIBI Dokter remote
9. test SIBI Obat remote
10. download remote video
11. matikan internet
12. putar video remote yang sudah dicache
13. pastikan tidak download ulang
14. test remote video yang belum pernah didownload dalam kondisi offline
15. pastikan aplikasi tidak crash
16. test dark mode
17. test text size
18. test layar kecil
19. pastikan tidak ada overflow
20. test dispose VideoPlayerController

==================================================
AF. EXPECTED FINAL REPORT DARI ANTIGRAVITY
==========================================

Setelah implementasi selesai, jangan hanya mengatakan "done".

Berikan:

1. file yang dibuat
2. file existing yang diubah
3. dependency yang ditambahkan
4. perubahan pubspec.yaml
5. perubahan Android jika ada
6. cara kerja asset offline
7. cara kerja remote download
8. lokasi cache
9. cara kerja catalog
10. cara kerja text-to-sign
11. test yang berhasil
12. test yang gagal
13. error analyzer yang tersisa jika ada
14. manual step yang masih harus saya lakukan

Jika ada masalah atau asumsi, jelaskan sebelum melakukan perubahan berisiko.

Jangan melakukan perubahan Firebase Console atau Firebase Hosting secara otomatis.

Jangan mengubah project Firebase utama.

Jangan membuat project Firebase baru.

==================================================
TARGET AKHIR
============

Saya ingin hasil akhir seperti ini:

```
                     HAJICARE FLUTTER
                            │
         ┌──────────────────┴──────────────────┐
         │                                     │
         ▼                                     ▼
   Firebase utama                     HajiCare Sign Hosting
   hajicare-e6497                      hajicare-sign.web.app
         │                                     │
         │                              ┌──────┴──────┐
         │                              │             │
         │                         index.json      videos
         │
         └──────────────────┐
                            ▼
                   Text-to-Sign System
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
    Asset Offline       Local Cache         Remote
        │                   │                   │
        ▼                   ▼                   ▼
   play langsung       play langsung       download
                                                │
                                                ▼
                                           local cache
                                                │
                                                ▼
                                            play offline
```

Pastikan implementasi nyata, bukan sekadar mockup UI.
Gunakan arsitektur existing HajiCare sebanyak mungkin.
