# OASE HajiCare — Interview Bank

Format setiap item:

- **Singkat:** jawaban 10–20 detik.
- **Lengkap:** jawaban 30–60 detik.
- **Mengapa benar:** dasar pemahaman.
- **Jangan katakan:** klaim berbahaya.

## A. Basic product — mudah

### 1. Apa itu HajiCare?

**Singkat:** HajiCare adalah prototype Android yang menyatukan koordinasi rombongan, keselamatan, navigasi, ibadah, dan aksesibilitas jamaah.  
**Lengkap:** HajiCare melayani jamaah, pendamping, dan admin. Alur intinya room, location sharing, distance/radius, map, dan SOS; lalu dilengkapi prayer, panduan haji, deteksi uang SAR, translator, BISINDO terbatas, serta client smartband lingkungan.  
**Mengapa benar:** semua kelompok fitur mempunyai route/source nyata.  
**Jangan katakan:** “aplikasi resmi” atau “siap produksi”.

### 2. Masalah apa yang diselesaikan?

**Singkat:** Bantuan jamaah terpecah antara koordinasi, navigasi, darurat, bahasa, dan transaksi.  
**Lengkap:** Desain proyek berangkat dari risiko terpisah, kesulitan mencari fasilitas, akses bantuan, serta hambatan komunikasi/uang di lingkungan asing. HajiCare mencoba memperpendek perpindahan antaralat melalui satu journey. Ini problem statement desain; angka prevalensinya belum divalidasi di repo.  
**Mengapa benar:** HajiCare_Design_Document.md menyebut masalah/target tersebut.  
**Jangan katakan:** statistik korban/kasus tanpa sumber.

### 3. Siapa target user?

**Singkat:** Jamaah, pendamping, dan admin; target desain memberi perhatian khusus kepada jamaah lansia, disabilitas, atau yang memerlukan pendamping.  
**Lengkap:** Role runtime ada tiga. Jamaah memakai bantuan dan informasi; pendamping mengelola room/monitor anggota; admin mengelola overview. Namun belum ada usability report yang membuktikan penerimaan kelompok lansia/disabilitas.  
**Mengapa benar:** enum, routes, dashboards, dan design document.  
**Jangan katakan:** “sudah terbukti mudah untuk lansia.”

### 4. Apa fitur inti, bukan sekadar daftar semua fitur?

**Singkat:** Room dan identitas, lokasi/jarak, peta, dan SOS adalah backbone; AI dan ibadah melengkapi journey.  
**Lengkap:** Tanpa room, pengguna masih dapat memakai beberapa layanan mandiri. Tetapi nilai koordinasi tercipta ketika Auth → room → location → map/distance → assistance/SOS terhubung. Money/BISINDO/translator memberi aksesibilitas, prayer/guide memberi konteks ibadah.  
**Mengapa benar:** alur global state dan route nyata.  
**Jangan katakan:** semua fitur sama kritis.

### 5. Mengapa solusi berupa aplikasi?

**Singkat:** Ponsel sudah memiliki GPS, kamera, mic, speaker, compass, Bluetooth, dan koneksi yang dibutuhkan.  
**Lengkap:** Satu perangkat bisa menjadi sensor, UI, dan runtime AI. Ini mengurangi hardware tambahan untuk sebagian fitur dan memungkinkan inference lokal. Batasnya adalah battery, permission, network, dan literasi digital.  
**Mengapa benar:** dependencies/platform permissions menunjukkan pemanfaatan sensor.  
**Jangan katakan:** semua jamaah pasti punya/mahir smartphone.

### 6. Apa value proposition?

**Singkat:** Satu alur bantuan haji yang menghubungkan keselamatan, navigasi, ibadah, dan aksesibilitas.  
**Lengkap:** Nilainya bukan mengganti tool khusus yang lebih matang, tetapi mengurangi context switching dan menjaga konteks room/lokasi saat pengguna membutuhkan bantuan. AI lokal memberi respons langsung untuk kamera.  
**Mengapa benar:** fitur terhubung di dashboard/route/state.  
**Jangan katakan:** “lebih baik dari semua aplikasi existing.”

### 7. Apa status produknya?

**Singkat:** Prototype/MVP yang fungsi utamanya telah diimplementasikan, tetapi belum production-ready.  
**Lengkap:** 300 automated tests lulus dan banyak flow nyata tersedia. Namun metric ML, security hardening, FCM/background alert, hardware end-to-end, usability/pilot, dan deployment proof belum selesai.  
**Mengapa benar:** hasil audit eksekusi dan gap artifact.  
**Jangan katakan:** “sudah siap dipakai jamaah sebenarnya.”

### 8. Mengapa project ini layak dikembangkan?

**Singkat:** Karena use case-nya terintegrasi, prototype teknisnya konkret, dan gap validasinya dapat dibuat roadmap terukur.  
**Lengkap:** HajiCare sudah membuktikan integrasi Flutter, Firebase, map, native vision, TFLite, dan BLE client. Langkah berikutnya bisa diukur: security tests, model card, device benchmark, user research, dan pilot room kecil.  
**Mengapa benar:** ada basis implementasi, bukan ide slide saja.  
**Jangan katakan:** kelayakan pasar/biaya sudah terbukti.

## B. UX, accessibility, dan Hajj context — mudah–menengah

### 9. Bagaimana HajiCare membantu lansia?

**Singkat:** Desain memakai alur terintegrasi, kartu/tombol besar, text scale, TTS, dan bantuan pendamping; efektivitasnya belum diuji formal.  
**Lengkap:** Ada skala teks, locale, audio output, quick actions, room pendamping, dan SOS. Tetapi accessibility bukan hanya ukuran tombol; perlu usability testing dengan lansia, contrast/screen-reader audit, dan failure recovery.  
**Mengapa benar:** settings/UI ada; research report tidak ada.  
**Jangan katakan:** “pasti mudah bagi semua lansia.”

### 10. Bagaimana jika pengguna tidak familiar smartphone?

