import 'dart:convert';

import 'package:flutter_application_1/core/database/database_helper.dart';

class BeritaModel {
  final String id;
  final String title;
  final String location;
  final String coordinates;
  final String category;
  final List<String> categories;
  final String timeAgo;
  final DateTime date;
  final String formattedDate;

  static String formatTimeAgo(DateTime uploadedAt) {
    final now = DateTime.now();
    final diff = now.difference(uploadedAt);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} hari yang lalu';
    }
    return '${(diff.inDays / 7).floor()} minggu yang lalu';
  }

  final String description;
  final List<String> photos;
  final String headerImage;
  final String rockType;
  final String grade;
  final String rating;
  final String author;
  final String duration;
  final String team;
  final String elevation;
  final String technique;
  final String mainRope;
  final bool isDraft;
  final int? userId;
  final String status;
  final int verifiedCount;
  final int hoaxCount;

  BeritaModel({
    required this.id,
    required this.title,
    required this.location,
    this.coordinates = '6°50\'25.8"S 107°27\'06.5"E',
    required this.category,
    this.categories = const [],
    String? timeAgo,
    required this.date,
    String? formattedDate,
    required this.description,
    this.photos = const [],
    String? headerImage,
    this.rockType = 'Andesit Karst',
    this.grade = 'Grade 5.9',
    this.rating = '4.8',
    this.author = 'Farhiyah',
    this.duration = '1 Hari',
    this.team = '1 Tim',
    this.elevation = '125 mdpl',
    this.technique = 'Single Rope Technique (SRT), Lead Climbing',
    this.mainRope = 'Dynamic Rope 10mm (60m)',
    this.isDraft = false,
    this.userId,
    this.status = 'VALID',
    this.verifiedCount = 0,
    this.hoaxCount = 0,
  }) : timeAgo = timeAgo ?? formatTimeAgo(date),
       formattedDate =
           formattedDate ??
           '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
       headerImage =
           headerImage ??
           (photos.isNotEmpty ? photos.first : 'assets/images/citatah.jpg');

  factory BeritaModel.fromMap(Map<String, dynamic> map) {
    return BeritaModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Judul belum tersedia',
      location: map['location']?.toString() ?? 'Lokasi belum tersedia',
      coordinates:
          map['coordinates']?.toString() ?? '6°50\'25.8"S 107°27\'06.5"E',
      category: map['category']?.toString() ?? 'EKSPEDISI',
      categories: List<String>.from(
        (jsonDecode(map['categories']?.toString() ?? '[]') as List?) ??
            const [],
      ),
      timeAgo:
          map['timeAgo']?.toString() ??
          formatTimeAgo(
            DateTime.parse(
              map['date']?.toString() ?? DateTime.now().toIso8601String(),
            ),
          ),
      date: DateTime.parse(
        map['date']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      formattedDate: map['formattedDate']?.toString(),
      description: map['description']?.toString() ?? '',
      photos: List<String>.from(
        (jsonDecode(map['photos']?.toString() ?? '[]') as List?) ?? const [],
      ),
      headerImage: map['headerImage']?.toString(),
      rockType: map['rockType']?.toString() ?? 'Andesit Karst',
      grade: map['grade']?.toString() ?? 'Grade 5.9',
      rating: map['rating']?.toString() ?? '4.8',
      author: map['author']?.toString() ?? 'Farhiyah',
      duration: map['duration']?.toString() ?? '1 Hari',
      team: map['team']?.toString() ?? '1 Tim',
      elevation: map['elevation']?.toString() ?? '125 mdpl',
      technique: map['technique']?.toString() ?? 'Single Rope Technique (SRT)',
      mainRope: map['mainRope']?.toString() ?? 'Dynamic Rope 10mm (60m)',
      isDraft: map['isDraft'] == 1 || map['isDraft'] == true,
      userId: map['userId'] is int ? map['userId'] as int : null,
      status: map['status']?.toString() ?? 'VALID',
      verifiedCount: map['verifiedCount'] is int ? map['verifiedCount'] as int : 0,
      hoaxCount: map['hoaxCount'] is int ? map['hoaxCount'] as int : 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'coordinates': coordinates,
      'category': category,
      'categories': jsonEncode(categories),
      'timeAgo': timeAgo,
      'date': date.toIso8601String(),
      'formattedDate': formattedDate,
      'description': description,
      'photos': jsonEncode(photos),
      'headerImage': headerImage,
      'rockType': rockType,
      'grade': grade,
      'rating': rating,
      'author': author,
      'duration': duration,
      'team': team,
      'elevation': elevation,
      'technique': technique,
      'mainRope': mainRope,
      'isDraft': isDraft ? 1 : 0,
      'userId': userId,
      'status': status,
      'verifiedCount': verifiedCount,
      'hoaxCount': hoaxCount,
    };
  }

  BeritaModel copyWith({
    String? id,
    String? title,
    String? location,
    String? coordinates,
    String? category,
    List<String>? categories,
    String? timeAgo,
    DateTime? date,
    String? formattedDate,
    String? description,
    List<String>? photos,
    String? headerImage,
    String? rockType,
    String? grade,
    String? rating,
    String? author,
    String? duration,
    String? team,
    String? elevation,
    String? technique,
    String? mainRope,
    bool? isDraft,
    int? userId,
    String? status,
    int? verifiedCount,
    int? hoaxCount,
  }) {
    return BeritaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      category: category ?? this.category,
      categories: categories ?? this.categories,
      timeAgo: timeAgo ?? this.timeAgo,
      date: date ?? this.date,
      formattedDate: formattedDate ?? this.formattedDate,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      headerImage: headerImage ?? this.headerImage,
      rockType: rockType ?? this.rockType,
      grade: grade ?? this.grade,
      rating: rating ?? this.rating,
      author: author ?? this.author,
      duration: duration ?? this.duration,
      team: team ?? this.team,
      elevation: elevation ?? this.elevation,
      technique: technique ?? this.technique,
      mainRope: mainRope ?? this.mainRope,
      isDraft: isDraft ?? this.isDraft,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      hoaxCount: hoaxCount ?? this.hoaxCount,
    );
  }
}

