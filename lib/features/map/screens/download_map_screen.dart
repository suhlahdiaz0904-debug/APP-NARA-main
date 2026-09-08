import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/map/screens/map_view_screen.dart';

class UnduhAreaBaruPage extends StatefulWidget {
  final String? initialAreaName;
  final bool isDownloaded; // Penanda status unduhan

  const UnduhAreaBaruPage({
    super.key,
    this.initialAreaName,
    this.isDownloaded = false,
  });

  @override
  State<UnduhAreaBaruPage> createState() => _UnduhAreaBaruPageState();
}

class _UnduhAreaBaruPageState extends State<UnduhAreaBaruPage> {
  // Status Proses Unduh
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Timer? _downloadTimer;

  static const String _mapSize = '250 MB';

  String get _areaTitle {
    if (widget.initialAreaName != null && widget.initialAreaName!.isNotEmpty) {
      return widget.initialAreaName!;
    }
    return 'Tebing Maros';
  }

  @override
  void dispose() {
    _downloadTimer?.cancel();
    super.dispose();
  }

  // Fungsi Simulasi Download & Langsung Masuk ke Peta Viewer
  void _mulaiDownloadDanNavigasi() {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    _downloadTimer = Timer.periodic(const Duration(milliseconds: 75), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _downloadProgress += 0.05;
      });

      // Saat download mencapai 100%
      if (_downloadProgress >= 1.0) {
        timer.cancel();
        setState(() {
          _downloadProgress = 1.0;
          _isDownloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Peta $_areaTitle selesai diunduh! Membuka peta...'),
            backgroundColor: context.themePrimary,
            duration: const Duration(seconds: 1),
          ),
        );

        // Langsung masuk ke navigasi PetaViewerPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PetaViewerPage(areaName: _areaTitle),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: context.themeBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: context.themePrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isDownloaded ? 'Detail Peta' : 'Unduh Peta Offline',
          style: TextStyle(
            color: context.themePrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
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
            tooltip: isDark ? 'Beralih ke Mode Terang' : 'Beralih ke Mode Gelap',
            onPressed: () => ThemeController.instance.toggleTheme(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Preview Peta Crop
                    _buildMapCropPreview(),
                    const SizedBox(height: 16),

                    // 2. Card Informasi Area Pilihan
                    _buildAreaInfoCard(),
                    const SizedBox(height: 16),

                    // 3. Card Paket Peta Tunggal (Single Choice)
                    _buildSingleMapPackageCard(),
                    const SizedBox(height: 16),

                    // 4. Card Informasi Penyimpanan Perangkat
                    _buildStorageInfoCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 5. Section Tombol Aksi Bawah
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _buildBottomActionButton(),
            ),
          ],
        ),
      ),
    );
  }

  // Method Pemisah Tombol Bawah (Bebas Error & Rapi)
  Widget _buildBottomActionButton() {
    final bool isDark = context.isDarkMode;

    // 1. Jika Peta Sudah Terunduh -> Tampilkan Tombol "Buka Peta"
    if (widget.isDownloaded) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PetaViewerPage(areaName: _areaTitle),
              ),
            );
          },
          icon: Icon(
            Icons.map_rounded,
            color: isDark ? const Color(0xFF0F1713) : Colors.white,
            size: 20,
          ),
          label: Text(
            'Buka Peta',
            style: TextStyle(
              color: isDark ? const Color(0xFF0F1713) : Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.themePrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      );
    }

    // 2. Jika Sedang Proses Mengunduh -> Tampilkan Progress Bar Aktif
    if (_isDownloading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeBorder),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: context.themePrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Mengunduh $_areaTitle...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(_downloadProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.themePrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _downloadProgress,
                minHeight: 7,
                backgroundColor: context.themeSurface,
                valueColor: AlwaysStoppedAnimation<Color>(context.themeGold),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Kondisi Awal Belum Diunduh -> Tampilkan Tombol "Unduh Sekarang"
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _mulaiDownloadDanNavigasi,
        icon: Icon(
          Icons.download_rounded,
          color: isDark ? const Color(0xFF0F1713) : Colors.white,
          size: 20,
        ),
        label: Text(
          'Unduh Sekarang',
          style: TextStyle(
            color: isDark ? const Color(0xFF0F1713) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.themePrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMapCropPreview() {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=1000',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: context.themeSurface,
                  child: Icon(
                    Icons.terrain_rounded,
                    size: 60,
                    color: context.themeTextSecondary,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 20,
              right: 20,
              bottom: 20,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFF3D3D),
                    width: 2.0,
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 12,
              left: 14,
              child: CircleAvatar(
                radius: 6,
                backgroundColor: Color(0xFFFF3D3D),
              ),
            ),
            const Positioned(
              top: 12,
              right: 14,
              child: CircleAvatar(
                radius: 6,
                backgroundColor: Color(0xFFFF3D3D),
              ),
            ),
            const Positioned(
              bottom: 14,
              left: 14,
              child: CircleAvatar(
                radius: 6,
                backgroundColor: Color(0xFFFF3D3D),
              ),
            ),
            const Positioned(
              bottom: 14,
              right: 14,
              child: CircleAvatar(
                radius: 6,
                backgroundColor: Color(0xFFFF3D3D),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.themeCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.themeBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 14, color: context.themePrimary),
                    const SizedBox(width: 6),
                    Text(
                      '4.5 km²',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Area Pilihan: $_areaTitle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.themeText,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: context.themePrimary),
              const SizedBox(width: 4),
              Text(
                '4°59\'48.0"S 119°42\'36.0"E',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.themeTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSingleMapPackageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.themePrimary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.themePrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Icon(
                  Icons.offline_pin_rounded,
                  color: context.themePrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paket Peta Lengkap',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Peta topografi & kontur elevasi',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: context.themePrimaryFixed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _mapSize,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.themePrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: context.themeBorder, height: 1),
          const SizedBox(height: 12),
          _buildFeatureItem('Navigasi & kompas GPS 100% tanpa sinyal'),
          const SizedBox(height: 6),
          _buildFeatureItem('Kontur elevasi dan data jalur lengkap'),
          const SizedBox(height: 6),
          _buildFeatureItem('Titik pos, tebing, goa, dan sumber air'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: context.themePrimary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.themeTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Penyimpanan Perangkat',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: context.themeText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tersisa: 14.5 GB',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.themeTextSecondary,
                ),
              ),
              Text(
                'Ukuran: $_mapSize',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.themePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.15,
              minHeight: 8,
              backgroundColor: context.themeSurface,
              valueColor: AlwaysStoppedAnimation<Color>(context.themePrimary),
            ),
          ),
        ],
      ),
    );
  }
}
