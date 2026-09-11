import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/news/models/news_model.dart';

/// =========================================================================
/// NEWS & COMMUNITY FIELD REPORTS FIRESTORE SERVICE
/// =========================================================================
/// Layanan terpusat untuk sinkronisasi Real-Time Firebase Firestore:
/// 1. Publikasi Laporan Ekspedisi & Berita Lapangan Petualang NARA
/// 2. Stream Real-Time Kabar Komunitas & Bulletin Jalur Baru
/// 3. Validasi Komunitas / Upvote Keaslian Laporan (Verified vs Hoax count)
/// 4. Sinkronisasi Dua Arah (Two-Way Sync) antara SQLite lokal & Cloud Firestore
class NewsFirestoreService {
  static final NewsFirestoreService instance =
      NewsFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  NewsFirestoreService._internal();

  static const String _collectionName = 'nara_community_news';

  /// Mendapatkan ID pengguna aktif Firebase atau ID fallback lokal
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return 'default_nara_author';
  }

  /// Koleksi berita komunitas di Cloud Firestore
  CollectionReference<Map<String, dynamic>> get _newsCollection {
    return _firestore.collection(_collectionName);
  }

  // =========================================================================
  // 1. SIMPAN & PUBLIKASIKAN BERITA / LAPORAN KE CLOUD FIRESTORE
  // =========================================================================

  /// Menyimpan satu dokumen laporan ekspedisi/berita ke Cloud Firestore
  Future<void> saveNewsPostToCloud(BeritaModel news) async {
    try {
      final docId = news.id.isNotEmpty
          ? news.id
          : 'berita_${DateTime.now().millisecondsSinceEpoch}';

      final Map<String, dynamic> data = news.toMap();
      data['firebaseUid'] = _currentUserId;
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['createdAt'] = Timestamp.fromDate(news.date);

      await _newsCollection.doc(docId).set(data, SetOptions(merge: true));

      debugPrint(
        '[NewsFirestoreService] Berita/Laporan "${news.title}" ($docId) berhasil disimpan ke Cloud Firestore.',
      );
    } catch (e) {
      debugPrint('[NewsFirestoreService] Gagal menyimpan berita ke Cloud: $e');
    }
  }

  // =========================================================================
  // 2. STREAM & FETCH BERITA REAL-TIME DARI CLOUD FIRESTORE
  // =========================================================================

  /// Mengambil semua berita publik dari Cloud Firestore
  Future<List<BeritaModel>> fetchNewsPostsFromCloud() async {
    try {
      final snapshot = await _newsCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BeritaModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('[NewsFirestoreService] Gagal fetch berita dari Cloud: $e');
      return [];
    }
  }

  /// Stream Real-Time daftar berita komunitas dari Cloud Firestore
  Stream<List<BeritaModel>> streamNewsPosts() {
    return _newsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => BeritaModel.fromMap(doc.data())).toList();
        });
  }

  // =========================================================================
  // 3. VOTING & VERIFIKASI KEASLIAN LAPORAN (COMMUNITY TRUST VOTE)
  // =========================================================================

  /// Mengirimkan suara verifikasi keaslian (Upvote/Valid vs Hoax) ke Cloud Firestore
  Future<void> voteNewsPost({
    required String newsId,
    required bool isUpvote,
  }) async {
    try {
      final docRef = _newsCollection.doc(newsId);
      await docRef.update({
        isUpvote ? 'verifiedCount' : 'hoaxCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        '[NewsFirestoreService] Vote berhasil dikirim untuk $newsId (Upvote: $isUpvote)',
      );
    } catch (e) {
      debugPrint('[NewsFirestoreService] Gagal update vote di Cloud: $e');
    }
  }

  // =========================================================================
  // 4. SINKRONISASI DUA ARAH (SQLITE LOKAL <-> CLOUD FIRESTORE)
  // =========================================================================

  /// Sinkronisasi otomatis data berita antara SQLite lokal dan Cloud Firestore
  Future<void> syncNewsPosts() async {
    try {
      // 1. Ambil data dari SQLite lokal
      final localRaw = await DatabaseHelper.instance.getAllBeritaAcara();
      final localNews = localRaw.map(BeritaModel.fromMap).toList();

      // 2. Ambil data dari Cloud Firestore
      final cloudNews = await fetchNewsPostsFromCloud();

      final localMap = {for (var n in localNews) n.id: n};
      final cloudMap = {for (var n in cloudNews) n.id: n};

      // 3. Simpan data lokal yang belum ada di Cloud ke Firestore
      for (var local in localNews) {
        if (!cloudMap.containsKey(local.id)) {
          await saveNewsPostToCloud(local);
        }
      }

      // 4. Simpan data Cloud yang belum ada di SQLite lokal ke SQLite
      for (var cloud in cloudNews) {
        if (!localMap.containsKey(cloud.id)) {
          await DatabaseHelper.instance.saveBeritaAcara(cloud.toMap());
        }
      }

      debugPrint(
        '[NewsFirestoreService] Sinkronisasi Berita selesai (Lokal: ${localNews.length}, Cloud: ${cloudNews.length})',
      );
    } catch (e) {
      debugPrint('[NewsFirestoreService] Gagal sinkronisasi berita: $e');
    }
  }
}