**Singkat:** Itu risiko UX nyata; desain harus meminimalkan langkah dan melibatkan pendamping, tetapi perlu uji pengguna.  
**Lengkap:** Prioritas seharusnya onboarding singkat, default aman, tombol inti konsisten, confirmation, audio, dan mode bantuan pendamping. Pilot harus mengukur task completion, error, dan waktu belajar—bukan hanya tampilan.  
**Mengapa benar:** mitigasi produk yang sesuai gap saat ini.  
**Jangan katakan:** “UI intuitif jadi tidak masalah.”

### 11. Mengapa tidak cukup WhatsApp live location?

**Singkat:** WhatsApp dapat menjadi alternatif koordinasi, tetapi HajiCare menggabungkan room, radius, SOS, map, profil darurat, dan accessibility dalam satu state.  
**Lengkap:** Kami tidak mengatakan WhatsApp buruk. HajiCare mencoba memberi domain model rombongan dan alur tindakan, bukan sekadar berbagi link lokasi. Efektivitas relatif belum diuji.  
**Mengapa benar:** room/SOS/domain state nyata.  
**Jangan katakan:** WhatsApp tidak aman/tidak mampu tanpa studi.

### 12. Apakah HajiCare menggantikan aplikasi resmi haji?

**Singkat:** Tidak; HajiCare adalah alat bantu prototype dan tidak menggantikan layanan resmi, petugas, atau emergency service.  
**Lengkap:** Fungsi pemerintah seperti identitas resmi, regulasi, layanan kesehatan, dan dispatch tidak ada. Integrasi formal juga belum terbukti. HajiCare berada pada koordinasi pendamping dan aksesibilitas.  
**Mengapa benar:** design/legal copy menyatakan non-replacement.  
**Jangan katakan:** integrasi pemerintah sudah ada.

### 13. Bagaimana nilai Islamnya?

**Singkat:** Teknologi ditempatkan sebagai alat kemudahan, keselamatan, aksesibilitas, dan tolong-menolong dalam perjalanan ibadah.  
**Lengkap:** Relevansi paling natural datang dari konteks haji, dukungan ibadah, dan membantu sesama jamaah. Aplikasi tidak menggantikan substansi ibadah. Saya tidak mengutip dalil tertentu karena proposal/source primer tidak ada di repository.  
**Mengapa benar:** konteks/fitur didukung; dalil tidak.  
**Jangan katakan:** ayat/hadis dari ingatan sebagai sumber proyek.

### 14. Apakah konten doa sudah resmi Kemenag?

**Singkat:** Entri mencantumkan atribusi Kemenag, tetapi verifikasi formal/source primer tidak tersedia di repo.  
**Lengkap:** Ada 22 entri/13 kategori dan sourceReference pada data. Namun tidak ada PDF/URL buku primer untuk pencocokan; audit lama juga menunjukkan histori content-source gap. Karena itu perlu review ahli/sumber resmi sebelum klaim.  
**Mengapa benar:** data vs artifact source.  
**Jangan katakan:** “sudah disahkan.”

## C. Flutter/frontend — menengah

### 15. Mengapa Flutter?

**Singkat:** Satu codebase UI dan ekosistem plugin sesuai MVP, sementara kebutuhan khusus tetap ditangani Kotlin native.  
**Lengkap:** Flutter menyatukan screen, theme, state, dan plugin Firebase/GPS/BLE/TTS. Untuk MediaPipe CameraX, project memakai platform channel sehingga tidak terjebak hanya pada kemampuan Dart. Trade-off adalah dependency/plugin native dan ukuran app.  
**Mengapa benar:** arsitektur repo.  
**Jangan katakan:** Flutter selalu lebih cepat dari native/React Native.

### 16. Mengapa GetX?

**Singkat:** GetX menyatukan route, dependency injection, dan reactive state untuk development MVP cepat.  
**Lengkap:** Binding mendaftarkan controller/service; Rx/Obx memperbarui UI; GetPage/guard mengatur navigasi. Trade-off-nya global locator dan controller besar, jadi constructor injection/lifecycle tests tetap penting.  
**Mengapa benar:** penggunaan konkret.  
**Jangan katakan:** GetX adalah arsitektur clean atau satu-satunya opsi.

### 17. Jelaskan alur UI–controller–service.

**Singkat:** Gesture UI memanggil controller/service, operasi async mengubah state, lalu Obx merender ulang.  
**Lengkap:** Contoh room: JoinRoomScreen → controller → RoomService/RoomCommandService → callable/Firestore → result/snapshot → HajiCareController Rx → dashboard. Beberapa complex screens memanggil service langsung, jadi arsitektur feature-first, bukan layer murni.  
**Mengapa benar:** trace call.  
**Jangan katakan:** semua fitur selalu melewati repository.

### 18. Bagaimana dependency injection?

**Singkat:** GetX Binding memakai lazyPut/put, lalu dependency diambil dengan Get.find; sejumlah service juga menerima constructor dependency untuk test.  
**Lengkap:** Binding scoped ke route membantu lifecycle. Global controller dipasang saat bootstrap. Dependency injection parsial memungkinkan fake Firestore/service pada tests, walau masih ada Firebase singleton di beberapa controller.  
**Mengapa benar:** bindings/constructors.  
**Jangan katakan:** tidak ada service locator/global dependency.

### 19. Bagaimana UI tidak freeze saat AI?

**Singkat:** BISINDO menganalisis frame di executor native dan membuang backlog; Money memindahkan enhancement ke compute isolate.  
**Lengkap:** CameraX memakai keep-only-latest, MediaPipe berjalan native, dan Flutter menerima vector landmark, bukan bitmap. Money pause camera setelah capture; image enhancement memakai compute. Inference tetap perlu benchmark device karena latency nyata belum didokumentasikan.  
**Mengapa benar:** Camera helper dan multi-pass service.  
**Jangan katakan:** UI pasti 60 FPS di semua device.

### 20. Bagaimana camera lifecycle?

