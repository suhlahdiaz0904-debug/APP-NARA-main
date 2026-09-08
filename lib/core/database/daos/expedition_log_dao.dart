import 'package:flutter_application_1/core/database/tables/database_tables.dart';
import 'package:flutter_application_1/features/profile/models/expedition_log_model.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

/// Data Access Object (DAO) for User Expedition Logs and Field Exploration Statistics.
class ExpeditionLogDao {
  final sqflite.Database Function() _getDb;

  ExpeditionLogDao(this._getDb);

  /// Helper to parse human readable duration strings (e.g., "08h 15m", "6h", "45 Menit") into total minutes.
  static int parseDurationToMinutes(String durationStr) {
    int totalMinutes = 0;
    final d = durationStr.toLowerCase().trim();

    final hMatch = RegExp(r'(\d+)\s*(?:h|jam|hr|hrs)').firstMatch(d);
    if (hMatch != null) {
      totalMinutes += (int.tryParse(hMatch.group(1)!) ?? 0) * 60;
    }

    final mMatch = RegExp(r'(\d+)\s*(?:m|menit|min|mins)').firstMatch(d);
    if (mMatch != null) {
      totalMinutes += int.tryParse(mMatch.group(1)!) ?? 0;
    }

    if (hMatch == null && mMatch == null) {
      final parts = d.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        totalMinutes = (h * 60) + m;
      } else {
        final onlyNum = int.tryParse(RegExp(r'\d+').stringMatch(d) ?? '');
        if (onlyNum != null) {
          totalMinutes = onlyNum * 60;
        }
      }
    }
    return totalMinutes;
  }

  /// Calculates aggregate statistics (completed count, total distance in km, active field hours).
  Future<Map<String, dynamic>> calculateUserStats(int? userId) async {
    final logs = await getUserExpeditionLogs(userId);
    final completedLogs = logs.where((l) => l.isCompleted).toList();

    final int totalCount = completedLogs.length;
    double totalKm = 0.0;
    int totalMinutes = 0;

    for (var log in completedLogs) {
      totalKm += log.distanceKm;
      totalMinutes += parseDurationToMinutes(log.duration);
    }

    final String formattedJarak = totalKm == 0
        ? '0 km'
        : '${totalKm.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} km';

    String formattedJam;
    if (totalMinutes == 0) {
      formattedJam = '0 Jam';
    } else if (totalMinutes < 60) {
      formattedJam = '$totalMinutes Menit';
    } else if (totalMinutes % 60 == 0) {
      formattedJam = '${totalMinutes ~/ 60} Jam';
    } else {
      final hours = (totalMinutes / 60.0)
          .toStringAsFixed(1)
          .replaceAll(RegExp(r'\.0$'), '');
      formattedJam = '$hours Jam';
    }

    return {
      'totalEkspedisi': totalCount,
      'jarakJelajah': formattedJarak,
      'jamTerbang': formattedJam,
      'totalKm': totalKm,
      'totalMinutes': totalMinutes,
    };
  }

  /// Inserts or replaces an expedition log entry in SQLite.
  Future<int> saveExpeditionLog(ExpeditionLog log) async {
    final db = _getDb();
    return await db.insert(
      ExpeditionLogTable.tableName,
      log.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  /// Deletes an expedition log entry by ID.
  Future<int> deleteExpeditionLog(int id) async {
    final db = _getDb();
    return await db.delete(
      ExpeditionLogTable.tableName,
      where: '${ExpeditionLogTable.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// Retrieves all expedition logs belonging to a user ID.
  Future<List<ExpeditionLog>> getUserExpeditionLogs(int? userId) async {
    final db = _getDb();
    final result = await db.query(
      ExpeditionLogTable.tableName,
      where: userId != null ? '${ExpeditionLogTable.columnUserId} = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: '${ExpeditionLogTable.columnId} DESC',
    );

    return result.map((json) => ExpeditionLog.fromMap(json)).toList();
  }

  /// Retrieves the latest logged expedition.
  Future<ExpeditionLog?> getLatestExpeditionLog() async {
    final db = _getDb();
    final result = await db.query(
      ExpeditionLogTable.tableName,
      orderBy: '${ExpeditionLogTable.columnId} DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ExpeditionLog.fromMap(result.first);
    }
    return null;
  }

  /// Seeds default starter expedition logs for a new user if database is empty.
  Future<List<ExpeditionLog>> initDefaultExpeditionLogsIfEmpty(int? userId) async {
    final defaultLog1 = ExpeditionLog(
      userId: userId,
      spotId: 'citatah_125',
      spotName: 'Tebing Citatah 125',
      spotType: 'Rock Climbing',
      region: 'Jawa Barat, Indonesia',
      imageUrl:
          'https://lh3.googleusercontent.com/aida/AP1WRLtlNSurYBr_XiGRkL2yLlS1NLL-NT_wFBANyecQrLUztwjrUgD8cewXY2JpXPyhzijdc4eT1-JsBTjHZ4FE1Se1vCDhHT8CsqLC770l69Adsxh0NTTPVcAivJ2y6b7jeBMwu8XM3gJEO7vxrNR_6SHFVMRHkKfOrkl1quKjMzWEVkLsE7f1dv9BRloyiUyPQMJkCLOaIPoDz-o8L-13mEWbNicOSa6a44Rpsh__uky_HpYnWUy-u9T1SIg',
      date: DateTime.now().subtract(const Duration(days: 2)),
      duration: '08h 15m',
      distanceKm: 1.2,
      elevation: '125m',
      trackMapUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAnEHDBE6DIZfq8Nw0PVwRD-Kx6mLOb_9XA830LBcsK5SX998okFtMAsH-IvCY70At9Q_dYSXsX2abEuS1AgEl4UUq302VtIh5P4wradYGkbMwio7dL5cIOVGmJr8ROjABfDA7OC0AnCorbpJJqRJ3jG3psu0OoCBwOccK36ph8ipuNM379zmmWp1p3_Oj0bDTMgxWm11MMeLV2GzoaqO5Rg8xQMhW0pWkbQhz4qfcQ1sz0bahfr3iw',
      notes: const [
        ExpeditionNoteItem(
          time: '09:00',
          title: 'Tiba di Basecamp',
          subtitle:
              'Kondisi cuaca sangat optimal, langit cerah dengan angin sejuk 12 km/jam.',
          iconType: 'flag',
        ),
        ExpeditionNoteItem(
          time: '10:30',
          title: 'Memulai Pitch 1 (Grade 5.9)',
          subtitle:
              'Kualitas batu kapur solid. Pemasangan anchor pengaman awal terpasang kokoh.',
          iconType: 'hardware',
        ),
        ExpeditionNoteItem(
          time: '13:15',
          title: 'Mencapai Crux & Puncak Sektor',
          subtitle:
              'Panorama lembah karst Padalarang terlihat sangat menakjubkan.',
          iconType: 'photo_camera',
          photos: [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAW8iZ26KTJLVzh0H-zJLIWK2aMmB_MpfZeppATNtGzimrSeTQ4sgIzi_w8rFFWXpTewgyIAIzdLDUfvMcxdu0ehhprWOYuo32BDBZPh3tNYNblrGlt5_kkUrltt2zaVZvYBWvkw_VGotq2mXxWuBhGKPOpovnXamzkL697x0HBpKXt4Lsv4fyd7He2_Sa9Ve4N2Z1xDhTsxi45hCLTcfDe3m5BNkvmybm1NglIbQejpZB46Vys6Sa6',
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDoJFY6Ca2Pec3A5XBXkfUkzmQPDhFtoErjDAOI0Of780fDdC6NWKVmiYd_5_PU2pFci0Tl2U7wXd24aZ1RO6ioGV4f94BffL5jFrqgyopmu9veE4v8Aauxz5v3pAv_jxr0AUgMtlyfSVfRhRyiIbc_7XyZjLkSw84bFMe48tLpoSBgoUzBItIF_4f-9EVn5kHVGH7WU66cjlxxeZabs9Px22C1ykxEtYkgeqes_vfR8p6QosDzx5h3',
          ],
        ),
      ],
      photoGallery: const [
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAW8iZ26KTJLVzh0H-zJLIWK2aMmB_MpfZeppATNtGzimrSeTQ4sgIzi_w8rFFWXpTewgyIAIzdLDUfvMcxdu0ehhprWOYuo32BDBZPh3tNYNblrGlt5_kkUrltt2zaVZvYBWvkw_VGotq2mXxWuBhGKPOpovnXamzkL697x0HBpKXt4Lsv4fyd7He2_Sa9Ve4N2Z1xDhTsxi45hCLTcfDe3m5BNkvmybm1NglIbQejpZB46Vys6Sa6',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDoJFY6Ca2Pec3A5XBXkfUkzmQPDhFtoErjDAOI0Of780fDdC6NWKVmiYd_5_PU2pFci0Tl2U7wXd24aZ1RO6ioGV4f94BffL5jFrqgyopmu9veE4v8Aauxz5v3pAv_jxr0AUgMtlyfSVfRhRyiIbc_7XyZjLkSw84bFMe48tLpoSBgoUzBItIF_4f-9EVn5kHVGH7WU66cjlxxeZabs9Px22C1ykxEtYkgeqes_vfR8p6QosDzx5h3',
      ],
      isCompleted: true,
    );

    final defaultLog2 = ExpeditionLog(
      userId: userId,
      spotId: 'jomblang',
      spotName: 'Goa Jomblang (Luweng Vertikal)',
      spotType: 'Caving Speleologi',
      region: 'Gunungkidul, D.I. Yogyakarta',
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      date: DateTime.now().subtract(const Duration(days: 9)),
      duration: '06h 40m',
      distanceKm: 0.8,
      elevation: 'Kedalaman 60m',
      notes: const [
        ExpeditionNoteItem(
          time: '08:30',
          title: 'Rigging Tali SRT Selesai',
          subtitle: 'Anchor pohon dan bolt di mulut luweng diverifikasi.',
          iconType: 'hardware',
        ),
        ExpeditionNoteItem(
          time: '11:45',
          title: 'Cahaya Surga (Ray of Light) Masuk',
          subtitle: 'Sinar matahari menembus lorong goa dengan sempurna.',
          iconType: 'photo_camera',
        ),
      ],
      isCompleted: true,
    );

    final db = _getDb();
    await db.insert(ExpeditionLogTable.tableName, defaultLog1.toMap());
    await db.insert(ExpeditionLogTable.tableName, defaultLog2.toMap());

    return [defaultLog1, defaultLog2];
  }
}
