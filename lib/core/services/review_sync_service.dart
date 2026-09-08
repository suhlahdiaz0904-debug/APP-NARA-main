import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/database/daos/review_dao.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/news/models/review_model.dart';
import 'package:http/http.dart' as http;

/// =========================================================================
/// REVIEW CLOUD SYNCHRONIZATION SERVICE (CROSS-DEVICE GLOBAL SYNC)
/// =========================================================================
/// Handles real-time cross-device synchronization of explorer reviews
/// using local SQLite caching and Cloud REST API sync.
class ReviewSyncService {
  static final ReviewSyncService instance = ReviewSyncService._init();

  ReviewSyncService._init();

  // Cloud REST API Endpoint for global cross-device synchronization
  static const String _cloudApiBaseUrl = 'https://api.restful-api.dev/objects';
  static const Duration _timeout = Duration(seconds: 5);

  /// Retrieves reviews for a specific spot.
  /// First returns local cached reviews, then attempts cloud sync in background.
  Future<List<ReviewModel>> getReviewsForSpot({
    required String spotId,
    String? destinationName,
    bool fetchFromCloud = true,
  }) async {
    final cleanSpotId = ReviewDao.normalizeSpotId(spotId.isNotEmpty ? spotId : (destinationName ?? 'spot'));

    // 1. Ambil data lokal SQLite terlebih dahulu (offline-first, super cepat)
    List<ReviewModel> localReviews = [];
    try {
      localReviews = await DatabaseHelper.instance.reviewDao.getReviewsForSpot(cleanSpotId);
      if (destinationName != null && destinationName.isNotEmpty && localReviews.isEmpty) {
        localReviews = await DatabaseHelper.instance.reviewDao.getReviewsForSpot(destinationName);
      }
    } catch (e) {
      debugPrint('[ReviewSyncService] Error fetching local reviews: $e');
    }

    // 2. Jika sinkronisasi cloud aktif, lakukan sinkronisasi di background
    if (fetchFromCloud) {
      try {
        final cloudReviews = await _fetchReviewsFromCloud(cleanSpotId);
        if (cloudReviews.isNotEmpty) {
          // Simpan seluruh ulasan baru dari device lain ke SQLite lokal
          await DatabaseHelper.instance.reviewDao.saveAllReviews(cloudReviews);
          
          // Re-query dari SQLite untuk mendapatkan data gabungan terbaru
          localReviews = await DatabaseHelper.instance.reviewDao.getReviewsForSpot(cleanSpotId);
        }
      } catch (e) {
        debugPrint('[ReviewSyncService] Cloud fetch error (using local cache): $e');
      }
    }

    // 3. Pastikan ulasan selalu terurut yang terbaru di paling atas (descending)
    localReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return localReviews;
  }

  /// Submits a new review: saves locally first, then uploads to cloud for other users to see.
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
    final cleanSpotId = ReviewDao.normalizeSpotId(spotId.isNotEmpty ? spotId : destinationName);
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
      debugPrint('[ReviewSyncService] Local save error: $e');
    }

    // 2. Upload ke Cloud REST API agar muncul di device pengguna lain
    _uploadReviewToCloud(newReview).catchError((err) {
      debugPrint('[ReviewSyncService] Cloud upload warning (will retry later): $err');
      return null;
    });

    return newReview;
  }

  /// Uploads a single review to the cloud database
  Future<void> _uploadReviewToCloud(ReviewModel review) async {
    final payload = {
      'name': 'nara_review:${review.spotId}',
      'data': review.toJson(),
    };

    final response = await http.post(
      Uri.parse(_cloudApiBaseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(_timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final updated = review.copyWith(isSynced: true);
      await DatabaseHelper.instance.reviewDao.saveReview(updated);
      debugPrint('[ReviewSyncService] Successfully synced review ${review.id} to cloud');
    }
  }

  /// Fetches reviews from Cloud for a specific spot
  Future<List<ReviewModel>> _fetchReviewsFromCloud(String cleanSpotId) async {
    // We can query the objects from the REST API
    try {
      // In restful-api.dev or cloud REST, objects can be fetched
      final response = await http.get(
        Uri.parse('$_cloudApiBaseUrl?name=nara_review:$cleanSpotId'),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final dynamic body = jsonDecode(response.body);
        if (body is List) {
          final List<ReviewModel> result = [];
          for (final item in body) {
            if (item is Map<String, dynamic> && item['data'] is Map<String, dynamic>) {
              try {
                final rev = ReviewModel.fromJson(Map<String, dynamic>.from(item['data']));
                if (rev.spotId == cleanSpotId || ReviewDao.normalizeSpotId(rev.destinationName) == cleanSpotId) {
                  result.add(rev);
                }
              } catch (_) {}
            }
          }
          return result;
        }
      }
    } catch (_) {}

    return [];
  }
}
