import pandas as pd
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# Data Rekapitulasi Audit Keamanan & Pengujian OWASP MASVS (IEEE / Scopus Journal Standard)
data = [
    # a. Temuan SAST mobsfscan
    {
        "Test_ID": "SEC-SAST-01",
        "MASVS_Category": "MASVS-PLATFORM",
        "Vulnerability_Vector": "StrandHogg 2.0 Task Hijacking (android_task_hijacking2)",
        "Target_Artifact": "android/app/src/main/AndroidManifest.xml",
        "Verification_Method": "Static SAST mobsfscan",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Deklarasi targetSdkVersion 34, konfigurasi taskAffinity='' dan launchMode singleTop untuk mencegah penumpukan malicious task",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-SAST-02",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Insecure ADB Data Backup (android_manifest_missing_explicit_allow_backup)",
        "Target_Artifact": "android/app/src/main/AndroidManifest.xml",
        "Verification_Method": "Static SAST mobsfscan",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Menetapkan android:allowBackup='false', fullBackupContent='false', dan deklarasi data_extraction_rules.xml",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-SAST-03",
        "MASVS_Category": "MASVS-NETWORK",
        "Vulnerability_Vector": "Cleartext HTTP Traffic Exposure (android_cleartext_traffic)",
        "Target_Artifact": "AndroidManifest.xml & network_security_config.xml",
        "Verification_Method": "Static SAST mobsfscan",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Menonaktifkan usesCleartextTraffic='false' dan menegakkan network_security_config.xml menolak HTTP",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-SAST-04",
        "MASVS_Category": "MASVS-RESILIENCE",
        "Vulnerability_Vector": "Code Reverse Engineering & Class Stripping Risk",
        "Target_Artifact": "android/app/proguard-rules.pro & build.gradle.kts",
        "Verification_Method": "Rule Engine Analysis",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Pengaktifan isMinifyEnabled/shrinkResources serta ProGuard keep rules untuk androidx.security.crypto, secure_storage, dan Play Integrity",
        "Post_Mitigation_Status": "Resolved"
    },

    # b. Audit Keamanan Backend & Aturan Akses (Firebase Rules)
    {
        "Test_ID": "SEC-RULE-01",
        "MASVS_Category": "MASVS-AUTH",
        "Vulnerability_Vector": "User Role Privilege Escalation Bypass (/users/{uid})",
        "Target_Artifact": "firestore.rules",
        "Verification_Method": "Rule Engine Analysis",
        "Pre_Mitigation_Severity": "Critical",
        "Mitigation_Applied": "Menghapus 'role' dari affectedKeys pada operasi update profil pengguna, menjadikan peran immutable di sisi klien",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-RULE-02",
        "MASVS_Category": "MASVS-AUTH",
        "Vulnerability_Vector": "Unauthorized Room Companion Privilege Escalation (/rooms/{id})",
        "Target_Artifact": "firestore.rules",
        "Verification_Method": "Rule Engine Analysis",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Membatasi modifikasi pendampingIds hanya untuk Room Manager/Owner; direct-join hanya dapat memperbarui memberCount & updatedAt",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-RULE-03",
        "MASVS_Category": "MASVS-AUTH",
        "Vulnerability_Vector": "Member Subcollection Role Manipulation (/members/{uid})",
        "Target_Artifact": "firestore.rules",
        "Verification_Method": "Rule Engine Analysis",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Mencegah mutasi 'role' pada subkoleksi members dan membatasi update hanya pada status runtime (lokasi, sosActive)",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-RULE-04",
        "MASVS_Category": "MASVS-AUTH",
        "Vulnerability_Vector": "Emergency SOS Event Spoofing (/sos_events/{id})",
        "Target_Artifact": "firestore.rules",
        "Verification_Method": "Rule Engine Analysis",
        "Pre_Mitigation_Severity": "Critical",
        "Mitigation_Applied": "Menegakkan request.auth.uid == userId, status == 'active', validasi keanggotaan rombongan, dan string length limits",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-RULE-05",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Resource Exhaustion & DoS Text Payload Injection",
        "Target_Artifact": "firestore.rules",
        "Verification_Method": "Rule Engine Analysis",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Menambahkan batas panjang karakter eksplisit pada seluruh input string (nama <= 100, NIK <= 30, catatan <= 500)",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-RULE-06",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Insecure Cloud Storage Object Access & Quota Exhaustion",
        "Target_Artifact": "storage.rules & firebase.json",
        "Verification_Method": "Rule Engine Analysis",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Deklarasi storage.rules dengan isolasi direktori UID users/{userId}, verifikasi MIME image/*, dan batas ukuran file < 5MB",
        "Post_Mitigation_Status": "Resolved"
    },

    # c. Enkripsi dan Sanitasi Data Klien
    {
        "Test_ID": "SEC-CRYPTO-01",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Plaintext Auth Token & Credential Persistence",
        "Target_Artifact": "lib/core/services/secure_storage_service.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Critical",
        "Mitigation_Applied": "Migrasi dari SharedPreferences ke flutter_secure_storage berbasis hardware-backed KeyStore (AES-GCM) dan Keychain",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-CRYPTO-02",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Insecure Session Lifecycle & Logout Sanitization",
        "Target_Artifact": "lib/core/state/app_startup_controller.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Pembersihan seluruh kunci kredensial dan token sesi terenkripsi secara serentak saat eksekusi signOut()",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-CRYPTO-03",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Active Room ID & Role Cache Leakage",
        "Target_Artifact": "lib/core/state/hajicare_controller.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Enkripsi penyimpanan cached activeRoomId dan role menggunakan SecureStorageService",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-NETWORK-01",
        "MASVS_Category": "MASVS-NETWORK",
        "Vulnerability_Vector": "Unauthorized Backend Access & Automated Bot Requests",
        "Target_Artifact": "lib/core/services/app_check_service.dart",
        "Verification_Method": "Rule Engine Analysis",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Integrasi Firebase App Check dengan AndroidPlayIntegrityProvider pada release dan AppleDeviceCheckProvider",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-CODE-01",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Cross-Site Scripting (XSS) & Null-Byte Injection",
        "Target_Artifact": "lib/core/utils/input_sanitizer.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Sanitasi null byte, karakter kontrol ASCII 0-31, dan tag HTML/skrip pada seluruh input formulir",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-CODE-02",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Registration Credential Format Tampering",
        "Target_Artifact": "lib/features/auth/controllers/register_controller.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Validasi panjang password minimum 6 karakter, validasi format email RFC 5322, dan sanitasi NIK sebelum dikirim ke Firebase",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-CODE-03",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Profile Medical & Identity Data Manipulation",
        "Target_Artifact": "lib/features/profile/controllers/profile_controller.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Sanitasi nama tampilan, NIK, nomor porsi, dan pembatasan panjang riwayat alergi/kondisi medis <= 500 karakter",
        "Post_Mitigation_Status": "Resolved"
    },
    {
        "Test_ID": "SEC-CODE-04",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Room Creation & Joining Code Injection",
        "Target_Artifact": "lib/features/room/controllers/join_room_controller.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Validasi regex alfanumerik 4-12 karakter pada kode rombongan dan pembatasan panjang nama rombongan <= 100 karakter",
        "Post_Mitigation_Status": "Resolved"
    },

    # d. Hasil Eksekusi Unit Test (Test Suites)
    {
        "Test_ID": "SEC-UNIT-01",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Null-Byte & Control Character Stripping Test",
        "Target_Artifact": "test/core/utils/input_sanitizer_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Verifikasi penghapusan karakter \\x00, \\x08, dan \\x1F tanpa merusak data teks valid",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-02",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "XSS Script & HTML Tag Stripping Test",
        "Target_Artifact": "test/core/utils/input_sanitizer_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Verifikasi pembersihan tag <script> dan <img onerror> menjadi string teks aman",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-03",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "String Length Clamping Boundary Test (Anti-DoS)",
        "Target_Artifact": "test/core/utils/input_sanitizer_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Verifikasi pemotongan string panjang ekstrem (>300 karakter) sesuai batas parameter maxLength",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-04",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "RFC 5322 Email Format Verification Test",
        "Target_Artifact": "test/core/utils/input_sanitizer_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Verifikasi penolakan format email tidak valid (tanpa domain, tanpa @, atau string kosong)",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-05",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Password Boundary & Minimum Length Test",
        "Target_Artifact": "test/core/utils/input_sanitizer_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Verifikasi penerimaan password >= 6 karakter dan penolakan password < 6 karakter",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-06",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Room Code Alphanumeric Boundary Test",
        "Target_Artifact": "test/core/utils/input_sanitizer_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Verifikasi format kode rombongan 4-12 karakter alfanumerik kapital dan penolakan simbol",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-07",
        "MASVS_Category": "MASVS-CODE",
        "Vulnerability_Vector": "Indonesian NIK 16-Digit Boundary Test",
        "Target_Artifact": "test/core/utils/input_sanitizer_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Verifikasi kelayakan digit numerik NIK (8-20 digit) dan penolakan data non-numerik",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-08",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Encrypted RememberMe KeyStore Persistence Test",
        "Target_Artifact": "test/core/services/secure_storage_service_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Verifikasi persistensi nilai boolean Remember Me pada KeyStore/Keychain terenkripsi",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-09",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Encrypted Active Room ID Persistence Test",
        "Target_Artifact": "test/core/services/secure_storage_service_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Verifikasi penyimpanan ID rombongan aktif terenkripsi dan penghapusan saat null",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-10",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Encrypted User Role State Persistence Test",
        "Target_Artifact": "test/core/services/secure_storage_service_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Verifikasi penyimpanan peran pengguna (jamaah/pendamping) dalam media penyimpanan aman",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-11",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Atomic Auth Session Purge on SignOut Test",
        "Target_Artifact": "test/core/services/secure_storage_service_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Critical",
        "Mitigation_Applied": "Verifikasi pembersihan total token otentikasi, room ID, dan peran pengguna tanpa residu",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-12",
        "MASVS_Category": "MASVS-AUTH",
        "Vulnerability_Vector": "Startup Authentication Lifecycle & Session Guard Test",
        "Target_Artifact": "test/app_startup_auth_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Verifikasi transisi state autentikasi startup dan penanganan sesi terenkripsi",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-13",
        "MASVS_Category": "MASVS-AUTH",
        "Vulnerability_Vector": "Emergency SOS Data Structure & Status Integrity Test",
        "Target_Artifact": "test/sos_emergency_flow_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Critical",
        "Mitigation_Applied": "Verifikasi kelengkapan struktur data payload event SOS dan proteksi resolusi status darurat",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-14",
        "MASVS_Category": "MASVS-STORAGE",
        "Vulnerability_Vector": "Medical Profile & NIK Data Integrity Test",
        "Target_Artifact": "test/profile_nik_porsi_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "Medium",
        "Mitigation_Applied": "Verifikasi integritas field NIK, nomor porsi, dan sinkronisasi rekam medis jamaah",
        "Post_Mitigation_Status": "Pass"
    },
    {
        "Test_ID": "SEC-UNIT-15",
        "MASVS_Category": "MASVS-PLATFORM",
        "Vulnerability_Vector": "Room Navigation Guard & Input Boundary Test",
        "Target_Artifact": "test/join_room_navigation_flow_test.dart",
        "Verification_Method": "Automated Unit Test",
        "Pre_Mitigation_Severity": "High",
        "Mitigation_Applied": "Verifikasi proteksi guard navigasi rombongan dan penolakan input kode room tidak valid",
        "Post_Mitigation_Status": "Pass"
    }
]

df = pd.DataFrame(data)

# 1. Simpan ke CSV
csv_filename = "security_test_execution_report.csv"
df.to_csv(csv_filename, index=False, encoding='utf-8')
print(f"Berhasil membuat {csv_filename} dengan {len(df)} baris data.")

# 2. Simpan ke Excel dengan pemformatan formal IEEE/Scopus
excel_filename = "security_test_execution_report.xlsx"
wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Security Execution Report"

# Ensure grid lines are visible
ws.views.sheetView[0].showGridLines = True

# Palet Warna Profesional
header_fill = PatternFill(start_color="1B365D", end_color="1B365D", fill_type="solid")  # Dark Navy
header_font = Font(name="Segoe UI", size=11, bold=True, color="FFFFFF")

# Severity Styles
sev_critical_fill = PatternFill(start_color="F8D7DA", end_color="F8D7DA", fill_type="solid")
sev_critical_font = Font(name="Segoe UI", size=10, bold=True, color="721C24")

sev_high_fill = PatternFill(start_color="FFF3CD", end_color="FFF3CD", fill_type="solid")
sev_high_font = Font(name="Segoe UI", size=10, bold=True, color="856404")

sev_medium_fill = PatternFill(start_color="D1ECF1", end_color="D1ECF1", fill_type="solid")
sev_medium_font = Font(name="Segoe UI", size=10, bold=False, color="0C5460")

sev_low_fill = PatternFill(start_color="E2E3E5", end_color="E2E3E5", fill_type="solid")
sev_low_font = Font(name="Segoe UI", size=10, bold=False, color="383D41")

# Status Styles
status_pass_fill = PatternFill(start_color="D4EDDA", end_color="D4EDDA", fill_type="solid")
status_pass_font = Font(name="Segoe UI", size=10, bold=True, color="155724")

body_font = Font(name="Segoe UI", size=10, color="000000")
code_font = Font(name="Consolas", size=9, color="1B365D")

thin_border = Border(
    left=Side(style='thin', color='E0E0E0'),
    right=Side(style='thin', color='E0E0E0'),
    top=Side(style='thin', color='E0E0E0'),
    bottom=Side(style='thin', color='E0E0E0')
)

# Header Row
columns = list(df.columns)
ws.append(columns)

for col_num, col_name in enumerate(columns, 1):
    cell = ws.cell(row=1, column=col_num)
    cell.fill = header_fill
    cell.font = header_font
    cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
ws.row_dimensions[1].height = 28

# Data Rows
for row_idx, row_data in enumerate(data, start=2):
    row_values = [row_data[col] for col in columns]
    ws.append(row_values)
    ws.row_dimensions[row_idx].height = 24

    for col_idx, col_name in enumerate(columns, start=1):
        cell = ws.cell(row=row_idx, column=col_idx)
        cell.border = thin_border
        cell.font = body_font
        cell.alignment = Alignment(vertical="center")

        # Specific Column Styling
        if col_name == "Test_ID":
            cell.font = code_font
            cell.alignment = Alignment(horizontal="center", vertical="center")
        elif col_name == "MASVS_Category":
            cell.alignment = Alignment(horizontal="center", vertical="center")
        elif col_name == "Verification_Method":
            cell.alignment = Alignment(horizontal="center", vertical="center")
        elif col_name == "Pre_Mitigation_Severity":
            cell.alignment = Alignment(horizontal="center", vertical="center")
            val = str(cell.value).strip()
            if val == "Critical":
                cell.fill = sev_critical_fill
                cell.font = sev_critical_font
            elif val == "High":
                cell.fill = sev_high_fill
                cell.font = sev_high_font
            elif val == "Medium":
                cell.fill = sev_medium_fill
                cell.font = sev_medium_font
            elif val == "Low":
                cell.fill = sev_low_fill
                cell.font = sev_low_font
        elif col_name == "Post_Mitigation_Status":
            cell.alignment = Alignment(horizontal="center", vertical="center")
            cell.fill = status_pass_fill
            cell.font = status_pass_font

# Auto-fit Column Widths
for col in ws.columns:
    max_len = 0
    col_letter = get_column_letter(col[0].column)
    for cell in col:
        val = str(cell.value or '')
        # Give more weight to shorter values, cap long text in length calc
        val_len = min(len(val), 45)
        if val_len > max_len:
            max_len = val_len
    ws.column_dimensions[col_letter].width = max(max_len + 4, 12)

# Specific adjustments for readability
ws.column_dimensions['A'].width = 16  # Test_ID
ws.column_dimensions['B'].width = 18  # MASVS_Category
ws.column_dimensions['C'].width = 38  # Vulnerability_Vector
ws.column_dimensions['D'].width = 32  # Target_Artifact
ws.column_dimensions['E'].width = 24  # Verification_Method
ws.column_dimensions['F'].width = 22  # Pre_Mitigation_Severity
ws.column_dimensions['G'].width = 65  # Mitigation_Applied
ws.column_dimensions['H'].width = 22  # Post_Mitigation_Status

# Freeze Top Header Row
ws.freeze_panes = "A2"

wb.save(excel_filename)
print(f"Berhasil membuat {excel_filename} dengan format styling formal IEEE/Scopus.")
