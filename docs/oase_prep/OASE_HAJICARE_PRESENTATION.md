Buat presentasi lomba inovasi OASE untuk HajiCare dalam format Slide Presenter, rasio 16:9, sekitar 15 slide utama untuk dibawakan oleh 5 presenter. Setiap presenter mendapat sekitar 3 slide dengan bobot materi yang relatif seimbang.

Gunakan Executive Summary HajiCare sebagai sumber utama isi, fitur, manfaat, screenshot, dan narasi presentasi. Gunakan Technical Architecture / Claim Audit hanya untuk memberikan penjelasan teknis yang benar dan menjaga agar klaim tidak melebihi implementasi yang tersedia.

TARGET PRESENTASI:
Presentasi harus bisa dipahami oleh orang awam/non-teknis, tetapi tetap menunjukkan bahwa HajiCare benar-benar memiliki implementasi engineering.

Komposisi isi kira-kira:
75% penjelasan produk, manfaat, dan visual.
25% penjelasan teknis ringan.

JANGAN menampilkan nama teknologi saja tanpa penjelasan.

Jika sebuah slide menggunakan istilah teknis seperti:
GPS • Geolocator • Firestore • Haversine

maka WAJIB memberikan penjelasan singkat dengan bahasa awam, misalnya:

“GPS membaca posisi jamaah, Firestore menyinkronkan lokasi antarperangkat, lalu perhitungan Haversine digunakan untuk mengetahui jarak jamaah dengan pendamping.”

Teknologi boleh ditampilkan sebagai small technical tag di bawah penjelasan:

GPS • Geolocator • Firestore • Haversine

Jadi format setiap fitur utama adalah:

NAMA FITUR
Apa manfaatnya bagi jamaah

CARA KERJA
1 kalimat sederhana tentang bagaimana fitur bekerja

TEKNOLOGI
small technical tags

Jangan menampilkan stack teknologi tanpa menjelaskan fungsi masing-masing.

==================================================
NARASI UTAMA
==================================================

HajiCare adalah prototype teknologi asistif untuk mendukung perjalanan Haji dan Umrah melalui tiga pilar utama:

1. SAFETY
Keselamatan dan pendampingan jamaah.

2. ACCESSIBILITY
Membantu jamaah memperoleh informasi dan berkomunikasi dengan lebih mudah.

3. IBADAH SUPPORT
Membantu jamaah memperoleh navigasi dan informasi ibadah.

Jangan membuat presentasi berupa daftar fitur.

Ceritakan HajiCare melalui perjalanan jamaah:

Login
→ memilih role
→ bergabung ke Room
→ lokasi rombongan terhubung
→ melihat Map dan Safe Radius
→ menggunakan SOS jika membutuhkan bantuan
→ menggunakan Money Recognition saat transaksi
→ menggunakan BISINDO / Translate jika mengalami hambatan komunikasi
→ melihat jadwal salat, arah kiblat, fasilitas, lokasi penting, dan panduan ibadah.

==================================================
STRUKTUR 15 SLIDE
==================================================

SLIDE 1 — COVER

Judul:
HajiCare

Subjudul:
Smart Assistive Technology for Safety, Accessibility & Ibadah Support

Gunakan visual perjalanan Haji yang minimal, modern, premium, dan elegan.

Visual Haji harus subtle:
siluet Ka'bah,
arsitektur Masjidil Haram,
garis perjalanan/rute,
atau pola geometris Islam dengan opacity rendah.

Jangan terlalu ramai.

==================================================

SLIDE 2 — MASALAH JAMAAH

Jelaskan dengan sangat sederhana masalah utama:

- kepadatan jamaah
- jamaah dapat terpisah dari rombongan
- kesulitan navigasi
- hambatan komunikasi
- akses informasi
- kebutuhan khusus lansia dan penyandang disabilitas

Jangan menggunakan paragraf panjang.

Gunakan visual manusia/perjalanan dan beberapa keyword besar.

