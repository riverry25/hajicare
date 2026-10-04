# HajiCare — Antigravity Execution Prompt
## Refactor Money Recognition menjadi Multi-Currency Photo Recognition (SAR, IDR, USD)

Saya ingin melakukan refactor fitur **Money Recognition** pada aplikasi Flutter **HajiCare**.

> **PENTING:** fitur ini **BUKAN real-time video recognition**.

Workflow aplikasi harus tetap:

```text
Camera Preview
→ User menekan tombol foto
→ Ambil 1 still image
→ Pause camera
→ Smart Multi-Pass inference terhadap foto
→ Deteksi seluruh uang pada foto
→ Deduplicate bounding box
→ Hitung nominal
→ Konversi mata uang
→ Tampilkan hasil
→ Bacakan hasil menggunakan TTS
```

Jangan mengubah fitur menjadi continuous real-time inference.

Existing photo-based workflow harus tetap dipertahankan.

---

# 1. KONTEKS IMPLEMENTASI EXISTING

Saat ini fitur Money Recognition hanya ditujukan untuk **Saudi Riyal (SAR)**.

Existing implementation sudah memiliki:

- Flutter
- GetX
- `ultralytics_yolo`
- local TFLite YOLO model
- still-photo capture
- bounding box
- Smart Multi-Pass detection
- Original Image inference
- Enhanced Image inference
- Tiled/Cropped inference
- Cross-pass IoU deduplication
- multi-object detection
- penjumlahan beberapa uang
- SAR → IDR conversion
- Exchange Rate API
- manual exchange-rate override
- Text-to-Speech
- accessibility untuk jamaah/tunanetra
- retake photo
- torch
- camera switching

File/komponen existing yang harus dipelajari sebelum melakukan perubahan antara lain:

```text
MoneyRecognitionScreen
MoneyDetection
SmartMultiPassDetector
MultiPassDetectionResult
CurrencyRateService
MoneyTtsService
RiyalCurrencyHelper
MoneyBoundingBoxPainter
```

Jangan rewrite project secara buta.

Pelajari implementation existing dan lakukan refactor secara incremental.

---

# 2. TARGET FITUR BARU

Model terbaru sekarang harus mendukung 3 mata uang:

```text
SAR — Saudi Riyal
IDR — Indonesian Rupiah
USD — United States Dollar
```

Aplikasi harus dapat mendeteksi beberapa uang sekaligus dari **SATU FOTO**.

Contoh:

```text
Foto:
10 SAR
5 SAR

Hasil:
10 SAR + 5 SAR
Total = 15 SAR
```

Kemudian user dapat melihat konversinya, misalnya:

```text
15 SAR
≈ Rp xxx.xxx
≈ $x.xx
```

TTS juga harus membacakan hasil tersebut.

---

# 3. MULTI-CURRENCY MULTI-OBJECT DETECTION

Model terbaru dapat menghasilkan beberapa bounding box dalam satu foto.

Setiap physical banknote/coin harus tetap menjadi satu `MoneyDetection`.

Contoh:

```text
Foto:

10 SAR
5 SAR
100000 IDR
20 USD
```

Maka hasil detection harus berisi 4 physical objects.

JANGAN menggabungkan uang hanya karena nominalnya sama.

Contoh:

```text
5 SAR di kiri
5 SAR di kanan
```

adalah dua uang berbeda dan total harus:

```text
10 SAR
```

Existing IoU-based physical-object deduplication harus tetap dipertahankan.

---

# 4. PERBAIKI DOMAIN MODEL

Existing `MoneyDetection` saat ini pada dasarnya berorientasi Riyal.

Refactor sehingga setiap detection mengetahui minimal:

```dart
enum CurrencyCode {
  sar,
  idr,
  usd,
}
```

Kemudian:

```dart
class MoneyDetection {
  final String className;

  final CurrencyCode currency;

  final double amount;

  final double confidence;

  final Rect box;
  final Rect normalizedBox;

  final bool isCoin;

  final String displayName;
  final String spokenName;
}
```

Boleh sesuaikan constructor dan struktur dengan codebase existing.

Yang penting:

```text
currency
```

menjadi bagian dari domain object, bukan ditebak oleh UI.

---

# 5. JANGAN PAKAI RIYALCURRENCYHELPER UNTUK SEMUA CURRENCY

Saat ini terdapat:

```dart
RiyalCurrencyHelper.getInfo(res.className)
```

Ini harus direfactor.

Buat generic parser/helper seperti:

```text
MoneyCurrencyHelper
```

atau:

```text
MoneyClassParser
```

Tanggung jawabnya:

```text
YOLO class label
→ currency
→ denomination
→ display name
→ spoken name
→ banknote/coin
```

Contoh:

```text
"10 riyal"
→ SAR
→ 10

"5 riyal"
→ SAR
→ 5

"100000 rupiah"
→ IDR
→ 100000

"20 dollar"
→ USD
→ 20
```

Gunakan EXACT label mapping berdasarkan `labels.txt` model terbaru yang benar-benar terdapat di project.

