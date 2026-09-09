# HajiCare — Design Document
### Platform Pendampingan, Navigasi, Keselamatan, dan Aksesibilitas bagi Jamaah Haji dan Umrah

---

## 1. Ringkasan Produk

| Item | Detail |
|---|---|
| Nama Aplikasi | HajiCare |
| Platform | Android (Flutter) |
| Target Pengguna | Jamaah lansia, jamaah disabilitas, jamaah yang butuh pendamping, pendamping jamaah |
| Jenis Produk | Prototype/MVP aplikasi pendamping (bukan pengganti aplikasi resmi pemerintah) |
| Model Bisnis | Non-komersial (tahap akademik/prototype) |
| Status | Konsep & Prototype |

**Pernyataan Masalah (Problem Statement):**
Jamaah Haji/Umrah — khususnya lansia dan penyandang disabilitas — menghadapi risiko terpisah dari pendamping, kesulitan menemukan fasilitas penting, keterbatasan akses informasi darurat, dan hambatan komunikasi/keuangan di lingkungan asing yang sangat ramai.

**Value Proposition:**
Satu aplikasi yang menggabungkan tracking dua arah, tombol darurat, peta interaktif terkurasi, jadwal sholat, dan fitur aksesibilitas (pengenalan uang & komunikasi dasar) — dirancang ringan, gratis di tahap prototype, dan kompatibel dengan perangkat Android modern.

---

## 2. Lima Pilar Produk (Core Pillars)

| # | Pilar | Deskripsi Singkat | Fitur Terkait |
|---|---|---|---|
| 1 | **Companion** | Menghubungkan jamaah & pendamping secara real-time | Pairing, Tracking GPS |
| 2 | **Safety** | Perlindungan saat darurat | Tombol SOS, notifikasi lokasi, Peringatan Jarak (Distance Alert) |
| 3 | **Navigation** | Membantu jamaah menemukan tempat penting | Peta interaktif, filter kategori |
| 4 | **Accessibility** | Bantuan untuk kebutuhan khusus | Money Recognition, komunikasi aksesibel |
| 5 | **Prayer Information** | Informasi ibadah harian | Jadwal sholat 5 waktu |

---

## 3. Dua Peran Pengguna (User Roles)

### A. Jamaah
- Melihat lokasi Pendamping
- Membagikan lokasi sendiri
- Melihat peta interaktif
- Mencari toilet & tempat wudhu
- Melihat hotel, restoran, toko oleh-oleh
- Melihat lokasi penting
- Melihat jadwal sholat
- Menekan tombol SOS
- Menerima peringatan jarak (Distance Alert) saat terlalu jauh dari Pendamping
- Menggunakan Money Recognition
- Menggunakan komunikasi aksesibel (tahap lanjutan)

### B. Pendamping
- Melihat lokasi Jamaah
- Melihat jarak dengan Jamaah
- Melihat posisi Jamaah pada peta
- Menerima notifikasi SOS
- Menerima peringatan jarak (Distance Alert) saat Jamaah terlalu jauh
- Mengatur batas jarak aman (radius) untuk setiap Jamaah yang dipantau
- Membantu menemukan Jamaah
- Melihat fasilitas & lokasi penting

> Kedua role saling melihat lokasi satu sama lain (**mutual visibility**) — bukan pengawasan satu arah, sehingga tetap etis dan disetujui bersama (consent-based pairing).

---

## 4. Information Architecture (Struktur Navigasi)

```
HajiCare App
│
├── Onboarding
│   ├── Splash Screen
│   ├── Pilih Bahasa
│   └── Intro Fitur (3 slide)
│
├── Auth
│   ├── Login
│   ├── Register
│   └── Pilih Role (Jamaah / Pendamping)
│
├── Dashboard Jamaah
│   ├── Home (ringkasan status pairing, SOS cepat)
│   ├── Peta Interaktif
│   ├── Jadwal Sholat
│   ├── Money Recognition
│   ├── Komunikasi Aksesibel
│   └── Profil & Pengaturan
│
├── Dashboard Pendamping
│   ├── Home (status jamaah, jarak, notifikasi SOS)
│   ├── Peta Interaktif
│   ├── Daftar Jamaah yang Dipantau
│   └── Profil & Pengaturan
│
└── Shared Screens
    ├── Detail Lokasi
    ├── Notifikasi
    └── Bantuan/FAQ
```

---

## 5. Wireframe Konsep per Layar (Deskripsi Visual)

