# 🛡️ Konstitusi & Aturan Utama Proyek (Project Master Rules)

Dokumen ini adalah **Aturan Mutlak Tingkat Tertinggi (Single Source of Truth Rule & Hard Gate)** bagi seluruh agen AI (Antigravity, Claude, Cursor, Codex, maupun subagen) yang bekerja di proyek ini.

Seluruh aturan di bawah ini mencakup **4 Pilar Utama**:
1. **Pilar 1:** Gerbang Wajib Pemanggilan Skill Sebelum Eksekusi (*Mandatory Pre-Action Skill Gate*)
2. **Pilar 2:** Batasan Rekayasa & Anti-Overengineering (*Engineering Boundaries & Code Harness*)
3. **Pilar 3:** Kontrak Design System, Responsivitas & Anti-AI-Slop (*Universal Design System Rules*)
4. **Pilar 4:** Mode Mentor & Penjelasan Bahasa Awam (*Mandatory Mentor & Explain-As-You-Code*)

---

## PILAR 1: GERBANG WAJIB SEBELUM NGODING, MENGUBAH, MENAMBAH FITUR, ATAU AUDIT KODE (MANDATORY SKILL GATE)

### 1.1 Hukum Utama: Dilarang Ngoding Sebelum Membaca Skill & Rules
> **ATURAN KERAS (ZERO-TOLERANCE GATE):**
> Agen AI **DILARANG KERAS** menulis kode baru (`write_file`), mengedit kode (`edit_file`), merombak arsitektur, memperbaiki bug, menambahkan fitur, atau melakukan audit kode **SEBELUM** terlebih dahulu:
> 1. **Mengidentifikasi domain fitur/tugas** yang diminta pengguna.
> 2. **Membaca (`read_file`) berkas `SKILL.md` yang relevan** dari daftar `.agents/skills/` proyek atau global skills.
> 3. **Membaca (`read_file`) berkas aturan ini (`.agents/rules/project-master-rules.md`)** serta dokumen desain/arsitektur (`DESIGN.md` / `ARCHITECTURE.md` jika tersedia).
> 4. **Menerapkan checklist dan batasan dari skill & rules tersebut** secara ketat selama pengerjaan.

Jika agen belum menemukan skill yang pas di daftar yang dimuat, agen wajib memeriksa direktori `.agents/skills/` atau memanggil `skill-advisor` (`C:\fadli\Antigravity-Skill-Brain`) terlebih dahulu. **Tidak boleh ada satu baris kode pun yang diubah berdasarkan tebakan atau asumsi tanpa pedoman skill dan rules.**

### 1.2 Alur Kerja Wajib 4-Tahap (Mandatory 4-Step Pre-Coding Workflow)
Setiap kali menerima instruksi untuk membuat, mengubah, memperbarui, memperbaiki, atau mengaudit kode, agen **WAJIB** menjalankan urutan ini:

1. **Tahap 1 — Klasifikasi Domain Tugas:**
   Tentukan domain apa saja yang tersentuh oleh permintaan pengguna (bisa lebih dari satu, misalnya: *UI + Supabase*, atau *Debugging + State Management*).
2. **Tahap 2 — Panggil & Baca Skill (`read_file`) + Baca `.agents/CODEBASE-REGISTRY.md` (Hemat Token):**
   - Gunakan tool `read_file` untuk membuka `SKILL.md` yang sesuai dengan matriks pada **Bagian 1.3**.
   - **WAJIB membaca `.agents/CODEBASE-REGISTRY.md`** untuk mengetahui daftar lengkap modul `/core`, komponen `/common/widgets`, helper `/common/utils`, dan `Services/Repositories` yang sudah ada di proyek **tanpa perlu membuka satu per satu file di `/core` atau `/common`** (sangat menghemat kuota token).
