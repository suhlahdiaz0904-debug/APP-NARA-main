import 'package:flutter_application_1/core/database/tables/database_tables.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Data Access Object (DAO) for User Authentication, Profiles, and Active Sessions.
class UserDao {
  final sqflite.Database Function() _getDb;
  static const String _activeUserKey = 'nara_active_user_id';

  UserDao(this._getDb);

  /// Registers a new user into the database and establishes active session.
  Future<int> registerUser(UserModel user) async {
    final db = _getDb();
    final id = await db.insert(
      UserTable.tableName,
      user.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.fail,
    );

    await setActiveUserId(id);
    return id;
  }

  /// Verifies user authentication credentials against local SQLite database.
  Future<UserModel?> loginUser(String email, String password) async {
    final db = _getDb();
    final maps = await db.query(
      UserTable.tableName,
      where: 'LOWER(${UserTable.columnEmail}) = ? AND ${UserTable.columnPassword} = ?',
      whereArgs: [email.toLowerCase().trim(), password],
    );

    if (maps.isNotEmpty) {
      final user = UserModel.fromMap(maps.first);
      if (user.id != null) {
        await setActiveUserId(user.id!);
      }
      return user;
    }
    return null;
  }

  /// Finds a user record by email address (case-insensitive).
  Future<UserModel?> getUserByEmail(String email) async {
    final db = _getDb();
    final maps = await db.query(
      UserTable.tableName,
      where: 'LOWER(${UserTable.columnEmail}) = ?',
      whereArgs: [email.toLowerCase().trim()],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all registered users ordered by ID descending.
  Future<List<UserModel>> getAllUsers() async {
    final db = _getDb();
    final result = await db.query(UserTable.tableName, orderBy: '${UserTable.columnId} DESC');
    return result.map((json) => UserModel.fromMap(json)).toList();
  }

  /// Retrieves the currently active authenticated user or the latest registered user.
  Future<UserModel?> getLatestUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getInt(_activeUserKey);
      if (activeId != null) {
        final user = await getUserById(activeId);
        if (user != null) return user;
      }
    } catch (_) {}

    final db = _getDb();
    final result = await db.query(
      UserTable.tableName,
      orderBy: '${UserTable.columnId} DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  /// Sets the active user session ID in SharedPreferences.
  Future<void> setActiveUserId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_activeUserKey, userId);
    } catch (_) {}
  }

  /// Retrieves the active user session ID from SharedPreferences.
  Future<int?> getActiveUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_activeUserKey);
    } catch (_) {
      return null;
    }
  }

  /// Retrieves a specific user by primary ID.
  Future<UserModel?> getUserById(int id) async {
    final db = _getDb();
    final result = await db.query(
      UserTable.tableName,
      where: '${UserTable.columnId} = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }
    return null;
  }

  /// Updates a user's password securely by email.
  Future<int> updatePassword(String email, String newPassword) async {
    final db = _getDb();
    return await db.update(
      UserTable.tableName,
      {UserTable.columnPassword: newPassword},
      where: 'LOWER(${UserTable.columnEmail}) = ?',
      whereArgs: [email.toLowerCase().trim()],
    );
  }

  /// Updates profile information for an existing user.
  Future<int> updateUser(UserModel user) async {
    final db = _getDb();
    if (user.id != null) {
      final rows = await db.update(
        UserTable.tableName,
        user.toMap(),
        where: '${UserTable.columnId} = ?',
        whereArgs: [user.id],
      );
      if (rows > 0) return rows;
    }
    final latest = await getLatestUser();
    if (latest != null && latest.id != null) {
      final updated = user.copyWith(id: latest.id);
      return await db.update(
        UserTable.tableName,
        updated.toMap(),
        where: '${UserTable.columnId} = ?',
        whereArgs: [latest.id],
      );
    } else {
      return await db.insert(UserTable.tableName, user.toMap());
    }
  }

  /// Convenience method to save or update user entity.
  Future<int> saveOrUpdateUser(UserModel user) async {
    return await updateUser(user);
  }
}
