import 'dart:io';
import '../../media_library/data/recordings_database.dart';
import '../../media_library/domain/media_item.dart';
import 'recording_storage_service.dart';

/// Service that scans the sandbox for unindexed video files (e.g. from crash or abrupt shutdown)
/// and automatically recovers them into the SQLite database.
class OrphanRecoveryService {
  final RecordingStorageService _storageService;
  final RecordingsDatabase _database;

  OrphanRecoveryService({
    required RecordingStorageService storageService,
    required RecordingsDatabase database,
  })  : _storageService = storageService,
        _database = database;

  /// Scans recordings directory and indexes any orphan files into database.
  /// Returns the number of recovered files.
  Future<int> recoverOrphanRecordings() async {
    final dir = await _storageService.getRecordingsDirectory();
    if (!await dir.exists()) return 0;

    int recoveredCount = 0;
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.mp4')) {
        final String path = entity.path;
        final int length = await entity.length();
        if (length == 0) continue; // Ignore 0KB corrupted stub files

        // Check if already indexed in database
        final existing = await _database.getRecordingByPath(path);
        if (existing == null) {
          final filename = entity.uri.pathSegments.last;
          final modified = await entity.lastModified();

          // Estimate duration roughly (1MB ~ 2 seconds for high preset video)
          final estimatedDurationSeconds = (length / (500 * 1024)).ceil().clamp(1, 7200);

          final recoveredItem = MediaItem(
            filename: filename,
            filepath: path,
            durationSeconds: estimatedDurationSeconds,
            fileSizeBytes: length,
            createdAt: modified,
          );

          await _database.insertRecording(recoveredItem);
          recoveredCount++;
        }
      }
    }

    return recoveredCount;
  }
}
