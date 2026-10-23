import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';

/// Service managing video file storage in the app sandbox.
class RecordingStorageService {
  final Directory? _overrideDir;

  RecordingStorageService({Directory? overrideDir}) : _overrideDir = overrideDir;

  /// Gets the dedicated recordings directory inside the application sandbox.
  Future<Directory> getRecordingsDirectory() async {
    final overrideDir = _overrideDir;
    if (overrideDir != null) {
      if (!await overrideDir.exists()) {
        await overrideDir.create(recursive: true);
      }
      return overrideDir;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(p.join(appDocDir.path, AppConstants.recordingsDir));
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return recordingsDir;
  }

  /// Generates a standardized, timestamped file path for a new recording.
  /// Format: REC_YYYYMMDD_HHMMSS.mp4
  Future<String> generateNewRecordingPath() async {
    final dir = await getRecordingsDirectory();
    final now = DateTime.now();
    final String timestamp = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final String filename = 'REC_$timestamp.mp4';
    return p.join(dir.path, filename);
  }

  /// Validates that a completed recording file exists and has non-zero size.
  Future<bool> validateRecordingFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return false;
    }
    final length = await file.length();
    return length > 0;
  }

  /// Calculates total bytes used by all files in the recordings directory.
  Future<int> calculateTotalRecordingsBytes() async {
    final dir = await getRecordingsDirectory();
    if (!await dir.exists()) return 0;

    int totalBytes = 0;
    await for (final entity in dir.list(recursive: false, followLinks: false)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes;
  }

  /// Deletes a recording file from disk.
  Future<bool> deleteRecordingFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
