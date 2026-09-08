import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';

class TulisUlasanPage extends StatefulWidget {
  final String title;
  final String date;
  final String thumbnail;

  const TulisUlasanPage({
    super.key,
    this.title = 'Citatah Ekspedisi',
    this.date = '12 Okt 2023',
    this.thumbnail = 'assets/images/fotober4.jpeg',
  });

  @override
  State<TulisUlasanPage> createState() => _TulisUlasanPageState();
}

class _TulisUlasanPageState extends State<TulisUlasanPage> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // List foto yang dipilih pengguna
  final List<File> _selectedFiles = [];
  bool _isLoading = false;

  // Dialog / BottomSheet untuk memilih sumber foto (Kamera atau Galeri)
  void _showImageSourceDialog() {
    if (_selectedFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 5 foto yang dapat diunggah.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.themePrimaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: context.themePrimary,
                    ),
                  ),
                  title: Text(
                    'Kamera',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.themeText,
                    ),
                  ),
                  subtitle: Text(
                    'Ambil foto langsung dengan kamera',
                    style: TextStyle(color: context.themeTextSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.themePrimaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: context.themePrimary,
                    ),
                  ),
                  title: Text(
                    'Galeri',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.themeText,
                    ),
                  ),
                  subtitle: Text(
                    'Pilih foto dari galeri perangkat',
                    style: TextStyle(color: context.themeTextSecondary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickMultiImageFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi mengambil foto dari kamera atau single image
  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        requestFullMetadata: false,
      );

      if (pickedFile != null) {
        if (_selectedFiles.length < 5) {
          setState(() {
            _selectedFiles.add(File(pickedFile.path));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Fungsi memilih multiple image dari galeri
  Future<void> _pickMultiImageFromGallery() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
        requestFullMetadata: false,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (final file in pickedFiles) {
            if (_selectedFiles.length < 5) {
              _selectedFiles.add(File(file.path));
            } else {
              break;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka galeri: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _submitReview() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih rating bintang terlebih dahulu.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi pengalaman Anda.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'rating': _rating,
      'comment': _reviewController.text.trim(),
      'photos': _selectedFiles.map((f) => f.path).toList(),
      'date': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
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
          icon: Icon(Icons.arrow_back, color: context.themePrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Reviews',
          style: TextStyle(
            color: context.themePrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Kartu Header Ekspedisi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themeCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      widget.thumbnail,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 60,
                        height: 60,
                        color: context.themeSurface,
                        child: Icon(Icons.landscape, color: context.themeTextSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.themeText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: context.themeTextSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Rating Bintang Interaktif
            Center(
              child: Column(
                children: [
                  Text(
                    'Bagaimana pengalaman\nAnda?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.themePrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _rating = starNum;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(
                            starNum <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 44,
                            color: starNum <= _rating
                                ? context.themeGold
                                : context.themeTextSecondary.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 3. Form Input Teks
            Text(
              'Ceritakan pengalamanmu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.themeText,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.themeCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: 5,
                style: TextStyle(fontSize: 13.5, color: context.themeText),
                decoration: InputDecoration(
                  hintText: 'Ceritakan lebih detail pengalamanmu...',
                  hintStyle: TextStyle(
                    color: context.themeTextSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. Bagian Upload Foto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambahkan Foto${_selectedFiles.isNotEmpty ? ' (${_selectedFiles.length}/5)' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
                Text(
                  'Opsional',
                  style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Baris Tombol Upload & Pratinjau Foto
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Kotak Tombol Upload
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _showImageSourceDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: context.themeSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: _isLoading
                            ? Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: context.themePrimary,
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    size: 26,
                                    color: context.themePrimary,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Upload',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.themePrimary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Daftar Foto yang Berhasil Dipilih dari Galeri
                  ..._selectedFiles.asMap().entries.map((entry) {
                    final int idx = entry.key;
                    final File file = entry.value;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.themeBorder),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(file, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _removePhoto(idx),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black87,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 5. Tombol Kirim Ulasan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Kirim Ulasan',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF0F1713) : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
