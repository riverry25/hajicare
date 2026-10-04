# OASE HajiCare — Master Study Guide

Gunakan urutan belajar ini: pahami produk → pahami empat alur inti → pahami AI → pahami batas → latihan menjawab. Jangan mulai dari menghafal istilah.

## 1. Mental model paling sederhana

### Apa itu HajiCare?

HajiCare adalah prototype aplikasi Android yang menggabungkan koordinasi rombongan, keselamatan, navigasi, informasi ibadah, dan aksesibilitas untuk membantu jamaah haji dan pendamping dalam satu alur.

### Masalah apa yang hendak diselesaikan?

Dokumen desain menyebut empat kelompok masalah:

1. Jamaah, terutama lansia/disabilitas atau yang membutuhkan pendamping, dapat terpisah di area ramai.
2. Jamaah kesulitan menemukan fasilitas, pemondokan, atau arah.
3. Informasi darurat dan koordinasi pendamping tersebar atau lambat.
4. Lingkungan asing menimbulkan hambatan bahasa, isyarat, dan pengenalan uang.

Itu adalah **problem statement desain**, bukan hasil riset lapangan yang dibuktikan repo. Jika juri bertanya jumlah kasus/statistik, jawab bahwa angka validasi belum tersedia dalam dokumen proyek.

### Siapa pengguna?

- jamaah;
- pendamping/petugas pendamping;
- admin operasional.

Target desain menekankan jamaah lansia, penyandang disabilitas, atau yang memerlukan bantuan. Namun usability test pada kelompok tersebut belum ditemukan.

### Kapan dipakai?

- sebelum kegiatan: login, room, profil, panduan, jadwal;
- saat bergerak bersama rombongan: GPS, peta, jarak;
- saat terpisah/darurat: bantuan, SOS, lokasi;
- saat transaksi/komunikasi: deteksi uang, translator, BISINDO;
- saat mengecek lingkungan: smartband DHT11.

### Core value proposition

Bukan “semua fiturnya belum pernah ada”. Nilainya adalah **mengurangi perpindahan konteks**: jamaah tidak perlu berpindah antara banyak aplikasi ketika membutuhkan pendamping, navigasi, bantuan aksesibilitas, dan panduan ibadah.

### Mengapa aplikasi mobile?

Ponsel sudah membawa kamera, GPS, mikrofon, speaker, Bluetooth, kompas, layar, dan koneksi. Semua input yang diperlukan berada pada perangkat yang sama. Model lokal juga dapat memakai kamera tanpa mengirim frame ke server.

## 2. Cara menjelaskan dalam beberapa durasi

### Satu kalimat

“HajiCare adalah prototype pendamping digital haji yang menyatukan koordinasi rombongan, keselamatan, navigasi, ibadah, dan aksesibilitas berbasis AI on-device.”

### 15 detik

“HajiCare membantu jamaah dan pendamping tetap terkoordinasi melalui room, GPS, peta, dan SOS, lalu menambahkan aksesibilitas seperti deteksi uang SAR, translator, dan pengenalan 23 kosakata BISINDO secara lokal di ponsel.”

### 30 detik

“Di lingkungan haji yang ramai, jamaah dapat terpisah, kesulitan mencari fasilitas, berkomunikasi, atau mengenali uang. HajiCare menyatukan room rombongan, lokasi, radius aman, SOS, peta, jadwal salat, panduan manasik, deteksi uang SAR, translator, BISINDO, dan koneksi smartband lingkungan. Versi ini adalah MVP; model AI berjalan lokal, sedangkan koordinasi realtime memakai Firebase.”

### 1 menit

“HajiCare adalah prototype Android untuk jamaah, pendamping, dan admin. Masalah yang kami angkat adalah fragmentasi bantuan: lokasi dan darurat ada di satu tempat, navigasi di tempat lain, sedangkan kebutuhan bahasa, isyarat, dan uang belum berada dalam alur haji yang sama. Karena itu, pengguna bergabung ke room rombongan, membagikan lokasi, melihat jarak dan peta, serta mengirim SOS. Untuk aksesibilitas, foto uang SAR diproses model object detection lokal dan hasilnya dibacakan; kamera BISINDO diubah MediaPipe menjadi landmark tangan lalu GRU membaca urutan 48 frame untuk memilih satu dari 23 label. Jadwal salat dan panduan ibadah melengkapi konteks haji. Backend menggunakan Firebase, sedangkan smartband saat ini baru membaca suhu/kelembapan lingkungan melalui BLE. Kami menyebutnya MVP, karena metric AI, uji lapangan, hardware end-to-end, dan security hardening masih perlu diselesaikan.”

### 3 menit — struktur, bukan naskah