==================================================

SLIDE 3 — MENGAPA HAJICARE DIBUTUHKAN

Gunakan evidence dari Executive Summary.

Tampilkan angka penelitian penting secara visual, bukan sebagai paragraf.

Jelaskan bahwa kebutuhan jamaah tidak hanya tentang lokasi, tetapi juga keselamatan, komunikasi, aksesibilitas, navigasi, dan informasi ibadah.

Bahasa harus sederhana.

==================================================

SLIDE 4 — HAJICARE DALAM SATU GAMBAR

Tampilkan tiga pilar utama secara clean:

SAFETY
ACCESSIBILITY
IBADAH SUPPORT

Jelaskan singkat:

Safety:
membantu koordinasi, pemantauan, dan bantuan jamaah.

Accessibility:
membantu komunikasi dan akses informasi.

Ibadah Support:
membantu navigasi serta kebutuhan informasi ibadah.

Gunakan tiga visual sederhana dengan glassmorphism ringan.

==================================================

SLIDE 5 — USER JOURNEY & ROLE

Tampilkan tiga role:

JAMAAH
PENDAMPING
ADMIN

Gunakan flow sederhana:

Login
→ Pilih Role
→ Join/Create Room
→ Dashboard
→ Gunakan Fitur HajiCare

Jelaskan:

Jamaah menggunakan layanan dan bantuan.

Pendamping memantau serta membantu jamaah.

Admin mendukung pengelolaan room dan koordinasi.

Gunakan screenshot asli HajiCare jika tersedia.

==================================================

SLIDE 6 — COMPANION TRACKING & SAFE RADIUS

Gunakan screenshot asli Map dan Safe Radius dari HajiCare.

Penjelasan utama:

“Pendamping dapat mengetahui posisi anggota Room dan melihat apakah jamaah masih berada dalam radius aman.”

Tambahkan bagian kecil:

CARA KERJA

“GPS membaca koordinat perangkat. Lokasi diperbarui ke Firestore saat aplikasi aktif, lalu jarak antaranggota dihitung untuk menampilkan status Aman, Waspada, atau Terlalu Jauh.”

TEKNOLOGI

GPS • Geolocator • Firestore Realtime • Haversine

Jika memungkinkan gunakan flow kecil:

GPS
→ Lokasi
→ Firestore
→ Hitung Jarak
→ Status Radius

Jangan menjelaskan formula matematika Haversine.

==================================================

SLIDE 7 — SOS & BANTUAN

Gunakan screenshot SOS dan dashboard pendamping.

Penjelasan utama:

“Ketika jamaah membutuhkan bantuan, SOS menyimpan informasi darurat beserta lokasi sehingga pendamping dalam Room dapat melihatnya.”

CARA KERJA

“Ketika tombol SOS digunakan saat aplikasi dan koneksi aktif, event dan lokasi disimpan di Firestore lalu ditampilkan melalui listener realtime pada aplikasi pendamping.”

TEKNOLOGI

Cloud Firestore • Realtime Listener • Location

Visual flow:

Jamaah
→ SOS
→ Lokasi & Event
→ Firestore
→ Pendamping

Jangan memberi kesan bahwa SOS otomatis menghubungi ambulans, pemerintah, atau emergency service resmi.

==================================================

SLIDE 8 — INTERACTIVE MAP & FACILITIES

Gunakan screenshot asli Interactive Map.

Jelaskan fungsi utama:

- melihat peta
- mencari fasilitas
- menemukan lokasi penting
- mencari tempat
- menampilkan rute

Jelaskan teknologinya dengan bahasa awam.

CARA KERJA

“OpenStreetMap/CARTO menyediakan tampilan dasar peta. Overpass membantu mengambil titik fasilitas di sekitar jamaah. Photon atau Nominatim digunakan untuk pencarian lokasi, sedangkan layanan routing membantu membuat rute perjalanan.”

TEKNOLOGI

