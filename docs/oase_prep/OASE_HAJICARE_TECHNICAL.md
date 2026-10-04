# OASE HajiCare — Technical Architecture Guide

Tanggal audit: 25 September 2026  
Versi aplikasi: 0.1.0+1  
Platform yang dibuktikan repo: Android/Flutter.

## 1. Jawaban teknis paling pendek

**Backend HajiCare menggunakan apa?**  
Firebase Authentication, Cloud Firestore, dan callable Cloud Functions Node.js. HajiCare tidak mempunyai REST server milik sendiri. Aplikasi juga memanggil beberapa API HTTPS pihak ketiga untuk peta, POI, geocoding, routing, dan kurs.

**AI berjalan di mana?**  
Model Money Recognition dan BISINDO berjalan di perangkat dari aset TFLite. MediaPipe/CameraX berada pada native Android untuk menghasilkan landmark BISINDO. Model terjemahan ML Kit juga berjalan on-device setelah language pack diunduh.

**Database apa?**  
Cloud Firestore untuk data akun/room/lokasi/SOS/notifikasi; SharedPreferences untuk preferensi/cache kecil; local JSON dan model assets untuk label/konfigurasi. Tidak ditemukan SQLite atau Hive.

## 2. Arsitektur end-to-end nyata

    Pengguna Android
          |
          v
    Flutter UI / GetMaterialApp
          |
          +--> GetX Route + Binding + Controller (reactive state)
          |          |
          |          +--> Feature Service / Repository
          |                    |
          |                    +--> Firebase Auth
          |                    +--> Cloud Firestore realtime
          |                    +--> Callable Cloud Functions
          |                    +--> API HTTPS pihak ketiga
          |                    +--> SharedPreferences / local assets
          |
          +--> Native Android Kotlin
          |          |
          |          +--> CameraX
          |          +--> MediaPipe Pose/Hand Landmarker
          |          +--> PlatformView + MethodChannel + EventChannel
          |
          +--> On-device ML
                     |
                     +--> YOLO-family TFLite: uang SAR
                     +--> GRU TFLite: BISINDO 23 kelas
                     +--> ML Kit translation model
          |
          +--> Perangkat/OS
                     |
                     +--> GPS, compass, microphone, TTS
                     +--> Camera
                     +--> BLE HajiCare Watch/DHT11
                     +--> Local notification/alarm

### Batas komponen

| Istilah | Dalam HajiCare |
|---|---|
| Frontend | Widget/screen Flutter, state GetX, form, dialog, map, camera overlay |
| Backend | Firebase Auth/Firestore serta Cloud Functions di functions/ |
| API | Kontrak pemanggilan: callable Firebase atau HTTP pihak ketiga |
| Database | Firestore cloud; SharedPreferences bukan database relasional |
| Native layer | Kotlin CameraX/MediaPipe dan channel ke Flutter |
| Local inference | TFLite/ML Kit memproses data pada perangkat tanpa server model HajiCare |
| Model | File parameter hasil training; bukan kode training dan bukan database |

## 3. Stack dan konfigurasi

| Area | Teknologi/dependency | Fungsi |
|---|---|---|
| UI | Flutter, Dart, Material, google_fonts | Aplikasi lintas ukuran layar Android |
| State/DI/navigation | GetX 4.7.3 | Observable, controller, binding, route |
| Auth | firebase_auth, google_sign_in | Email/password dan Google |
| Database | cloud_firestore | Stream realtime dan persistence cloud |
| Backend | cloud_functions; Node 22 functions | Operasi tepercaya/callable |
| GPS | geolocator, geocoding | Koordinat, stream posisi, reverse geocoding |
| Map | flutter_map, latlong2 | Tile/marker/polyline |
| AI uang | ultralytics_yolo, image | Detection dan preprocessing multi-pass |
| AI BISINDO | tflite_flutter | Interpreter GRU TFLite |
| Native vision | CameraX 1.3.4; MediaPipe Tasks Vision 0.10.14 | Frame kamera dan landmark |
| Translation | google_mlkit_translation | Terjemahan on-device |
| Speech | speech_to_text, flutter_tts | STT/TTS perangkat |
| BLE | flutter_blue_plus | Scan/connect/read/notify wearable |
| Ibadah | adhan, flutter_compass, hijri, timezone | Jadwal, kiblat, kalender/timezone |
| Alarm | flutter_local_notifications, audioplayers | Adzan lokal |
| Local persistence | shared_preferences | Preference/cache kecil |

Konfigurasi Android:

- namespace/applicationId masih com.example.hajicare.
- compileSdk 36; Java/Kotlin JVM 17.
- build release hanya signed jika android/key.properties tersedia.
- aset .tflite dan .task tidak dikompresi.
- ABI: arm64-v8a, armeabi-v7a, x86, x86_64.
- permissions: Internet/network, camera, vibration, audio, fine/coarse location, notification, boot, wake lock, exact alarm, foreground media playback, dan Bluetooth/BLE.

