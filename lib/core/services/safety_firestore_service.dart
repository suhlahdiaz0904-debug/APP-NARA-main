import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';

/// =========================================================================
/// SAFETY & SOS FIRESTORE SERVICE
/// =========================================================================
/// Layanan terpusat untuk sinkronisasi Real-Time Firebase Firestore:
/// 1. Broadcast lokasi & status penjelajah (Live Trackers / Mesh Peers)
/// 2. Siaran Darurat SOS Real-Time (SOS Broadcasts & Response Acknowledgments)
/// 3. Sinkronisasi Telemetri Lapangan (Koordinat, Ketinggian, Baterai, Satelit)
class SafetyFirestoreService {
  static final SafetyFirestoreService instance =
      SafetyFirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SafetyFirestoreService._internal();

  /// Koleksi Dokumen Firestore
  static const String _collectionTrackers = 'nara_safety_trackers';
  static const String _collectionSosAlerts = 'nara_sos_alerts';

  /// Mendapatkan ID pengguna aktif atau ID anonim unik lokal
  String get currentUserId {
    final user = _auth.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return 'nara_user_local';
  }

  /// Mendapatkan nama pengguna aktif saat ini
  Future<String> getCurrentUserName() async {
    final user = _auth.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    try {
      final localUser = await DatabaseHelper.instance.getLatestUser();
      if (localUser != null && localUser.nama.trim().isNotEmpty) {
        return localUser.nama.trim();
      }
    } catch (_) {}
    return 'Petualang NARA';
  }

  // =========================================================================
  // 1. BROADCAST TELEMETRI & LOKASI REALTIME (LIVE TRACKER)
  // =========================================================================

