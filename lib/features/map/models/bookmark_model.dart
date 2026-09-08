class BookmarkModel {
  final int? id;
  final int userId;
  final String spotId;
  final String title;
  final String location;
  final String type;
  final String imageUrl;
  final String? rating;
  final String? elevation;
  final String? coordinates;
  final String createdAt;

  BookmarkModel({
    this.id,
    required this.userId,
    required this.spotId,
    required this.title,
    required this.location,
    required this.type,
    required this.imageUrl,
    this.rating,
    this.elevation,
    this.coordinates,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'spotId': spotId,
      'title': title,
      'location': location,
      'type': type,
      'imageUrl': imageUrl,
      'rating': rating,
      'elevation': elevation,
      'coordinates': coordinates,
      'createdAt': createdAt,
    };
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      id: map['id'] as int?,
      userId: map['userId'] as int? ?? 1,
      spotId: map['spotId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      location: map['location'] as String? ?? '',
      type: map['type'] as String? ?? 'Tebing Panjat',
      imageUrl: map['imageUrl'] as String? ?? '',
      rating: map['rating'] as String?,
      elevation: map['elevation'] as String?,
      coordinates: map['coordinates'] as String?,
      createdAt:
          map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  BookmarkModel copyWith({
    int? id,
    int? userId,
    String? spotId,
    String? title,
    String? location,
    String? type,
    String? imageUrl,
    String? rating,
    String? elevation,
    String? coordinates,
    String? createdAt,
  }) {
    return BookmarkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      spotId: spotId ?? this.spotId,
      title: title ?? this.title,
      location: location ?? this.location,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      elevation: elevation ?? this.elevation,
      coordinates: coordinates ?? this.coordinates,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
