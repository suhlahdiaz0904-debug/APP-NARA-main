import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/profile/models/expedition_log_model.dart';

/// =========================================================================
/// EXPEDITION FIRESTORE SERVICE (SINKRONISASI LOG EKSPEDISI CLOUD)
/// =========================================================================
/// Mengelola sinkronisasi 2 arah (Two-Way Sync) antara SQLite lokal dan
/// Cloud Firestore untuk riwayat penjelajahan tebing, goa, durasi & statistik.
class ExpeditionFirestoreService {
  static final ExpeditionFirestoreService instance =
      ExpeditionFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ExpeditionFirestoreService._internal();

  static const String _collectionName = 'nara_expedition_logs';

  /// Mendapatkan ID pengguna aktif atau ID fallback lokal
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return 'default_nara_explorer';
  }

  /// Koleksi log ekspedisi pengguna saat ini di Firestore
  CollectionReference<Map<String, dynamic>> get _userLogsCollection {
    return _firestore
        .collection(_collectionName)
        .doc(_currentUserId)
        .collection('logs');
  }

  // =========================================================================
  // 1. SIMPAN / UPDATE LOG EKSPEDISI KE FIRESTORE
  // =========================================================================

  /// Menyimpan satu catatan log ekspedisi ke Cloud Firestore
  Future<void> saveExpeditionLogToCloud(ExpeditionLog log) async {
    try {
      final docId = 'log_${log.spotId}_${log.date.millisecondsSinceEpoch}';

      final Map<String, dynamic> data = log.toMap();
      data['userId'] = _currentUserId;
      data['userEmail'] = _auth.currentUser?.email ?? 'petualang@nara.id';
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['createdAt'] = Timestamp.fromDate(log.date);

      await _userLogsCollection.doc(docId).set(data, SetOptions(merge: true));

      debugPrint(
        '[ExpeditionFirestoreService] Log ekspedisi "${log.spotName}" berhasil disimpan ke Cloud Firestore.',
      );
    } catch (e) {
      debugPrint('[ExpeditionFirestoreService] Gagal simpan log ke Firestore: $e');
    }
  }

  // =========================================================================
  // 2. MENGAMBIL LOG EKSPEDISI DARI FIRESTORE
  // =========================================================================

  /// Mengambil seluruh log ekspedisi pengguna dari Cloud Firestore
  Future<List<ExpeditionLog>> fetchExpeditionLogsFromCloud() async {
    try {
      final snapshot =
          await _userLogsCollection.orderBy('date', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ExpeditionLog.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('[ExpeditionFirestoreService] Gagal memuat log dari Cloud: $e');
      return [];
    }
  }

  /// Stream realtime untuk log ekspedisi dari Cloud Firestore
  Stream<List<ExpeditionLog>> streamExpeditionLogs() {
    return _userLogsCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => ExpeditionLog.fromMap(doc.data())).toList();
        });
  }

  // =========================================================================
  // 3. SINKRONISASI 2 ARAH (SQLITE LOKAL <-> CLOUD FIRESTORE)
  // =========================================================================

  /// Melakukan sinkronisasi otomatis antara SQLite lokal dan Firestore
  Future<List<ExpeditionLog>> syncLocalAndCloudLogs({int? localUserId}) async {
    try {
      // 1. Ambil data lokal SQLite
      final localLogs =
          await DatabaseHelper.instance.getUserExpeditionLogs(localUserId);

      // 2. Ambil data dari Cloud Firestore
      final cloudLogs = await fetchExpeditionLogsFromCloud();

      // 3. Upload data lokal yang belum ada di Cloud ke Firestore
      for (var localLog in localLogs) {
        final existsInCloud = cloudLogs.any((c) =>
            c.spotId == localLog.spotId &&
            c.date.difference(localLog.date).inMinutes.abs() < 5);
        if (!existsInCloud) {
          await saveExpeditionLogToCloud(localLog);
        }
      }

      // 4. Simpan data cloud yang belum ada di SQLite ke database lokal
      for (var cloudLog in cloudLogs) {
        final existsInLocal = localLogs.any((l) =>
            l.spotId == cloudLog.spotId &&
            l.date.difference(cloudLog.date).inMinutes.abs() < 5);
        if (!existsInLocal) {
          await DatabaseHelper.instance.saveExpeditionLog(cloudLog);
        }
      }

      // 5. Kembalikan data gabungan terbaru dari SQLite
      final syncedLogs =
          await DatabaseHelper.instance.getUserExpeditionLogs(localUserId);
      await DatabaseHelper.instance.syncUserStatsFromLogs(localUserId);

      debugPrint(
        '[ExpeditionFirestoreService] Sinkronisasi selesai. Total ${syncedLogs.length} log aktif.',
      );
      return syncedLogs;
    } catch (e) {
      debugPrint('[ExpeditionFirestoreService] Gagal sinkronisasi: $e');
      return await DatabaseHelper.instance.getUserExpeditionLogs(localUserId);
    }
  }

  // =========================================================================
  // 4. HAPUS LOG DARI FIRESTORE
  // =========================================================================

  /// Menghapus log ekspedisi dari Cloud Firestore
  Future<void> deleteExpeditionLogFromCloud(ExpeditionLog log) async {
    try {
      final docId = 'log_${log.spotId}_${log.date.millisecondsSinceEpoch}';
      await _userLogsCollection.doc(docId).delete();
      debugPrint('[ExpeditionFirestoreService] Log $docId berhasil dihapus dari Cloud.');
    } catch (e) {
      debugPrint('[ExpeditionFirestoreService] Gagal menghapus log dari Cloud: $e');
    }
  }
}
