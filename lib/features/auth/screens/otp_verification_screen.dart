import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/home/screens/home_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';
import 'package:url_launcher/url_launcher.dart';

class OtpVerificationPage extends StatefulWidget {
  final UserModel? user;
  final String? initialOtp;

  const OtpVerificationPage({
    super.key,
    this.user,
    this.initialOtp,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const int _otpLength = 6;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  late UserModel _user;
  late String _currentOtp;
  bool _isVerifying = false;
  String? _errorMessage;

  // Timer Kirim Ulang OTP
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user ??
        UserModel(
          nama: 'Farhiyah Petualang',
          email: 'farhiyah.outdoor@nara.id',
          noHp: '+62 812-3456-7890',
          password: '******',
          asalKota: 'Bandung Barat',
        );

    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    // Inisialisasi OTP
    _currentOtp = widget.initialOtp ?? _generateNewOtp();

    _startCountdown();

    // Otomatis muat user dari SQLite jika null dan buka instruksi email device
    _initUserAndSendEmail();
  }

  Future<void> _initUserAndSendEmail() async {
    if (widget.user == null) {
      try {
        final latest = await DatabaseHelper.instance.getLatestUser();
        if (latest != null && mounted) {
          setState(() {
            _user = latest;
          });
        }
      } catch (_) {}
    }

    if (mounted) {
      _sendOtpToDeviceEmail(showToast: false);
    }
  }

  String _generateNewOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtpToDeviceEmail({bool showToast = true}) async {
    final email = _user.email;
    final userName = _user.nama.isNotEmpty ? _user.nama : 'Petualang';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Kode Verifikasi OTP Masuk Akun NARA',
        'body': '''Halo $userName,

Berikut adalah Kode Verifikasi OTP 2 Langkah untuk masuk ke akun NARA Anda:

========================================
KODE VERIFIKASI OTP: $_currentOtp
========================================

Kode ini berlaku selama 5 menit. Jangan berikan kode ini kepada siapa pun untuk keamanan akun petualangan Anda.

Detail Permintaan:
- Akun Pengguna: $userName ($email)
- Waktu: ${DateTime.now().toLocal().toString().split('.')[0]}

Salam Hangat,
Tim Keamanan & Petualangan NARA
(Nusantara Adventure Risk Awareness)''',
      },
    );

    try {
      final launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(emailLaunchUri);
      }
    } catch (_) {}

    if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kode OTP baru telah dikirim ke aplikasi email ($email)!',
          ),
          backgroundColor: const Color(0xFF2D5A43),
        ),
      );
    }
  }

  void _handleResendOtp() {
    if (!_canResend) return;

    setState(() {
      _currentOtp = _generateNewOtp();
      _errorMessage = null;
      for (var c in _controllers) {
        c.clear();
      }
    });

    _focusNodes[0].requestFocus();
    _startCountdown();
    _sendOtpToDeviceEmail(showToast: true);
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _controllers.map((c) => c.text).join();

    if (enteredOtp.length < _otpLength) {
      setState(() {
        _errorMessage = 'Masukkan seluruh $_otpLength digit kode OTP';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    if (enteredOtp == _currentOtp) {
      // 1. Simpan Sesi Pengguna Aktif ke DatabaseHelper & SharedPreferences
      if (_user.id != null) {
        await DatabaseHelper.instance.setActiveUserId(_user.id!);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verifikasi Berhasil! Selamat Datang, ${_user.nama}.',
          ),
          backgroundColor: const Color(0xFF2D5A43),
        ),
      );

      // 2. Masuk langsung ke Halaman Utama NARA Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const NaraHomePage(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Kode OTP tidak cocok! Periksa kembali email Anda.';
      });
      HapticFeedback.vibrate();
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Jika user paste string lebih dari 1 digit
      if (value.length > 1) {
        for (int i = 0; i < value.length && (index + i) < _otpLength; i++) {
          _controllers[index + i].text = value[i];
        }
        final nextIndex = min(index + value.length, _otpLength - 1);
        _focusNodes[nextIndex].requestFocus();
        if (_controllers.every((c) => c.text.isNotEmpty)) {
          _verifyOtp();
        }
        return;
      }

      // Pindah ke box berikutnya
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Otomatis verifikasi jika semua terisi
        if (_controllers.every((c) => c.text.isNotEmpty)) {
          _verifyOtp();
        }
      }
    } else {
      // Jika hapus digit, otomatis mundur ke box sebelumnya
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
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
          _buildOtpFormCard(),
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

  Widget _buildOtpFormCard() {
    final String maskedEmail = _user.email;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
                decoration: BoxDecoration(
                  color: const Color(0xFF14241C).withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderBadge(),
                    const SizedBox(height: 18),
                    _buildTitleAndDescription(maskedEmail),
                    const SizedBox(height: 24),
                    _buildOtpInputs(),
                    _buildErrorMessageSection(),
                    const SizedBox(height: 24),
                    _buildVerifyButton(),
                    const SizedBox(height: 16),
                    _buildEmailAppButton(),
                    const SizedBox(height: 18),
                    _buildResendSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2D5A43),
              Color(0xFF4CAF78),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF78).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.mark_email_read_rounded,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTitleAndDescription(String maskedEmail) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Verifikasi OTP Email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Masukkan 6 digit kode verifikasi yang telah dikirimkan ke aplikasi email perangkat Anda:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2E25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF4CAF78).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.alternate_email_rounded,
                color: Color(0xFF4CAF78),
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  maskedEmail,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_otpLength, (index) {
        return _buildOtpDigitBox(index);
      }),
    );
  }

  Widget _buildErrorMessageSection() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.errorRed,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isVerifying ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5A43),
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: const Color(0xFF4CAF78).withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isVerifying
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'VERIFIKASI & MASUK',
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

  Widget _buildEmailAppButton() {
    return OutlinedButton.icon(
      onPressed: () => _sendOtpToDeviceEmail(showToast: false),
      icon: const Icon(
        Icons.mail_outline_rounded,
        size: 18,
        color: Color(0xFF4CAF78),
      ),
      label: const Text(
        'Buka Aplikasi Email',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: const Color(0xFF4CAF78).withValues(alpha: 0.6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: _canResend
          ? GestureDetector(
              onTap: _handleResendOtp,
              child: const Text(
                'Kirim Ulang Kode OTP',
                style: TextStyle(
                  color: Color(0xFF4CAF78),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          : Text(
              'Kirim ulang dalam 00:${_secondsRemaining.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }

  Widget _buildOtpDigitBox(int index) {
    final isFocused = _focusNodes[index].hasFocus;
    final hasValue = _controllers[index].text.isNotEmpty;

    return Container(
      width: 44,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFF1B2E25).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF4CAF78)
              : hasValue
                  ? const Color(0xFF2D5A43)
                  : Colors.white.withValues(alpha: 0.2),
          width: isFocused ? 2.0 : 1.2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF4CAF78).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (val) => _onDigitChanged(val, index),
        ),
      ),
    );
  }
}