### 5.1 Splash & Onboarding
- Logo HajiCare di tengah, dengan warna coklat gelap (espresso) dan aksen gold — nuansa premium, hangat, dan religius (selaras dengan identitas visual tanah suci)
- Background gradient lembut dari coklat gelap ke coklat tan, atau cream/beige bermotif geometris Islami halus
- 3 slide intro: "Tetap Terhubung", "Aman & Terpantau", "Mudah Diakses Semua Orang"
- Tombol "Lewati" di kanan atas, "Lanjut" berbentuk pill solid coklat gelap di bawah

### 5.2 Login & Pilih Role
- Form input Email/No. HP + Password
- Toggle pemilihan role: **Jamaah** atau **Pendamping** (dua kartu besar bisa ditekan)
- Tombol besar full-width "Masuk"
- Link "Daftar Akun Baru" di bawah

### 5.3 Dashboard Jamaah (Home)
- Header: nama pengguna + status koneksi pendamping (●Terhubung / ○Terputus)
- Kartu besar **Tombol SOS** berwarna merah, ditempatkan mencolok di tengah atas
- Grid menu 2x3: Peta, Jadwal Sholat, Toilet Terdekat, Money Recognition, Komunikasi, Profil
- Card kecil "Jarak ke Pendamping: 120m" jika sedang terhubung

### 5.4 Dashboard Pendamping (Home)
- Header: daftar jamaah yang dipantau (list avatar horizontal)
- Card status tiap jamaah: nama, jarak, status baterai/lokasi terakhir update
- Notifikasi SOS muncul sebagai banner merah full-width jika aktif
- Tombol "Lihat di Peta" pada tiap card jamaah

### 5.4a Peringatan Jarak (Distance Alert) — Fitur Baru

**Konsep:**
Sistem secara otomatis memantau jarak antara Jamaah dan Pendamping berdasarkan koordinat GPS keduanya. Jika jarak melebihi batas aman (radius) yang ditentukan, aplikasi akan mengirimkan **peringatan (alert)** ke kedua perangkat secara bersamaan — berupa:
- **Bunyi peringatan** (alert sound khusus, berbeda dari notifikasi biasa, agar mudah dikenali)
- **Getaran (vibration)** pada perangkat
- **Teks peringatan** yang jelas, contoh: *"Perhatian! Anda terlalu jauh dari Pendamping (150m). Segera kembali ke titik kumpul."*

**Pengaturan Batas Jarak (Radius):**
- Pendamping dapat mengatur batas jarak aman melalui halaman pengaturan (misal: 50m, 100m, 200m — dapat disesuaikan)
- Nilai default disarankan: **100 meter** untuk area ramai seperti Masjidil Haram
- Batas jarak dapat berbeda untuk setiap Jamaah yang dipantau (misal lansia diberi radius lebih ketat)

**Tingkat Peringatan (Escalation):**
| Level | Kondisi | Aksi Sistem |
|---|---|---|
| Normal | Jarak < radius aman | Tidak ada notifikasi |
| Peringatan 1 | Jarak ≥ radius aman | Notifikasi ringan + getaran pada kedua perangkat |
| Peringatan 2 | Jarak ≥ radius aman x2 dalam durasi tertentu | Bunyi alarm lebih keras + teks peringatan mencolok (banner merah/oranye) |
| Kritis | Jarak sangat jauh / sinyal GPS Jamaah hilang | Sarankan Pendamping menekan tombol "Bantu Cari Jamaah" atau opsi eskalasi ke SOS |

**Wireframe Konsep:**
- Saat alert terpicu, layar Jamaah menampilkan **banner peringatan melayang** di bagian atas (warna oranye/merah) dengan ikon jarak + tombol "Lihat Peta" untuk langsung menuju lokasi Pendamping
- Layar Pendamping menampilkan **banner serupa** + jarak real-time yang terus diperbarui + tombol "Lacak di Peta"
- Alert tetap muncul (persist) di notification tray Android hingga jarak kembali dalam batas aman atau alert ditutup manual
- Bunyi peringatan menggunakan nada khas yang bisa dibedakan dari notifikasi SOS (SOS = nada darurat lebih tinggi & mendesak, Distance Alert = nada peringatan sedang)

**Catatan Teknis:**
- Perhitungan jarak menggunakan formula geolokasi standar (Haversine) berdasarkan dua titik koordinat GPS
- Update jarak dilakukan secara berkala (interval beberapa detik) untuk menghemat baterai, bukan tracking terus-menerus tanpa jeda
- Fitur ini melengkapi (bukan menggantikan) tombol SOS — Distance Alert bersifat **preventif/pencegahan dini**, sedangkan SOS bersifat **reaktif** saat kondisi sudah darurat

