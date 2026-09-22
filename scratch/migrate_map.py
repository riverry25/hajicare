import re

def migrate_map():
    # 1. interactive_map_screen.dart
    p = 'lib/features/map/screens/interactive_map_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()

    # ensure import
    if "import '../../../core/locales/app_localizations.dart';" not in c:
        c = "import '../../../core/locales/app_localizations.dart';\n" + c

    c = c.replace("'Semua'", "context.tr('maps.all')")
    c = c.replace("'Posko Medis'", "context.tr('maps.medicalPostPoi')")
    c = c.replace("'Toilet & Wudhu'", "context.tr('maps.toiletAndWudhu')")
    c = c.replace("'Maktab'", "context.tr('maps.maktabPoi')")
    c = c.replace("'Pos Pantau'", "context.tr('maps.guardPost')")
    c = c.replace("'Hotel'", "context.tr('maps.hotelPoi')")
    c = c.replace("'Lokasi Disalin'", "context.tr('maps.locationCopied')")
    c = c.replace("'Lokasi Belum Tersedia'", "context.tr('maps.locationUnavailable')")
    c = c.replace("'Nomor Telepon Belum Tersedia'", "context.tr('maps.phoneUnavailable')")
    c = c.replace("'Gelang Belum Terhubung'", "context.tr('maps.bandDisconnected')")

    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)
    print("Migrated interactive_map_screen.dart")

    # 2. map_bottom_sheet.dart
    p2 = 'lib/features/map/widgets/map_bottom_sheet.dart'
    with open(p2, 'r', encoding='utf-8') as f:
        c2 = f.read()

    if "import '../../../core/locales/app_localizations.dart';" not in c2:
        c2 = "import '../../../core/locales/app_localizations.dart';\n" + c2

    c2 = c2.replace("'Langsung'", "context.tr('maps.direct')")
    c2 = c2.replace("'Jalan Kaki'", "context.tr('maps.walking')")
    c2 = c2.replace("'Estimasi'", "context.tr('maps.estimate')")
    c2 = c2.replace("'Cari nama atau status...'", "context.tr('maps.searchNameOrStatus')")

    with open(p2, 'w', encoding='utf-8') as f:
        f.write(c2)
    print("Migrated map_bottom_sheet.dart")

    # 3. map_top_header.dart
    p3 = 'lib/features/map/widgets/map_top_header.dart'
    with open(p3, 'r', encoding='utf-8') as f:
        c3 = f.read()

    if "import '../../../core/locales/app_localizations.dart';" not in c3:
        c3 = "import '../../../core/locales/app_localizations.dart';\n" + c3

    c3 = c3.replace("'Search Location...'", "context.tr('maps.searchPlaceholder')")

    with open(p3, 'w', encoding='utf-8') as f:
        f.write(c3)
    print("Migrated map_top_header.dart")

    # 4. map_controller.dart
    p4 = 'lib/features/map/controllers/map_controller.dart'
    with open(p4, 'r', encoding='utf-8') as f:
        c4 = f.read()

    if "import '../../../core/locales/app_translations.dart';" not in c4:
        c4 = "import '../../../core/locales/app_translations.dart';\n" + c4

    c4 = c4.replace("'Lokasi Ponsel Belum Aktif'", "AppTranslations.tr('maps.phoneGpsInactive')")
    c4 = c4.replace("'Izin Lokasi Diperlukan'", "AppTranslations.tr('maps.locationPermissionRequired')")
    c4 = c4.replace("'Buka Pengaturan Lokasi'", "AppTranslations.tr('maps.openLocationSettings')")
    c4 = c4.replace("'Tampilan Peta Diubah'", "AppTranslations.tr('maps.mapViewChanged')")

    with open(p4, 'w', encoding='utf-8') as f:
        f.write(c4)
    print("Migrated map_controller.dart")

if __name__ == '__main__':
    migrate_map()