3. **Tahap 3 — Eksekusi Sesuai Kontrak Arsitektur & Engineering Harness:**
   Lakukan perubahan kode dengan mematuhi prinsip **Pilar 2 (Engineering Harness)** dan **Pilar 3 (Design System)**.
4. **Tahap 4 — Sinkronisasi `CODEBASE-REGISTRY.md`, Verifikasi Wajib, & Penjelasan Mentor Sebelum Klaim Selesai:**
   - **Write-Through Sync:** Jika Anda baru saja menambah, mengubah parameter/return, atau menghapus fungsi/service/komponen di `/core`, `/common`, atau `Services`, Anda **WAJIB langsung memperbarui tabel di `.agents/CODEBASE-REGISTRY.md`** pada giliran yang sama.
   - Jalankan prosedur `verification-before-completion` (linter/analyzer = 0 issues, test terkait = 100% lulus).
   - Tutup respons dengan blok **"🎓 Pojok Mentor"** sesuai **Pilar 4**.

### 1.3 Matriks Pemetaan Tugas $\rightarrow$ Skill Wajib Dibaca
Gunakan tabel referensi ini setiap kali akan memulai tugas:

| No | Domain / Fitur yang Dikerjakan | Skill Wajib Dibaca (`read_file` ke `SKILL.md`) | Fokus Kepatuhan Utama |
| :- | :--- | :--- | :--- |
| **1** | **Perencanaan Fitur Baru / Brainstorming / PRD / Riset** | `brainstorming`, `writing-plans`, `last30days`, `skill-advisor` | Validasi kebutuhan nyata, pecah rencana kerja sebelum menyentuh kode. |
| **2** | **UI/UX, Halaman Baru, Komponen, Tema Warna, Dark Mode** | `ui-ux-pro-max`, `design-md`, `awwwards` (web), `flutter-responsive` (mobile) | Patuhi `DESIGN.md`, token warna/font tunggal, zero raw hex, anti-AI-slop. |
| **3** | **Copywriting UI, Teks Landing Page, Dokumentasi, Microcopy** | `humanizer` | Bersihkan pola bahasa klise AI (*AI tells*) agar teks natural & tajam. |
| **4** | **Ilustrasi Teknis, Diagram Sistem / Arsitektur Interaktif** | `anatomy`, `generative_ui` | Gunakan model objek fisik isometrik presisi, hindari diagram kotak-panah murahan. |
| **5** | **Arsitektur Fitur, State Management, Repository, Clean Code** | `flutter-architecture`, `flutter-state-navigation-pro` (Flutter) / `vercel-react-best-practices` (Web) | Ikuti pola state & arsitektur yang sudah dikunci di repo, jangan ganti sepihak. |
| **6** | **Layout Responsif Multi-Device & Perbaikan Overflow** | `flutter-build-responsive-layout`, `flutter-fix-layout-issues`, `flutter-responsive` | Responsif di Mobile/Tablet/Desktop, bungkus scroll/flex dengan aman. |
| **7** | **Database, Supabase, PostgreSQL, RLS, Auth, Storage, Migrasi** | `supabase-postgres-best-practices`, `supabase-skills`, `firebase-official-skills` | Wajib RLS di 100% tabel, aman dari kebocoran `service_role_key`, skema optimal. |
| **8** | **Debugging Bug, Layar Error/Putih, Race Condition, Crash Runtime** | `systematic-debugging`, `artemis` (Android Logcat & screenshot), `flutter-performance-debug` | Cari root cause, tarik Android Logcat real-time via Artemis pada mobile, jangan menebak fix. |
| **9** | **Unit Test, Widget Test, E2E Test (Web & Android), TDD** | `test-driven-development`, `playwright` (web), `artemis` (Android automation), `verification-before-completion` | Tulis pengujian yang memverifikasi perilaku nyata (E2E web via Playwright / Android via Artemis). |
| **10** | **Audit Kode, Audit Keamanan, Audit Desain Pra-Rilis** | `cloudflare-security-audit`, `trailofbits-skills`, `jury` (web), `web-quality-skills` | Bukti verifikasi nyata, 0 secret leaks, skor kualitas visual & aksesibilitas tinggi. |