File: pubspec.yaml; android/app/build.gradle.kts; android/app/src/main/AndroidManifest.xml.

## 4. Arsitektur Flutter dan GetX

### Struktur nyata

- lib/core: config, constants, locales, models, routes, services, global state, theme, utils, widgets.
- lib/features: auth, communication, dashboard, hajj_dua, map, money, notification, onboarding, prayer, profile, room, sign_language, smartband, sos, splash, translator.
- functions: callable backend.
- android/app/src/main/kotlin: native BISINDO camera/landmarks.
- assets/models: model, label, dan config.

### Peran layer

- **Screen/widget:** menangkap gesture pengguna dan merender state.
- **Binding:** mendaftarkan dependency secara lazy pada route.
- **Controller:** menyimpan state observable dan mengatur flow UI/async.
- **Service:** akses platform, Firebase, HTTP, BLE, atau model.
- **Model/entity:** bentuk data seperti RoomModel, JamaahData, MoneyDetection.
- **Repository:** hanya digunakan jelas pada HajjDuaRepository; proyek bukan clean architecture murni.

### Contoh call flow: gabung room

    JoinRoomScreen
      -> JoinRoomController
      -> RoomService / RoomCommandService
      -> callable joinRoomByCode
      -> Cloud Function transaction Firestore
      -> result roomId/role/memberName
      -> HajiCareController sync + SharedPreferences room id
      -> GetX navigation/dashboard berubah

Catatan: RoomCommandService memiliki direct Firestore fallback. Ini membantu demo saat callable belum tersedia, tetapi melemahkan security boundary dan menimbulkan perilaku berbeda antar deployment.

### Contoh call flow: perubahan state realtime

    Firestore snapshot
      -> RoomQueryService stream
      -> HajiCareController subscription
      -> Rx/RxList berubah
      -> Obx widget rebuild

### Lifecycle

- Controller GetX membatalkan stream/timer pada onClose pada banyak fitur.
- HajiCareController memegang auth, room, GPS, dan SOS sehingga tanggung jawabnya besar.
- BISINDO native menghentikan kamera pada lifecycle pause dan menghidupkan kembali sesuai channel/lifecycle.
- Money screen menjeda YOLO preview setelah foto sebelum multi-pass.
- Async worker Dart compute dipakai untuk enhancement foto agar pekerjaan CPU berat tidak seluruhnya dilakukan di UI isolate.

### Jawaban “Kenapa Flutter?”

Faktual: codebase sudah memakai satu UI Flutter untuk banyak fitur, integrasi Firebase/ML/BLE, dan tetap dapat menjangkau native Android melalui platform channel. Keuntungan engineering: satu codebase UI, komponen konsisten, hot reload, dan ekosistem plugin. Batasnya: integrasi kamera/MediaPipe khusus memerlukan Kotlin; plugin/dependency native tetap harus dikelola.

### Jawaban “Kenapa GetX?”

Faktual: project memakai GetMaterialApp, GetPage, Binding, lazyPut/put, Rx, Obx, dan Get.find. GetX menyatukan route, DI, dan reactive state sehingga prototipe cepat. Trade-off: global locator dan controller besar dapat menyembunyikan dependency, sehingga testability memerlukan dependency injection eksplisit dan disiplin lifecycle.

### “Kenapa bukan React Native?”

Jawaban aman: itu bukan hasil benchmark dalam repo. Pilihan Flutter sesuai implementasi tim karena UI, plugin, dan jalur native Android sudah terbentuk. Jangan mengklaim Flutter secara universal lebih cepat/aman dari React Native.

## 5. Backend Firebase

### Komponen

1. Firebase Authentication: session dan identitas UID.
2. Cloud Firestore: dokumen realtime.
3. Callable Cloud Functions, region asia-southeast2, Node 22.
4. Firestore Security Rules dan indexes.

### Callable yang diekspor

- ensureUserProfile
- reviewPendampingAccess
- createRoom
- joinRoomByCode
- leaveRoom
- updateRoomSettings
- removeJamaah
- inviteJamaah
- respondInvitation
- deleteRoom
- triggerSos
- transitionSos
- sendNotification
- sendPickupRequest
- sendCompanionMessage

Entry point: functions/index.js.  
Client adapter: lib/core/services/trusted_backend_service.dart.

### Data collections yang ditemukan

| Collection/path | Data utama |
|---|---|
| users/{uid} | profil, role display, room aktif, lokasi, status SOS, medis/identitas |
| rooms/{roomId} | nama, kode, creator, pendamping, safeRadius, status |
| rooms/{roomId}/members/{uid} | role room, nama, lokasi, status SOS |
| invitations/{id} | undangan room dan status |
| notifications/{id} | sender/recipient/scope/type/message/read |
| sos_events/{id} | pemilik, room, waktu, lokasi, status/responder |
| active_sos/{uid} | pointer SOS aktif untuk operasi server |
| activities/{id} | audit/activity feed server |
| roomCodes/{code} | mapping kode ke room |
| pairings/{id} | struktur lama/terbatas; write ditutup rules |

