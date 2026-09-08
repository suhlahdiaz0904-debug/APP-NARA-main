import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/auth/screens/login_screen.dart';
import 'package:flutter_application_1/features/home/screens/home_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';
import 'package:flutter_application_1/features/profile/screens/privacy_policy_screen.dart';

class Tugas12RegisterPage extends StatefulWidget {
  const Tugas12RegisterPage({super.key});

  @override
  State<Tugas12RegisterPage> createState() => _Tugas12RegisterPageState();
}

class _Tugas12RegisterPageState extends State<Tugas12RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _namaCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _noHpCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _asalKotaCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailCtrl.text.trim();
      final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
      if (existingUser != null) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email ini sudah terdaftar! Silakan langsung Masuk.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      final newUser = UserModel(
        nama: _namaCtrl.text.trim(),
        email: email,
        noHp: _noHpCtrl.text.trim(),
        password: _passwordCtrl.text,
        asalKota: _asalKotaCtrl.text.trim(),
      );

      try {
        await DatabaseHelper.instance.registerUser(newUser);
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Akun Berhasil Dibuat! Selamat Datang di NARA, ${newUser.nama}!',
            ),
            backgroundColor: const Color(0xFF2D5A43),
          ),
        );

        // Arahkan langsung ke Home Page NARA
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const NaraApp()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Gagal Mendaftar: Terjadi kesalahan saat menyimpan ke database!',
            ),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Tugas12LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _noHpCtrl.dispose();
    _passwordCtrl.dispose();
    _asalKotaCtrl.dispose();
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
          _buildRegisterCard(),
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
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      child: GestureDetector(
        onTap: _goToLogin,
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

  Widget _buildRegisterCard() {
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
                  vertical: 28,
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
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildFormFields(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 14),
                      _buildPrivacyPolicyNotice(),
                      const SizedBox(height: 14),
                      _buildLoginLink(),
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

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 90, fit: BoxFit.contain),
        const SizedBox(height: 8),
        Text(
          'Mulai petualangan luar ruang Anda bersama NARA',
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

  Widget _buildFormFields() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildField(
          controller: _namaCtrl,
          label: 'Nama Lengkap',
          icon: Icons.person_outline,
          validator: (val) =>
              val == null || val.isEmpty ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _emailCtrl,
          label: 'Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.isEmpty) {
              return 'Email wajib diisi';
            }
            if (!val.contains('@')) {
              return 'Email tidak valid';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _noHpCtrl,
          label: 'Nomor HP',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (val) =>
              val == null || val.isEmpty ? 'No HP wajib diisi' : null,
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _asalKotaCtrl,
          label: 'Asal Kota',
          icon: Icons.location_city_outlined,
          validator: (val) =>
              val == null || val.isEmpty ? 'Asal kota wajib diisi' : null,
        ),
        const SizedBox(height: 12),
        _buildField(
          controller: _passwordCtrl,
          label: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withValues(alpha: 0.65),
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
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
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
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
                'DAFTAR AKUN',
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

  Widget _buildPrivacyPolicyNotice() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text.rich(
          TextSpan(
            text: 'Dengan mendaftar, Anda menyetujui ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.35,
            ),
            children: const [
              TextSpan(
                text: 'Kebijakan Privasi & Perlindungan Data NARA',
                style: TextStyle(
                  color: Color(0xFF4CAF78),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun? ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: _goToLogin,
          child: const Text(
            'Masuk Disini',
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF4CAF78), size: 20),
        suffixIcon: suffixIcon,
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
      validator: validator,
    );
  }
}
