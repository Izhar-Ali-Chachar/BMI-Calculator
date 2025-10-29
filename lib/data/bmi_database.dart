import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// FFI import for desktop platforms
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../model/BmiRecord.dart';

class BMIDatabase {
  static final BMIDatabase instance = BMIDatabase._init();
  static Database? _database;

  // in-memory fallback for web
  final List<BMIRecord> _inMemory = [];
  int _nextId = 1;

  BMIDatabase._init();

  Future<Database> get database async {
    // If running on web we don't have a sqflite Database -> caller should not rely on this.
    if (kIsWeb) {
      throw Exception('BMIDatabase: database getter not available on web; use insertRecord/getRecords which handle web fallback.');
    }
    if (_database != null) return _database!;
    _database = await _initDB('bmi_records.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    // If running on a desktop platform, initialize sqflite FFI and set the global factory
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
         defaultTargetPlatform == TargetPlatform.linux ||
         defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('BMIDatabase: initialized sqflite_common_ffi for desktop');
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    print('BMIDatabase: initializing database at $path');
    try {
      return await openDatabase(path, version: 1, onCreate: _createDB);
    } catch (e, st) {
      print('BMIDatabase: failed to open/create DB at $path -> $e\n$st');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bmi_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bmi REAL NOT NULL,
        category TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        gender TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    print('BMIDatabase: table bmi_records created');
  }

  Future<BMIRecord> insertRecord(BMIRecord record) async {
    // web fallback: store in memory
    if (kIsWeb) {
      final copy = BMIRecord(
        id: _nextId++,
        bmi: record.bmi,
        category: record.category,
        height: record.height,
        weight: record.weight,
        gender: record.gender,
        createdAt: record.createdAt,
      );
      _inMemory.insert(0, copy); // newest first
      print('BMIDatabase: (web) inserted in-memory record id=${copy.id}');
      return copy;
    }

    final db = await instance.database;
    try {
      final id = await db.insert('bmi_records', record.toMap());
      record.id = id;
      print('BMIDatabase: inserted record id=$id');
      return record;
    } catch (e, st) {
      print('BMIDatabase: insertRecord failed -> $e\n$st');
      rethrow;
    }
  }

  Future<List<BMIRecord>> getRecords() async {
    // web fallback
    if (kIsWeb) {
      print('BMIDatabase: (web) fetched ${_inMemory.length} in-memory records');
      return List<BMIRecord>.from(_inMemory);
    }

    final db = await instance.database;
    try {
      final maps = await db.query('bmi_records', orderBy: 'createdAt DESC');
      print('BMIDatabase: fetched ${maps.length} records');
      return maps.map((m) => BMIRecord.fromMap(m)).toList();
    } catch (e, st) {
      print('BMIDatabase: getRecords failed -> $e\n$st');
      rethrow;
    }
  }

  Future<int> deleteAll() async {
    if (kIsWeb) {
      final len = _inMemory.length;
      _inMemory.clear();
      _nextId = 1;
      print('BMIDatabase: (web) deleted $len in-memory records');
      return len;
    }
    final db = await instance.database;
    return await db.delete('bmi_records');
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    await db.close();
  }
}
