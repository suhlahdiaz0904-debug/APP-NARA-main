import 'package:flutter_application_1/core/database/daos/bookmark_dao.dart';
import 'package:flutter_application_1/core/database/daos/expedition_log_dao.dart';
import 'package:flutter_application_1/core/database/daos/news_dao.dart';
import 'package:flutter_application_1/core/database/daos/review_dao.dart';
import 'package:flutter_application_1/core/database/daos/user_dao.dart';
import 'package:flutter_application_1/core/database/tables/database_tables.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';
import 'package:flutter_application_1/features/map/models/bookmark_model.dart';
import 'package:flutter_application_1/features/profile/models/expedition_log_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// =========================================================================
/// ENTERPRISE DATABASE HELPER (SQLITE MANAGER & REPOSITORY FACADE)
/// =========================================================================
/// Manages SQLite database lifecycle, schema migrations, and provides
/// decoupled access to Domain DAOs (`UserDao`, `BookmarkDao`, `ExpeditionLogDao`, `NewsDao`, `ReviewDao`).
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static sqflite.Database? _database;
  static const String _dbName = 'nara_users.db';
  static const int _dbVersion = 7;

  late final UserDao _userDao;
  late final BookmarkDao _bookmarkDao;
  late final ExpeditionLogDao _expeditionLogDao;
  late final NewsDao _newsDao;
  late final ReviewDao _reviewDao;

  DatabaseHelper._init() {
    _userDao = UserDao(_requireDb);
    _bookmarkDao = BookmarkDao(_requireDb);
    _expeditionLogDao = ExpeditionLogDao(_requireDb);
    _newsDao = NewsDao(_requireDb);
    _reviewDao = ReviewDao(_requireDb);
  }

  sqflite.Database _requireDb() {
    if (_database == null) {
      throw StateError(
        'Database has not been initialized. Await database before invoking operations.',
      );
    }
    return _database!;
  }

  // Domain DAOs Exposure
  UserDao get userDao => _userDao;
  BookmarkDao get bookmarkDao => _bookmarkDao;
  ExpeditionLogDao get expeditionLogDao => _expeditionLogDao;
  NewsDao get newsDao => _newsDao;
  ReviewDao get reviewDao => _reviewDao;

  /// Lazy database getter ensuring singleton instantiation.
  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<sqflite.Database> _initDB(String filePath) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await sqflite.openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureColumnsExist(db);
        await _ensureExpeditionLogsTableExist(db);
        await _ensureBookmarksTableExist(db);
        await _ensureBeritaAcaraTableExist(db);
        await _ensureReviewTableExist(db);
      },
    );
  }

  Future<void> _createDB(sqflite.Database db, int version) async {
    await db.execute(UserTable.createTableSql);
    await db.execute(ExpeditionLogTable.createTableSql);
    await db.execute(BookmarkTable.createTableSql);
    await db.execute(NewsTable.createTableSql);
    await db.execute(ReviewTable.createTableSql);
  }

  Future<void> _onUpgrade(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _ensureColumnsExist(db);
    }
    if (oldVersion < 3) {
      await _ensureExpeditionLogsTableExist(db);
    }
    if (oldVersion < 4) {
      await _ensureBookmarksTableExist(db);
    }
    if (oldVersion < 5) {
      await _ensureBeritaAcaraTableExist(db);
    }
    if (oldVersion < 6) {
      await _ensureReviewTableExist(db);
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE ${NewsTable.tableName} ADD COLUMN status TEXT DEFAULT \'VALID\'');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${NewsTable.tableName} ADD COLUMN verifiedCount INTEGER DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${NewsTable.tableName} ADD COLUMN hoaxCount INTEGER DEFAULT 0');
      } catch (_) {}
    }
  }

  static Future<void> _ensureReviewTableExist(sqflite.Database db) async {
    await db.execute(ReviewTable.createTableSql);
  }

  static Future<void> _ensureColumnsExist(sqflite.Database db) async {
    final columns = [
      'fotoProfil TEXT',
      'rolePetualang TEXT',
      'bio TEXT',
      'golonganDarah TEXT',
      'kontakDaruratNama TEXT',
      'kontakDaruratHp TEXT',
      'organisasi TEXT',
      'totalEkspedisi INTEGER',
      'jarakJelajah TEXT',
      'jamTerbang TEXT',
    ];

    for (var col in columns) {
      try {
        final colName = col.split(' ')[0];
        await db.execute(
          'ALTER TABLE ${UserTable.tableName} ADD COLUMN $colName ${col.split(' ')[1]}',
        );
      } catch (_) {
        // Column already exists
      }
    }
  }

  static Future<void> _ensureExpeditionLogsTableExist(
    sqflite.Database db,
  ) async {
    await db.execute(ExpeditionLogTable.createTableSql);
  }

  static Future<void> _ensureBookmarksTableExist(sqflite.Database db) async {
    await db.execute(BookmarkTable.createTableSql);
  }

  static Future<void> _ensureBeritaAcaraTableExist(sqflite.Database db) async {
    await db.execute(NewsTable.createTableSql);
    try {
      await db.execute('ALTER TABLE ${NewsTable.tableName} ADD COLUMN status TEXT DEFAULT \'VALID\'');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE ${NewsTable.tableName} ADD COLUMN verifiedCount INTEGER DEFAULT 0');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE ${NewsTable.tableName} ADD COLUMN hoaxCount INTEGER DEFAULT 0');
    } catch (_) {}
  }

  // =========================================================================
  // 1. USER AUTHENTICATION & PROFILE APIS (FACADE)
  // =========================================================================

  Future<int> registerUser(UserModel user) async {
    await database;
    return _userDao.registerUser(user);
  }

  Future<UserModel?> loginUser(String email, String password) async {
    await database;
    return _userDao.loginUser(email, password);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    await database;
    return _userDao.getUserByEmail(email);
  }

  Future<List<UserModel>> getAllUsers() async {
    await database;
    return _userDao.getAllUsers();
  }

  Future<UserModel?> getLatestUser() async {
    await database;
    return _userDao.getLatestUser();
  }

  Future<void> setActiveUserId(int userId) async {
    return _userDao.setActiveUserId(userId);
  }

  Future<int?> getActiveUserId() async {
    return _userDao.getActiveUserId();
  }

  Future<UserModel?> getUserById(int id) async {
    await database;
    return _userDao.getUserById(id);
  }

  Future<int> updatePassword(String email, String newPassword) async {
    await database;
    return _userDao.updatePassword(email, newPassword);
  }

  Future<int> updateUser(UserModel user) async {
    await database;
    return _userDao.updateUser(user);
  }

  Future<int> saveOrUpdateUser(UserModel user) async {
    await database;
    return _userDao.saveOrUpdateUser(user);
  }

  // =========================================================================
  // 2. EXPEDITION LOGS & METRICS APIS (FACADE)
  // =========================================================================

  static int parseDurationToMinutes(String durationStr) {
    return ExpeditionLogDao.parseDurationToMinutes(durationStr);
  }

  Future<Map<String, dynamic>> calculateUserStats(int? userId) async {
    await database;
    return _expeditionLogDao.calculateUserStats(userId);
  }

  Future<UserModel?> syncUserStatsFromLogs(int? userId) async {
    await database;
    final user = userId != null
        ? await getUserById(userId)
        : await getLatestUser();
    if (user == null) return null;

    final stats = await calculateUserStats(user.id);
    final updated = user.copyWith(
      totalEkspedisi: stats['totalEkspedisi'] as int,
      jarakJelajah: stats['jarakJelajah'] as String,
      jamTerbang: stats['jamTerbang'] as String,
    );

    await updateUser(updated);
    return updated;
  }

  Future<int> saveExpeditionLog(ExpeditionLog log) async {
    await database;
    final id = await _expeditionLogDao.saveExpeditionLog(log);
    await syncUserStatsFromLogs(log.userId);
    return id;
  }

  Future<int> deleteExpeditionLog(int id, {int? userId}) async {
    await database;
    final rows = await _expeditionLogDao.deleteExpeditionLog(id);
    await syncUserStatsFromLogs(userId);
    return rows;
  }

  Future<List<ExpeditionLog>> getUserExpeditionLogs(int? userId) async {
    await database;
    return _expeditionLogDao.getUserExpeditionLogs(userId);
  }

  Future<ExpeditionLog?> getLatestExpeditionLog() async {
    await database;
    return _expeditionLogDao.getLatestExpeditionLog();
  }

  Future<List<ExpeditionLog>> initDefaultExpeditionLogsIfEmpty(
    int? userId,
  ) async {
    await database;
    return _expeditionLogDao.initDefaultExpeditionLogsIfEmpty(userId);
  }

  // =========================================================================
  // 3. BOOKMARKS & SPOT FAVORITES APIS (FACADE)
  // =========================================================================

  Future<bool> isBookmarked(int userId, String spotId) async {
    await database;
    return _bookmarkDao.isBookmarked(userId, spotId);
  }

  Future<bool> toggleBookmark({
    required int userId,
    required String spotId,
    required String title,
    required String location,
    required String type,
    required String imageUrl,
    String? rating,
    String? elevation,
    String? coordinates,
  }) async {
    await database;
    return _bookmarkDao.toggleBookmark(
      userId: userId,
      spotId: spotId,
      title: title,
      location: location,
      type: type,
      imageUrl: imageUrl,
      rating: rating,
      elevation: elevation,
      coordinates: coordinates,
    );
  }

  Future<List<BookmarkModel>> getUserBookmarks(int userId) async {
    await database;
    return _bookmarkDao.getUserBookmarks(userId);
  }

  Future<int> removeBookmark(int userId, String spotId) async {
    await database;
    return _bookmarkDao.removeBookmark(userId, spotId);
  }

  Future<int> addBookmark(BookmarkModel bookmark) async {
    await database;
    return _bookmarkDao.addBookmark(bookmark);
  }

  // =========================================================================
  // 4. NEWS & COMMUNITY INCIDENT REPORTS APIS (FACADE)
  // =========================================================================

  Future<void> saveBeritaAcara(Map<String, dynamic> berita) async {
    await database;
    return _newsDao.saveBeritaAcara(berita);
  }

  Future<List<Map<String, dynamic>>> getAllBeritaAcara() async {
    await database;
    return _newsDao.getAllBeritaAcara();
  }

  /// Closes active database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
