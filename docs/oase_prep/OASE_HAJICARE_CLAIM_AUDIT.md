# OASE HajiCare — Claim Audit dan Project Truth Summary

Tanggal audit: 25 September 2026  
Basis audit: source code, konfigurasi, aset model, rules, tests, dan dokumen yang ada di workspace C:\hajicare.  
Tujuan: mencegah klaim presentasi melampaui bukti.

## Cara membaca status

- **IMPLEMENTED**: jalur implementasi nyata ditemukan dan terhubung ke aplikasi.
- **PARTIALLY IMPLEMENTED**: ada kode/aset, tetapi jalur belum lengkap, belum teruji end-to-end, bergantung deployment/perangkat, atau memiliki gap material.
- **PLANNED / PROPOSED**: hanya muncul dalam desain/niat, atau ada artefak eksperimen yang tidak terhubung ke runtime aktif.
- **UNKNOWN**: repositori tidak cukup untuk membuktikan klaim.

Kata kunci aman ketika bukti tidak cukup: **BELUM TERBUKTI DARI CODEBASE/DOKUMEN.**

## Project truth summary

### IMPLEMENTED

- Aplikasi Android Flutter dengan GetX, navigasi, binding, controller, service, model, tema, dark mode, skala teks, dan empat locale aplikasi: Indonesia, Inggris, Jawa, Sunda.
- Firebase Authentication: email/password dan Google Sign-In.
- Firestore untuk user, room, member, invitation, notification, SOS, activity, dan room code.
- Firebase callable Cloud Functions di region asia-southeast2 untuk operasi room, profil, notifikasi, dan SOS. Ini adalah backend HajiCare; tidak ada REST server milik sendiri.
- Room jamaah: buat/gabung dengan kode atau QR, undangan, keluar, pengaturan, anggota, dan beberapa peran.
- Pelacakan GPS saat berada dalam room, sinkron lokasi Firestore, perhitungan jarak, radius aman, dan tier aman/waspada/terlalu jauh pada aplikasi yang aktif.
- SOS berbasis Firestore, status realtime, lokasi SOS, respons/penyelesaian, dan layar pencarian pendamping.
- Peta FlutterMap dengan tile CARTO/OSM, POI dinamis dari Overpass, pencarian Photon/Nominatim/native geocoding, serta rute ORS atau fallback OSM routing.
- Jadwal salat lokal, kiblat, lokasi/timezone, alarm adzan lokal, dan dua aset audio adzan.
- Penerjemah teks tiga bahasa id/ar/en memakai ML Kit on-device setelah model bahasa diunduh; STT dan TTS melalui layanan perangkat.
- Money Recognition foto berbasis model TFLite YOLO-family, 14 kelas SAR, multi-pass, penggabungan IoU, total SAR/IDR, dan TTS.
- BISINDO runtime aktif: CameraX → MediaPipe landmarks → 48×135 → model GRU TFLite → 23 label → filter confidence/stability → teks/TTS.
- Panduan haji/doa lokal: 22 entri, 13 kategori, pencarian, bookmark, riwayat, dan skala teks.
- Smartband sisi aplikasi: BLE ke perangkat bernama HajiCare Watch dan membaca suhu, kelembapan, heat index dari karakteristik DHT11.
- Profil berisi data identitas/medis dan UI bantuan, tentang aplikasi, privasi, serta syarat penggunaan.

### PARTIALLY IMPLEMENTED

- Distance alert: perhitungan jarak dan status UI ada, tetapi background monitoring, push notification dua perangkat, alarm persisten, dan eskalasi bertingkat seperti dokumen desain tidak ditemukan.
- Smartband: aplikasi BLE ada, tetapi firmware ESP32, rangkaian, bukti perangkat, kalibrasi, dan uji end-to-end tidak ada di repo. Widget dashboard juga masih memuat placeholder baterai/detak jantung/langkah.
- Backend security: callable functions ada, tetapi direct Firestore fallback dan rules saat ini membuka jalur akses terlalu luas. Deployment rules/functions aktual juga tidak dapat dibuktikan dari repo.
- Profil medis/identitas: UI dan controller ada, tetapi rules tidak mengizinkan NIK/paspor yang ditulis controller; penyimpanan dapat gagal bila rules repo dideploy.
- Permintaan bantuan: pengiriman pesan notifikasi dapat tersimpan di Firestore, tetapi state lifecycle permintaan aktif/riwayat terutama in-memory pada perangkat.
- Notifikasi: realtime inbox Firestore dan notifikasi alarm lokal ada; push notification FCM umum tidak ada.
- Offline: AI lokal tertentu dapat bekerja offline setelah semua aset/model siap, tetapi banyak fitur inti tetap membutuhkan Firebase/internet/GPS atau layanan sistem.
- Rilis: konfigurasi build release ada, tetapi applicationId masih com.example.hajicare dan keystore produksi tidak disertakan.