class BeritaManager {
  static final List<BeritaModel> _beritaList = [
    BeritaModel(
      id: 'citatah_ekspedisi_1',
      title:
          '4 Pemuda-Pemudi Taklukkan Tebing Citatah: Sinergi Tim di Ketinggian',
      location: 'Padalarang, Bandung Barat',
      coordinates: '6°50\'25.8"S 107°27\'06.5"E',
      category: 'EKSPEDISI SUKSES',
      categories: ['Tebing', 'Jalur Baru'],
      timeAgo: '1 jam yang lalu',
      date: DateTime(2026, 2, 24),
      formattedDate: '24 Feb 2026',
      description:
          'Ekspedisi pemanjatan tebing Citatah 125, Padalarang, Jawa Barat telah sukses dilaksanakan oleh tim beranggotakan 4 orang. Cuaca cerah dan mendukung sepanjang kegiatan berlangsung, memungkinkan tim untuk fokus pada aspek teknis pemanjatan.\n\n'
          'Tebing Citatah, yang mayoritas tersusun dari batuan Andesit yang keras dan solid, memberikan tantangan tersendiri. Karakteristik batuan ini menuntut penempatan alat pengaman (anchor) yang presisi dan kehati-hatian ekstra saat memilih pijakan maupun pegangan. Tim memulai pemanjatan pada pukul 07.00 WIB untuk menghindari terik matahari siang.',
      photos: [
        'assets/images/fotober4.jpeg',
        'assets/images/fotocitatah1.jpeg',
        'assets/images/fotocitatah2.jpeg',
      ],
      headerImage: 'assets/images/fotober4.jpeg',
      rockType: 'Andesit',
      grade: 'Grade 5.9',
      rating: '4.8',
      author: 'Farhiyah',
      duration: '2 Hari 1 Malam',
      team: '4 Orang',
      elevation: '125 mdpl',
      technique: 'Single Rope Technique (SRT), Lead Climbing',
      mainRope: 'Dynamic Rope 10mm (60m)',
    ),
    BeritaModel(
      id: 'citatah_jalur_2',
      title:
          'Tebing Citatah 125: Jalur Utama dan Sektor Pemanjatan Dibuka Kembali',
      location: 'Padalarang, Bandung Barat',
      coordinates: '6°50\'25.8"S 107°27\'06.5"E',
      category: 'KONDISI JALUR',
      categories: ['Tebing'],
      timeAgo: '2 jam yang lalu',
      date: DateTime(2026, 2, 23),
      formattedDate: '23 Feb 2026',
      description:
          'Pengelola kawasan dan tim SAR gabungan memastikan seluruh anchor dan hanger pada jalur pemanjatan Tebing Citatah 125 aman untuk digunakan kembali. Jalur utama kini telah dibuka bagi para pemanjat dengan protokol keselamatan ketat.\n\n'
          'Para pemanjat disarankan untuk tetap melakukan pengecekan mandiri pada webbing dan baut sebelum melakukan lead climb.',
      photos: ['assets/images/citatah.jpg', 'assets/images/fotocitatah1.jpeg'],
      headerImage: 'assets/images/citatah.jpg',
      rockType: 'Andesit & Limestone',
      grade: 'Grade 5.9 - 5.11',
      rating: '4.8',
      author: 'Pengelola Citatah',
      duration: '1 Hari',
      team: 'Tim SAR & Pengelola',
      elevation: '125 mdpl',
    ),
  ];

  static List<BeritaModel> get daftarBerita => List.unmodifiable(_beritaList);

  static Future<void> loadFromDatabase() async {
    final beritaDb = await DatabaseHelper.instance.getAllBeritaAcara();
    if (beritaDb.isNotEmpty) {
      _beritaList
        ..clear()
        ..addAll(beritaDb.map(BeritaModel.fromMap));
      return;
    }

    for (final item in _beritaList) {
      await DatabaseHelper.instance.saveBeritaAcara(item.toMap());
    }
  }

  static Future<void> tambahBerita(BeritaModel item) async {
    await DatabaseHelper.instance.saveBeritaAcara(item.toMap());
    _beritaList.removeWhere((berita) => berita.id == item.id);
    _beritaList.insert(0, item);
  }

  static Future<void> updateBeritaStatus(String id, String status) async {
    final index = _beritaList.indexWhere((b) => b.id == id);
    if (index != -1) {
      final updated = _beritaList[index].copyWith(status: status);
      _beritaList[index] = updated;
      await DatabaseHelper.instance.saveBeritaAcara(updated.toMap());
    }
  }

  static Future<void> voteBerita(String id, {required bool isUpvote}) async {
    final index = _beritaList.indexWhere((b) => b.id == id);
    if (index != -1) {
      final item = _beritaList[index];
      final updated = item.copyWith(
        verifiedCount: isUpvote ? item.verifiedCount + 1 : item.verifiedCount,
        hoaxCount: !isUpvote ? item.hoaxCount + 1 : item.hoaxCount,
      );
      _beritaList[index] = updated;
      await DatabaseHelper.instance.saveBeritaAcara(updated.toMap());
    }
  }

  static void hapusBerita(String id) {
    _beritaList.removeWhere((item) => item.id == id);
  }
}
