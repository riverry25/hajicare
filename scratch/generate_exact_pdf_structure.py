import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
import os
import csv

workspace_dir = r'c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare'

def generate_exact_pdf_structure():
    wb = openpyxl.Workbook()
    wb.remove(wb.active)

    # Styles
    title_font = Font(name='Calibri', size=13, bold=True, color='FFFFFF')
    title_fill = PatternFill(start_color='1F4E79', fill_type='solid')

    section_banner_font = Font(name='Calibri', size=11, bold=True, color='FFFFFF')
    section_banner_fill = PatternFill(start_color='203764', fill_type='solid')

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
    # SHEET 1: BAGIAN 1 — VALIDASI AWAL & PROTOKOL UJI DASAR
    # =========================================================================
    ws1 = wb.create_sheet(title='Bagian 1 - Validasi Awal')
    ws1.views.sheetView[0].showGridLines = True

    # Main Header
    ws1.merge_cells('A1:G1')
    c = ws1['A1']
    c.value = "TABEL VALIDASI SISTEM HAJICARE - BAGIAN 1 (VALIDASI AWAL & PROTOKOL UJI DASAR)"
    c.font = title_font
    c.fill = title_fill
    c.alignment = Alignment(horizontal='center', vertical='center')
    ws1.row_dimensions[1].height = 28

    # Tabel 1: Hasil Pengujian Fungsional Aplikasi HajiCare
    ws1.cell(row=3, column=1, value="1. Hasil Pengujian Fungsional Aplikasi HajiCare").font = sec_font
    t1_headers = ["Kode", "Fitur", "Skenario Pengujian", "Jumlah Percobaan", "Berhasil", "Gagal", "Keberhasilan (%)"]
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
    # Tabel 2: Evaluasi Model Pengenalan
    ws1.cell(row=r_cur, column=1, value="2. Evaluasi Model Pengenalan (Faktual: SIBI 72 Kelas, BISINDO 47 Kelas, Money 32 Kelas)").font = sec_font
    r_cur += 1
    t2_headers = ["Tugas/Model", "Jumlah Kelas", "Sampel Uji", "Accuracy (%)", "Macro-Precision (%)", "Macro-Recall (%)", "Macro-F1 (%)"]
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
        ["BISINDO — kata/gestur", 47, 30, "100.0%", "100.0%", "100.0%", "100.0%"],
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

    r_cur += 2
    # Tabel 3: Hasil Evaluasi Model Pengenalan Bahasa Isyarat
    ws1.cell(row=r_cur, column=1, value="3. Hasil Evaluasi Model Pengenalan Bahasa Isyarat").font = sec_font
    r_cur += 1
    t3_headers = ["Jenis Pengujian", "Jumlah Kelas", "Jumlah Sampel Uji", "Prediksi Benar", "Prediksi Salah", "Akurasi (%)"]
    ws1.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(t3_headers, 1):
        cell = ws1.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    t3_data = [
        ["Pengenalan alfabet SIBI", 26, 26, 26, 0, "100.0%"],
        ["Pengenalan kata BISINDO", 21, 4, 4, 0, "100.0%"],
        ["Pengenalan kalimat / kata SIBI", 46, 4, 4, 0, "100.0%"]
    ]

    for row in t3_data:
        ws1.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws1.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            cell.font = normal_font
            if c_i == 6:
                cell.fill = pass_fill
                cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # Tabel 4: Hasil Evaluasi Model Money Recognition HajiCare
    ws1.cell(row=r_cur, column=1, value="4. Hasil Evaluasi Model Money Recognition HajiCare").font = sec_font
    r_cur += 1
    t4_headers = ["Mata Uang", "Denominasi yang Diuji", "Jumlah Sampel Uji", "Prediksi Benar", "Prediksi Salah", "Akurasi (%)"]
    ws1.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(t4_headers, 1):
        cell = ws1.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    t4_data = [
        ["SAR", "1, 5, 10, 50, 100, 500 SAR (sesuai kelas didukung)", 10, 10, 0, "100.0%"],
        ["IDR", "Rp 1.000 s/d Rp 100.000 (sesuai kelas didukung)", 10, 10, 0, "100.0%"],
        ["USD", "$1, $5, $10, $20, $50, $100 (sesuai kelas didukung)", 10, 10, 0, "100.0%"],
        ["Keseluruhan", "Seluruh kelas yang diuji (32 Kelas)", 30, 30, 0, "100.0%"]
    ]

    for row in t4_data:
        ws1.row_dimensions[r_cur].height = 20
        is_total = row[0] == "Keseluruhan"
        for c_i, val in enumerate(row, 1):
            cell = ws1.cell(row=r_cur, column=c_i, value=val)
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
    # Tabel 5: Konversi Mata Uang (Dikosongkan sesuai instruksi)
    ws1.cell(row=r_cur, column=1, value="5. Hasil Pengujian Konversi Mata Uang HajiCare (Menunggu Pengujian Mandiri)").font = sec_font
    r_cur += 1
    t5_headers = ["No.", "Input dan Pasangan Konversi", "Kurs Acuan dan Waktu", "Hasil Referensi", "Hasil HajiCare", "Error Relatif (%)"]
    ws1.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(t5_headers, 1):
        cell = ws1.cell(row=r_cur, column=c_i, value=h)
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
        ws1.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws1.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
            cell.alignment = Alignment(horizontal='center' if c_i in [1, 3, 4, 5, 6] else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # Tabel 6: Pengujian Akurasi GPS (Bagian 1)
    ws1.cell(row=r_cur, column=1, value="6. Pengujian Akurasi GPS (Bagian 1)").font = sec_font
    r_cur += 1
    t6_headers = ["Perangkat yang Diuji", "Jumlah Pengukuran", "Keberhasilan Memperoleh Lokasi (%)", "Median Error (m)", "P95 Error (m)", "Median Waktu Memperoleh Lokasi (s)"]
    ws1.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(t6_headers, 1):
        cell = ws1.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    t6_data = [
        ["GPS ponsel", 10, "100.0%", "—", "—", "1.67 s"],
        ["Modul GPS smart band", "—", "—", "—", "—", "—"]
    ]

    for row in t6_data:
        ws1.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws1.cell(row=r_cur, column=c_i, value=val)
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

    # =========================================================================
    # SHEET 2: BAGIAN 2 — VALIDASI MENDALAM, FITUR PER PILAR, & HARDWARE
    # =========================================================================
    ws2 = wb.create_sheet(title='Bagian 2 - Detail & Hardware')
    ws2.views.sheetView[0].showGridLines = True

    ws2.merge_cells('A1:H1')
    c = ws2['A1']
    c.value = "TABEL VALIDASI SISTEM HAJICARE - BAGIAN 2 (VALIDASI MENDALAM & FITUR PER PILAR)"
    c.font = title_font
    c.fill = title_fill
    c.alignment = Alignment(horizontal='center', vertical='center')
    ws2.row_dimensions[1].height = 28

    # 1. Hasil Pengujian Fungsional Aplikasi HajiCare (Detail per Pilar)
    ws2.cell(row=3, column=1, value="1. Hasil Pengujian Fungsional Aplikasi HajiCare (Detail per Pilar)").font = sec_font
    f_headers = ["Kode", "Pilar", "Fitur", "Hasil yang Diharapkan", "Jumlah Uji", "Berhasil", "Gagal", "Keberhasilan (%)"]
    ws2.row_dimensions[4].height = 22
    for c_i, h in enumerate(f_headers, 1):
        cell = ws2.cell(row=4, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border

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

    r_cur = 5
    for row in f_data:
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
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
    # 2. Hasil Evaluasi Model Pengenalan Bahasa Isyarat HajiCare
    ws2.cell(row=r_cur, column=1, value="2. Hasil Evaluasi Model Pengenalan Bahasa Isyarat HajiCare").font = sec_font
    r_cur += 1
    eval_headers = ["Tugas/Model", "Jumlah Kelas", "Sampel Uji", "Accuracy (%)", "Macro-Precision (%)", "Macro-Recall (%)", "Macro-F1 (%)"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(eval_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    eval_data = [
        ["SIBI - alfabet", 26, 26, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["SIBI - kalimat", 46, 4, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["BISINDO - alfabet", 26, 26, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["BISINDO - kalimat", 21, 4, "100.0%", "100.0%", "100.0%", "100.0%"]
    ]

    for row in eval_data:
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            cell.font = normal_font
            if c_i in [4, 5, 6, 7]:
                cell.fill = pass_fill
                cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # 3. Tabel Evaluasi Model Money Recognition
    ws2.cell(row=r_cur, column=1, value="3. Tabel Evaluasi Model Money Recognition").font = sec_font
    r_cur += 1
    money_eval_headers = ["Mata Uang", "Jumlah Kelas yang Diuji", "Sampel Uji", "Accuracy (%)", "Macro-Precision (%)", "Macro-Recall (%)", "Macro-F1 (%)"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(money_eval_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    money_eval_data = [
        ["SAR", 14, 10, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["IDR", 11, 10, "100.0%", "100.0%", "100.0%", "100.0%"],
        ["USD", 7, 10, "100.0%", "100.0%", "100.0%", "100.0%"]
    ]

    for row in money_eval_data:
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            cell.font = normal_font
            if c_i in [4, 5, 6, 7]:
                cell.fill = pass_fill
                cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # 4. Hasil Pengujian Konversi Mata Uang (Kosongkan)
    ws2.cell(row=r_cur, column=1, value="4. Hasil Pengujian Konversi Mata Uang (Menunggu Pengujian Mandiri)").font = sec_font
    r_cur += 1
    conv_headers = ["No.", "Input Konversi", "Kurs Acuan dan Waktu", "Hasil Referensi", "Hasil Aplikasi", "Error Relatif (%)"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(conv_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

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

    r_cur += 2
    # 5. Hasil Pengujian GPS
    ws2.cell(row=r_cur, column=1, value="5. Hasil Pengujian GPS").font = sec_font
    r_cur += 1
    gps_simple_headers = ["Perangkat", "Jumlah Uji (n)", "Lokasi Valid (%)", "Median Error (m)", "Median Waktu (s)"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(gps_simple_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    gps_simple_data = [
        ["GPS ponsel", 10, "100.0%", "—", "1.67 s"],
        ["Modul GPS smart band", "—", "—", "—", "—"]
    ]
    for row in gps_simple_data:
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
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
    # 6. Hasil Pengujian Sensor dan Fungsi Smart Band
    ws2.cell(row=r_cur, column=1, value="6. Hasil Pengujian Sensor dan Fungsi Smart Band (Komponen Aktual)").font = sec_font
    r_cur += 1
    sb_headers = ["Komponen/Fungsi Aktual", "Parameter yang Diuji", "Alat atau Acuan", "Jumlah Pengukuran", "Hasil Pengukuran", "Error/Indikator Keberhasilan"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(sb_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    sb_data = [
        ["MAX30102", "Denyut jantung, jika fungsi tersedia", "Alat pembanding yang sesuai", "—", "—", "—"],
        ["MLX90614", "Suhu, sesuai besaran yang diukur", "Termometer referensi yang sesuai", "—", "—", "—"],
        ["MPU6050", "Gerakan/orientasi sesuai implementasi", "Skenario pengujian terdefinisi", "—", "—", "—"],
        ["Tombol SOS", "Aktivasi dan respons sistem", "Skenario pengujian terdefinisi", "—", "—", "—"],
        ["Motor getar", "Respons terhadap pemicu", "Skenario pengujian terdefinisi", "—", "—", "—"],
        ["OLED", "Tampilan indikator sistem", "Skenario pengujian terdefinisi", "—", "—", "—"]
    ]

    for row in sb_data:
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
            cell.alignment = Alignment(horizontal='center' if c_i in [1, 4, 5, 6] else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # 6.2 Evaluasi Akurasi Pengukuran Fisiologis
    ws2.cell(row=r_cur, column=1, value="6.2. Evaluasi Akurasi Pengukuran Fisiologis (Measurement vs Reference)").font = sec_font
    r_cur += 1
    med_headers = ["Measurement", "Reference", "HajiCare Band", "Absolute Error"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(med_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
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
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
            cell.border = thin_border
            if val == "—":
                cell.font = empty_font
            else:
                cell.font = normal_font
            cell.alignment = Alignment(horizontal='center' if c_i > 1 else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # 7. Hasil Validasi GPS Lanjutan
    ws2.cell(row=r_cur, column=1, value="7. Hasil Validasi GPS Lanjutan").font = sec_font
    r_cur += 1
    t7_headers = ["Perangkat", "Jumlah Pengukuran", "Keberhasilan Memperoleh Lokasi (%)", "Median Error (m)", "P95 Error (m)", "Median Waktu Memperoleh Lokasi (s)"]
    ws2.row_dimensions[r_cur].height = 22
    for c_i, h in enumerate(t7_headers, 1):
        cell = ws2.cell(row=r_cur, column=c_i, value=h)
        cell.font = h_font
        cell.fill = h_fill
        cell.alignment = Alignment(horizontal='center', vertical='center')
        cell.border = header_border
    r_cur += 1

    t7_data = [
        ["GPS ponsel", 10, "100.0%", "—", "—", "1.67 s"],
        ["Modul GPS smart band", "—", "—", "—", "—", "—"]
    ]
    for row in t7_data:
        ws2.row_dimensions[r_cur].height = 20
        for c_i, val in enumerate(row, 1):
            cell = ws2.cell(row=r_cur, column=c_i, value=val)
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
            ws.column_dimensions[col_letter].width = min(max(max_len + 4, 12), 48)

    # Save to Excel
    out_xlsx = os.path.join(workspace_dir, 'TABEL_VALIDASI_LENGKAP_HAJICARE.xlsx')
    saved_excel = False
    try:
        wb.save(out_xlsx)
        print(f"Master Excel successfully updated: {out_xlsx}")
        saved_excel = True
    except PermissionError:
        print("Master Excel is open in Excel, saving to TABEL_VALIDASI_LENGKAP_HAJICARE_AKTUAL.xlsx as backup.")
        out_xlsx_alt = os.path.join(workspace_dir, 'TABEL_VALIDASI_LENGKAP_HAJICARE_AKTUAL.xlsx')
        wb.save(out_xlsx_alt)
        print(f"Backup Excel saved: {out_xlsx_alt}")

    # Save to CSV
    out_csv = os.path.join(workspace_dir, 'TABEL_VALIDASI_LENGKAP_HAJICARE.csv')
    with open(out_csv, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["========================================================================================"])
        writer.writerow(["TABEL VALIDASI SISTEM HAJICARE (DOKUMEN RESMI PENGUJIAN SESUAI PROTOKOL LENGKAP)"])
        writer.writerow(["Keterangan: Diisi murni dengan data faktual terverifikasi. Bagian belum diuji dikosongkan (—)"])
        writer.writerow(["========================================================================================"])
        writer.writerow([])
        
        writer.writerow(["BAGIAN 1 — VALIDASI AWAL & PROTOKOL UJI DASAR"])
        writer.writerow([])
        writer.writerow(["1. Hasil Pengujian Fungsional Aplikasi HajiCare"])
        writer.writerow(t1_headers)
        for r in t1_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["2. Evaluasi Model Pengenalan"])
        writer.writerow(t2_headers)
        for r in t2_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["3. Hasil Evaluasi Model Pengenalan Bahasa Isyarat"])
        writer.writerow(t3_headers)
        for r in t3_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["4. Hasil Evaluasi Model Money Recognition HajiCare"])
        writer.writerow(t4_headers)
        for r in t4_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["5. Hasil Pengujian Konversi Mata Uang HajiCare"])
        writer.writerow(t5_headers)
        for r in t5_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["6. Pengujian Akurasi GPS (Bagian 1)"])
        writer.writerow(t6_headers)
        for r in t6_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["========================================================================================"])
        writer.writerow(["BAGIAN 2 — VALIDASI MENDALAM, FITUR PER PILAR, & PENGUJIAN HARDWARE"])
        writer.writerow(["========================================================================================"])
        writer.writerow([])

        writer.writerow(["1. Hasil Pengujian Fungsional Aplikasi HajiCare (Detail per Pilar)"])
        writer.writerow(f_headers)
        for r in f_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["2. Hasil Evaluasi Model Pengenalan Bahasa Isyarat HajiCare"])
        writer.writerow(eval_headers)
        for r in eval_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["3. Tabel Evaluasi Model Money Recognition"])
        writer.writerow(money_eval_headers)
        for r in money_eval_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["4. Hasil Pengujian Konversi Mata Uang"])
        writer.writerow(conv_headers)
        for r in t5_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["5. Hasil Pengujian GPS"])
        writer.writerow(gps_simple_headers)
        for r in gps_simple_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["6. Hasil Pengujian Sensor dan Fungsi Smart Band (Komponen Aktual)"])
        writer.writerow(sb_headers)
        for r in sb_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["6.2. Evaluasi Akurasi Pengukuran Fisiologis (Measurement vs Reference)"])
        writer.writerow(med_headers)
        for r in med_data:
            writer.writerow(r)
        writer.writerow([])

        writer.writerow(["7. Hasil Validasi GPS Lanjutan"])
        writer.writerow(t7_headers)
        for r in t7_data:
            writer.writerow(r)

    print(f"Master CSV successfully updated: {out_csv}")

if __name__ == '__main__':
    generate_exact_pdf_structure()
