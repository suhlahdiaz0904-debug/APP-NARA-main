import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// =========================================================================
/// FIREBASE DATABASE INITIAL SEEDER
/// =========================================================================
/// Mengisi seluruh koleksi Cloud Firestore NARA dengan data awal (Initial Data)
/// secara otomatis agar koleksi langsung tampil di Firebase Console saat dibuka:
/// 1. `nara_user_profiles` (Profil Penjelajah)
/// 2. `nara_community_news` (Kabar Komunitas & Laporan Lapangan)
/// 3. `nara_spot_reviews` (Ulasan & Rating Bintang Spot)
/// 4. `nara_safety_trackers` (Radar Beacon Teman Luring & GPS)
/// 5. `nara_gear_inventories` (Inventaris Peralatan Panjat & Goa)
/// 6. `nara_expedition_logs` (Riwayat Ekspedisi & Log Jalur)
/// 7. `nara_user_bookmarks` (Daftar Spot Favorit)
class FirebaseDatabaseSeeder {
  static final FirebaseDatabaseSeeder instance = FirebaseDatabaseSeeder._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseDatabaseSeeder._internal();

  /// Menjalankan inisialisasi & penanaman data awal ke Cloud Firestore
  Future<void> seedInitialDataToFirestore({bool force = false}) async {
    try {
      debugPrint('[FirebaseDatabaseSeeder] Memulai penanaman data awal ke Cloud Firestore...');

      await Future.wait([
        _seedUserProfile(force),
        _seedCommunityNews(force),
        _seedSpotReviews(force),
        _seedSafetyTrackers(force),
        _seedGearInventory(force),
        _seedExpeditionLogs(force),
        _seedUserBookmarks(force),
      ]);

      debugPrint('[FirebaseDatabaseSeeder] Seluruh data awal berhasil dimasukkan ke Firebase Firestore!');
    } catch (e) {
      debugPrint('[FirebaseDatabaseSeeder] Gagal seeding data ke Firestore: $e');
    }
  }