### 1.4 Daftar Tanda Bahaya (Red Flags — Wajib Berhenti!)
Jika agen berpikir seperti di bawah ini, agen **WAJIB BERHENTI** dan membaca skill terlebih dahulu:
- ❌ *"Perubahan ini cuma kecil, langsung edit saja tanpa baca skill."* ➔ **SALAH.** Perubahan kecil tanpa membaca aturan sering merusak kontrak arsitektur, token UI, atau keamanan RLS.
- ❌ *"Saya sudah hafal isi skill dari percakapan sebelumnya."* ➔ **SALAH.** Konteks bisa terpotong; wajib verifikasi dan patuhi daftar periksa terbaru.
- ❌ *"Saya buat saja fungsi helper/komponen baru biar cepat."* ➔ **SALAH.** Cek dulu `/common`, `/core`, atau `/shared` agar tidak menduplikasi kode yang sudah ada.

---

## PILAR 2: BATASAN REKAYASA & ANTI-OVERENGINEERING (ENGINEERING BOUNDARIES & HARNESS)

Setiap baris kode yang ditulis wajib mematuhi rambu-rambu rekayasa perangkat lunak berikut:

### 2.1 Wajib Gunakan Library yang Sudah Ada di Repo (Dependency Lock Rule)
1. **Periksa Manifest Dependensi Terlebih Dahulu:**
   - Sebelum menulis kode, cek file manifest proyek (`pubspec.yaml`, `package.json`, `pyproject.toml`, atau `Cargo.toml`).
   - **WAJIB** menggunakan library yang sudah terpasang di dalam repositori (baik untuk state management, HTTP client, router, icon pack, maupun utility).
2. **Dilarang Menambah Package Baru Tanpa Izin:**
   - **DILARANG KERAS** menjalankan `pub add`, `npm install`, `pnpm add`, atau menambahkan package pihak ketiga baru tanpa meminta persetujuan eksplisit dari pengguna beserta alasan kuat mengapa fitur bawaan repo tidak mencukupi.
3. **Dilarang Mengganti Arsitektur/State Management Sepihak:**
   - Ikuti pola yang sudah berjalan di proyek (misal: jika proyek menggunakan GetX, tetap gunakan GetX; jika Riverpod, tetap Riverpod; jika Next.js App Router, tetap App Router).

### 2.2 Arsitektur `/core` vs `/common` & Katalog Wajib `.agents/CODEBASE-REGISTRY.md` (Write-Through Index)
Agar AI selalu tahu seluruh fungsi/service yang ada tanpa boros token mencari ke puluhan file:

1. **Pembagian Tegas Isi `/core` vs `/common`:**
   - **`/core` (Mesin & Infrastruktur Inti Aplikasi):** Hanya berisi pondasi tingkat aplikasi yang dikonfigurasi satu kali:
     - `/core/theme`: Token warna (`AppColors`), tipografi (`AppTypography`), konfigurasi tema Light/Dark.
     - `/core/network` (atau `/core/api`): HTTP/Dio client, Supabase/Firebase client initializer, interceptor.
     - `/core/error`: Wrapper hasil dan error terpusat (`Result<T>`, `Failure`, `AppException`).
     - `/core/routing`: Konfigurasi rute navigasi dan *auth guards*.
     - `/core/localization` & `/core/config`: Kamus multi-bahasa (`AppStrings`) dan environment config.
   - **`/common` atau `/shared` (Komponen & Alat Pakai Ulang Lintas Fitur):**
     - `/common/widgets` (atau `/shared/components`): Tombol standar, field input, dialog, `EmptyStateView`, `LoadingSkeleton`, `ResponsiveWrapper`.
     - `/common/utils`: Formatter (mata uang Rupiah, tanggal), validator form, debouncer, extension helper.
     - `/common/services`: Service umum lintas fitur (`LocalStorageService`, `PermissionService`, `SnackbarService`).

