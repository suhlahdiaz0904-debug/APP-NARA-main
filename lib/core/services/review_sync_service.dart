import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/database/daos/review_dao.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/news/models/review_model.dart';

/// =========================================================================
/// SPOT REVIEWS FIRESTORE SERVICE (CROSS-DEVICE CLOUD SYNC)
/// =========================================================================
/// Layanan terpusat untuk sinkronisasi Real-Time Firebase Firestore:
/// 1. Ulasan, Rating Bintang, dan Dokumentasi Spot Tebing & Goa
/// 2. Offline-First Architecture (SQLite Local Cache + Cloud Firestore Two-Way Sync)
/// 3. Real-Time Stream Ulasan Pengguna Antar Perangkat
class ReviewSyncService {
  static final ReviewSyncService instance = ReviewSyncService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ReviewSyncService._init();

  static const String _collectionName = 'nara_spot_reviews';

  /// Mendapatkan ID pengguna aktif Firebase atau ID fallback
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return 'default_nara_reviewer';
  }

  /// Koleksi ulasan spot di Cloud Firestore
  CollectionReference<Map<String, dynamic>> get _reviewsCollection {
    return _firestore.collection(_collectionName);
  }

  // =========================================================================
  // 1. MENGAMBIL ULASAN SPOT (SQLITE + FIRESTORE SYNC)
  // =========================================================================

  /// Mengambil ulasan untuk suatu spot tebing/goa.
  /// Menampilkan cache lokal SQLite secara instan, lalu menyinkronkan data dari Cloud Firestore.
  Future<List<ReviewModel>> getReviewsForSpot({
    required String spotId,
    String? destinationName,
    bool fetchFromCloud = true,
  }) async {
    final cleanSpotId = ReviewDao.normalizeSpotId(
      spotId.isNotEmpty ? spotId : (destinationName ?? 'spot'),
    );

    // 1. Ambil data lokal SQLite terlebih dahulu (offline-first)
    List<ReviewModel> localReviews = [];
    try {
      localReviews = await DatabaseHelper.instance.reviewDao.getReviewsForSpot(
        cleanSpotId,
      );
      if (destinationName != null &&
          destinationName.isNotEmpty &&
          localReviews.isEmpty) {
        localReviews = await DatabaseHelper.instance.reviewDao.getReviewsForSpot(
          destinationName,
        );
      }
    } catch (e) {
      debugPrint('[ReviewSyncService] Error fetching local reviews: $e');
    }

    // 2. Jika sinkronisasi cloud aktif, lakukan query ke Cloud Firestore
    if (fetchFromCloud) {
      try {
        final cloudReviews = await _fetchReviewsFromCloud(cleanSpotId);
        if (cloudReviews.isNotEmpty) {
          // Simpan seluruh ulasan baru dari Firestore ke SQLite lokal
          await DatabaseHelper.instance.reviewDao.saveAllReviews(cloudReviews);

          // Ambil kembali data gabungan terbaru dari SQLite
          localReviews = await DatabaseHelper.instance.reviewDao.getReviewsForSpot(
            cleanSpotId,
          );
        }
      } catch (e) {
        debugPrint('[ReviewSyncService] Cloud Firestore fetch error (using local cache): $e');
      }
    }

    // 3. Pastikan ulasan selalu terurut descending (terbaru di atas)
    localReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return localReviews;
  }

  /// Stream Real-Time untuk ulasan spot tertentu dari Cloud Firestore
  Stream<List<ReviewModel>> streamReviewsForSpot(String spotId) {
    final cleanSpotId = ReviewDao.normalizeSpotId(spotId);
    return _reviewsCollection
        .where('spotId', isEqualTo: cleanSpotId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            final data = doc.data();
            return ReviewModel.fromJson(data);
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // =========================================================================
  // 2. MENULIS & MENGIRIM ULASAN BARU (SUBMIT REVIEW)
  // =========================================================================

  /// Menyimpan ulasan baru: Simpan ke SQLite lokal dahulu, kemudian kirim ke Cloud Firestore.
  Future<ReviewModel> submitReview({
    required String spotId,
    required String destinationName,
    required String userName,
    String? userRole,
    String? userAvatar,
    required double rating,
    required String comment,
    List<String> photos = const [],
  }) async {
    final cleanSpotId = ReviewDao.normalizeSpotId(
      spotId.isNotEmpty ? spotId : destinationName,
    );
    final now = DateTime.now();
    final reviewId = 'rev_${cleanSpotId}_${now.millisecondsSinceEpoch}';

    final newReview = ReviewModel(
      id: reviewId,
      spotId: cleanSpotId,
      destinationName: destinationName,
      userName: userName.isNotEmpty ? userName : 'Penjelajah NARA',
      userRole: userRole ?? 'Penjelajah',
      userAvatar: userAvatar,
      rating: rating,
      comment: comment,
      createdAt: now,
      photos: photos,
      likes: 0,
      isSynced: false,
    );

    // 1. Simpan langsung ke database lokal SQLite
    try {
      await DatabaseHelper.instance.reviewDao.saveReview(newReview);
    } catch (e) {
      debugPrint('[ReviewSyncService] Local SQLite save error: $e');
    }

    // 2. Upload ke Cloud Firestore agar langsung terbaca di device pengguna lain
    _uploadReviewToCloud(newReview).catchError((err) {
      debugPrint('[ReviewSyncService] Cloud upload warning (will retry later): $err');
      return null;
    });

    return newReview;
  }

  /// Mengunggah dokumen ulasan ke Cloud Firestore
  Future<void> _uploadReviewToCloud(ReviewModel review) async {
    try {
      final docId = review.id;
      final Map<String, dynamic> data = review.toJson();
      data['firebaseUid'] = _currentUserId;
      data['createdAt'] = Timestamp.fromDate(review.createdAt);
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _reviewsCollection.doc(docId).set(data, SetOptions(merge: true));

      final updated = review.copyWith(isSynced: true);
      await DatabaseHelper.instance.reviewDao.saveReview(updated);
      debugPrint(
        '[ReviewSyncService] Ulasan ${review.id} berhasil disinkronkan ke Cloud Firestore.',
      );
    } catch (e) {
      debugPrint('[ReviewSyncService] Gagal simpan ulasan ke Firestore: $e');
    }
  }

  /// Mengambil dokumen ulasan dari Cloud Firestore berdasarkan spotId
  Future<List<ReviewModel>> _fetchReviewsFromCloud(String cleanSpotId) async {
    try {
      final snapshot = await _reviewsCollection
          .where('spotId', isEqualTo: cleanSpotId)
          .get();

      final List<ReviewModel> result = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          result.add(ReviewModel.fromJson(data));
        } catch (_) {}
      }
      return result;
    } catch (e) {
      debugPrint('[ReviewSyncService] Gagal fetch review dari Firestore: $e');
      return [];
    }
  }

  // =========================================================================
  // 3. LIKE & SINKRONISASI DUA ARAH
  // =========================================================================

  /// Mengirim like/apresiasi ulasan ke Cloud Firestore
  Future<void> likeReview(String reviewId) async {
    try {
      await _reviewsCollection.doc(reviewId).update({
        'likes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ReviewSyncService] Gagal like ulasan di Firestore: $e');
    }
  }
}
