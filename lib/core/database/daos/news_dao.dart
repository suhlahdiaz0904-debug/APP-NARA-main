import 'dart:convert';
import 'package:flutter_application_1/core/database/tables/database_tables.dart';
import 'package:flutter_application_1/core/services/news_firestore_service.dart';
import 'package:flutter_application_1/features/news/models/news_model.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Data Access Object (DAO) for Community News, Expedition Reports, and Incident Bulletins
/// with automatic background synchronization to Cloud Firestore (`nara_community_news`).
class NewsDao {
  final sqflite.Database Function() _getDb;

  NewsDao(this._getDb);

  /// Saves or updates a news / incident report entry in SQLite with JSON-sanitized arrays,
  /// and automatically synchronizes to Cloud Firestore.
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

    // Sinkronisasi otomatis ke Cloud Firestore
    try {
      final model = BeritaModel.fromMap(sanitized);
      NewsFirestoreService.instance.saveNewsPostToCloud(model);
    } catch (_) {}
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