**Singkat:** Native camera start/stop dikontrol MethodChannel dan lifecycle; screen membersihkan subscription/controller saat dispose.  
**Lengkap:** MainActivity mendaftarkan PlatformView, EventChannel landmark, dan MethodChannel control. Helper mengikat CameraX ke lifecycle dan memakai analyzer. Money controller dijeda setelah foto.  
**Mengapa benar:** Kotlin/Flutter services.  
**Jangan katakan:** satu camera implementation dipakai Money dan BISINDO; keduanya berbeda.

## D. Backend, API, database — menengah

### 21. Backend HajiCare apa?

**Singkat:** Firebase Auth, Cloud Firestore, dan callable Cloud Functions Node.js region asia-southeast2.  
**Lengkap:** Auth memberi UID/session, Firestore menyimpan document/stream, Functions menjalankan operasi room/profile/SOS/notification. Tidak ada custom REST server. External HTTP APIs bukan backend business logic kami.  
**Mengapa benar:** functions/index.js dan dependencies.  
**Jangan katakan:** “backend Flutter” atau “REST API HajiCare.”

### 22. Apa beda backend, API, dan database?

**Singkat:** Backend adalah logika cloud, API adalah pintu komunikasinya, database tempat data bertahan.  
**Lengkap:** Cloud Functions adalah backend; callable SDK adalah API; Firestore adalah database. ORS adalah API eksternal. TFLite adalah runtime model lokal, bukan API/database.  
**Mengapa benar:** batas arsitektur.  
**Jangan katakan:** semua service disebut database.

### 23. Mengapa Firebase?

**Singkat:** Auth, document realtime, callable, dan SDK Flutter mempercepat MVP koordinasi.  
**Lengkap:** Room/location/SOS cocok dengan stream perubahan. Transaction/batch membantu konsistensi. Trade-off: vendor dependency, cost/listener design, rules complexity, dan offline behavior yang harus diuji.  
**Mengapa benar:** penggunaan nyata.  
**Jangan katakan:** Firebase otomatis scalable/secure tanpa desain.

### 24. API eksternal apa saja?

**Singkat:** CARTO/OSM tile, Overpass POI, Photon/Nominatim geocoding, ORS/OSM route, exchange-rate API, serta Google Maps external URLs.  
**Lengkap:** Overpass memakai POST; search/rate/routing fallback memakai GET; ORS memakai POST + Authorization key. ML Kit model manager dan platform speech juga integrasi SDK. Semua memerlukan error/fallback sesuai code.  
**Mengapa benar:** endpoint service.  
**Jangan katakan:** Google Maps API menjadi map utama.

### 25. Apa yang disimpan lokal?

**Singkat:** SharedPreferences untuk settings/cache kecil, local JSON/model/audio untuk assets; tidak ada SQLite/Hive.  
**Lengkap:** Theme, locale, text scale, onboarding/session hints, room cache, prayer cache, exchange rate, map history, bookmarks/recent. SharedPreferences tidak terenkripsi, jadi jangan meletakkan secret/PII berat di sana.  
**Mengapa benar:** dependency dan calls.  
**Jangan katakan:** local DB terenkripsi.

### 26. Apa yang terjadi jika server mati?

**Singkat:** Koordinasi Firebase dan API online gagal/stale; AI lokal dan beberapa konten lokal tetap dapat bekerja.  
**Lengkap:** Sebagian service mencoba direct Firestore fallback bila Functions gagal, tetapi Firestore sendiri tetap server dan fallback itu membawa risiko security. Production design sebaiknya queue/retry/idempotency dan UX offline yang jelas, bukan bypass validasi.  
**Mengapa benar:** fallback paths.  
**Jangan katakan:** seluruh aplikasi tetap normal.

## E. GPS, SOS, maps, notification — menengah–sulit

### 27. Bagaimana lokasi bekerja?

**Singkat:** Geolocator stream memperbarui state, lokasi dipublish ke user/member Firestore, peer snapshot dipakai menghitung jarak.  
**Lengkap:** High-accuracy stream memakai distanceFilter 10 m. Broadcast dibatasi oleh waktu/perpindahan; room member dan active SOS ikut diperbarui. Jarak adalah garis lurus antarcoordinate, bukan walking route.  
**Mengapa benar:** HajiCareController/LocationService.  
**Jangan katakan:** lokasi selalu tepat/realtime kontinu.

### 28. Bagaimana distance tier?

**Singkat:** <=50% radius aman, <=100% waspada, di atas radius terlalu jauh; separated flag setelah lima detik.  
**Lengkap:** Radius default controller 200 m dan disimpan sebagai setting room. Tier dihitung ulang saat jarak berubah. Ini belum background alert/push dua perangkat dan belum radius per jamaah.  
**Mengapa benar:** JamaahData/HajiCareController.  
**Jangan katakan:** default 100 m dari design doc sebagai runtime.

### 29. Bagaimana SOS bekerja?

**Singkat:** Konfirmasi → Firestore batch event/status → listener realtime → detail/response/resolve.  
**Lengkap:** Event membawa user, room, waktu, lokasi opsional, kloter/maktab. Active client memakai SosService direct batch, meski callable triggerSos juga ada. Ia menghubungkan room HajiCare, bukan emergency service resmi.  
**Mengapa benar:** active call trace.  
**Jangan katakan:** ambulance/petugas Saudi otomatis menerima.

### 30. Apakah notifikasi adalah push?

**Singkat:** Inbox app memakai Firestore realtime; adzan memakai local notification; general FCM push tidak ada.  
**Lengkap:** firebase_messaging tidak menjadi dependency. Jika app tertutup, Firestore listener tidak sama dengan OS push. Karena itu design document tentang push distance/SOS adalah target, bukan runtime aktif.  
**Mengapa benar:** pubspec dan notification service.  
**Jangan katakan:** “notifikasi masuk walau app mati.”

### 31. Dari mana data fasilitas peta?