2. **Kewajiban Membaca & Mengupdate `.agents/CODEBASE-REGISTRY.md` (Aturan Write-Through Sync):**
   - **1 Proyek = 1 File `.agents/CODEBASE-REGISTRY.md`:** Jika file ini belum ada di proyek, agen **WAJIB membuatnya terlebih dahulu** (menggunakan template dari `C:\fadli\Antigravity-Skill-Brain\Agent-Rules\CODEBASE-REGISTRY-TEMPLATE.md`) dan mencatat modul `/core`, `/common`, serta `Services` yang sudah ada.
   - **Baca Sebelum Buat Baru (Hemat Token):** Sebelum menulis fungsi helper, validator, komponen UI, atau service baru, agen **WAJIB membaca `.agents/CODEBASE-REGISTRY.md`**. Jika sudah tercatat di tabel, langsung `import` dan gunakan sesuai *signature*-nya tanpa perlu membuka file kode aslinya.
   - **Wajib Catat Setiap Ada Penambahan/Perubahan/Penghapusan:** Setiap kali agen membuat baru, mengubah parameter/return type, atau menghapus item di `/core`, `/common`, atau `Services/Repositories`, agen **WAJIB memperbarui baris tabel di `.agents/CODEBASE-REGISTRY.md` pada giliran yang sama** dengan format padat **1 baris per item**:
     `Nama | Lokasi File (Path) | Signature (Input -> Return) | Kegunaan Singkat (1 Kalimat)`
   - **Dilarang Menulis Blok Kode Panjang di Registry:** Jaga `.agents/CODEBASE-REGISTRY.md` tetap berisi tabel 4 kolom yang ringkas agar konsumsi token selalu di bawah $\le 800$ token.

### 2.3 Anti-Overengineering & Anti-Halusinasi (Simplicity & Grounded Code)
1. **Dilarang Membuat Abstraksi Baru Jika Sudah Ada atau Belum Perlu:**
   - Jangan membuat *wrapper class*, *factory*, *generic interface* berlapis-lapis, atau *design pattern* rumit untuk kebutuhan yang hanya dipakai di satu tempat (*Rule of Three*: jangan abstraksi sebelum ada minimal 3 duplikasi nyata).
   - Jika proyek sudah memiliki pola abstraksi (misal `BaseRepository` atau `Result<T>`), gunakan pola tersebut—**jangan menciptakan abstraksi tandingan baru**.
2. **Anti-Halusinasi API (Zero Hallucination):**
   - Dilarang mengarang nama method, parameter, atau class dari library yang tidak benar-benar ada di versi dependensi proyek.
   - Jika ragu terhadap API versi terbaru, cek kode sumber dependency di repo atau gunakan tool dokumentasi (`context7` / web search resmi).
3. **Jangan Mengubah Kode di Luar Cakupan Tugas:**
   - Fokus pada file dan baris yang relevan dengan permintaan pengguna. Jangan memformat ulang atau merombak kode fitur lain yang sedang berjalan baik tanpa diminta.

### 2.4 Aturan 500-LOC Confirmation Gate (Batas Baris Kode per File)
1. **Target Modularitas Ideal:**
   - Usahakan setiap file kode tetap ringkas, fokus pada satu tanggung jawab (*Single Responsibility*), dan idealnya berada di kisaran **$\le 300 - 450$ baris**.
