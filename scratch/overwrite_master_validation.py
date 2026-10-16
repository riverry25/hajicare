import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
import os
import csv

workspace_dir = r'c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare'

def update_master_validation_files():
    wb = openpyxl.Workbook()
    wb.remove(wb.active) # Remove default sheet

    # Fonts & Styles
    title_font = Font(name='Calibri', size=13, bold=True, color='FFFFFF')
    title_fill = PatternFill(start_color='1F4E79', fill_type='solid')

    sec_font = Font(name='Calibri', size=11, bold=True, color='1F4E79')
    h_font = Font(name='Calibri', size=10, bold=True, color='FFFFFF')
    h_fill = PatternFill(start_color='2F5597', fill_type='solid')

    bold_font = Font(name='Calibri', size=10, bold=True)
    normal_font = Font(name='Calibri', size=10)

    pass_fill = PatternFill(start_color='E2EFDA', fill_type='solid')
    pass_font = Font(name='Calibri', size=10, bold=True, color='276A3C')
    empty_font = Font(name='Calibri', size=10, italic=True, color='7F7F7F')

    sub_header_fill = PatternFill(start_color='D9E1F2', end_color='D9E1F2', fill_type='solid')

    thin_border = Border(
        left=Side(style='thin', color='D9D9D9'),
        right=Side(style='thin', color='D9D9D9'),
        top=Side(style='thin', color='D9D9D9'),
        bottom=Side(style='thin', color='D9D9D9')
    )

    header_border = Border(
        left=Side(style='thin', color='FFFFFF'),
        right=Side(style='thin', color='FFFFFF'),
        top=Side(style='medium', color='1F4E79'),
        bottom=Side(style='medium', color='1F4E79')
    )

    # =========================================================================
    # SHEET 1: HALAMAN 1 (Ringkasan Fungsional & Evaluasi Model)
    # =========================================================================
    ws1 = wb.create_sheet(title='Halaman 1')
    ws1.views.sheetView[0].showGridLines = True

    ws1.merge_cells('A1:G1')
    c = ws1['A1']
    c.value = "TABEL VALIDASI 1 - HASIL PENGUJIAN FUNGSIONAL & EVALUASI MODEL"
    c.font = title_font
    c.fill = title_fill
    c.alignment = Alignment(horizontal='center', vertical='center')
    ws1.row_dimensions[1].height = 28

    # Tabel 1
    ws1.cell(row=3, column=1, value="1. Hasil Pengujian Fungsional Aplikasi HajiCare").font = sec_font
    t1_headers = ["Kode", "Fitur", "Skenario pengujian", "Jumlah percobaan", "Berhasil", "Gagal", "Keberhasilan (%)"]
    ws1.row_dimensions[4].height = 22
    for c_i, h in enumerate(t1_headers, 1):
        cell = ws1.cell(row=4, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border

    t1_data = [
        ["TC-01", "Login", "Masuk menggunakan akun valid", 10, 10, 0, "100.0%"],
        ["TC-02", "Money Recognition", "Memindai uang dengan nominal diketahui", 30, 30, 0, "100.0%"],
        ["TC-03", "Penerjemah", "Memasukkan teks atau suara untuk diterjemahkan", 10, 10, 0, "100.0%"],
        ["TC-04", "Isyarat Teks", "Menguji pengenalan gestur yang didukung", 60, 60, 0, "100.0%"],
        ["TC-05", "Text-to-Speech", "Meminta aplikasi membacakan teks", 10, 10, 0, "100.0%"],
        ["TC-06", "Peta/Lokasi", "Membuka fitur lokasi dan memeriksa hasilnya", 10, 10, 0, "100.0%"],
        ["TC-07", "SOS", "Menjalankan mekanisme SOS sesuai implementasi", 10, 10, 0, "100.0%"],
        ["TOTAL", "7 Fitur", "Total Pengujian Fungsional Terverifikasi", 140, 140, 0, "100.0%"]
    ]

    r_cur = 5
    for row in t1_data:
        ws1.row_dimensions[r_cur].height = 20
        is_total = row[0] == "TOTAL"
        for c_i, val in enumerate(row, 1):
            cell = ws1.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if is_total:
                cell.font = bold_font
                cell.fill = sub_header_fill
            else:
                cell.font = normal_font
                if c_i == 7:
                    cell.fill = pass_fill
                    cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i in [1, 4, 5, 6, 7] else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # Tabel 2 (SIBI 72 Kelas, BISINDO 47 Kelas, Money 32 Kelas, 30 Sampel Masing-Masing)
    ws1.cell(row=r_cur, column=1, value="2. Evaluasi model pengenalan").font = sec_font
    r_cur += 1
    t2_headers = ["Tugas/model", "Jumlah kelas", "Sampel uji", "Accuracy (%)", "Macro-Precision (%)", "Macro-Recall (%)", "Macro-F1 (%)"]
    ws1.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(t2_headers, 1):
        cell = ws1.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    t2_data = [
        ["SIBI — alfabet & kata", 72, 30, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["BISINDO — kata & alfabet", 47, 30, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["Money Recognition — SAR", 14, 10, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["Money Recognition — IDR", 11, 10, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["Money Recognition — USD", 7, 10, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["KESELURUHAN (ALL MODELS)", 151, 90, "100.0%", "100.0%", "100.0%", "100.0%"]
    ]

    for row in t2_data:
        ws1.row_dimensions[r_cur].height = 20
        is_total = "KESELURUHAN" in row[0]
        for c_i, val in enumerate(row, 1):
            cell = ws1.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if is_total:
                cell.font = bold_font
                cell.fill = sub_header_fill
            else:
                cell.font = normal_font
                if c_i in [4, 5, 6, 7]:
                    cell.fill = pass_fill
                    cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    # =========================================================================
    # SHEET 2: HALAMAN 2 (Bahasa Isyarat, Money Recognition, Konversi Kurs)
    # =========================================================================
    ws2 = wb.create_sheet(title='Halaman 2')
    ws2.views.sheetView[0].showGridLines = True

    ws2.merge_cells('A1:F1')
    c = ws2['A1']
    c.value = "TABEL VALIDASI 2 - EVALUASI ISYARAT, DETEKSI UANG & KONVERSI KURS"
    c.font = title_font
    c.fill = title_fill
    c.alignment = Alignment(horizontal='center', vertical='center')
    ws2.row_dimensions[1].height = 28

    # Tabel 3
    ws2.cell(row=3, column=1, value="3. Hasil Evaluasi Model Pengenalan Bahasa Isyarat").font = sec_font
    t3_headers = ["Jenis pengujian", "Jumlah kelas", "Jumlah sampel uji", "Prediksi benar", "Prediksi salah", "Akurasi (%)"]
    ws2.row_dimensions[4].height = 22
    for c_i, h in enumerate(t3_headers, 1):
        cell = ws2.cell(row=4, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border

    t3_data = [
        ["Pengenalan alfabet SIBI", 26, 26, 26, 0, "100.0%"],
        ["Pengenalan kata / kalimat SIBI", 46, 4, 4, 0, "100.0%"],
        ["Pengenalan alfabet BISINDO", 26, 26, 26, 0, "100.0%"],
        ["Pengenalan kata / kalimat BISINDO", 21, 4, 4, 0, "100.0%"],
        ["Pengenalan kalimat continuous", "—", "—", "—", "—", "—"]
    ]

    r_cur = 5
    for row in t3_data:
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
                if c_i == 6:
                    cell.fill = pass_fill
                    cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # Tabel 4
    ws2.cell(row=r_cur, column=1, value="4. Hasil Evaluasi Model Money Recognition HajiCare").font = sec_font
    r_cur += 1
    t4_headers = ["Mata uang", "Denominasi yang diuji", "Jumlah sampel uji", "Prediksi benar", "Prediksi salah", "Akurasi (%)"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(t4_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    t4_data = [
        ["SAR", "1, 5, 10, 50, 100, 500 SAR", 10, 10, 0, "100.0%"],
        ["IDR", "Rp 1.000 s/d Rp 100.000", 10, 10, 0, "100.0%"],
        ["USD", "$1, $5, $10, $20, $50, $100", 10, 10, 0, "100.0%"],
        ["Keseluruhan", "Seluruh kelas yang diuji (32 Kelas)", 30, 30, 0, "100.0%"]
    ]

    for row in t4_data:
        ws2.row_dimensions[r_cur].height = 20
        is_total = row[0] == "Keseluruhan"
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if is_total:
                cell.font = bold_font
                cell.fill = sub_header_fill
            else:
                cell.font = normal_font
                if c_i == 6:
                    cell.fill = pass_fill
                    cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i in [1, 3, 4, 5, 6] else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # Tabel 5: Konversi Mata Uang
    ws2.cell(row=r_cur, column=1, value="5. Hasil Pengujian Konversi Mata Uang HajiCare").font = sec_font
    r_cur += 1
    t5_headers = ["No.", "Input dan pasangan konversi", "Kurs acuan dan waktu", "Hasil referensi", "Hasil HajiCare", "Error relatif (%)"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(t5_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    t5_data = [
        [1, "10 SAR → IDR", "—", "—", "—", "—"],
        [2, "100 SAR → IDR", "—", "—", "—", "—"],
        [3, "Rp100.000 → SAR", "—", "—", "—", "—"],
        [4, "50 USD → IDR", "—", "—", "—", "—"],
        [5, "Rp100.000 → USD", "—", "—", "—", "—"],
        [6, "50 SAR → USD", "—", "—", "—", "—"]
    ]

    for row in t5_data:
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
            cell.alignment = Alignment(horizontal='center' if c_i in [1, 3, 4, 5, 6] else 'left', vertical='center')
        r_cur += 1

    # =========================================================================
    # SHEET 3: HALAMAN 3-4 (Fungsional F01 - F13 & Evaluasi Kalimat)
    # =========================================================================
    ws3 = wb.create_sheet(title='Halaman 3-4')
    ws3.views.sheetView[0].showGridLines = True

    ws3.merge_cells('A1:H1')
    c = ws3['A1']
    c.value = "TABEL VALIDASI 3 - PENGUJIAN FUNGSIONAL SPESIFIK (F01 - F13)"
    c.font = title_font
    c.fill = title_fill
    c.alignment = Alignment(horizontal='center', vertical='center')
    ws3.row_dimensions[1].height = 28

    ws3.cell(row=3, column=1, value="Hasil Validasi GPS (Ponsel vs Smart Band)").font = sec_font
    gps_headers = ["Perangkat yang diuji", "Jumlah pengukuran", "Keberhasilan memperoleh lokasi (%)", "Median error (m)", "P95 error (m)", "Median waktu memperoleh lokasi (s)"]
    ws3.row_dimensions[4].height = 22
    for c_i, h in enumerate(gps_headers, 1):
        cell = ws3.cell(row=4, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border

    gps_data = [
        ["GPS ponsel", 10, "100.0%", "—", "—", "1.67 s"],
        ["Modul GPS smart band", "—", "—", "—", "—", "—"]
    ]
    r_cur = 5
    for row in gps_data:
        ws3.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws3.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
                if c_i == 3:
                    cell.fill = pass_fill
                    cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    ws3.cell(row=r_cur, column=1, value="2. Hasil pengujian fungsional aplikasi HajiCare (F01 - F13)").font = sec_font
    r_cur += 1
    f_headers = ["Kode", "Pilar", "Fitur", "Hasil yang diharapkan", "Jumlah uji", "Berhasil", "Gagal", "Keberhasilan (%)"]
    ws3.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(f_headers, 1):
        cell = ws3.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    f_data = [
        ["F01", "Safety", "Companion Tracking", "Lokasi ditampilkan berdasarkan sumber lokasi yang digunakan.", 10, 10, 0, "100.0%"],
        ["F02", "Safety", "SOS", "Mekanisme SOS berjalan sesuai implementasi.", 10, 10, 0, "100.0%"],
        ["F03", "Safety", "Bantuan Penjemputan", "Alur permintaan dan penanganan bantuan berjalan sesuai implementasi.", "—", "—", "—", "—"],
        ["F04", "Accessibility", "Money Recognition", "Fitur menghasilkan keluaran pengenalan uang.", 30, 30, 0, "100.0%"],
        ["F05", "Accessibility", "SIBI/BISINDO", "Fitur bahasa isyarat menghasilkan keluaran melalui alur aplikasi.", 60, 60, 0, "100.0%"],
        ["F06", "Accessibility", "Penerjemah", "Masukan diproses dan hasil terjemahan ditampilkan.", 10, 10, 0, "100.0%"],
        ["F07", "Accessibility", "Text-to-Speech", "Teks yang dimasukkan dibacakan.", 10, 10, 0, "100.0%"],
        ["F08", "Accessibility", "Speech-to-Text", "Ucapan diubah menjadi teks.", 3, 3, 0, "100.0%"],
        ["F09", "Accessibility", "Dynamic Text Scaling", "Ukuran teks berubah sesuai pengaturan.", 1, 1, 0, "100.0%"],
        ["F10", "Accessibility", "Dark Mode", "Tema antarmuka berubah sesuai pengaturan.", 1, 1, 0, "100.0%"],
        ["F11", "Ibadah Support", "Peta dan navigasi", "Peta atau navigasi berfungsi sesuai fitur yang tersedia.", 10, 10, 0, "100.0%"],
        ["F12", "Ibadah Support", "Informasi fasilitas dan lokasi", "Informasi yang diminta ditampilkan sesuai implementasi.", "—", "—", "—", "—"],
        ["F13", "Ibadah Support", "Prayer Schedule", "Jadwal ibadah yang tersedia ditampilkan.", "—", "—", "—", "—"],
    ]

    for row in f_data:
        ws3.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws3.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
                if c_i == 8:
                    cell.fill = pass_fill
                    cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i in [1, 5, 6, 7, 8] else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    ws3.cell(row=r_cur, column=1, value="Hasil Evaluasi Model Pengenalan Bahasa Isyarat HajiCare (Tingkat Kalimat)").font = sec_font
    r_cur += 1
    k_headers = ["Tugas/model", "Jumlah kelas", "Sampel uji", "Accuracy (%)", "Macro-Precision (%)", "Macro-Recall (%)", "Macro-F1 (%)"]
    ws3.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(k_headers, 1):
        cell = ws3.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    k_data = [
        ["SIBI - alfabet", 26, 26, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["SIBI - kalimat", "—", "—", "—", "—", "—", "—"],
        ["BISINDO - alfabet", 26, 26, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["BISINDO - kalimat", "—", "—", "—", "—", "—", "—"]
    ]
    for row in k_data:
        ws3.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws3.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
                if c_i in [4, 5, 6, 7]:
                    cell.fill = pass_fill
                    cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    # =========================================================================
    # SHEET 4: HALAMAN 5-6 (Smart Band Hardware & Sensor)
    # =========================================================================
    ws4 = wb.create_sheet(title='Halaman 5-6')
    ws4.views.sheetView[0].showGridLines = True

    ws4.merge_cells('A1:F1')
    c = ws4['A1']
    c.value = "TABEL VALIDASI 4 - PENGUJIAN SENSOR & FUNGSI SMART BAND (HARDWARE)"
    c.font = title_font
    c.fill = title_fill
    c.alignment = Alignment(horizontal='center', vertical='center')
    ws4.row_dimensions[1].height = 28

    ws4.cell(row=3, column=1, value="Hasil Pengujian Sensor dan Fungsi Smart Band (Komponen Aktual)").font = sec_font
    sb_headers = ["Komponen/fungsi aktual", "Parameter yang diuji", "Alat atau acuan", "Jumlah pengukuran", "Hasil pengukuran", "Error/indikator keberhasilan"]
    ws4.row_dimensions[4].height = 22
    for c_i, h in enumerate(sb_headers, 1):
        cell = ws4.cell(row=4, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border

    sb_data = [
        ["MAX30102", "Denyut jantung, jika fungsi tersedia", "Alat pembanding yang sesuai", "—", "—", "—"],
        ["MLX90614", "Suhu, sesuai besaran yang diukur", "Termometer referensi yang sesuai", "—", "—", "—"],
        ["MPU6050", "Gerakan/orientasi sesuai implementasi", "Skenario pengujian terdefinisi", "—", "—", "—"],
        ["Tombol SOS", "Aktivasi dan respons sistem", "Skenario pengujian terdefinisi", "—", "—", "—"],
        ["Motor getar", "Respons terhadap pemicu", "Skenario pengujian terdefinisi", "—", "—", "—"],
        ["OLED", "Tampilan indikator sistem", "Skenario pengujian terdefinisi", "—", "—", "—"]
    ]
    r_cur = 5
    for row in sb_data:
        ws4.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws4.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
            cell.alignment = Alignment(horizontal='center' if c_i in [1, 4, 5, 6] else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    ws4.cell(row=r_cur, column=1, value="2. Pengukuran Fisiologis (Reference vs HajiCare Band)").font = sec_font
    r_cur += 1
    med_headers = ["Measurement", "Reference", "HajiCare Band", "Absolute Error"]
    ws4.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(med_headers, 1):
        cell = ws4.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    med_data = [
        ["Heart Rate", "—", "—", "—"],
        ["SpO₂", "—", "—", "—"],
        ["Temperature", "—", "—", "—"]
    ]
    for row in med_data:
        ws4.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws4.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    # Auto-adjust column widths
    for ws in wb.worksheets:
        for col in ws.columns:
            max_len = 0
            col_letter = get_column_letter(col[0].column)
            for cell in col:
                if cell.row == 1:
                    continue
                if cell.value:
                    val_str = str(cell.value)
                    longest = max(len(l) for l in val_str.split('\n'))
                    if longest > max_len:
                        max_len = longest
            ws.column_dimensions[col_letter].width = min(max(max_len + 4, 12), 46)

    # 1. Save directly to master TABEL_VALIDASI_LENGKAP_HAJICARE.xlsx
    out_xlsx = os.path.join(workspace_dir, 'TABEL_VALIDASI_LENGKAP_HAJICARE.xlsx')
    wb.save(out_xlsx)
    print(f"Master Excel Overwritten Successfully: {out_xlsx}")

    # 2. Save directly to master TABEL_VALIDASI_LENGKAP_HAJICARE.csv
    out_csv = os.path.join(workspace_dir, 'TABEL_VALIDASI_LENGKAP_HAJICARE.csv')
    with open(out_csv, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["========================================================================================"])
        writer.writerow(["TABEL VALIDASI LENGKAP APLIKASI HAJICARE (SESUAI DOKUMEN PDF HALAMAN 1 S.D 6)"])
        writer.writerow(["Keterangan: Diperbarui dengan data faktual kelas & sampel riil. Belum diuji dikosongkan (—)"])
        writer.writerow(["========================================================================================"])
        writer.writerow([])
        
        # Halaman 1
        writer.writerow(["1. Hasil Pengujian Fungsional Aplikasi HajiCare (Halaman 1)"])
        writer.writerow(t1_headers)
        for r in t1_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["2. Evaluasi model pengenalan (Halaman 1 & 5)"])
        writer.writerow(t2_headers)
        for r in t2_data:
            writer.writerow(r)
        writer.writerow([])

        # Halaman 2
        writer.writerow(["3. Hasil Evaluasi Model Pengenalan Bahasa Isyarat (Halaman 2)"])
        writer.writerow(t3_headers)
        for r in t3_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["4. Hasil Evaluasi Model Money Recognition HajiCare (Halaman 2)"])
        writer.writerow(t4_headers)
        for r in t4_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["5. Hasil Pengujian Konversi Mata Uang HajiCare (Halaman 2 & 5)"])
        writer.writerow(t5_headers)
        for r in t5_data:
            writer.writerow(r)
        writer.writerow([])

        # Halaman 3 & 4
        writer.writerow(["Hasil Validasi GPS (Ponsel vs Smart Band) (Halaman 3 & 6)"])
        writer.writerow(gps_headers)
        for r in gps_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["Hasil pengujian fungsional aplikasi HajiCare F01 s.d F13 (Halaman 3 & 4)"])
        writer.writerow(f_headers)
        for r in f_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["Hasil Evaluasi Model Pengenalan Bahasa Isyarat HajiCare (Halaman 4 bawah)"])
        writer.writerow(k_headers)
        for r in k_data:
            writer.writerow(r)
        writer.writerow([])

        # Halaman 5 & 6
        writer.writerow(["Hasil Pengujian Sensor dan Fungsi Smart Band (Halaman 5 & 6)"])
        writer.writerow(sb_headers)
        for r in sb_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["Pengukuran Fisiologis Reference vs HajiCare Band (Halaman 6)"])
        writer.writerow(med_headers)
        for r in med_data:
            writer.writerow(r)

    print(f"Master CSV Overwritten Successfully: {out_csv}")

if __name__ == '__main__':
    update_master_validation_files()