Jangan mengarang nama class.

Scan dahulu:

```text
assets/models/labels.txt
```

atau label metadata model yang digunakan.

Mapping harus centralized.

Jangan membuat banyak `contains("riyal")`, `contains("dollar")`, dan `contains("rupiah")` tersebar di project.

---

# 6. SANGAT PENTING: TOTALAMOUNT TIDAK BOLEH LAGI GLOBAL SCALAR

Saat ini:

```dart
final double totalAmount;
```

dan:

```dart
final double totalAmount = finalDetections.fold(
  0.0,
  (sum, item) => sum + item.amount,
);
```

hanya aman ketika semua detection adalah SAR.

Dengan 3 currencies implementation ini SALAH.

Contoh:

```text
10 SAR
$20 USD
Rp50.000
```

tidak boleh menjadi:

```text
50030
```

Refactor hasil pipeline menjadi currency-aware.

Gunakan contoh struktur:

```dart
class MultiPassDetectionResult {
  final List<MoneyDetection> finalDetections;

  final Map<CurrencyCode, double> totalsByCurrency;

  final List<PassResult> passResults;

  final int totalExecutionTimeMs;
}
```

Contoh hasil:

```dart
{
  CurrencyCode.sar: 15.0,
  CurrencyCode.usd: 20.0,
  CurrencyCode.idr: 100000.0,
}
```

Buat helper generic untuk menghitung:

```dart
Map<CurrencyCode, double> calculateTotalsByCurrency(
  List<MoneyDetection> detections,
)
```

---

# 7. BEHAVIOR PENJUMLAHAN

## Scenario A — Semua uang mata uang yang sama

Foto:

```text
10 SAR
5 SAR
50 SAR
```

Hasil:

```text
Detected:
10 SAR
5 SAR
50 SAR

Total SAR:
65 SAR

Conversion:
≈ Rp ...
≈ $...
```

Foto:

```text
Rp100.000
Rp50.000
Rp20.000
```

Hasil:

```text
Total IDR:
Rp170.000

≈ ... SAR
≈ $...
```

Foto:

```text
$20
$10
$5
```

Hasil:

```text
Total USD:
$35

≈ ... SAR
≈ Rp ...
```

---

# 8. SUPPORT MIXED-CURRENCY PHOTO

Model harus tetap aman jika user memasukkan beberapa currency dalam satu foto.

Contoh:

```text
10 SAR
5 SAR
20 USD
100000 IDR
```

Jangan menjumlahkan raw numeric values.

Tampilkan:

```text
TOTAL PER MATA UANG

SAR
15 SAR

USD
$20

IDR
Rp100.000
```

Kemudian aplikasi dapat menghitung **grand total equivalent** berdasarkan target currency yang dipilih.

Contoh target:

```text
IDR
```

Maka:

```text
Grand Total dalam IDR =
convert(15 SAR → IDR)
+
convert(20 USD → IDR)
+
100000 IDR
```

Target lain:

```text
USD

convert(15 SAR → USD)
+
20 USD
+
convert(100000 IDR → USD)
```

atau:

```text
SAR

15 SAR
+
convert(20 USD → SAR)
+
convert(100000 IDR → SAR)
```

Buat perhitungan generic.

Jangan membuat formula khusus per pasangan.

---

# 9. GENERIC MONEY AGGREGATOR

Buat service/domain utility seperti:

```text
MoneyAggregator
```

Contoh API:

```dart
Map<CurrencyCode, double> totalsByCurrency(
  List<MoneyDetection> detections,
);
```

dan jika diperlukan:

```dart
Future<double> grandTotalIn({
  required Map<CurrencyCode, double> totals,
  required CurrencyCode targetCurrency,
});
```

Money detection engine bertanggung jawab terhadap:

```text
object detection
classification
bounding box
deduplication
```

Money aggregation bertanggung jawab terhadap:

```text
grouping
sum denomination
```

Currency conversion bertanggung jawab terhadap:

```text
exchange rate
cross-currency calculation
```

Jangan mencampurkan semuanya dalam `SmartMultiPassDetector`.

---

# 10. SMART MULTI-PASS HARUS TETAP DIPERTAHANKAN

Existing pipeline:

```text
PASS 1
Original image

PASS 2
Enhanced image

PASS 3
Tiled inference

↓

Cross-pass IoU merge
```

sudah sesuai dengan photo-based detection.

Pertahankan mekanisme ini.

JANGAN menggantinya dengan:

```text
consecutive video frames
frame stabilization
camera stream detection
```

karena aplikasi saya bukan real-time recognition.

Yang perlu direfactor hanya supaya Smart Multi-Pass menjadi currency-agnostic.

Contoh:

ubah:

```dart
final info = RiyalCurrencyHelper.getInfo(res.className);
```

menjadi generic parser:

```dart
final info = MoneyClassParser.parse(res.className);
```

Kemudian:

```dart
MoneyDetection(
  currency: info.currency,
  amount: info.amount,
  ...
)
```

Lakukan ini juga pada tiled inference.

