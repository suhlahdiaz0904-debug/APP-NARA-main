/// Schema definition for the `users` table.
abstract class UserTable {
  static const String tableName = 'users';

  static const String columnId = 'id';
  static const String columnNama = 'nama';
  static const String columnEmail = 'email';
  static const String columnNoHp = 'noHp';
  static const String columnPassword = 'password';
  static const String columnAsalKota = 'asalKota';
  static const String columnFotoProfil = 'fotoProfil';
  static const String columnRolePetualang = 'rolePetualang';
  static const String columnBio = 'bio';
  static const String columnGolonganDarah = 'golonganDarah';
  static const String columnKontakDaruratNama = 'kontakDaruratNama';
  static const String columnKontakDaruratHp = 'kontakDaruratHp';
  static const String columnOrganisasi = 'organisasi';
  static const String columnTotalEkspedisi = 'totalEkspedisi';
  static const String columnJarakJelajah = 'jarakJelajah';
  static const String columnJamTerbang = 'jamTerbang';

  static const String createTableSql =
      '''
    CREATE TABLE $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnNama TEXT NOT NULL,
      $columnEmail TEXT NOT NULL UNIQUE,
      $columnNoHp TEXT NOT NULL,
      $columnPassword TEXT NOT NULL,
      $columnAsalKota TEXT NOT NULL,
      $columnFotoProfil TEXT,
      $columnRolePetualang TEXT,
      $columnBio TEXT,
      $columnGolonganDarah TEXT,
      $columnKontakDaruratNama TEXT,
      $columnKontakDaruratHp TEXT,
      $columnOrganisasi TEXT,
      $columnTotalEkspedisi INTEGER,
      $columnJarakJelajah TEXT,
      $columnJamTerbang TEXT
    )
  ''';
}

/// Schema definition for the `bookmarks` table.
abstract class BookmarkTable {
  static const String tableName = 'bookmarks';

  static const String columnId = 'id';
  static const String columnUserId = 'userId';
  static const String columnSpotId = 'spotId';
  static const String columnTitle = 'title';
  static const String columnLocation = 'location';
  static const String columnType = 'type';
  static const String columnImageUrl = 'imageUrl';
  static const String columnRating = 'rating';
  static const String columnElevation = 'elevation';
  static const String columnCoordinates = 'coordinates';
  static const String columnCreatedAt = 'createdAt';

  static const String createTableSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnUserId INTEGER NOT NULL,
      $columnSpotId TEXT NOT NULL,
      $columnTitle TEXT NOT NULL,
      $columnLocation TEXT NOT NULL,
      $columnType TEXT NOT NULL,
      $columnImageUrl TEXT NOT NULL,
      $columnRating TEXT,
      $columnElevation TEXT,
      $columnCoordinates TEXT,
      $columnCreatedAt TEXT NOT NULL,
      UNIQUE($columnUserId, $columnSpotId)
    )
  ''';
}

/// Schema definition for the `expedition_logs` table.
abstract class ExpeditionLogTable {
  static const String tableName = 'expedition_logs';

  static const String columnId = 'id';
  static const String columnUserId = 'userId';
  static const String columnSpotId = 'spotId';
  static const String columnSpotName = 'spotName';
  static const String columnSpotType = 'spotType';
  static const String columnRegion = 'region';
  static const String columnImageUrl = 'imageUrl';
  static const String columnDate = 'date';
  static const String columnDuration = 'duration';
  static const String columnDistanceKm = 'distanceKm';
  static const String columnElevation = 'elevation';
  static const String columnTrackMapUrl = 'trackMapUrl';
  static const String columnNotesJson = 'notesJson';
  static const String columnPhotoGalleryJson = 'photoGalleryJson';
  static const String columnIsCompleted = 'isCompleted';

  static const String createTableSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
      $columnUserId INTEGER,
      $columnSpotId TEXT NOT NULL,
      $columnSpotName TEXT NOT NULL,
      $columnSpotType TEXT NOT NULL,
      $columnRegion TEXT NOT NULL,
      $columnImageUrl TEXT NOT NULL,
      $columnDate TEXT NOT NULL,
      $columnDuration TEXT NOT NULL,
      $columnDistanceKm REAL NOT NULL,
      $columnElevation TEXT NOT NULL,
      $columnTrackMapUrl TEXT,
      $columnNotesJson TEXT,
      $columnPhotoGalleryJson TEXT,
      $columnIsCompleted INTEGER DEFAULT 1
    )
  ''';
}

/// Schema definition for the `berita_acara` table.
abstract class NewsTable {
  static const String tableName = 'berita_acara';

  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnLocation = 'location';
  static const String columnCoordinates = 'coordinates';
  static const String columnCategory = 'category';
  static const String columnCategories = 'categories';
  static const String columnTimeAgo = 'timeAgo';
  static const String columnDate = 'date';
  static const String columnFormattedDate = 'formattedDate';
  static const String columnDescription = 'description';
  static const String columnPhotos = 'photos';
  static const String columnHeaderImage = 'headerImage';
  static const String columnRockType = 'rockType';
  static const String columnGrade = 'grade';
  static const String columnRating = 'rating';
  static const String columnAuthor = 'author';
  static const String columnDuration = 'duration';
  static const String columnTeam = 'team';
  static const String columnElevation = 'elevation';
  static const String columnTechnique = 'technique';
  static const String columnMainRope = 'mainRope';
  static const String columnIsDraft = 'isDraft';
  static const String columnUserId = 'userId';
  static const String columnStatus = 'status';

  static const String createTableSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnTitle TEXT NOT NULL,
      $columnLocation TEXT NOT NULL,
      $columnCoordinates TEXT,
      $columnCategory TEXT NOT NULL,
      $columnCategories TEXT,
      $columnTimeAgo TEXT,
      $columnDate TEXT NOT NULL,
      $columnFormattedDate TEXT,
      $columnDescription TEXT,
      $columnPhotos TEXT,
      $columnHeaderImage TEXT,
      $columnRockType TEXT,
      $columnGrade TEXT,
      $columnRating TEXT,
      $columnAuthor TEXT,
      $columnDuration TEXT,
      $columnTeam TEXT,
      $columnElevation TEXT,
      $columnTechnique TEXT,
      $columnMainRope TEXT,
      $columnIsDraft INTEGER DEFAULT 0,
      $columnUserId INTEGER,
      $columnStatus TEXT DEFAULT 'VALID'
    )
  ''';
}

/// Schema definition for the `explorer_reviews` table.
abstract class ReviewTable {
  static const String tableName = 'explorer_reviews';

  static const String columnId = 'id';
  static const String columnSpotId = 'spotId';
  static const String columnDestinationName = 'destinationName';
  static const String columnUserName = 'userName';
  static const String columnUserRole = 'userRole';
  static const String columnUserAvatar = 'userAvatar';
  static const String columnRating = 'rating';
  static const String columnComment = 'comment';
  static const String columnCreatedAt = 'createdAt';
  static const String columnPhotosJson = 'photosJson';
  static const String columnLikes = 'likes';
  static const String columnIsSynced = 'isSynced';

  static const String createTableSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnSpotId TEXT NOT NULL,
      $columnDestinationName TEXT NOT NULL,
      $columnUserName TEXT NOT NULL,
      $columnUserRole TEXT,
      $columnUserAvatar TEXT,
      $columnRating REAL NOT NULL,
      $columnComment TEXT NOT NULL,
      $columnCreatedAt TEXT NOT NULL,
      $columnPhotosJson TEXT,
      $columnLikes INTEGER DEFAULT 0,
      $columnIsSynced INTEGER DEFAULT 0
    )
  ''';
}
