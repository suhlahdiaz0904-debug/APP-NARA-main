import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/auth/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/features/home/screens/home_screen.dart';
import 'package:flutter_application_1/features/auth/screens/register_screen.dart';
import 'package:flutter_application_1/features/profile/screens/privacy_policy_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';

class Tugas12LoginPage extends StatefulWidget {
  const Tugas12LoginPage({super.key});

  @override
  State<Tugas12LoginPage> createState() => _Tugas12LoginPageState();
}

class _Tugas12LoginPageState extends State<Tugas12LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final user = await DatabaseHelper.instance.loginUser(email, password);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selamat Datang Kembali, ${user.nama}!',
            ),
            backgroundColor: const Color(0xFF2D5A43),
          ),
        );

        // Masuk langsung ke Home Page NARA
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NaraApp()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email atau Password salah / belum terdaftar!'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildBackground(),
          _buildGradientOverlay(),
          _buildBackButton(),
          _buildLoginFormCard(),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/mountains.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Container(color: const Color(0xFF101B14)),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.40),
              Colors.black.withValues(alpha: 0.65),
              Colors.black.withValues(alpha: 0.88),
              Colors.black,
            ],
            stops: const [0.0, 0.35, 0.70, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 0.8,
            ),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildLoginFormCard() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLogoHeader(),
                      const SizedBox(height: 28),
                      _buildEmailField(),
                      const SizedBox(height: 14),
                      _buildPasswordField(),
                      _buildForgotPasswordLink(),
                      const SizedBox(height: 16),
                      _buildSubmitButton(),
                      const SizedBox(height: 16),
                      _buildRegisterLink(),
                      const SizedBox(height: 14),
                      _buildPrivacyPolicyFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 90,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          'Nusantara Adventure Risk Awareness',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.70),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Color(0xFF4CAF78),
          size: 20,
        ),
        filled: true,
        fillColor: const Color(0xFF14241C).withValues(alpha: 0.70),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4CAF78), width: 1.5),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Email wajib diisi';
        }
        if (!val.contains('@')) {
          return 'Format email tidak valid';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF4CAF78),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white.withValues(alpha: 0.65),
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        filled: true,
        fillColor: const Color(0xFF14241C).withValues(alpha: 0.70),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4CAF78), width: 1.5),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Password wajib diisi';
        }
        if (val.length < 6) {
          return 'Password minimal 6 karakter';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Tugas12ForgotPassword(),
            ),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
        child: const Text(
          'Lupa Kata Sandi?',
          style: TextStyle(
            color: Color(0xFF4CAF78),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5A43),
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: const Color(0xFF4CAF78).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'MASUK',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.5,
                  fontFamily: 'Inter',
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Tugas12RegisterPage(),
              ),
            );
          },
          child: const Text(
            'Daftar Sekarang',
            style: TextStyle(
              color: Color(0xFF4CAF78),
              fontWeight: FontWeight.bold,
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicyFooter() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrivacyPolicyPage(),
            ),
          );
        },
        child: Text(
          'Kebijakan Privasi & Ketentuan NARA',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.55),
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
