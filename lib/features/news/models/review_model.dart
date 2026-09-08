import 'dart:convert';
import 'package:flutter_application_1/core/database/tables/database_tables.dart';

/// Data Model representing an Explorer Community Review.
class ReviewModel {
  final String id;
  final String spotId;
  final String destinationName;
  final String userName;
  final String? userRole;
  final String? userAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String> photos;
  final int likes;
  final bool isSynced;

  ReviewModel({
    required this.id,
    required this.spotId,
    required this.destinationName,
    required this.userName,
    this.userRole,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.photos = const [],
    this.likes = 0,
    this.isSynced = false,
  });

  /// Formatted upload hour e.g. "14:35 WIB"
  String get uploadTimeFormatted {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  /// Human-readable relative time or exact time stamp
  String get displayTimestamp {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Baru saja ($uploadTimeFormatted)';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt lalu ($uploadTimeFormatted)';
    } else if (difference.inHours < 24 && now.day == createdAt.day) {
      return 'Hari ini, $uploadTimeFormatted';
    } else if (difference.inDays == 1 || (difference.inHours < 48 && now.day - createdAt.day == 1)) {
      return 'Kemarin, $uploadTimeFormatted';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final monthStr = months[createdAt.month - 1];
      return '${createdAt.day} $monthStr ${createdAt.year}, $uploadTimeFormatted';
    }
  }

  /// Converts model to Map for SQLite database storage
  Map<String, dynamic> toMap() {
    return {
      ReviewTable.columnId: id,
      ReviewTable.columnSpotId: spotId,
      ReviewTable.columnDestinationName: destinationName,
      ReviewTable.columnUserName: userName,
      ReviewTable.columnUserRole: userRole ?? 'Penjelajah',
      ReviewTable.columnUserAvatar: userAvatar ?? '',
      ReviewTable.columnRating: rating,
      ReviewTable.columnComment: comment,
      ReviewTable.columnCreatedAt: createdAt.toIso8601String(),
      ReviewTable.columnPhotosJson: jsonEncode(photos),
      ReviewTable.columnLikes: likes,
      ReviewTable.columnIsSynced: isSynced ? 1 : 0,
    };
  }

  /// Constructs model from SQLite database Map
  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedPhotos = [];
    if (map[ReviewTable.columnPhotosJson] != null) {
      try {
        final decoded = jsonDecode(map[ReviewTable.columnPhotosJson]);
        if (decoded is List) {
          parsedPhotos = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ReviewModel(
      id: map[ReviewTable.columnId]?.toString() ?? '',
      spotId: map[ReviewTable.columnSpotId]?.toString() ?? '',
      destinationName: map[ReviewTable.columnDestinationName]?.toString() ?? '',
      userName: map[ReviewTable.columnUserName]?.toString() ?? 'Penjelajah',
      userRole: map[ReviewTable.columnUserRole]?.toString() ?? 'Penjelajah',
      userAvatar: map[ReviewTable.columnUserAvatar]?.toString(),
      rating: (map[ReviewTable.columnRating] as num?)?.toDouble() ?? 5.0,
      comment: map[ReviewTable.columnComment]?.toString() ?? '',
      createdAt: DateTime.tryParse(map[ReviewTable.columnCreatedAt]?.toString() ?? '') ?? DateTime.now(),
      photos: parsedPhotos,
      likes: (map[ReviewTable.columnLikes] as num?)?.toInt() ?? 0,
      isSynced: (map[ReviewTable.columnIsSynced] as num?)?.toInt() == 1,
    );
  }

  /// JSON serialization for Cloud REST API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spotId': spotId,
      'destinationName': destinationName,
      'userName': userName,
      'userRole': userRole ?? 'Penjelajah',
      'userAvatar': userAvatar ?? '',
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'photos': photos,
      'likes': likes,
    };
  }

  /// JSON deserialization from Cloud REST API
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedPhotos = [];
    if (json['photos'] is List) {
      parsedPhotos = (json['photos'] as List).map((e) => e.toString()).toList();
    }

    return ReviewModel(
      id: json['id']?.toString() ?? '',
      spotId: json['spotId']?.toString() ?? '',
      destinationName: json['destinationName']?.toString() ?? '',
      userName: json['userName']?.toString() ?? 'Penjelajah',
      userRole: json['userRole']?.toString() ?? 'Penjelajah',
      userAvatar: json['userAvatar']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      comment: json['comment']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      photos: parsedPhotos,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      isSynced: true,
    );
  }

  ReviewModel copyWith({
    String? id,
    String? spotId,
    String? destinationName,
    String? userName,
    String? userRole,
    String? userAvatar,
    double? rating,
    String? comment,
    DateTime? createdAt,
    List<String>? photos,
    int? likes,
    bool? isSynced,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      spotId: spotId ?? this.spotId,
      destinationName: destinationName ?? this.destinationName,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      userAvatar: userAvatar ?? this.userAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      photos: photos ?? this.photos,
      likes: likes ?? this.likes,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
