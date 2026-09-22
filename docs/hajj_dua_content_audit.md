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

| Judul | Kategori | Sumber saat ini | Sumber diketahui | Arab | Transliterasi | Arti Indonesia | Status |
|---|---|---|---|---|---|---|---|
| Bacaan Talbiyah | Ihram & Talbiyah | Implementasi dashboard lama | Tidak | Ada | Ada, tetapi berakhir dengan elipsis | Ada, tetapi berakhir dengan elipsis | Perlu verifikasi kelengkapan teks, transliterasi, arti, dan rujukan |
| Doa Masuk Masjidil Haram | Masuk Masjidil Haram | Implementasi dashboard lama | Tidak | Ada | Ada | Ada | Perlu verifikasi transliterasi dan rujukan |
| Antara Rukun Yamani dan Hajar Aswad | Thawaf | Implementasi dashboard lama | Tidak | Ada | Ada | Ada | Perlu verifikasi rujukan dan penempatan konteks |

## Kategori tanpa teks terverifikasi

Kategori berikut telah disiapkan dalam struktur navigasi, tetapi sengaja belum diberi teks doa karena tidak ada dataset tepercaya di proyek saat audit:

- Sa'i
- Wukuf di Arafah
- Muzdalifah
- Mina & Jamarat
- Tahallul
- Doa Umum

UI menampilkan status "Konten sedang diverifikasi" untuk kategori tersebut. Hal ini mencegah aplikasi mengarang teks Arab, transliterasi, arti, hadis, ayat, atau hukum agama.

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
