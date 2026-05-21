import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/asset.dart';
import '../models/loan.dart';
import '../models/asset_return.dart';
import '../models/maintenance.dart';
import '../models/history.dart';
import '../models/user.dart';

class LocalDbHelper {
  static final LocalDbHelper _instance = LocalDbHelper._internal();
  factory LocalDbHelper() => _instance;
  LocalDbHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'final_exam.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        uid TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        role INTEGER,
        status INTEGER,
        syncStatus INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE assets(
        id TEXT PRIMARY KEY,
        name TEXT,
        code TEXT,
        status TEXT,
        syncStatus INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE loans(
        id TEXT PRIMARY KEY,
        assetId TEXT,
        requestedBy TEXT,
        approvedBy TEXT,
        approvedBy TEXT,
        loanDate TEXT,
        dueDate TEXT,
        status INTEGER,
        syncStatus INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE returns(
        id TEXT PRIMARY KEY,
        loanId TEXT,
        returnDate TEXT,
        status TEXT,
        syncStatus INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenances(
        id TEXT PRIMARY KEY,
        assetId TEXT,
        technician TEXT,
        date TEXT,
        status TEXT,
        syncStatus INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE history(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        date TEXT,
        type TEXT,
        syncStatus INTEGER
      )
    ''');
  }

  // --- GENERIC CRUD OPERATIONS ---

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<Map<String, dynamic>?> getById(String table, String idColumn, String id) async {
    final db = await database;
    final res = await db.query(table, where: '$idColumn = ?', whereArgs: [id], limit: 1);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> update(String table, String idColumn, String id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(table, data, where: '$idColumn = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, String idColumn, String id) async {
    final db = await database;
    return await db.delete(table, where: '$idColumn = ?', whereArgs: [id]);
  }

  // Fetch pending items for sync
  Future<List<Map<String, dynamic>>> getPendingSync(String table) async {
    final db = await database;
    return await db.query(table, where: 'syncStatus = ?', whereArgs: [1]); // 1 is pendingSync
  }
}