### Tidak ada REST server tradisional

Callable Firebase bukan endpoint REST yang dikelola aplikasi seperti /api/rooms. SDK Firebase mengirim request callable, membawa auth context, dan backend mengembalikan object. API HTTP pihak ketiga tetap REST-like, tetapi bukan backend bisnis HajiCare.

### Deployment yang dapat dan tidak dapat dibuktikan

- Kode functions/rules/index ada: terbukti.
- Project ID Firebase client ada: terbukti.
- Deployment rules/functions terbaru, custom claim account, atau App Check enforcement: **BELUM TERBUKTI DARI CODEBASE/DOKUMEN**.

## 6. Inventaris API/integrasi external

| Integrasi | Method/endpoint | Auth/input | Output | Ketergantungan/failure |
|---|---|---|---|---|
| Firebase callable | SDK cloud_functions, asia-southeast2 | Firebase auth + map data | Map hasil/error | Internet, deployment, token |
| Firestore | SDK native Firebase | UID/rules; document/query | Snapshot realtime | Internet/cache SDK/rules |
| CARTO tile | GET basemaps.cartocdn.com/... | API key query dari dart-define/default | Raster tile | Internet/key/quota; fallback OSM tile |
| OSM tile | GET tile.openstreetmap.org | Tanpa key | Raster tile | Internet/policy/quota |
| Overpass | POST tiga endpoint interpreter | Query OSM + User-Agent | JSON elements/POI | Internet, timeout; endpoint fallback; memory cache 5 menit |
| Photon | GET photon.komoot.io/api | query, limit | JSON places | Timeout 6 detik; fallback Nominatim/native |
| Nominatim | GET nominatim.openstreetmap.org/search | query; User-Agent | JSON places | Internet/rate policy |
| Native geocoding | plugin geocoding | text/coordinate | platform placemark | Device service |
| OpenRouteService | POST api.heigit.org/.../foot-walking/geojson | Authorization ORS key; coordinates JSON | GeoJSON route | Internet/key; timeout 18 detik |
| OSM routing fallback | GET routing.openstreetmap.de/routed-foot/route/v1/driving | coordinates query | OSRM-like route JSON | Internet/public capacity |
| Exchange rate | GET open.er-api.com/v6/latest/SAR | Tanpa auth | JSON rate IDR | 8 detik; cache 12 jam; user rate fallback |
| Google Maps external | URL search/directions | coordinate/query | App/browser eksternal | Google Maps/browser/internet |
| ML Kit model manager | SDK | language codes | download status/model | Internet pertama kali; inference lokal kemudian |
| Platform STT/TTS | OS/plugin | audio/text + locale | recognized text/speech | Izin/engine/language pack; online/offline device-dependent |

Semua endpoint web aktif yang ditemukan memakai HTTPS. Tidak ada certificate pinning.

## 7. Storage dan lifecycle data

### Firestore cloud

Data sensitif:

- nama, email, nomor porsi, NIK, paspor;
- golongan darah, alergi, kondisi, kontak darurat;
- lokasi dan timestamp;
- membership room, pesan/notifikasi, SOS.

Lifecycle: dibuat/diubah oleh client/callable; di-stream secara realtime; beberapa room/invitation dibersihkan oleh functions. Tidak ada flow delete-account/total erasure. Retention policy tidak ditemukan.

### SharedPreferences

Dipakai antara lain untuk:

- onboarding, remember-me flag, role dan room cache;
- theme, locale, text scale;
- prayer location cache (<7 hari), metode/sound preference;
- exchange rate dan waktu update (12 jam);
- map search history;
- bookmark/recent/text scale panduan doa.

SharedPreferences bukan storage terenkripsi. Password tidak disimpan oleh LoginController; remember-me terutama mengelola flow session/cache sementara Firebase Auth menangani credential session.

### Local assets

- model/labels/config AI;
- 22 entri doa dalam Dart source;
- dua audio adzan;
- fonts dan icon.

### Cache

- POI: in-memory sekitar 5 menit.
- Exchange rate: SharedPreferences 12 jam.
- Prayer location: SharedPreferences maksimal 7 hari.
- Firestore dapat mempunyai behavior cache SDK, tetapi repo tidak mengonfigurasi kebijakan khusus sehingga jangan menjanjikan offline synchronization tertentu.

## 8. Money Recognition — pipeline teknis

