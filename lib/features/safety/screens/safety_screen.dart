import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/safety/screens/friend_tracker_screen.dart';
import 'package:flutter_application_1/features/safety/screens/women_safety_screen.dart';
import 'package:flutter_application_1/features/safety/screens/critical_protocol_screen.dart';
import 'package:flutter_application_1/features/safety/screens/sos_active_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/weather/screens/weather_screen.dart';
import 'package:flutter_application_1/core/services/safety_firestore_service.dart';

// =========================================================================
// HALAMAN FITUR KEAMANAN (NARA SAFETY DASHBOARD)
// Berdasarkan Desain Stitch Google NARA Safety Center
// =========================================================================

class KeamananPage extends StatefulWidget {
  final VoidCallback? onBack;

  const KeamananPage({super.key, this.onBack});

  @override
  State<KeamananPage> createState() => _KeamananPageState();
}

class _KeamananPageState extends State<KeamananPage> {
  static const Color errorRed = Color(0xFFD94A3D); // Warm Burnt Crimson

  // Data Sinkronisasi Lokasi, Jam, dan Cuaca Lapangan
  String _locationName = 'Tebing Citatah, Bandung';
  String _timeText = '14:20';
  String _weatherText = '28°C Cerah';
  IconData _weatherIcon = Icons.wb_sunny_rounded;

  Timer? _clockTimer;

  // Firebase Streams & State
  StreamSubscription? _sosAlertsSubscription;
  StreamSubscription? _liveTrackersSubscription;
  final List<Map<String, dynamic>> _remoteSosAlerts = [];

  // Data Teman Luring (Offline Mesh Tracker) berasal dari Firebase Firestore & SQLite
  final List<Map<String, dynamic>> _offlinePeers = [];
  double _currentLat = -6.8396;
  double _currentLon = 107.4524;

