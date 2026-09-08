import 'dart:convert';

// =========================================================================
// MODEL LOG EKSPEDISI PETUALANG NARA (TEBING & GOA)
// Sesuai Desain Stitch (Node: Detail Log Ekspedisi 2b8d54a1a5654f898491073d039bbdfd)
// =========================================================================

class ExpeditionNoteItem {
  final String time;
  final String title;
  final String? subtitle;
  final String iconType; // 'flag', 'hardware', 'photo_camera', 'check'
  final List<String> photos;

  const ExpeditionNoteItem({
    required this.time,
    required this.title,
    this.subtitle,
    required this.iconType,
    this.photos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'time': time,
      'title': title,
      'subtitle': subtitle,
      'iconType': iconType,
      'photos': photos,
    };
  }

  factory ExpeditionNoteItem.fromMap(Map<String, dynamic> map) {
    return ExpeditionNoteItem(
      time: map['time'] ?? '08:00',
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      iconType: map['iconType'] ?? 'flag',
      photos: (map['photos'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ExpeditionLog {
  final int? id;
  final int? userId;
  final String spotId;
  final String spotName;
  final String spotType; // 'Rock Climbing' / 'Caving Speleologi' / 'Tebing' / 'Goa'
  final String region;
  final String imageUrl;
  final DateTime date;
  final String duration;
  final double distanceKm;
  final String elevation;
  final String? trackMapUrl;
  final List<ExpeditionNoteItem> notes;
  final List<String> photoGallery;
  final bool isCompleted;

  ExpeditionLog({
    this.id,
    this.userId,
    required this.spotId,
    required this.spotName,
    required this.spotType,
    required this.region,
    required this.imageUrl,
    required this.date,
    required this.duration,
    required this.distanceKm,
    required this.elevation,
    this.trackMapUrl,
    required this.notes,
    this.photoGallery = const [],
    this.isCompleted = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'spotId': spotId,
      'spotName': spotName,
      'spotType': spotType,
      'region': region,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'duration': duration,
      'distanceKm': distanceKm,
      'elevation': elevation,
      'trackMapUrl': trackMapUrl,
      'notesJson': jsonEncode(notes.map((n) => n.toMap()).toList()),
      'photoGalleryJson': jsonEncode(photoGallery),
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory ExpeditionLog.fromMap(Map<String, dynamic> map) {
    List<ExpeditionNoteItem> parsedNotes = [];
    if (map['notesJson'] != null) {
      try {
        final List decoded = jsonDecode(map['notesJson']);
        parsedNotes = decoded.map((item) => ExpeditionNoteItem.fromMap(item as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    List<String> parsedPhotos = [];
    if (map['photoGalleryJson'] != null) {
      try {
        final List decoded = jsonDecode(map['photoGalleryJson']);
        parsedPhotos = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    return ExpeditionLog(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      spotId: map['spotId'] ?? 'spot_default',
      spotName: map['spotName'] ?? 'Tebing Citatah 125',
      spotType: map['spotType'] ?? 'Rock Climbing',
      region: map['region'] ?? 'Jawa Barat, Indonesia',
      imageUrl: map['imageUrl'] ??
          'https://lh3.googleusercontent.com/aida/AP1WRLtlNSurYBr_XiGRkL2yLlS1NLL-NT_wFBANyecQrLUztwjrUgD8cewXY2JpXPyhzijdc4eT1-JsBTjHZ4FE1Se1vCDhHT8CsqLC770l69Adsxh0NTTPVcAivJ2y6b7jeBMwu8XM3gJEO7vxrNR_6SHFVMRHkKfOrkl1quKjMzWEVkLsE7f1dv9BRloyiUyPQMJkCLOaIPoDz-o8L-13mEWbNicOSa6a44Rpsh__uky_HpYnWUy-u9T1SIg',
      date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      duration: map['duration'] ?? '08h 15m',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 1.2,
      elevation: map['elevation'] ?? '125m',
      trackMapUrl: map['trackMapUrl'],
      notes: parsedNotes,
      photoGallery: parsedPhotos,
      isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
    );
  }
}