---

### 5.5 Peta Interaktif
- Peta full-screen (OpenStreetMap) sebagai layer utama
- Search bar melayang di atas peta
- Filter chip horizontal scroll: `Semua | Jamaah | Pendamping | Toilet | Wudhu | Hotel | Restoran | Oleh-oleh | Lokasi Penting`
- Marker berbeda warna/icon per kategori
- Tap marker → bottom sheet muncul dengan detail lokasi (nama, deskripsi, jarak, tombol arah)

### 5.6 Tombol SOS (Flow Modal)
- Tombol SOS besar bulat warna merah di dashboard
- Saat ditekan → modal konfirmasi "Kirim Sinyal Darurat?" dengan tombol Ya/Batal
- Setelah dikonfirmasi → layar status "Mengirim lokasi darurat..." dengan animasi loading
- Layar akhir: "Pendamping telah menerima notifikasi" + tombol batalkan SOS

### 5.7 Jadwal Sholat
- List 5 waktu sholat (Subuh, Dzuhur, Ashar, Maghrib, Isya) dalam card vertikal
- Waktu sholat berikutnya di-highlight dengan warna berbeda + hitung mundur
- Info lokasi kota di bagian atas

### 5.8 Money Recognition
- Layar kamera full-screen dengan frame panduan di tengah (posisi uang)
- Tombol capture bulat di bawah tengah
- Setelah foto diambil → hasil nominal ditampilkan besar di layar + ikon speaker (Text-to-Speech otomatis dibacakan)
- Tombol "Scan Ulang" jika hasil tidak terbaca

### 5.9 Komunikasi Aksesibel
- Dua tab: **Bicara → Teks/Isyarat** dan **Isyarat/Kamera → Suara**
- Tab 1: tombol mic besar di tengah, hasil teks muncul di bawah
- Tab 2: kamera aktif dengan area deteksi gesture, hasil kata muncul sebagai teks + diucapkan otomatis
- Grid kata-kata cepat (quick phrases): Tolong, Sakit, Air, Toilet, Saya Tersesat, Bantuan

---

## 6. Design System (Gaya Visual)

> Palet visual HajiCare diadaptasi dari analisa gaya UI platform booking Umrah & Haji (طواف) — dipilih **coklat-gold** sebagai identitas utama karena kesan premium, hangat, dan religius, jauh lebih kuat merepresentasikan konteks ibadah Haji/Umrah dibanding warna hijau generik.

### 6.1 Palet Warna

**Warna Primer**
| Warna | Kode | Penggunaan |
|---|---|---|
| Coklat Gelap/Espresso | `#4A3428` – `#3D2B1F` | Header, bottom navigation, tombol solid utama, background section statistik |
| Coklat Medium/Tan | `#8B6F47` – `#A67C52` | Badge, icon container bulat, aksen sekunder |
| Coklat Muda/Gold | `#C9A876` – `#D4B896` | Button outline, teks penekanan, border card |

**Warna Background**
| Warna | Kode | Penggunaan |
|---|---|---|
| Cream/Beige Lembut | `#F0E8DC` – `#EDE4D3` | Background utama layar, dengan motif geometris Islami halus |
| Putih | `#FFFFFF` | Background card, list layanan, form |

**Warna Teks**
| Warna | Kode | Penggunaan |
|---|---|---|
| Heading | `#2B1F16` | Judul, teks penting |
| Body Text | `#6B5D4F` | Deskripsi, teks sekunder |
| Putih | `#FFFFFF` | Teks di atas foto hero (dengan overlay gelap) |

**Warna Aksen/Status (tetap dipertahankan untuk fungsi kritikal)**
| Warna | Kode | Penggunaan |
|---|---|---|
| Merah Darurat | `#E63946` | Tombol SOS, notifikasi darurat — **satu-satunya elemen mencolok** di luar palet coklat-gold agar mudah dikenali dalam kondisi genting |
| Oranye Peringatan | `#F4A259` | Banner Distance Alert (peringatan jarak) |
| Kuning/Gold | `#D4A857` | Ikon rating, highlight pencapaian |
| Hijau Kecil | `#4CAF50` | Checklist fitur (✓) saja — bukan warna dominan |