1. Hook: satu jamaah terpisah tidak hanya butuh peta; ia butuh koordinasi, komunikasi, dan jalur bantuan.
2. Target: jamaah, pendamping, admin.
3. Alur inti: room → lokasi/jarak → peta → SOS.
4. Aksesibilitas: uang SAR dan BISINDO on-device; translator.
5. Ibadah: waktu salat, kiblat, panduan.
6. Teknologi: Flutter/GetX, Firebase, native Android, TFLite/MediaPipe, BLE.
7. Novelty: integrasi kontekstual, privacy/latency lokal.
8. Jujur: MVP; metric, security, smartband fisik, dan pilot masih berikutnya.

Versi 3/5/7/10 menit lengkap ada di OASE_HAJICARE_PRESENTATION.md.

## 3. Project truth map

### Benar-benar aktif

Auth, tiga role, room/invitation/QR, Firestore realtime, GPS/jarak/radius, SOS, peta/POI/search/route, prayer/kiblat/local adzan, translator/STT/TTS, Money Recognition, BISINDO GRU 23 kelas, panduan haji/doa, profil, notification inbox, dan client BLE DHT11.

### Parsial

Security backend, lifecycle bantuan yang durable, notifikasi lintas perangkat, distance alert background, profil NIK/paspor, smartband end-to-end, offline behavior, dan release readiness.

### Bukan fitur aktif

SIBI YOLO26, 42-label YOLO screen, model alphabet/word yang asetnya hilang, ONNX prototype pipeline, FCM push, background distance alarm, sensor vital, diagnosis medis, speech-to-sign.

### Tidak diketahui

Accuracy/mAP, dataset/training, pilot/usability, angka dampak, deployment produksi, spesifikasi hardware/firmware, dan sumber formal OASE/Kemenag.

Selalu cek OASE_HAJICARE_CLAIM_AUDIT.md sebelum mengubah wording.

## 4. Seluruh fitur — inventory ringkas

| Kelompok | Fitur | Status |
|---|---|---|
| Onboarding/settings | onboarding, locale ID/EN/JV/SU, dark mode, text scale | IMPLEMENTED |
| Auth | email/password, Google Sign-In, remember flow | IMPLEMENTED; approval role PARTIAL |
| Room | create, code/QR join, invite, member, edit/delete/leave | IMPLEMENTED; rules PARTIAL |
| Admin | room/user/SOS/activity dashboards | IMPLEMENTED UI/query; deployment/security PARTIAL |
| Location | GPS stream, Firestore publish, distance, safe radius | IMPLEMENTED saat app aktif |
| Distance alert | tier/card/separated state | PARTIAL; background/push proposed |
| SOS | trigger, event, location, response/resolve, scanning/detail | IMPLEMENTED dengan direct-write caveat |
| Assistance | pickup/lost/separated/message | PARTIAL; lifecycle banyak in-memory |
| Notification | Firestore inbox, invite, compose, read/delete | IMPLEMENTED; bukan FCM push |
| Map | tiles, members, POI, filters, search, route, external Maps | IMPLEMENTED online |
| Prayer | schedule, countdown, qibla, local adzan/reminder | IMPLEMENTED; device-dependent |
| Hajj guide | 22 entries/13 categories, bookmark/search/recent | IMPLEMENTED; source verification UNKNOWN |
| Money | photo detection, 14 classes, total, IDR, TTS | IMPLEMENTED; metrics UNKNOWN |
| Translator | id/ar/en, STT/text/TTS | IMPLEMENTED; first model download needed |
| Communication | quick phrases and link to BISINDO/translator | IMPLEMENTED |
| BISINDO | MediaPipe hands + GRU 23 classes + TTS | IMPLEMENTED; limited vocabulary/metrics UNKNOWN |
| SIBI/YOLO sign | assets + unused adapter | PLANNED/EXPERIMENTAL |
| Smartband | BLE DHT11 temperature/humidity/heat index | PARTIAL end-to-end |
| Profile/legal/help | medical/identity UI, FAQ, about, privacy/terms | IMPLEMENTED UI; storage/rules mismatch |

## 5. Bedah fitur inti dengan pola A–O

## 5.1 Room dan autentikasi

**A. Masalah:** identitas dan scope rombongan diperlukan agar lokasi/pesan tidak bercampur.  
**B. Tujuan:** membuat konteks room untuk jamaah dan pendamping.  
**C. User flow:** daftar/login → pilih role → buat/gabung room dengan kode/QR/undangan → dashboard room.  
**D. Input:** email/password/Google, nama, nomor porsi, role, room code.  
**E. Processing:** Firebase Auth menghasilkan UID; profil Firestore dibuat; callable melakukan transaction room/membership.  
**F. Output:** session, role UI, activeRoomId, stream room/member.  
**G. Teknologi:** Firebase Auth, Firestore, Cloud Functions, GetX, mobile_scanner, qr_flutter.  
**H. File:** auth controllers; room_command_service.dart; room_query_service.dart; functions/src/room_operations.js.  
**I. Data flow:** UI → controller → RoomService → callable → transaction → snapshot → controller → UI.  
**J. Alasan teknologi:** realtime document streams cocok untuk perubahan membership; callable memberi tempat validasi server.  
**K. Kelebihan:** kode/QR sederhana; transaksi server; update realtime.  
**L. Keterbatasan:** rules terlalu luas; direct fallback; role approval tidak enforce penuh.  
**M. Pertanyaan juri:** “Apakah user bisa mengaku pendamping?”  
**N. Jawaban:** “Workflow approval/custom claim ada, tetapi audit menemukan fallback/rules masih membuka celah; sebelum pilot harus di-hardening.”  
**O. Demo:** gunakan akun demo tanpa data pribadi; login → scan/ketik kode → tampilkan anggota.

