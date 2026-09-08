import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';

// =========================================================================
// HALAMAN KEBUTUHAN WANITA (DARK & LIGHT EARTH TONE WELLNESS THEME)
// =========================================================================

class KebutuhanWanitaPage extends StatelessWidget {
  const KebutuhanWanitaPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      // =======================================================================
      // TOP APP BAR
      // =======================================================================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.themePrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NARA',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? AppTheme.darkPrimary : const Color(0xFF143023),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isDark ? AppTheme.goldAccentDark : context.themePrimary,
              size: 22,
            ),
            tooltip: isDark
                ? 'Beralih ke Mode Terang'
                : 'Beralih ke Mode Gelap',
            onPressed: () => ThemeController.instance.toggleTheme(context),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.themeTerracotta.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: context.themeBorder, width: 1.5),
            ),
            child: Icon(
              Icons.spa_rounded,
              color: context.themeTerracotta,
              size: 18,
            ),
          ),
        ],
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: context.themeBg.withValues(alpha: 0.8)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Glow Decorative Blobs
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: context.themeTerracotta.withValues(
                  alpha: isDark ? 0.08 : 0.15,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(
                  alpha: isDark ? 0.08 : 0.15,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.themeTerracotta.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PANDUAN EKSPLORASI',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: context.themeTerracotta,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Perawatan Diri di\nAlam Terbuka',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: context.themeText,
                          height: 1.2,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Panduan lembut dan memberdayakan untuk menjaga kebersihan, kenyamanan, dan rasa aman saat menjelajah di alam terbuka.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.themeCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.themeBorder),
                    boxShadow: [
                      BoxShadow(
                        color: context.isDarkMode
                            ? Colors.black.withValues(alpha: 0.2)
                            : context.themePrimary.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.themeTerracotta.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: context.themeTerracotta,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tindakan paling penting',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.themeText,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Semua langkah berikut dirancang agar tetap nyaman, aman, dan tetap menghormati lingkungan saat Anda berada di alam terbuka.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildChecklistPanel(
                  context,
                  label: '01',
                  title: 'Menstruasi di Alam Liar',
                  body:
                      'Kemas produk yang Anda pakai dalam wadah aman dan bawa kembali limbah pada tempat yang sesuai. Pilih pilihan yang nyaman dan ramah lingkungan.',
                  icon: Icons.water_drop_rounded,
                ),
                const SizedBox(height: 12),
                _buildChecklistPanel(
                  context,
                  label: '02',
                  title: 'Sanitasi & Higiene',
                  body:
                      'Gunakan sabun biodegradable, jauhkan aktivitas mencuci dari sumber air, dan pastikan alat kebersihan Anda tertutup rapi agar tidak mencemari lingkungan.',
                  icon: Icons.wash_rounded,
                ),
                const SizedBox(height: 12),
                _buildChecklistPanel(
                  context,
                  label: '03',
                  title: 'Kesehatan & Kesejahteraan',
                  body:
                      'Perhatikan tanda lelah, dehidrasi, atau kram. Istirahat sejenak, minum cukup, dan jangan menunda tindakan jika tubuh mulai tidak fit.',
                  icon: Icons.favorite_rounded,
                ),
                const SizedBox(height: 12),
                _buildChecklistPanel(
                  context,
                  label: '04',
                  title: 'Kit Wajib Bawa',
                  body:
                      'Pembalut atau menstrual cup steril, hand sanitizer, tisu basah biodegradable, dan obat pereda nyeri sangat penting untuk menjaga kenyamanan Anda.',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: context.themePrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kit Kebersihan Wajib Bawa',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.themeText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildKitRow(
                        context,
                        Icons.medical_services_outlined,
                        'Pembalut / Menstrual cup steril',
                      ),
                      _buildKitRow(
                        context,
                        Icons.clean_hands_outlined,
                        'Tisu basah biodegradable & hand sanitizer',
                      ),
                      _buildKitRow(
                        context,
                        Icons.shield_moon_outlined,
                        'Kantong kedap bau (Ziplock dobel lapis)',
                      ),
                      _buildKitRow(
                        context,
                        Icons.medication_outlined,
                        'Obat pereda nyeri kram (Paracetamol/Ibuprofen)',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistPanel(
    BuildContext context, {
    required String label,
    required String title,
    required String body,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.themePrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.themeTerracotta.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.themeTerracotta, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.themeTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKitRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: context.themePrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