> **Prinsip:** Warna coklat-gold mendominasi 90% antarmuka untuk kesan tenang & premium; warna merah/oranye sengaja dibatasi hanya untuk elemen keselamatan (SOS & Alert) agar tetap menonjol saat dibutuhkan.

### 6.2 Tipografi
- Font Arab: geometric/modern Arabic sans-serif — Cairo, Tajawal, atau IBM Plex Sans Arabic — tebal pada heading
- Font Latin/angka: sans-serif modern (Poppins/Inter) untuk angka, harga, dan teks Latin
- Hierarki ukuran (mobile scale):
  - H1 Hero: ±20–22sp, bold
  - H2 Section: ±16–18sp, medium-bold
  - Body: ±14–15sp (diperbesar dari standar demi aksesibilitas lansia), regular
  - Caption/label: ±12sp
- Line-height dilebihkan (1.4–1.6x) khusus teks Arab agar nyaman dibaca RTL
- Kontras teks terhadap background selalu tinggi (WCAG AA minimum)

### 6.3 Shape & Bentuk Komponen
- **Rounded corner dominan** di seluruh komponen — radius 16–24px pada card, **full-pill** pada button dan search bar (identitas visual utama dari referensi طواف)
- **Icon container**: lingkaran penuh (circle) dengan background coklat muda/tan, ikon di tengah — dipakai konsisten pada statistik pencapaian & shortcut fitur
- **Card**: rounded rectangle, shadow lembut agar terkesan "mengambang", padding lega
- **Search/filter bar**: bentuk pill, disusun vertical stacked card di mobile
- **Bottom sheet** dipakai untuk detail tambahan (lokasi, hasil Money Recognition) agar transisi terasa halus tanpa berpindah halaman penuh
- Tombol besar dengan tinggi minimal 48px (touch target ramah lansia)

### 6.4 Iconography
- Gaya ikon **outline/line-based**, minimalis, stroke tipis-medium — konsisten dengan gaya ikon referensi طواف
- Ukuran ikon 20–24px, cukup besar agar jelas terlihat oleh lansia
- Ikon besar dalam lingkaran khusus dipakai pada angka pencapaian/statistik dan navigasi fitur utama

