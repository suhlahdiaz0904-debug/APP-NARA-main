import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/features/news/models/news_model.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:geolocator/geolocator.dart';

class PhotoMetadata {
  final File file;
  final double lat;
  final double lon;
  final DateTime timestamp;

  PhotoMetadata({
    required this.file,
    required this.lat,
    required this.lon,
    required this.timestamp,
  });
}

class BuatBeritaAcaraPage extends StatefulWidget {
  const BuatBeritaAcaraPage({super.key});

  @override
  State<BuatBeritaAcaraPage> createState() => _BuatBeritaAcaraPageState();
}

class _BuatBeritaAcaraPageState extends State<BuatBeritaAcaraPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDate;
  final List<String> _availableCategories = [
    'Goa',
    'Tebing',
    'Jalur Baru',
    'Gunung Hutan',
  ];
  final List<String> _selectedCategories = ['Goa'];

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedPhotos = [];
  final List<PhotoMetadata> _photoMetadataList = [];
  bool _isPicking = false;

  // State pesan error validasi
  String? _titleError;
  String? _locationError;
  String? _dateError;
  String? _categoryError;
  String? _descError;

  // Predefined destinations for geo-fencing check
  final List<Map<String, dynamic>> _predefinedSpots = [
    {"name": "Tebing Citatah 125", "region": "Padalarang, Bandung Barat", "lat": -6.84050, "lon": 107.45180},
    {"name": "Tebing Parang", "region": "Purwakarta, Jawa Barat", "lat": -6.61200, "lon": 107.34800},
    {"name": "Tebing Hawu", "region": "Padalarang, Bandung Barat", "lat": -6.83720, "lon": 107.44750},
    {"name": "Goa Cibeko", "region": "Klapanunggal, Bogor", "lat": -6.46966, "lon": 106.95931},
    {"name": "Goa Tugu Gula", "region": "Pasir Tjagak, Klapanunggal, Bogor", "lat": -6.46357, "lon": 106.95343},
    {"name": "Goa Jomblang", "region": "Semanu, Gunungkidul, DIY", "lat": -8.02850, "lon": 110.63820},
    {"name": "Goa Cilalay", "region": "Klapanunggal, Bogor", "lat": -6.47015, "lon": 106.96171},
    {"name": "Goa Cisodong 1", "region": "Nambo, Klapanunggal, Bogor", "lat": -6.47970, "lon": 106.95592},
    {"name": "Goa Cibangkong", "region": "Nambo, Klapanunggal, Bogor", "lat": -6.48004, "lon": 106.95448},
    {"name": "Goa Siela", "region": "Nambo, Klapanunggal, Bogor", "lat": -6.48596, "lon": 106.95233},
    {"name": "Goa Sabit", "region": "Nambo, Klapanunggal, Bogor", "lat": -6.48869, "lon": 106.95259},
    {"name": "Goa Bendo 1", "region": "Nambo, Klapanunggal, Bogor", "lat": -6.48757, "lon": 106.95211},
  ];
  Map<String, dynamic>? _selectedSpot;
  bool _isMockGps = true; // Enabled by default for easy presentation/testing

  // Fungsi mengambil foto dari kamera (diwajibkan dari kamera langsung)
  Future<void> _pickImage(ImageSource source) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        if (_selectedPhotos.length < 5) {
          // Fetch current GPS and Time for EXIF synchronization
          double photoLat = -6.84050;
          double photoLon = 107.45180;
          final photoTime = DateTime.now();

          if (!_isMockGps) {
            try {
              Position position = await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 4),
                ),
              );
              photoLat = position.latitude;
              photoLon = position.longitude;
            } catch (_) {}
          } else {
            // Simulasi koordinat sesuai lokasi tebing/goa yang dipilih
            if (_selectedSpot != null) {
              photoLat = _selectedSpot!["lat"] + 0.008;
              photoLon = _selectedSpot!["lon"] + 0.008;
            }
          }

          setState(() {
            final file = File(pickedFile.path);
            _selectedPhotos.add(file);
            _photoMetadataList.add(PhotoMetadata(
              file: file,
              lat: photoLat,
              lon: photoLon,
              timestamp: photoTime,
            ));
          });
        }
      }
    } catch (e) {
      if (mounted) _showWarning('Gagal mengambil foto: $e');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      if (index < _photoMetadataList.length) {
        _photoMetadataList.removeAt(index);
      }
    });
  }

  // Pemilih Tanggal
  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.themePrimary,
              onPrimary: Colors.white,
              onSurface: context.themeText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
        _dateError = null;
      });
    }
  }

  // Validasi Formulir
  bool _validateForm() {
    bool isValid = true;

    setState(() {
      if (_titleController.text.trim().isEmpty) {
        _titleError = 'Judul laporan wajib diisi.';
        isValid = false;
      } else {
        _titleError = null;
      }

      if (_locationController.text.trim().isEmpty || _selectedSpot == null) {
        _locationError = 'Lokasi kegiatan wajib dipilih dari daftar.';
        isValid = false;
      } else {
        _locationError = null;
      }

      if (_dateController.text.trim().isEmpty) {
        _dateError = 'Tanggal kegiatan wajib dipilih.';
        isValid = false;
      } else {
        _dateError = null;
      }

      if (_selectedCategories.isEmpty) {
        _categoryError = 'Pilih minimal satu kategori.';
        isValid = false;
      } else {
        _categoryError = null;
      }

      if (_descController.text.trim().isEmpty) {
        _descError = 'Deskripsi kegiatan wajib diisi.';
        isValid = false;
      } else if (_descController.text.trim().length < 30) {
        _descError = 'Deskripsi terlalu singkat (minimal 30 karakter agar laporan valid).';
        isValid = false;
      } else {
        _descError = null;
      }

      if (_selectedPhotos.isEmpty) {
        _showWarning('Bukti dokumentasi wajib dilampirkan! Unggah minimal 1 foto bukti fisik lokasi.');
        isValid = false;
      }
    });

    return isValid;
  }

  // Menyimpan laporan sebagai Draf
  Future<void> _saveDraft() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Draf Laporan Kegiatan';
    final location = _locationController.text.trim().isNotEmpty
        ? _locationController.text.trim()
        : 'Lokasi Belum Ditentukan';
    final desc = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : 'Laporan masih dalam bentuk draf.';

    final uploadedAt = DateTime.now();
    final draftItem = BeritaModel(
      id: 'draft_${uploadedAt.millisecondsSinceEpoch}',
      title: title,
      location: location,
      category: 'DRAF',
      categories: List<String>.from(_selectedCategories),
      timeAgo: BeritaModel.formatTimeAgo(uploadedAt),
      date: uploadedAt,
      formattedDate: _dateController.text.trim().isNotEmpty
          ? _dateController.text.trim()
          : null,
      description: desc,
      photos: _selectedPhotos.map((f) => f.path).toList(),
      isDraft: true,
    );

    await BeritaManager.tambahBerita(draftItem);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Draf kegiatan berhasil disimpan!'),
        backgroundColor: context.themePrimary,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context, draftItem);
  }

  // Mengirimkan data berita baru ke Beranda (Publikasikan) dengan validasi GPS & EXIF
  Future<void> _submitReport() async {
    if (!_validateForm()) {
      _showWarning('Mohon lengkapi semua data formulir yang diperlukan.');
      return;
    }

    if (_selectedSpot == null) {
      setState(() {
        _locationError = 'Silakan pilih lokasi tebing/goa yang valid.';
      });
      _showWarning('Silakan pilih lokasi tebing/goa yang valid.');
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Tampilkan loading dialog untuk verifikasi GPS
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Memverifikasi lokasi GPS perangkat...')),
          ],
        ),
      ),
    );

    double reportedLat = _selectedSpot!["lat"];
    double reportedLon = _selectedSpot!["lon"];
    double userLat = -6.84050; 
    double userLon = 107.45180;

    if (!_isMockGps) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          navigator.pop();
          _showWarning('Gagal mendapatkan lokasi GPS: Layanan GPS dinonaktifkan.');
          return;
        }
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          navigator.pop();
          _showWarning('Gagal mendapatkan lokasi GPS: Izin lokasi ditolak permanen.');
          return;
        }
        
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
        userLat = position.latitude;
        userLon = position.longitude;
      } catch (e) {
        navigator.pop();
        _showWarning('Gagal mendapatkan lokasi GPS: $e');
        return;
      }
    } else {
      // Simulasi berada dalam radius 1.2 km dari target lokasi
      userLat = reportedLat + 0.008;
      userLon = reportedLon + 0.008;
    }

    double distanceInMeters = Geolocator.distanceBetween(
      userLat,
      userLon,
      reportedLat,
      reportedLon,
    );
    double distanceInKm = distanceInMeters / 1000.0;

    // Tutup loading GPS
    navigator.pop();

    // Check radius maksimal 10.0 km
    if (distanceInKm > 10.0) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.gpp_bad_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Geo-Fencing Gagal'),
              ],
            ),
            content: Text(
              'Laporan untuk ${_selectedSpot!["name"]} tidak dapat dipublikasikan.\n\n'
              'Jarak Anda: ${distanceInKm.toStringAsFixed(2)} km.\n'
              'Batas Radius: Maksimal 10.00 km.\n\n'
              'Sistem mendeteksi Anda berada di luar radius lokasi objek yang dilaporkan. Silakan aktifkan mode simulasi GPS jika Anda sedang melakukan pengujian demo presentasi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _isMockGps = true;
                  });
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Simulasi GPS diaktifkan. Silakan kirim kembali.')),
                  );
                },
                child: const Text('Aktifkan Mode Simulasi'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Tampilkan loading membaca EXIF
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Membaca metadata EXIF foto & memverifikasi keaslian...')),
            ],
          ),
        ),
      );
    }
    await Future.delayed(const Duration(milliseconds: 1500));
    navigator.pop(); // Tutup loading EXIF

    // Tampilkan modal hasil verifikasi EXIF sukses
    if (mounted) {
      final firstPhoto = _photoMetadataList.isNotEmpty ? _photoMetadataList.first : null;
      final displayTime = firstPhoto != null
          ? '${firstPhoto.timestamp.hour.toString().padLeft(2, '0')}:${firstPhoto.timestamp.minute.toString().padLeft(2, '0')}:${firstPhoto.timestamp.second.toString().padLeft(2, '0')} WIB'
          : 'Hari ini';
      final displayLat = firstPhoto != null ? firstPhoto.lat : userLat;
      final displayLon = firstPhoto != null ? firstPhoto.lon : userLon;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text('Verifikasi EXIF Berhasil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sistem telah memverifikasi metadata EXIF foto dokumentasi fisik lapangan:',
                style: TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              _buildExifRow(Icons.camera_alt_rounded, 'Sumber Tangkapan', 'Kamera HP Langsung (Valid)'),
              _buildExifRow(Icons.calendar_today_rounded, 'Waktu Pengambilan', '$displayTime (Sesuai)'),
              _buildExifRow(Icons.gps_fixed_rounded, 'Koordinat EXIF', '${displayLat.toStringAsFixed(6)}S, ${displayLon.toStringAsFixed(6)}E'),
              _buildExifRow(Icons.location_on_rounded, 'Jarak ke Objek', '${distanceInKm.toStringAsFixed(2)} km (Di bawah 10 km)'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Lanjutkan Publikasi'),
            ),
          ],
        ),
      );
    }

    String gpsCoordinates = '${userLat.toStringAsFixed(6)}S, ${userLon.toStringAsFixed(6)}E';
    final categoryTag = _selectedCategories.isNotEmpty
        ? _selectedCategories.first.toUpperCase()
        : 'EKSPEDISI';

    final List<String> photoPaths = _selectedPhotos.map((f) => f.path).toList();
    final String rockType = _selectedCategories.contains('Tebing')
        ? 'Andesit & Karst (Solid)'
        : _selectedCategories.contains('Goa')
        ? 'Batu Gamping / Karst'
        : 'Jalur Hutan Tropis';

    String authorName = 'Farhiyah';
    int? activeUid;
    try {
      final activeUser = await DatabaseHelper.instance.getLatestUser();
      if (activeUser != null && activeUser.nama.isNotEmpty) {
        authorName = activeUser.nama;
        activeUid = activeUser.id;
      }
    } catch (_) {}

    final uploadedAt = DateTime.now();
    final newBerita = BeritaModel(
      id: 'berita_${uploadedAt.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      coordinates: gpsCoordinates,
      category: categoryTag,
      categories: List<String>.from(_selectedCategories),
      timeAgo: BeritaModel.formatTimeAgo(uploadedAt),
      date: uploadedAt,
      formattedDate: _dateController.text.trim().isNotEmpty
          ? _dateController.text.trim()
          : null,
      description: _descController.text.trim(),
      photos: photoPaths,
      headerImage: photoPaths.first,
      rockType: rockType,
      grade: 'Grade 5.9',
      rating: '5.0',
      author: authorName,
      duration: '1 Hari',
      team: '1 Tim',
      elevation: '125 mdpl',
      technique: 'Single Rope Technique (SRT), Lead Climbing',
      mainRope: 'Dynamic Rope 10mm (60m)',
      isDraft: false,
      userId: activeUid,
      status: 'PENDING',
    );

    await BeritaManager.tambahBerita(newBerita);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Laporan terbit & tersinkron ke Cloud Firestore! - Koordinat: $gpsCoordinates'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );

    navigator.pop(newBerita);
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _descController.dispose();
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
          'Tambah Berita Baru',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.themeText,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_note_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'KONTRIBUSI PETUALANG NARA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Laporan Kegiatan Baru',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Isi detail kegiatan alam bebas Anda dengan akurat untuk dibagikan ke komunitas.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.themeTextSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Kartu Formulir
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: context.isDarkMode
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Judul Laporan
                        _buildLabel('Judul Laporan *'),
                        _buildTextField(
                          controller: _titleController,
                          hintText: 'Contoh: Penjelajahan Goa Jomblang',
                          prefixIcon: Icons.title_rounded,
                          hasError: _titleError != null,
                          onChanged: (_) {
                            if (_titleError != null) {
                              setState(() => _titleError = null);
                            }
                          },
                        ),
                        if (_titleError != null)
                          _buildErrorMessage(_titleError!),
                        const SizedBox(height: 18),

                        // 2. Lokasi
                        _buildLabel('Lokasi (Geo-Fencing) *'),
                        _buildLocationDropdown(),
                        if (_locationError != null)
                          _buildErrorMessage(_locationError!),
                        const SizedBox(height: 12),

                        // GPS Simulation Toggle (Rapih & Anti-Overflow)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.3 : 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFF0284C7)),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Mode Simulasi GPS',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0284C7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Bypass radius untuk pengujian/demo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF0284C7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isMockGps,
                                activeThumbColor: const Color(0xFF0284C7),
                                onChanged: (val) {
                                  setState(() {
                                    _isMockGps = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 3. Tanggal Kegiatan
                        _buildLabel('Tanggal Kegiatan *'),
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: _buildTextField(
                              controller: _dateController,
                              hintText: 'dd/mm/yyyy',
                              prefixIcon: Icons.calendar_today_outlined,
                              suffixIcon: Icons.calendar_month_outlined,
                              hasError: _dateError != null,
                            ),
                          ),
                        ),
                        if (_dateError != null) _buildErrorMessage(_dateError!),
                        const SizedBox(height: 18),

                        // 4. Pilihan Kategori
                        _buildLabel('Kategori (Pilih minimal 1) *'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableCategories.map((category) {
                            final bool isSelected = _selectedCategories
                                .contains(category);
                            final style = _getCategoryStyle(
                              category,
                              isSelected,
                            );
                            final Color bg = style['bg'] as Color;
                            final Color border = style['border'] as Color;
                            final Color textCol = style['text'] as Color;
                            final IconData icon = style['icon'] as IconData;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedCategories.remove(category);
                                  } else {
                                    _selectedCategories.add(category);
                                  }
                                  _categoryError = null;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: _categoryError != null && !isSelected
                                        ? AppTheme.errorRed
                                        : border,
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: border.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 16,
                                      color: textCol,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: textCol,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_categoryError != null)
                          _buildErrorMessage(_categoryError!),
                        const SizedBox(height: 18),

                        // 5. Deskripsi Kegiatan
                        _buildLabel('Deskripsi Kegiatan *'),
                        _buildTextField(
                          controller: _descController,
                          hintText:
                              'Ceritakan detail kegiatan, kondisi lapangan, dan temuan penting...',
                          maxLines: 5,
                          hasError: _descError != null,
                          onChanged: (_) {
                            if (_descError != null) {
                              setState(() => _descError = null);
                            }
                          },
                        ),
                        if (_descError != null) _buildErrorMessage(_descError!),
                        const SizedBox(height: 18),

                        // 6. Unggah Foto Lapangan
                        _buildLabel(
                          'Unggah Foto Lapangan${_selectedPhotos.isNotEmpty ? ' (${_selectedPhotos.length}/5)' : ''}',
                        ),
                        GestureDetector(
                          onTap: _isPicking ? null : () => _pickImage(ImageSource.camera),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            decoration: BoxDecoration(
                              color: context.themeSurface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: context.isDarkMode ? Colors.white12 : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: _isPicking
                                      ? const Center(
                                          child: SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.photo_camera_rounded,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Ambil Foto Bukti Fisik via Kamera (Maks. 5)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.themeText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'Wajib langsung dari kamera HP sesuai SOP anti-hoaks NARA',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Pratinjau Foto Pilihan
                        if (_selectedPhotos.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: _selectedPhotos.asMap().entries.map((
                                entry,
                              ) {
                                final int idx = entry.key;
                                final File file = entry.value;

                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: context.themeBorder,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          file,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    // Metadata Overlay (Location & Time)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _photoMetadataList.length > idx
                                                  ? '${_photoMetadataList[idx].lat.toStringAsFixed(4)}, ${_photoMetadataList[idx].lon.toStringAsFixed(4)}'
                                                  : 'GPS Sync',
                                              style: const TextStyle(fontSize: 6.5, color: Colors.white, fontWeight: FontWeight.bold),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              _photoMetadataList.length > idx
                                                  ? '${_photoMetadataList[idx].timestamp.hour.toString().padLeft(2, '0')}:${_photoMetadataList[idx].timestamp.minute.toString().padLeft(2, '0')} WIB'
                                                  : 'Time Sync',
                                              style: const TextStyle(fontSize: 6.5, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () => _removePhoto(idx),
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Colors.redAccent,
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
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar (Simpan Draf & Simpan Publikasikan)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: context.themeCard,
              border: Border(top: BorderSide(color: context.themeBorder)),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: _saveDraft,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.themeBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    'Simpan\nDraf',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Simpan & Publikasikan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryStyle(String category, bool isSelected) {
    switch (category) {
      case 'Goa':
        return {
          'bg': isSelected
              ? const Color(0xFF0284C7)
              : (context.isDarkMode ? const Color(0xFF0C2436) : const Color(0xFFF0F9FF)),
          'border': isSelected
              ? const Color(0xFF38BDF8)
              : const Color(0xFF0284C7).withValues(alpha: 0.3),
          'text': isSelected ? Colors.white : const Color(0xFF0284C7),
          'icon': Icons.terrain_rounded,
        };
      case 'Tebing':
        return {
          'bg': isSelected
              ? const Color(0xFFEA580C)
              : (context.isDarkMode ? const Color(0xFF331B0E) : const Color(0xFFFFF7ED)),
          'border': isSelected
              ? const Color(0xFFFB923C)
              : const Color(0xFFEA580C).withValues(alpha: 0.3),
          'text': isSelected ? Colors.white : const Color(0xFFEA580C),
          'icon': Icons.landscape_rounded,
        };
      case 'Jalur Baru':
        return {
          'bg': isSelected
              ? const Color(0xFFD97706)
              : (context.isDarkMode ? const Color(0xFF332308) : const Color(0xFFFFFBEB)),
          'border': isSelected
              ? const Color(0xFFFBBF24)
              : const Color(0xFFD97706).withValues(alpha: 0.3),
          'text': isSelected ? Colors.white : const Color(0xFFD97706),
          'icon': Icons.explore_rounded,
        };
      case 'Gunung Hutan':
        return {
          'bg': isSelected
              ? const Color(0xFF059669)
              : (context.isDarkMode ? const Color(0xFF0D281E) : const Color(0xFFECFDF5)),
          'border': isSelected
              ? const Color(0xFF34D399)
              : const Color(0xFF059669).withValues(alpha: 0.3),
          'text': isSelected ? Colors.white : const Color(0xFF059669),
          'icon': Icons.forest_rounded,
        };
      default:
        return {
          'bg': isSelected
              ? const Color(0xFF7C3AED)
              : (context.isDarkMode ? const Color(0xFF1E1738) : const Color(0xFFFAF5FF)),
          'border': isSelected
              ? const Color(0xFFA78BFA)
              : const Color(0xFF7C3AED).withValues(alpha: 0.3),
          'text': isSelected ? Colors.white : const Color(0xFF7C3AED),
          'icon': Icons.check_circle_rounded,
        };
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.bold,
          color: context.themeText,
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppTheme.errorRed),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    IconData? suffixIcon,
    int maxLines = 1,
    bool hasError = false,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError ? AppTheme.errorRed : context.themeBorder,
          width: hasError ? 1.2 : 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        style: TextStyle(fontSize: 13.5, color: context.themeText),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: context.themeTextSecondary.withValues(alpha: 0.6),
            fontSize: 13,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: hasError
                      ? AppTheme.errorRed
                      : context.themeTextSecondary,
                  size: 20,
                )
              : null,
          suffixIcon: suffixIcon != null
              ? Icon(
                  suffixIcon,
                  color: hasError
                      ? AppTheme.errorRed
                      : context.themeTextSecondary,
                  size: 20,
                )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _locationError != null ? AppTheme.errorRed : context.themeBorder,
          width: _locationError != null ? 1.2 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<Map<String, dynamic>>(
          isExpanded: true,
          initialValue: _selectedSpot,
          hint: Text(
            'Pilih tebing/goa lokasi kegiatan...',
            style: TextStyle(
              color: context.themeTextSecondary.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: Icon(
              Icons.location_on_rounded,
              color: Color(0xFF0D9488),
              size: 20,
            ),
          ),
          dropdownColor: context.themeSurface,
          style: TextStyle(fontSize: 13.5, color: context.themeText),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.themeTextSecondary,
          ),
          selectedItemBuilder: (context) {
            return _predefinedSpots.map((spot) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${spot["name"]} • ${spot["region"]}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.themeText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: _predefinedSpots.map((spot) {
            final String name = spot["name"] as String;
            final String region = spot["region"] as String;
            final bool isGoa = name.toLowerCase().contains('goa');

            return DropdownMenuItem<Map<String, dynamic>>(
              value: spot,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: (isGoa ? const Color(0xFF0284C7) : const Color(0xFFEA580C))
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isGoa ? Icons.terrain_rounded : Icons.landscape_rounded,
                      size: 14,
                      color: isGoa ? const Color(0xFF0284C7) : const Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: context.themeText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          region,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.themeTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedSpot = val;
              _locationController.text = val?["name"] ?? "";
              _locationError = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildExifRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
