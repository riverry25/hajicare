import 'sign_video_entry.dart';

/// Model katalog video bahasa isyarat dari remote static hosting.
class SignLanguageCatalog {
  final int schemaVersion;
  final String catalogVersion;
  final String updatedAt;
  final List<SignVideoEntry> videos;

  const SignLanguageCatalog({
    required this.schemaVersion,
    required this.catalogVersion,
    required this.updatedAt,
    required this.videos,
  });

  factory SignLanguageCatalog.fromJson(Map<String, dynamic> json) {
    final rawVideos = json['videos'] as List<dynamic>? ?? [];
    final parsedVideos = rawVideos
        .whereType<Map<String, dynamic>>()
        .map((item) => SignVideoEntry.fromJson(item))
        .toList();

    return SignLanguageCatalog(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      catalogVersion: json['catalogVersion'] as String? ?? '1.0.0',
      updatedAt: json['updatedAt'] as String? ?? '',
      videos: parsedVideos,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'catalogVersion': catalogVersion,
      'updatedAt': updatedAt,
      'videos': videos.map((v) => v.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'SignLanguageCatalog(version: $catalogVersion, count: ${videos.length})';
}
