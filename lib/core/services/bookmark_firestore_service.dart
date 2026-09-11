import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/map/models/bookmark_model.dart';

/// =========================================================================
/// BOOKMARK & FAVORITE SPOTS FIRESTORE SERVICE
/// =========================================================================
/// Layanan terpusat untuk sinkronisasi 2 arah (Two-Way Sync) antara SQLite lokal
/// dan Cloud Firestore (`nara_user_bookmarks`) untuk penanda spot/lokasi favorit.
class BookmarkFirestoreService {
  static final BookmarkFirestoreService instance =
      BookmarkFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BookmarkFirestoreService._internal();

  static const String _collectionName = 'nara_user_bookmarks';

  /// Mendapatkan ID pengguna aktif Firebase atau ID fallback
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return 'default_nara_user';
  }

  /// Koleksi bookmarks pengguna aktif di Firestore
  CollectionReference<Map<String, dynamic>> get _userBookmarksCollection {
    return _firestore
        .collection(_collectionName)
        .doc(_currentUserId)
        .collection('items');
  }

  // =========================================================================
  // 1. SIMPAN ATAU HAPUS BOOKMARK KE CLOUD
  // =========================================================================

  /// Menyimpan bookmark ke Firestore
  Future<void> saveBookmarkToCloud(BookmarkModel bookmark) async {
    try {
      final docId = 'bm_${bookmark.spotId}';
      final Map<String, dynamic> data = bookmark.toMap();
      data['firebaseUid'] = _currentUserId;
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _userBookmarksCollection
          .doc(docId)
          .set(data, SetOptions(merge: true));

      debugPrint(
        '[BookmarkFirestoreService] Bookmark "${bookmark.title}" berhasil disimpan ke Firestore.',
      );
    } catch (e) {
      debugPrint('[BookmarkFirestoreService] Gagal simpan bookmark ke Cloud: $e');
    }
  }

  /// Menghapus bookmark dari Firestore
  Future<void> removeBookmarkFromCloud(String spotId) async {
    try {
      final docId = 'bm_$spotId';
      await _userBookmarksCollection.doc(docId).delete();
      debugPrint(
        '[BookmarkFirestoreService] Bookmark spot $spotId berhasil dihapus dari Firestore.',
      );
    } catch (e) {
      debugPrint(
        '[BookmarkFirestoreService] Gagal menghapus bookmark dari Cloud: $e',
      );
    }
  }

  // =========================================================================
  // 2. MENGAMBIL DOKUMEN BOOKMARK DARI CLOUD
  // =========================================================================

  /// Mengambil semua bookmark dari Firestore
  Future<List<BookmarkModel>> fetchBookmarksFromCloud() async {
    try {
      final snapshot = await _userBookmarksCollection.get();
      return snapshot.docs.map((doc) {
        return BookmarkModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      debugPrint('[BookmarkFirestoreService] Gagal fetch bookmark dari Cloud: $e');
      return [];
    }
  }

  // =========================================================================
  // 3. SINKRONISASI 2 ARAH (SQLITE LOKAL <-> CLOUD FIRESTORE)
  // =========================================================================

  /// Sinkronisasi bookmark antara SQLite lokal dan Cloud Firestore
  Future<void> syncBookmarks() async {
    try {
      final activeUserId =
          await DatabaseHelper.instance.getActiveUserId() ?? 1;

      // 1. Ambil data dari lokal
      final localBookmarks = await DatabaseHelper.instance.getUserBookmarks(
        activeUserId,
      );

      // 2. Ambil data dari Cloud
      final cloudBookmarks = await fetchBookmarksFromCloud();

      // Buat peta spotId untuk perbandingan cepat
      final localMap = {for (var b in localBookmarks) b.spotId: b};
      final cloudMap = {for (var b in cloudBookmarks) b.spotId: b};

      // 3. Sinkronkan dari Lokal -> Cloud (jika belum ada di Cloud)
      for (var local in localBookmarks) {
        if (!cloudMap.containsKey(local.spotId)) {
          await saveBookmarkToCloud(local);
        }
      }

      // 4. Sinkronkan dari Cloud -> Lokal (jika belum ada di SQLite)
      for (var cloud in cloudBookmarks) {
        if (!localMap.containsKey(cloud.spotId)) {
          final toInsert = cloud.copyWith(userId: activeUserId);
          await DatabaseHelper.instance.addBookmark(toInsert);
        }
      }

      debugPrint(
        '[BookmarkFirestoreService] Sinkronisasi Bookmark selesai (Lokal: ${localBookmarks.length}, Cloud: ${cloudBookmarks.length})',
      );
    } catch (e) {
      debugPrint('[BookmarkFirestoreService] Gagal sinkronisasi bookmark: $e');
    }
  }
}