**Singkat:** POI dinamis dari OpenStreetMap melalui Overpass, bukan daftar hardcoded utama.  
**Lengkap:** Service mencoba tiga endpoint dan cache memori sekitar lima menit. Quality/kelengkapan mengikuti kontribusi OSM dan perlu validasi lapangan. Tile memakai CARTO/OSM; search/routing provider berbeda.  
**Mengapa benar:** PoiService.  
**Jangan katakan:** seluruh POI telah diverifikasi petugas.

## F. Money Recognition — sulit

### 32. Classification atau object detection?

**Singkat:** Object detection, karena output mencakup banyak kandidat objek, class, confidence, dan box.  
**Lengkap:** Model input 640×640 dan output [1,300,6]. Plugin berjalan dengan YOLOTask.detect. Ini memungkinkan beberapa lembar/koin pada satu foto dan totalisasi.  
**Mengapa benar:** tensor/task/postprocess.  
**Jangan katakan:** image classification satu label.

### 33. Jelaskan pipeline Money.

**Singkat:** Capture → original/enhanced/tile detection → IoU merge → threshold → total → kurs → TTS.  
**Lengkap:** Kandidat mulai .50; final .65. Pass tambahan adaptif. Same-class box dengan IoU >=.50 dikelompokkan; kandidat lintas dua pass dapat boost .10. Nominal dari label dijumlahkan, bukan dihasilkan model sebagai total langsung.  
**Mengapa benar:** SmartMultiPassDetector.  
**Jangan katakan:** multi-pass terbukti meningkatkan accuracy X%.

### 34. Mengapa 640×640?

**Singkat:** Itu bentuk input model yang terverifikasi; alasan training historis tidak tercatat.  
**Lengkap:** Secara engineering ukuran square tetap memudahkan detector dan menyeimbangkan detail/komputasi, tetapi repo tidak menyimpan ablation atau keputusan desain. Jadi saya membedakan fakta tensor dari rationale umum.  
**Mengapa benar:** menghindari fabricated history.  
**Jangan katakan:** “karena pasti optimal.”

### 35. Apa itu IoU dan mengapa dipakai?

**Singkat:** Rasio overlap dua box; dipakai untuk menganggap detection lintas pass sebagai objek fisik yang sama.  
**Lengkap:** IoU = intersection area / union area. Threshold .50 mencegah uang yang sama dihitung beberapa kali, sedangkan dua uang terpisah dengan overlap rendah tetap dihitung.  
**Mengapa benar:** merge implementation.  
**Jangan katakan:** IoU adalah accuracy.

### 36. Berapa accuracy/mAP Money?

**Singkat:** Belum terbukti; tidak ada evaluation report di repo.  
**Lengkap:** UI menampilkan confidence tiap detection, bukan accuracy dataset. Untuk jawaban ilmiah, saya membutuhkan held-out test, per-class precision/recall, mAP@50/mAP@50–95, confusion/failure breakdown, dan device benchmark.  
**Mengapa benar:** artifact metrics absent.  
**Jangan katakan:** angka dari confidence demo.

### 37. Apakah Money offline?

**Singkat:** Deteksi nominal on-device dan dapat offline; kurs terbaru perlu internet, TTS bergantung engine.  
**Lengkap:** Model dan labels dibundel dalam app. Exchange rate dicache 12 jam dan user dapat menyesuaikan. Jadi “deteksi offline” benar, “seluruh flow selalu offline” terlalu luas.  
**Mengapa benar:** assets/rate service.  
**Jangan katakan:** API kurs adalah bagian model.

## G. BISINDO, SIBI, MediaPipe, GRU — sulit

### 38. Jelaskan pipeline BISINDO.

**Singkat:** CameraX → MediaPipe landmarks → 135 fitur × 48 frame → GRU TFLite → 23 score → confidence/stability → teks/TTS.  
**Lengkap:** Native Android menganalisis camera frame, menyinkronkan hand/pose result, dan mengirim 543 layout values. Flutter mengambil dua tangan, menormalisasi, membentuk 135 features, lalu GRU menghasilkan [1,23]. Controller memakai gate .58, tiga label stabil, dan cooldown.  
**Mengapa benar:** active route/binding/service.  
**Jangan katakan:** MediaPipe langsung menerjemahkan.

### 39. Apa arti 48, 135, 23?

**Singkat:** 48 timestep, 135 fitur setiap timestep, 23 kelas keluaran.  
**Lengkap:** 135 = 63 left XYZ + 63 right XYZ + 2 presence + 4 wrist XY + 3 inter-wrist XYZ. Pada 15 FPS nominal, 48 frame sekitar 3,2 detik. Runtime dapat mulai pada 24 frame lalu padding.  
**Mengapa benar:** config/preprocessor/screen.  
**Jangan katakan:** selalu 48 frame asli penuh.

### 40. Mengapa keypoint, bukan raw image?

**Singkat:** Landmark memadatkan gambar menjadi geometri tangan sehingga sequence model fokus pada bentuk/gerak.  
**Lengkap:** Hanya vector kecil dikirim ke Flutter, mengurangi background/pixel dimensionality dan menjaga frame processing lokal. Trade-off: error MediaPipe/occlusion langsung memengaruhi model dan detail visual non-hand hilang.  
**Mengapa benar:** pipeline.  
**Jangan katakan:** landmark membuat model kebal terhadap background.

### 41. Mengapa GRU?

**Singkat:** Karena gesture mempunyai urutan gerak; GRU menyimpan konteks temporal.  
**Lengkap:** Pose satu frame bisa sama tetapi trajektori berbeda. GRU memakai gates untuk mempertahankan/melupakan informasi. Alasan efisiensi dibanding LSTM adalah rationale umum; benchmark pemilihan model tidak ada di repo.  
**Mengapa benar:** tensor temporal/artifact name/ops.  
**Jangan katakan:** GRU terbukti paling akurat.

### 42. Mengapa bukan LSTM/Transformer?

