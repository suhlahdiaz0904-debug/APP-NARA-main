import 'package:flutter_application_1/core/database/tables/database_tables.dart';
import 'package:flutter_application_1/core/services/bookmark_firestore_service.dart';
import 'package:flutter_application_1/features/map/models/bookmark_model.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Data Access Object (DAO) for User Bookmarks and Favorited Cave Spots
/// with automatic background Cloud Firestore synchronization (`nara_user_bookmarks`).
class BookmarkDao {
  final sqflite.Database Function() _getDb;

  BookmarkDao(this._getDb);

  /// Checks whether a particular spot has been bookmarked by a specific user.
  Future<bool> isBookmarked(int userId, String spotId) async {
    final db = _getDb();
    final maps = await db.query(
      BookmarkTable.tableName,
      where: '${BookmarkTable.columnUserId} = ? AND ${BookmarkTable.columnSpotId} = ?',
      whereArgs: [userId, spotId],
    );
    return maps.isNotEmpty;
  }

  /// Toggles bookmark state for a user. Returns `true` if saved, `false` if removed.
  Future<bool> toggleBookmark({
    required int userId,
    required String spotId,
    required String title,
    required String location,
    required String type,
    required String imageUrl,
    String? rating,
    String? elevation,
    String? coordinates,
  }) async {
    final db = _getDb();
    final exists = await isBookmarked(userId, spotId);

    if (exists) {
      await db.delete(
        BookmarkTable.tableName,
        where: '${BookmarkTable.columnUserId} = ? AND ${BookmarkTable.columnSpotId} = ?',
        whereArgs: [userId, spotId],
      );

      // Sinkronisasi hapus ke Cloud Firestore
      BookmarkFirestoreService.instance.removeBookmarkFromCloud(spotId);

      return false;
    } else {
      final newBookmark = BookmarkModel(
        userId: userId,
        spotId: spotId,
        title: title,
        location: location,
        type: type,
        imageUrl: imageUrl,
        rating: rating ?? '4.8',
        elevation: elevation,
        coordinates: coordinates,
        createdAt: DateTime.now().toIso8601String(),
      );
      await db.insert(
        BookmarkTable.tableName,
        newBookmark.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );

      // Sinkronisasi simpan ke Cloud Firestore
      BookmarkFirestoreService.instance.saveBookmarkToCloud(newBookmark);

      return true;
    }
  }

  /// Retrieves all bookmarks for a specific user ID ordered by newest first.
  Future<List<BookmarkModel>> getUserBookmarks(int userId) async {
    final db = _getDb();
    final result = await db.query(
      BookmarkTable.tableName,
      where: '${BookmarkTable.columnUserId} = ?',
      whereArgs: [userId],
      orderBy: '${BookmarkTable.columnId} DESC',
    );
    return result.map((m) => BookmarkModel.fromMap(m)).toList();
  }

  /// Removes a bookmark record matching user ID and spot ID.
  Future<int> removeBookmark(int userId, String spotId) async {
    final db = _getDb();
    final count = await db.delete(
      BookmarkTable.tableName,
      where: '${BookmarkTable.columnUserId} = ? AND ${BookmarkTable.columnSpotId} = ?',
      whereArgs: [userId, spotId],
    );

    // Sinkronisasi hapus ke Cloud Firestore
    BookmarkFirestoreService.instance.removeBookmarkFromCloud(spotId);

    return count;
  }

  /// Directly inserts a bookmark record into SQLite.
  Future<int> addBookmark(BookmarkModel bookmark) async {
    final db = _getDb();
    return await db.insert(
      BookmarkTable.tableName,
      bookmark.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }
}
