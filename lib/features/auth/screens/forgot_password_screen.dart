import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class Tugas12ForgotPassword extends StatefulWidget {
  const Tugas12ForgotPassword({super.key});

  @override
  State<Tugas12ForgotPassword> createState() => _Tugas12ForgotPasswordState();
}

class _Tugas12ForgotPasswordState extends State<Tugas12ForgotPassword> {
  final TextEditingController emailC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> handleResetPassword() async {
    // 1. Jalankan Validator Form
    if (!_formKey.currentState!.validate()) return;

    final email = emailC.text.trim();
    setState(() => _isLoading = true);

    // 2. Cek apakah email terdaftar di SQLite Database
    final user = await DatabaseHelper.instance.getUserByEmail(email);
    if (user == null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email belum terdaftar di database NARA! Silakan daftar akun terlebih dahulu.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final String userName =
        user.nama.isNotEmpty ? user.nama : 'Petualang';
    final int verificationCode = 100000 + Random().nextInt(900000);

    // 3. Format URL Mailto untuk membuka aplikasi email bawaan / perangkat
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Instruksi Pemulihan Kata Sandi Akun NARA',
        'body': '''Halo $userName,

Kami menerima permintaan untuk mengatur ulang kata sandi akun NARA Anda ($email).

Berikut adalah Kode Verifikasi Pemulihan Kata Sandi Anda:
========================================
KODE VERIFIKASI: $verificationCode
========================================

Silakan gunakan kode di atas atau balas email ini untuk melanjutkan proses pemulihan akun Anda.

Detail Akun NARA:
- Nama Pengguna: $userName
- Alamat Email: $email
- Waktu Permintaan: ${DateTime.now().toLocal().toString().split('.')[0]}

Jika Anda tidak pernah meminta pemulihan kata sandi, mohon abaikan pesan ini. Akun Anda tetap aman dan terlindungi.

Salam Hangat,
Tim Keamanan & Petualangan NARA
(Nusantara Adventure Risk Awareness)''',
      },
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    // 4. Hubungkan langsung ke aplikasi Email di perangkat
    bool launched = false;
    try {
      launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      try {
        launched = await launchUrl(emailLaunchUri);
      } catch (_) {
        launched = false;
      }
    }

    if (!mounted) return;

    // 5. Tampilkan Modal Konfirmasi & Notifikasi Sukses
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14241C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.2,
          ),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.mark_email_read_rounded,
              color: Color(0xFF4CAF78),
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Email Terhubung',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instruksi pemulihan kata sandi untuk $userName ($email) telah disiapkan dan dikirim.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2E25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF4CAF78).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.key_rounded,
                    color: Color(0xFFE9C46A),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Kode OTP: $verificationCode',
                      style: const TextStyle(
                        color: Color(0xFFE9C46A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              launched
                  ? 'Aplikasi email di perangkat Anda telah dibuka secara otomatis.'
                  : 'Silakan periksa kotak masuk email Anda pada aplikasi email perangkat.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // Kembali ke Login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5A43),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: const Text(
                'Selesai & Masuk Kembali',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailC.dispose();
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
          _buildResetPasswordCard(),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/citatah.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF101B14),
        ),
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
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildResetPasswordCard() {
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                      const SizedBox(height: 28),
                      _buildEmailField(),
                      const SizedBox(height: 24),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      _buildBackToLoginLink(),
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
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D5A43),
                Color(0xFF4CAF78),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PULIHKAN SANDI',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Masukkan email terdaftar Anda untuk menerima tautan pemulihan kata sandi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailC,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: 'Email Terdaftar',
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.65),
          fontSize: 13,
        ),
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
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF4CAF78),
            width: 1.5,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Email tidak boleh kosong";
        }
        final emailRegex = RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        );
        if (!emailRegex.hasMatch(value.trim())) {
          return "Format email tidak valid (cth: user@gmail.com)";
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : handleResetPassword,
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'KIRIM INSTRUKSI',
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

  Widget _buildBackToLoginLink() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back,
            color: Color(0xFF4CAF78),
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'Kembali ke Masuk',
            style: TextStyle(
              color: Color(0xFF4CAF78),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
