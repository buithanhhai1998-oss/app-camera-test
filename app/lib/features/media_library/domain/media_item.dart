/// Entity representing a recorded video in the secure media vault.
class MediaItem {
  final int? id;
  final String filename;
  final String filepath;
  final int durationSeconds;
  final int fileSizeBytes;
  final DateTime createdAt;
  final String? thumbnailPath;

  const MediaItem({
    this.id,
    required this.filename,
    required this.filepath,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.createdAt,
    this.thumbnailPath,
  });

  String get formattedDuration {
    final minutes = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final y = createdAt.year;
    final m = createdAt.month.toString().padLeft(2, '0');
    final d = createdAt.day.toString().padLeft(2, '0');
    final h = createdAt.hour.toString().padLeft(2, '0');
    final min = createdAt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'filename': filename,
      'filepath': filepath,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'created_at': createdAt.toIso8601String(),
      'thumbnail_path': thumbnailPath,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as int?,
      filename: map['filename'] as String,
      filepath: map['filepath'] as String,
      durationSeconds: map['duration_seconds'] as int,
      fileSizeBytes: map['file_size_bytes'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      thumbnailPath: map['thumbnail_path'] as String?,
    );
  }
}
