enum UpdateStatus {
  upToDate,
  optional,
  forced,
  unknown,
}

class AppUpdateInfo {
  final String versionName;
  final int buildNumber;
  final int minSupportedBuild;
  final String downloadUrl;
  final String sha256;
  final int? fileSizeBytes;
  final String changelogId;
  final String changelogEn;
  final DateTime? releasedAt;

  const AppUpdateInfo({
    required this.versionName,
    required this.buildNumber,
    required this.minSupportedBuild,
    required this.downloadUrl,
    required this.sha256,
    this.fileSizeBytes,
    this.changelogId = '',
    this.changelogEn = '',
    this.releasedAt,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> j) => AppUpdateInfo(
        versionName: (j['version_name'] ?? '') as String,
        buildNumber: (j['build_number'] ?? 0) as int,
        minSupportedBuild: (j['min_supported_build'] ?? 0) as int,
        downloadUrl: (j['download_url'] ?? '') as String,
        sha256: (j['sha256'] ?? '') as String,
        fileSizeBytes: j['file_size_bytes'] != null ? (j['file_size_bytes'] as num).toInt() : null,
        changelogId: (j['changelog_id'] ?? '') as String,
        changelogEn: (j['changelog_en'] ?? '') as String,
        releasedAt: j['released_at'] != null ? DateTime.tryParse(j['released_at'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'version_name': versionName,
        'build_number': buildNumber,
        'min_supported_build': minSupportedBuild,
        'download_url': downloadUrl,
        'sha256': sha256,
        'file_size_bytes': fileSizeBytes,
        'changelog_id': changelogId,
        'changelog_en': changelogEn,
        if (releasedAt != null) 'released_at': releasedAt!.toIso8601String(),
      };
}
