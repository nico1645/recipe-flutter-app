import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:convert' as convert;

class DatabaseHelper {
  // Private constructor
  DatabaseHelper._privateConstructor();

  // Singleton instance
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static const _databaseName = "recipes_database.db";
  static const _databaseVersion = 1;

  static const table = 'recipes';

  static const columnId = '_id';
  static const columnTitle = 'title';
  static const columnDescription = 'description';
  static const columnSearchKeywords = 'search_keywords';
  static const columnImagePath = 'image_path';
  static const columnCategory = 'category';

  late Database _db;

  // this opens the database (and creates it if it doesn't exist)
  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY,
            $columnTitle TEXT NOT NULL,
            $columnDescription TEXT,
            $columnSearchKeywords TEXT,
            $columnImagePath TEXT,
            $columnCategory TEXT
          )
          ''');
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table);
  }

  Future<List<Map<String, Object?>>> getById(int id) async {
    return await _db.query(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(Map<String, dynamic> row) async {
    int id = row[columnId];
    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(int id) async {
    return await _db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<String> generateBackup() async {
    List backups = await _db.query(table);

    String json = convert.jsonEncode(backups);

    return json;
  }

  Future<void> restoreBackup(String backup) async {
    Batch batch = _db.batch();

    List json = convert.jsonDecode(backup);

    for (var i = 0; i < json.length; i++) {
      batch.insert(table, json[i]);
    }
    await batch.commit(continueOnError: false, noResult: true);
  }

  Future<void> clearAllTables() async {
    await _db.delete(table);
  }
}
