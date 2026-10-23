import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/media_item.dart';

/// SQLite Database Manager for video recordings metadata.
class RecordingsDatabase {
  Database? _db;

  RecordingsDatabase([Database? db]) : _db = db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb(AppConstants.dbName);
    return _db!;
  }

  Future<Database> _initDb(String dbName) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);

    return await openDatabase(
      path,
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
    );
  }

  /// Inserts a newly recorded video metadata record.
  Future<int> insertRecording(MediaItem item) async {
    final db = await database;
    return await db.insert(
      'recordings',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all recordings with optional query filtering and ordering.
  Future<List<MediaItem>> getAllRecordings({
    String? searchQuery,
    String sortBy = 'newest', // 'newest', 'oldest', 'duration', 'size'
  }) async {
    final db = await database;

    String orderBy;
    switch (sortBy) {
      case 'oldest':
        orderBy = 'created_at ASC';
        break;
      case 'duration':
        orderBy = 'duration_seconds DESC';
        break;
      case 'size':
        orderBy = 'file_size_bytes DESC';
        break;
      case 'newest':
      default:
        orderBy = 'created_at DESC';
        break;
    }

    List<Map<String, dynamic>> results;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      results = await db.query(
        'recordings',
        where: 'filename LIKE ?',
        whereArgs: ['%$searchQuery%'],
        orderBy: orderBy,
      );
    } else {
      results = await db.query(
        'recordings',
        orderBy: orderBy,
      );
    }

    return results.map((m) => MediaItem.fromMap(m)).toList();
  }

  /// Retrieves a single recording by file path.
  Future<MediaItem?> getRecordingByPath(String path) async {
    final db = await database;
    final results = await db.query(
      'recordings',
      where: 'filepath = ?',
      whereArgs: [path],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MediaItem.fromMap(results.first);
  }

  /// Deletes a recording entry from SQLite.
  Future<int> deleteRecording(int id) async {
    final db = await database;
    return await db.delete(
      'recordings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Clears all database records.
  Future<int> clearAll() async {
    final db = await database;
    return await db.delete('recordings');
  }

  /// Closes database connection.
  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }
}
