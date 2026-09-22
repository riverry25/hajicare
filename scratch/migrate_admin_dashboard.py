import re

def migrate():
    # 1. admin_dashboard_screen.dart: add import
    p = 'lib/features/room/screens/admin_dashboard_screen.dart'
    with open(p, 'r', encoding='utf-8') as f:
        c = f.read()
    if "import '../../../core/locales/app_localizations.dart';" not in c:
        c = "import '../../../core/locales/app_localizations.dart';\n" + c
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

    # 2. admin_dashboard_sections.dart
    p2 = 'lib/features/room/screens/admin_dashboard_sections.dart'
    with open(p2, 'r', encoding='utf-8') as f:
        c2 = f.read()
    c2 = c2.replace("label: 'Buat Room',", "label: context.tr('room.createRoomBtn'),")
    c2 = c2.replace("subtitle: 'Grup/Kloter baru',", "subtitle: context.tr('room.newGroupOrKloter'),")
    c2 = c2.replace("label: 'Kelola Jamaah',", "label: context.tr('room.managePilgrims'),")
    c2 = c2.replace("subtitle: 'Daftar semua room',", "subtitle: context.tr('room.allRoomsList'),")
    c2 = c2.replace("label: 'Pantau Map',", "label: context.tr('room.monitorMap'),")
    c2 = c2.replace("subtitle: 'Lokasi & perimeter',", "subtitle: context.tr('room.locationAndPerimeter'),")
    c2 = c2.replace("label: 'Pusat Alert',", "label: context.tr('room.alertCenter'),")
    c2 = c2.replace("label: 'Kirim Siaran',", "label: context.tr('room.sendBroadcast'),")
    c2 = c2.replace("subtitle: 'Notifikasi broadcast',", "subtitle: context.tr('room.broadcastSub'),")
    c2 = c2.replace("label: 'Perimeter Radar',", "label: context.tr('room.perimeterRadar'),")
    c2 = c2.replace("subtitle: 'Radius aman jamaah',", "subtitle: context.tr('room.safeRadiusSub'),")
    with open(p2, 'w', encoding='utf-8') as f:
        f.write(c2)

    # 3. admin_dashboard_metrics.dart
    p3 = 'lib/features/room/screens/admin_dashboard_metrics.dart'
    with open(p3, 'r', encoding='utf-8') as f:
        c3 = f.read()
    c3 = c3.replace("label: 'Jamaah',", "label: context.tr('maps.pilgrims'),")
    c3 = c3.replace("sublabel: 'Data Jamaah',", "sublabel: context.tr('profile.groupAccountData'),")
    c3 = c3.replace("label: 'Room',", "label: context.tr('room.roomCode'),")
    c3 = c3.replace("sublabel: 'Room Aktif',", "sublabel: context.tr('room.activeRooms'),")
    c3 = c3.replace("label: 'Petugas',", "label: context.tr('maps.companions'),")
    c3 = c3.replace("sublabel: 'Siaga Maktab',", "sublabel: context.tr('room.officerDuty'),")
    c3 = c3.replace("sublabel: 'Pusat Alert',", "sublabel: context.tr('room.alertCenter'),")
    with open(p3, 'w', encoding='utf-8') as f:
        f.write(c3)

    # 4. admin_dashboard_jamaah_sheet.dart
    p4 = 'lib/features/room/screens/admin_dashboard_jamaah_sheet.dart'
    with open(p4, 'r', encoding='utf-8') as f:
        c4 = f.read()
    c4 = c4.replace("hintText: 'Cari jamaah atau maktab...',", "hintText: context.tr('room.searchJamaahOrMaktab'),")
    with open(p4, 'w', encoding='utf-8') as f:
        f.write(c4)

    # 5. admin_dashboard_sheets.dart
    p5 = 'lib/features/room/screens/admin_dashboard_sheets.dart'
    with open(p5, 'r', encoding='utf-8') as f:
        c5 = f.read()
    c5 = c5.replace("hintText: 'Cari aktivitas, kamar, atau jamaah...',", "hintText: context.tr('room.searchActivityOrPilgrim'),")
    with open(p5, 'w', encoding='utf-8') as f:
        f.write(c5)

    # 6. admin_dashboard_components.dart
    p6 = 'lib/features/room/screens/admin_dashboard_components.dart'
    with open(p6, 'r', encoding='utf-8') as f:
        c6 = f.read()
    c6 = c6.replace("'Kode Disalin'", "context.tr('room.codeCopied')")
    with open(p6, 'w', encoding='utf-8') as f:
        f.write(c6)

    print("Admin dashboard migration complete!")

if __name__ == '__main__':
    migrate()
