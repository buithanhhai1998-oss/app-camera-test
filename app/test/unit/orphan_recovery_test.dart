import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_sideload_app/features/media_library/data/recordings_database.dart';
import 'package:flutter_sideload_app/features/recording/services/orphan_recovery_service.dart';
import 'package:flutter_sideload_app/features/recording/services/recording_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('OrphanRecoveryService Tests', () {
    late Directory tempDir;
    late RecordingStorageService storageService;
    late Database memoryDb;
    late RecordingsDatabase database;
    late OrphanRecoveryService recoveryService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('orphan_recovery_test_');
      storageService = RecordingStorageService(overrideDir: tempDir);

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
      database = RecordingsDatabase(memoryDb);
      recoveryService = OrphanRecoveryService(
        storageService: storageService,
        database: database,
      );
    });

    tearDown(() async {
      await database.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Recovers unindexed .mp4 files and ignores 0KB or already indexed files', () async {
      // 1. Create an unindexed valid .mp4 file (orphan)
      final orphanFile = File('${tempDir.path}/REC_20261023_090000.mp4');
      await orphanFile.writeAsBytes(List.filled(2048, 1));

      // 2. Create a 0KB corrupt file (should be ignored)
      final corruptFile = File('${tempDir.path}/corrupt.mp4');
      await corruptFile.writeAsBytes([]);

      // 3. Create a non-mp4 file (should be ignored)
      final txtFile = File('${tempDir.path}/notes.txt');
      await txtFile.writeAsString('not a video');

      expect((await database.getAllRecordings()).isEmpty, isTrue);

      final recovered = await recoveryService.recoverOrphanRecordings();
      expect(recovered, equals(1));

      final allInDb = await database.getAllRecordings();
      expect(allInDb.length, equals(1));
      expect(allInDb.first.filename, equals('REC_20261023_090000.mp4'));
      expect(allInDb.first.fileSizeBytes, equals(2048));

      // Running recovery again should find 0 new orphans
      final recoveredSecondRun = await recoveryService.recoverOrphanRecordings();
      expect(recoveredSecondRun, equals(0));
    });
  });
}