### Arsitektur

    Uang SAR di depan kamera
      -> YOLOView preview
      -> capturePhoto; fallback captureFrame
      -> pause camera
      -> Pass 1: original image
      -> bila perlu Pass 2: contrast-enhanced JPEG
      -> bila perlu Pass 3: empat tile overlapping
      -> detection boxes + class + confidence
      -> merge same class jika IoU >= 0.50
      -> threshold / cross-pass confirmation
      -> jumlah nominal SAR
      -> konversi IDR dari cache/API/user setting
      -> UI result + TTS Indonesia

### Model yang dibuktikan

- File: assets/models/best_float16.tflite, sekitar 5 MB.
- Runtime: ultralytics_yolo, YOLOTask.detect.
- Input tensor: [1,640,640,3] Float32.
- Output tensor: [1,300,6] Float32.
- 14 kelas: denominasi one/five/ten/twenty/fifty/one hundred/two hundred/five hundred riyal serta one/five/ten/twenty five/fifty halalas sebagaimana labels.txt.

### Threshold/post-processing

- candidate threshold: 0.50.
- final threshold: 0.65.
- cross-pass IoU: 0.50.
- candidate yang muncul pada minimal dua pass dapat memperoleh boost +0.10.
- pass enhancement dijalankan bila tidak ada hasil, confidence borderline <0.80, atau banyak objek; kasus satu objek besar confidence >=0.90 dapat melewati pass tambahan.

### Apa arti IoU

Intersection-over-Union membandingkan luas irisan dua bounding box dengan luas gabungannya. Dalam HajiCare, IoU membantu memutuskan apakah hasil dari foto original/enhanced/tile adalah uang fisik yang sama, agar total tidak dihitung ganda.

### Data flow class

- UI: lib/features/money/screens/money_recognition_screen.dart
- Engine multi-pass: smart_multi_pass_detector.dart
- Entity: money_detection.dart
- Label/nominal: riyal_currency_helper.dart dan assets/models/labels.txt
- Kurs: currency_rate_service.dart
- Speech: money_tts_service.dart
- Model: assets/models/best_float16.tflite

### Online/offline

- Detection: lokal/offline setelah app terpasang.
- Kurs terbaru: internet; jika gagal memakai cache/default/user rate.
- TTS: engine perangkat; jangan janjikan 100% offline.

### Yang tidak terbukti

Dataset, arsitektur/versi YOLO spesifik, training, augmentation, annotation process, metric, device benchmark, dan alasan historis 640×640. 640×640 dapat dijelaskan sebagai kompromi umum detail vs latency, tetapi labeli sebagai engineering rationale, bukan catatan training.

## 9. BISINDO — pipeline teknis aktif

### Arsitektur lintas Flutter/native

    Kamera depan CameraX (fallback belakang)
      -> ImageAnalysis, keep-only-latest, target sekitar 15 FPS
      -> MediaPipe HandLandmarker + PoseLandmarker
      -> sinkronisasi result berdasarkan timestamp
      -> frame 543 angka melalui EventChannel
         33 pose + 468 face zero + 21 left hand + 21 right hand
      -> Flutter LandmarkStreamBuffer
         window 48, mulai inferensi pada 24 frame, stride 2, throttle 70 ms
      -> BisindoPreprocessor mengambil bagian tangan
      -> 135 fitur per frame, normalisasi wrist/palm scale, clip [-5,5]
      -> pad awal/ambil 48 frame terbaru
      -> GRU TFLite [1,48,135]
      -> probability [1,23]
      -> gate runtime confidence 0.58
      -> tiga prediksi label sama berturut-turut
      -> duplicate cooldown 1.2 detik
      -> token teks di UI
      -> TTS Indonesia

### Arti [1,48,135]

- **1**: batch size satu sequence pada satu inference.
- **48**: jumlah timestep/frame yang dilihat model.
- **135**: jumlah fitur numerik pada setiap timestep.

135 terdiri dari:

- 63 left-hand local XYZ = 21 landmark × 3 koordinat;
- 63 right-hand local XYZ = 21 × 3;
- 2 presence flags;
- 4 wrist XY global relatif pusat gambar;
- 3 selisih XYZ antara wrist kiri dan kanan.

Jumlah: 63 + 63 + 2 + 4 + 3 = 135.

### Arti output [1,23]

Satu vector berisi score/probability untuk 23 label. Top score dipilih. Daftar kelas: Air, Apa, Apa Kabar, Bagaimana, Baik, Berapa, Berdiri, Dia, Dimana, Duduk, Halo, Kalian, Kami, Kamu, Kapan, Kemana, Kita, Makan, Mandi, Minum, Siapa, Terima Kasih, Tuli.

### Mengapa temporal/GRU

Beberapa isyarat dibedakan bukan hanya bentuk tangan pada satu frame, tetapi urutan arah, kecepatan, dan perubahan posisi. Landmark mengubah gambar menjadi rangka koordinat; GRU membaca urutan rangka itu. Jika hanya satu foto, konteks geraknya hilang.

