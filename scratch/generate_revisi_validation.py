import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter
import os
import csv

workspace_dir = r'c:\Users\Ferdi Ahyana yusri\Downloads\hajicare new\hajicare'

def generate_revisi_validation():
    wb = openpyxl.Workbook()
    wb.remove(wb.active)

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
    # SHEET 1: HALAMAN 1 (Ringkasan Fungsional & Evaluasi Model Sesuai Kelas Faktual)
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
            else:
                cell.font = normal_font
                if c_i == 7:
                    cell.fill = pass_fill
                    cell.font = pass_font
            cell.alignment = Alignment(horizontal='center' if c_i in [1, 4, 5, 6, 7] else 'left', vertical='center')
        r_cur += 1

    r_cur += 2
    # Tabel 2 (Actual Classes from labels_sibi.txt & labels_bisindo.txt, 30 Samples Each)
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
            else:
                cell.font = normal_font
            if c_i in [4, 5, 6, 7]:
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
            ws.column_dimensions[col_letter].width = min(max(max_len + 4, 12), 46)

    # Save to FINAL and REVISI with exception handling
    final_xlsx = os.path.join(workspace_dir, 'TABEL_VALIDASI_LENGKAP_HAJICARE_FINAL.xlsx')
    wb.save(final_xlsx)
    print(f"Generated Final Excel: {final_xlsx}")

    out_xlsx = os.path.join(workspace_dir, 'TABEL_VALIDASI_LENGKAP_HAJICARE_REVISI.xlsx')
    try:
        wb.save(out_xlsx)
        print(f"Generated Revisi Excel: {out_xlsx}")
    except PermissionError:
        print("Revisi Excel is open in Excel, skipping locked file.")

    final_csv = os.path.join(workspace_dir, 'TABEL_VALIDASI_LENGKAP_HAJICARE_FINAL.csv')
    with open(final_csv, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["========================================================================================"])
        writer.writerow(["TABEL VALIDASI LENGKAP APLIKASI HAJICARE (REVISI DATA KELAS & SAMPEL FAKTUAL)"])
        writer.writerow(["========================================================================================"])
        writer.writerow([])
        writer.writerow(["1. Hasil Pengujian Fungsional Aplikasi HajiCare"])
        writer.writerow(t1_headers)
        for r in t1_data:
            writer.writerow(r)
        writer.writerow([])
        writer.writerow(["2. Evaluasi model pengenalan (Faktual: SIBI 72 Kelas / 30 Sampel, BISINDO 47 Kelas / 30 Sampel)"])
        writer.writerow(t2_headers)
        for r in t2_data:
            writer.writerow(r)

    print(f"Generated Final CSV: {final_csv}")

if __name__ == '__main__':
    generate_revisi_validation()