**Singkat:** Repo hanya membuktikan model GRU; perbandingan model tidak didokumentasikan.  
**Lengkap:** GRU umumnya lebih sederhana dan cocok mobile, sedangkan LSTM/Transformer mungkin memberi trade-off berbeda. Keputusan ilmiah seharusnya berdasarkan accuracy-latency-size benchmark pada dataset yang sama, yang belum tersedia.  
**Mengapa benar:** jujur membedakan rationale/evidence.  
**Jangan katakan:** model lain pasti lebih buruk.

### 43. Mengapa 15 FPS dan 48 frame?

**Singkat:** Itu kontrak metadata model: sekitar 3,2 detik; alasan optimasi historis belum terdokumentasi.  
**Lengkap:** 15 FPS mengurangi beban dibanding full camera FPS, sementara 48 memberi konteks gerak. Tetapi untuk membuktikan optimal perlu ablation latency/accuracy; runtime aktual juga dipengaruhi device dan mulai pada 24 frame.  
**Mengapa benar:** model_config/Kotlin/screen.  
**Jangan katakan:** angka tersebut universal untuk BISINDO.

### 44. Bagaimana preprocessing 135 fitur?

**Singkat:** Setiap tangan dibuat wrist-centered, dibagi skala telapak, di-clip; posisi wrist dan relasi dua tangan dipertahankan.  
**Lengkap:** 21×XYZ dikurangi landmark wrist 0, lalu dibagi mean jarak wrist ke MCP 5/9/13/17. Presence memberi tahu tangan hilang; wrist XY global dan inter-wrist XYZ menjaga konfigurasi spasial.  
**Mengapa benar:** BisindoPreprocessor.  
**Jangan katakan:** pose/face menjadi feature aktif.

### 45. Apa threshold BISINDO?

**Singkat:** Gate production controller .58 dan tiga prediksi sama; metadata .78 dan service flag .48 menunjukkan configuration drift.  
**Lengkap:** Saya tidak akan menyederhanakan menjadi satu angka palsu. Config model menyimpan .78, inference object menandai candidate .48, tetapi BisindoBinding menentukan commit di .58 plus stability 3 dan cooldown 1.2 detik.  
**Mengapa benar:** tiga source file.  
**Jangan katakan:** “threshold final 78%” tanpa konteks.

### 46. Apakah ini menerjemahkan seluruh BISINDO?

**Singkat:** Tidak; model mengklasifikasikan 23 kosakata terbatas.  
**Lengkap:** Ia belum melakukan continuous sign segmentation, grammar, sentence translation, unknown rejection yang tervalidasi, atau vocabulary luas. Sebut “recognizer 23 label”, bukan universal translator.  
**Mengapa benar:** labels.json.  
**Jangan katakan:** “real-time translator BISINDO lengkap.”

### 47. Bagaimana generalisasi antar-signer?

**Singkat:** Belum terbukti; metadata menyebut signer-independent split, tetapi dataset/report tidak tersedia.  
**Lengkap:** Evaluasi yang benar harus memisahkan signer antar train/test dan melaporkan per-class metric serta kondisi lighting/background. Tanpa artifact itu, saya tidak mengklaim generalisasi.  
**Mengapa benar:** config bukan bukti hasil.  
**Jangan katakan:** “signer-independent accuracy tinggi.”

### 48. Apa risiko data leakage?

**Singkat:** Frame atau signer yang sama bisa masuk train dan test sehingga metric tampak tinggi.  
**Lengkap:** Video menghasilkan banyak frame serupa; split per frame sangat berbahaya. Seharusnya group split per signer/session/video dilakukan sebelum augmentation. Metadata mengarah ke signer-independent, tetapi prosesnya belum dapat diaudit.  
**Mengapa benar:** prinsip ML relevan.  
**Jangan katakan:** tidak mungkin leakage karena memakai GRU.

### 49. Apakah kamera dikirim ke cloud?

**Singkat:** Pada pipeline BISINDO/Money yang diaudit, inference lokal dan tidak ditemukan upload frame.  
**Lengkap:** BISINDO memproses bitmap di native lalu mengirim landmark ke Flutter; Money memakai model bundled. Itu klaim terbatas pada code path saat ini—telemetry/crash SDK masa depan harus diaudit lagi.  
**Mengapa benar:** no upload call in pipeline.  
**Jangan katakan:** privasi sempurna hanya karena local inference.

### 50. Bagaimana SIBI bekerja?

**Singkat:** SIBI aktif tidak terbukti. Ada YOLO-family 42-label asset dan adapter yang tidak terhubung screen/runtime.  
**Lengkap:** Artifact mempunyai tensor [1,3,640,640] → [1,46,8400] dan label huruf+kata. Service bernama BisindoYoloService, bukan SIBI, dan istilah YOLO26 tidak punya metadata bukti. Jadi saya menyebutnya eksperimen sign-language object detector.  
**Mengapa benar:** reference search.  
**Jangan katakan:** “SIBI YOLO26 sudah selesai.”

### 51. Mengapa tidak samakan model BISINDO dan SIBI?

**Singkat:** Premisnya perlu diluruskan karena SIBI belum aktif; secara umum static pose dan temporal gesture memang punya kebutuhan berbeda.  
**Lengkap:** Detector satu frame dapat cocok untuk simbol statis yang butuh box/class. Landmark+GRU cocok untuk motion trajectory. Namun model final harus dipilih lewat data/benchmark, bukan karena nama bahasanya.  
**Mengapa benar:** reasoning dengan caveat.  
**Jangan katakan:** BISINDO selalu dinamis dan SIBI selalu statis.

## H. IoT, smartband, online/offline — sulit

### 52. Smartband mengukur apa?

**Singkat:** Suhu dan kelembapan lingkungan DHT11 serta heat index; bukan vital tubuh.  
**Lengkap:** BLE mempunyai tiga characteristic. Heat index dapat dihitung dengan Rothfusz fallback. Status dingin/normal/panas adalah rule lingkungan. Heart rate/battery/steps pada dialog masih “-” placeholder.  
**Mengapa benar:** BLE/controller/UI.  
**Jangan katakan:** health monitoring medis.