Pada target 15 FPS, 48 frame sekitar 3,2 detik. Runtime aktif sebenarnya dapat mulai saat 24 frame tersedia dan mem-pad frame awal sampai 48; jadi jangan berkata selalu menunggu 3,2 detik penuh.

### Normalisasi

Setiap tangan dibuat relatif ke wrist landmark 0, lalu dibagi mean jarak 2D dari wrist ke MCP 5/9/13/17. Ini mengurangi pengaruh posisi dan skala tangan di gambar. Nilai di-clip ke [-5,5] untuk membatasi outlier. Posisi wrist global dan relasi antar tangan dipertahankan agar model masih tahu konfigurasi kedua tangan.

### Confidence dan stability

- metadata model_config: 0.78;
- service menandai candidate internal recognized mulai 0.48;
- controller production binding menerima minimal 0.58;
- tiga prediksi sama berturut-turut sebelum commit;
- label sama ditekan selama cooldown 1200 ms;
- absence timeout 1000 ms.

Ini konfigurasi yang tidak sinkron. Saat menjawab juri, sebut gate produksi 0.58 + 3 stabil, lalu akui metadata 0.78 perlu dirapikan.

### File utama

- Flutter screen: lib/features/sign_language/screens/bisindo_screen.dart
- Binding/gate: bisindo_binding.dart
- Controller: bisindo_recognition_controller.dart
- Buffer: landmark_stream_buffer.dart
- Preprocessing: bisindo_preprocessor.dart
- Inference: bisindo_inference_service.dart
- Camera service/channel: bisindo_camera_landmark_service.dart
- TTS: bisindo_tts_service.dart
- Kotlin: MainActivity.kt; BisindoCameraHelper.kt; BisindoCameraPreview.kt
- Model/config/labels: assets/models/bisindo/
- MediaPipe Android assets: android/app/src/main/assets/

### Camera lifecycle dan UI freeze

- CameraX ImageAnalysis memakai STRATEGY_KEEP_ONLY_LATEST sehingga frame lama tidak mengantre terus.
- Analisis memakai executor native, bukan thread UI Flutter.
- MediaPipe mode video/stream memakai timestamp dan tracking.
- EventChannel mengirim hasil angka, bukan bitmap penuh, ke Flutter.
- Camera dihentikan/dilanjutkan melalui lifecycle dan MethodChannel.

### Batas

Hanya 23 label, sensitif variasi signer/cahaya/occlusion/handedness, belum ada metric, dan metadata model_status berbunyi KERAS_GOLDEN_TFLITE_REQUIRES_FIX. Meskipun model dapat diload/test bentuk tensor, nama status ini harus diperlakukan sebagai warning provenance.

## 10. Artefak sign-language lain dan status SIBI

### YOLO-family 42 label

- assets/models/fix_model/best.tflite sekitar 9.9 MB.
- input [1,3,640,640] Float32.
- output [1,46,8400] Float32, konsisten dengan 4 box value + 42 class score pada raw detector.
- labels terdiri dari A–Z dan kata seperti Aku, Apa, Ayah, Dia, Halo, Ibu, Maaf, Nama, Sedih, Senang, Suka, Terima kasih.
- lib/features/sign_language/services/bisindo_yolo_service.dart dapat memetakan detection menjadi prediction.
- Tidak ada screen/controller/binding yang memanggil service ini.

Kesimpulan: **artefak/adapter eksperimen, bukan SIBI runtime aktif.** Nama YOLO26 tidak dibuktikan oleh model metadata atau dokumen. Label file dan class memakai istilah BISINDO, bukan SIBI, sehingga nomenklatur juga belum final.

### Service model yang kehilangan aset

- BisindoAlphabetInferenceService mengharapkan bisindo_alphabet_model_f32.tflite dan labels yang tidak ada/tidak dideklarasikan.
- BisindoWordInferenceService mengharapkan bisindo_wl_model.tflite dan labels yang tidak ada/tidak dideklarasikan.

### ONNX/prototype lama

- assets/models/hajicare_encoder.onnx menerima bentuk [batch,2,100,27] dan mengeluarkan embedding.
- hajicare_prototypes.json memuat 8 class prototype 256 dimensi.
- Tidak dipakai runtime aktif; hanya artifact/test lama.

### Jawaban “Kenapa model SIBI dan BISINDO tidak disamakan?”

Premis yang aman: hanya pipeline BISINDO GRU yang aktif. Secara engineering, detector cocok untuk pose/simbol yang cukup dibedakan dari satu frame, sedangkan sequence landmark cocok untuk gerak temporal. Namun jangan menyatakan ini sebagai keputusan final tim untuk SIBI, karena pipeline SIBI aktif belum terbukti.

## 11. IoT/smartband

