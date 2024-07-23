import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE feedback('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'location TEXT, '
          'event TEXT, '
          'issues TEXT, '
          'additional_info TEXT, '
          'timestamp TEXT)',
        );
        await db.execute(
          'CREATE TABLE users('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'username TEXT, '
          'password TEXT)',
        );
      },
    );
  }

  // Feedback methods
  Future<void> insertFeedback(Map<String, dynamic> feedback) async {
    final db = await database;
    await db.insert(
      'feedback',
      feedback,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFeedbacks() async {
    final db = await database;
    return db.query('feedback', orderBy: 'timestamp DESC');
  }

  Future<void> updateFeedback(int id, Map<String, dynamic> feedback) async {
    final db = await database;
    await db.update(
      'feedback',
      feedback,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFeedback(int id) async {
    final db = await database;
    await db.delete(
      'feedback',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // User methods
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return db.query('users', orderBy: 'id ASC');
  }

  Future<void> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
