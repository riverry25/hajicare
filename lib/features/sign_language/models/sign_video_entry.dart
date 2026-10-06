/// Source asal media video bahasa isyarat.
enum SignVideoSource {
  /// Video berasal dari bundled assets di dalam APK (tersedia offline sejak install).
  asset,

  /// Video berada di Firebase Hosting (perlu diunduh).
  remote,

  /// Video remote yang telah berhasil diunduh dan tersimpan di persistent local storage.
  localCached;

  String get displayName {
    switch (this) {
      case SignVideoSource.asset:
        return 'Aset Offline';
      case SignVideoSource.localCached:
        return 'Tersimpan di Perangkat';
      case SignVideoSource.remote:
        return 'Perlu Diunduh';
    }
  }

  bool get isOfflineAvailable =>
      this == SignVideoSource.asset || this == SignVideoSource.localCached;
}

/// Model data type-safe untuk setiap video bahasa isyarat (SIBI & BISINDO).
class SignVideoEntry {
  final String id;
  final String language; // 'sibi' atau 'bisindo'
  final String type; // 'alphabet', 'word', 'phrase'
  final String label;
  final List<String> aliases;
  final String category; // 'alphabet', 'health', 'hajj', 'emergency', dsb.
  final int version;
  final String path; // Asset path atau remote relative path
  final SignVideoSource source;
  final String? cachedFilePath; // Path file lokal jika sudah di-cache

  const SignVideoEntry({
    required this.id,
    required this.language,
    required this.type,
    required this.label,
    required this.aliases,
    required this.category,
    required this.version,
    required this.path,
    required this.source,
    this.cachedFilePath,
  });

  /// Nama unik file cache di disk: `${id}_v${version}.mp4`
  String get cacheFileName => '${id}_v$version.mp4';

  bool get isOfflineReady => source.isOfflineAvailable;

  SignVideoEntry copyWith({
    String? id,
    String? language,
    String? type,
    String? label,
    List<String>? aliases,
    String? category,
    int? version,
    String? path,
    SignVideoSource? source,
    String? cachedFilePath,
  }) {
    return SignVideoEntry(
      id: id ?? this.id,
      language: language ?? this.language,
      type: type ?? this.type,
      label: label ?? this.label,
      aliases: aliases ?? this.aliases,
      category: category ?? this.category,
      version: version ?? this.version,
      path: path ?? this.path,
      source: source ?? this.source,
      cachedFilePath: cachedFilePath ?? this.cachedFilePath,
    );
  }

  factory SignVideoEntry.fromJson(
    Map<String, dynamic> json, {
    SignVideoSource source = SignVideoSource.remote,
    String? cachedFilePath,
  }) {
    return SignVideoEntry(
      id: json['id'] as String? ?? '',
      language: (json['language'] as String? ?? 'sibi').toLowerCase(),
      type: (json['type'] as String? ?? 'word').toLowerCase(),
      label: json['label'] as String? ?? '',
      aliases:
          (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase().trim())
              .toList() ??
          [],
      category: (json['category'] as String? ?? 'general').toLowerCase(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      path: json['path'] as String? ?? '',
      source: source,
      cachedFilePath: cachedFilePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language,
      'type': type,
      'label': label,
      'aliases': aliases,
      'category': category,
      'version': version,
      'path': path,
    };
  }

  @override
  String toString() =>
      'SignVideoEntry(id: $id, lang: $language, label: $label, src: ${source.name}, ver: $version)';
}