## 5.2 GPS, jarak, dan radius aman

**A. Masalah:** pendamping perlu mengetahui pemisahan fisik.  
**B. Tujuan:** memperlihatkan jarak dan status risiko.  
**C. Flow:** izin GPS → posisi stream → Firestore → posisi lawan → jarak → tier UI.  
**D. Input:** latitude/longitude dua perangkat, radius room.  
**E. Processing:** distanceFilter 10 m; throttle; Haversine; tier 50%/100%; separated setelah 5 detik.  
**F. Output:** meter/km, aman/waspada/terlalu jauh, marker peta.  
**G. Teknologi:** geolocator, Firestore, latlong/location service.  
**H. File:** hajicare_controller.dart; location_service.dart; jamaah_data.dart.  
**I. Data flow:** GPS → state → Firestore user/member → listener peer → distance → Obx.  
**J. Why:** smartphone sudah punya GPS; Firestore memudahkan stream dua arah.  
**K. Kelebihan:** data nyata, radius configurable, tidak memakai angka jarak mock.  
**L. Keterbatasan:** akurasi GPS/canyon building, battery/network, tidak background, radius room bukan per orang.  
**M. Juri:** “Apakah alert tetap masuk saat app ditutup?”  
**N. Jawaban:** “Belum. Versi aktif menghitung saat app berjalan; background/push masih roadmap.”  
**O. Demo:** dua akun/perangkat; ubah radius; tunjukkan timestamp/freshness, jangan memindah GPS palsu tanpa mengaku.

## 5.3 SOS

**A. Masalah:** jamaah membutuhkan sinyal bantuan yang membawa identitas dan lokasi.  
**B. Tujuan:** menyebarkan event SOS pada ekosistem room.  
**C. Flow:** tombol → konfirmasi → trigger → pendamping melihat banner/detail → respons → selesai/cancel.  
**D. Input:** UID/nama, room, posisi, kloter/maktab.  
**E. Processing:** Firestore batch membuat event dan status; stream realtime; location event diperbarui.  
**F. Output:** sos_events, banner, map/detail, status.  
**G. Teknologi:** Firestore, GetX, vibration, Google Maps external.  
**H. File:** sos_service.dart; modal_sos_screen.dart; sos_alert_detail_screen.dart; room_query_service.dart.  
**I. Data flow:** UI → HajiCareController → direct Firestore batch → listeners.  
**J. Why:** batch mencegah event dan status terpisah.  
**K. Kelebihan:** lokasi opsional, room/standalone, realtime state.  
**L. Keterbatasan:** bukan emergency dispatch resmi, bergantung internet/app aktif, active client tidak memakai callable triggerSos.  
**M. Juri:** “Apakah ini menggantikan layanan darurat?”  
**N. Jawaban:** “Tidak; ini alat koordinasi internal dan pengguna tetap diarahkan ke petugas/layanan resmi.”  
**O. Demo:** tekan konfirmasi, lihat pendamping menerima event, resolve; siapkan data demo.

## 5.4 Peta, POI, search, route

**A. Masalah:** menemukan fasilitas dan anggota di lingkungan asing.  
**B. Tujuan:** satu peta untuk posisi room dan fasilitas.  
**C. Flow:** buka map → lokasi → load POI → filter/search → pilih → route/directions.  
**D. Input:** coordinate, viewport/category, query.  
**E. Processing:** tile render; Overpass POST; Photon/Nominatim search; ORS/OSM routing.  
**F. Output:** markers, bottom sheet, polyline/directions.  
**G. Teknologi:** flutter_map, CARTO/OSM, Overpass, Photon, Nominatim, ORS.  
**H. File:** map_controller.dart; poi_service.dart; route_service.dart; geocoding_service.dart.  
**I. Data flow:** UI/controller → HTTPS/provider → JSON → MapPoi/route → markers/polyline.  
**J. Why:** open geodata menekan biaya prototipe dan fleksibel.  
**K. Kelebihan:** POI dinamis dan fallback provider.  
**L. Keterbatasan:** internet/quota/coverage, data crowdsourced, route bukan jaminan aksesibilitas.  
**M. Juri:** “Apakah datanya dikurasi?”  
**N. Jawaban:** “Runtime mengambil POI dinamis dari OSM; quality mengikuti data sumber dan perlu validasi lapangan.”  
**O. Demo:** filter toilet/medical/hotel dekat lokasi; buka sumber/directions.

## 5.5 Money Recognition