### Arsitektur yang dibuktikan sisi aplikasi

    DHT11 pada HajiCare Watch/ESP32 (diasumsikan protokol)
      -> temperature / humidity / heat-index strings
      -> BLE custom service UUID ...90ab
      -> characteristics ...90ac / ...90ad / ...90ae
      -> FlutterBluePlus scan nama “HajiCare Watch”
      -> connect + discover + initial read + notification subscription
      -> parse UTF-8 menjadi double
      -> validasi dan timeout 45 detik
      -> heat index dari perangkat atau fallback Rothfusz
      -> status Dingin / Normal / Panas
      -> GetX observable -> smartband page/dashboard

### Threshold status

- Dingin: suhu <20°C.
- Panas: suhu >=32°C atau heat index >=35°C.
- Normal: selain itu.

Threshold adalah rule aplikasi, bukan diagnosis medis.

### Yang benar-benar diukur

- suhu lingkungan;
- kelembapan relatif;
- heat index dilaporkan atau dihitung.

### Yang tidak diukur

- suhu tubuh;
- denyut jantung;
- SpO2;
- tekanan darah;
- langkah;
- diagnosis dehidrasi/heatstroke.

Dashboard memiliki nilai “-” untuk baterai, heart rate, dan steps. Itu placeholder UI dan tidak boleh didemokan sebagai sensor aktif.

### Ketergantungan dan failure

- Bluetooth off: dialog meminta pengguna menyalakan Bluetooth.
- Device tidak ditemukan: scan timeout 15 detik.
- Putus: state disconnected; tidak ada uncontrolled auto-reconnect loop.
- Data berhenti: timeout 45 detik dan sensor unavailable.
- Firmware/device/rangkaian/calibration: tidak ada di repo, sehingga end-to-end **PARTIALLY IMPLEMENTED**.

File: lib/features/smartband/services/ble_service.dart; controllers/smartband_ldr_controller.dart; screens/smartband_ldr_page.dart.

## 12. GPS, room, distance, SOS, dan assistance

### Location flow

    Geolocator permission/service
      -> initial position
      -> high-accuracy stream dengan distanceFilter 10 m
      -> local position state
      -> broadcast Firestore
           user document
           room member document bila ada room
           active SOS event bila SOS aktif
      -> peer snapshot
      -> Haversine distance
      -> tier + UI

Broadcast tambahan ditahan bila update sebelumnya kurang dari 15 detik **atau** perpindahan kurang dari 10 m. Efek praktis: update memerlukan keduanya cukup; detail ini dapat mempengaruhi perceived realtime.

### Distance tier

- Aman: <=50% radius.
- Waspada: >50% dan <=100% radius.
- Terlalu jauh: >radius.
- separatedMode aktif setelah terlalu jauh selama minimal 5 detik pada object runtime.

Tidak ditemukan service background/push untuk menjalankan eskalasi saat app tertutup.

### SOS flow

    Jamaah tekan SOS
      -> modal konfirmasi + vibration
      -> HajiCareController.triggerSos
      -> SosService Firestore batch
          create sos_events
          update users.sosActive
          update member.sosActive bila room
      -> realtime listeners pendamping/admin
      -> pendamping membuka detail/radar/map
      -> transition status melalui RoomCommandService/callable atau fallback

Ada callable triggerSos yang lebih ketat, tetapi jalur client aktif HajiCareController memakai SosService direct Firestore. Ini harus dijelaskan sebagai current implementation, bukan desain ideal.

### Assistance request

Jenis: lostWay, separated, pickup, message. Service membentuk object request dan menaruhnya pada Rx state lokal, lalu mengirim companion message ke Firestore. Acknowledge/on-the-way/completed terutama mengubah object lokal; jangan klaim sebagai workflow server durable penuh.

Terdapat fallback tujuan Hotel Al Madinah, Room 304, dan koordinat referensi Madinah pada AssistanceRequestService. Ini placeholder/prototype dan perlu dihapus sebelum penggunaan nyata.

## 13. Peta, prayer, translator, dan panduan haji

### Peta

- Tile: CARTO Voyager/Dark; fallback OSM.
- POI: Overpass, dinamis, bukan daftar demo bawaan.
- Search: Photon → Nominatim → native geocoding.
- Route: ORS foot-walking bila key tersedia → public routed-foot fallback.
- Marker: current user, room member/jamaah, POI, search result.
- Google Maps external intent untuk directions/search.

Batas: provider publik mempunyai quota/policy; lokasi/rute dapat tidak akurat; fallback route URL memakai host routed-foot dengan path “driving”, sehingga perlu uji hasil.

### Prayer

- adhan package menghitung jadwal dari coordinate/timezone/metode.
- Location source: GPS, last known, cache, unavailable.
- Cache valid 7 hari; fallback internal dapat dipakai bila GPS gagal.
- Prayer alarm dan reminder dijadwalkan lokal; Android exact alarm dapat fallback inexact.
- Kompas kiblat perlu sensor perangkat.

### Translator

    user mengetik / STT platform
      -> language pair id/ar/en
      -> pastikan source + target ML Kit models tersedia
      -> translateText on-device
      -> hasil UI
      -> TTS platform bila dipilih

