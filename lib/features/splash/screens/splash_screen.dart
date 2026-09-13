import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/screens/home_screen.dart';

// =========================================================================
// HALAMAN PEMBUKA AWAL (SPLASH SCREEN RESMI NARA - NUSANTARA ADVENTURE)
// =========================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  String _loadingStatus = 'Menyiapkan modul navigasi satelit...';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animController.forward();

    // Timer simulasi status pemuatan dan navigasi otomatis ke halaman beranda
    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _loadingStatus = 'Sinkronisasi koordinat GPS & data cuaca...';
        });
      }
    });

    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _loadingStatus = 'Mempersiapkan petualangan Anda...';
        });
      }
    });

    Timer(const Duration(milliseconds: 2800), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const NaraHomePage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1811), // Deep Forest Obsidian
      body: Stack(
        children: [
          // Background Atmospheric Gradient & Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 1.1,
                  colors: [
                    Color(0xFF1B4332), // Emerald Forest
                    Color(0xFF0F2B1D),
                    Color(0xFF07140E), // Obsidian Dark
                  ],
                ),
              ),
            ),
          ),

          // Dekorasi Lingkaran Cahaya Halus di Belakang Logo
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFED65B).withValues(alpha: 0.14),
                    const Color(0xFF2E7D32).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Konten Utama Splash
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // Logo NARA dengan Animasi Fade & Scale
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _animController.value > 0.7
                                ? _pulseAnimation.value
                                : _scaleAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: 255,
                        height: 255,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFED65B).withValues(alpha: 0.25),
                              blurRadius: 40,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon/ikonnara.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const CustomNaraLogoPainterWidget();
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Teks Judul Utama NARA
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'N A R A',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Color(0xFFFED65B),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'NUSANTARA ADVENTURE RISK AWARENESS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: const Color(0xFFFED65B).withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sistem Keselamatan, Peta & Navigasi Petualang',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Indikator Loading & Status Inisialisasi
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Container(
                            width: 150,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFED65B).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: const LinearProgressIndicator(
                                minHeight: 6,
                                borderRadius: BorderRadius.all(Radius.circular(100)),
                                backgroundColor: Color(0xFF133224),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFED65B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _loadingStatus,
                              key: ValueKey(_loadingStatus),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// WIDGET VEKTOR FALLBACK LOGO NARA (TEBING, PENDAKI & KOMPAS)
// =========================================================================
class CustomNaraLogoPainterWidget extends StatelessWidget {
  const CustomNaraLogoPainterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(180, 180),
      painter: _NaraLogoPainter(),
    );
  }
}

class _NaraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintWhite = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintAccent = Paint()
      ..color = const Color(0xFFD4A373)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // 1. Gambar Siluet Tebing Karst
    final cliffPath = Path();
    cliffPath.moveTo(w * 0.15, h * 0.65);
    cliffPath.lineTo(w * 0.28, h * 0.42);
    cliffPath.lineTo(w * 0.45, h * 0.22);
    cliffPath.lineTo(w * 0.58, h * 0.26);
    cliffPath.lineTo(w * 0.68, h * 0.48);
    cliffPath.lineTo(w * 0.52, h * 0.65);
    cliffPath.close();
    canvas.drawPath(cliffPath, paintWhite);

    // Garis Kontur Celah Tebing Aksen
    final crackPath = Path();
    crackPath.moveTo(w * 0.45, h * 0.26);
    crackPath.quadraticBezierTo(w * 0.48, h * 0.42, w * 0.52, h * 0.55);
    canvas.drawPath(crackPath, paintAccent);

    // 2. Gambar Pendaki (Climber)
    // Kepala
    canvas.drawCircle(Offset(w * 0.66, h * 0.18), w * 0.042, paintWhite);
    // Badan & Kaki Pendaki
    final climberPath = Path();
    climberPath.moveTo(w * 0.66, h * 0.23);
    climberPath.lineTo(w * 0.62, h * 0.32);
    climberPath.lineTo(w * 0.55, h * 0.35); // Tangan meraih tebing
    climberPath.moveTo(w * 0.62, h * 0.32);
    climberPath.lineTo(w * 0.68, h * 0.40); // Kaki menumpu
    canvas.drawPath(climberPath, paintWhite);

    // 3. Gambar Mawar Kompas (Compass Rose)
    final centerCompass = Offset(w * 0.66, h * 0.66);
    final compassRadius = w * 0.22;

    // Lingkaran Luar Kompas
    canvas.drawCircle(centerCompass, compassRadius, paintWhite);
    canvas.drawCircle(centerCompass, compassRadius * 0.72, paintWhite);

    // Jarum Bintang Kompas (8 Arah Mata Angin)
    final starPath = Path();
    // Arah Utara - Selatan
    starPath.moveTo(centerCompass.dx, centerCompass.dy - compassRadius * 1.15);
    starPath.lineTo(centerCompass.dx + compassRadius * 0.2, centerCompass.dy);
    starPath.lineTo(centerCompass.dx, centerCompass.dy + compassRadius * 1.15);
    starPath.lineTo(centerCompass.dx - compassRadius * 0.2, centerCompass.dy);
    starPath.close();

    // Arah Timur - Barat
    starPath.moveTo(centerCompass.dx - compassRadius * 1.15, centerCompass.dy);
    starPath.lineTo(centerCompass.dx, centerCompass.dy + compassRadius * 0.2);
    starPath.lineTo(centerCompass.dx + compassRadius * 1.15, centerCompass.dy);
    starPath.lineTo(centerCompass.dx, centerCompass.dy - compassRadius * 0.2);
    starPath.close();

    canvas.drawPath(starPath, paintWhite);

    // Titik Pusat Kompas
    canvas.drawCircle(centerCompass, w * 0.024, paintAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