2. **Gerbang Konfirmasi Wajib pada 500 Baris (500-LOC Gate):**
   - Apabila sebuah file yang sedang dibuat atau diedit **sudah melebihi atau akan melebihi $\pm 500$ baris kode (LOC)**:
   - Agen **DILARANG** langsung memecah file secara sepihak (yang berisiko membuat terlalu banyak file kecil membingungkan), dan **DILARANG** terus menumpuk kode secara diam-diam.
   - Agen **WAJIB meminta konfirmasi terlebih dahulu kepada pengguna** dengan pesan jelas seperti:
     > *"File `[nama_file]` saat ini sudah/akan mencapai lebih dari 500 baris karena logic/halaman ini cukup panjang. Apakah tidak apa-apa saya lanjutkan lebih dari 500 baris di dalam file ini, atau Anda ingin saya pecah menjadi sub-komponen/file terpisah?"*

---

## PILAR 3: KONTRAK DESIGN SYSTEM, RESPONSIVITAS & ANTI-AI-SLOP (DESIGN SYSTEM RULES)

Setiap pembuatan atau perubahan tampilan antarmuka (UI/UX) di proyek ini **WAJIB** mematuhi standar Design System berikut:

### 3.1 Single Source of Truth untuk Warna & Tipografi (Zero Hardcoded Styles)
1. **Acuan Dokumen & Token Desain:**
   - Seluruh keputusan visual wajib mengacu pada `DESIGN.md` proyek dan file token tema terpusat (misal: `AppColors` & `AppTypography` di Flutter, atau `tailwind.config` / CSS Variables di Web).
   - Jika proyek baru belum memiliki `DESIGN.md` dan file token tema, agen wajib membuatnya terlebih dahulu sebelum membangun halaman UI.
2. **Dilarang Keras Menggunakan Raw Hex / Color & Raw TextStyle:**
   - ❌ **SALAH:** Menulis `Color(0xFF...)`, `Colors.blue`, `#3B82F6`, atau `TextStyle(fontSize: 16)` langsung di dalam komponen/widget.
   - ✅ **BENAR:** Menggunakan token semantik dari sistem tema (`AppColors.primary`, `AppColors.surface`, `AppTypography.titleMedium`, atau class token semantik `bg-surface text-ink`).
3. **Dukungan Tema Terang & Gelap (Light & Dark Mode Parity):**
   - Pastikan setiap token warna yang digunakan mendukung kontras yang nyaman dan terbaca jelas (minimal standar WCAG AA) baik pada Light Mode maupun Dark Mode.

### 3.2 Standar Responsif Multi-Device & Defensive Anti-Overflow
> **ATURAN MUTLAK UI:** Setiap halaman, komponen, dialog, bottom sheet, atau card **WAJIB responsif di berbagai ukuran layar** (Mobile/Compact `< 600px`, Tablet/Foldable/Medium `600-839px`, Desktop/Expanded `≥ 840px`).

1. **Adaptasi Layout per Ukuran Layar:**
   - Gunakan layout satu kolom pada layar kecil (Mobile), dan adaptasikan menjadi multi-kolom / split-view atau berikan batasan lebar maksimal (`maxWidth` container) pada layar besar (Tablet/Desktop) agar teks dan form tidak meregang terlalu lebar.
2. **Pencegahan Overflow (Defensive Layout):**
   - Bungkus konten vertikal yang berpotensi melebihi tinggi layar atau terdorong keyboard virtual dengan container scrollable (`SingleChildScrollView` / `ListView` / `overflow-y-auto`).
   - Bungkus teks dinamis di dalam baris (`Row` / `flex`) dengan `Expanded` / `Flexible` / `min-w-0 truncate` agar tidak memicu error *RenderFlex overflow* atau merusak layout saat teks panjang.
3. **Ergonomi Sentuhan (Touch Targets):**
   - Seluruh tombol, ikon interaktif, dan chip wajib memiliki area sentuh/klik minimal **$48\times 48\text{ dp/px}$**.

