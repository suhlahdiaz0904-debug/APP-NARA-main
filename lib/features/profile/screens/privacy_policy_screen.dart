import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';

// =========================================================================
// LAYAR KEBIJAKAN PRIVASI RESMI NARA (NAVIGASI TEBING & GOA)
// Memenuhi Standar Privasi Google Play Store & Perlindungan Data Pengguna
// Mendukung Light Mode & Dark Mode NARA Earth Tone Design System
// =========================================================================

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  // Palet Aksen NARA
  static const Color darkGreen = Color(0xFF1E382B);

  // Status ekspansi kartu kebijakan
  final Map<int, bool> _expandedCards = {
    0: true,  // Buka kartu pertama secara default
  };

  void _toggleCard(int index) {
    setState(() {
      _expandedCards[index] = !(_expandedCards[index] ?? false);
    });
  }

  void _expandAll() {
    setState(() {
      for (int i = 0; i < 10; i++) {
        _expandedCards[i] = true;
      }
    });
  }

  void _collapseAll() {
    setState(() {
      _expandedCards.clear();
    });
  }

  void _copyContactEmail(String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email $email berhasil disalin ke papan klip!'),
        backgroundColor: context.isDarkMode ? AppTheme.darkPrimary : darkGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color primaryColor = isDark ? AppTheme.darkPrimary : darkGreen;

    return Scaffold(
      backgroundColor: context.themeBg,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // 1. APP BAR GLASSMORPHIC
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: primaryColor,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Kebijakan Privasi',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  ThemeController.instance.isDarkMode(context)
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_outlined,
                  color: isDark ? AppTheme.goldAccent : darkGreen,
                  size: 22,
                ),
                tooltip: 'Ganti Mode Tampilan',
                onPressed: () => ThemeController.instance.toggleTheme(context),
              ),
              const SizedBox(width: 6),
            ],
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: context.themeBg.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),

          // 2. KONTEN KEBIJAKAN PRIVASI
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Hero Banner Komitmen Privasi
                _buildHeroBanner(primaryColor),
                const SizedBox(height: 16),

                // Bar Kontrol Expand / Collapse & Info Versi
                _buildControlBar(primaryColor),
                const SizedBox(height: 16),

                // 1. Pengantar & Ruang Lingkup
                _buildPolicyCard(
                  index: 0,
                  primaryColor: primaryColor,
                  icon: Icons.info_outline_rounded,
                  title: '1. Pengantar & Ruang Lingkup',
                  summary: 'Komitmen perlindungan privasi petualang tebing & goa NARA',
                  content:
                      'Aplikasi **NARA (Navigasi Tebing & Goa)** dikembangkan untuk mendukung komunitas pemanjat tebing, penelusur goa, dan penggiat alam bebas di Indonesia.\n\n'
                      'Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi informasi pribadi Anda saat menggunakan aplikasi mobile NARA pada perangkat Android dan iOS.',
                ),
                const SizedBox(height: 12),

                // 2. Data Lokasi & GPS
                _buildPolicyCard(
                  index: 1,
                  primaryColor: primaryColor,
                  icon: Icons.location_on_outlined,
                  title: '2. Data Lokasi & GPS Lapangan',
                  summary: 'Penggunaan koordinat untuk peta tebing, rute goa, & cuaca',
                  content:
                      'Aplikasi NARA membutuhkan akses ke data lokasi perangkat Anda:\n\n'
                      '• **Lokasi Presisi (GPS)**: Digunakan untuk menampilkan posisi Anda secara real-time pada peta topografi tebing dan titik koordinat mulut goa.\n'
                      '• **Prakiraan Cuaca Real-Time**: Koordinat lokasi digunakan untuk mengambil data cuaca mikro lokal (suhu, curah hujan, kecepatan angin) demi keselamatan pemanjatan.\n'
                      '• **Navigasi Offline**: Koordinat yang diakses tidak dibagikan ke pihak ketiga atau pengiklan.',
                ),
                const SizedBox(height: 12),

                // 3. Data Profil & Akun Petualang
                _buildPolicyCard(
                  index: 2,
                  primaryColor: primaryColor,
                  icon: Icons.person_outline_rounded,
                  title: '3. Data Profil & Akun Pengguna',
                  summary: 'Informasi identitas akun dan personalisasi pengalaman',
                  content:
                      'Ketika Anda mendaftar atau mengatur profil di NARA, kami mengelola informasi berikut:\n\n'
                      '• **Identitas Akun**: Nama lengkap, alamat email, nomor telepon, dan asal kota.\n'
                      '• **Profil Petualang**: Role pemanjat/caver, biografi singkat, dan organisasi/klub petualang.\n'
                      '• **Foto Profil**: Foto yang Anda pilih dari galeri perangkat atau kamera untuk personalisasi akun.',
                ),
                const SizedBox(height: 12),

                // 4. Data Keselamatan Medis & Kontak Darurat
                _buildPolicyCard(
                  index: 3,
                  primaryColor: primaryColor,
                  icon: Icons.health_and_safety_outlined,
                  title: '4. Data Medis & Kontak Darurat SOS',
                  summary: 'Informasi krusial penanganan darurat di tebing & goa',
                  content:
                      'Untuk keselamatan pemanjat dan penelusur goa di lokasi ekstrem:\n\n'
                      '• **Golongan Darah & Kontak Darurat**: Digunakan secara cepat saat kondisi darurat atau integrasi panggilan SOS basecamp tebing/goa.\n'
                      '• **Penyimpanan Lokal**: Data ini tersimpan aman di database lokal perangkat Anda agar dapat diakses seketika meskipun berada di area tanpa sinyal seluler (*blank spot*).',
                ),
                const SizedBox(height: 12),

                // 5. Log Ekspedisi & Media Foto
                _buildPolicyCard(
                  index: 4,
                  primaryColor: primaryColor,
                  icon: Icons.explore_outlined,
                  title: '5. Log Ekspedisi & Dokumentasi Rute',
                  summary: 'Pencatatan riwayat pemanjatan, jarak jelajah, & foto',
                  content:
                      '• **Riwayat Log**: Data log pendakian, nama tebing/goa yang dikunjungi, tingkat kesulitan rute (grade), dan durasi di lapangan.\n'
                      '• **Foto Dokumentasi**: Foto ekspedisi dan dokumentasi tebing disimpan di penyimpanan lokal aplikasi atau galeri perangkat Anda sesuai izin yang diberikan.',
                ),
                const SizedBox(height: 12),

                // 6. Penyimpanan Lokal & Arsitektur Offline-First
                _buildPolicyCard(
                  index: 5,
                  primaryColor: primaryColor,
                  icon: Icons.storage_rounded,
                  title: '6. Penyimpanan Lokal (Offline-First)',
                  summary: 'Data aman di SQLite perangkat tanpa ketergantungan cloud publik',
                  content:
                      'NARA menerapkan arsitektur *Offline-First*:\n\n'
                      '• Seluruh basis data ekspedisi, bookmark spot, dan profil Anda disimpan dalam database **SQLite lokal** di perangkat Anda.\n'
                      '• Hal ini menjamin privasi penuh dan memastikan Anda tetap dapat mengakses rute tebing dan panduan keselamatan di dalam goa atau tebing terpencil tanpa koneksi internet.',
                ),
                const SizedBox(height: 12),

                // 7. Izin Perangkat (Device Permissions)
                _buildPolicyCard(
                  index: 6,
                  primaryColor: primaryColor,
                  icon: Icons.security_rounded,
                  title: '7. Izin Akses Perangkat (Permissions)',
                  summary: 'Daftar izin Android/iOS yang diminta oleh aplikasi',
                  content:
                      'Aplikasi NARA hanya meminta izin perangkat yang benar-benar esensial:\n\n'
                      '1. **ACCESS_FINE_LOCATION & COARSE_LOCATION**: Untuk penentuan koordinat GPS tebing/goa dan cuaca.\n'
                      '2. **CAMERA & READ_MEDIA_IMAGES**: Untuk mengambil foto profil dan dokumentasi ekspedisi.\n'
                      '3. **INTERNET & ACCESS_NETWORK_STATE**: Untuk mengunduh peta dan pembaruan cuaca BMKG/OpenWeather.\n'
                      '4. **CALL_PHONE / URL_LAUNCHER**: Untuk menghubungi nomor darurat basecamp tebing/goa.',
                ),
                const SizedBox(height: 12),

                // 8. Perlindungan & Pihak Ketiga
                _buildPolicyCard(
                  index: 7,
                  primaryColor: primaryColor,
                  icon: Icons.shield_outlined,
                  title: '8. Kerahasiaan & Tidak Ada Penjualan Data',
                  summary: 'Kami tidak pernah menjual data pribadi Anda kepada pihak ketiga',
                  content:
                      '• **Tanpa Penjualan Data**: NARA **tidak pernah** menjual, menyewakan, atau memperdagangkan data pribadi pengguna kepada pihak ketiga atau biro iklan manapun.\n'
                      '• **Layanan Pihak Ketiga**: Aplikasi menggunakan layanan peta terbuka (OpenStreetMap / FlutterMap) dan API cuaca yang hanya menerima koordinat geografis tanpa menyertakan identitas pribadi Anda.',
                ),
                const SizedBox(height: 12),

                // 9. Hak Pengguna & Penghapusan Data
                _buildPolicyCard(
                  index: 8,
                  primaryColor: primaryColor,
                  icon: Icons.manage_accounts_outlined,
                  title: '9. Hak Pengguna & Penghapusan Data',
                  summary: 'Kontrol penuh atas modifikasi dan penghapusan data Anda',
                  content:
                      'Sebagai pengguna NARA, Anda memiliki hak penuh untuk:\n\n'
                      '• **Mengakses & Mengubah Data**: Memperbarui profil, no HP, kota, dan data darurat kapan saja melalui menu Setup Akun.\n'
                      '• **Menghapus Log Ekspedisi**: Menghapus catatan riwayat atau spot bookmark secara mandiri.\n'
                      '• **Menghapus Seluruh Data**: Menghapus data aplikasi langsung melalui pengaturan aplikasi atau membersihkan penyimpanan lokal (Clear Data).',
                ),
                const SizedBox(height: 12),

                // 10. Kontak & Hubungi Tim Privasi
                _buildPolicyCard(
                  index: 9,
                  primaryColor: primaryColor,
                  icon: Icons.support_agent_rounded,
                  title: '10. Kontak & Pusat Bantuan Privasi',
                  summary: 'Hubungi tim NARA jika Anda memiliki pertanyaan privasi',
                  content:
                      'Jika Anda memiliki pertanyaan, masukan, atau permintaan terkait Kebijakan Privasi ini, silakan hubungi tim kami:\n\n'
                      '• **Email Resmi**: privacy@nara.id\n'
                      '• **Dukungan Pengguna**: support@nara.id\n'
                      '• **Komunitas**: NARA Outdoor & Speleo Indonesia\n'
                      '• **Alamat**: Bandung, Jawa Barat, Indonesia',
                ),
                const SizedBox(height: 20),

                // Kotak Kontak Cepat Interaktif
                _buildQuickContactBox(primaryColor),
                const SizedBox(height: 20),

                // Tombol "Saya Mengerti"
                _buildAcknowledgeButton(primaryColor),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET HELPER
  // ==========================================

  Widget _buildHeroBanner(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.themeBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privasi & Keamanan Petualang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NARA • Versi 1.0 (2026)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Keamanan data navigasi, koordinat GPS, dan riwayat petualangan Anda adalah prioritas tertinggi NARA. Kami berkomitmen menjaga kerahasiaan data Anda dengan standar perlindungan data terpercaya.',
            style: TextStyle(
              fontSize: 12.5,
              color: context.themeTextSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(Color primaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Daftar Klausul Privasi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.themeText,
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: _expandAll,
              icon: Icon(Icons.unfold_more_rounded, size: 16, color: primaryColor),
              label: Text(
                'Buka Semua',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _collapseAll,
              icon: Icon(Icons.unfold_less_rounded, size: 16, color: context.themeTextSecondary),
              label: Text(
                'Tutup Semua',
                style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPolicyCard({
    required int index,
    required Color primaryColor,
    required IconData icon,
    required String title,
    required String summary,
    required String content,
  }) {
    final bool isExpanded = _expandedCards[index] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded ? primaryColor.withValues(alpha: 0.35) : context.themeBorder,
          width: isExpanded ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isExpanded ? 0.05 : 0.02),
            blurRadius: isExpanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleCard(index),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? primaryColor.withValues(alpha: 0.15)
                            : context.themeSurfaceHigh,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isExpanded ? primaryColor : context.themeTextSecondary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: context.themeText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.themeTextSecondary,
                            ),
                            maxLines: isExpanded ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isExpanded ? primaryColor : context.themeTextSecondary,
                      size: 22,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 14),
                  Divider(height: 1, color: context.themeBorder),
                  const SizedBox(height: 14),
                  _buildFormattedContent(content, primaryColor),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormattedContent(String content, Color primaryColor) {
    // Format teks dengan highlight bold sederhana
    final paragraphs = content.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            p.replaceAll('**', ''),
            style: TextStyle(
              fontSize: 12.5,
              color: context.themeText,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickContactBox(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeSurfaceHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Pertanyaan Seputar Privasi?',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: context.themeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tim Data Protection Officer (DPO) NARA siap membantu Anda jika ada kendala data atau privasi.',
            style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyContactEmail('privacy@nara.id'),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Salin privacy@nara.id', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgeButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: const Text(
          'SAYA MENGERTI & MENYETUJUI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.0,
            fontFamily: 'Inter',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: context.isDarkMode ? const Color(0xFF061E14) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
