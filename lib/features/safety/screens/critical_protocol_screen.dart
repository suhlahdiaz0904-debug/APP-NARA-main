import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';

// =========================================================================
// HALAMAN PROTOKOL KRITIS & LEAVE NO TRACE (FULL SCREEN PAGE)
// =========================================================================

class ProtokolKritisPage extends StatelessWidget {
  const ProtokolKritisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      // =======================================================================
      // TOP APP BAR (SAMA PERSIS DENGAN KEBUTUHAN WANITA)
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
              color: context.themePrimary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: context.themeBorder, width: 1.5),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: context.themePrimary,
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
                color: context.themePrimary.withValues(
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
                color: context.themeTerracotta.withValues(
                  alpha: isDark ? 0.08 : 0.15,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Konten Utama Protokol Kritis
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: context.themePrimary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PANDUAN EKSPLORASI & KESELAMATAN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: context.themePrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Protokol Kritis &\nLeave No Trace',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: context.themeText,
                            height: 1.2,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Standar operasional keselamatan, etika kelestarian alam, sanitasi lapangan, dan tindakan tanggap darurat saat berpetualang.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: context.themeTextSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header Tindakan Paling Penting
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.themeBorder),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : context.themePrimary.withValues(alpha: 0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: context.themePrimary.withValues(
                              alpha: 0.18,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.eco_rounded,
                            color: context.themePrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Prinsip Utama Keselamatan & Etika Alam',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: context.themeText,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Setiap langkah dirancang agar Anda aman, rekan tim terlindungi, dan ekosistem tebing/goa tetap lestari tanpa jejak kerusakan.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: context.themeTextSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Daftar Panel Protokol
                  _buildProtocolCard(
                    context: context,
                    label: '01',
                    title: '7 Prinsip Leave No Trace (LNT)',
                    body:
                        '1. Rencanakan & persiapkan matang.\n2. Berjelajah & berkemah di permukaan kokoh.\n3. Kelola sampah tuntas (bawa turun kembali).\n4. Biarkan apa yang Anda temukan di alam.\n5. Minimalkan dampak api unggun.\n6. Hormati satwa liar dan habitatnya.\n7. Hargai kenyamanan pengunjung lain.',
                    icon: Icons.forest_outlined,
                    accentColor: context.themePrimary,
                  ),
                  const SizedBox(height: 14),

                  _buildProtocolCard(
                    context: context,
                    label: '02',
                    title: 'Sanitasi Lapangan & Lubang Cathole',
                    body:
                        'Gali lubang sedalam 15-20 cm dengan jarak minimal 60 meter (±80 langkah) dari sumber air, mata air tebing, dan jalur umum. Timbun kembali dengan tanah asli dan kamuflasekan dengan dedaunan kering.',
                    icon: Icons.cleaning_services_outlined,
                    accentColor: context.themeTerracotta,
                  ),
                  const SizedBox(height: 14),

                  _buildProtocolCard(
                    context: context,
                    label: '03',
                    title: 'Sinyal Darurat Peluit & Cermin (Alpine Distress)',
                    body:
                        'Kirimkan 6 kali tiupan peluit / kilatan cermin per menit, jeda hening selama 1 menit, lalu ulangi secara berkala. Balasan konfirmasi dari tim penolong SAR adalah 3 kali tiupan peluit per menit.',
                    icon: Icons.campaign_rounded,
                    accentColor: const Color(0xFFD32F2F),
                  ),
                  const SizedBox(height: 14),

                  _buildProtocolCard(
                    context: context,
                    label: '04',
                    title: 'Evakuasi Korban Cedera di Ketinggian',
                    body:
                        'Amankan korban pada anchor cadangan ganda (redundant anchor), periksa jalan napas dan pendarahan utama, pasang neck collar/stabilkan leher sebelum memulai proses lowering atau hauling.',
                    icon: Icons.health_and_safety_outlined,
                    accentColor: const Color(0xFFE65100),
                  ),
                  const SizedBox(height: 14),

                  _buildProtocolCard(
                    context: context,
                    label: '05',
                    title: 'Pemeriksaan Anchor & Redundansi Simpul',
                    body:
                        'Pastikan titik pengaman memenuhi prinsip SERENE-V (Solid, Equalized, Redundant, Efficient, No Extension, Versatile). Selalu cek locking carabiner dan stopper knot sebelum beban penuh.',
                    icon: Icons.lock_outline_rounded,
                    accentColor: context.themePrimary,
                  ),
                  const SizedBox(height: 24),

                  // Tombol Konfirmasi Paham
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themePrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Paham & Siap Patuhi Protokol',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard({
    required BuildContext context,
    required String label,
    required String title,
    required String body,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: TextStyle(
              fontSize: 12.5,
              color: context.themeTextSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