**A. Masalah:** jamaah dapat kesulitan membedakan denominasi asing.  
**B. Tujuan:** foto beberapa uang, jumlahkan, konversi, dan bacakan.  
**C. Flow:** kamera → foto → proses multi-pass → result → TTS/rescan.  
**D. Input:** JPEG/frame kamera.  
**E. Processing:** detector 640×640; original/enhanced/tile; IoU merge; threshold; sum.  
**F. Output:** box/class/confidence, total SAR/IDR, suara.  
**G. Teknologi:** TFLite via ultralytics_yolo, Dart image, flutter_tts, exchange API.  
**H. File:** money_recognition_screen.dart; smart_multi_pass_detector.dart; model/labels.  
**I. Data flow:** pixels → tensor → detection rows → MoneyDetection → total → UI/TTS.  
**J. Why detector:** beberapa lembar/koin bisa berada pada satu foto; detector memberi kelas dan lokasi tiap objek.  
**K. Kelebihan:** inference lokal; 14 label; dedup antar-pass; TTS.  
**L. Keterbatasan:** no metrics, glare/fold/occlusion/counterfeit, kurs tidak selalu online, confidence bukan accuracy.  
**M. Juri:** “Berapa akurasinya?”  
**N. Jawaban:** “Repo belum menyimpan evaluation report, jadi saya hanya dapat menunjukkan confidence per detection dan 300 regression tests—bukan angka accuracy.”  
**O. Demo:** satu uang jelas dahulu, lalu dua denominasi; tunjukkan total dan suara.

## 5.6 BISINDO

**A. Masalah:** hambatan komunikasi dengan pengguna bahasa isyarat.  
**B. Tujuan:** mengenali kosakata terbatas menjadi teks/suara.  
**C. Flow:** kamera → landmark → sequence → GRU → stability → token → TTS.  
**D. Input:** live frames; dua tangan.  
**E. Processing:** CameraX/MediaPipe; 135 feature; window 48; GRU; gate .58/3.  
**F. Output:** salah satu 23 label, confidence, transcript, speech.  
**G. Teknologi:** Kotlin CameraX, MediaPipe Tasks Vision, EventChannel, tflite_flutter.  
**H. File:** sign_language folder; BisindoCameraHelper.kt; assets/models/bisindo.  
**I. Data flow:** pixels tetap native → 543 landmark values → 135 features → [1,48,135] → [1,23].  
**J. Why:** landmark mengurangi background sensitivity; GRU menangkap urutan gerak.  
**K. Kelebihan:** on-device, live, no frame upload found, stability/cooldown.  
**L. Keterbatasan:** 23 label, unknown accuracy, signer/lighting/occlusion, threshold mismatch, padding early frames.  
**M. Juri:** “Apakah ini penerjemah BISINDO?”  
**N. Jawaban:** “Belum; ini recognizer kosakata terbatas, bukan penerjemah bahasa bebas.”  
**O. Demo:** cahaya terang, torso/tangan terlihat, satu gesture known, tunggu indikator stabil.

## 5.7 Translator/STT/TTS

**A. Masalah:** hambatan Indonesia–Arab–Inggris.  
**B. Tujuan:** text/speech assistance sederhana.  
**C. Flow:** pilih bahasa → ketik/bicara → translate → tampil/bacakan.  
**D. Input:** text atau microphone.  
**E. Processing:** speech platform; ensure ML Kit language model; on-device translate.  
**F. Output:** text hasil dan TTS.  
**G. Teknologi:** google_mlkit_translation, speech_to_text, flutter_tts.  
**H. File:** translator/services dan translator_sheet.dart.  
**I. Data flow:** audio → OS STT → text → ML Kit → text → OS TTS.  
**J. Why:** ML Kit mengurangi kebutuhan mengirim teks ke backend HajiCare.  
**K. Kelebihan:** setelah download, translation local; tiga bahasa relevan.  
**L. Keterbatasan:** download awal, quality casual, STT/TTS device-dependent; jangan pakai sebagai keputusan medis/hukum.  
**M. Juri:** “Sepenuhnya offline?”  
**N. Jawaban:** “Terjemahan bisa lokal setelah model diunduh; STT/TTS offline bergantung engine perangkat.”  
**O. Demo:** siapkan model sebelumnya; gunakan teks singkat; tampilkan fallback quick phrase.

## 5.8 Prayer dan panduan haji

**A. Masalah:** jadwal/kiblat/panduan tersebar.  
**B. Tujuan:** konteks ibadah di aplikasi pendamping.  
**C. Flow:** lokasi → jadwal/countdown/kiblat/alarm; atau browse/search/bookmark doa.  
**D. Input:** coordinate/timezone/metode, preference; query konten.  
**E. Processing:** library adhan lokal; local notifications; repository local.  
**F. Output:** times, direction, alarm, 22 entries.  
**G. Teknologi:** adhan, timezone, compass, SharedPreferences, audio assets.  
**H. File:** prayer feature; core prayer services; hajj_dua feature.  
**I. Data flow:** GPS/cache → calculation → controller → UI/alarm; local list → repository → UI.  
**J. Why:** tetap berguna saat jaringan terbatas setelah lokasi siap.  
**K. Kelebihan:** local calculation, preference, readable Arabic/font, bookmark.  
**L. Keterbatasan:** location/method differences; compass interference; source texts not independently verified; no dua audio.  
**M. Juri:** “Sudah disahkan Kemenag?”  
**N. Jawaban:** “Data mencantumkan atribusi Kemenag, tetapi source primer/verifikasi formal tidak ada di repo, jadi belum saya klaim disahkan.”  
**O. Demo:** jadwal berikut/countdown; satu kategori/manasik; jangan berdebat fiqh.

