import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_sideload_app/features/media_library/data/recordings_database.dart';
import 'package:flutter_sideload_app/features/media_library/domain/media_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('RecordingsDatabase SQLite Unit Tests (via FFI)', () {
    late Database memoryDb;
    late RecordingsDatabase recordingsDb;

    setUp(() async {
      memoryDb = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE recordings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                filename TEXT NOT NULL,
                filepath TEXT NOT NULL UNIQUE,
                duration_seconds INTEGER NOT NULL,
                file_size_bytes INTEGER NOT NULL,
                created_at TEXT NOT NULL,
                thumbnail_path TEXT
              )
            ''');
          },
        ),
      );
      recordingsDb = RecordingsDatabase(memoryDb);
    });

    tearDown(() async {
      await recordingsDb.close();
    });

    test('Insert and retrieve recording metadata', () async {
      final now = DateTime.now();
      final item = MediaItem(
        filename: 'REC_20261023_080000.mp4',
        filepath: '/docs/recordings/REC_20261023_080000.mp4',
        durationSeconds: 125,
        fileSizeBytes: 15728640,
        createdAt: now,
      );

      final id = await recordingsDb.insertRecording(item);
      expect(id, isPositive);

      final all = await recordingsDb.getAllRecordings();
      expect(all.length, equals(1));
      expect(all.first.filename, equals('REC_20261023_080000.mp4'));
      expect(all.first.durationSeconds, equals(125));
      expect(all.first.formattedDuration, equals('02:05'));
      expect(all.first.formattedSize, equals('15.0 MB'));
    });

    test('Query filtering by filename search query', () async {
      await recordingsDb.insertRecording(MediaItem(
        filename: 'REC_ALPHA_01.mp4',
        filepath: '/path/1.mp4',
        durationSeconds: 10,
        fileSizeBytes: 1000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ));
      await recordingsDb.insertRecording(MediaItem(
        filename: 'REC_BETA_02.mp4',
        filepath: '/path/2.mp4',
        durationSeconds: 20,
        fileSizeBytes: 2000,
        createdAt: DateTime.now(),
      ));

      final alphaResults = await recordingsDb.getAllRecordings(searchQuery: 'ALPHA');
      expect(alphaResults.length, equals(1));
      expect(alphaResults.first.filename, equals('REC_ALPHA_01.mp4'));

      final allResults = await recordingsDb.getAllRecordings(searchQuery: 'REC');
      expect(allResults.length, equals(2));
    });

    test('Sort by duration, size, and oldest', () async {
      final t1 = DateTime.now().subtract(const Duration(hours: 1));
      final t2 = DateTime.now();

      await recordingsDb.insertRecording(MediaItem(
        filename: 'ShortSmall.mp4',
        filepath: '/path/s.mp4',
        durationSeconds: 5,
        fileSizeBytes: 500,
        createdAt: t1,
      ));
      await recordingsDb.insertRecording(MediaItem(
        filename: 'LongLarge.mp4',
        filepath: '/path/l.mp4',
        durationSeconds: 300,
        fileSizeBytes: 50000,
        createdAt: t2,
      ));

      // Sort by duration descending
      final byDuration = await recordingsDb.getAllRecordings(sortBy: 'duration');
      expect(byDuration.first.filename, equals('LongLarge.mp4'));

      // Sort by oldest
      final byOldest = await recordingsDb.getAllRecordings(sortBy: 'oldest');
      expect(byOldest.first.filename, equals('ShortSmall.mp4'));
    });

    test('Delete recording removes record from table', () async {
      final id = await recordingsDb.insertRecording(MediaItem(
        filename: 'ToDelete.mp4',
        filepath: '/path/del.mp4',
        durationSeconds: 1,
        fileSizeBytes: 100,
        createdAt: DateTime.now(),
      ));

      expect((await recordingsDb.getAllRecordings()).length, equals(1));

      final rowsDeleted = await recordingsDb.deleteRecording(id);
      expect(rowsDeleted, equals(1));
      expect((await recordingsDb.getAllRecordings()).isEmpty, isTrue);
    });
  });
}