ML Kit menyatakan on-device translation ditujukan untuk terjemahan kasual/sederhana dan pasangan non-English dapat melalui English. Dalam konteks haji/medis, output harus diperlakukan sebagai bantuan, bukan terjemahan resmi.

### Hajj dua

- 22 HajjDua dan 13 HajjDuaCategory.
- Arabic/transliteration/translation/context/source/sourceReference.
- search, bookmark, recent, text-scale.
- tidak ada audioPath pada data saat audit.
- source text menyebut Kemenag/riwayat, tetapi dokumen primer tidak ada.

## 14. Online/offline/permission matrix

| Fitur | Internet | Camera | Mic | GPS | BLE | Catatan |
|---|---:|---:|---:|---:|---:|---|
| Login/register/Google | Ya | Tidak | Tidak | Tidak | Tidak | Firebase/Google |
| Room/location/SOS/notifikasi inbox | Ya | Tidak | Tidak | Lokasi ya | Tidak | Firestore realtime |
| Peta tile/POI/search/route | Ya | Tidak | Voice search saja | Ya untuk posisi | Tidak | Provider eksternal |
| Jadwal salat | Tidak setelah lokasi/timezone siap | Tidak | Tidak | Idealnya | Tidak | Cache/fallback ada |
| Kiblat | Tidak | Tidak | Tidak | Koordinat + compass | Tidak | Sensor perangkat |
| Alarm adzan | Tidak setelah schedule/assets | Tidak | Tidak | Tidak saat bunyi | Tidak | Permission notification/alarm |
| Money detection | Tidak | Ya | Tidak | Tidak | Tidak | Kurs terbaru perlu internet; TTS device-dependent |
| BISINDO | Tidak | Ya | Tidak | Tidak | Tidak | TTS device-dependent |
| Translator text | Pertama kali download model | Tidak | Tidak | Tidak | Tidak | Setelah model siap on-device |
| STT | Device-dependent | Tidak | Ya | Tidak | Tidak | Engine/language pack |
| Panduan doa | Tidak | Tidak | Tidak | Tidak | Tidak | Data teks lokal |
| Smartband | Tidak untuk BLE | Tidak | Tidak | Tidak | Ya | Device/protocol wajib |

### Failure behavior

- Internet mati: Firebase dan map APIs gagal/stale; AI lokal/doa/jadwal cache masih mungkin.
- Camera ditolak: Money/BISINDO tidak dapat bekerja; tampilkan permission error, jangan memaksa.
- Model gagal load: screen menunjukkan error/hasil kosong; lakukan demo fallback video/screenshot dan jelaskan artifact.
- BLE mati/device tidak ada: scan dihentikan dengan pesan; fitur lain tetap berjalan.
- GPS ditolak/mati: lokasi/room distance/SOS coordinate terbatas; jadwal memakai last known/cache/fallback.
- Cloud Functions mati: sebagian code mencoba direct Firestore fallback; ini bukan behavior yang diinginkan untuk produksi.

## 15. Security dan privacy audit

### Yang sudah ada

- Firebase Auth dan UID.
- Callable functions dengan transaction/batch dan validasi input.
- custom claim admin/pendamping pada beberapa flow.
- HTTPS untuk endpoint web.
- private service-account/keystore tidak ditemukan tracked.
- camera AI lokal tidak mempunyai upload frame dalam code.
- rules menutup activities, active_sos, pairings write dari client.
- release tidak memakai debug signing otomatis.

### Risiko aktual yang wajib diakui

1. users readable oleh semua signed-in user: paparan profil, medis, lokasi.
2. rooms read/create/update untuk semua signed-in user.
3. members create/update oleh diri sendiri tanpa field allowlist.
4. user dapat mengubah role profil sendiri selama bukan admin.
5. authorization Cloud Function fallback percaya role profil bila claim tidak privileged.
6. roomCodes seluruh CRUD oleh signed-in user.
7. notifikasi tipe umum dapat dibuat client dengan validasi longgar.
8. direct Firestore fallback mengurangi jaminan server-side validation.
9. App Check belum diintegrasikan/enforced.
10. NIK/paspor gagal allowlist rules, sementara data tersebut sangat sensitif.
11. SharedPreferences tidak terenkripsi.
12. tidak ada account deletion, retention, export/consent flow eksplisit.
13. CARTO key default ada di client source; ORS key client build juga dapat diekstrak.
14. tidak ada certificate pinning.
15. privacy policy menyatakan access restriction yang tidak cocok dengan rules sekarang.

### Contoh rantai privilege escalation

    signed-in jamaah
      -> ubah users/{self}.role menjadi pendamping (rules mengizinkan non-admin)
      -> buat members/{self} dengan role pendamping (rules mengizinkan self create)
      -> ubah room.pendampingIds (rooms update terbuka)
      -> Cloud Function requireRoomManager fallback membaca profile role
      -> dianggap manager