## 5.9 Smartband lingkungan

**A. Masalah:** paparan kondisi lingkungan panas dapat perlu perhatian.  
**B. Tujuan:** menampilkan suhu/kelembapan/heat index sekitar.  
**C. Flow:** Bluetooth on → scan HajiCare Watch → connect → read/notify → status.  
**D. Input:** tiga characteristic string BLE.  
**E. Processing:** parse/validate; calculate heat index fallback; threshold environment.  
**F. Output:** °C, %, heat index, dingin/normal/panas.  
**G. Teknologi:** FlutterBluePlus; protokol ESP32/DHT11 yang diasumsikan.  
**H. File:** ble_service.dart; smartband_ldr_controller.dart/page.  
**I. Data flow:** sensor → firmware BLE (tidak ada di repo) → phone → GetX → UI.  
**J. Why BLE:** konsumsi daya dan jarak dekat sesuai wearable.  
**K. Kelebihan:** notify realtime, timeout, no fake sensor value.  
**L. Keterbatasan:** firmware/hardware/calibration absent; DHT11 lingkungan, bukan tubuh; placeholder vital UI.  
**M. Juri:** “Mengapa bukan smartwatch?”  
**N. Jawaban:** “Versi ini mengeksplorasi sensor lingkungan murah dan integrasi khusus; kami belum membuktikan keunggulan atas smartwatch, dan tidak mengukur vital.”  
**O. Demo:** hanya jika perangkat benar-benar ada; tampilkan disconnect/timeout jujur.

## 5.10 Notification dan bantuan

**A. Masalah:** jamaah perlu menghubungi pendamping dengan konteks.  
**B. Tujuan:** inbox realtime, invitation, pesan/pickup.  
**C. Flow:** compose/request → target room/user → Firestore notification → listener recipient.  
**D. Input:** title/message/type/scope/location.  
**E. Processing:** callable, recipient discovery, atau fallback direct write.  
**F. Output:** document notification dan UI unread/read.  
**G. Teknologi:** Firestore/callable.  
**H. File:** notification_service.dart; notification_controller.dart; assistance_request_service.dart.  
**I. Data flow:** UI → service → functions/Firestore → snapshots → inbox.  
**J. Why:** Firestore cocok untuk inbox realtime sederhana.  
**K. Kelebihan:** scope user/room; status read; invitation.  
**L. Keterbatasan:** bukan OS push; rules/general notification risk; assistance lifecycle local.  
**M. Juri:** “Kalau app tertutup?”  
**N. Jawaban:** “Tanpa FCM, kami belum menjamin OS-level delivery; itu gap roadmap.”  
**O. Demo:** dua akun aktif dan inbox Firestore.

## 5.11 Profile/admin/settings

**A. Masalah:** identitas/kondisi penting untuk koordinasi; admin perlu overview.  
**B. Tujuan:** kelola profil, preference, room/SOS overview.  
**C. Flow:** edit → validation → Firestore; admin claim → dashboard queries.  
**D. Input:** nama, nomor porsi, NIK/paspor opsional, blood/allergy/condition/contact.  
**E. Processing:** local validation dan set merge.  
**F. Output:** profile/admin cards.  
**G. Teknologi:** Auth, Firestore, GetX, SharedPreferences.  
**H. File:** profile_controller.dart; admin_room_controller.dart; app_settings_controller.dart.  
**I. Data flow:** UI → Firestore → reload/stream.  
**J. Why:** data emergency berada di profil yang sama.  
**K. Kelebihan:** preference accessibility dan data emergency.  
**L. Keterbatasan:** rules leakage, NIK/passport mismatch, no deletion/retention.  
**M. Juri:** “Mengapa menyimpan NIK?”  
**N. Jawaban:** “Itu opsional dan saat ini belum siap produksi; prinsip minimisasi harus menilai apakah benar diperlukan.”  
**O. Demo:** gunakan data fiktif; jangan tampilkan PII nyata.

## 6. AI/ML dari nol

### Training vs inference

- **Training:** model belajar dari dataset; tidak ada script/log training yang memadai di repo.
- **Inference:** model terlatih memproses input baru; inilah yang diimplementasikan di app.

Jangan menyimpulkan cara training hanya dari file model.

### Classification vs detection vs landmark vs sequence