### PLANNED / PROPOSED ATAU ARTEFAK TIDAK AKTIF

- FCM push untuk distance alert/SOS, background process yang tetap bekerja saat aplikasi tertutup, alert dua perangkat otomatis, dan escalation level dari HajiCare_Design_Document.md.
- Jalur sign-language object detection 42 kelas di assets/models/fix_model/best.tflite mempunyai adapter BisindoYoloService, tetapi tidak dipanggil screen/controller runtime aktif.
- BisindoAlphabetInferenceService dan BisindoWordInferenceService menunjuk aset model/label yang tidak ada atau tidak didaftarkan di pubspec.
- Encoder ONNX + prototype JSON delapan kelas adalah artefak lama/eksperimental, bukan pipeline runtime aktif.
- Speech-to-sign tidak ditemukan.
- Diagnosis medis, detak jantung, SpO2, langkah, dan status baterai smartband nyata tidak diimplementasikan.

### UNKNOWN

- Akurasi, precision, recall, F1, confusion matrix, mAP@50, dan mAP@50–95 seluruh model. Tidak ada laporan evaluasi/model card/training log yang memadai.
- Dataset, jumlah sampel, anotasi, augmentasi, epoch, optimizer, learning rate, pembagian train/validation/test, perangkat training, dan asal model uang/YOLO 42 kelas.
- Metadata BISINDO menyebut signer-independent group split, tetapi dataset dan laporan evaluasi tidak tersedia untuk membuktikan eksekusinya.
- Apakah functions, rules, indexes, custom claims, App Check, dan build terbaru sudah dideploy ke project Firebase produksi.
- Apakah smartband fisik dan firmware sesuai UUID benar-benar tersedia untuk demo.
- Statistik kebutuhan jamaah, angka dampak, hasil usability testing, validasi pengguna, atau pilot lapangan.
- Juknis/rubrik OASE, Executive Summary, proposal resmi, dan daftar pustaka kompetisi tidak ditemukan.
- Verifikasi formal oleh Kemenag/ahli agama atas 22 konten doa saat ini.

## Truth table klaim presentasi