### 53. Apakah ESP32 benar-benar ada?

**Singkat:** App dan copy menargetkan ESP32 HajiCare Watch, tetapi firmware/rangkaian/bukti hardware tidak ada di repo.  
**Lengkap:** Sisi mobile scan/connect/read/notify diimplementasikan dengan UUID tertentu. Tanpa firmware/device test, end-to-end berstatus parsial. Demo hanya jika hardware nyata tersedia.  
**Mengapa benar:** artifact boundary.  
**Jangan katakan:** hardware tervalidasi.

### 54. Mengapa BLE?

**Singkat:** BLE cocok untuk telemetry jarak dekat dan konsumsi energi rendah.  
**Lengkap:** App dapat subscribe notification daripada polling HTTP. Namun actual battery consumption, pairing security, reconnection, dan interference belum diukur.  
**Mengapa benar:** protocol implementation/rationale.  
**Jangan katakan:** BLE otomatis aman.

### 55. Apa yang terjadi saat BLE putus?

**Singkat:** State menjadi disconnected, data tidak tersedia; tidak ada auto-reconnect loop liar.  
**Lengkap:** Scan/connect timeout 15 s; setelah connected, bila data diam 45 s sensor ditandai timeout. User dapat reconnect manual.  
**Mengapa benar:** controller/service.  
**Jangan katakan:** data lama adalah realtime.

### 56. Fitur mana offline?

**Singkat:** Money/BISINDO inference dan guide lokal; prayer dapat lokal; translation setelah download. Firebase/map/kurs terbaru online.  
**Lengkap:** Offline juga device-dependent untuk TTS/STT. GPS coordinate tidak membutuhkan internet, tetapi sharing/tiles/routing memerlukannya. Karena itu jawab per fitur, bukan “app offline”.  
**Mengapa benar:** dependency matrix.  
**Jangan katakan:** GPS selalu butuh internet atau seluruh peta offline.

## I. Security, privacy, ethics — killer

### 57. Bagaimana keamanan data jamaah?

**Singkat:** Fondasi Auth/HTTPS/callable/local inference ada, tetapi rules repo memiliki gap kritis sehingga belum layak klaim production-safe.  
**Lengkap:** users/rooms readable luas; room/member/self-role writes terlalu permisif; authorization punya profile fallback; direct writes, roomCodes, App Check, deletion/retention juga bermasalah. Rencana: least privilege per membership, claim-only privileged roles, no sensitive fallback, App Check, emulator tests, field minimization/encryption/retention.  
**Mengapa benar:** audit rules/functions.  
**Jangan katakan:** “aman karena Firebase.”

### 58. Tunjukkan contoh celah nyata.

**Singkat:** Signed-in user dapat mengubah profile role menjadi pendamping, membuat self membership, mengubah room manager data, lalu fallback backend dapat mempercayainya.  
**Lengkap:** Rules mengizinkan non-admin role self-update, self member create/update, dan room update oleh semua signed-in. requireRoomManager fallback membaca profile role jika claim bukan privileged. Rantai ini harus diputus di setiap lapisan.  
**Mengapa benar:** cross-file exploit reasoning.  
**Jangan katakan:** hanya hipotetis tanpa menunjukkan rules.

### 59. Apakah data medis private?

**Singkat:** Niat desainnya private, tetapi rules saat ini membolehkan semua signed-in membaca users, jadi belum aman.  
**Lengkap:** Itu juga membuat privacy policy tidak cocok dengan enforcement. Sebelum data nyata, pindahkan public/member projection ke dokumen terpisah, batasi full profile ke self/authorized responder, dan audit query.  
**Mengapa benar:** explicit allow read.  
**Jangan katakan:** hanya pendamping room dapat melihat.

### 60. Mengapa menyimpan NIK/paspor/medical data?

**Singkat:** Tujuannya kesiapsiagaan, tetapi kebutuhan dan proporsionalitasnya belum divalidasi; saat ini ada mismatch rules.  
**Lengkap:** Data sensitif harus optional, minimal, consented, access-scoped, encrypted where appropriate, retained/deleted with policy. Jika use case tidak membutuhkan NIK penuh, jangan menyimpannya. Controller menulis field yang rules update tidak izinkan.  
**Mengapa benar:** privacy by minimization.  
**Jangan katakan:** semakin banyak data semakin aman.

### 61. Apakah Firebase API key bocor?

**Singkat:** Firebase client API key memang dibundel dan bukan service-account secret; keamanan tetap bergantung restriction, Auth, Rules, dan App Check.  
**Lengkap:** Audit tidak menemukan private key/service-account/keystore tracked. CARTO default key dan ORS dart-define tetap client-extractable; key sensitif perlu provider restriction atau backend proxy.  
**Mengapa benar:** client threat model.  
**Jangan katakan:** menyembunyikan string di app membuat secret aman.

### 62. Bagaimana consent lokasi?

**Singkat:** OS permission ada, tetapi consent lifecycle dan retention perlu diperkuat.  
**Lengkap:** Tracking dimulai terkait active room dan berhenti saat room tidak aktif pada controller. Namun user perlu penjelasan jelas siapa yang melihat, kapan berhenti, freshness, revoke, dan deletion. Mutual visibility pada design tidak cukup sebagai legal/ethical consent proof.  
**Mengapa benar:** implementation vs policy.  
**Jangan katakan:** join room otomatis berarti consent sempurna.

### 63. Bagaimana mencegah AI membahayakan pengguna?

**Singkat:** Posisikan sebagai bantuan, tampilkan uncertainty, minta verifikasi, dan jangan gunakan output untuk diagnosis/keputusan keselamatan tunggal.  
**Lengkap:** Money/BISINDO dapat salah. Confidence/stability membantu UX tetapi bukan safety guarantee. Diperlukan model card, unknown class, fallback manual, accessibility feedback, logging consented, dan human confirmation.  
**Mengapa benar:** risk-aware AI.  
**Jangan katakan:** threshold menghilangkan false prediction.