---

# 11. PERBAIKI CROSS-PASS DEDUPLICATION

Existing implementation membandingkan:

```dart
existing.className.toLowerCase() ==
candidate.className.toLowerCase()
```

dan IoU.

Pastikan behavior berikut tetap berlaku:

```text
same physical object
+
same class
+
high IoU

→ merge
```

Tetapi:

```text
same denomination
different physical position

→ JANGAN merge
```

Contoh dua lembar 5 SAR:

```text
5 SAR kiri
5 SAR kanan
```

tetap dua detection.

Cross-pass detection terhadap lembar yang sama:

```text
Pass 1 → 5 SAR
Pass 2 → 5 SAR
Pass 3 → 5 SAR

IoU tinggi
```

harus menjadi satu physical detection.

Untuk keamanan, identity comparison boleh menggunakan:

```text
currency + denomination/class + IoU
```

bukan denomination saja.

---

# 12. EXCHANGE RATE SERVICE HARUS GENERIC

Existing implementation saat ini berorientasi:

```text
SAR → IDR
```

Refactor menjadi generic:

```dart
Future<double> convert({
  required double amount,
  required CurrencyCode from,
  required CurrencyCode to,
});
```

Harus mendukung:

```text
SAR → IDR
SAR → USD

IDR → SAR
IDR → USD

USD → SAR
USD → IDR
```

Jika:

```dart
from == to
```

langsung return:

```dart
amount
```

tanpa network request.

---

# 13. EXCHANGE RATE TIDAK BOLEH HARDCODED

Gunakan Exchange Rate API existing.

Tidak boleh menggunakan production calculation seperti:

```dart
1 USD = 16000;
1 SAR = 4300;
```

Default/fallback boleh tersedia hanya sebagai fallback yang jelas jika memang existing implementation membutuhkannya.

Primary conversion harus menggunakan dynamic exchange rate.

---

# 14. CROSS RATE

Jika provider API menggunakan satu base currency, hitung cross-rate secara generic.

Contoh response:

```text
base USD

USD = 1
SAR = A
IDR = B
```

Maka conversion harus dapat menghasilkan:

```text
SAR ↔ USD
SAR ↔ IDR
IDR ↔ USD
```

tanpa hardcoded pair.

---

# 15. CACHE EXCHANGE RATE

Karena user hanya mengambil satu foto lalu melihat hasil, exchange rate tidak perlu di-fetch berkali-kali.

Implementasikan:

```text
API
↓
ExchangeRateRepository
↓
Cache
↓
CurrencyConversionService
```

Gunakan TTL yang wajar, misalnya 15–60 menit atau sesuaikan provider existing.

Jangan fetch ulang untuk setiap detection.

Contoh foto memiliki:

```text
10 SAR
5 SAR
20 SAR
50 SAR
```

tidak boleh menyebabkan 4 HTTP requests.

Semua conversion harus memakai rate cache yang sama.

---

# 16. OFFLINE BEHAVIOR

TFLite detection harus tetap bekerja offline.

Jika internet tidak tersedia:

```text
Photo capture         ✅
YOLO inference        ✅
Multi-pass            ✅
Bounding boxes        ✅
Currency recognition  ✅
Nominal recognition   ✅
Sum                    ✅
TTS                    ✅
```

Jika cached rate tersedia:

```text
Conversion ✅
```

Jika rate belum tersedia:

```text
Detection tetap tampil
Conversion = Tidak tersedia
```

Jangan membuat seluruh result screen gagal hanya karena Exchange Rate API gagal.

---

# 17. RESULT SCREEN BARU

Existing text seperti:

```text
Hasil Deteksi Riyal
TOTAL NOMINAL RIYAL
SETARA RUPIAH
```

harus menjadi generic.

Contoh:

```text
Hasil Deteksi Uang
```

Jika hanya SAR:

```text
3 Uang Terdeteksi

10 SAR
5 SAR
50 SAR

TOTAL
65 SAR

Setara:
≈ Rp ...
≈ $...
```

Jika hanya IDR:

```text
TOTAL
Rp170.000

Setara:
≈ ... SAR
≈ $...
```

Jika hanya USD:

```text
TOTAL
$35.00

Setara:
≈ ... SAR
≈ Rp ...
```

---

# 18. MIXED CURRENCY RESULT UI

Untuk foto:

```text
10 SAR
5 SAR
20 USD
Rp100.000
```

tampilkan:

```text
4 Uang Terdeteksi

RINCIAN

10 SAR
5 SAR
$20
Rp100.000

TOTAL PER MATA UANG

Saudi Riyal
15 SAR

US Dollar
$20

Rupiah Indonesia
Rp100.000
```

Kemudian berikan bagian:

```text
TOTAL SETARA
```

dengan target selectable:

```text
IDR | SAR | USD
```

Default target boleh:

```text
IDR
```

karena pengguna utama HajiCare adalah pengguna Indonesia.

Tetapi implementasikan dengan generic currency target state.

Misalnya:

```dart
CurrencyCode _conversionTarget = CurrencyCode.idr;
```

Kemudian:

```text
Total Setara Rupiah
Rp xxx.xxx
```

User bisa memilih:

```text
SAR
USD
IDR
```

tanpa melakukan inference ulang.

Hanya conversion calculation yang berubah.

---

# 19. JANGAN INFERENCE ULANG SAAT TARGET CONVERSION DIGANTI

Jika user sudah foto:

```text
10 SAR + 5 SAR
```

dan memilih:

```text
IDR
```

kemudian berubah ke:

```text
USD
```

JANGAN menjalankan YOLO lagi.

Gunakan:

```text
existing detections
+
existing totalsByCurrency
+
cached exchange rates
```

untuk menghitung nilai baru.

---

# 20. TTS ADALAH FITUR UTAMA ACCESSIBILITY

Aplikasi HajiCare dipakai juga untuk membantu user tunanetra.

Jangan treat TTS sebagai fitur tambahan.

Refactor `MoneyTtsService` supaya mendukung SAR, IDR, dan USD.

TTS harus membacakan hasil setelah foto selesai dianalisis.

---

# 21. TTS — SINGLE CURRENCY

Foto:

```text
10 SAR
5 SAR
```

TTS yang natural:

```text
Terdeteksi dua uang.
Sepuluh Riyal dan lima Riyal.
Total lima belas Riyal Saudi.
Setara sekitar [nilai] Rupiah
dan [nilai] Dolar Amerika.
```

Tidak perlu menyebut confidence kepada user melalui suara kecuali memang diperlukan.

Foto:

```text
Rp100.000
Rp50.000
```

TTS:

```text
Terdeteksi dua uang.
Seratus ribu Rupiah dan lima puluh ribu Rupiah.
Total seratus lima puluh ribu Rupiah.
Setara sekitar [nilai] Riyal Saudi
dan [nilai] Dolar Amerika.
```

Foto:

```text
$20
$5
```

TTS:

```text
Terdeteksi dua uang.
Dua puluh Dolar Amerika dan lima Dolar Amerika.
Total dua puluh lima Dolar Amerika.
Setara sekitar [nilai] Rupiah
dan [nilai] Riyal Saudi.
```

---

# 22. TTS — MIXED CURRENCY

Contoh detection:

```text
10 SAR
5 SAR
20 USD
Rp100.000
```

TTS harus natural dan tidak membingungkan:

```text
Terdeteksi empat uang.

Sepuluh Riyal Saudi,
lima Riyal Saudi,
dua puluh Dolar Amerika,
dan seratus ribu Rupiah.

Total per mata uang:
lima belas Riyal Saudi,
dua puluh Dolar Amerika,
dan seratus ribu Rupiah.

Jika seluruhnya dikonversikan ke Rupiah,
total setara sekitar [nilai] Rupiah.
```

Jika conversion API unavailable:

```text
Terdeteksi empat uang.

Total:
lima belas Riyal Saudi,
dua puluh Dolar Amerika,
dan seratus ribu Rupiah.

Konversi mata uang sedang tidak tersedia.
```

Detection announcement tetap harus berfungsi.

---

# 23. REPLAY VOICE

Existing:

```text
Bacakan Suara
```

harus tetap tersedia.

Tetapi jangan recompute YOLO saat replay.

Replay menggunakan:

```text
_capturedDetections
totalsByCurrency
conversion result
```

yang sudah tersedia.

TTS harus berhenti jika voice dimatikan.

Existing mute behavior harus dipertahankan.

---

# 24. NUMBER-TO-SPEECH

Pastikan spoken amount natural dalam Bahasa Indonesia.

Contoh:

```text
SAR 15
→ lima belas Riyal Saudi

IDR 150000
→ seratus lima puluh ribu Rupiah

USD 25
→ dua puluh lima Dolar Amerika
```

Untuk decimal denomination/koin gunakan spoken representation yang sesuai.

Jangan mengandalkan formatted UI string untuk TTS.

Gunakan raw numeric values + currency metadata.

---

# 25. PERBAIKI HELPER

`RiyalCurrencyHelper` tidak boleh lagi menjadi pusat fitur.

Refactor menjadi komponen generic seperti:

```text
CurrencyFormatter
MoneyClassParser
CurrencyMetadata
MoneySpeechFormatter
```

Contoh responsibility:

```text
CurrencyFormatter
→ SAR / IDR / USD display

MoneyClassParser
→ model class → MoneyInfo

MoneySpeechFormatter
→ numeric money → Indonesian spoken text
```

Jangan membuat satu giant helper.

---

# 26. FORMAT CURRENCY

Gunakan formatter berdasarkan currency.

IDR:

```text
Rp100.000
Rp1.500.000
```

USD:

```text
$20.00
$100.00
```

SAR:

```text
15 SAR
50 SAR
```

Jika SAR coin memiliki decimal:

```text
0.50 SAR
```

Gunakan locale-aware formatting jika infrastructure project mendukung.

---

# 27. BOUNDING BOX LABEL