| Konsep | Analogi | Contoh HajiCare |
|---|---|---|
| Classification | Memilih nama untuk satu isi kotak | BISINDO memilih 1 dari 23 untuk satu sequence |
| Object detection | Mencari beberapa benda dan menggambar kotak | Uang SAR |
| Landmark | Mengubah gambar tangan menjadi titik sendi | MediaPipe hands |
| Sequence classification | Membaca beberapa frame seperti kata dari rangkaian huruf | GRU BISINDO |

### CNN, YOLO, MediaPipe, GRU

- **CNN:** keluarga jaringan yang efektif mengekstrak pola spasial gambar. Model YOLO umumnya berbasis operasi convolution.
- **YOLO:** detector satu tahap yang memprediksi box dan class dalam satu inference.
- **MediaPipe Hand Landmarker:** model/pipeline yang menghasilkan 21 titik tangan dan handedness; bukan penerjemah BISINDO.
- **GRU:** recurrent sequence model dengan gate untuk menyimpan/melupakan informasi urutan.

### Mengapa GRU, bukan LSTM?

Fakta: model artifact menggunakan struktur yang konsisten dengan GRU dan nama file menyebut GRU. Alasan historis tidak ada. Engineering rationale: GRU lebih sederhana daripada LSTM, parameter/gate lebih sedikit, sehingga sering cocok untuk inference mobile dengan sequence pendek. Ini harus disebut rationale, bukan hasil benchmark HajiCare.

### TFLite/LiteRT

TFLite adalah format/runtime mobile yang sekarang dilanjutkan Google sebagai LiteRT. HajiCare memakai file .tflite dan package interpreter/plugin. Manfaat: model dibundel, latency rendah, dan kamera tidak perlu dikirim ke server. Trade-off: app size, kompatibilitas operator, optimasi device, dan update model.

### FP32, Float16, INT8

- FP32: 32-bit floating point.
- Float16: bobot dapat disimpan 16-bit untuk ukuran lebih kecil; I/O bisa tetap FP32.
- INT8: integer 8-bit; memerlukan quantization/calibration dan bisa mengubah accuracy.

Model uang bernama best_float16 dan mempunyai I/O FP32 dengan dequantize ops; jangan menyebut INT8. Model BISINDO bernama float32 dan I/O FP32.

### Metric yang seharusnya ada

- classification/sequence: accuracy, per-class precision/recall/F1, confusion matrix, signer-independent test.
- detection: precision, recall, mAP@50, mAP@50–95, per-class AP.
- mobile: latency p50/p95, memory, battery, crash rate.

Tidak satu pun angka tersebut dapat diklaim dari repo sekarang.

### Overfitting dan leakage

Overfitting: model hafal kondisi training tetapi buruk pada orang/latar baru. Data leakage: orang/frame/scene yang hampir sama masuk train dan test sehingga metric palsu tinggi. Untuk BISINDO, signer-independent group split adalah target yang tepat karena signer yang sama tidak boleh bocor antarsplit; tetapi metadata saja belum membuktikan hasil.

## 7. Novelty yang defensibel

### Product novelty

Satu alur haji menggabungkan companion safety, navigasi, ibadah, dan aksesibilitas. Klaimnya adalah integrasi kontekstual, bukan fitur tunggal baru.

### Technical integration novelty

- kamera uang → local detection → total/currency/TTS;
- native MediaPipe → vector kecil → Flutter GRU → token/TTS;
- Firestore room/location/SOS bersama map;
- BLE environment telemetry sebagai eksperimen context awareness.

### UX novelty

Output visual dipasangkan dengan audio, quick phrase, text scaling, locale, dan tombol bantuan. Namun efektivitas untuk lansia/disabilitas belum diuji secara formal.

### Yang jangan diklaim

- pertama di dunia/Indonesia;
- paling akurat;
- menggantikan aplikasi resmi;
- siap jutaan user;
- diagnosis/pencegahan pasti;
- seluruh bahasa BISINDO/SIBI.

## 8. Competitor/alternatif — jawaban tanpa mengarang riset

Alternatif umum: Google Maps untuk navigasi, Google Lens/vision apps untuk gambar, Google Translate untuk bahasa, WhatsApp/location sharing untuk koordinasi, aplikasi resmi haji untuk layanan pemerintah, smartwatch untuk sensor, dan aplikasi bahasa isyarat khusus.

### “Kalau Google Lens sudah ada?”

“Kami tidak mengklaim lebih akurat. Nilai HajiCare adalah alur khusus jamaah: denominasi SAR, penjumlahan, estimasi IDR, dan output suara berada bersama fitur pendamping. Benchmark langsung belum dilakukan.”

### “Kalau Google Translate sudah ada?”

“Google Translate lebih matang sebagai penerjemah. HajiCare mengintegrasikan quick phrase, room/SOS, dan BISINDO terbatas dalam konteks perjalanan haji. Kami memanfaatkan ML Kit, bukan bersaing pada skala model.”

### “Kalau smartwatch sudah ada?”