## J. Novelty, competition, scale, feasibility — killer

### 64. Apa novelty-nya kalau semua teknologi sudah ada?

**Singkat:** Novelty defensibel ada pada integrasi dan adaptasi journey haji, bukan penemuan algoritma baru.  
**Lengkap:** HajiCare menghubungkan room/location/SOS dengan map, worship, currency/TTS, BISINDO, dan BLE environment. Native-to-Flutter landmark pipeline juga integrasi teknis konkret. Novelty harus diuji dari value pengguna, bukan klaim “belum pernah ada”.  
**Mengapa benar:** honest innovation framing.  
**Jangan katakan:** pertama di dunia.

### 65. Kalau Google Lens/Translate lebih matang, mengapa HajiCare?

**Singkat:** Kami tidak bersaing pada model global; kami mengintegrasikan output yang relevan ke workflow jamaah.  
**Lengkap:** Money langsung total SAR/IDR/TTS; translator/quick phrase berada bersama room/SOS. Tool khusus tetap alternatif. Keunggulan relatif perlu comparative usability study yang belum ada.  
**Mengapa benar:** differentiator tanpa superiority claim.  
**Jangan katakan:** lebih akurat dari Google.

### 66. Apakah AI benar-benar perlu atau gimmick?

**Singkat:** AI diperlukan ketika input kamera/gerak tidak dapat diselesaikan rule sederhana; fitur lain tidak dipaksa memakai AI.  
**Lengkap:** Object detection menangani variasi posisi/multiple money; GRU menangani trajectory gesture. Room/SOS/prayer memakai logic/database biasa. Pemisahan ini menunjukkan AI dipilih per problem, walau manfaat pengguna tetap perlu diuji.  
**Mengapa benar:** appropriate-tool argument.  
**Jangan katakan:** semua fitur lebih baik dengan AI.

### 67. Bisa dipakai jutaan jamaah?

**Singkat:** Belum terbukti; Firebase memberi jalur scale, tetapi perlu load/cost/security/offline/pilot evidence.  
**Lengkap:** GPS write rate, listener fan-out, room size, indexes, functions quotas, external APIs, observability, data residency, network, dan support operation harus diuji. Mulai pilot kecil dan ukur sebelum scale.  
**Mengapa benar:** architecture capacity ≠ proven scale.  
**Jangan katakan:** Firebase otomatis menangani jutaan user.

### 68. Apa business model?

**Singkat:** Dokumen menyebut tahap akademik/prototype non-komersial; business model belum divalidasi.  
**Lengkap:** Jalur implementasi bisa berupa pilot institusi/penyelenggara, tetapi biaya cloud, hardware, support, compliance, dan procurement belum dianalisis. Saya tidak akan mengarang monetization.  
**Mengapa benar:** design doc.  
**Jangan katakan:** sudah ada partner/revenue.

### 69. Apa roadmap paling prioritas?

**Singkat:** Security P0, evidence ML, reliable core demo/device tests, lalu pilot pengguna.  
**Lengkap:** 1) kunci rules/roles/direct writes dan privacy; 2) model card/dataset metrics; 3) FCM/background design bila dibutuhkan; 4) hardware firmware/calibration; 5) accessibility/user pilot; 6) load/cost/operations.  
**Mengapa benar:** risiko terbesar didahulukan.  
**Jangan katakan:** menambah fitur baru adalah prioritas pertama.

### 70. Apa bukti kualitas saat ini?

**Singkat:** 300 automated tests lulus; analyzer tanpa error/warning tetapi enam deprecation infos.  
**Lengkap:** Tests mencakup widget/logic/flow, bukan akurasi ML, real device, security deployment, atau user acceptance. Backend/security emulator tests ada di firebase-tests tetapi tidak dijalankan karena Node/npm tidak tersedia; script functions juga menunjuk folder test yang tidak ada.  
**Mengapa benar:** audit hari ini.  
**Jangan katakan:** test suite membuktikan production readiness.

## K. Cross-examination — sangat teknis/menjebak

### 71. “Accuracy tinggi tidak berarti model bagus. Bagaimana mencegah leakage?”

**Singkat:** Saya setuju; split harus per signer/session sebelum augmentation, bukan per frame, lalu laporkan per-class metric pada held-out signer.  
**Lengkap:** Sequence dari video yang sama sangat berkorelasi. Group split signer-independent, duplicate detection, immutable manifest, dan audit train/val/test diperlukan. Metadata menyebut split itu, tetapi hasil/dataset belum tersedia sehingga saya belum mengklaim berhasil.  
**Mengapa benar:** menjawab prinsip dan evidence gap.  
**Jangan katakan:** metadata membuktikan tidak ada leakage.

### 72. “Mengapa saya percaya heat index smartband?”

**Singkat:** Jangan percaya sebagai metric medis; itu indikator lingkungan dari DHT11/Rothfusz yang perlu kalibrasi dan validasi hardware.  
**Lengkap:** Code memvalidasi range, timeout, dan fallback formula, tetapi tidak ada calibration report, placement protocol, atau comparison instrument. Gunakan sebagai awareness, bukan diagnosis/evacuation threshold tunggal.  
**Mengapa benar:** scope sensor.  
**Jangan katakan:** mencegah heatstroke.

### 73. “BISINDO salah mengenali gesture; lalu apa?”

**Singkat:** Stability filter menahan noise, tetapi salah tetap mungkin; output harus dikonfirmasi dan tersedia fallback text/quick phrase.  
**Lengkap:** Threshold .58 + 3 stability bukan proof of correctness. UI seharusnya menampilkan candidate/undo, unknown handling, dan tidak otomatis mengirim pesan kritis tanpa confirmation. Model perlu per-signer evaluation.  
**Mengapa benar:** safety-aware interaction.  
**Jangan katakan:** TTS otomatis berarti hasil valid.

### 74. “Mengapa model_status mengatakan REQUIRES_FIX?”