Existing bounding box badge menggunakan:

```dart
detection.displayName
```

Pertahankan.

Tetapi tampilkan currency secara jelas.

Contoh:

```text
10 SAR (96%)
Rp100.000 IDR (94%)
$20 USD (97%)
```

atau display label yang lebih clean berdasarkan design existing.

---

# 28. WARNA BOUNDING BOX

Existing:

```dart
getDenominationColor(double amount, bool isCoin)
```

mengasumsikan denomination SAR.

Ini tidak scalable karena:

```text
100 IDR
100 USD
100 SAR
```

tidak seharusnya diperlakukan sama berdasarkan angka nominal saja.

Refactor menjadi:

```dart
getDetectionColor(MoneyDetection detection)
```

atau:

```dart
getCurrencyColor(
  CurrencyCode currency,
  double amount,
  bool isCoin,
)
```

Pilih strategy warna yang konsisten dan accessible.

Boleh:

```text
warna utama berdasarkan currency
```

atau struktur lain yang cocok dengan UI.

Jangan menggunakan threshold SAR:

```dart
amount >= 500
amount >= 200
...
```

secara global.

---

# 29. CAMERA UI

Existing camera flow dipertahankan:

```text
camera
shutter
torch
switch camera
tap to focus
viewfinder
voice toggle
```

Tetapi copywriting yang masih spesifik Riyal harus diganti.

Contoh:

ubah:

```text
captureRiyal
```

menjadi generic:

```text
captureMoney
```

jika localization infrastructure mendukung.

Tetapi lakukan migration dengan aman agar localization tidak rusak.

---

# 30. EXCHANGE RATE TOP BAR

Jangan lagi hanya tampilkan:

```text
1 SAR ≈ Rp ...
```

Karena aplikasi sekarang mendukung 3 currencies.

Gunakan UI yang lebih generic seperti:

```text
Kurs Mata Uang
```

atau tampilkan reference utama secara compact.

Klik area tersebut membuka currency conversion/rate sheet.

Jangan memenuhi camera UI dengan terlalu banyak nilai exchange rate.

---

# 31. REFACTOR EXCHANGE RATE BOTTOM SHEET

Existing:

```text
Pengaturan Kurs Riyal
```

harus menjadi generic seperti:

```text
Kurs Mata Uang
```

Jika manual override tetap dipertahankan, manual rate harus jelas pasangan mata uangnya.

Jangan menggunakan satu:

```dart
double _exchangeRate;
```

untuk semua currency.

Gunakan struktur seperti:

```dart
Map<CurrencyPair, double>
```

atau preferably base-rate structure:

```dart
ExchangeRateSnapshot {
  CurrencyCode base;
  Map<CurrencyCode, double> rates;
  DateTime updatedAt;
}
```

sesuai response API existing.

---

# 32. JANGAN BIKIN 6 VARIABLE RATE

Hindari:

```dart
double sarToIdr;
double sarToUsd;
double idrToSar;
double idrToUsd;
double usdToSar;
double usdToIdr;
```

Gunakan generic conversion engine.

Misalnya:

```dart
rate(from, to)
convert(amount, from, to)
```

---

# 33. MANUAL OVERRIDE

Existing manual SAR→IDR rate dapat dipertahankan jika masih diperlukan.

Tetapi refactor supaya manual override memiliki explicit currency pair:

```text
SAR → IDR
USD → IDR
...
```

atau gunakan base rate yang consistent.

Jangan sampai user mengubah satu rate lalu calculation currency lain menjadi mathematically inconsistent.

Jika manual rate architecture menjadi terlalu kompleks, prioritaskan API rates sebagai source of truth dan pertahankan fallback existing secara aman.

---

# 34. MODEL CONFIGURATION

Saat ini terdapat:

```dart
static const String _modelAssetPath =
    'assets/models/best_float16.tflite';
```

Periksa model terbaru di project.

Pastikan:

- TFLite model baru yang digunakan memang model SAR + IDR + USD.
- labels cocok dengan model.
- input/output tensor tidak diasumsikan dari model lama.
- jangan hardcode jumlah labels = 14 jika model baru berbeda.
- jangan mempertahankan debug text `[RIYAL]`.

Ubah log menjadi generic:

```text
[MoneyAI]
```

Contoh:

```text
[MoneyAI] Multi-currency model ready
[MoneyAI] model = ...
[MoneyAI] detected = SAR 10 confidence=0.96
```

---

# 35. PERIKSA OUTPUT MODEL, JANGAN ASUMSI

Existing debug:

```text
input = [1, 640, 640, 3]
output = [1, 300, 6]
labels = 14
```

Jangan mengasumsikan metadata model baru identik.

Inspect actual model/labels/inference implementation.

Jika plugin `ultralytics_yolo` sudah melakukan post-processing, gunakan contract library tersebut.

Jangan membuat custom tensor parser baru tanpa kebutuhan.

---

# 36. MULTIPASS RESULT

Target ideal:

```dart
class MultiPassDetectionResult {
  final List<MoneyDetection> finalDetections;

  final Map<CurrencyCode, double> totalsByCurrency;

  final List<PassResult> passResults;

  final int totalExecutionTimeMs;

  const MultiPassDetectionResult({
    required this.finalDetections,
    required this.totalsByCurrency,
    required this.passResults,
    required this.totalExecutionTimeMs,
  });
}
```

Optional convenience:

```dart
double totalFor(CurrencyCode currency)
```

Tetapi jangan simpan duplicated state yang mudah tidak sinkron.

---

# 37. SCREEN STATE

Existing:

```dart
double _totalAmount = 0.0;
```

refactor misalnya:

```dart
Map<CurrencyCode, double> _totalsByCurrency = {};
```

dan:

```dart
CurrencyCode _conversionTarget = CurrencyCode.idr;
```

Optional:

```dart
double? _convertedGrandTotal;
Map<CurrencyCode, double> _convertedTotals = {};
```

sesuaikan dengan architecture terbaik.

---

# 38. CAPTURE FLOW YANG DIINGINKAN

Target `_captureAndAnalyze()`:

```text
1. Validate model ready

2. mode = processing

3. Capture still photo

4. Pause camera

5. Decode original image size

6. SmartMultiPassDetector.processImage(photo)

7. Receive:
   - final detections
   - totalsByCurrency
   - execution metadata

8. Request/read cached FX rates

9. Calculate conversions

10. mode = result

11. Speak accessible result ONCE
```

Jika FX gagal:

```text
step 8 gagal
↓
jangan throw seluruh capture process
↓
tetap tampilkan detection result
↓
TTS tetap bacakan nominal
```

Sangat penting:

**API conversion error bukan inference error.**

---

# 39. JANGAN MASUKKAN FX API KE TRY/CATCH YANG MEMBATALKAN SELURUH DETECTION

Current `_captureAndAnalyze()` memiliki satu broad try/catch.

Refactor agar kegagalan:

```text
Currency API
```

tidak menyebabkan:

```text
_mode kembali ke camera
"Uang Belum Terbaca"
```

karena uang sebenarnya mungkin sudah berhasil dikenali.

Pisahkan error boundaries:

```text
CAPTURE ERROR
MODEL ERROR
INFERENCE ERROR
EXCHANGE RATE ERROR
TTS ERROR
```

TTS failure juga tidak boleh menghilangkan result screen.

---

# 40. TTS FAILURE TIDAK BOLEH FAIL DETECTION

Ideal:

```dart
try {
  await _ttsService.speakResults(...);
} catch (e) {
  debugPrint('[MoneyTTS] ...');
}
```

Result screen tetap tampil.

---

# 41. NO-DETECTION CONDITION

Jika hasil YOLO:

```text
[]
```

tetap tampilkan behavior existing yang sesuai.

Jangan menghasilkan:

```text
0 SAR
0 USD
0 IDR
```

seolah-olah hasil valid.

UI harus menunjukkan:

```text
Belum Ada Uang Terdeteksi
```

dan memungkinkan:

```text
Pindai Lagi
```

---

# 42. DETECTION LIST

Setiap detection result card menampilkan:

```text
currency
denomination
banknote/coin
confidence
converted values jika relevan
```

Contoh:

```text
50 SAR
Uang Kertas • Akurasi 96%

≈ Rp ...
≈ $...
```

Contoh:

```text
Rp100.000
Uang Kertas • Akurasi 95%

≈ ... SAR
≈ $...
```

Tetapi jangan membuat UI terlalu penuh.

Prioritaskan:

```text
detected denomination
currency
confidence
```

dan total/conversion pada summary card.

---

# 43. ACCESSIBILITY

Fitur ini ditujukan juga untuk membantu tunanetra.

Pastikan:

- semantics label meaningful
- button punya spoken label
- jangan mengandalkan warna saja
- TTS menggunakan Bahasa Indonesia natural
- hasil total mudah direplay
- voice state tetap konsisten
- screen reader memperoleh informasi currency + amount
- touch target tetap besar
- existing elderly-friendly sizing dipertahankan

---

# 44. CONVERSION LOGIC UNTUK MIXED CURRENCY

Implementasikan generic algorithm:

```text
totalsByCurrency
        ↓
targetCurrency
        ↓

for each currency:
    if currency == target:
        converted = original amount
    else:
        converted = FX.convert(
            amount,
            from: currency,
            to: target,
        )

grandTotal += converted
```

Contoh:

```text
SAR = 15
USD = 20
IDR = 100000

target = IDR

grandTotal =
  convert(15 SAR → IDR)
+ convert(20 USD → IDR)
+ 100000
```

---

# 45. PRESERVE ORIGINAL VALUES

Jangan mengganti original detected amount dengan converted amount.

Always preserve:

```text
original currency
original amount
```

Conversion hanya derived data.

---

# 46. PRECISION

Currency calculation jangan melakukan pembulatan terlalu awal.

Gunakan full numeric precision saat calculation.

Formatting/pembulatan hanya pada presentation layer.