Ini alasan paling kuat mengapa HajiCare tidak boleh diklaim secure/production-ready saat ini.

### Jawaban juri tentang keamanan

“Saat ini kami sudah memakai Firebase Auth, rules, callable functions, HTTPS, dan on-device camera inference. Tetapi audit kami menemukan rules masih terlalu permisif dan ada direct-write fallback. Jadi saya tidak mengklaim production-ready. Sebelum pilot, kami akan menutup akses user/room berdasarkan membership, menghapus role fallback dan direct sensitive writes, menyelaraskan field rules, mengaktifkan App Check, menambah emulator security tests, serta menerapkan minimisasi dan penghapusan data.”

## 16. Performance dan scalability

### Performance lokal

- Money: still-photo multi-pass dapat meningkatkan waktu inferensi; enhancement dikerjakan compute isolate.
- BISINDO: keep-only-latest, throttle, stride, dan landmark vector mengurangi transfer dibanding mengirim bitmap ke Flutter.
- Model latency aktual per device tidak didokumentasikan; log stopwatch ada, benchmark tidak.

### Cloud scalability

Firebase dapat scale, tetapi “realistis untuk jutaan jamaah” belum terbukti. Risiko:

- frekuensi GPS write dan listener cost;
- rules/query design dan index;
- hotspot/listener fan-out pada room besar;
- external public API quota;
- cost Cloud Functions/Firestore;
- observability, retry/idempotency, disaster recovery;
- Saudi network conditions dan device diversity.

Jawaban aman: arsitektur serverless memberi jalur scale, tetapi perlu load test, cost model, partition strategy, offline design, dan pilot bertahap.

## 17. Verification status

- flutter test: 300/300 lulus pada audit ini.
- flutter analyze --no-pub: enam info deprecated API, tanpa error/warning.
- Backend/security emulator tests ada di firebase-tests, tetapi tidak dapat dijalankan karena npm/Node tidak tersedia. Selain itu, script test pada functions/package.json menunjuk functions/test/*.test.js yang tidak ada; ini adalah test-script drift tersendiri.
- Security test source justru mengharapkan akses yang lebih ketat daripada firestore.rules saat ini; ini bukti configuration drift.
- Tidak dilakukan perubahan source production.

## 18. Peta file penting

| Area | File/class |
|---|---|
| Bootstrap | lib/main.dart |
| Routes/guards | lib/core/routes/app_routes.dart; role_and_room_guard.dart |
| Global state | lib/core/state/hajicare_controller.dart; app_startup_controller.dart; app_settings_controller.dart |
| Auth | lib/features/auth/controllers/login_controller.dart; register_controller.dart |
| Backend client | lib/core/services/trusted_backend_service.dart |
| Functions | functions/index.js; functions/src/*.js |
| Rules/index | firestore.rules; firestore.indexes.json |
| Room | lib/features/room/services/room_service.dart; room_command_service.dart; room_query_service.dart |
| GPS | lib/core/services/location_service.dart; hajicare_controller.dart |
| SOS | lib/features/sos/services/sos_service.dart; screens/sos_* |
| Notifications | lib/features/notification/services/notification_service.dart |
| Map | lib/features/map/controllers/map_controller.dart; services/poi_service.dart; route_service.dart; lib/core/services/geocoding_service.dart |
| Prayer | prayer_times_controller.dart; prayer_calculation_service.dart; adhan_notification_service.dart |
| Translator | translation_service.dart; speech_service.dart; tts_service.dart; translator_sheet.dart |
| Money | money_recognition_screen.dart; smart_multi_pass_detector.dart; currency_rate_service.dart; money_tts_service.dart |
| BISINDO | lib/features/sign_language/**; Android MainActivity.kt/BisindoCameraHelper.kt |
| Smartband | ble_service.dart; smartband_ldr_controller.dart; smartband_ldr_page.dart |
| Hajj guide | hajj_dua_data.dart; hajj_dua_repository.dart; hajj_dua_service.dart |
| Profile | profile_controller.dart; profile_screen_sections.dart; legal_document_screen.dart |

## 19. Rujukan teknologi resmi

- LiteRT overview: https://developers.google.com/edge/litert
- MediaPipe Hand Landmarker Android: https://developers.google.com/edge/mediapipe/solutions/vision/hand_landmarker/android
- ML Kit on-device translation: https://developers.google.com/ml-kit/language/translation
- Firebase callable functions: https://firebase.google.com/docs/functions/callable
- Firestore Security Rules: https://firebase.google.com/docs/firestore/security/get-started
- Firebase App Check: https://firebase.google.com/docs/app-check

Rujukan tersebut menjelaskan teknologi umum. Status implementasi HajiCare tetap ditentukan oleh codebase, bukan oleh kemampuan produk vendor.
