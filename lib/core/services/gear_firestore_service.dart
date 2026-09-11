import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/gear/screens/gear_manager_screen.dart';

/// =========================================================================
/// GEAR FIRESTORE CLOUD SERVICE (SINKRONISASI INVENTARIS & LOG PERAWATAN)
/// =========================================================================
/// Menangani penyimpanan, pembaruan status kelayakan alat, dan riwayat log
/// perawatan ke Cloud Firestore dengan dukungan multi-user & offline cache.
class GearFirestoreService {
  static final GearFirestoreService instance = GearFirestoreService._init();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  GearFirestoreService._init();

  /// Mendapatkan ID pengguna aktif atau default fallback
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return 'default_nara_explorer';
  }

  /// Referensi Dokumen Inventaris Pengguna di Firestore
  DocumentReference<Map<String, dynamic>> get _inventoryDocRef {
    return _firestore
        .collection('nara_gear_inventories')
        .doc(_currentUserId);
  }

  /// Referensi Koleksi Log Perawatan Alat di Firestore
  CollectionReference<Map<String, dynamic>> get _maintenanceLogsRef {
    return _firestore
        .collection('nara_maintenance_logs')
        .doc(_currentUserId)
        .collection('logs');
  }

  // =========================================================================
  // 1. SINKRONISASI INVENTARIS ALAT (CATEGORIES & GEAR ITEMS)
  // =========================================================================

  /// Menyimpan seluruh data inventaris kategori & alat ke Cloud Firestore
  Future<void> saveInventory(List<GearCategory> categories) async {
    try {
      final List<Map<String, dynamic>> categoriesData = categories.map((cat) {
        return {
          'id': cat.id,
          'title': cat.title,
          'description': cat.description,
          'iconCodePoint': cat.icon.codePoint,
          'iconFontFamily': cat.icon.fontFamily,
          'items': cat.items.map((item) => item.toMap()).toList(),
        };
      }).toList();

      await _inventoryDocRef.set({
        'userId': _currentUserId,
        'userEmail': _auth.currentUser?.email ?? 'petualang@nara.id',
        'updatedAt': FieldValue.serverTimestamp(),
        'categories': categoriesData,
      }, SetOptions(merge: true));

      debugPrint('[GearFirestoreService] Berhasil menyimpan inventaris ke Cloud Firestore.');
    } catch (e) {
      debugPrint('[GearFirestoreService] Gagal menyimpan inventaris: $e');
    }
  }

  /// Mengambil data inventaris alat pengguna dari Cloud Firestore
  Future<List<Map<String, dynamic>>?> fetchInventory() async {
    try {
      final doc = await _inventoryDocRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['categories'] is List) {
          final rawList = data['categories'] as List;
          return rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        }
      }
    } catch (e) {
      debugPrint('[GearFirestoreService] Gagal mengambil inventaris dari Cloud Firestore: $e');
    }
    return null;
  }

  /// Memperbarui satu item alat tertentu ke Firestore
  Future<void> updateSingleGearItem(GearItem item, String categoryId) async {
    try {
      // Baca inventaris, modifikasi item yang cocok, lalu simpan kembali
      final doc = await _inventoryDocRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawCats = List<Map<String, dynamic>>.from(data['categories'] ?? []);
        
        bool found = false;
        for (var cat in rawCats) {
          if (cat['id'] == categoryId || cat['id'] == item.categoryId) {
            final rawItems = List<Map<String, dynamic>>.from(cat['items'] ?? []);
            final itemIndex = rawItems.indexWhere((i) => i['id'] == item.id);
            if (itemIndex != -1) {
              rawItems[itemIndex] = item.toMap();
              cat['items'] = rawItems;
              found = true;
              break;
            }
          }
        }

        if (found) {
          await _inventoryDocRef.update({
            'categories': rawCats,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('[GearFirestoreService] Gagal memperbarui gear item: $e');
    }
  }

  /// Menghapus satu item alat kustom dari Firestore
  Future<void> deleteGearItem(String itemId, String categoryId) async {
    try {
      final doc = await _inventoryDocRef.get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawCats = List<Map<String, dynamic>>.from(data['categories'] ?? []);

        for (var cat in rawCats) {
          if (cat['id'] == categoryId) {
            final rawItems = List<Map<String, dynamic>>.from(cat['items'] ?? []);
            rawItems.removeWhere((i) => i['id'] == itemId);
            cat['items'] = rawItems;
            break;
          }
        }

        await _inventoryDocRef.update({
          'categories': rawCats,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[GearFirestoreService] Gagal menghapus gear item: $e');
    }
  }

  // =========================================================================
  // 2. RIWAYAT LOG PERAWATAN ALAT (MAINTENANCE LOGS)
  // =========================================================================

  /// Mencatat riwayat log perawatan baru ke Cloud Firestore
  Future<void> recordMaintenanceLog({
    required String itemId,
    required String itemTitle,
    required String categoryId,
    required String note,
    DateTime? date,
  }) async {
    try {
      final logDate = date ?? DateTime.now();
      await _maintenanceLogsRef.add({
        'itemId': itemId,
        'itemTitle': itemTitle,
        'categoryId': categoryId,
        'note': note,
        'date': Timestamp.fromDate(logDate),
        'recordedBy': _auth.currentUser?.displayName ?? 'Petualang NARA',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[GearFirestoreService] Log perawatan $itemTitle berhasil dicatat ke Firestore.');
    } catch (e) {
      debugPrint('[GearFirestoreService] Gagal mencatat log perawatan: $e');
    }
  }

  /// Mengambil daftar riwayat log perawatan untuk alat tertentu (atau semua alat)
  Future<List<Map<String, dynamic>>> getMaintenanceLogs({String? itemId}) async {
    try {
      Query<Map<String, dynamic>> query = _maintenanceLogsRef.orderBy('date', descending: true);
      if (itemId != null && itemId.isNotEmpty) {
        query = query.where('itemId', isEqualTo: itemId);
      }

      final snapshot = await query.limit(20).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        DateTime parsedDate = DateTime.now();
        if (data['date'] is Timestamp) {
          parsedDate = (data['date'] as Timestamp).toDate();
        }

        return {
          'id': doc.id,
          'itemId': data['itemId'] ?? '',
          'itemTitle': data['itemTitle'] ?? '',
          'note': data['note'] ?? '',
          'date': parsedDate,
          'recordedBy': data['recordedBy'] ?? 'Petualang NARA',
        };
      }).toList();
    } catch (e) {
      debugPrint('[GearFirestoreService] Gagal memuat log perawatan: $e');
      return [];
    }
  }
}