### 3.3 Kelengkapan 6 State Antarmuka (6 Mandatory UI States)
Jangan hanya membuat tampilan saat data berhasil dimuat (*happy path*). Setiap layar/komponen berbasis data wajib menangani:
1. **Loading State:** Skeleton loader atau indikator muat yang rapi.
2. **Empty State:** Tampilan informatif dan ramah saat data masih kosong beserta tombol aksi (CTA).
3. **Error State:** Pesan kesalahan yang manusiawi (bukan raw exception) disertai tombol *Coba Lagi (Retry)*.
4. **Success / Normal State:** Tampilan utama saat data tersedia.
5. **Offline / Network State:** Indikator atau penanganan anggun saat koneksi terputus (jika relevan).
6. **Long Content State:** Penanganan saat nama user, judul, atau deskripsi sangat panjang (ellipsis/wrapping rapi).

### 3.4 Anti-AI-Slop & Lokalisasi
1. **Bebas dari Estetika "AI Slop":**
   - Hindari gradien ungu-biru neon klise, bayangan berlebihan yang kotor, tata letak kartu generik yang membosankan, dan copywriting penuh kata klise AI.
2. **Kepatuhan Lokalisasi (Jika Proyek Multi-Bahasa):**
   - Jika proyek menerapkan multi-bahasa (i18n / `AppStrings` / `.tr`), dilarang keras menulis string UI secara hardcode di dalam komponen. Daftarkan seluruh teks ke kamus bahasa yang tersedia.

---

## PILAR 4: MODE MENTOR & PENJELASAN BAHASA AWAM (MENTOR & EXPLAIN-AS-YOU-CODE)

Pengguna ingin terus belajar dan memahami alasan di balik setiap keputusan teknis secara mendalam namun dengan bahasa yang mudah dicerna.

### 4.1 Kewajiban Blok "🎓 Pojok Mentor" di Akhir Setiap Respons Koding/Perubahan
Setiap kali agen selesai menulis kode baru, mengubah kode, memperbaiki bug, atau merancang solusi teknis, agen **WAJIB** menyertakan bagian khusus di akhir respons dengan format berikut:

```markdown
---
### 🎓 Pojok Mentor: Kenapa Solusi Ini Dipilih?

1. **Analogi Sederhana (Bahasa Awam):**
   [Jelaskan konsep teknis atau perubahan yang baru saja dibuat menggunakan perumpamaan sehari-hari yang sangat mudah dibayangkan oleh orang awam, tanpa jargon rumit.]

2. **Bagaimana Kode Ini Bekerja (Step-by-Step):**
   - **Langkah 1:** [Jelaskan bagian/file mana yang menerima input atau pemicu awal]
   - **Langkah 2:** [Jelaskan bagaimana data/logika diproses di balik layar]
   - **Langkah 3:** [Jelaskan hasil akhirnya di layar atau database]

3. **Kenapa Pakai Cara Ini? (Alasan Teknis & Trade-off):**
   - **Alasan Pemilihan:** [Jelaskan secara jujur dan detail kenapa solusi/algoritma/komponen ini adalah pilihan terbaik untuk proyek ini—misalnya karena hemat memori, mengikuti fungsi yang sudah ada di `/common`, atau mencegah layar freeze.]
   - **Kenapa Tidak Pakai Cara Lain:** [Sebutkan singkat 1 alternatif lain dan kenapa kita menghindarinya—misalnya karena terlalu rumit/over-engineering atau boros kuota query.]
```

### 4.2 Prinsip Komunikasi Mentor
- **Sederhana tapi Tidak Dangkal:** Gunakan bahasa sehari-hari yang santai dan mudah dimengerti ("anggap pengguna masih awam"), namun tetap jelaskan *alasan teknis sebenarnya* secara akurat sehingga pemahaman rekayasa pengguna terus meningkat di setiap fitur yang dibangun.
- **Tunjukkan Reuse & Kepatuhan Rules:** Di dalam penjelasan, sebutkan juga skill apa yang baru saja dipakai dan fungsi/komponen `/common` atau `/core` mana yang berhasil di-reuse agar pengguna tahu bagaimana bagian-bagian proyek saling terhubung.
