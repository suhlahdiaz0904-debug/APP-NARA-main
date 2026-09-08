import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/map/screens/interactive_map_screen.dart';
import 'package:flutter_application_1/features/news/screens/news_screen.dart';
import 'package:flutter_application_1/core/services/review_sync_service.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';

// =========================================================================
// HALAMAN INFORMASI TEMPAT & DETAIL SPOT (TEBING & GOA) - NARA WILDERNESS
// Desain 1:1 Google Stitch: Detail Ekspedisi (ID)
// Screen Node: dd6a6b6910d745eda33e438ca20005c9
// Menampilkan Spesifikasi Teknis Bento, Info Basecamp, Ulasan, dan Tombol Navigasi
// =========================================================================

class SpotInfoModel {
  final String title;
  final String location;
  final String coordinates;
  final double lat;
  final double lon;
  final String rating;
  final String reviewCount;
  final String type; // e.g. Rock Climbing, Caving Speleologi
  final String rockType; // e.g. Andesit & Limestone, Karst Kalsit
  final String elevation; // e.g. 125 Meter, Kedalaman 60m
  final String grade; // e.g. Grade 5.9 - 5.11 (YDS)
  final List<Map<String, String>> technicalBreakdown;
  final String techniqueNote;
  final String basecampName;
  final String basecampPhone;
  final String basecampImage;
  final String imageUrl;
  final List<Map<String, dynamic>> reviews;

  const SpotInfoModel({
    required this.title,
    required this.location,
    required this.coordinates,
    required this.lat,
    required this.lon,
    required this.rating,
    required this.reviewCount,
    required this.type,
    required this.rockType,
    required this.elevation,
    required this.grade,
    required this.technicalBreakdown,
    required this.techniqueNote,
    required this.basecampName,
    required this.basecampPhone,
    required this.basecampImage,
    required this.imageUrl,
    this.reviews = const [],
  });

  // Data Builder Standar Berdasarkan Nama Tebing/Goa
  static SpotInfoModel getDetailsForSpot(Map<String, dynamic> raw) {
    final String title = raw['title'] ?? 'Tebing Citatah 125';
    final String location = raw['location'] ?? 'Padalarang, Bandung Barat';
    final String coordinates = raw['coordinates'] ?? '6°50\'16.1"S 107°27\'00.4"E';
    final double lat = (raw['lat'] as num?)?.toDouble() ?? -6.8378;
    final double lon = (raw['lon'] as num?)?.toDouble() ?? 107.4501;
    final String rating = raw['rating']?.toString() ?? '4.8';
    final String type = raw['type'] ?? 'Rock Climbing';
    final String elevation = raw['elevation'] ?? '125 Meter';
    final String imageUrl = raw['imageUrl'] ?? 'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=800';

    final bool isCave = title.toLowerCase().contains('goa') || type.toLowerCase().contains('caving') || type.toLowerCase().contains('luweng');

    if (isCave) {
      return SpotInfoModel(
        title: title,
        location: location,
        coordinates: coordinates,
        lat: lat,
        lon: lon,
        rating: rating,
        reviewCount: '0 Ulasan',
        type: 'Caving Speleologi',
        rockType: 'Karst Kalsit Vertikal',
        elevation: elevation,
        grade: 'SRT Level 2 (Single Rope Technique)',
        technicalBreakdown: [
          {
            'level': 'Pitch 1 (0-25m)',
            'desc': 'Turunan vertikal bebas (free hang) dengan lintasan tali statis 11mm.',
          },
          {
            'level': 'Pitch 2 (25-60m)',
            'desc': 'Zona gelap total (dark zone) dengan ornamen stalaktit aktif dan lantai lumpur.',
          },
          {
            'level': 'Lorong Horisontal',
            'desc': 'Jalur penghubung sepanjang 300m menuju lorong cahaya surga (Ray of Light).',
          },
        ],
        techniqueNote: 'Wajib menggunakan helm speleo dengan headlamp waterproof dan cowstail ganda.',
        basecampName: 'Basecamp Speleo Nusantara $title',
        basecampPhone: '0812-3456-7890',
        basecampImage: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
        imageUrl: imageUrl,
        reviews: const [],
      );
    }

    return SpotInfoModel(
      title: title,
      location: location,
      coordinates: coordinates,
      lat: lat,
      lon: lon,
      rating: rating,
      reviewCount: '0 Ulasan',
      type: 'Rock Climbing',
      rockType: 'Andesit & Limestone',
      elevation: elevation,
      grade: 'Grade 5.9 - 5.11 (Yosemite Decimal System)',
      technicalBreakdown: [
        {
          'level': 'Kelas 5.9',
          'desc': 'Menengah. Menantang bagi pemula, membutuhkan pijakan kaki dan keseimbangan yang baik.',
        },
        {
          'level': 'Kelas 5.10',
          'desc': 'Lanjutan. Membutuhkan gerakan teknis, kekuatan, dan teknik memanjat yang spesifik.',
        },
        {
          'level': 'Kelas 5.11',
          'desc': 'Ahli. Sangat teknis dan menuntut, sering kali melibatkan pegangan kecil (crimp) dan urutan gerakan kompleks.',
        },
      ],
      techniqueNote: 'Membutuhkan teknik \'Face Climbing\' dan manajemen tali yang baik pada sektor atas.',
      basecampName: 'Basecamp Citatah Paimpuran',
      basecampPhone: '0812-3456-7890',
      basecampImage: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
      imageUrl: imageUrl,
      reviews: const [],
    );
  }
}

