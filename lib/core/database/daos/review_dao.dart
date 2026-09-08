import 'package:flutter_application_1/core/database/tables/database_tables.dart';
import 'package:flutter_application_1/features/news/models/review_model.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Data Access Object (DAO) for Explorer Reviews SQLite storage.
class ReviewDao {
  final sqflite.Database Function() _getDb;

  ReviewDao(this._getDb);

  /// Saves or updates a review in SQLite.
  Future<void> saveReview(ReviewModel review) async {
    final db = _getDb();
    await db.insert(
      ReviewTable.tableName,
      review.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  /// Bulk saves reviews (e.g. from Cloud sync).
  Future<void> saveAllReviews(List<ReviewModel> reviews) async {
    final db = _getDb();
    final batch = db.batch();
    for (final r in reviews) {
      batch.insert(
        ReviewTable.tableName,
        r.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Retrieves reviews for a specific spot sorted by newest first (descending).
  Future<List<ReviewModel>> getReviewsForSpot(String spotId) async {
    final db = _getDb();
    final cleanSpotId = normalizeSpotId(spotId);
    final result = await db.query(
      ReviewTable.tableName,
      where: '${ReviewTable.columnSpotId} = ? OR ${ReviewTable.columnDestinationName} = ?',
      whereArgs: [cleanSpotId, spotId],
      orderBy: '${ReviewTable.columnCreatedAt} DESC',
    );

    return result.map((m) => ReviewModel.fromMap(m)).toList();
  }

  /// Normalizes spotId string to ensure consistent matching across casing/spaces
  static String normalizeSpotId(String raw) {
    return raw
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  /// Retrieves all reviews across all spots sorted by newest first.
  Future<List<ReviewModel>> getAllReviews() async {
    final db = _getDb();
    final result = await db.query(
      ReviewTable.tableName,
      orderBy: '${ReviewTable.columnCreatedAt} DESC',
    );
    return result.map((m) => ReviewModel.fromMap(m)).toList();
  }

  /// Deletes a review by ID.
  Future<int> deleteReview(String id) async {
    final db = _getDb();
    return await db.delete(
      ReviewTable.tableName,
      where: '${ReviewTable.columnId} = ?',
      whereArgs: [id],
    );
  }
}
