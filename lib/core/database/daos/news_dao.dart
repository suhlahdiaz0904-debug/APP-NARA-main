import 'dart:convert';
import 'package:flutter_application_1/core/database/tables/database_tables.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Data Access Object (DAO) for Community News, Expedition Reports, and Incident Bulletins.
class NewsDao {
  final sqflite.Database Function() _getDb;

  NewsDao(this._getDb);

  /// Saves or updates a news / incident report entry in SQLite with JSON-sanitized arrays.
  Future<void> saveBeritaAcara(Map<String, dynamic> berita) async {
    final db = _getDb();
    final sanitized = Map<String, dynamic>.from(berita);
    sanitized[NewsTable.columnCategories] ??= jsonEncode(<String>[]);
    sanitized[NewsTable.columnPhotos] ??= jsonEncode(<String>[]);
    await db.insert(
      NewsTable.tableName,
      sanitized,
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  /// Retrieves all news and incident reports ordered chronologically by date descending.
  Future<List<Map<String, dynamic>>> getAllBeritaAcara() async {
    final db = _getDb();
    final result = await db.query(
      NewsTable.tableName,
      orderBy: '${NewsTable.columnDate} DESC',
    );
    return result;
  }
}
