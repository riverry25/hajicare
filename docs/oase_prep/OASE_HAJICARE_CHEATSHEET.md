# HajiCare OASE — 10-Minute Cheat Sheet

## Definisi dan pitch

**Satu kalimat:** HajiCare adalah prototype Android yang menyatukan koordinasi rombongan, keselamatan, navigasi, ibadah, dan aksesibilitas jamaah dengan Firebase dan AI on-device.

**Masalah:** risiko terpisah, sulit menemukan fasilitas, koordinasi darurat, hambatan bahasa/isyarat/transaksi.  
**User:** jamaah, pendamping, admin; target desain mencakup lansia/disabilitas/yang memerlukan pendamping.  
**Value:** satu alur haji, bukan banyak aplikasi terpisah.  
**Novelty aman:** integrasi kontekstual + on-device accessibility; bukan “pertama” atau “paling akurat”.  
**Status:** prototype/MVP, bukan production-ready.

## Architecture satu gambar

    Flutter UI + GetX
       |-- Firebase Auth / Firestore / Callable Functions
       |-- HTTPS APIs: OSM/CARTO/Overpass/Photon/Nominatim/ORS/kurs
       |-- Local: SharedPreferences, JSON, adzan, prayer calculation
       |-- On-device AI: Money TFLite, BISINDO GRU, ML Kit translate
       |-- Native Kotlin: CameraX + MediaPipe -> EventChannel
       `-- Device: GPS, compass, mic/TTS, camera, BLE DHT11

**Backend:** Firebase serverless; tidak ada custom REST server.  
**Database:** Firestore. Local preference/cache: SharedPreferences. Tidak ada SQLite/Hive.

## Fitur dan status

- **Implemented:** auth, 3 role, room/QR/invite, GPS/jarak/radius, SOS realtime, map/POI/search/route, prayer/qibla/local adzan, hajj guide, translator, Money, BISINDO, notification inbox, BLE client.
- **Partial:** security rules, distance alert background, profile NIK/paspor, assistance lifecycle, smartband end-to-end, release/pilot.
- **Not active:** FCM push, background distance alarm, SIBI/YOLO26, 42-class YOLO screen, vital sensor, diagnosis, speech-to-sign.
- **Unknown:** all ML accuracy/mAP/dataset/training metrics, deployment production, usability/pilot statistics.

## AI angka wajib

### Money Recognition

- Model: assets/models/best_float16.tflite; YOLO-family detector.
- Tensor: **[1,640,640,3] Float32 → [1,300,6] Float32**.
- **14 kelas** Riyal/Halala.
- Candidate **0.50**, final **0.65**, cross-pass IoU **0.50**.
- Foto → original/enhanced/4 tile → merge/dedup → sum SAR → IDR → TTS.
- Deteksi offline; kurs terbaru online; confidence ≠ accuracy.

### BISINDO aktif

- CameraX → MediaPipe hand landmarks → 135 features → GRU TFLite → 23 labels → text/TTS.
- Tensor: **[1,48,135] Float32 → [1,23] Float32**.
- 48 frame ≈ **3.2 s pada 15 FPS nominal**, tetapi runtime mulai pada 24 frame lalu padding.
- 135 = **63 left XYZ + 63 right XYZ + 2 presence + 4 wrist XY + 3 inter-wrist XYZ**.
- Gate produksi **0.58 + 3 prediksi sama**, cooldown **1.2 s**.
- Metadata 0.78 dan service 0.48 tidak sinkron—akui gap.
- Vocabulary terbatas, bukan penerjemah seluruh BISINDO.

### SIBI/YOLO sign

- Ada artifact **[1,3,640,640] → [1,46,8400]**, 42 labels dan adapter.
- Tidak terhubung ke runtime aktif; “YOLO26” dan “SIBI final” **BELUM TERBUKTI**.

### Smartband

- BLE “HajiCare Watch”; DHT11: suhu/kelembapan/heat index lingkungan.
- Scan 15 s; sensor timeout 45 s.
- Tidak mengukur heart rate, SpO2, langkah, suhu tubuh, diagnosis.
- Firmware/rangkaian/device proof tidak ada: partial.

## Online/offline

- **Lokal:** Money inference, BISINDO inference, hajj guide, prayer calculation; translation setelah model diunduh.
- **Internet:** login/room/location sharing/SOS/inbox, map provider/POI/search/route, kurs terbaru, initial ML Kit model download.
- **Device-dependent:** STT/TTS offline, compass, alarm OEM.
- **BLE:** smartband.

## Security/privacy — jawaban wajib jujur

Sudah ada Auth, HTTPS, callable functions, local camera inference, rules, dan no private service-account/keystore tracked. Namun rules repo terlalu permisif:

- semua signed-in dapat membaca users/rooms;
- rooms update dan self member write terlalu luas;
- self role dapat menjadi pendamping;
- function authorization punya profile-role fallback;
- roomCodes terbuka;
- direct Firestore fallback;
- NIK/paspor tidak masuk allowlist update;
- App Check, deletion/retention, encrypted local storage belum ada.

**Jawab:** “Karena itu kami belum mengklaim production-ready. Sebelum pilot kami akan menutup akses per membership, menghapus role/direct-write fallback, mengaktifkan App Check, menyelaraskan rules, dan menjalankan emulator security tests.”

## Evidence hari ini

- **300 automated tests lulus.**
- Analyzer: **0 error, 0 warning, 6 deprecation infos.**
- Functions/security test tidak dijalankan: npm/Node tidak tersedia.
- Tidak ada ML evaluation report, proposal/ES/juknis OASE, PDF/DOCX/PPTX, atau source primer agama di repo.

## Islamic relevance

“Teknologi menjadi alat kemudahan, keselamatan, aksesibilitas, dan tolong-menolong bagi jamaah; bukan pengganti petugas atau substansi ibadah.”  
Jangan mengutip ayat/hadis baru. Konten aplikasi mencantumkan atribusi Kemenag, tetapi belum ada source primer/verifikasi formal di repo.

## 15 pertanyaan paling mungkin

1. **Apa HajiCare?** — MVP pendamping digital haji terintegrasi.
2. **Apa bedanya dari aplikasi biasa?** — Integrasi room/safety/map/worship/accessibility dalam satu journey; bukan klaim fitur pertama.
3. **Backend?** — Firebase Auth, Firestore, callable Cloud Functions; tanpa custom REST server.
4. **Kenapa Flutter?** — Satu UI codebase dan ekosistem plugin; native Kotlin tetap dipakai untuk vision.
5. **Kenapa GetX?** — Route, DI, reactive state cepat untuk MVP; trade-off global dependency/controller besar.
6. **Money classification atau detection?** — Object detection; bisa beberapa uang + box.
7. **Accuracy Money?** — Unknown; repo tidak punya report. Confidence layar bukan accuracy.
8. **Mengapa GRU?** — Membaca urutan gerak; lebih ringan secara umum dari LSTM. Itu rationale, bukan benchmark repo.
9. **Arti 48/135/23?** — timestep / fitur per frame / kelas keluaran.
10. **BISINDO lengkap?** — Tidak, hanya 23 kosakata.
11. **SIBI YOLO26?** — Tidak aktif/versi tidak terbukti; hanya artifact 42-label.
12. **Semua offline?** — Tidak; AI tertentu lokal, koordinasi/map memerlukan internet.
13. **Smartband health?** — Hanya lingkungan DHT11, bukan vital/diagnosis.
14. **Aman?** — Fondasi ada, tetapi rules punya gap kritis; belum production-ready.
15. **Layak scale jutaan?** — Firebase memberi jalur scale, tetapi belum ada load/cost/pilot evidence.

## Kalimat aman

- “Yang dibuktikan codebase adalah …”
- “Itu confidence per prediksi, bukan accuracy test set.”
- “BELUM TERBUKTI DARI CODEBASE/DOKUMEN.”
- “Fitur sisi aplikasi ada; validasi end-to-end masih tahap berikutnya.”
- “Dokumen desain adalah target; runtime sekarang baru …”
- “Ya, itu keterbatasan MVP. Dampaknya … dan mitigasinya …”

## Jangan pernah klaim

Production-ready; 90/95/99% accuracy; semua offline; Firebase otomatis aman; FCM/background alert; smartband medis; SIBI aktif; source Kemenag sudah disahkan; menghubungi emergency service; pertama di dunia; 300 tests membuktikan AI akurat.