“Smartwatch komersial jauh lebih matang. Eksperimen kami hanya telemetri lingkungan DHT11 melalui BLE, bukan vital monitoring; nilai risetnya adalah integrasi konteks, tetapi keunggulan produk belum terbukti.”

## 9. Nilai Islam dan konteks OASE

### Yang didukung proyek

- konteks langsung ibadah haji/umrah;
- keselamatan, kemudahan, aksesibilitas, koordinasi, dan bantuan antarpengguna;
- jadwal salat, kiblat, panduan manasik/doa;
- aplikasi menyatakan tidak menggantikan petugas, layanan darurat, atau tenaga medis.

### Yang tidak didukung dokumen

- ayat Qur’an/hadis khusus sebagai dasar proposal;
- sumber Executive Summary/OASE;
- verifikasi ahli agama;
- statistik jamaah/disabilitas.

### Jawaban natural

“Relevansi Islam HajiCare bukan karena teknologi menggantikan ibadah, tetapi karena teknologi menjadi alat bantu agar jamaah lebih aman, mudah berkoordinasi, dan lebih aksesibel saat beribadah. Di level nilai, ini selaras dengan kemaslahatan dan tolong-menolong sebagai framing umum. Saya sengaja tidak mengutip ayat atau hadis tertentu karena proposal/sumber primer tidak tersedia di repository untuk saya verifikasi.”

## 10. Red-team: kelemahan yang harus Anda kuasai

1. Dataset dan metric ML tidak ada.
2. Hanya 23 kosakata BISINDO.
3. Threshold BISINDO tidak konsisten.
4. SIBI/YOLO 42 kelas tidak aktif.
5. Smartband tidak mengukur vital dan firmware tidak ada.
6. GPS bergantung izin, perangkat, internet, kondisi area padat.
7. Tidak ada background distance alert/FCM.
8. Assistance lifecycle tidak sepenuhnya durable.
9. External APIs memiliki quota dan coverage risk.
10. Firestore rules kritis terlalu permisif.
11. Privacy policy tidak sesuai enforcement.
12. Data deletion/retention/consent belum lengkap.
13. NIK/passport write dapat ditolak rules.
14. App Check belum ada.
15. applicationId/signing/pilot belum production-ready.
16. Content Kemenag/hadis belum independently verified.
17. Belum ada usability/pilot evidence.

Pola jawab:

“Ya, itu keterbatasan versi saat ini. Yang sudah kami lakukan adalah X. Dampaknya adalah Y. Sebelum pilot kami akan melakukan Z, dan kami tidak akan mengklaim lebih jauh sebelum bukti tersedia.”

## 11. Glossary HajiCare