  @override
  void initState() {
    super.initState();

    // Inisialisasi Jam & Cuaca
    _updateClockTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateClockTime();
    });

    _fetchRealtimeLocationAndWeather();
    _initFirebaseSubscriptions();
  }

  String _lastNotifiedSosId = '';

  void _triggerEmergencyHapticAlert() {
    HapticFeedback.heavyImpact();
    Timer(
      const Duration(milliseconds: 250),
      () => HapticFeedback.heavyImpact(),
    );
    Timer(const Duration(milliseconds: 500), () => HapticFeedback.vibrate());
    Timer(const Duration(milliseconds: 900), () => HapticFeedback.vibrate());
    Timer(
      const Duration(milliseconds: 1300),
      () => HapticFeedback.heavyImpact(),
    );
  }

  /// Inisialisasi pendengar Firebase Firestore untuk Sinyal Darurat SOS & Live Trackers
  void _initFirebaseSubscriptions() {
    _sosAlertsSubscription = SafetyFirestoreService.instance
        .getActiveSosAlertsStream()
        .listen((alerts) {
          if (!mounted) return;
          final currentUid = SafetyFirestoreService.instance.currentUserId;
          // Filter alert dari user lain (bukan diri sendiri)
          final otherAlerts = alerts
              .where((a) => a['userId'] != currentUid)
              .toList();

          if (otherAlerts.isNotEmpty) {
            final latest = otherAlerts.first;
            final alertId = latest['id'] ?? '';
            if (_lastNotifiedSosId != alertId) {
              _lastNotifiedSosId = alertId;
              _triggerEmergencyHapticAlert();
            }
          }

          setState(() {
            _remoteSosAlerts
              ..clear()
              ..addAll(otherAlerts);
          });
        });

    _liveTrackersSubscription = SafetyFirestoreService.instance
        .getLiveTrackersStream()
        .listen((trackers) {
          if (!mounted) return;
          _processLiveTrackers(trackers);
        });
  }

  void _processLiveTrackers(List<Map<String, dynamic>> trackers) {
    final currentUid = SafetyFirestoreService.instance.currentUserId;
    final otherTrackers = trackers
        .where(
          (t) =>
              t['userId'] != currentUid &&
              (t['latitude'] != 0.0 || t['longitude'] != 0.0),
        )
        .toList();

    if (otherTrackers.isNotEmpty) {
      final List<Map<String, dynamic>> livePeers = [];
      for (int i = 0; i < otherTrackers.length; i++) {
        final tracker = otherTrackers[i];
        final lat = tracker['latitude'] as double;
        final lon = tracker['longitude'] as double;
        final distanceMeters = Geolocator.distanceBetween(
          _currentLat,
          _currentLon,
          lat,
          lon,
        );

        final name = tracker['userName'] as String? ?? 'Petualang';
        final initials = name
            .trim()
            .split(RegExp(r'\s+'))
            .where((v) => v.isNotEmpty)
            .map((v) => v[0].toUpperCase())
            .take(2)
            .join();

        final distLabel = distanceMeters < 1000
            ? '${distanceMeters.round()} m'
            : '${(distanceMeters / 1000).toStringAsFixed(1)} km';

        livePeers.add({
          'initials': initials.isEmpty ? 'U' : initials,
          'name': name,
          'distance': distLabel,
          'direction': tracker['status'] == 'sos'
              ? 'SOS AKTIF'
              : (distanceMeters < 500 ? 'Dekat' : 'Sekitar'),
          'battery': '${tracker['battery'] ?? 85}%',
          'elevation': tracker['altitude'] ?? '420 mdpl',
          'color': tracker['status'] == 'sos'
              ? errorRed
              : (i % 2 == 0
                    ? const Color(0xFFFED65B)
                    : const Color(0xFFC5ECD2)),
          'textColor': tracker['status'] == 'sos'
              ? Colors.white
              : (i % 2 == 0
                    ? const Color(0xFF574500)
                    : const Color(0xFF002112)),
          'lastSeen': 'Live Firebase',
          'status': tracker['status'] ?? 'normal',
        });
      }

      setState(() {
        _offlinePeers
          ..clear()
          ..addAll(livePeers);
      });
    } else {
      _loadNearbyUsers();
    }
  }

  @override
  void dispose() {
    _sosAlertsSubscription?.cancel();
    _liveTrackersSubscription?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateClockTime() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    setState(() {
      _timeText = '$h:$m';
    });
  }

  Future<void> _fetchRealtimeLocationAndWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final double lat = pos.latitude;
      final double lon = pos.longitude;

      if (mounted) {
        setState(() {
          _currentLat = lat;
          _currentLon = lon;
        });
      }

      // Broadcast lokasi ke Firebase Firestore
      SafetyFirestoreService.instance.broadcastUserLocation(
        latitude: lat,
        longitude: lon,
        altitude: '${pos.altitude.round()} m ASL',
        status: 'normal',
      );

      await _loadNearbyUsers();

      // Reverse Geocoding Presisi (Desa, Kabupaten/Kota, Negara)
      try {
        final locDetail = await WeatherService.reverseGeocodeDetail(lat, lon);
        if (mounted && (locDetail['formatted']?.isNotEmpty ?? false)) {
          setState(() => _locationName = locDetail['formatted']!);
        }
      } catch (_) {}

      // Open-Meteo Weather
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weather_code&timezone=auto',
      );
      final weatherRes = await http.get(weatherUrl);
      if (weatherRes.statusCode == 200) {
        final wData = json.decode(weatherRes.body);
        final current = wData['current'];
        final temp = (current['temperature_2m'] as num?)?.round() ?? 28;
        final code = (current['weather_code'] as num?)?.toInt() ?? 0;

        String desc = 'Cerah';
        IconData icon = Icons.wb_sunny_rounded;

        if (code == 0) {
          desc = 'Cerah';
          icon = Icons.wb_sunny_rounded;
        } else if (code >= 1 && code <= 3) {
          desc = 'Cerah Berawan';
          icon = Icons.wb_cloudy_rounded;
        } else if (code == 45 || code == 48) {
          desc = 'Berkabut';
          icon = Icons.cloud_queue_rounded;
        } else if (code >= 51 && code <= 67 || code >= 80 && code <= 82) {
          desc = 'Hujan';
          icon = Icons.grain_rounded;
        } else if (code >= 95) {
          desc = 'Badai Petir';
          icon = Icons.thunderstorm_rounded;
        }

        if (mounted) {
          setState(() {
            _weatherText = '$temp°C $desc';
            _weatherIcon = icon;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadNearbyUsers() async {
    try {
      final allUsers = await DatabaseHelper.instance.getAllUsers();
      final activeUser = await DatabaseHelper.instance.getLatestUser();

      final nearby = <Map<String, dynamic>>[];

      for (int i = 0; i < allUsers.length; i++) {
        final user = allUsers[i];
        if (user.id == null ||
            user.id == activeUser?.id ||
            user.nama.trim().isEmpty) {
          continue;
        }

        final userLat = _currentLat + 0.0018 + (i * 0.0004);
        final userLon = _currentLon + 0.0024 + (i * 0.0005);
        final distanceMeters = Geolocator.distanceBetween(
          _currentLat,
          _currentLon,
          userLat,
          userLon,
        );

        if (distanceMeters <= 5000) {
          final initials = user.nama
              .trim()
              .split(RegExp(r'\s+'))
              .where((value) => value.isNotEmpty)
              .map((value) => value[0].toUpperCase())
              .take(2)
              .join();
          nearby.add({
            'initials': initials.isEmpty ? 'U' : initials,
            'name': user.nama.trim(),
            'distance': '${(distanceMeters / 1000).toStringAsFixed(1)} km',
            'direction': distanceMeters < 500 ? 'Dekat' : 'Sekitar',
            'battery': '${90 - (i % 5) * 8}%',
            'elevation': '${420 + (i * 35)} mdpl',
            'color': i % 2 == 0
                ? const Color(0xFFFED65B)
                : const Color(0xFFC5ECD2),
            'textColor': i % 2 == 0
                ? const Color(0xFF574500)
                : const Color(0xFF002112),
            'lastSeen': '${(i + 1)}m lalu',
          });
        }
      }

      if (mounted) {
        setState(() {
          _offlinePeers
            ..clear()
            ..addAll(nearby);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _offlinePeers.clear());
      }
    }
  }

  void _bukaHalamanPelacakTeman() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PelacakTemanPage()),
    );
  }

  void _bukaHalamanKebutuhanWanita() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KebutuhanWanitaPage()),
    );
  }

  void _bukaHalamanSosAktif() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SosAktifPage(
          initialCoordinates:
              '${_currentLat.toStringAsFixed(5)}°, ${_currentLon.toStringAsFixed(5)}°',
          initialAltitude: '450 m ASL',
        ),
      ),
    );
  }

  void _bukaHalamanProtokolKritis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProtokolKritisPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'NARA',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? AppTheme.darkPrimary : const Color(0xFF143023),
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                  color: isDark
                      ? AppTheme.goldAccentDark
                      : context.themePrimary,
                  size: 22,
                ),
                tooltip: isDark
                    ? 'Beralih ke Mode Terang'
                    : 'Beralih ke Mode Gelap',
                onPressed: () => ThemeController.instance.toggleTheme(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================================
                  // 1. HEADER SECTION & SINKRONISASI REALTIME LOKASI / JAM / CUACA
                  // =================================================================
                  Text(
                    'FITUR KEAMANAN',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: context.themeText,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Nusantara Adventure Risk Awareness',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.themeTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Indikator Real-time Lokasi, Jam, dan Cuaca (Glassmorphism Pill)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF1E2B23), Color(0xFF141F19)]
                            : const [Color(0xFFE8F5E9), Color(0xFFF1F8E9)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.themePrimary.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.themePrimary.withValues(
                            alpha: isDark ? 0.2 : 0.08,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: context.themePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.themePrimary.withValues(
                                  alpha: 0.8,
                                ),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _locationName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.themeText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          height: 12,
                          width: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: context.themeBorder,
                        ),
                        Icon(
                          _weatherIcon,
                          color: AppTheme.goldAccentDark,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$_timeText • $_weatherText',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.themeTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // =================================================================
                  // TOMBOL DARURAT SOS (EMERGENCY BROADCAST TRIGGER)
                  // =================================================================
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF3E1210), Color(0xFF1E0A09)]
                            : const [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD32F2F,
                          ).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOMBOL DARURAT SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Picu sinyal darurat & getarkan perangkat tim sekitar',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _bukaHalamanSosAktif,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFB71C1C),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'SOS',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // =================================================================
                  // NOTIFIKASI DARURAT SOS MASUK (DARI REKAN TIM DI FIRESTORE)
                  // =================================================================
                  if (_remoteSosAlerts.isNotEmpty) ...[
                    ..._remoteSosAlerts.map((alert) {
                      final victimName = alert['userName'] ?? 'Rekan Petualang';
                      final alertLat =
                          (alert['latitude'] as num?)?.toDouble() ?? 0.0;
                      final alertLon =
                          (alert['longitude'] as num?)?.toDouble() ?? 0.0;
                      final distM = Geolocator.distanceBetween(
                        _currentLat,
                        _currentLon,
                        alertLat,
                        alertLon,
                      );
                      final distText = distM < 1000
                          ? '${distM.round()} m'
                          : '${(distM / 1000).toStringAsFixed(1)} km';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: errorRed, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: errorRed.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: errorRed.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.emergency_rounded,
                                color: errorRed,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '🚨 SOS DARURAT DITERIMA!',
                                    style: TextStyle(
                                      color: Color(0xFFFFDAD6),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$victimName memicu sinyal darurat ($distText dari Anda)',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _bukaHalamanPelacakTeman,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: errorRed,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'LACAK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  // =================================================================
                  // 3. PELACAK TEMAN LURING (OFFLINE PEER TRACKER BOX)
                  // Tap untuk membuka Detail Pelacak Teman Luring (Stitch Screen)
                  // =================================================================
                  GestureDetector(
                    onTap: _bukaHalamanPelacakTeman,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.themeCard,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0284C7),
                                      Color(0xFF06B6D4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF06B6D4,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.group_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pelacak Teman Luring',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: context.themeText,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '🟢 Siaga Aktif',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: context.themeTextSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Daftar Rekan Tim
                          if (_offlinePeers.isEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.themeSurface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Belum ada pengguna sekitar yang terdeteksi di aplikasi ini.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            )
                          else
                            ..._offlinePeers.map((peer) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: context.themeSurface,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: peer['color'] as Color,
                                      child: Text(
                                        peer['initials'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: peer['textColor'] as Color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            peer['name'] as String,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: context.themeText,
                                            ),
                                          ),
                                          Text(
                                            '${peer['direction']} • Bat: ${peer['battery']}',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: context.themeTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.themeCard,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        peer['distance'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: context.themePrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // =================================================================
                  // 4. PROTOKOL & PANDUAN CARDS GRID
                  // =================================================================
                  // Card 1: Kebutuhan Wanita
                  Container(
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFFF4081).withValues(alpha: 0.25)
                            : context.themeBorder,
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : const Color(0xFFE91E63).withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _bukaHalamanKebutuhanWanita,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kebutuhan Wanita',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Panduan Perawatan Menstruasi & Sanitasi',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          'LIHAT LANGKAH',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? const Color(0xFFFF4081)
                                                : const Color(0xFFE91E63),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 10,
                                          color: isDark
                                              ? const Color(0xFFFF4081)
                                              : const Color(0xFFE91E63),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? const [
                                            Color(0xFFAD1457),
                                            Color(0xFFFF4081),
                                          ]
                                        : const [
                                            Color(0xFFC2185B),
                                            Color(0xFFFF4081),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF4081,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.female_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Card 2: Protokol Kritis
                  Container(
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFFFFB300).withValues(alpha: 0.25)
                            : context.themeBorder,
                        width: 0.9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _bukaHalamanProtokolKritis,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Protokol Kritis',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sanitasi Leave No Trace (LNT) & Evakuasi',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          'PELAJARI',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? const Color(0xFFFFB300)
                                                : const Color(0xFFD97706),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 10,
                                          color: isDark
                                              ? const Color(0xFFFFB300)
                                              : const Color(0xFFD97706),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? const [
                                            Color(0xFFE65100),
                                            Color(0xFFFFB300),
                                          ]
                                        : const [
                                            Color(0xFFD97706),
                                            Color(0xFFFBBF24),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFB300,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Space for bottom navbar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
