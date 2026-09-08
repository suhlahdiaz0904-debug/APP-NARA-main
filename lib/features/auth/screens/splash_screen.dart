import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/screens/onboarding_screen.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _isNavigated = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAndPlayVideo();
  }

  Future<void> _initializeAndPlayVideo() async {
    final controller = VideoPlayerController.asset(
      'assets/videos/opening1.mp4',
    );
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(false);
      // Volume 1.0 (jika autoplay di web terhalang, fallback timer akan tetap berjalan)
      await controller.setVolume(1.0);
      await controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }

      // Listener saat video selesai diputar
      controller.addListener(() {
        if (controller.value.isInitialized &&
            controller.value.position >= controller.value.duration &&
            controller.value.duration > Duration.zero &&
            !_isNavigated) {
          _goToNextScreen();
        }
      });

      // Timer aman jika video selesai
      final duration = controller.value.duration;
      final waitDuration = duration.inMilliseconds > 0
          ? duration + const Duration(milliseconds: 400)
          : const Duration(seconds: 4);

      Future.delayed(waitDuration, () {
        if (!_isNavigated && mounted) {
          _goToNextScreen();
        }
      });
    } catch (e) {
      // Fallback jika video gagal dimuat
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isNavigated && mounted) {
          _goToNextScreen();
        }
      });
    }
  }

  void _goToNextScreen() {
    if (_isNavigated) return;
    _isNavigated = true;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingPage(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth > 400 ? 300 : screenWidth * 0.78;
    final double videoAspect =
        (controller != null &&
            _isInitialized &&
            controller.value.isInitialized &&
            controller.value.aspectRatio > 0)
        ? controller.value.aspectRatio
        : (16 / 9);
    final double cardHeight = cardWidth / videoAspect;

    return Scaffold(
      backgroundColor: const Color(0xFF0C140F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Tampilan Video Player Pas Proporsi (Perfect Fit & Proportion)
          Center(
            child: GestureDetector(
              onTap: _goToNextScreen,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller != null &&
                      _isInitialized &&
                      controller.value.isInitialized)
                    Container(
                      width: cardWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4CAF78,
                            ).withValues(alpha: 0.22),
                            blurRadius: 36,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: cardWidth,
                      height: cardWidth * 0.65,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF4CAF78),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Teks NARA & Subtitle
                  const Text(
                    'NARA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nusantara Adventure Risk Awareness',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Tombol Lewati / Skip di Pojok Kanan Atas
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: GestureDetector(
              onTap: _goToNextScreen,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lewati',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 11,
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
}
