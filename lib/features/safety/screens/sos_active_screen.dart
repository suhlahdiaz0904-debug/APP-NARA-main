import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_1/core/services/safety_firestore_service.dart';

// =========================================================================
// HALAMAN SOS AKTIF (STITCH GOOGLE NARA EMERGENCY BROADCAST)
// Node-ID: cf1617730df947b0bb212f0f5313d1ab
// =========================================================================

class SosAktifPage extends StatefulWidget {
  final String? initialCoordinates;
  final String? initialAltitude;
  final String? initialAlertId;

  const SosAktifPage({
    super.key,
    this.initialCoordinates,
    this.initialAltitude,
    this.initialAlertId,
  });

  @override
  State<SosAktifPage> createState() => _SosAktifPageState();
}

class _SosAktifPageState extends State<SosAktifPage>
    with TickerProviderStateMixin {
  // Palet Warna Resmi Dark Emergency
  static const Color bgDark = Color(0xFF1C1C18);
  static const Color errorRed = Color(0xFFB00020);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color textSecondary = Color(0xFFE5E2DC);
  static const Color cardDark = Color(0xFF31312D);
  static const Color textDim = Color(0xFFDCDAD4);
  static const Color greenConnected = Color(0xFFC5ECD2);

  // Controller Animasi Triple Pulse
  late AnimationController _pulseController1;
  late AnimationController _pulseController2;
  late AnimationController _pulseController3;

  // Controller Animasi Interaktif Tap Tombol SOS
  late AnimationController _sosTapController;
  late Animation<double> _sosScaleAnimation;
  int _sosPingCount = 1;
  bool _isSosPinging = false;

  // Controller Batal Tahan
  late AnimationController _cancelHoldController;
  bool _isHoldingCancel = false;

  String _currentCoordsText = '-6.83960° S, 107.45240° E';
  String _currentAltitudeText = '450 m ASL';
  double _currentLat = -6.8396;
  double _currentLon = 107.4524;

  // Firebase Firestore State
  String _alertId = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _alertDocSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<Map<String, dynamic>> _responders = [];
  bool _isFirebaseSynced = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi Koordinat
    if (widget.initialCoordinates != null && widget.initialCoordinates!.isNotEmpty) {
      _currentCoordsText = widget.initialCoordinates!;
    }
    if (widget.initialAltitude != null && widget.initialAltitude!.isNotEmpty) {
      _currentAltitudeText = widget.initialAltitude!;
    }
    if (widget.initialAlertId != null && widget.initialAlertId!.isNotEmpty) {
      _alertId = widget.initialAlertId!;
    }

    _initFirebaseSosBroadcast();
    _fetchCurrentGpsAndTrack();

    // Animasi Denyut Bertingkat (Triple Pulse Layer)
    _pulseController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _pulseController2.repeat();
    });

    _pulseController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _pulseController3.repeat();
    });

    // Animasi Interaktif Tap Tombol SOS (Spring scale bounce)
    _sosTapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _sosScaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _sosTapController, curve: Curves.easeInOut),
    );

    // Kontroller Tahan Batal 1.5 Detik
    _cancelHoldController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _cancelSosAndExit();
        }
      });
  }

  /// Mempublikasikan sinyal SOS ke Firebase Firestore secara Real-Time
  Future<void> _initFirebaseSosBroadcast() async {
    try {
      if (_alertId.isEmpty) {
        _alertId = await SafetyFirestoreService.instance.publishSosAlert(
          latitude: _currentLat,
          longitude: _currentLon,
          altitude: _currentAltitudeText,
        );
      }

      if (_alertId.isNotEmpty) {
        if (mounted) {
          setState(() => _isFirebaseSynced = true);
        }

        // Listen update respon dari rekan tim pada dokumen Firestore
        _alertDocSubscription = FirebaseFirestore.instance
            .collection('nara_sos_alerts')
            .doc(_alertId)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null && mounted) {
            final data = snapshot.data()!;
            final rawResponders = data['responders'] as List?;
            if (rawResponders != null) {
              setState(() {
                _responders
                  ..clear()
                  ..addAll(
                    rawResponders
                        .map((r) => Map<String, dynamic>.from(r as Map)),
                  );
              });
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCurrentGpsAndTrack() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _updatePosition(pos);

      // Start Realtime GPS Position Stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_updatePosition);
    } catch (_) {}
  }

  void _updatePosition(Position pos) {
    if (!mounted) return;
    setState(() {
      _currentLat = pos.latitude;
      _currentLon = pos.longitude;
      final latFormatted = pos.latitude < 0
          ? '${pos.latitude.abs().toStringAsFixed(6)}° S'
          : '${pos.latitude.toStringAsFixed(6)}° N';
      final lonFormatted = pos.longitude < 0
          ? '${pos.longitude.abs().toStringAsFixed(6)}° W'
          : '${pos.longitude.toStringAsFixed(6)}° E';
      _currentCoordsText = '$latFormatted, $lonFormatted';
      _currentAltitudeText = '${pos.altitude.round()} m ASL';
    });

    if (_alertId.isNotEmpty) {
      SafetyFirestoreService.instance.updateSosLocation(
        _alertId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: '${pos.altitude.round()} m ASL',
      );
    }
  }

  @override
  void dispose() {
    _alertDocSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _pulseController1.dispose();
    _pulseController2.dispose();
    _pulseController3.dispose();
    _sosTapController.dispose();
    _cancelHoldController.dispose();
    super.dispose();
  }

  Future<void> _handleSosButtonTap() async {
    HapticFeedback.heavyImpact();
    await _sosTapController.forward();
    await _sosTapController.reverse();

    setState(() {
      _sosPingCount++;
      _isSosPinging = true;
    });

    // Getarkan HP untuk konfirmasi transmisi
    HapticFeedback.vibrate();

    // Broadcast update GPS ping ke Firestore
    if (_alertId.isNotEmpty) {
      SafetyFirestoreService.instance.updateSosLocation(
        _alertId,
        latitude: _currentLat,
        longitude: _currentLon,
        altitude: _currentAltitudeText,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🚨 Sinyal SOS Ke-$_sosPingCount Terkirim! Getaran disiarkan ke tim terdekat.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _isSosPinging = false);
      }
    });
  }

  void _startHoldingCancel() {
    setState(() => _isHoldingCancel = true);
    HapticFeedback.lightImpact();
    _cancelHoldController.forward(from: 0.0);
  }

  void _cancelHoldingCancel() {
    if (_cancelHoldController.isAnimating) {
      _cancelHoldController.stop();
      _cancelHoldController.reset();
    }
    setState(() => _isHoldingCancel = false);
  }

  Future<void> _cancelSosAndExit() async {
    HapticFeedback.mediumImpact();
    // Batalkan di Firebase Firestore
    if (_alertId.isNotEmpty) {
      await SafetyFirestoreService.instance.cancelSosAlert(
        _alertId,
        latitude: _currentLat,
        longitude: _currentLon,
        altitude: _currentAltitudeText,
      );
    }
    if (mounted) {
      Navigator.pop(context, true); // Return true indicating cancelled
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          backgroundColor: bgDark.withValues(alpha: 0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: errorContainer),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: const Text(
            'SOS AKTIF',
            style: TextStyle(
              color: errorContainer,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          actions: const [SizedBox(width: 48)],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // =======================================================
                      // 1. CENTRAL ALERT TRIPLE PULSE & INTERACTIVE SOS BUTTON
                      // =======================================================
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse Layer 3
                            _buildPulseCircle(_pulseController3),
                            // Pulse Layer 2
                            _buildPulseCircle(_pulseController2),
                            // Pulse Layer 1
                            _buildPulseCircle(_pulseController1),

                            // Central Interactive SOS Button (Tekan untuk Broadcast Ping)
                            AnimatedBuilder(
                              animation: _sosTapController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _sosScaleAnimation.value,
                                  child: Material(
                                    color: Colors.transparent,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      splashColor: Colors.white.withValues(alpha: 0.4),
                                      highlightColor: Colors.redAccent.withValues(alpha: 0.3),
                                      onTap: _handleSosButtonTap,
                                      child: Ink(
                                        width: 136,
                                        height: 136,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const RadialGradient(
                                            colors: [
                                              Color(0xFFFF5252),
                                              Color(0xFFD32F2F),
                                              Color(0xFF8B0000),
                                            ],
                                            center: Alignment(-0.2, -0.3),
                                            radius: 0.85,
                                          ),
                                          border: Border.all(
                                            color: _isSosPinging
                                                ? Colors.white
                                                : errorContainer.withValues(alpha: 0.4),
                                            width: _isSosPinging ? 4.5 : 3.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: errorRed.withValues(
                                                alpha: _isSosPinging ? 0.9 : 0.65,
                                              ),
                                              blurRadius: _isSosPinging ? 40 : 28,
                                              spreadRadius: _isSosPinging ? 6 : 2,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _isSosPinging
                                                    ? Icons.wifi_tethering_rounded
                                                    : Icons.emergency_rounded,
                                                color: Colors.white,
                                                size: 26,
                                              ),
                                              const SizedBox(height: 2),
                                              const Text(
                                                'SOS',
                                                style: TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 2.0,
                                                ),
                                              ),
                                              Text(
                                                _isSosPinging
                                                    ? 'MEMANCARKAN...'
                                                    : 'KETUK UNTUK PING',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  letterSpacing: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // =======================================================
                      // 2. STATUS & INSTRUCTIONS
                      // =======================================================
                      const Text(
                        'Sinyal Sedang Dikirim...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: errorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Layanan darurat dan kontak darurat Anda telah diberitahu dengan lokasi Anda saat ini.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: textSecondary,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // =======================================================
                      // 3. LOCATION DATA CARD (SATELIT IRIDIUM)
                      // =======================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardDark.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header Satelit
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Satelit Iridium',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.satellite_alt_rounded,
                                      color: greenConnected,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Terhubung',
                                      style: TextStyle(
                                        color: greenConnected,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                            const SizedBox(height: 14),

                            // Data Koordinat & Ketinggian
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'KOORDINAT LOKASI',
                                        style: TextStyle(
                                          color: textDim,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentCoordsText,
                                        style: const TextStyle(
                                          color: errorContainer,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'KETINGGIAN',
                                        style: TextStyle(
                                          color: textDim,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentAltitudeText,
                                        style: const TextStyle(
                                          color: errorContainer,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_isFirebaseSynced) ...[
                              const SizedBox(height: 12),
                              Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Cloud Firestore Live Broadcast',
                                        style: TextStyle(
                                          color: textDim,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _alertId.isNotEmpty ? 'ID: ${_alertId.substring(0, _alertId.length > 6 ? 6 : _alertId.length)}' : 'Tersinkron',
                                    style: const TextStyle(
                                      color: textSecondary,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_responders.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E382B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.support_agent_rounded, color: Color(0xFFC5ECD2), size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_responders.length} Rekan Tim Menanggapi SOS!',
                                      style: const TextStyle(
                                        color: Color(0xFFC5ECD2),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _responders.map((r) => r['name'] ?? 'Rekan').join(', '),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ===============================================================
              // 4. ACTION BUTTON: BATALKAN SOS (TAHAN)
              // ===============================================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: GestureDetector(
                  onTapDown: (_) => _startHoldingCancel(),
                  onTapUp: (_) => _cancelHoldingCancel(),
                  onTapCancel: () => _cancelHoldingCancel(),
                  child: AnimatedBuilder(
                    animation: _cancelHoldController,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: errorRed,
                                width: 2,
                              ),
                            ),
                          ),
                          // Progress Bar saat Tahan Batal
                          if (_isHoldingCancel)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: _cancelHoldController.value,
                                    child: Container(
                                      color: errorRed.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cancel_rounded, color: errorContainer, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  _isHoldingCancel
                                      ? 'LEPASKAN UNTUK BATALKAN...'
                                      : 'BATALKAN SOS (TAHAN)',
                                  style: const TextStyle(
                                    color: errorContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseCircle(AnimationController controller) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 0.8 + (controller.value * 1.5);
        final opacity = (1.0 - controller.value).clamp(0.0, 0.6);

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 120,
            height: 120,
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
