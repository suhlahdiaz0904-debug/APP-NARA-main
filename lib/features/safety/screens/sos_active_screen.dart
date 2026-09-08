import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

// =========================================================================
// HALAMAN SOS AKTIF (STITCH GOOGLE NARA EMERGENCY BROADCAST)
// Node-ID: cf1617730df947b0bb212f0f5313d1ab
// =========================================================================

class SosAktifPage extends StatefulWidget {
  final String? initialCoordinates;
  final String? initialAltitude;

  const SosAktifPage({
    super.key,
    this.initialCoordinates,
    this.initialAltitude,
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

  // Controller Batal Tahan
  late AnimationController _cancelHoldController;
  bool _isHoldingCancel = false;

  String _currentCoordsText = '-6.83960° S, 107.45240° E';
  String _currentAltitudeText = '450 m ASL';

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

    _fetchCurrentGps();

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

  Future<void> _fetchCurrentGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          final latFormatted = pos.latitude < 0
              ? '${pos.latitude.abs().toStringAsFixed(6)}° S'
              : '${pos.latitude.toStringAsFixed(6)}° N';
          final lonFormatted = pos.longitude < 0
              ? '${pos.longitude.abs().toStringAsFixed(6)}° W'
              : '${pos.longitude.toStringAsFixed(6)}° E';
          _currentCoordsText = '$latFormatted, $lonFormatted';
          _currentAltitudeText = '${pos.altitude.round()} m ASL';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController1.dispose();
    _pulseController2.dispose();
    _pulseController3.dispose();
    _cancelHoldController.dispose();
    super.dispose();
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

  void _cancelSosAndExit() {
    HapticFeedback.mediumImpact();
    Navigator.pop(context, true); // Return true indicating cancelled
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
                      // 1. CENTRAL ALERT TRIPLE PULSE
                      // =======================================================
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse Layer 3
                            _buildPulseCircle(_pulseController3),
                            // Pulse Layer 2
                            _buildPulseCircle(_pulseController2),
                            // Pulse Layer 1
                            _buildPulseCircle(_pulseController1),
                            // Central SOS Button
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                color: errorRed,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: errorContainer.withValues(alpha: 0.25),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: errorRed.withValues(alpha: 0.6),
                                    blurRadius: 30,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

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
                          ],
                        ),
                      ),
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
