import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/map/screens/interactive_map_screen.dart';

// =========================================================================
// MODEL DATA OFFLINE GIS & TOPOGRAFI
// =========================================================================
class OfflineWaypoint {
  final String id;
  final String name;
  final String note;
  final LatLng location;
  final String coordinatesText;
  final Color color;
  final IconData icon;
  final DateTime createdAt;

  OfflineWaypoint({
    required this.id,
    required this.name,
    required this.note,
    required this.location,
    required this.coordinatesText,
    required this.color,
    required this.icon,
    required this.createdAt,
  });
}

enum MapMode { normal, measure, addWaypoint }

enum CoordFormat { dms, decimal }

// =========================================================================
// HALAMAN PETA VIEWER OFFLINE (FULL-SCREEN OUTDOOR TOPOGRAPHY GIS ENGINE)
// =========================================================================
class PetaViewerPage extends StatefulWidget {
  final String areaName;
  final String? coordinates;
  final String? region;
  final String? elevation;
  final String? type;

  const PetaViewerPage({
    super.key,
    required this.areaName,
    this.coordinates,
    this.region,
    this.elevation,
    this.type,
  });

  @override
  State<PetaViewerPage> createState() => _PetaViewerPageState();
}

class _PetaViewerPageState extends State<PetaViewerPage>
    with SingleTickerProviderStateMixin {
  // Controller Peta
  final MapController _mapController = MapController();
  late AnimationController _pulseController;

  // Warna Standar
  static const Color darkGreen = Color(0xFF001D0F);
  static const Color accentAmber = Color(0xFFFED65B);
  static const Color secondaryColor = Color(0xFF735C00);
  static const Color routeRed = Color(0xFFE53935);
  static const Color userBlue = Color(0xFF1E88E5);

  // Status Lapisan & Tampilan
  bool _showRoute = false;
  bool _showWaypoints = true;
  int _selectedLayerIndex =
      0; // 0: OpenTopoMap, 1: OpenStreetMap, 2: CartoDB Voyager, 3: ESRI Satelit

  final List<Map<String, String>> _mapLayers = [
    {
      'name': 'OpenTopoMap (Topografi & Kontur Ketinggian)',
      'url': 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
      'desc':
          'Peta topografi outdoor dengan garis kontur, relief bukit, dan elevasi',
    },
    {
      'name': 'OpenStreetMap Outdoor Standard',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'desc': 'Peta jalan, jalur setapak trekking, dan bentang alam lengkap',
    },
    {
      'name': 'CartoDB Voyager (Kontras Bersih)',
      'url':
          'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      'desc': 'Tampilan peta modern, bersih, dan jelas terbaca di lapangan',
    },
    {
      'name': 'ESRI Satelit Resolusi Tinggi',
      'url':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'desc': 'Citra satelit permukaan tebing, batuan karst, dan tutupan hutan',
    },
  ];

  // Mode Operasi Peta (Normal, Ukur Jarak, Tambah Waypoint)
  MapMode _currentMode = MapMode.normal;
  CoordFormat _coordFormat = CoordFormat.dms;

  // Titik Target & Koordinat
  late LatLng _targetLocation;
  LatLng? _userLocation;
  Position? _currentGpsPosition;
  double _headingDegrees = 45.0;
  bool _isGpsLocked = false;
  StreamSubscription<Position>? _gpsSubscription;

  // Fitur Rekam Jejak (Record GPS Track / Breadcrumbs)
  bool _isRecordingTrack = false;
  bool _isTrackPaused = false;
  Timer? _trackTimer;
  int _trackDurationSeconds = 0;
  double _trackDistanceMeters = 0.0;
  final List<LatLng> _recordedTrackPoints = [];

  // Fitur Waypoints / Placemarks Tersimpan
  final List<OfflineWaypoint> _savedWaypoints = [];

  // Fitur Alat Ukur Jarak & Sudut (Measure Distance & Bearing)
  final List<LatLng> _measurePoints = [];

  bool get _isGoa =>
      widget.areaName.toLowerCase().contains('goa') ||
      widget.areaName.toLowerCase().contains('karst') ||
      widget.type?.toLowerCase().contains('goa') == true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Inisialisasi Titik Lokasi Target Tebing / Goa
    _initTargetLocation();

    // Inisialisasi Waypoints Bawaan
    _initDefaultWaypoints();

    // Inisialisasi GPS Offline
    _initOfflineGps();
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _trackTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _initTargetLocation() {
    if (widget.coordinates != null) {
      final parsed = PetaInteraktifPage.parseCoordinateString(
        widget.coordinates!,
      );
      if (parsed != null) {
        _targetLocation = parsed;
        return;
      }
    }

    // Default matching lokasi berdasarkan nama spot tebing / goa di Indonesia
    final nameLower = widget.areaName.toLowerCase();
    if (nameLower.contains('citatah 125')) {
      _targetLocation = const LatLng(-6.8396, 107.4524);
    } else if (nameLower.contains('citatah 90')) {
      _targetLocation = const LatLng(-6.8378, 107.4501);
    } else if (nameLower.contains('hawu')) {
      _targetLocation = const LatLng(-6.8320, 107.4470);
    } else if (nameLower.contains('parang')) {
      _targetLocation = const LatLng(-6.5912, 107.3512);
    } else if (nameLower.contains('bongkok')) {
      _targetLocation = const LatLng(-6.6020, 107.3420);
    } else if (nameLower.contains('ciampea')) {
      _targetLocation = const LatLng(-6.5540, 106.6980);
    } else if (nameLower.contains('siung')) {
      _targetLocation = const LatLng(-8.1819, 110.6833);
    } else if (nameLower.contains('harau')) {
      _targetLocation = const LatLng(-0.0987, 100.6653);
    } else if (nameLower.contains('maros')) {
      _targetLocation = const LatLng(-4.9961, 119.6833);
    } else if (nameLower.contains('uluwatu')) {
      _targetLocation = const LatLng(-8.8290, 115.0849);
    } else if (nameLower.contains('jomblang')) {
      _targetLocation = const LatLng(-8.0287, 110.6384);
    } else if (nameLower.contains('pindul')) {
      _targetLocation = const LatLng(-7.9347, 110.6489);
    } else if (nameLower.contains('gong')) {
      _targetLocation = const LatLng(-8.1633, 110.9806);
    } else {
      _targetLocation = const LatLng(
        -6.8396,
        107.4524,
      ); // Default Tebing Citatah
    }
  }

  void _initDefaultWaypoints() {
    _savedWaypoints.addAll([
      OfflineWaypoint(
        id: 'wp_basecamp',
        name: 'Basecamp & Registrasi',
        note: 'Pos perizinan simaksi & titik awal trekking',
        location: LatLng(
          _targetLocation.latitude + 0.0055,
          _targetLocation.longitude - 0.0045,
        ),
        coordinatesText:
            '${(_targetLocation.latitude + 0.0055).toStringAsFixed(5)}, ${(_targetLocation.longitude - 0.0045).toStringAsFixed(5)}',
        color: userBlue,
        icon: Icons.home_rounded,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      OfflineWaypoint(
        id: 'wp_pos1',
        name: 'Pos 1 (Shelter Kayu)',
        note: 'Tempat istirahat & briefing pemanjatan',
        location: LatLng(
          _targetLocation.latitude + 0.0028,
          _targetLocation.longitude - 0.0020,
        ),
        coordinatesText:
            '${(_targetLocation.latitude + 0.0028).toStringAsFixed(5)}, ${(_targetLocation.longitude - 0.0020).toStringAsFixed(5)}',
        color: accentAmber,
        icon: Icons.hiking_rounded,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      OfflineWaypoint(
        id: 'wp_target',
        name: widget.areaName,
        note: widget.elevation ?? 'Titik Utama Pemanjatan/Penelusuran',
        location: _targetLocation,
        coordinatesText:
            widget.coordinates ??
            '${_targetLocation.latitude.toStringAsFixed(5)}, ${_targetLocation.longitude.toStringAsFixed(5)}',
        color: routeRed,
        icon: _isGoa ? Icons.landscape_rounded : Icons.terrain_rounded,
        createdAt: DateTime.now(),
      ),
    ]);
  }

  Future<void> _initOfflineGps() async {
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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentGpsPosition = position;
          _userLocation = userLatLng;
          if (position.heading >= 0) _headingDegrees = position.heading;
        });
      }

      // Dengarkan Gerakan Perangkat GPS Presisi Tinggi
      _gpsSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 1,
            ),
          ).listen((Position pos) {
            if (!mounted) return;
            final newLatLng = LatLng(pos.latitude, pos.longitude);

            setState(() {
              _currentGpsPosition = pos;
              _userLocation = newLatLng;
              if (pos.heading >= 0) _headingDegrees = pos.heading;

              if (_isRecordingTrack && !_isTrackPaused) {
                if (_recordedTrackPoints.isNotEmpty) {
                  final last = _recordedTrackPoints.last;
                  final double d = Geolocator.distanceBetween(
                    last.latitude,
                    last.longitude,
                    newLatLng.latitude,
                    newLatLng.longitude,
                  );
                  _trackDistanceMeters += d;
                }
                _recordedTrackPoints.add(newLatLng);
              }

              if (_isGpsLocked) {
                _mapController.move(newLatLng, _mapController.camera.zoom);
              }
            });
          });
    } catch (_) {}
  }

  void _recenterToTarget() {
    setState(() => _isGpsLocked = false);
    _mapController.move(_targetLocation, 15.0);
  }

  void _recenterToUserGps() {
    if (_userLocation != null) {
      setState(() => _isGpsLocked = true);
      _mapController.move(_userLocation!, 16.0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamera terkunci pada posisi GPS perangkat Anda.'),
          backgroundColor: darkGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _initOfflineGps();
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
  }

  // Rekam Jejak (Record Track)
  void _toggleTrackRecording() {
    if (_isRecordingTrack) {
      _trackTimer?.cancel();
      setState(() {
        _isRecordingTrack = false;
        _isTrackPaused = false;
      });
      _showTrackSummaryModal();
    } else {
      final startPoint = _userLocation ?? _targetLocation;
      setState(() {
        _isRecordingTrack = true;
        _isTrackPaused = false;
        _trackDurationSeconds = 0;
        _trackDistanceMeters = 0.0;
        _recordedTrackPoints.clear();
        _recordedTrackPoints.add(startPoint);
      });

      _trackTimer?.cancel();
      _trackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_isRecordingTrack || _isTrackPaused) return;
        setState(() {
          _trackDurationSeconds++;
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.fiber_manual_record,
                color: Colors.redAccent,
                size: 16,
              ),
              SizedBox(width: 8),
              Text('Perekaman Jejak GPS Offline Aktif'),
            ],
          ),
          backgroundColor: darkGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showTrackSummaryModal() {
    final durationText = _formatDuration(_trackDurationSeconds);
    final distKm = (_trackDistanceMeters / 1000.0).toStringAsFixed(2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: routeRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jejak Trekking Selesai Disimpan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          Text(
                            'Format GPX/KML tersimpan di memori offline',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTrackStatItem(
                        'JARAK',
                        '$distKm km',
                        Icons.straighten,
                      ),
                      _buildTrackStatItem(
                        'DURASI',
                        durationText,
                        Icons.timer_outlined,
                      ),
                      _buildTrackStatItem(
                        'TITIK GPS',
                        '${_recordedTrackPoints.length}',
                        Icons.scatter_plot_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Tutup & Kembali ke Peta',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: darkGreen, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: darkGreen,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Tambah Waypoint pada Peta
  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (_currentMode == MapMode.measure) {
      setState(() {
        _measurePoints.add(point);
      });
    } else if (_currentMode == MapMode.addWaypoint) {
      _showAddWaypointDialog(point);
    }
  }

  void _showAddWaypointDialog(LatLng point) {
    final TextEditingController nameCtrl = TextEditingController(
      text: 'Waypoint ${_savedWaypoints.length + 1}',
    );
    final TextEditingController noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: routeRed),
              SizedBox(width: 8),
              Text(
                'Tambah Waypoint Offline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Titik / Landmark',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Catatan Lapangan (Kondisi/Elevasi)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  setState(() {
                    _savedWaypoints.add(
                      OfflineWaypoint(
                        id: 'wp_${DateTime.now().millisecondsSinceEpoch}',
                        name: nameCtrl.text.trim(),
                        note: noteCtrl.text.trim().isNotEmpty
                            ? noteCtrl.text.trim()
                            : 'Titik singgah koordinat offline',
                        location: point,
                        coordinatesText:
                            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
                        color: routeRed,
                        icon: Icons.pin_drop_rounded,
                        createdAt: DateTime.now(),
                      ),
                    );
                    _currentMode = MapMode.normal;
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Waypoint "${nameCtrl.text.trim()}" berhasil ditambahkan.',
                      ),
                      backgroundColor: darkGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: darkGreen),
              child: const Text(
                'Simpan Waypoint',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _bukaPetaInteraktifLive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetaInteraktifPage(
          initialSpotName: widget.areaName,
          initialCoordinates: widget.coordinates,
          autoStartNavigation: true,
        ),
      ),
    );
  }

  // Hitung total jarak pengukuran
  double _calculateTotalMeasureDistance() {
    if (_measurePoints.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < _measurePoints.length - 1; i++) {
      total += Geolocator.distanceBetween(
        _measurePoints[i].latitude,
        _measurePoints[i].longitude,
        _measurePoints[i + 1].latitude,
        _measurePoints[i + 1].longitude,
      );
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final activeLayer = _mapLayers[_selectedLayerIndex];
    final String currentCoordsDms =
        widget.coordinates ??
        '${_targetLocation.latitude.toStringAsFixed(5)}, ${_targetLocation.longitude.toStringAsFixed(5)}';
    final double elevationMdpl = _currentGpsPosition?.altitude ?? 450.0;
    final double speedKmh = (_currentGpsPosition?.speed ?? 0.0) * 3.6;

    // Garis Rute Pendekatan Tebing (Basecamp -> Checkpoint -> Puncak)
    final List<LatLng> approachRoute = [
      LatLng(
        _targetLocation.latitude + 0.0055,
        _targetLocation.longitude - 0.0045,
      ),
      LatLng(
        _targetLocation.latitude + 0.0040,
        _targetLocation.longitude - 0.0035,
      ),
      LatLng(
        _targetLocation.latitude + 0.0028,
        _targetLocation.longitude - 0.0020,
      ),
      LatLng(
        _targetLocation.latitude + 0.0015,
        _targetLocation.longitude - 0.0008,
      ),
      _targetLocation,
    ];

    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: context.themePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? const Color(0xFF0F1713) : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'OFFLINE',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF0F1713)
                          : AppTheme.goldAccentDark,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    widget.areaName.toUpperCase(),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF0F1713) : Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              currentCoordsDms,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF0F1713).withValues(alpha: 0.75)
                    : Colors.white70,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isDark ? const Color(0xFF0F1713) : AppTheme.goldAccentDark,
              size: 20,
            ),
            tooltip: isDark
                ? 'Beralih ke Mode Terang'
                : 'Beralih ke Mode Gelap',
            onPressed: () => ThemeController.instance.toggleTheme(context),
          ),
          // Kompas Orientasi Arah
          Transform.rotate(
            angle: -_headingDegrees * (math.pi / 180.0),
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.explore_rounded,
                color: isDark
                    ? const Color(0xFF0F1713)
                    : AppTheme.goldAccentDark,
                size: 22,
              ),
              tooltip: 'Orientasi Kompas (${_headingDegrees.round()}°)',
              onPressed: () {
                setState(() => _headingDegrees = 0.0);
              },
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.travel_explore_rounded,
              color: isDark ? const Color(0xFF0F1713) : Colors.white,
              size: 22,
            ),
            tooltip: 'Buka di Peta Live (Online GPS)',
            onPressed: _bukaPetaInteraktifLive,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // ===================================================================
          // 1. ENGINE PETA OFFLINE OPENSTREETMAP / OPENTOPOMAP (FULL SCREEN)
          // ===================================================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _targetLocation,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: _handleMapTap,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture && _isGpsLocked) {
                  setState(() => _isGpsLocked = false);
                }
              },
            ),
            children: [
              // Tile Layer Topografi / Satelit / Outdoor
              TileLayer(
                urlTemplate: activeLayer['url']!,
                userAgentPackageName: 'com.suhlah.nara',
                maxZoom: 19,
              ),

              // Polyline Rute Pendekatan & Jejak GPS
              PolylineLayer(
                polylines: [
                  // Rute Pendekatan Trekking Merah
                  if (_showRoute) ...[
                    Polyline(
                      points: approachRoute,
                      strokeWidth: 7.0,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    Polyline(
                      points: approachRoute,
                      strokeWidth: 4.5,
                      color: routeRed,
                    ),
                  ],

                  // Rekaman Jejak GPS (Breadcrumbs Cyan Glow)
                  if (_recordedTrackPoints.length >= 2) ...[
                    Polyline(
                      points: _recordedTrackPoints,
                      strokeWidth: 6.0,
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    ),
                    Polyline(
                      points: _recordedTrackPoints,
                      strokeWidth: 3.5,
                      color: const Color(0xFF00E5FF),
                    ),
                  ],

                  // Garis Alat Ukur Jarak (Measure Distance)
                  if (_currentMode == MapMode.measure &&
                      _measurePoints.length >= 2)
                    Polyline(
                      points: _measurePoints,
                      strokeWidth: 3.0,
                      color: const Color(0xFF2E7D32),
                    ),
                ],
              ),

              // Jangkauan Radius Akurasi Titik GPS Pengguna (Accuracy Halo)
              if (_userLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _userLocation!,
                      radius: (_currentGpsPosition?.accuracy ?? 0) > 0
                          ? _currentGpsPosition!.accuracy
                          : 12.0,
                      useRadiusInMeter: true,
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                      borderColor: const Color(
                        0xFF1E88E5,
                      ).withValues(alpha: 0.50),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Marker Layer (Waypoints, Target, & User GPS)
              MarkerLayer(
                markers: [
                  // 1. Waypoints Tersimpan
                  if (_showWaypoints)
                    ..._savedWaypoints.map((wp) {
                      final isTarget = wp.id == 'wp_target';

                      return Marker(
                        point: wp.location,
                        width: 120,
                        height: 70,
                        child: GestureDetector(
                          onTap: () => _showWaypointDetailModal(wp),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: darkGreen,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isTarget ? routeRed : Colors.white70,
                                    width: 1,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  wp.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: wp.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  wp.icon,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  // 2. Titik-titik Alat Ukur Jarak (Measure Points)
                  if (_currentMode == MapMode.measure)
                    ..._measurePoints.map((pt) {
                      return Marker(
                        point: pt,
                        width: 20,
                        height: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      );
                    }),

                  // 3. Marker GPS User Live (Pulsing Dot + Heading Cone)
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 54,
                      height: 54,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (ctx, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.rotate(
                                angle: _headingDegrees * (math.pi / 180.0),
                                child: const Icon(
                                  Icons.navigation,
                                  size: 28,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                              Container(
                                width: 22 + (_pulseController.value * 12),
                                height: 22 + (_pulseController.value * 12),
                                decoration: BoxDecoration(
                                  color: userBlue.withValues(
                                    alpha: 0.35 * (1 - _pulseController.value),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: userBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ===================================================================
          // 2. TOP RECORDING / MEASURE BANNER OVERLAY
          // ===================================================================
          if (_isRecordingTrack)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (ctx, child) => Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: routeRed.withValues(
                            alpha: _pulseController.value,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: routeRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDuration(_trackDurationSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(_trackDistanceMeters / 1000.0).toStringAsFixed(2)} km',
                      style: const TextStyle(
                        color: accentAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isTrackPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() => _isTrackPaused = !_isTrackPaused);
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.stop_circle_rounded,
                        color: routeRed,
                        size: 20,
                      ),
                      onPressed: _toggleTrackRecording,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),

          if (_currentMode == MapMode.measure)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.straighten,
                      color: Color(0xFF4CAF50),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total Jarak Ukur: ${(_calculateTotalMeasureDistance() / 1000.0).toStringAsFixed(2)} km (${_measurePoints.length} titik)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _measurePoints.clear()),
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: accentAmber, fontSize: 11),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 16,
                      ),
                      onPressed: () => setState(() {
                        _currentMode = MapMode.normal;
                        _measurePoints.clear();
                      }),
                    ),
                  ],
                ),
              ),
            ),

          // ===================================================================
          // 3. FLOATING TOOLBAR KANAN (OUTDOOR GIS TOOLS)
          // ===================================================================
          Positioned(
            top: _isRecordingTrack || _currentMode == MapMode.measure ? 64 : 16,
            right: 14,
            child: Column(
              children: [
                // Tombol Pusatkan ke Lokasi Target
                _buildMapIconButton(
                  icon: Icons.center_focus_strong_rounded,
                  tooltip: 'Fokus ke ${widget.areaName}',
                  iconColor: routeRed,
                  onTap: _recenterToTarget,
                ),
                const SizedBox(height: 8),

                // Tombol Kunci / Pusatkan GPS Saya
                _buildMapIconButton(
                  icon: _isGpsLocked
                      ? Icons.my_location
                      : Icons.location_searching_rounded,
                  tooltip: 'Pusatkan ke Lokasi GPS Saya',
                  iconColor: _isGpsLocked
                      ? const Color(0xFF1E88E5)
                      : Colors.black87,
                  onTap: _recenterToUserGps,
                ),
                const SizedBox(height: 8),

                // Tombol Rekam Jejak (Record Track)
                _buildMapIconButton(
                  icon: _isRecordingTrack
                      ? Icons.fiber_manual_record
                      : Icons.play_circle_outline_rounded,
                  tooltip: _isRecordingTrack
                      ? 'Perekaman Jejak Aktif'
                      : 'Mulai Rekam Jejak GPS',
                  iconColor: _isRecordingTrack ? routeRed : darkGreen,
                  onTap: _toggleTrackRecording,
                ),
                const SizedBox(height: 8),

                // Tombol Tambah Placemark / Waypoint
                _buildMapIconButton(
                  icon: _currentMode == MapMode.addWaypoint
                      ? Icons.check_circle_rounded
                      : Icons.add_location_alt_outlined,
                  tooltip: 'Tambah Waypoint / Titik Singgah',
                  iconColor: _currentMode == MapMode.addWaypoint
                      ? routeRed
                      : darkGreen,
                  onTap: () {
                    setState(() {
                      _currentMode = _currentMode == MapMode.addWaypoint
                          ? MapMode.normal
                          : MapMode.addWaypoint;
                    });
                    if (_currentMode == MapMode.addWaypoint) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ketuk di peta untuk menambahkan Waypoint.',
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),

                // Tombol Alat Ukur Jarak (Measure Distance)
                _buildMapIconButton(
                  icon: Icons.straighten_rounded,
                  tooltip: 'Ukur Jarak Antar Titik',
                  iconColor: _currentMode == MapMode.measure
                      ? const Color(0xFF2E7D32)
                      : darkGreen,
                  onTap: () {
                    setState(() {
                      _currentMode = _currentMode == MapMode.measure
                          ? MapMode.normal
                          : MapMode.measure;
                      if (_currentMode == MapMode.normal)
                        _measurePoints.clear();
                    });
                  },
                ),
                const SizedBox(height: 8),

                // Tombol Lapisan & Gaya Topografi
                _buildMapIconButton(
                  icon: Icons.layers_outlined,
                  tooltip: 'Ganti Layer Peta Topografi',
                  onTap: _showLayerOptionsModal,
                ),
                const SizedBox(height: 8),

                // Tombol Zoom In & Zoom Out
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: darkGreen, size: 20),
                        onPressed: _zoomIn,
                      ),
                      Container(
                        height: 1,
                        width: 26,
                        color: const Color(0xFFE0DDD5),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          color: darkGreen,
                          size: 20,
                        ),
                        onPressed: _zoomOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 4. BOTTOM GPS HUD BAR (KOORDINAT, ELEVASI, KECEPATAN & SKALA)
          // ===================================================================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: darkGreen.withValues(alpha: 0.98),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _coordFormat = _coordFormat == CoordFormat.dms
                                ? CoordFormat.decimal
                                : CoordFormat.dms;
                          });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.gps_fixed_rounded,
                                  color: Color(0xFF4CAF50),
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _coordFormat == CoordFormat.dms
                                        ? currentCoordsDms
                                        : '${_targetLocation.latitude.toStringAsFixed(5)}, ${_targetLocation.longitude.toStringAsFixed(5)} (WGS84)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Elevasi: ${elevationMdpl.round()} mdpl • Speed: ${speedKmh.toStringAsFixed(1)} km/j • Heading: ${_headingDegrees.round()}°',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Skala Batang Peta Topografi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '100 m',
                            style: TextStyle(
                              color: accentAmber,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            '|-------|',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  void _showWaypointDetailModal(OfflineWaypoint wp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: wp.color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(wp.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wp.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          Text(
                            wp.coordinatesText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  wp.note,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _mapController.move(wp.location, 16.0);
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.center_focus_strong, size: 16),
                        label: const Text('Fokus ke Titik'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _bukaPetaInteraktifLive();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                        ),
                        icon: const Icon(
                          Icons.navigation_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Navigasi Live',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLayerOptionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Pilih Lapisan Peta Topografi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_mapLayers.length, (idx) {
                      final layer = _mapLayers[idx];
                      final isSelected = _selectedLayerIndex == idx;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? darkGreen.withValues(alpha: 0.08)
                              : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? darkGreen : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            idx == 0
                                ? Icons.terrain_rounded
                                : (idx == 3 ? Icons.satellite_alt : Icons.map),
                            color: isSelected ? darkGreen : Colors.black54,
                          ),
                          title: Text(
                            layer['name']!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: darkGreen,
                            ),
                          ),
                          subtitle: Text(
                            layer['desc']!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF616161),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: darkGreen)
                              : null,
                          onTap: () {
                            setState(() => _selectedLayerIndex = idx);
                            setSheetState(() {});
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text(
                        'Garis Rute Pendekatan Merah',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _showRoute,
                      onChanged: (val) {
                        setState(() => _showRoute = val);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: const Text(
                        'Tampilkan Waypoints & Placemarks',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _showWaypoints,
                      onChanged: (val) {
                        setState(() => _showWaypoints = val);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor ?? darkGreen, size: 20),
        ),
      ),
    );
  }
}