FlutterMap
OpenStreetMap / CARTO
Overpass API
Photon / Nominatim
Routing

Jangan hanya menampilkan:

OpenStreetMap • Overpass • Photon • Nominatim

tanpa penjelasan.

Gunakan diagram sederhana:

Base Map
+
Search
+
Facilities
+
Route

→ Interactive Map HajiCare

==================================================

SLIDE 9 — MONEY RECOGNITION

Gunakan screenshot asli Money Recognition dari Executive Summary.

Penjelasan utama:

“Kamera membantu jamaah mengenali nominal Riyal Saudi dan menghitung total uang yang terlihat.”

CARA KERJA

“Foto uang diproses langsung di perangkat menggunakan model AI. Model mencari uang yang terlihat pada gambar, mengenali jenis nominalnya, menggabungkan deteksi yang sama agar tidak dihitung dua kali, lalu menghitung total SAR dan dapat membacakannya melalui suara.”

TEKNOLOGI

TensorFlow Lite
Object Detection
14 kelas Riyal/Halala
On-device AI
Text-to-Speech

Visual flow:

Camera
→ AI Detection
→ Nominal
→ Total SAR
→ Speech

Jangan menampilkan confidence sebagai accuracy.

Jangan membuat angka accuracy yang tidak tersedia dalam sumber.

==================================================

SLIDE 10 — BISINDO

Gunakan screenshot asli BISINDO HajiCare.

Penjelasan utama:

“Gerakan tangan pengguna dikenali kemudian hasil pengenalannya dapat ditampilkan sebagai teks dan dibacakan sebagai suara.”

CARA KERJA

“CameraX mengambil gambar dari kamera. MediaPipe membaca titik-titik tangan. Informasi gerakan dari beberapa frame kemudian diproses oleh model GRU untuk mengenali salah satu kosakata yang tersedia.”

TEKNOLOGI

CameraX
MediaPipe
GRU
TensorFlow Lite
23 kosakata

Visual flow:

Camera
→ Hand Landmarks
→ Sequence Gerakan
→ GRU
→ Text
→ Speech

Jelaskan secara jelas:

Implementasi saat ini adalah pengenal 23 kosakata BISINDO terbatas.

Jangan menyebutnya sebagai penerjemah seluruh bahasa BISINDO.

==================================================

SLIDE 11 — COMMUNICATION & ACCESSIBILITY

Tampilkan fitur:

Translate
Speech-to-Text
Text-to-Speech
Dynamic Text Scaling
Dark Mode

Jelaskan manfaatnya bagi pengguna.

Contoh:

TRANSLATE

“Membantu komunikasi sederhana dalam bahasa Indonesia, Arab, dan Inggris.”

CARA KERJA

“Model bahasa diterapkan di perangkat setelah paket bahasa tersedia.”

TEKNOLOGI

Google ML Kit Translation

SPEECH-TO-TEXT

“Ucapan pengguna dapat diubah menjadi teks melalui layanan pengenalan suara perangkat.”

TEKNOLOGI

Speech Recognition / STT

TEXT-TO-SPEECH

“Teks dapat dibacakan melalui suara perangkat.”

TEKNOLOGI

TTS Engine

Dynamic Text Scaling:

“Membantu pengguna memperbesar teks agar lebih mudah dibaca.”

Dark Mode:

“Memberikan alternatif tampilan yang lebih nyaman sesuai kebutuhan pengguna.”

Jangan memenuhi slide dengan teks.
Gunakan visual/icon minimal dan screenshot jika tersedia.

==================================================

SLIDE 12 — IBADAH SUPPORT

Gunakan screenshot asli Prayer Schedule, Qibla, Map, dan Guide Haji.

Tampilkan:

Prayer Schedule
Qibla
Facilities
Location Information
Hajj Guide

Jelaskan singkat:

PRAYER SCHEDULE

“Jadwal salat dihitung berdasarkan posisi dan zona waktu pengguna.”

