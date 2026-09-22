# Audit Konten Doa & Dzikir Ibadah Haji

Tanggal audit: 22 September 2026

## Ringkasan implementasi sebelum refactor

- Fitur aktif berbentuk bottom sheet di dashboard jamaah.
- Data terdiri dari tiga `Map<String, String>` yang ditulis langsung di dalam widget.
- Salinan data yang sama juga terdapat di `JamaahServiceGrid`, sehingga data dan UI terduplikasi.
- Tidak ada model, repository, pencarian, bookmark, audio, atau sumber konten agama.
- Teks Arab, transliterasi, dan arti tersedia untuk ketiga entri, tetapi tidak ada rujukan yang dicantumkan.
- Label layanan lama menyebut audio, meskipun implementasi fitur tidak menyediakan audio doa.

## Audit per bacaan

| Kategori | Judul | Arab | Transliterasi | Arti ID | Arti EN/JV/SU | Sumber | Duplikat | Placeholder | Status verifikasi |
|---|---|---|---|---|---|---|---|---|---|
| Ihram & Talbiyah | Bacaan Talbiyah | Ada | Ada, tetapi berakhir dengan elipsis | Ada, tetapi berakhir dengan elipsis | Belum ada; fallback ke ID | Tidak ada | Tidak | Tidak | `existing-unverified`, `missing-source` |
| Masuk Masjidil Haram | Doa Masuk Masjidil Haram | Ada | Ada | Ada | Belum ada; fallback ke ID | Tidak ada | Tidak | Tidak | `existing-unverified`, `missing-source` |
| Thawaf | Antara Rukun Yamani dan Hajar Aswad | Ada | Ada | Ada | Belum ada; fallback ke ID | Tidak ada | Tidak | Tidak | `existing-unverified`, `missing-source` |

## Kategori tanpa teks terverifikasi

Kategori berikut telah disiapkan dalam struktur navigasi, tetapi sengaja belum diberi teks doa karena tidak ada dataset tepercaya di proyek saat audit:

- Sa'i
- Wukuf di Arafah
- Muzdalifah
- Mina & Jamarat
- Tahallul
- Doa Umum

Kategori tersebut tidak ditampilkan pada layar utama sampai memiliki sedikitnya satu entri yang dapat digunakan. Model kategorinya tetap tersedia untuk audit dan pengembangan berikutnya. Layar placeholder tidak dapat dicapai melalui navigasi pengguna normal.

## Localization dan tipografi

- UI memakai sistem `AppTranslations`/`context.tr` Hajicare untuk bahasa Indonesia, Inggris, Jawa, dan Sunda.
- Teks Arab kanonik tidak dilokalkan atau diubah ketika bahasa UI berganti.
- Arti yang belum tersedia pada locale lain memakai fallback arti Indonesia, bukan terjemahan buatan.
- Judul memakai Poppins, teks pendukung memakai Montserrat, dan teks Arab memakai Noto Naskh Arabic.
- Ketiga keluarga font dibundel di `assets/fonts` agar tidak membutuhkan jaringan saat runtime.

## Keputusan keamanan konten

- Ketiga teks lama dipertahankan apa adanya; tidak dilengkapi atau "dibersihkan" secara otomatis.
- Tidak ada doa baru, ayat, hadis, sumber, atau klaim hukum yang ditambahkan.
- Bacaan tidak diberi label wajib.
- Bacaan thawaf dijelaskan sebagai bacaan yang dapat dibaca, bukan doa tetap untuk setiap putaran.
- Setiap entri lama menampilkan penanda "Perlu verifikasi sumber" di aplikasi.

## Tindak lanjut manual yang diperlukan

1. Penelaah agama menetapkan sumber tepercaya untuk setiap teks yang ada.
2. Penelaah memeriksa kelengkapan Talbiyah karena teks lama menggunakan elipsis pada transliterasi dan arti.
3. Penelaah memeriksa konsistensi transliterasi Indonesia.
4. Konten untuk enam kategori kosong hanya boleh ditambahkan setelah teks, terjemahan, konteks, dan rujukannya disetujui.
5. Jika sumber URL digunakan, pastikan tautan berasal dari penerbit atau lembaga yang disetujui dan tetap tersedia secara offline di aplikasi.