IDR biasanya tampil tanpa decimal.

USD/SAR dapat tampil dengan appropriate decimal digits.

---

# 47. TEST CASE WAJIB

Tambahkan unit tests jika project test infrastructure memungkinkan.

## A — SAR Same Currency

Input:

```text
10 SAR
5 SAR
```

Expected:

```text
detections = 2
totalsByCurrency[SAR] = 15
```

## B — IDR Same Currency

```text
100000 IDR
50000 IDR
20000 IDR
```

Expected:

```text
170000 IDR
```

## C — USD Same Currency

```text
20 USD
10 USD
5 USD
```

Expected:

```text
35 USD
```

## D — Duplicate denomination, different object

```text
5 SAR
5 SAR
```

bounding boxes berbeda.

Expected:

```text
2 detections
total = 10 SAR
```

## E — Same physical object across passes

```text
Pass 1 = 10 SAR
Pass 2 = 10 SAR
Pass 3 = 10 SAR
```

IoU tinggi.

Expected:

```text
1 final detection
total = 10 SAR
```

bukan:

```text
30 SAR
```

## F — Mixed Currency

Input:

```text
10 SAR
5 SAR
20 USD
100000 IDR
```

Expected:

```text
SAR = 15
USD = 20
IDR = 100000
```

Tidak boleh ada raw global total.

## G — Conversion

Test all:

```text
SAR → IDR
SAR → USD

IDR → SAR
IDR → USD

USD → SAR
USD → IDR
```

## H — Same Currency Conversion

```text
100000 IDR → IDR
```

Expected:

```text
100000
```

tanpa network call.

## I — FX API Failure

Detection berhasil tetapi API gagal.

Expected:

```text
Detection result tetap tampil
TTS detection tetap berjalan
Conversion marked unavailable
App tidak crash
```

## J — TTS Failure

Expected:

```text
UI result tetap tampil
```

---

# 48. DEBUG LOGGING

Ganti log:

```text
[RIYAL]
```

menjadi:

```text
[MoneyAI]
[MoneyFX]
[MoneyTTS]
```

Contoh:

```text
[MoneyAI] Detected 4 unique money objects
[MoneyAI] SAR total = 15
[MoneyAI] USD total = 20
[MoneyAI] IDR total = 100000

[MoneyFX] Target = IDR
[MoneyFX] Using cached exchange rates

[MoneyTTS] Speaking detection summary
```

Jangan log API secret.

---

# 49. BACKWARD COMPATIBILITY

Current SAR functionality harus tetap bekerja.

Scenario lama:

```text
Foto:
10 SAR
5 SAR

Detection:
10 SAR + 5 SAR

Total:
15 SAR

Convert:
15 SAR → IDR

TTS:
bacakan 15 SAR dan hasil Rupiah
```

harus tetap bekerja setelah refactor.

Kemudian extend menjadi SAR + IDR + USD.

---

# 50. JANGAN MERUSAK MULTI-PASS EXISTING

Jangan menghapus:

```text
adaptive enhanced pass
adaptive tiled pass
cross-pass confirmation
IoU dedup
candidate threshold
final threshold
image coordinate mapping
captured image result
bounding box overlay
```

kecuali ditemukan bug nyata.

Refactor concern currency tanpa merusak detection quality.

---

# 51. CLEAN ARCHITECTURE YANG DIHARAPKAN

Ideal separation:

```text
Camera / Photo Capture
        ↓
SmartMultiPassDetector
        ↓
MoneyClassParser
        ↓
List<MoneyDetection>
        ↓
MoneyAggregator
        ↓
Map<CurrencyCode, double>
        ↓
CurrencyConversionService
        ↓
ExchangeRateRepository
        ↓
Result UI
        ↓
MoneyTtsService
```

Responsibilities:

```text
SmartMultiPassDetector
= computer vision

MoneyClassParser
= class metadata

MoneyAggregator
= arithmetic per currency

CurrencyConversionService
= money conversion

MoneyTtsService
= accessibility speech

MoneyRecognitionScreen
= UI orchestration
```

---

# 52. ANTI-PATTERNS YANG DILARANG

Jangan membuat:

```dart
if (currency == "SAR") ...
else if (currency == "USD") ...
else if (currency == "IDR") ...
```

tersebar di banyak file.

Jangan membuat:

```text
SAR total + USD total + IDR total
```

tanpa conversion.

Jangan:

```text
fetch API per banknote
fetch API per bounding box
fetch API per pass
fetch API saat repaint
fetch API saat build()
```

Jangan:

```text
run inference saat user mengganti target currency
```

Jangan:

```text
hapus existing multi-pass
```

Jangan:

```text
mengubah menjadi real-time video detection
```

---

# 53. IMPLEMENTASI SECARA INCREMENTAL

Lakukan urutan berikut:

```text
1. Scan seluruh existing Money Recognition module.

2. Inspect model terbaru dan labels.

3. Identifikasi semua logic yang masih hardcoded SAR/Riyal.

4. Buat CurrencyCode.

5. Refactor MoneyDetection supaya currency-aware.

6. Ganti RiyalCurrencyHelper parser dengan MoneyClassParser generic.

7. Update original-pass inference.

8. Update tiled-pass inference.

9. Pastikan cross-pass merge masih benar.

10. Ganti totalAmount dengan totalsByCurrency.

11. Buat MoneyAggregator.

12. Refactor CurrencyRateService menjadi multi-currency.

13. Tambahkan generic convert().

14. Tambahkan rate caching/fallback.

15. Update result screen.

16. Update mixed-currency result.

17. Update bounding boxes.

18. Refactor MoneyTtsService.

19. Update exchange-rate sheet.

20. Update localization/copywriting.

21. Jalankan analyzer/tests.

22. Perbaiki compile errors.

23. Hapus dead legacy Riyal-specific code hanya setelah replacement bekerja.
```

---

# 54. JANGAN BERHENTI SETELAH MEMBERIKAN SARAN

Saya ingin Anda melakukan perubahan langsung ke codebase.

Jangan hanya menjelaskan bagaimana caranya.

Setelah perubahan:

```bash
flutter analyze
```

dan test yang tersedia harus dijalankan.

Perbaiki error yang muncul akibat refactor.

---

# 55. ACCEPTANCE CRITERIA FINAL

Refactor baru dianggap selesai jika:

## Photo Workflow

- [ ] Tetap photo-based.
- [ ] User harus menekan shutter.
- [ ] Satu foto dianalisis.
- [ ] Tidak berubah menjadi video real-time inference.

## Detection

- [ ] SAR terdeteksi.
- [ ] IDR terdeteksi.
- [ ] USD terdeteksi.
- [ ] Beberapa uang dapat terdeteksi dalam satu foto.
- [ ] Dua uang nominal sama tetap dihitung sebagai dua physical objects.
- [ ] Cross-pass duplicate tidak dihitung ganda.
- [ ] Bounding box tetap akurat.

## Addition

- [ ] 10 SAR + 5 SAR = 15 SAR.
- [ ] Rp100.000 + Rp50.000 = Rp150.000.
- [ ] $20 + $5 = $25.
- [ ] Mixed currency tidak dijumlahkan secara raw.
- [ ] Mixed currency menghasilkan `totalsByCurrency`.

## Conversion

- [ ] SAR ↔ IDR.
- [ ] SAR ↔ USD.
- [ ] IDR ↔ USD.
- [ ] User bisa mengganti target conversion tanpa inference ulang.
- [ ] Mixed currencies dapat dihitung menjadi satu grand total setelah seluruh amount dikonversi ke target yang sama.
- [ ] Dynamic exchange rate API.
- [ ] Cache bekerja.
- [ ] Offline fallback bekerja.

## TTS

- [ ] Hasil SAR dapat dibacakan.
- [ ] Hasil IDR dapat dibacakan.
- [ ] Hasil USD dapat dibacakan.
- [ ] Beberapa lembar uang dibacakan.
- [ ] Total dibacakan.
- [ ] Mixed-currency result dibacakan dengan natural.
- [ ] Conversion result dibacakan jika tersedia.
- [ ] TTS failure tidak membuat detection gagal.
- [ ] Replay voice tetap bekerja.

## Architecture

- [ ] Tidak lagi Riyal-centric.
- [ ] Tidak ada satu global `_totalAmount` untuk mixed currency.
- [ ] Currency menggunakan enum/domain model.
- [ ] Parser centralized.
- [ ] Conversion service generic.
- [ ] UI tidak melakukan HTTP request.
- [ ] SmartMultiPassDetector tidak menangani network.
- [ ] MoneyTtsService tidak melakukan inference.
- [ ] Existing SAR behavior tidak regression.

---

# 56. OUTPUT LAPORAN SETELAH SELESAI

Setelah implementasi selesai, laporkan:

```text
1. Existing architecture yang ditemukan.

2. Hardcoded Riyal logic yang ditemukan.

3. File yang diubah.

4. File baru yang dibuat.

5. File legacy yang dihapus atau deprecated.

6. Struktur MoneyDetection terbaru.

7. Struktur MultiPassDetectionResult terbaru.

8. Cara MoneyClassParser bekerja.

9. Cara multi-object aggregation bekerja.

10. Cara mixed currencies ditangani.

11. Cara generic conversion bekerja.

12. Cara exchange-rate cache bekerja.

13. Cara TTS baru bekerja.

14. Error handling/fallback.

15. Testing yang dijalankan.

16. Output flutter analyze.

17. Risiko/regression yang masih mungkin ada.
```

Untuk setiap file yang diubah, jelaskan secara singkat alasan perubahan.

Prioritas utama:

```text
CORRECTNESS
ACCESSIBILITY
NO DOUBLE COUNTING
MULTI-CURRENCY SAFETY
BACKWARD COMPATIBILITY
MAINTAINABILITY
PERFORMANCE
```

Jangan mengorbankan kemampuan existing untuk mendeteksi dan menjumlahkan beberapa uang dalam satu foto.