class InformasiTempatPage extends StatefulWidget {
  final Map<String, dynamic> spotData;

  const InformasiTempatPage({
    super.key,
    required this.spotData,
  });

  @override
  State<InformasiTempatPage> createState() => _InformasiTempatPageState();
}

class _InformasiTempatPageState extends State<InformasiTempatPage> {
  // Palet Warna Sesuai Desain Earth Tone NARA
  static const Color darkGreen = Color(0xFF1E382B); // Deep Forest Moss
  static const Color forestDeep = Color(0xFF1E382B); // Deep Forest Moss
  static const Color bgCream = Color(0xFFF6F3EC); // Sandstone Linen
  static const Color cardLowest = Color(0xFFFFFFFF); // Warm White Card
  static const Color surfaceContainer = Color(0xFFECE6DA); // Warm Oat Pebble
  static const Color primaryFixed = Color(0xFFCFE3D5); // Soft Sage Meadow
  static const Color secondaryFixed = Color(0xFFE9C46A); // Warm Ochre
  static const Color secondaryGold = Color(0xFFDDA15E); // Warm Desert Ochre Gold
  static const Color roseAccent = Color(0xFFB8786B); // Dusty Clay Rose
  static const Color textDark = Color(0xFF26201B); // Deep Espresso Bark
  static const Color textVariant = Color(0xFF4A423B); // Dark Warm Stone
  static const Color textMuted = Color(0xFF7A7065); // Warm Driftwood Stone

  bool _isBookmarked = false;
  int _currentUserId = 1;
  late SpotInfoModel _spot;
  List<ReviewItem> _reviewsList = [];
  bool _isLoadingReviews = true;

  // Sinkronisasi Internet & Wikipedia API
  String _wikipediaSummary = 'Sedang menyinkronkan data detail dari internet...';
  bool _isLoadingWiki = true;

  @override
  void initState() {
    super.initState();
    _spot = SpotInfoModel.getDetailsForSpot(widget.spotData);
    _reviewsList = [];

    _initBookmarkStatus();
    _fetchInternetDetails();
    _loadSyncedReviews();
  }

