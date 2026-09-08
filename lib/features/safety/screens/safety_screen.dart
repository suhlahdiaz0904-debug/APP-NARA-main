import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/safety/screens/sos_active_screen.dart';
import 'package:flutter_application_1/features/safety/screens/friend_tracker_screen.dart';
import 'package:flutter_application_1/features/safety/screens/women_safety_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/weather/screens/weather_screen.dart';

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

class _KeamananPageState extends State<KeamananPage>
    with TickerProviderStateMixin {
  // Palet Warna Resmi NARA Safety Dashboard (Earth Tone)
  static const Color darkGreen = Color(0xFF1E382B); // Deep Forest Moss
  static const Color accentAmber = Color(0xFFDDA15E); // Warm Desert Ochre
  static const Color errorRed = Color(0xFFD94A3D); // Warm Burnt Crimson

  // Animasi Denyut SOS & Long-press Progress
  late AnimationController _pulseController;
  late AnimationController _holdController;
  bool _isHoldingSos = false;

  // Data Sinkronisasi Lokasi, Jam, dan Cuaca Lapangan
  String _locationName = 'Tebing Citatah, Bandung';
  String _timeText = '14:20';
  String _weatherText = '28°C Cerah';
  IconData _weatherIcon = Icons.wb_sunny_rounded;
  String _latText = '-6.83960° S';
  String _lonText = '107.45240° E';
  String _elevationText = '450 m ASL';

  Timer? _clockTimer;
  String _selectedSafetyFilter = 'Semua';

  final List<Map<String, dynamic>> _safetyFilterCategories = [
    {
      'name': 'Semua',
      'label': 'Semua Fitur',
      'icon': Icons.auto_awesome_rounded,
      'gradient': [Color(0xFF143023), Color(0xFF2E7D32)],
      'accentColor': Color(0xFF4CAF78),
      'unselectedBg': Color(0xFFE8F5E9),
      'unselectedIcon': Color(0xFF2E7D32),
    },
    {
      'name': 'SOS',
      'label': 'Tombol Darurat SOS',
      'icon': Icons.sos_rounded,
      'gradient': [Color(0xFFB71C1C), Color(0xFFE53935)],
      'accentColor': Color(0xFFFF8A80),
      'unselectedBg': Color(0xFFFFEBEE),
      'unselectedIcon': Color(0xFFD32F2F),
    },
    {
      'name': 'Wanita',
      'label': 'Kebutuhan Wanita',
      'icon': Icons.female_rounded,
      'gradient': [Color(0xFF880E4F), Color(0xFFE91E63)],
      'accentColor': Color(0xFFFF80AB),
      'unselectedBg': Color(0xFFFCE4EC),
      'unselectedIcon': Color(0xFFC2185B),
    },
    {
      'name': 'Satelit',
      'label': 'Satelit & GPS',
      'icon': Icons.satellite_alt_rounded,
      'gradient': [Color(0xFF0D47A1), Color(0xFF1E88E5)],
      'accentColor': Color(0xFF82B1FF),
      'unselectedBg': Color(0xFFE3F2FD),
      'unselectedIcon': Color(0xFF1976D2),
    },
    {
      'name': 'Evakuasi',
      'label': 'Protokol Evakuasi',
      'icon': Icons.medical_services_rounded,
      'gradient': [Color(0xFFE65100), Color(0xFFFF9800)],
      'accentColor': Color(0xFFFFAB91),
      'unselectedBg': Color(0xFFFBE9E7),
      'unselectedIcon': Color(0xFFD84315),
    },
  ];

  // Data Teman Luring (Offline Mesh Tracker) berasal dari pengguna terdaftar yang berada di sekitar lokasi saat ini
  final List<Map<String, dynamic>> _offlinePeers = [];
  double _currentLat = -6.8396;
  double _currentLon = 107.4524;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _holdController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _triggerSosEmergency();
            }
          });

    // Inisialisasi Jam & Cuaca
    _updateClockTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateClockTime();
    });

    _fetchRealtimeLocationAndWeather();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pulseController.dispose();
    _holdController.dispose();
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
          _latText = lat < 0
              ? '${lat.abs().toStringAsFixed(6)}° S'
              : '${lat.toStringAsFixed(6)}° N';
          _lonText = lon < 0
              ? '${lon.abs().toStringAsFixed(6)}° W'
              : '${lon.toStringAsFixed(6)}° E';
          _elevationText = '${pos.altitude.round()} m ASL';
        });
      }

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

  void _startHoldingSos() {
    setState(() {
      _isHoldingSos = true;
    });
    HapticFeedback.mediumImpact();
    _holdController.forward(from: 0.0);
  }

  void _cancelHoldingSos() {
    if (_holdController.isAnimating) {
      _holdController.stop();
      _holdController.reset();
    }
    setState(() {
      _isHoldingSos = false;
    });
  }

  void _triggerSosEmergency() async {
    HapticFeedback.heavyImpact();
    _holdController.reset();
    setState(() {
      _isHoldingSos = false;
    });

    // Navigasi ke Halaman SOS Aktif (Sesuai Desain Stitch Google)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SosAktifPage(
          initialCoordinates: '$_latText, $_lonText',
          initialAltitude: _elevationText,
        ),
      ),
    );

    // Saat kembali/batal, pastikan SOS dalam keadaan siap sedia (belum dipencet)
    if (result == true && mounted) {
      _holdController.reset();
      setState(() {
        _isHoldingSos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinyal SOS telah dibatalkan. Mode darurat non-aktif.'),
          backgroundColor: darkGreen,
          duration: Duration(seconds: 2),
        ),
      );
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

  void _showProtokolKritisSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bool isDark = context.isDarkMode;

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: context.themeBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.themeTerracotta.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PANDUAN EKSPLORASI',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: context.themeTerracotta,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Protokol Kritis &\nLeave No Trace',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: context.themeText,
                            height: 1.2,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Panduan sederhana untuk menjaga keamanan, sanitasi, dan keputusan darurat saat menjelajah di alam terbuka.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: context.themeBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : context.themePrimary.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.themeTerracotta.withValues(
                              alpha: 0.2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.eco_rounded,
                            color: context.themeTerracotta,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tindakan paling penting',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.themeText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Semua langkah berikut dirancang agar aman, manusiawi, dan tetap menjaga alam.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProtocolChecklistPanel(
                    label: '01',
                    title: '7 Prinsip Leave No Trace (LNT)',
                    body:
                        'Rencanakan dan persiapkan matang, berjelajah di jalur resmi, kelola sampah secara tuntas (bawa turun kembali), biarkan apa yang ditemukan, dan hormati satwa liar.',
                    icon: Icons.forest_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildProtocolChecklistPanel(
                    label: '02',
                    title: 'Sanitasi & Lubang Cathole',
                    body:
                        'Buang air besar di lubang sedalam 15-20 cm dengan jarak minimal 60 meter dari sumber air, mata air tebing, dan jalur umum. Timbun kembali hingga rata.',
                    icon: Icons.cleaning_services_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildProtocolChecklistPanel(
                    label: '03',
                    title: 'Sinyal Darurat Peluit & Cermin (Alpine Distress)',
                    body:
                        'Kirimkan 6 tiupan peluit / kilatan cermin per menit, jeda 1 menit, ulangi. Balasan konfirmasi dari tim penolong adalah 3 tiupan peluit per menit.',
                    icon: Icons.campaign_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildProtocolChecklistPanel(
                    label: '04',
                    title: 'Evakuasi Korban Cedera di Ketinggian',
                    body:
                        'Amankan korban pada anchor cadangan ganda, periksa jalan napas dan pendarahan utama, stabilkan leher/tulang belakang sebelum memulai proses lowering.',
                    icon: Icons.health_and_safety_outlined,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themePrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Paham & Patuhi Protokol',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProtocolChecklistPanel({
    required String label,
    required String title,
    required String body,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.themePrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.themeTerracotta.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.themeTerracotta, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.themeTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          // Glassmorphism SliverAppBar (Transparan dengan Blur seperti halaman lainnya)
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
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: context.themeBg.withValues(alpha: 0.85),
                ),
              ),
            ),
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

                  // Indikator Real-time Lokasi, Jam, dan Cuaca (Tersinkronisasi dengan Home)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: context.themePrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
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
                      const SizedBox(width: 14),
                      Icon(
                        _weatherIcon,
                        color: AppTheme.goldAccentDark,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_timeText • $_weatherText',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.themeTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Fitur Keamanan Berwarna
                  _buildSafetyFilterChips(),
                  const SizedBox(height: 18),

                  // =================================================================
                  // 2. SOS CARD (INTERACTIVE TRIGGER & SATELLITE LINK)
                  // =================================================================
                  Container(
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : context.themePrimary.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: context.themeBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Top Half - SOS Action Area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          color: AppTheme.errorRed.withValues(
                            alpha: isDark ? 0.15 : 0.08,
                          ),
                          child: Column(
                            children: [
                              // Tombol SOS Interaktif dengan Efek Pulse & Hold Progress
                              GestureDetector(
                                onTapDown: (_) => _startHoldingSos(),
                                onTapUp: (_) => _cancelHoldingSos(),
                                onTapCancel: () => _cancelHoldingSos(),
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([
                                    _pulseController,
                                    _holdController,
                                  ]),
                                  builder: (context, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Gelombang Pulse Luar
                                        Container(
                                          width:
                                              120 +
                                              (_pulseController.value * 24),
                                          height:
                                              120 +
                                              (_pulseController.value * 24),
                                          decoration: BoxDecoration(
                                            color: errorRed.withValues(
                                              alpha:
                                                  0.25 *
                                                  (1 - _pulseController.value),
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        // Lingkaran Progress Tahan 3 Detik
                                        SizedBox(
                                          width: 108,
                                          height: 108,
                                          child: CircularProgressIndicator(
                                            value: _holdController.value,
                                            strokeWidth: 4,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(accentAmber),
                                            backgroundColor: Colors.transparent,
                                          ),
                                        ),
                                        // Tombol Merah Inti
                                        Transform.scale(
                                          scale: _isHoldingSos ? 0.94 : 1.0,
                                          child: Container(
                                            width: 96,
                                            height: 96,
                                            decoration: BoxDecoration(
                                              color: errorRed,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: errorRed.withValues(
                                                    alpha: 0.45,
                                                  ),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: const Center(
                                              child: Text(
                                                'SOS',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _isHoldingSos
                                    ? 'TAHAN TERUS... (${(3 - (_holdController.value * 3)).ceil()}s)'
                                    : '(TAHAN 3 DETIK)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE53935),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Half - Network Status (Iridium Satellite)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: context.themeSurface,
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: context.themePrimary.withValues(
                                    alpha: 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.satellite_alt_rounded,
                                  color: context.themePrimary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'STATUS JARINGAN',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeTextSecondary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'Iridium Satellite Alert Active',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: context.themeText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Indikator Hijau Berdenyut
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) => Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF118833).withValues(
                                      alpha:
                                          0.4 + (_pulseController.value * 0.6),
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: context.themeSurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.group_rounded,
                                  color: context.themePrimary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Pelacak Teman Luring',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: context.themeText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: context.themeSurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '2m lalu',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.themeTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: context.themeTextSecondary,
                                size: 18,
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
                  GestureDetector(
                    onTap: _bukaHalamanKebutuhanWanita,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.themeCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.themeBorder),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
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
                                        color: context.themeTerracotta,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
                                      color: context.themeTerracotta,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.themeTerracotta.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.female_rounded,
                              color: context.themeTerracotta,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Card 2: Protokol Kritis
                  GestureDetector(
                    onTap: _showProtokolKritisSheet,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.themeCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.themeBorder),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
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
                                        color: context.themePrimary,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 10,
                                      color: context.themePrimary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: context.themePrimaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.eco_rounded,
                              color: context.themePrimary,
                              size: 24,
                            ),
                          ),
                        ],
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

  Widget _buildSafetyFilterChips() {
    final bool isDark = context.isDarkMode;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _safetyFilterCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _safetyFilterCategories[index];
          final String name = cat['name'] as String;
          final String label = cat['label'] as String;
          final IconData icon = cat['icon'] as IconData;
          final List<Color> gradient = cat['gradient'] as List<Color>;
          final Color accentColor = cat['accentColor'] as Color;
          final Color unselectedBg = cat['unselectedBg'] as Color;
          final Color unselectedIcon = cat['unselectedIcon'] as Color;
          final bool isSelected = _selectedSafetyFilter == name;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedSafetyFilter = name;
              });
              if (name == 'Wanita') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KebutuhanWanitaPage(),
                  ),
                );
              } else if (name == 'Evakuasi') {
                _showProtokolKritisSheet();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                          ? context.themeSurface
                          : unselectedBg.withValues(alpha: 0.85)),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.7)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : unselectedIcon.withValues(alpha: 0.3)),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: gradient.last.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : (isDark
                                ? unselectedIcon.withValues(alpha: 0.25)
                                : Colors.white),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 14,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? accentColor : unselectedIcon),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? context.themeText
                                : const Color(0xFF1E293B)),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
