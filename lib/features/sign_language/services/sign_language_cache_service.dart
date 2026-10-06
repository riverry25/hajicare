import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sign_video_entry.dart';

/// Layanan manajemen penyimpanan lokal permanen (Persistent Local Storage)
/// untuk katalog metadata dan video remote bahasa isyarat yang diunduh.
///
/// Menyimpan data di bawah:
/// `ApplicationSupportDirectory/sign_language/`
/// ├── catalog.json
/// └── videos/
///     ├── sibi/
///     └── bisindo/
class SignLanguageCacheService {
  static SignLanguageCacheService? _instance;
  static SignLanguageCacheService get instance =>
      _instance ??= SignLanguageCacheService._();

  SignLanguageCacheService._();

  Directory? _baseDir;

  /// Memastikan folder direktori dasar `sign_language` telah diinisialisasi.
  Future<Directory> _getBaseDirectory() async {
    if (_baseDir != null && await _baseDir!.exists()) {
      return _baseDir!;
    }
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}/sign_language');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _baseDir = dir;
    return dir;
  }

  /// File `catalog.json` lokal.
  Future<File> getCatalogFile() async {
    final base = await _getBaseDirectory();
    return File('${base.path}/catalog.json');
  }

  /// Folder video untuk bahasa tertentu ('sibi' atau 'bisindo').
  Future<Directory> getVideoDirectory(String language) async {
    final base = await _getBaseDirectory();
    final cleanLang = language.toLowerCase().trim();
    final dir = Directory('${base.path}/videos/$cleanLang');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Target path file lokal untuk suatu video entry:
  /// `${base}/videos/${language}/${id}_v${version}.mp4`
  Future<File> getTargetVideoFile(SignVideoEntry entry) async {
    final dir = await getVideoDirectory(entry.language);
    return File('${dir.path}/${entry.cacheFileName}');
  }

  /// Mengecek apakah file video versi tersebut sudah tersimpan di cache lokal.
  Future<bool> isVideoCached(SignVideoEntry entry) async {
    try {
      final file = await getTargetVideoFile(entry);
      if (await file.exists()) {
        final length = await file.length();
        return length > 1024; // Minimal valid size
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Mengambil objek File video cache jika ada.
  Future<File?> getCachedVideoFile(SignVideoEntry entry) async {
    try {
      final file = await getTargetVideoFile(entry);
      if (await file.exists() && await file.length() > 1024) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('[SignCache] Error getting cached file: $e');
      return null;
    }
  }

  /// Menyimpan teks JSON katalog ke `catalog.json`.
  Future<void> saveCatalogJson(String jsonString) async {
    try {
      final file = await getCatalogFile();
      await file.writeAsString(jsonString, flush: true);
      debugPrint(
        '[SignCache] Catalog cached successfully (${jsonString.length} bytes)',
      );
    } catch (e) {
      debugPrint('[SignCache] Error saving catalog: $e');
    }
  }

  /// Membaca teks JSON dari `catalog.json` lokal jika ada.
  Future<String?> readCachedCatalogJson() async {
    try {
      final file = await getCatalogFile();
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('[SignCache] Error reading cached catalog: $e');
      return null;
    }
  }

  /// Menghapus satu file video yang diunduh.
  Future<bool> deleteCachedVideo(SignVideoEntry entry) async {
    try {
      final file = await getTargetVideoFile(entry);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[SignCache] Deleted video: ${entry.cacheFileName}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[SignCache] Error deleting video: $e');
      return false;
    }
  }

  /// Menghapus semua file video remote yang disimpan lokal.
  /// CATATAN: Bundled assets TIDAK PERNAH disentuh atau dihapus.
  Future<int> clearAllDownloadedVideos() async {
    int deletedCount = 0;
    try {
      final base = await _getBaseDirectory();
      final videosDir = Directory('${base.path}/videos');
      if (await videosDir.exists()) {
        final entities = videosDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.mp4')) {
            await entity.delete();
            deletedCount++;
          }
        }
      }
      debugPrint('[SignCache] Cleared $deletedCount downloaded videos');
    } catch (e) {
      debugPrint('[SignCache] Error clearing downloaded videos: $e');
    }
    return deletedCount;
  }

  /// Menghitung total ukuran file video yang telah diunduh dalam satuan bytes.
  Future<int> getTotalCachedSizeBytes() async {
    int totalBytes = 0;
    try {
      final base = await _getBaseDirectory();
      final videosDir = Directory('${base.path}/videos');
      if (await videosDir.exists()) {
        final entities = videosDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File && entity.path.endsWith('.mp4')) {
            totalBytes += await entity.length();
          }
        }
      }
    } catch (_) {}
    return totalBytes;
  }
}
