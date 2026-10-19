#!/usr/bin/env python3
"""
Sync Script untuk Hasil Pengujian Sensor dan Fungsi Smart Band ESP32-S3 HajiCare.
Script ini membaca hasil pengujian aktual dan memperbarui TABEL_VALIDASI_LENGKAP_HAJICARE.csv
dan TABEL_VALIDASI_LENGKAP_HAJICARE_AKTUAL.xlsx secara faktual tanpa data dummy buatan.
"""

import os
import sys
import json
import openpyxl

CSV_PATH = "TABEL_VALIDASI_LENGKAP_HAJICARE.csv"
XLSX_ACTUAL_PATH = "TABEL_VALIDASI_LENGKAP_HAJICARE_AKTUAL.xlsx"
XLSX_MASTER_PATH = "TABEL_VALIDASI_LENGKAP_HAJICARE.xlsx"

def update_validation_files(component_data=None, physio_data=None, gps_data=None):
    """
    component_data: dict of component -> {'total': int, 'lastMeasured': str, 'indicator': str}
    physio_data: dict of type -> {'ref': str, 'band': str, 'error': str}
    gps_data: dict -> {'total': int, 'validRate': str, 'medianError': str, 'p95Error': str, 'medianTime': str}
    """
    print("Mempersiapkan pembaruan data validasi Smart Band...")
    
    # 1. Update CSV
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        new_lines = []
        for line in lines:
            # Check for component lines
            if component_data and line.startswith("MAX30102,") and "MAX30102" in component_data:
                c = component_data["MAX30102"]
                line = f'MAX30102,"Denyut jantung, jika fungsi tersedia",Alat pembanding yang sesuai,{c["total"]},{c["lastMeasured"]},{c["indicator"]}\n'
            elif component_data and line.startswith("MLX90614,") and "MLX90614" in component_data:
                c = component_data["MLX90614"]
                line = f'MLX90614,"Suhu, sesuai besaran yang diukur",Termometer referensi yang sesuai,{c["total"]},{c["lastMeasured"]},{c["indicator"]}\n'
            elif component_data and line.startswith("MPU6050,") and "MPU6050" in component_data:
                c = component_data["MPU6050"]
                line = f'MPU6050,Gerakan/orientasi sesuai implementasi,Skenario pengujian terdefinisi,{c["total"]},{c["lastMeasured"]},{c["indicator"]}\n'
            elif component_data and line.startswith("Tombol SOS,") and "Tombol SOS" in component_data:
                c = component_data["Tombol SOS"]
                line = f'Tombol SOS,Aktivasi dan respons sistem,Skenario pengujian terdefinisi,{c["total"]},{c["lastMeasured"]},{c["indicator"]}\n'
            elif component_data and line.startswith("Motor getar,") and "Motor getar" in component_data:
                c = component_data["Motor getar"]
                line = f'Motor getar,Respons terhadap pemicu,Skenario pengujian terdefinisi,{c["total"]},{c["lastMeasured"]},{c["indicator"]}\n'
            elif component_data and line.startswith("OLED,") and "OLED" in component_data:
                c = component_data["OLED"]
                line = f'OLED,Tampilan indikator sistem,Skenario pengujian terdefinisi,{c["total"]},{c["lastMeasured"]},{c["indicator"]}\n'
            
            # Check for physio lines
            elif physio_data and line.startswith("Heart Rate,") and "Heart Rate" in physio_data:
                p = physio_data["Heart Rate"]
                line = f'Heart Rate,{p["ref"]},{p["band"]},{p["error"]}\n'
            elif physio_data and line.startswith("SpO₂,") and "SpO₂" in physio_data:
                p = physio_data["SpO₂"]
                line = f'SpO₂,{p["ref"]},{p["band"]},{p["error"]}\n'
            elif physio_data and line.startswith("Temperature,") and "Temperature" in physio_data:
                p = physio_data["Temperature"]
                line = f'Temperature,{p["ref"]},{p["band"]},{p["error"]}\n'
                
            # Check for GPS smart band
            elif gps_data and line.startswith("Modul GPS smart band,") and gps_data:
                g = gps_data
                line = f'Modul GPS smart band,{g.get("total", "—")},{g.get("validRate", "—")},{g.get("medianError", "—")},{g.get("p95Error", "—")},{g.get("medianTime", "—")}\n'
                
            new_lines.append(line)
            
        with open(CSV_PATH, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"Berhasil memperbarui {CSV_PATH}")

    # 2. Update Excel
    target_xlsx = XLSX_ACTUAL_PATH
    if os.path.exists(target_xlsx):
        wb = openpyxl.load_workbook(target_xlsx)
        ws = wb.active
        
        # Traverse rows and update matching cells
        for row in ws.iter_rows(values_only=False):
            cell_val = str(row[0].value or "").strip()
            
            if component_data and cell_val in component_data:
                c = component_data[cell_val]
                if len(row) >= 6:
                    row[3].value = c["total"]
                    row[4].value = c["lastMeasured"]
                    row[5].value = c["indicator"]
                    
            elif physio_data and cell_val in physio_data:
                p = physio_data[cell_val]
                if len(row) >= 4:
                    row[1].value = p["ref"]
                    row[2].value = p["band"]
                    row[3].value = p["error"]
                    
            elif gps_data and cell_val == "Modul GPS smart band":
                g = gps_data
                if len(row) >= 6:
                    row[1].value = g.get("total", "—")
                    row[2].value = g.get("validRate", "—")
                    row[3].value = g.get("medianError", "—")
                    row[4].value = g.get("p95Error", "—")
                    row[5].value = g.get("medianTime", "—")
                    
        try:
            wb.save(target_xlsx)
            print(f"Berhasil memperbarui Excel: {target_xlsx}")
        except PermissionError:
            print(f"File {target_xlsx} sedang dibuka di Excel. Tutup Excel terlebih dahulu.")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--status":
        print("Status sinkronisasi siap.")
    else:
        print("Gunakan fungsi update_validation_files(component_data, physio_data, gps_data) untuk sinkronisasi.")