  Future<void> _loadSyncedReviews() async {
    final spotId = widget.spotData['id']?.toString() ?? _spot.title;
    try {
      final synced = await ReviewSyncService.instance.getReviewsForSpot(
        spotId: spotId,
        destinationName: _spot.title,
        fetchFromCloud: true,
      );
      if (mounted) {
        setState(() {
          _reviewsList = synced.map((m) => ReviewItem.fromModel(m)).toList();
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _initBookmarkStatus() async {
    final activeId = await DatabaseHelper.instance.getActiveUserId() ?? 1;
    final spotId = widget.spotData['id']?.toString() ?? _spot.title;
    final isSaved = await DatabaseHelper.instance.isBookmarked(activeId, spotId);
    if (mounted) {
      setState(() {
        _currentUserId = activeId;
        _isBookmarked = isSaved;
      });
    }
  }

  Future<void> _handleToggleBookmark() async {
    final spotId = widget.spotData['id']?.toString() ?? _spot.title;
    final status = await DatabaseHelper.instance.toggleBookmark(
      userId: _currentUserId,
      spotId: spotId,
      title: _spot.title,
      location: _spot.location,
      type: _spot.type,
      imageUrl: _spot.imageUrl,
      rating: _spot.rating,
      elevation: _spot.elevation,
      coordinates: _spot.coordinates,
    );

    if (mounted) {
      setState(() => _isBookmarked = status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status
                ? '⭐ ${_spot.title} disimpan ke Bookmark Anda'
                : 'Dihapus dari Bookmark Anda',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: status ? const Color(0xFF2D5A43) : const Color(0xFFC62828),
        ),
      );
    }
  }

  Future<void> _fetchInternetDetails() async {
    final rawTitle = widget.spotData['title'] ?? 'Tebing Citatah';
    final customDesc = widget.spotData['description'] as String?;

    // Bersihkan angka-angka seperti 125, 90, 350m agar pencarian Wikipedia akurat
    final cleanKeyword = rawTitle.replaceAll(RegExp(r'\d+'), '').replaceAll('mdpl', '').trim();
    final url = 'https://id.wikipedia.org/w/api.php?action=query&format=json&generator=search&gsrsearch=$cleanKeyword&prop=extracts&exintro&explaintext&exlimit=1&origin=*';

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          final firstPage = pages.values.first;
          final extract = firstPage['extract'] as String?;
          if (extract != null && extract.isNotEmpty) {
            if (mounted) {
              setState(() {
                _wikipediaSummary = (customDesc != null && customDesc.isNotEmpty)
                    ? '$customDesc\n\n$extract'
                    : extract;
                _isLoadingWiki = false;
              });
            }
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _wikipediaSummary = (customDesc != null && customDesc.isNotEmpty)
            ? customDesc
            : 'Informasi detail tempat ini berhasil dimuat secara dinamis. ${_spot.type} yang terletak di daerah ${_spot.location} ini menawarkan petualangan alam bebas menantang dengan formasi batuan ${_spot.rockType} dan elevasi spektakuler ${_spot.elevation}.';
        _isLoadingWiki = false;
      });
    }
  }

  void _bukaNavigasiPeta() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetaInteraktifPage(
          initialSpotName: _spot.title,
          initialCoordinates: _spot.coordinates,
          autoStartNavigation: true,
        ),
      ),
    );
  }

  // DIHUBUNGKAN LANGSUNG KE LOG PANGGILAN DEVICE USER
  void _hubungiBasecamp() async {
    final Uri telUri = Uri(scheme: 'tel', path: _spot.basecampPhone);
    try {
      final bool canLaunch = await launcher.canLaunchUrl(telUri);
      if (!mounted) return;
      if (canLaunch) {
        await launcher.launchUrl(telUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menghubungi ${_spot.basecampPhone}...'),
            backgroundColor: forestDeep,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka log panggilan device: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _bagikanInformasiSpot() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tautan informasi ${_spot.title} disalin ke papan klip!'),
        backgroundColor: forestDeep,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      body: Stack(
        children: [
          // 1. Konten Scrollable
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // A. Hero Header dengan Gambar, Judul & Badge
              _buildHeroHeader(),

              // B. Konten Spesifikasi, Basecamp, & Review
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 0. Wikipedia Internet Details Card
                    _buildInternetDetailsCard(),
                    const SizedBox(height: 24),

                    // 1. Technical Specifications Card (Bento Style)
                    _buildTechnicalSpecsCard(),
                    const SizedBox(height: 24),

                    // 2. Informasi Basecamp Card
                    _buildBasecampCard(),
                    const SizedBox(height: 24),

                    // 3. Community Reviews Section (Sesuai Logika & Tampilan berita.dart)
                    _buildReviewsSection(),
                    const SizedBox(height: 120), // Ruang untuk Bottom Floating Button
                  ]),
                ),
              ),
            ],
          ),

          // 2. Top Navigation Bar (Glassmorphism Back, Bookmark, Share)
          _buildTopNavOverlay(),

          // 3. Fixed Bottom Action Bar (Tombol Mulai Rute Navigasi)
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  // =========================================================================
  // 0. WIKIPEDIA INTERNET DETAILS CARD
  // =========================================================================
  Widget _buildInternetDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded, color: context.themePrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informasi Internet & Geologi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.themePrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingWiki
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: context.themePrimary,
                      ),
                    ),
                  ),
                )
              : Text(
                  _wikipediaSummary,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.themeTextSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. HERO HEADER SECTION
  // =========================================================================
  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: Container(
        height: 390,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gambar Spot
              Image.network(
                _spot.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: forestDeep,
                  child: const Icon(Icons.terrain, size: 72, color: primaryFixed),
                ),
              ),

              // Gradient Shadow Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      darkGreen.withValues(alpha: 0.35),
                      Colors.transparent,
                      darkGreen.withValues(alpha: 0.85),
                      darkGreen.withValues(alpha: 0.98),
                    ],
                    stops: const [0.0, 0.3, 0.75, 1.0],
                  ),
                ),
              ),

              // Detail Info Spot (Bawah Hero)
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lokasi Pin
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 15, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          _spot.location,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Judul Spot
                    Text(
                      _spot.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Badge Rating & Kategori
                    Row(
                      children: [
                        // Rating Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: secondaryFixed, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _spot.rating,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Kategori Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.terrain_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 5),
                              Text(
                                _spot.type,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. TOP NAV OVERLAY (BACK, BOOKMARK, SHARE)
  // =========================================================================
  Widget _buildTopNavOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tombol Kembali
          _buildGlassIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pop(context),
          ),

          // Tombol Favorit & Share
          Row(
            children: [
              _buildGlassIconButton(
                icon: _isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                iconColor: _isBookmarked ? const Color(0xFFE53935) : forestDeep,
                onTap: _handleToggleBookmark,
              ),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                icon: Icons.share_rounded,
                onTap: _bagikanInformasiSpot,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = forestDeep,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgCream.withValues(alpha: 0.85),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: iconColor, size: 20),
            onPressed: onTap,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. TECHNICAL SPECIFICATIONS BENTO CARD
  // =========================================================================
  Widget _buildTechnicalSpecsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: forestDeep.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technical Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: forestDeep,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),

          // Row 1: Jenis Batuan & Ketinggian
          Row(
            children: [
              // Jenis Batuan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgCream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: roseAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.layers_rounded, color: forestDeep, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jenis Batuan',
                              style: TextStyle(fontSize: 10.5, color: textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _spot.rockType,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Ketinggian / Kedalaman
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bgCream,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: primaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.straighten_rounded, color: forestDeep, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ketinggian',
                              style: TextStyle(fontSize: 10.5, color: textMuted, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _spot.elevation,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Detail Teknis & Kesulitan (Grade Breakdown)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bgCream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: secondaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.timeline_rounded, color: Color(0xFF776005), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Teknis & Kesulitan',
                            style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _spot.grade,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Breakdown Items
                ..._spot.technicalBreakdown.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: secondaryGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: textVariant, height: 1.35),
                              children: [
                                TextSpan(
                                  text: '${item['level']}: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                                ),
                                TextSpan(text: item['desc'] ?? ''),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),

                // Note
                Text(
                  _spot.techniqueNote,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. INFORMASI BASECAMP
  // =========================================================================
  Widget _buildBasecampCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Basecamp',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: forestDeep,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardLowest,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: forestDeep.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Foto Thumbnail Basecamp
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _spot.basecampImage,
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 58,
                    height: 58,
                    color: surfaceContainer,
                    child: const Icon(Icons.cabin_rounded, color: forestDeep),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Detail Basecamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _spot.basecampName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.call, size: 13, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          _spot.basecampPhone,
                          style: const TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Tombol Hubungi (TERHUBUNG LANGSUNG KE LOG PANGGILAN DEVICE USER)
              ElevatedButton.icon(
                onPressed: _hubungiBasecamp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: forestDeep,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.call, size: 14),
                label: const Text(
                  'Hubungi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 5. COMMUNITY REVIEWS SECTION (LOGIKA & TAMPILAN SAMA SEPERTI DI BERITA.DART)
  // =========================================================================
  Widget _buildReviewsSection() {
    final spotId = widget.spotData['id']?.toString() ?? _spot.title;
    final int totalReviews = _reviewsList.length;
    final double avgRating = totalReviews > 0
        ? (_reviewsList.fold<double>(0.0, (acc, r) => acc + r.rating) / totalReviews)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ulasan Penjelajah',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: forestDeep,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      totalReviews > 0
                          ? '${avgRating.toStringAsFixed(1)}/5 ($totalReviews Ulasan)'
                          : 'Belum Ada Ulasan',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            TextButton(
              onPressed: () async {
                // Navigasi ke ReviewsPage dari berita.dart
                final List<ReviewItem>? updatedReviews = await Navigator.push<List<ReviewItem>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewsPage(
                      initialReviews: _reviewsList,
                      spotId: spotId,
                      destinationName: _spot.title,
                      destinationImage: _spot.imageUrl,
                    ),
                  ),
                );

                if (updatedReviews != null && mounted) {
                  setState(() {
                    _reviewsList = updatedReviews;
                  });
                }
              },
              child: Text(
                totalReviews > 0 ? 'Lihat Semua' : 'Tulis Ulasan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: forestDeep,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Preview Ulasan (Menampilkan maksimal 3 ulasan pertama atau Empty State)
        if (_reviewsList.isEmpty && !_isLoadingReviews)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: cardLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 36,
                  color: forestDeep.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Belum Ada Ulasan Penjelajah',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jadilah yang pertama mengulas ${_spot.title}!',
                  style: const TextStyle(fontSize: 12, color: textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._reviewsList.take(3).map((review) => _buildReviewPreviewCard(review)),
      ],
    );
  }

  Widget _buildReviewPreviewCard(ReviewItem review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: forestDeep.withValues(alpha: 0.04),
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
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFC8E6C9),
                backgroundImage: review.avatarUrl != null && review.avatarUrl!.isNotEmpty
                    ? NetworkImage(review.avatarUrl!)
                    : null,
                child: (review.avatarUrl == null || review.avatarUrl!.isEmpty)
                    ? Text(
                        review.name.isNotEmpty ? review.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: forestDeep,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating.round() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    review.time,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review.uploadTimeFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      color: textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${review.comment}"',
            style: const TextStyle(
              fontSize: 12.5,
              fontStyle: FontStyle.italic,
              color: textVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. FIXED BOTTOM ACTION BAR (RUTE NAVIGASI)
  // =========================================================================
  Widget _buildBottomActionBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            decoration: BoxDecoration(
              color: bgCream.withValues(alpha: 0.88),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: forestDeep.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _bukaNavigasiPeta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: darkGreen.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded, size: 20, color: secondaryFixed),
                label: const Text(
                  'Mulai Navigasi Rute',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
