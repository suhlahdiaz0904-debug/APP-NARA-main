import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/map/screens/interactive_map_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';

// =========================================================================
// HALAMAN DETAIL PELACAK TEMAN LURING (POV PEMANJAT & SOS RECEIVED)
// Berdasarkan Desain Stitch Google: 255a660ea9b6449db49180091ee1dbe3
// =========================================================================

class PelacakTemanPage extends StatefulWidget {
  const PelacakTemanPage({super.key});

  @override
  State<PelacakTemanPage> createState() => _PelacakTemanPageState();
}

class _PelacakTemanPageState extends State<PelacakTemanPage>
    with TickerProviderStateMixin {
  // Palet Warna Resmi NARA Outdoor & Emergency
  static const Color darkGreen = Color(0xFF001D0F);
  static const Color accentAmber = Color(0xFFFED65B);
  static const Color errorRed = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  late AnimationController _sosPulseController1;
  late AnimationController _sosPulseController2;
  late AnimationController _bannerSlideController;
  final MapController _mapController = MapController();

  // Status Distress Anggota Tim (Mode Penerima Sinyal SOS Dekat)
  bool _hasSosDistress = true;
  bool _showIncomingNotification = true;

  // Titik Koordinat GPS (Device Pengguna & Korban / Anggota Tim)
  LatLng _userDeviceLocation = const LatLng(-6.8410, 107.4535);
  final LatLng _ayuSosLocation = const LatLng(-6.8360, 107.4490);

  // Data Anggota Berstatus Normal di Sekitar Pemanjat
  final List<Map<String, dynamic>> _normalMembers = [];

  @override
  void initState() {
    super.initState();

    _fetchUserRealGps();

    // Animasi Double Pulse SOS Marker
    _sosPulseController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _sosPulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _sosPulseController2.repeat();
    });

    // Animasi Notifikasi SOS Masuk
    _bannerSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    // Haptic Getaran saat menerima sinyal darurat
    HapticFeedback.heavyImpact();
  }

  Future<void> _fetchUserRealGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _userDeviceLocation = LatLng(pos.latitude, pos.longitude);
        });
        await _loadDetectedUsers();
      }
    } catch (_) {
      await _loadDetectedUsers();
    }
  }

  Future<void> _loadDetectedUsers() async {
    try {
      final users = await DatabaseHelper.instance.getAllUsers();
      final activeUser = await DatabaseHelper.instance.getLatestUser();

      final detectedUsers = users
          .where(
            (user) =>
                user.id != null &&
                user.id != activeUser?.id &&
                user.nama.trim().isNotEmpty,
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _normalMembers
          ..clear()
          ..addAll(_buildMembersFromUsers(detectedUsers));
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _normalMembers.clear();
        });
      }
    }
  }

  List<Map<String, dynamic>> _buildMembersFromUsers(List<UserModel> users) {
    final List<Map<String, dynamic>> result = [];

    for (int i = 0; i < users.length && i < 6; i++) {
      final user = users[i];
      final offsetLat = 0.0015 + (i * 0.0008);
      final offsetLon = 0.0024 + (i * 0.0011);
      final memberLocation = LatLng(
        _userDeviceLocation.latitude + offsetLat,
        _userDeviceLocation.longitude + offsetLon,
      );

      final distanceMeters = Geolocator.distanceBetween(
        _userDeviceLocation.latitude,
        _userDeviceLocation.longitude,
        memberLocation.latitude,
        memberLocation.longitude,
      ).round();

      final distanceLabel = distanceMeters < 1000
          ? '$distanceMeters m away'
          : '${(distanceMeters / 1000).toStringAsFixed(1)} km away';

      final initials = user.nama
          .trim()
          .split(RegExp(r'\s+'))
          .where((v) => v.isNotEmpty)
          .map((v) => v[0].toUpperCase())
          .take(2)
          .join();

      result.add({
        'initial': initials.isEmpty ? 'U' : initials,
        'name': user.nama.trim(),
        'distance': distanceLabel,
        'elevation': 'Elev ${2600 + i * 90} m',
        'battery': '${82 - i * 7}%',
        'batteryIcon': i % 2 == 0
            ? Icons.battery_full_rounded
            : Icons.battery_5_bar_rounded,
        'location': memberLocation,
      });
    }

    return result;
  }

  @override
  void dispose() {
    _sosPulseController1.dispose();
    _sosPulseController2.dispose();
    _bannerSlideController.dispose();
    super.dispose();
  }

  // Sinkronisasi Navigasi Rute Penyelamatan ke Device Rekan
  void _navigasiRuteKeDevice(String targetName, LatLng targetCoords) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetaInteraktifPage(
          initialSpotName: 'Rute ke $targetName',
          initialCoordinates:
              '${targetCoords.latitude.toStringAsFixed(5)}, ${targetCoords.longitude.toStringAsFixed(5)}',
          autoStartNavigation: true,
        ),
      ),
    );
  }

  void _kirimPingRespon() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cell_tower_rounded, color: accentAmber, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Sinyal Respon & Konfirmasi Pertolongan telah dikirimkan ke device Ayu.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Garis Rute Penyelamatan dari Device User ke Device Ayu (SOS)
    final List<LatLng> rescueRoutePoints = [
      _userDeviceLocation,
      LatLng(
        (_userDeviceLocation.latitude + _ayuSosLocation.latitude) / 2 + 0.001,
        (_userDeviceLocation.longitude + _ayuSosLocation.longitude) / 2 -
            0.0015,
      ),
      _ayuSosLocation,
    ];

    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.themePrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'NARA',
              style: TextStyle(
                color: context.themePrimary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              'PELACAK TEMAN (LURING)',
              style: TextStyle(
                color: context.themeTextSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 9.5,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isDark ? AppTheme.goldAccentDark : context.themePrimary,
              size: 22,
            ),
            tooltip: isDark
                ? 'Beralih ke Mode Terang'
                : 'Beralih ke Mode Gelap',
            onPressed: () => ThemeController.instance.toggleTheme(context),
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.themePrimary),
            tooltip: 'Pengaturan Simulasi Mesh / SOS',
            onPressed: () {
              setState(() {
                _hasSosDistress = !_hasSosDistress;
                _showIncomingNotification = _hasSosDistress;
                if (_hasSosDistress) _bannerSlideController.forward(from: 0.0);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _hasSosDistress
                        ? 'Simulasi Penerimaan Sinyal Darurat SOS Aktif.'
                        : 'Status Semua Tim Normal.',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =============================================================
                // 1. EXPEDITION TOPOGRAPHICAL MAP (INTERACTIVE REAL TIME VIEW)
                // =============================================================
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _ayuSosLocation,
                          initialZoom: 14.5,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.all,
                          ),
                        ),
                        children: [
                          // OpenTopoMap Layer
                          TileLayer(
                            urlTemplate:
                                'https://tile.opentopomap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.suhlah.nara',
                            maxZoom: 18,
                          ),

                          // Garis Rute Penyelamatan Merah ke Device Ayu
                          if (_hasSosDistress)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: rescueRoutePoints,
                                  strokeWidth: 5.0,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                                Polyline(
                                  points: rescueRoutePoints,
                                  strokeWidth: 3.5,
                                  color: errorRed,
                                ),
                              ],
                            ),

                          // Marker Teman & Lokasi SOS
                          MarkerLayer(
                            markers: [
                              // 1. Marker Device Pengguna (You)
                              Marker(
                                point: _userDeviceLocation,
                                width: 70,
                                height: 65,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: accentAmber,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.my_location_rounded,
                                        size: 16,
                                        color: Color(0xFF574500),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'You (Saya)',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: darkGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 2. Marker Rekan SOS (Ayu) dengan Efek Double Pulse Ring
                              if (_hasSosDistress)
                                Marker(
                                  point: _ayuSosLocation,
                                  width: 140,
                                  height: 100,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _buildMarkerPulseRing(
                                            _sosPulseController2,
                                          ),
                                          _buildMarkerPulseRing(
                                            _sosPulseController1,
                                          ),
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: errorRed,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black45,
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.emergency_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // Glass Label untuk Korban
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.95,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: errorRed.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 6,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Ayu (SOS)',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w900,
                                                color: errorRed,
                                              ),
                                            ),
                                            Text(
                                              '1.2 km • 3 min',
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w600,
                                                color: darkGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // 3. Markers Anggota Tim Normal (Alex, Maya, Sarah)
                              ..._normalMembers.map((member) {
                                final LatLng loc = member['location'] as LatLng;
                                return Marker(
                                  point: loc,
                                  width: 60,
                                  height: 55,
                                  child: GestureDetector(
                                    onTap: () => _navigasiRuteKeDevice(
                                      member['name'] as String,
                                      loc,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEBE8E2),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: darkGreen,
                                              width: 1.8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              member['initial'] as String,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: darkGreen,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            member['name'] as String,
                                            style: const TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: darkGreen,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),

                      // Overlay Badge Status Luring di Pojok Kiri Atas Peta
                      Positioned(
                        top: 12,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.satellite_alt_rounded,
                                color: errorRed,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Luring (LoRa Mesh 915 MHz)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // =============================================================
                // 2. TEAM STATUS SECTION & SOS HIGHLIGHT CARD
                // =============================================================
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: context.themeText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        _hasSosDistress
                            ? '1 member in distress (1 rekan membutuhkan bantuan)'
                            : 'Semua anggota tim dalam status aman',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.themeTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // SOS Highlight Card (Sesuai Desain Stitch Google)
                      if (_hasSosDistress)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C1518)
                                : errorContainer,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: errorRed.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: errorRed.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Card Korban
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: errorRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'A',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ayu',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: isDark
                                                ? const Color(0xFFFFB4AB)
                                                : onErrorContainer,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: errorRed,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.warning_rounded,
                                                color: Colors.white,
                                                size: 12,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'SOS ACTIVE',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Updated',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: errorRed,
                                        ),
                                      ),
                                      Text(
                                        '3 mins ago',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: errorRed,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // 3 Grid Box Metrik (Dist, Elev, Batt)
                              Row(
                                children: [
                                  // Dist
                                  Expanded(
                                    child: _buildDistressMetricBox(
                                      icon: Icons.straighten_rounded,
                                      label: 'Dist',
                                      value: '1.2 km',
                                      isRed: false,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Elev
                                  Expanded(
                                    child: _buildDistressMetricBox(
                                      icon: Icons.landscape_rounded,
                                      label: 'Elev',
                                      value: '2,840 m',
                                      isRed: false,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Batt
                                  Expanded(
                                    child: _buildDistressMetricBox(
                                      icon: Icons.battery_2_bar_rounded,
                                      label: 'Batt',
                                      value: '18%',
                                      isRed: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Action Buttons: Lihat Rute & Kirim Ping
                              Row(
                                children: [
                                  // Button 1: Lihat Rute (Navigasi Rute Terintegrasi)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _navigasiRuteKeDevice(
                                        'Ayu (SOS)',
                                        _ayuSosLocation,
                                      ),
                                      icon: Icon(
                                        Icons.route_rounded,
                                        size: 18,
                                        color: isDark
                                            ? const Color(0xFF0F1713)
                                            : Colors.white,
                                      ),
                                      label: Text(
                                        'Lihat Rute',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF0F1713)
                                              : Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: context.themePrimary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Button 2: Kirim Ping Respon
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _kirimPingRespon,
                                      icon: Icon(
                                        Icons.cell_tower_rounded,
                                        size: 18,
                                        color: context.themePrimary,
                                      ),
                                      label: Text(
                                        'Kirim Ping',
                                        style: TextStyle(
                                          color: context.themePrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: context.themeCard,
                                        side: BorderSide(
                                          color: context.themeBorder,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 22),

                      // =======================================================
                      // 3. NORMAL STATUS MEMBERS LIST (DENGAN AKSI LIHAT RUTE)
                      // =======================================================
                      Text(
                        'NORMAL STATUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: context.themeTextSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_normalMembers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Belum ada pengguna lain yang terdeteksi dalam aplikasi ini.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        )
                      else
                        ..._normalMembers.map((member) {
                          final LatLng loc = member['location'] as LatLng;

                          return InkWell(
                            onTap: () => _navigasiRuteKeDevice(
                              member['name'] as String,
                              loc,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: context.themeBorder,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: context.themeSurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        member['initial'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: context.themePrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member['name'] as String,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: context.themeText,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          '${member['distance']} • ${member['elevation']}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        member['batteryIcon'] as IconData,
                                        color: context.themePrimary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        member['battery'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: context.themePrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: context.themeTextSecondary,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 4. FLOATING TOP POPUP NOTIFIKASI SOS DARURAT (INCOMING SOS BROADCAST)
          // ===================================================================
          if (_hasSosDistress && _showIncomingNotification)
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, -1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _bannerSlideController,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: errorRed, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: errorRed.withValues(alpha: 0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: errorRed.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emergency_rounded,
                          color: errorRed,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'SOS DARURAT DITERIMA!',
                              style: TextStyle(
                                color: errorContainer,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Text(
                              'Ayu memicu sinyal darurat (1.2 km dari lokasi Anda)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _navigasiRuteKeDevice('Ayu (SOS)', _ayuSosLocation);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text(
                          'RUTE',
                          style: TextStyle(
                            color: accentAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() => _showIncomingNotification = false);
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDistressMetricBox({
    required IconData icon,
    required String label,
    required String value,
    required bool isRed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorRed.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: isRed ? errorRed : onErrorContainer),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: isRed ? errorRed : onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerPulseRing(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 0.8 + (controller.value * 1.6);
        final opacity = (1.0 - controller.value).clamp(0.0, 0.6);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: errorRed.withValues(alpha: opacity),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
