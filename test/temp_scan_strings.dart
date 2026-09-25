import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Scan dashboard and map for hardcoded Indonesian UI strings', () {
    final dirs = [
      Directory('lib/features/dashboard'),
      Directory('lib/features/map'),
      Directory('lib/features/profile'),
      Directory('lib/features/hajj_dua'),
    ];

    final knownIndo = [
      ' yang ', ' dan ', ' untuk ', ' dengan ', ' dari ', ' ke ', ' di ',
      ' ini ', ' itu ', ' anda ', ' kamu ', ' saya ', ' kami ', ' mereka ',
      ' saat ', ' ketika ', ' jika ', ' tidak ', ' belum ', ' bisa ', ' sudah ',
      ' silakan ', ' mohon ', ' harap ', ' kembali ', ' batal ', ' simpan ',
      ' unduh ', ' cari ', ' keluar ', ' masuk ', ' setelan ', ' pengaturan ',
      ' bahasa ', ' riwayat ', ' bantuan ', ' tentang ', ' doa ', ' bacaan ',
      ' putaran ', ' porsi ', ' kesehatan ', ' darurat ', ' kamar ', ' rute ',
      ' jamaah ', ' pendamping ', ' petugas ', ' salin ', ' lihat ', ' tutup ',
      ' panggil ', ' telepon ', ' peta ', ' jarak ', ' aktif ', ' selesai '
    ];

    for (final dir in dirs) {
      if (!dir.existsSync()) continue;
      final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        if (file.path.contains('hajj_dua_data.dart')) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trim().startsWith('//')) continue;
          if (line.contains('debugPrint') || line.contains('print(') || line.contains("key:") || line.contains("Key(")) continue;

          for (final word in knownIndo) {
            // Find quoted strings containing word
            final matches = RegExp("['\"]([^'\"]*" + RegExp.escape(word) + "[^'\"]*)['\"]").allMatches(line);
            for (final m in matches) {
              final text = m.group(1)!;
              if (text.contains('/') || (text.contains('_') && !text.contains(' '))) continue;
              print('${file.path}:${i+1}: "$text"');
            }
          }
        }
      }
    }
  });
}
