import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/auth/screens/login_screen.dart';
import 'package:flutter_application_1/features/auth/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/features/auth/screens/register_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Memanjat Layaknya Warga Lokal',
      'subtitle': 'Temukan rute tersembunyi & jelajahi dengan aman',
      'image': 'assets/images/citatah.jpeg',
    },
    {
      'title': 'Rencanakan Perjalanan Anda',
      'subtitle': 'Ubah perjalanan Anda menjadi petualangan epik',
      'image': 'assets/images/goa.jpg',
    },
    {
      'title': 'Selamat Datang',
      'subtitle': 'Halo! Kami di sini siap membantu Anda',
      'image': 'assets/images/mountains.jpg',
    },
  ];

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Tugas12LoginPage()),
    );
  }

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Tugas12RegisterPage()),
    );
  }

  void _goToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Tugas12ForgotPassword()),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. PageView Background Images, Logo, & Main Top Headlines
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildBackgroundImage(index, slide['image']!),
                  _buildGradientOverlay(index),
                  _buildNaraLogo(),
                  _buildSlideTextContent(index, slide),
                ],
              );
            },
          ),

          // 2. Fixed Bottom Section
          _buildUnifiedBottomSection(),
        ],
      ),
    );
  }

  // --- Helper Widgets to Simplify and Modularize Code ---

  Widget _buildBackgroundImage(int index, String imagePath) {
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: index == 0
            ? const Color(0xFF2B1A14)
            : index == 1
            ? const Color(0xFF142430)
            : const Color(0xFF101B14),
      ),
    );
  }

  Widget _buildGradientOverlay(int index) {
    final bool isWelcome = index == 2;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWelcome
              ? [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.85),
                  Colors.black,
                ]
              : [
                  Colors.black.withValues(alpha: 0.70),
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.40),
                  Colors.black.withValues(alpha: 0.85),
                ],
          stops: isWelcome
              ? const [0.0, 0.40, 0.75, 1.0]
              : const [0.0, 0.40, 0.70, 1.0],
        ),
      ),
    );
  }

  Widget _buildSlideTextContent(int index, Map<String, String> slide) {
    final String title = slide['title'] ?? '';
    final String subtitle = slide['subtitle'] ?? '';

    const shadowStyle = [
      Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2)),
    ];

    return Positioned(
      top: MediaQuery.of(context).padding.top + 110,
      left: 28,
      right: 28,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title (Di Atas, Rata Tengah)
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
              height: 1.25,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 14,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            // Subtitle (Di Bawah, Rata Tengah)
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
                letterSpacing: 0.2,
                shadows: shadowStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNaraLogo() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 0,
      right: 0,
      child: Center(
        child: Image.asset(
          'assets/images/logo.png',
          height: 85,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildUnifiedBottomSection() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 24,
      left: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwipeIndicator(),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_slides.length, (i) {
          final bool isActive = i == _currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isActive
                  ? (i == _slides.length - 1
                        ? const Icon(
                            Icons.check_circle_rounded,
                            key: ValueKey('check'),
                            color: Color(0xFF4CAF78),
                            size: 18,
                          )
                        : const Icon(
                            Icons.terrain_rounded,
                            key: ValueKey('terrain'),
                            color: Color(0xFF4CAF78),
                            size: 18,
                          ))
                  : Container(
                      key: ValueKey('dot_$i'),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.40),
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isLastPage = _currentPage >= _slides.length - 1;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLastPage ? _buildWelcomeButtons() : _buildNextButton(),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      key: const ValueKey('next_button'),
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5A43),
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: const Color(0xFF4CAF78).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SELANJUTNYA',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeButtons() {
    return Column(
      key: const ValueKey('welcome_buttons'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Tombol Create Account (Solid Emerald NARA)
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _goToRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5A43),
              foregroundColor: Colors.white,
              elevation: 5,
              shadowColor: const Color(0xFF4CAF78).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Buat Akun',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Tombol Log In (Outlined Emerald Sage)
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: _goToLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF14241C).withValues(alpha: 0.6),
              side: const BorderSide(color: Color(0xFF4CAF78), width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Masuk',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Link Forgot Password?
        Center(
          child: GestureDetector(
            onTap: _goToForgotPassword,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Text(
                'Lupa Password?',
                style: TextStyle(
                  color: Color(0xFF4CAF78),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  letterSpacing: 0.3,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