  // 1. Seed Profil Pengguna
  Future<void> _seedUserProfile(bool force) async {
    try {
      final docRef = _firestore.collection('nara_user_profiles').doc('farhiyah_outdoor@nara_id');
      final doc = await docRef.get();
      if (!doc.exists || force) {
        await docRef.set({
          'id': 1,
          'nama': 'Farhiyah Petualang',
          'email': 'farhiyah.outdoor@nara.id',
          'noHp': '+62 812-3456-7890',
          'asalKota': 'Bandung Barat',
          'rolePetualang': 'Senior Caver & Speleologi',
          'bio': 'Penjelajah goa vertikal karst Citatah & pemanjat tebing tegar bersama NARA Outdoor.',
          'golonganDarah': 'O+',
          'kontakDaruratNama': 'Basecamp Citatah',
          'kontakDaruratHp': '+62 812-9876-5432',
          'organisasi': 'NARA Speleo Club',
          'fotoProfil': 'https://images.unsplash.com/photo-1522163182402-834f871fd851?auto=format&fit=crop&w=400&q=80',
          'totalEkspedisi': 14,
          'jarakJelajah': '84 km',
          'jamTerbang': '120 Jam',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  // 2. Seed Kabar Komunitas & Berita
  Future<void> _seedCommunityNews(bool force) async {
    try {
      final newsCollection = _firestore.collection('nara_community_news');

      final news1 = {
        'id': 'citatah_ekspedisi_1',
        'title': '4 Pemuda-Pemudi Taklukkan Tebing Citatah: Sinergi Tim di Ketinggian',
        'location': 'Padalarang, Bandung Barat',
        'coordinates': '6°50\'25.8"S 107°27\'06.5"E',
        'category': 'EKSPEDISI',
        'categories': '["Tebing", "Jalur Baru"]',
        'timeAgo': '1 jam yang lalu',
        'date': '2026-02-24T07:00:00.000Z',
        'formattedDate': '24/02/2026',
        'description': 'Ekspedisi pemanjatan tebing Citatah 125, Padalarang, Jawa Barat telah sukses dilaksanakan oleh tim beranggotakan 4 orang. Cuaca cerah dan mendukung sepanjang kegiatan berlangsung, memungkinkan tim untuk fokus pada aspek teknis pemanjatan.',
        'photos': '["assets/images/fotober4.jpeg", "assets/images/fotocitatah1.jpeg", "assets/images/fotocitatah2.jpeg"]',
        'headerImage': 'assets/images/fotober4.jpeg',
        'rockType': 'Andesit Karst',
        'grade': 'Grade 5.9',
        'rating': '5.0',
        'author': 'Farhiyah Petualang',
        'duration': '2 Hari 1 Malam',
        'team': '4 Orang',
        'elevation': '125 mdpl',
        'technique': 'Single Rope Technique (SRT), Lead Climbing',
        'mainRope': 'Dynamic Rope 10mm (60m)',
        'isDraft': 0,
        'status': 'VALID',
        'verifiedCount': 18,
        'hoaxCount': 0,
        'createdAt': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final news2 = {
        'id': 'citatah_jalur_2',
        'title': 'Tebing Citatah 125: Jalur Utama dan Sektor Pemanjatan Dibuka Kembali',
        'location': 'Padalarang, Bandung Barat',
        'coordinates': '6°50\'25.8"S 107°27\'06.5"E',
        'category': 'KONDISI JALUR',
        'categories': '["Tebing"]',
        'timeAgo': '3 jam yang lalu',
        'date': '2026-02-23T09:00:00.000Z',
        'formattedDate': '23/02/2026',
        'description': 'Pengelola kawasan dan tim SAR gabungan memastikan seluruh anchor dan hanger pada jalur pemanjatan Tebing Citatah 125 aman untuk digunakan kembali.',
        'photos': '["assets/images/citatah.jpg", "assets/images/fotocitatah1.jpeg"]',
        'headerImage': 'assets/images/citatah.jpg',
        'rockType': 'Andesit & Limestone',
        'grade': 'Grade 5.9 - 5.11',
        'rating': '4.8',
        'author': 'Pengelola Citatah',
        'duration': '1 Hari',
        'team': 'Tim SAR & Pengelola',
        'elevation': '125 mdpl',
        'isDraft': 0,
        'status': 'VALID',
        'verifiedCount': 24,
        'hoaxCount': 0,
        'createdAt': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await newsCollection.doc(news1['id'] as String).set(news1, SetOptions(merge: true));
      await newsCollection.doc(news2['id'] as String).set(news2, SetOptions(merge: true));
    } catch (_) {}
  }

  // 3. Seed Ulasan & Rating Spot
  Future<void> _seedSpotReviews(bool force) async {
    try {
      final reviewsCollection = _firestore.collection('nara_spot_reviews');

      final reviews = [
        {
          'id': 'rev_tebing_citatah_125_1',
          'spotId': 'tebing_citatah_125',
          'destinationName': 'Tebing Citatah 125',
          'userName': 'Farhiyah Petualang',
          'userRole': 'Senior Caver & Speleologi',
          'userAvatar': 'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=200',
          'rating': 5.0,
          'comment': 'Jalurnya sangat menantang dan view dari atas luar biasa! Pastikan bawa kapur yang cukup dan cek anchor sebelum lead climbing.',
          'photos': ['assets/images/fotocitatah1.jpeg'],
          'likes': 8,
          'createdAt': Timestamp.now(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'rev_tebing_citatah_125_2',
          'spotId': 'tebing_citatah_125',
          'destinationName': 'Tebing Citatah 125',
          'userName': 'Alex Rivers',
          'userRole': 'Mountain Guide',
          'userAvatar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          'rating': 4.8,
          'comment': 'Basecamp sangat ramah dan informasinya akurat. Cocok untuk latihan teknik SRT dan pemanjatan akhir pekan.',
          'photos': ['assets/images/fotober4.jpeg'],
          'likes': 5,
          'createdAt': Timestamp.now(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      for (var r in reviews) {
        await reviewsCollection.doc(r['id'] as String).set(r, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  // 4. Seed Live Mesh Safety Trackers
  Future<void> _seedSafetyTrackers(bool force) async {
    try {
      final trackersCollection = _firestore.collection('nara_safety_trackers');

      final peers = [
        {
          'userId': 'peer_budi_01',
          'userName': 'Budi Santoso',
          'latitude': -6.8378,
          'longitude': 107.4502,
          'altitude': '480 m ASL',
          'status': 'normal',
          'battery': 88,
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'userId': 'peer_ayu_02',
          'userName': 'Ayu Lestari',
          'latitude': -6.8412,
          'longitude': 107.4545,
          'altitude': '435 m ASL',
          'status': 'normal',
          'battery': 74,
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      for (var p in peers) {
        await trackersCollection.doc(p['userId'] as String).set(p, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  // 5. Seed Inventaris Alat
  Future<void> _seedGearInventory(bool force) async {
    try {
      final inventoryRef = _firestore.collection('nara_gear_inventories').doc('default_nara_explorer');
      await inventoryRef.set({
        'userId': 'default_nara_explorer',
        'updatedAt': FieldValue.serverTimestamp(),
        'categories': [
          {
            'id': 'cat_rope',
            'title': 'Tali & Webbing',
            'description': 'Dynamic & Static Climbing Ropes',
            'iconCodePoint': 58732,
            'items': [
              {
                'id': 'gear_rope_01',
                'name': 'Beal Joker 9.1mm Golden Dry (60m)',
                'brand': 'Beal',
                'status': 'Layak Pakai',
                'usageCount': 8,
                'maxUsage': 50,
              },
            ],
          },
        ],
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // 6. Seed Log Ekspedisi
  Future<void> _seedExpeditionLogs(bool force) async {
    try {
      final logsCollection = _firestore
          .collection('nara_expedition_logs')
          .doc('default_nara_explorer')
          .collection('logs');

      final log1 = {
        'id': 1,
        'spotId': 'tebing_citatah_125',
        'spotName': 'Tebing Citatah 125',
        'location': 'Padalarang, Bandung Barat',
        'date': '2026-02-24T08:00:00.000Z',
        'durationMinutes': 180,
        'distanceKm': 3.5,
        'elevationGainM': 125,
        'activityType': 'Climbing',
        'notes': 'Pemanjatan rute jalur andesit sisi barat.',
        'createdAt': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await logsCollection.doc('log_citatah_1').set(log1, SetOptions(merge: true));
    } catch (_) {}
  }

  // 7. Seed Bookmarks
  Future<void> _seedUserBookmarks(bool force) async {
    try {
      final bookmarksCollection = _firestore
          .collection('nara_user_bookmarks')
          .doc('default_nara_explorer')
          .collection('items');

      final bm1 = {
        'id': 1,
        'spotId': 'tebing_citatah_125',
        'title': 'Tebing Citatah 125',
        'location': 'Padalarang, Bandung Barat',
        'type': 'Tebing Karst',
        'imageUrl': 'assets/images/citatah.jpg',
        'rating': '4.8',
        'elevation': '125 mdpl',
        'coordinates': '-6.84050, 107.45180',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await bookmarksCollection.doc('bm_tebing_citatah_125').set(bm1, SetOptions(merge: true));
    } catch (_) {}
  }
}