TEKNOLOGI

Adhan local calculation • GPS • Timezone

QIBLA

“Arah kiblat dihitung dari posisi pengguna dan ditampilkan menggunakan sensor arah perangkat.”

TEKNOLOGI

GPS • Compass

FACILITIES & LOCATION

“Peta membantu jamaah menemukan fasilitas dan lokasi penting di sekitar area perjalanan.”

TEKNOLOGI

OpenStreetMap • Overpass API

HAJJ GUIDE

“Panduan ibadah disimpan dalam aplikasi sehingga dapat diakses dengan mudah.”

Jangan membuat slide seperti daftar pustaka fitur.

Utamakan screenshot.

==================================================

SLIDE 13 — BAGAIMANA HAJICARE DIBANGUN

Buat architecture diagram sederhana dan mudah dipahami orang awam.

Jangan membuat diagram software engineering yang terlalu kompleks.

Di tengah:

HAJICARE APP
Flutter + GetX

Dari HajiCare App buat 4 cabang terpisah:

1. FIREBASE CLOUD

Firebase Authentication:
“mengelola identitas dan login pengguna.”

Cloud Firestore:
“menyimpan dan menyinkronkan data seperti Room, lokasi, SOS, dan notifikasi.”

Cloud Functions:
“menangani sebagian proses backend.”

2. ON-DEVICE AI

Money Recognition:
“TFLite memproses foto uang langsung di perangkat.”

BISINDO:
“GRU TFLite memproses urutan gerakan tangan.”

3. NATIVE ANDROID

CameraX:
“mengambil frame kamera.”

MediaPipe:
“mengubah gerakan tangan menjadi data landmark.”

4. DEVICE / BLE

“Bluetooth menghubungkan aplikasi dengan smartband.”

Implementasi yang terbukti saat ini:
DHT11 membaca suhu lingkungan, kelembapan, dan heat index.

Jangan menampilkan heart rate, SpO2, suhu tubuh, langkah, atau diagnosis sebagai kemampuan aktif.

Architecture harus sangat visual.

Gunakan icon + satu kalimat pendek.

==================================================

SLIDE 14 — PROTOTYPE SAAT INI & ROADMAP

Gunakan tiga bagian:

IMPLEMENTED

Contoh:
Room
GPS / Distance
Map
SOS
Prayer
Money Recognition
BISINDO terbatas
Translator
Notification
BLE client

VALIDATING

Security hardening
Evaluasi model AI
Smartband end-to-end
Accessibility testing

NEXT

Text-to-Sign
User pilot
Hardware validation
Pengembangan aksesibilitas

Tampilkan sebagai roadmap sederhana.

Jangan membuat fitur roadmap terlihat seperti fitur yang sudah selesai.

==================================================

SLIDE 15 — CLOSING

Gunakan visual paling bersih dan emosional.

Headline:

“Menghubungkan Bantuan, Memudahkan Perjalanan Ibadah Jamaah.”

atau:

“Safety, Accessibility, dan Ibadah Support dalam Satu Perjalanan HajiCare.”

Gunakan satu perjalanan visual:

Room
→ Navigation & Ibadah
→ Accessibility
→ Assistance

Tegaskan:

“HajiCare adalah teknologi pendamping untuk membantu jamaah, bukan pengganti petugas resmi maupun tenaga kesehatan.”

Gunakan QS. Al-Ma'idah [5]:2 secara ringan sebagai landasan nilai tolong-menolong apabila sesuai.

==================================================
PEMBAGIAN 5 PRESENTER
==================================================

Presenter 1:
Slide 1–3
Cover, masalah, urgensi.

Presenter 2:
Slide 4–6
Konsep HajiCare, role, Companion Tracking.

Presenter 3:
Slide 7–9
SOS, Interactive Map, Money Recognition.

Presenter 4:
Slide 10–12
BISINDO, Accessibility, Ibadah Support.

Presenter 5:
Slide 13–15
Architecture, Prototype/Roadmap, Closing.