| Claim | Status | Evidence | Source file | Safe to say? | Recommended wording |
|---|---|---|---|---|---|
| HajiCare adalah aplikasi pendamping haji Android berbasis Flutter | IMPLEMENTED | Project Flutter, Android config, routes dan screens | pubspec.yaml; lib/main.dart; android/app/build.gradle.kts | Ya | “HajiCare adalah prototipe/MVP aplikasi Android berbasis Flutter untuk koordinasi, keselamatan, navigasi, ibadah, dan aksesibilitas jamaah.” |
| HajiCare sudah production-ready | UNKNOWN / TIDAK TERBUKTI | Ada gap security, deployment, hardware, model metric, signing/applicationId | firestore.rules; docs/refactor_completion.md; android/app/build.gradle.kts | Tidak | “Versi saat ini adalah prototype/MVP yang sedang divalidasi menuju pilot terkontrol.” |
| Targetnya jamaah lansia, disabilitas, yang membutuhkan pendamping, dan pendamping | IMPLEMENTED sebagai target desain | Tertulis eksplisit pada design document | HajiCare_Design_Document.md | Ya, sebagai target | “Target desain kami adalah …”; jangan klaim sudah diuji kepada populasi tersebut. |
| Ada tiga peran: jamaah, pendamping, admin | IMPLEMENTED | Enum, guards, dashboard dan backend | lib/core/models/jamaah_data.dart; lib/core/routes/app_routes.dart | Ya | “Runtime sekarang mengenal tiga peran.” |
| Hak admin hanya dari custom claim | PARTIALLY IMPLEMENTED | Guard/controller memakai claim, tetapi rules dan backend memiliki fallback/akses luas | lib/core/state/hajicare_controller.dart; functions/src/authorization.js; firestore.rules | Hati-hati | “Desain otorisasi privileged memakai custom claim, tetapi hardening rules dan penghapusan fallback masih prioritas sebelum produksi.” |
| Pendamping harus disetujui admin | PARTIALLY IMPLEMENTED | Callable review ada; profil pending ada, tetapi klien dapat memilih role dan rules/fallback dapat dibypass | functions/src/profile_operations.js; register_controller.dart; firestore.rules | Hati-hati | “Workflow persetujuan server tersedia, tetapi enforcement end-to-end masih perlu diperketat.” |
| Ada backend HajiCare | IMPLEMENTED | Firebase Auth, Firestore, Cloud Functions | functions/index.js; trusted_backend_service.dart | Ya | “Backend kami serverless berbasis Firebase, bukan REST server tradisional.” |
| HajiCare memakai REST API sendiri | TIDAK TERBUKTI | Tidak ada custom REST server; hanya callable Firebase dan API pihak ketiga | functions/index.js; lib/core/services | Tidak | “Kami tidak memiliki REST backend sendiri pada versi ini.” |
| Operasi sensitif selalu melalui backend tepercaya | PARTIALLY IMPLEMENTED | Banyak operasi mencoba callable, lalu direct Firestore fallback; SOS aktif langsung Firestore | room_command_service.dart; notification_service.dart; sos_service.dart | Tidak | “Callable functions tersedia, tetapi beberapa fallback direct-write masih harus dihapus sebelum produksi.” |
| Room dan pairing sudah ada | IMPLEMENTED | Create/join/invite/QR/member flows ditemukan | lib/features/room; functions/src/room_operations.js | Ya, sebagai fungsi aplikasi | “Room rombongan dan keanggotaan realtime sudah diimplementasikan.” |
| Semua akses room sudah terisolasi per anggota | TIDAK BENAR pada rules repo | rooms dapat dibaca/diubah setiap signed-in user | firestore.rules | Tidak | “Isolasi room adalah tujuan desain; rules repo saat ini masih memiliki celah dan belum layak diklaim aman.” |
| Data medis hanya terlihat pihak berwenang | TIDAK BENAR pada rules repo | users/{uid} dapat dibaca semua signed-in user | firestore.rules | Tidak | “Saat ini ada risiko akses terlalu luas; rules harus dibatasi ke diri sendiri/admin/pendamping room yang sah.” |
| NIK dan paspor dapat tersimpan | PARTIALLY IMPLEMENTED / berpotensi gagal | Controller menulis field, rules allowlist tidak mengizinkan passportNumber/passport/nik | profile_controller.dart; firestore.rules | Hati-hati | “UI sudah ada, tetapi sinkronisasi rules untuk field NIK/paspor belum selesai.” |
| User dapat menghapus akun dan seluruh datanya | TIDAK TERBUKTI | Tidak ada delete-account/data-erasure flow; rules menolak delete user | firestore.rules; lib/features/auth | Tidak | “Penghapusan akun/data perlu ditambahkan sebagai future work.” |
| Lokasi dilacak realtime | IMPLEMENTED dengan syarat | Geolocator stream, update minimal perpindahan 10 m dan throttle; Firestore listeners | hajicare_controller.dart | Ya, bersyarat | “Saat aplikasi aktif, izin/GPS/internet tersedia, lokasi diperbarui ke Firestore secara berkala.” |
| Lokasi selalu dilacak walau aplikasi ditutup | TIDAK TERBUKTI | Tidak ada background location service | AndroidManifest.xml; hajicare_controller.dart | Tidak | “Belum ada background tracking production.” |
| Distance Alert otomatis mengirim alarm ke dua perangkat | PLANNED / PROPOSED | Hanya ada di design doc; runtime terutama status/card dalam aplikasi | HajiCare_Design_Document.md; jamaah_data.dart | Tidak | “Versi sekarang menghitung dan menampilkan status jarak saat aplikasi aktif; push dua arah/background masih roadmap.” |
| Radius aman dapat diubah | IMPLEMENTED | setSafeRadius dan update room settings | hajicare_controller.dart; room services | Ya | “Pendamping dapat mengubah radius room; tier dihitung dari radius itu.” |
| Radius berbeda untuk setiap jamaah | TIDAK TERBUKTI | safeRadius adalah setting room/global controller, bukan per-jamaah | hajicare_controller.dart; room_model.dart | Tidak | “Radius saat ini berlaku pada room, belum per individu.” |
| Perhitungan jarak memakai GPS/Haversine | IMPLEMENTED | LocationService distance calculation dipakai | location_service.dart; hajicare_controller.dart | Ya | “Jarak garis lurus dihitung dari dua koordinat; bukan jarak rute jalan.” |
| SOS tersimpan realtime | IMPLEMENTED | Batch menulis event/user/member dan listener realtime | sos_service.dart; room_query_service.dart | Ya, dengan syarat backend/rules | “SOS dicatat di Firestore dan diamati secara realtime selama koneksi tersedia.” |
| SOS otomatis menghubungi layanan darurat Saudi | TIDAK TERBUKTI | Tidak ada integrasi emergency dispatch | lib/features/sos | Tidak | “SOS menghubungkan jamaah dengan ekosistem pendamping HajiCare, bukan layanan darurat resmi.” |
| SOS memakai push notification FCM | TIDAK TERBUKTI | firebase_messaging tidak ada | pubspec.yaml | Tidak | “Status/notifikasi SOS menggunakan Firestore realtime saat aplikasi aktif.” |
| Peta bisa menampilkan fasilitas dinamis | IMPLEMENTED | Overpass POST dan kategori POI | poi_service.dart; map_controller.dart | Ya | “POI diambil dinamis dari OpenStreetMap/Overpass ketika internet tersedia.” |
| Peta dan rute sepenuhnya offline | TIDAK BENAR | Tile, POI, geocoding, routing perlu jaringan | map services; app_constants.dart | Tidak | “Lokasi GPS dapat diperoleh lokal, tetapi peta/rute/POI umumnya memerlukan internet.” |
| ORS key wajib | TIDAK BENAR | ORS opsional; fallback OSM routing | app_config.dart; route_service.dart | Ya untuk menjelaskan | “Jika ORS key tidak ada, aplikasi mencoba layanan routing publik OSM.” |
| API key aman karena dart-define | PARTIALLY IMPLEMENTED | ORS via dart-define; CARTO memiliki default di source; client key tetap dapat diekstrak | app_config.dart; app_constants.dart | Hati-hati | “Tidak ada private server credential di repo, tetapi client API key perlu restriction/proxy bila sensitif.” |
| Jadwal salat dihitung lokal | IMPLEMENTED | package adhan + lokasi/timezone | prayer_calculation_service.dart; prayer_times_controller.dart | Ya | “Perhitungan jadwal dilakukan lokal; akurasi bergantung koordinat, timezone, dan metode.” |
| Alarm adzan adalah FCM | TIDAK BENAR | flutter_local_notifications + file audio lokal | adhan_notification_service.dart; assets/audio | Tidak | “Alarm adzan adalah local notification.” |
| Panduan doa memiliki audio tiap doa | TIDAK BENAR | 22 entri tidak memiliki audioPath; hanya audio adzan tersedia | hajj_dua_data.dart; assets/audio | Tidak | “Konten doa saat ini berbentuk teks; audio doa belum tersedia.” |
| Konten doa sudah diverifikasi resmi Kemenag | UNKNOWN | Source label ada, tetapi referensi primer tidak ada di repo; audit lama menyebut belum menambah sumber | hajj_dua_data.dart; docs/hajj_dua_content_audit.md | Tidak | “Entri mencantumkan atribusi Kemenag di data aplikasi; verifikasi tekstual formal masih perlu dilakukan.” |
| Ada ayat/hadis sebagai landasan proposal OASE | UNKNOWN | Proposal/ES/daftar pustaka tidak ditemukan | seluruh docs | Tidak | “Dokumen yang tersedia tidak memberi landasan dalil kompetisi yang dapat saya verifikasi.” |
| Money Recognition mendeteksi uang SAR | IMPLEMENTED | Model, 14 labels, screen runtime | assets/models/best_float16.tflite; labels.txt; money_recognition_screen.dart | Ya | “Model mendeteksi 14 label denominasi Riyal/Halala pada foto.” |
| Money Recognition adalah classification | TIDAK TEPAT | Output memiliki banyak box/class/confidence; YOLOTask.detect | money_recognition_screen.dart; model tensor | Tidak | “Ini object detection, sehingga dapat menemukan beberapa objek dan lokasi box.” |
| Input model uang 640×640 | IMPLEMENTED pada model | Tensor input [1,640,640,3] Float32 | assets/models/best_float16.tflite | Ya | “Runtime/plugin menyiapkan gambar untuk model 640×640.” |
| Model uang INT8 | TIDAK TERBUKTI | I/O Float32; banyak DEQUANTIZE mengarah ke weight float16 | model artifact | Tidak | “File bernama float16 dan I/O-nya Float32; jangan menyebut INT8.” |
| Money Recognition bekerja offline | IMPLEMENTED untuk inferensi, bersyarat | Model bundled dan inference lokal; kurs/TTS dapat bergantung jaringan/engine | money screen/services | Ya, dengan batas | “Deteksi nominalnya on-device dan dapat offline setelah aplikasi terpasang; pembaruan kurs perlu internet.” |
| Nilai confidence adalah akurasi model | TIDAK BENAR | Confidence per prediksi bukan metric evaluasi dataset | money_detection.dart; UI string | Tidak | “Angka itu tingkat keyakinan prediksi, bukan accuracy keseluruhan.” |
| Accuracy/mAP model uang X% | UNKNOWN | Tidak ada metrics artifact | assets/models; docs | Tidak | “BELUM TERBUKTI DARI CODEBASE/DOKUMEN.” |
| Multi-pass meningkatkan akurasi sebesar X% | UNKNOWN | Mekanisme ada, tetapi tidak ada ablation/evaluation | smart_multi_pass_detector.dart | Tidak | “Multi-pass dirancang meningkatkan robustness; besar peningkatannya belum diukur.” |
| BISINDO aktif memakai MediaPipe + GRU | IMPLEMENTED | Active screen/binding/inference/native helper | lib/features/sign_language; android/app/src/main/kotlin/com/example/hajicare/BisindoCameraHelper.kt | Ya | “Pipeline aktif memakai landmark tangan temporal dan GRU TFLite.” |
| Input BISINDO [1,48,135], output [1,23] | IMPLEMENTED / terverifikasi artifact | Tensor dan checks di service | bisindo_inference_service.dart; model_config.json; .tflite | Ya | “Satu batch, 48 frame, 135 fitur per frame, 23 kelas keluaran.” |
| 48 frame selalu penuh dari kamera sebelum inferensi | TIDAK TEPAT | Screen mulai pada 24 frame dan service mem-pad ke 48 | bisindo_screen.dart; bisindo_inference_service.dart | Tidak | “Window maksimum 48; runtime dapat mulai setelah 24 frame dengan padding frame awal.” |
| 48 frame setara sekitar 3,2 detik | IMPLEMENTED sebagai target sampling | metadata 15 FPS dan 3.2 s | model_config.json; Kotlin min interval | Ya, sebagai nominal | “Pada target 15 FPS, 48 frame kira-kira 3,2 detik; frame aktual dapat bervariasi.” |
| 135 fitur memuat dua tangan dan relasi | IMPLEMENTED | 63+63+2+4+3 | bisindo_preprocessor.dart; model_config.json | Ya | “Dua tangan XYZ lokal, presence, posisi wrist, dan relasi antar-wrist.” |
| Pose/face dipakai model BISINDO | TIDAK TEPAT untuk model aktif | Native mengirim 543, face zero-filled; preprocessor aktif hanya hands | BisindoCameraHelper.kt; bisindo_preprocessor.dart | Tidak | “Transport memakai layout 543 untuk kompatibilitas, tetapi model GRU aktif mengambil fitur tangan.” |
| Threshold BISINDO adalah 0,78 | PARTIALLY TRUE / runtime berbeda | Config file .78, production binding .58; service flag .48 | model_config.json; bisindo_binding.dart; bisindo_inference_service.dart | Jangan sebut tunggal | “Metadata menyimpan 0,78, tetapi gate runtime produksi saat ini 0,58 dan tiga prediksi stabil; konfigurasi perlu diselaraskan.” |
| BISINDO mempunyai 23 kelas | IMPLEMENTED | labels.json | assets/models/bisindo/labels.json | Ya | Sebut daftar hanya jika ditanya; jangan klaim mencakup seluruh BISINDO. |
| Model BISINDO merepresentasikan seluruh bahasa BISINDO | TIDAK BENAR | Hanya 23 label | labels.json | Tidak | “Ini pengenal kosakata terbatas, bukan penerjemah bahasa isyarat bebas.” |
| Akurasi BISINDO X% | UNKNOWN | Tidak ada report | assets/models/bisindo | Tidak | “BELUM TERBUKTI DARI CODEBASE/DOKUMEN.” |
| Signer-independent split terbukti | UNKNOWN | Hanya metadata, tidak ada data/log | model_config.json | Hati-hati | “Konfigurasi mencatat rencana signer-independent split; hasilnya belum dapat diaudit.” |
| Video BISINDO dikirim ke cloud | TIDAK DITEMUKAN | Pipeline native/TFLite lokal, tanpa upload frame | BisindoCameraHelper.kt; bisindo_inference_service.dart | Ya, scope code | “Pada implementasi yang diaudit, frame diproses on-device dan tidak ada upload kamera.” |
| SIBI memakai YOLO26 aktif | TIDAK TERBUKTI | Tidak ada istilah/version proof; service YOLO tidak terhubung runtime | fix_model assets; bisindo_yolo_service.dart; app_routes.dart | Tidak | “Ada artefak YOLO-family 42 kelas dan adapter eksperimen, tetapi bukan fitur runtime aktif; versi YOLO26 tidak terbukti.” |
| SIBI dan BISINDO sengaja memakai dua model berbeda | UNKNOWN sebagai keputusan historis | Hanya pipeline BISINDO aktif; pipeline YOLO tidak aktif | sign_language services | Tidak sebagai fakta sejarah | “Secara engineering, gerak temporal cocok dengan sequence model dan pose statis dapat cocok dengan detector; tetapi repo tidak membuktikan keputusan SIBI final.” |
| Model 42 kelas adalah SIBI lengkap | TIDAK TERBUKTI | Labels campuran huruf dan kata; file/service menamakannya BISINDO | fix_model/label.txt; bisindo_yolo_service.dart | Tidak | “Sebut sebagai artefak sign-language YOLO 42 label, bukan SIBI produksi.” |
| Smartband memonitor suhu tubuh | TIDAK BENAR | DHT11 membaca lingkungan | smartband controller/service | Tidak | “Smartband membaca suhu dan kelembapan lingkungan.” |
| Smartband memonitor detak jantung/SpO2 | TIDAK BENAR | Tidak ada characteristic/sensor tersebut; UI placeholder | ble_service.dart; jamaah_service_grid.dart | Tidak | “Belum ada sensor vital; jangan menyebut health monitoring medis.” |
| Smartband melakukan diagnosis panas/dehidrasi | TIDAK BENAR | Hanya threshold kondisi lingkungan dan heat index | smartband_ldr_controller.dart | Tidak | “Status panas adalah indikator lingkungan, bukan diagnosis.” |
| Smartband menggunakan ESP32 + DHT11 | PARTIALLY IMPLEMENTED | App copy dan protocol mengasumsikan ESP32/DHT11; firmware tidak ada | ble_service.dart; smartband screen | Hati-hati | “Sisi aplikasi disiapkan untuk HajiCare Watch berbasis ESP32/DHT11; firmware dan perangkat end-to-end tidak ada di repo.” |
| Smartband memakai BLE | IMPLEMENTED sisi app | flutter_blue_plus, scan/connect/read/notify | pubspec.yaml; ble_service.dart | Ya, dengan batas | “Aplikasi menggunakan BLE custom service dengan tiga karakteristik.” |
| Penerjemah selalu offline | PARTIALLY IMPLEMENTED | Inference lokal setelah model diunduh; unduhan awal butuh internet | translation_service.dart | Hati-hati | “Setelah model bahasa tersedia, terjemahan teks berjalan on-device.” |
| STT selalu offline | UNKNOWN / device-dependent | speech_to_text memakai speech service platform | speech_service.dart | Tidak | “Ketersediaan offline tergantung engine dan language pack perangkat.” |
| TTS selalu offline | UNKNOWN / device-dependent | flutter_tts memakai engine perangkat | tts services | Tidak | “TTS tidak mengirim teks lewat kode kami, tetapi kemampuan offline bergantung engine.” |
| HajiCare menyimpan data di SQLite/Hive | TIDAK BENAR | Dependency tidak ada | pubspec.yaml | Tidak | “Penyimpanan memakai Firestore, SharedPreferences, local JSON, dan model assets.” |
| SharedPreferences terenkripsi | TIDAK TERBUKTI | Paket standar, tidak ada encrypted storage | pubspec.yaml; controllers/services | Tidak | “Preferensi lokal belum memakai secure encrypted storage.” |
| Firebase client API key adalah private secret | TIDAK TEPAT | Firebase client config memang dibundel; keamanan utama rules/restriction | firebase_options.dart; google-services.json | Tidak | “Itu identifier client, bukan service-account secret; tetap perlu API restriction dan rules aman.” |
| Tidak ada private service-account/keystore di repo | IMPLEMENTED dari scan saat audit | gitignore dan tracked-files scan | .gitignore; git ls-files | Ya, terbatas | “Audit repo tidak menemukan private service-account atau keystore produksi yang terlacak.” |
| Semua jaringan memakai HTTPS | IMPLEMENTED untuk endpoint aplikasi aktif | Endpoint ditemukan memakai https; tel URI bukan jaringan web | lib/**/*.dart | Ya, terbatas | “Endpoint web yang ditemukan menggunakan HTTPS; belum ada certificate pinning.” |
| App Check aktif | PLANNED | Hanya direkomendasikan dalam README functions; dependency/init tidak ada | functions/README.md; pubspec.yaml | Tidak | “App Check adalah future hardening.” |
| Privacy policy sesuai enforcement teknis | TIDAK SEPENUHNYA | Copy menyatakan akses dibatasi, tetapi rules membolehkan pembacaan users/rooms luas | locales/id.dart; firestore.rules | Tidak | “Kebijakan dan rules harus diselaraskan sebelum pilot.” |
| Aplikasi sudah diuji | IMPLEMENTED untuk unit/widget suite | 300 test lulus pada 25 Sep 2026 | test/; perintah flutter test | Ya, jelaskan scope | “300 automated tests lulus; ini bukan uji lapangan, keamanan, hardware, atau akurasi ML.” |
| Static analyzer bersih | PARTIALLY TRUE | Tidak ada error/warning, tetapi ada 6 info deprecation | flutter analyze --no-pub | Hati-hati | “Tidak ada error/warning analyzer; ada enam info deprecation.” |
| Cloud Functions/security tests lulus | UNKNOWN saat audit ini | npm/Node tidak tersedia; emulator tests tidak dijalankan; functions/package.json juga menunjuk test/*.test.js yang tidak ada | functions/package.json; firebase-tests/*.test.js | Tidak | “Emulator/backend tests belum dieksekusi pada audit ini.” |
| Firestore security tests sesuai rules sekarang | Kemungkinan TIDAK | Test mengharapkan outsider/profile access ditolak, sedangkan rules mengizinkan | firebase-tests/firestore.rules.test.js; firestore.rules | Tidak | “Ada drift antara test security dan rules yang harus diselesaikan.” |
| Ada hasil uji pengguna/lapangan | UNKNOWN | Tidak ditemukan research report | docs | Tidak | “Belum ada bukti usability/pilot di repo.” |
| HajiCare lebih akurat daripada Google Lens/Translate | UNKNOWN | Tidak ada benchmark | seluruh repo | Tidak | “Nilai utama yang dapat diklaim adalah integrasi alur haji, bukan superioritas model.” |
| HajiCare belum pernah ada | UNKNOWN dan terlalu luas | Tidak ada competitor study | docs | Tidak | “Novelty kami berada pada integrasi kontekstual beberapa kebutuhan, bukan klaim pertama di dunia.” |

## Temuan red-team prioritas

### P0 — jangan pilot dengan data nyata sebelum diperbaiki

1. **Kebocoran profil:** firestore.rules mengizinkan semua pengguna login membaca semua dokumen users, termasuk lokasi dan data medis/identitas.
2. **Takeover room:** semua pengguna login dapat membaca/membuat/mengubah rooms; pengguna dapat membuat/mengubah membership dirinya sendiri tanpa allowlist field.
3. **Privilege escalation:** user dapat mengubah field profil sendiri menjadi pendamping, membuat membership pendamping, lalu memanfaatkan fallback role pada functions/src/authorization.js.
4. **roomCodes terbuka:** setiap signed-in user dapat membaca, membuat, mengubah, dan menghapus mapping kode.
5. **Notification forgery/spam:** jenis notifikasi selain tiga jenis khusus dapat dibuat langsung oleh signed-in user tanpa validasi sender/recipient yang memadai.
6. **Rules/profile mismatch:** penyimpanan NIK dan paspor dapat ditolak karena field tidak masuk allowlist update.

### P1 — sebelum klaim demo kuat

1. Selaraskan threshold BISINDO .78 metadata, .58 gate produksi, dan .48 flag service.
2. Hapus atau labeli jelas UI placeholder detak jantung/baterai/langkah.
3. Putuskan status artefak YOLO sign-language 42 kelas; hubungkan end-to-end atau sebut eksperimen.
4. Tambahkan model card: dataset, split, metric, device latency, failure cases, dan batas penggunaan.
5. Uji perangkat fisik untuk kamera, alarm, GPS dua perangkat, BLE, dan kondisi jaringan buruk.
6. Selaraskan privacy policy dengan implementasi rules dan data-retention/deletion flow.

## Kalimat penyelamat saat ditanya bukti

- “Yang dapat saya buktikan dari implementasi saat ini adalah …”
- “Angka itu confidence per prediksi, bukan accuracy dataset.”
- “Metrik evaluasi tersebut belum tersedia di repository, jadi saya tidak akan mengarang nilainya.”
- “Fitur ini sudah ada pada sisi aplikasi, sedangkan validasi end-to-end perangkat/deployment masih tahap berikutnya.”
- “Dokumen desain menggambarkan target final; versi runtime saat ini baru …”
- “Itu engineering rationale yang masuk akal, bukan fakta historis yang terdokumentasi.”
- “Untuk keselamatan, HajiCare adalah alat bantu dan bukan pengganti petugas, layanan darurat, atau tenaga medis.”

## Bukti verifikasi teknis audit ini

- flutter test --reporter compact: **300 test lulus**.
- flutter analyze --no-pub: **6 info deprecation**, tanpa error/warning.
- npm test pada functions: **tidak dapat dijalankan**, karena npm tidak tersedia pada mesin audit.
- Model tensor yang diperiksa:
  - Money: input [1,640,640,3] Float32; output [1,300,6] Float32.
  - Sign-language YOLO artifact: input [1,3,640,640] Float32; output [1,46,8400] Float32.
  - BISINDO GRU: input [1,48,135] Float32; output [1,23] Float32.
- Tidak ditemukan PDF, DOCX, PPTX, proposal OASE, Executive Summary, juknis, dataset documentation, atau laporan metric ML di workspace.

## Aturan lisan untuk besok

1. Selalu buka dengan kata **prototype/MVP**.
2. Sebut **on-device** hanya untuk pipeline yang benar-benar lokal.
3. Jangan ubah confidence menjadi accuracy.
4. Jangan sebut smartband sebagai monitor medis.
5. Jangan sebut SIBI/YOLO26 sebagai fitur aktif.
6. Jangan menjanjikan background/push notification.
7. Jika ditanya keamanan, akui gap rules secara langsung dan jelaskan rencana hardening.
8. Jika ditanya dalil/statistik, katakan sumber formal belum ada di pack proyek.