| Istilah | Definisi sederhana | Definisi teknis + contoh HajiCare |
|---|---|---|
| Frontend | Bagian yang disentuh pengguna | Flutter screens/widgets dan state yang merender UI |
| Backend | Bagian cloud yang menjaga data/logika | Firebase Auth, Firestore, callable Functions |
| API | Cara dua komponen berbicara | ORS HTTP atau callable createRoom |
| REST | Gaya API resource lewat HTTP | External exchange/map APIs; bukan backend bisnis sendiri |
| JSON | Format key-value | response kurs, labels/config model |
| Flutter | Toolkit UI | Seluruh UI Android HajiCare |
| Dart | Bahasa Flutter | controller/service/widget |
| Kotlin | Bahasa native Android | CameraX/MediaPipe BISINDO |
| GetX | State, DI, navigation | Rx/Obx, Binding, GetPage |
| Controller | Pengatur state/flow | HajiCareController, MapController |
| Binding | Pabrik dependency untuk route | BisindoBinding memasang service/controller |
| Service | Adapter operasi | BleService, RouteService, TranslationService |
| Repository | Akses koleksi data | HajjDuaRepository |
| State management | Cara state mengubah UI | Rx value diobservasi Obx |
| Dependency injection | Memberi dependency dari luar | Get.lazyPut/Get.find atau constructor test |
| Async | Operasi selesai kemudian | HTTP, Firebase, inference, permission |
| Stream | Data berulang sepanjang waktu | Firestore snapshots, GPS, BLE notify |
| Inference | Model menjawab input baru | foto uang → detections |
| Training | Model belajar dari dataset | Artifact prosesnya tidak ada di repo |
| Dataset | Kumpulan contoh belajar/evaluasi | BISINDO signer data; detail unknown |
| Annotation | Label ground truth | box uang atau label sequence; unknown |
| Preprocessing | Menyiapkan input model | wrist-centering dan scaling landmark |
| Augmentation | Variasi data training | rotasi/cahaya dsb.; unknown pada project |
| Epoch | Satu putaran dataset training | unknown |
| Batch | Sekelompok sample per step | input BISINDO batch dimension 1 saat inference |
| Learning rate | Besar langkah optimasi | unknown |
| Overfitting | Hafal training | risiko signer/background |
| Underfitting | Model terlalu sederhana/belum belajar | perlu dilihat dari metric, yang belum ada |
| Precision | Dari prediksi positif, berapa benar | perlu per kelas; unknown |
| Recall | Dari objek nyata, berapa ditemukan | penting untuk uang; unknown |
| IoU | Tumpang tindih box | merge detection lintas pass pada 0.50 |
| mAP@50 | rata-rata AP pada IoU 0.50 | metric detector; unknown |
| mAP@50–95 | AP dirata-rata banyak IoU | lebih ketat; unknown |
| Confusion matrix | tabel kelas benar vs prediksi | perlu BISINDO; tidak ada |
| Classification | pilih kelas | GRU memilih 23 label |
| Object detection | kelas + lokasi box | uang SAR |
| Bounding box | kotak posisi objek | deteksi tiap uang |
| YOLO | detector satu tahap | plugin uang; artifact sign 42 class |
| Keypoint/landmark | titik sendi/fitur | 21 titik per tangan MediaPipe |
| MediaPipe | toolkit perception on-device | Hand/Pose Landmarker native |
| GRU | jaringan temporal bergate | membaca 48 timestep BISINDO |
| Sequence | urutan timestep | gerak tangan sepanjang frame |
| Tensor | array multidimensi | [1,48,135] |
| TFLite | format/runtime model mobile lama/populer | tiga .tflite dalam assets |
| LiteRT | nama generasi lanjut runtime TFLite Google | istilah payung modern; code package masih TFLite |
| FP32 | float 32-bit | input/output BISINDO |
| Float16 | float 16-bit | indikasi bobot model uang |
| INT8 | integer 8-bit quantized | tidak terbukti dipakai model aktif |
| Quantization | mengurangi presisi/ukuran model | perlu benchmark accuracy/latency |
| Confidence | keyakinan untuk satu prediksi | bukan accuracy dataset |
| Threshold | batas menerima prediksi | uang .65; BISINDO controller .58 |
| Stability filter | harus konsisten beberapa kali | BISINDO 3 prediksi sama |
| BLE | Bluetooth hemat energi | Watch characteristic notifications |
| ESP32 | mikrokontroler wireless | diasumsikan HajiCare Watch; firmware absent |
| Sensor | alat mengukur lingkungan/fisik | DHT11 suhu/kelembapan lingkungan |
| Heat index | rasa panas gabungan suhu+RH | dihitung Rothfusz fallback |
| Latency | waktu input sampai output | belum ada benchmark lintas perangkat |
| FPS | frame per detik | target BISINDO sekitar 15 |
| Callable Function | fungsi cloud via SDK | createRoom, sendNotification |
| Firestore Rules | policy akses client | saat ini memiliki gap kritis |
| Custom claim | atribut role pada token auth | admin/pendamping privileged role |
| App Check | attestation aplikasi/perangkat | direkomendasikan, belum aktif |
| Haversine | jarak garis lurus di bumi | jarak antar coordinate |
| TTS/STT | text-to-speech/speech-to-text | audio output/input via OS |

## 12. Checklist belajar malam ini

### Putaran 1 — 25 menit

- Ucapkan definisi 1 kalimat, 30 detik, 1 menit tanpa membaca.
- Gambar: Flutter → Firebase/API/native → model/device.
- Hafal empat alur: room/location, SOS, Money, BISINDO.

### Putaran 2 — 35 menit

- Jelaskan 1–48–135–23.
- Jelaskan object detection vs landmark vs GRU.
- Jelaskan backend, API, database, local inference.
- Jelaskan online/offline matrix.

### Putaran 3 — 25 menit

- Baca seluruh klaim berbahaya di claim audit.
- Latih lima jawaban keterbatasan tanpa defensif.
- Latih keamanan: apa ada, gap, remediation.

### Putaran 4 — 35 menit

- Latih naskah 5 menit dengan timer.
- Jalankan demo plan dan failure plan.
- Baca 15 killer questions.

### Lima hal yang wajib hafal

1. Money: [1,640,640,3] → [1,300,6], 14 labels, .50/.65, IoU .50.
2. BISINDO: [1,48,135] → [1,23], 15 FPS nominal, .58 + 3 stabil.
3. Smartband: DHT11 environment only, BLE, no firmware proof/no vital.
4. Backend: Firebase Auth + Firestore + callable Functions, no custom REST.
5. Evidence: 300 tests pass; 6 analyzer deprecation infos; no ML metrics.

## 13. Self-test sebelum masuk ruangan

Anda siap jika dapat menjawab tanpa catatan:

- Apa yang terjadi dari tombol capture uang hingga suara keluar?
- Mengapa BISINDO membutuhkan urutan dan apa isi 135 fitur?
- Mana backend, API, database, native layer, dan model?
- Apa yang tetap berjalan ketika internet mati?
- Apakah smartband mengukur kesehatan tubuh?
- Berapa accuracy model dan mengapa Anda tidak menyebut angka?
- Apakah distance alert tetap hidup di background?
- Apa celah keamanan terbesar dan mitigasinya?
- Apa novelty tanpa berkata “belum pernah ada”?
- Apa hubungan Islam tanpa membuat dalil baru?