**Singkat:** Itu warning provenance dalam metadata; runtime shape/load berfungsi, tetapi artifact status harus diselesaikan sebelum klaim final.  
**Lengkap:** Code memuat model [1,48,135] → [1,23], tetapi metadata backup menyimpan KERAS_GOLDEN_TFLITE_REQUIRES_FIX. Tanpa training/conversion report saya tidak menafsirkan lebih jauh. Saya akan regenerate/export, compare golden outputs, version, checksum, dan update model card.  
**Mengapa benar:** jujur pada artifact inconsistency.  
**Jangan katakan:** string itu tidak penting.

### 75. “Mengapa test bilang secure, tetapi rules tidak?”

**Singkat:** Itu configuration drift; test security mengharapkan denial yang rules sekarang tidak enforce.  
**Lengkap:** Source test mengharapkan outsider tidak membaca room/profile dan client tidak mengambil alih member/manager. Rules saat ini membolehkan beberapa hal itu. Karena test tidak dieksekusi di audit ini, laporan lama tidak boleh dijadikan bukti. CI emulator wajib memblokir drift.  
**Mengapa benar:** direct comparison.  
**Jangan katakan:** 300 Flutter tests mencakup rules.

### 76. “Mengapa ada direct fallback jika security penting?”

**Singkat:** Itu kompromi prototype untuk availability, tetapi tidak tepat untuk operasi sensitif produksi.  
**Lengkap:** Fallback membuat validasi terbagi dan bergantung rules yang saat ini lemah. Target production harus callable-only untuk privilege mutation, idempotent retry, explicit offline queue, dan deny-by-default rules.  
**Mengapa benar:** identifies trade-off/remedy.  
**Jangan katakan:** fallback meningkatkan keamanan.

### 77. “Apakah 0,58 threshold ilmiah?”

**Singkat:** Belum terbukti; itu runtime parameter, sedangkan calibration curve/validation evidence tidak ada.  
**Lengkap:** Threshold seharusnya dipilih dari validation trade-off false accept/reject dan mungkin per-class. Saat ini metadata .78 dan binding .58 juga berbeda. Jadi perlu calibration experiment, bukan debat angka.  
**Mengapa benar:** threshold vs evidence.  
**Jangan katakan:** 58% adalah accuracy minimum.

### 78. “Bagaimana menghitung total uang tanpa double count?”

**Singkat:** Detection lintas pass dengan kelas sama dan IoU >=.50 dikelompokkan, lalu confidence terbaik dipakai satu kali.  
**Lengkap:** Semua candidate diurutkan; cluster menyimpan match count antar-pass. Box berbeda/IoU rendah tetap objek terpisah. Edge case uang bertumpuk rapat masih dapat salah merge/split dan perlu test image benchmark.  
**Mengapa benar:** implementation detail.  
**Jangan katakan:** algoritma menjamin tidak pernah double count.

### 79. “Apa single point of failure?”

**Singkat:** Firebase/internet untuk koordinasi dan third-party map providers; device sensors/permissions untuk fitur lokal.  
**Lengkap:** Auth/Firestore outage menghentikan room/SOS realtime; Overpass/route/search bisa gagal; model/device compatibility memengaruhi AI; BLE device memengaruhi band. Mitigasi: provider fallback, cache, queue, monitoring, degraded mode, dan operational runbook.  
**Mengapa benar:** dependency map.  
**Jangan katakan:** serverless berarti tanpa failure.

### 80. “Jika Anda hanya bisa memperbaiki satu hal sebelum pilot?”

**Singkat:** Firestore authorization/security boundary.  
**Lengkap:** Karena data mencakup lokasi, kesehatan, dan identitas, kebocoran/takeover lebih berbahaya daripada kekurangan fitur. Saya akan menutup rules, menghapus fallback role/direct writes, menyelaraskan functions, dan menjalankan emulator adversarial tests sebelum memasukkan user nyata.  
**Mengapa benar:** risk prioritization.  
**Jangan katakan:** menambah accuracy/fitur adalah prioritas di atas privacy.

## L. Rapid-fire prompts tanpa jawaban

Gunakan daftar ini untuk simulasi interaktif satu per satu:

1. Jelaskan HajiCare tanpa menyebut nama teknologi.
2. Apa bukti masalah pengguna Anda?
3. Gambarkan arsitektur dalam 30 detik.
4. Trace tombol SOS sampai layar pendamping.
5. Mengapa Firestore dan bukan SQL?
6. Apa beda confidence dan accuracy?
7. Apa beda detection dan classification?
8. Mengapa Money perlu IoU?
9. Uraikan 135 fitur BISINDO.
10. Mengapa MediaPipe bukan model BISINDO?
11. Mengapa sequence temporal?
12. Apa risiko padding 24 menjadi 48 frame?
13. Bagaimana memilih threshold yang benar?
14. Bagaimana test signer-independent?
15. Apa status SIBI?
16. Apa yang terjadi jika internet mati?
17. Apakah smartband alat kesehatan?
18. Sebutkan celah rules terbesar.
19. Bagaimana privacy-by-design diterapkan nanti?
20. Apa novelty tanpa klaim “pertama”?
21. Mengapa AI bukan gimmick?
22. Apakah dapat scale satu juta user?
23. Bagaimana menilai usability lansia?
24. Apa hubungan nilai Islam tanpa dalil baru?
25. Apa tiga hal yang tidak akan Anda klaim?

## M. Rubrik menilai jawaban Anda sendiri

Skor 0–2 pada setiap dimensi:

- **Faktual:** sesuai code/status.
- **Jelas:** jawaban langsung dulu, detail kemudian.
- **Evidence:** menyebut file/alur/angka yang benar.
- **Boundary:** mengakui ketergantungan/keterbatasan.
- **No overclaim:** confidence ≠ accuracy; prototype ≠ production.

Total 8–10: siap. 5–7: ulang dengan struktur “jawab → bukti → batas”. <5: baca kembali master/claim audit.