Pastikan kelima presenter mendapatkan materi yang cukup untuk dijelaskan, bukan hanya membaca bullet.

==================================================
VISUAL STYLE
==================================================

Gunakan visual:

SIMPLE
MODERN
ELEGANT
PREMIUM
CLEAN
MINIMAL

Tetap memiliki identitas perjalanan Haji.

Gunakan unsur visual Haji secara halus:

siluet Ka'bah
arsitektur Masjidil Haram
Islamic geometric pattern
garis perjalanan
map contour
koordinat
lengkungan arsitektur Islam

Gunakan elemen tersebut hanya sebagai background/subtle decorative element.

Jangan memenuhi slide dengan ornamen.

PALET WARNA:

Deep Emerald
Warm Ivory / Cream
Charcoal
Soft Gold

Gunakan transparency / opacity.

Gunakan GLASSMORPHISM secara elegan:

semi-transparent panel
background blur
thin translucent border
soft shadow
layered depth
subtle transparency

Glassmorphism hanya digunakan untuk card/panel tertentu.

Jangan membuat semua isi slide berupa glass card.

Readability adalah prioritas.

Gunakan warna transparan tetapi teks harus tetap memiliki contrast tinggi.

Gunakan kombinasi dark slide dan light slide supaya presentasi tidak monoton.

==================================================
SCREENSHOT & PRODUCT VISUAL
==================================================

PRIORITASKAN screenshot asli HajiCare dari Executive Summary.

Gunakan screenshot asli:

Dashboard Jamaah
Prayer & Qibla
Room
Map
Safe Radius
Dashboard Pendamping
Dashboard Admin
Money Recognition
BISINDO

Crop screenshot dengan rapi.

Tampilkan dalam premium phone mockup atau clean device showcase.

Jangan mengganti UI asli HajiCare dengan UI aplikasi buatan AI.

Jangan mengarang screenshot baru.

==================================================
ATURAN TEKS
==================================================

Satu slide = satu pesan utama.

Gunakan headline besar.

Gunakan maksimal sekitar 25–40 kata visible per slide jika memungkinkan.

Penjelasan teknologi maksimal 1–2 kalimat pendek.

Jangan menggunakan paragraf akademik panjang.

Jika ada istilah teknis:

JELASKAN FUNGSI TERLEBIH DAHULU.

BARU tampilkan nama teknologinya sebagai small technical tag.

Contoh yang BENAR:

“Lokasi jamaah diperbarui ke Room dan jaraknya dihitung untuk menentukan status aman.”

GPS • Geolocator • Firestore • Haversine

Contoh yang SALAH:

“GPS • Geolocator • Firestore • Haversine”

tanpa penjelasan.

Contoh yang BENAR:

“Peta mengambil data fasilitas sekitar dan membantu pengguna mencari lokasi serta rute.”

OpenStreetMap • Overpass API • Photon/Nominatim • Routing

Contoh yang SALAH:

hanya menampilkan nama API tanpa menjelaskan kegunaannya.

==================================================
HINDARI
==================================================

generic AI blue-purple gradient
robot imagery
floating 3D icons
random futuristic technology image
terlalu banyak rounded cards
semua slide menggunakan layout sama
paragraf panjang
jargon teknis tanpa penjelasan
jargon marketing seperti revolutionary / cutting-edge
UI buatan AI
klaim accuracy tanpa data
fitur yang tidak tersedia dalam sumber
smartband medis seolah sudah aktif
BISINDO universal translator
background tracking / push notification seolah sudah aktif

==================================================

Hasil akhir harus terasa seperti PRESENTATION DECK LOMBA INOVASI yang dibuat oleh professional human designer:

mudah dipahami orang awam,
visualnya premium,
fitur HajiCare terlihat jelas,
screenshot aplikasi asli dominan,
dan detail engineering tetap terlihat melalui penjelasan singkat tentang teknologi yang digunakan.