### 6.5 Imagery Style
- Foto dokumentatif nyata (jamaah ihram putih, Ka'bah, suasana tawaf) dengan **warm color grading/sepia** agar selaras dengan palet coklat-gold
- **Overlay gradient gelap** pada hero image agar teks putih tetap terbaca jelas
- Ilustrasi vektor flat (karakter jamaah) dapat dipakai sebagai variasi visual di section statistik/pencapaian
- Foto dan ilustrasi menghindari kesan "dingin/klinis" — tetap hangat dan menenangkan sesuai konteks spiritual

### 6.6 Button & CTA Style
- **Solid button** (full-width di mobile): coklat gelap, teks putih, bentuk pill — untuk CTA utama ("Masuk", "Kirim Lokasi", "Mulai Tracking")
- **Outline button**: border coklat muda/gold, teks coklat, background transparan — untuk CTA sekunder ("Batal", "Lihat Detail")
- **Tombol SOS**: dikecualikan dari skema warna coklat — tetap solid merah bulat besar, agar instan dikenali dalam kondisi darurat
- Tombol filter/tab menggunakan pill toggle, state aktif solid coklat gelap

### 6.7 Visual Hierarchy & Branding
- Badge kecil pill di atas halaman Home (misal "Selamat Datang di HajiCare") sebagai trust element, mengikuti pola badge welcome pada referensi طواف
- Konsistensi shape (rounded pill) dipertahankan dari header hingga footer untuk membangun bahasa visual yang seragam
- Statistik pencapaian (jumlah pengguna, jarak tertracking, dsb — jika ada) ditampilkan dalam card gelap kontras sebagai social proof, mengikuti pola section statistik dari referensi طواف

### 6.8 Prinsip Aksesibilitas UI
- Kontras warna tinggi (WCAG AA minimum) — terutama teks di atas background cream
- Tombol besar, area sentuh minimal 48x48dp
- Dukungan TalkBack/screen reader
- Navigasi sederhana, maksimal 2 tap untuk mencapai fitur utama (SOS, Peta)
- Font scaling: mendukung pengaturan ukuran teks besar dari sistem Android

---

## 7. Arsitektur Sistem (Ringkas)

```
┌─────────────────────────────┐
│   Jamaah & Pendamping        │
└──────────────┬───────────────┘
               │
      ┌────────▼─────────┐
      │ Flutter Mobile App│
      └────────┬─────────┘
               │
   ┌───────────┼─────────────────────────────┐
   │           │             │               │
┌──▼──┐   ┌────▼────┐   ┌────▼─────┐   ┌─────▼─────┐
│Auth │   │GPS+Map   │   │SOS System│   │Accessibility│
└──┬──┘   └────┬─────┘   └────┬─────┘   └─────┬─────┘
   │           │              │               │
   └───────────┴──────┬───────┴───────────────┘
                       │
             ┌─────────▼──────────┐
             │ Firebase / Local DB │
             │ + On-device AI      │
             └─────────────────────┘
```

---

## 7a. Alur Fitur Distance Alert (Flowchart Konsep)

```
START
  ↓
Sistem Mengambil Lokasi Jamaah & Pendamping (berkala)
  ↓
Hitung Jarak (Haversine Formula)
  ↓
[Jarak ≥ Radius Aman?]
  │
  ├── Tidak → Kembali ke pengambilan lokasi berikutnya
  │
  └── Ya
       ↓
     Kirim Peringatan ke Kedua Perangkat
       ↓
     Tampilkan Bunyi + Getaran + Teks Peringatan
       ↓
     [Jarak Membesar Lagi / GPS Hilang?]
       │
       ├── Ya → Naikkan Level Peringatan (Kritis) → Sarankan Eskalasi ke SOS
       │
       └── Tidak → Pantau Terus hingga Jarak Kembali Aman
                     ↓
                   Tutup Peringatan Otomatis
                     ↓
                    END
```

**Penjelasan singkat:** Alur ini berjalan sebagai proses latar belakang (background process) selama fitur Companion Tracking aktif. Sistem tidak menunggu aksi manual pengguna — begitu jarak melewati ambang batas, peringatan otomatis dikirim ke kedua perangkat tanpa perlu dibuka aplikasinya terlebih dahulu (menggunakan push notification).

---

## 8. Tumpukan Teknologi (Tech Stack)

| Komponen | Teknologi | Kegunaan |
|---|---|---|
| Mobile App | Flutter | Membangun aplikasi Android |
| Database | Firebase (Free Tier) | Data pairing, lokasi, status SOS |
| Peta | OpenStreetMap | Peta interaktif prototype |
| Lokasi | GPS Smartphone | Tracking real-time |
| AI Lokal | TensorFlow Lite | Money Recognition on-device |
| Speech | STT/TTS bawaan | Aksesibilitas suara |
| Gesture | MediaPipe | Deteksi bahasa isyarat dasar |
| Notifikasi | Firebase Cloud Messaging (FCM) | Mengirim Distance Alert & SOS sebagai push notification real-time |

---

## 9. Prioritas Fitur (MVP)

| Tingkat | Fitur |
|---|---|
| **MVP Utama** | Login, Role, Pairing, GPS Tracking, Peringatan Jarak (Distance Alert), Peta Interaktif, SOS |
| **MVP Informasi** | Toilet, Wudhu, Hotel, Restoran, Oleh-oleh, Lokasi Penting, Jadwal Sholat |
| **MVP Aksesibilitas** | Money Recognition, Text-to-Speech |
| **Lanjutan** | Speech-to-Text, Speech-to-Sign, Sign-to-Speech |

---

## 10. Catatan Desain Penting

- Semua elemen desain mengutamakan **kemudahan bagi lansia & disabilitas**: teks besar, tombol besar, warna kontras tinggi.
- Tombol SOS harus **selalu terlihat/tersedia** dari layar Home tanpa perlu navigasi tambahan.
- Distance Alert harus tetap berfungsi meski aplikasi berjalan di background (push notification), dengan bunyi & getaran khas agar mudah dibedakan dari notifikasi biasa.
- Batas jarak aman (radius) sebaiknya dapat disesuaikan oleh Pendamping agar fleksibel untuk kondisi lokasi berbeda (area sempit vs area terbuka luas).
- Peta menggunakan data lokasi terkurasi manual untuk tahap prototype (bukan real-time crawling data).
- Desain visual dibuat modular agar mudah dikembangkan bertahap sesuai roadmap MVP.
- Identitas visual coklat-gold dipertahankan konsisten di seluruh layar untuk membangun kesan premium & tepercaya — hanya elemen SOS/Alert yang boleh menyimpang ke warna merah/oranye demi fungsi keselamatan.

---

*Dokumen ini adalah rancangan desain (design document) pendukung proposal HajiCare, digunakan sebagai acuan pengembangan UI/UX dan struktur sistem aplikasi.*