  /// Memperbarui atau mem-broadcast lokasi real-time pengguna saat ini ke Firestore
  Future<void> broadcastUserLocation({
    required double latitude,
    required double longitude,
    required String altitude,
    String status = 'normal', // 'normal' | 'sos'
    int battery = 85,
  }) async {
    try {
      final uid = currentUserId;
      final userName = await getCurrentUserName();
      final userPhoto = _auth.currentUser?.photoURL;

      await _firestore.collection(_collectionTrackers).doc(uid).set({
        'userId': uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'status': status,
        'battery': battery,
        'lastActive': FieldValue.serverTimestamp(),
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint(
        '[SafetyFirestoreService] Broadcast lokasi $userName ($latitude, $longitude) berhasil.',
      );
    } catch (e) {
      debugPrint('[SafetyFirestoreService] Gagal broadcast lokasi: $e');
    }
  }

  /// Stream daftar semua penjelajah yang aktif di Firestore
  Stream<List<Map<String, dynamic>>> getLiveTrackersStream() {
    return _firestore
        .collection(_collectionTrackers)
        .snapshots()
        .map((snapshot) {
          final List<Map<String, dynamic>> results = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            // Abaikan device sendiri dalam daftar teman di sekitar jika diperlukan
            results.add({
              'id': doc.id,
              'userId': data['userId'] ?? doc.id,
              'userName': data['userName'] ?? 'Petualang',
              'userPhoto': data['userPhoto'],
              'latitude': (data['latitude'] as num?)?.toDouble() ?? 0.0,
              'longitude': (data['longitude'] as num?)?.toDouble() ?? 0.0,
              'altitude': data['altitude'] ?? '450 m ASL',
              'status': data['status'] ?? 'normal',
              'battery': (data['battery'] as num?)?.toInt() ?? 80,
              'lastActive': data['lastActive'],
            });
          }
          return results;
        });
  }

  // =========================================================================
  // 2. DARURAT SOS REALTIME (BROADCAST & RESCUE COORDINATION)
  // =========================================================================

  /// Menerbitkan sinyal darurat SOS baru ke Firestore
  /// Mengembalikan `alertId` dokumen Firestore
  Future<String> publishSosAlert({
    required double latitude,
    required double longitude,
    required String altitude,
    String? note,
    int? battery,
  }) async {
    try {
      final uid = currentUserId;
      final userName = await getCurrentUserName();
      final userPhoto = _auth.currentUser?.photoURL;

      final docRef = await _firestore.collection(_collectionSosAlerts).add({
        'userId': uid,
        'userName': userName,
        'userPhoto': userPhoto,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'status': 'active', // 'active' | 'cancelled' | 'resolved'
        'note': note ?? 'Sinyal darurat SOS dipicu oleh petualang.',
        'battery': battery ?? 85,
        'responders': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update status penjelajah di Live Tracker menjadi 'sos'
      await broadcastUserLocation(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        status: 'sos',
        battery: battery ?? 85,
      );

      debugPrint(
        '[SafetyFirestoreService] Sinyal SOS ID: ${docRef.id} berhasil dipublikasikan ke Firestore!',
      );
      return docRef.id;
    } catch (e) {
      debugPrint('[SafetyFirestoreService] Gagal mempublikasikan SOS: $e');
      return '';
    }
  }

  /// Memperbarui lokasi GPS real-time saat SOS sedang berlangsung
  Future<void> updateSosLocation(
    String alertId, {
    required double latitude,
    required double longitude,
    required String altitude,
  }) async {
    if (alertId.isEmpty) return;
    try {
      await _firestore.collection(_collectionSosAlerts).doc(alertId).update({
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[SafetyFirestoreService] Gagal update lokasi SOS: $e');
    }
  }

  /// Membatalkan sinyal darurat SOS pengguna (User menahan tombol Batal)
  Future<void> cancelSosAlert(
    String alertId, {
    double? latitude,
    double? longitude,
    String? altitude,
  }) async {
    try {
      if (alertId.isNotEmpty) {
        await _firestore.collection(_collectionSosAlerts).doc(alertId).update({
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Kembalikan status di Live Tracker menjadi normal
      if (latitude != null && longitude != null) {
        await broadcastUserLocation(
          latitude: latitude,
          longitude: longitude,
          altitude: altitude ?? '450 m ASL',
          status: 'normal',
        );
      }

      debugPrint(
        '[SafetyFirestoreService] Sinyal SOS ID: $alertId berhasil dibatalkan.',
      );
    } catch (e) {
      debugPrint('[SafetyFirestoreService] Gagal membatalkan SOS: $e');
    }
  }

  /// Stream daftar SOS aktif di sekitar yang sedang memerlukan pertolongan
  Stream<List<Map<String, dynamic>>> getActiveSosAlertsStream() {
    return _firestore
        .collection(_collectionSosAlerts)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final List<Map<String, dynamic>> results = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            results.add({
              'id': doc.id,
              'userId': data['userId'] ?? '',
              'userName': data['userName'] ?? 'Petualang NARA',
              'userPhoto': data['userPhoto'],
              'latitude': (data['latitude'] as num?)?.toDouble() ?? 0.0,
              'longitude': (data['longitude'] as num?)?.toDouble() ?? 0.0,
              'altitude': data['altitude'] ?? '450 m ASL',
              'status': data['status'] ?? 'active',
              'note': data['note'] ?? '',
              'battery': data['battery'],
              'responders':
                  (data['responders'] as List?)
                      ?.map((r) => Map<String, dynamic>.from(r as Map))
                      .toList() ??
                  [],
              'createdAt': data['createdAt'],
            });
          }
          return results;
        });
  }

  /// Mengirim ping respon / konfirmasi pertolongan dari rekan tim ke korban SOS
  Future<void> sendSosResponsePing({
    required String alertId,
    required double responderLat,
    required double responderLng,
  }) async {
    try {
      final responderName = await getCurrentUserName();
      final uid = currentUserId;

      final docRef = _firestore.collection(_collectionSosAlerts).doc(alertId);
      await docRef.update({
        'responders': FieldValue.arrayUnion([
          {
            'userId': uid,
            'name': responderName,
            'lat': responderLat,
            'lng': responderLng,
            'timestamp': DateTime.now().toIso8601String(),
          },
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '[SafetyFirestoreService] Ping respon dari $responderName berhasil dikirim ke SOS $alertId.',
      );
    } catch (e) {
      debugPrint('[SafetyFirestoreService] Gagal mengirim ping respon: $e');
    }
  }
}
