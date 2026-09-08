import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/map/screens/interactive_map_screen.dart';
import 'package:flutter_application_1/features/news/models/review_model.dart';
import 'package:flutter_application_1/core/services/review_sync_service.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/news/models/news_model.dart';

// =========================================================================
// MODEL DATA ULASAN
// =========================================================================
class ReviewItem {
  final String? id;
  final String name;
  final String time;
  final double rating;
  final String comment;
  final String? avatarUrl;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isSynced;

  ReviewItem({
    this.id,
    required this.name,
    required this.time,
    required this.rating,
    required this.comment,
    this.avatarUrl,
    this.imageUrl,
    DateTime? createdAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  String get uploadTimeFormatted {
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  String get displayTimestamp {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Baru saja ($uploadTimeFormatted)';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt lalu ($uploadTimeFormatted)';
    } else if (difference.inHours < 24 && now.day == createdAt.day) {
      return 'Hari ini, $uploadTimeFormatted';
    } else if (difference.inDays == 1 || (difference.inHours < 48 && now.day - createdAt.day == 1)) {
      return 'Kemarin, $uploadTimeFormatted';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final monthStr = months[createdAt.month - 1];
      return '${createdAt.day} $monthStr ${createdAt.year}, $uploadTimeFormatted';
    }
  }

  factory ReviewItem.fromModel(ReviewModel m) {
    return ReviewItem(
      id: m.id,
      name: m.userName,
      time: m.displayTimestamp,
      rating: m.rating,
      comment: m.comment,
      avatarUrl: m.userAvatar,
      imageUrl: m.photos.isNotEmpty ? m.photos.first : null,
      createdAt: m.createdAt,
      isSynced: m.isSynced,
    );
  }
}

// =========================================================================
// 1. HALAMAN LAPORAN EKSPEDISI (4 PEMUDA & PEMUDI / DETAIL LAPORAN)
// =========================================================================
class LaporanEkspedisiDetailPage extends StatefulWidget {
  final String id;
  final String title;
  final String location;
  final String coordinates;
  final String rating;
  final String category;
  final String headerImage;
  final String? docImage1;
  final String? docImage2;
  final List<String> photos;
  final String date;
  final String duration;
  final String team;
  final String elevation;
  final String description;
  final String technique;
  final String mainRope;
  final String rockType;
  final String status;
  final int verifiedCount;
  final int hoaxCount;
  final bool isAdminMode;
  final VoidCallback onStatusChanged;

  const LaporanEkspedisiDetailPage({
    super.key,
    required this.id,
    this.title = '4 Pemuda & Pemudi\nTaklukkan Tebing Citatah',
    this.location = 'Padalarang, Bandung Barat',
    this.coordinates = '6°50\'25.8"S 107°27\'06.5"E',
    this.rating = '4.8',
    this.category = 'Ekspedisi Sukses',
    this.headerImage = 'assets/images/fotober4.jpeg',
    this.docImage1,
    this.docImage2,
    this.photos = const [],
    this.date = '24 Feb 2026',
    this.duration = '2 Hari 1 Malam',
    this.team = '4 Orang',
    this.elevation = '125 mdpl',
    this.description =
        'Ekspedisi pemanjatan tebing Citatah 125, Padalarang, Jawa Barat telah sukses dilaksanakan oleh tim beranggotakan 4 orang. Cuaca cerah dan mendukung sepanjang kegiatan berlangsung, memungkinkan tim untuk fokus pada aspek teknis pemanjatan.\n\n'
        'Tebing Citatah, yang mayoritas tersusun dari batuan Andesit yang keras dan solid, memberikan tantangan tersendiri. Karakteristik batuan ini menuntut penempatan alat pengaman (anchor) yang presisi dan kehati-hatian ekstra saat memilih pijakan maupun pegangan. Tim memulai pemanjatan pada pukul 07.00 WIB untuk menghindari terik matahari siang.',
    this.technique = 'Single Rope Technique (SRT), Lead Climbing',
    this.mainRope = 'Dynamic Rope 10mm (60m)',
    this.rockType = 'Andesit Karst (Keras & Solid)',
    this.status = 'VALID',
    this.verifiedCount = 0,
    this.hoaxCount = 0,
    this.isAdminMode = false,
    required this.onStatusChanged,
  });

  @override
  State<LaporanEkspedisiDetailPage> createState() => _LaporanEkspedisiDetailPageState();
}

class _LaporanEkspedisiDetailPageState extends State<LaporanEkspedisiDetailPage> {
  List<ReviewItem> _reviews = [];

  Future<void> _loadReviews() async {
    try {
      final list = await ReviewSyncService.instance.getReviewsForSpot(
        spotId: widget.id,
        destinationName: widget.title,
        fetchFromCloud: false,
      );
      if (mounted) {
        setState(() {
          _reviews = list.map((m) => ReviewItem.fromModel(m)).toList();
        });
      }

      final cloudList = await ReviewSyncService.instance.getReviewsForSpot(
        spotId: widget.id,
        destinationName: widget.title,
        fetchFromCloud: true,
      );
      if (mounted && cloudList.isNotEmpty) {
        setState(() {
          _reviews = cloudList.map((m) => ReviewItem.fromModel(m)).toList();
        });
      }
    } catch (_) {}
  }

  late String _currentStatus;
  late int _currentVerifiedCount;
  late int _currentHoaxCount;
  bool _hasVoted = false;

  static const Color darkGreen = Color(0xFF0F3223);

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _currentStatus = widget.status;
    _currentVerifiedCount = widget.verifiedCount;
    _currentHoaxCount = widget.hoaxCount;
  }

  Color _getStatusColor(String status) {
    if (status == 'PENDING') return Colors.amber.shade800;
    if (status == 'HOAX') return Colors.red.shade800;
    return Colors.green.shade800;
  }

  IconData _getStatusIcon(String status) {
    if (status == 'PENDING') return Icons.hourglass_empty_rounded;
    if (status == 'HOAX') return Icons.cancel_outlined;
    return Icons.check_circle_outline_rounded;
  }

  Future<void> _vote(bool isUpvote) async {
    if (_hasVoted) return;
    await BeritaManager.voteBerita(widget.id, isUpvote: isUpvote);
    setState(() {
      if (isUpvote) {
        _currentVerifiedCount += 1;
      } else {
        _currentHoaxCount += 1;
      }
      _hasVoted = true;
    });
    widget.onStatusChanged();
  }

  Widget _buildAdaptiveImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (path.isEmpty) {
      return _buildPlaceholder(width, height);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(width, height),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(width, height),
      );
    } else {
      final file = File(path);
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(width, height),
      );
    }
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade400,
      alignment: Alignment.center,
      child: const Icon(Icons.terrain, color: Colors.white70),
    );
  }

  Widget _buildCommunityVerificationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_outline, color: darkGreen),
              SizedBox(width: 8),
              Text(
                'Verifikasi Komunitas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Bantu komunitas memverifikasi kebenaran laporan ini. Apakah laporan ini valid sesuai kondisi lapangan?',
            style: TextStyle(fontSize: 11.5, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasVoted ? null : () => _vote(true),
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 14),
                  label: Text('Ya, Valid ($_currentVerifiedCount)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasVoted ? null : () => _vote(false),
                  icon: const Icon(Icons.warning_amber_rounded, size: 14),
                  label: Text('Laporkan Hoax ($_currentHoaxCount)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade800,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (_hasVoted) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Terima kasih atas partisipasi Anda dalam memverifikasi!',
                style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      body: Column(
        children: [
          _buildFixedHeroHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 36.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Peringatan Hoaks (Admin)
                  if (_currentStatus == 'HOAX') ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'PERINGATAN: Laporan ini telah dinyatakan sebagai HOAX oleh Admin dan tidak dapat diandalkan.',
                              style: TextStyle(color: Colors.red.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                  // Banner Peringatan Hoaks (Komunitas)
                  if (_currentStatus != 'HOAX' && _currentHoaxCount >= 2) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'PERINGATAN: Laporan ini dicurigai sebagai HOAX oleh $_currentHoaxCount pengguna komunitas!',
                              style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],

                  // Panel Verifikasi Komunitas
                  _buildCommunityVerificationCard(),
                  const SizedBox(height: 16),


                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.calendar_today_outlined,
                          iconBg: const Color(0xFFE8F5E9),
                          iconColor: darkGreen,
                          label: 'TANGGAL',
                          value: widget.date,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.timer_outlined,
                          iconBg: const Color(0xFFFCEAEA),
                          iconColor: const Color(0xFFC62828),
                          label: 'DURASI',
                          value: widget.duration,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.people_outline_rounded,
                          iconBg: const Color(0xFFFFF3E0),
                          iconColor: Colors.orange.shade800,
                          label: 'TIM',
                          value: widget.team,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.terrain_outlined,
                          iconBg: const Color(0xFFEDE7F6),
                          iconColor: Colors.deepPurple,
                          label: 'KETINGGIAN',
                          value: widget.elevation,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLaporanPerjalananCard(),
                  const SizedBox(height: 24),
                  _buildDokumentasiSection(),
                  const SizedBox(height: 24),
                  _buildLokasiSection(context),
                  const SizedBox(height: 24),
                  _buildCatatanTeknisCard(),
                  const SizedBox(height: 24),
                  _buildReviewsHeader(context),
                  const SizedBox(height: 12),
                  _reviews.isEmpty
                      ? _buildEmptyReviewsState(context)
                      : _buildReviewPreviewCard(_reviews.first),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeroHeader(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 310,
            child: _buildAdaptiveImage(
              widget.headerImage,
              width: double.infinity,
              height: 310,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: Colors.black87,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.location,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.rating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.terrain_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_currentStatus).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(_currentStatus),
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentStatus.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF757575),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanPerjalananCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: darkGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Laporan Perjalanan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.description,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF424242),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDokumentasiSection() {
    final List<String> docImages = [];
    if (widget.photos.isNotEmpty) {
      docImages.addAll(widget.photos);
    } else {
      if (widget.docImage1 != null && widget.docImage1!.isNotEmpty) {
        docImages.add(widget.docImage1!);
      }
      if (widget.docImage2 != null && widget.docImage2!.isNotEmpty) {
        docImages.add(widget.docImage2!);
      }
      if (docImages.isEmpty) {
        docImages.add('assets/images/fotocitatah1.jpeg');
        docImages.add('assets/images/fotocitatah2.jpeg');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.photo_library_outlined, color: darkGreen, size: 18),
            SizedBox(width: 8),
            Text(
              'Dokumentasi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (docImages.length == 1)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: _buildAdaptiveImage(docImages.first, height: 160),
            ),
          )
        else if (docImages.length == 2)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 140,
                    child: _buildAdaptiveImage(docImages[0], height: 140),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 140,
                    child: _buildAdaptiveImage(docImages[1], height: 140),
                  ),
                ),
              ),
            ],
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: docImages.map((imgPath) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 160,
                  height: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildAdaptiveImage(
                      imgPath,
                      height: 140,
                      width: 160,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLokasiSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: darkGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Lokasi & Koordinat GPS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.elevation,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PetaInteraktifPage(
                      initialCoordinates: widget.coordinates,
                      initialSpotName: widget.title,
                      autoStartNavigation: true,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 130,
                  width: double.infinity,
                  color: const Color(0xFF1E3A2F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 30,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.coordinates,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFED65B),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.navigation_rounded,
                              size: 12,
                              color: Color(0xFF001D0F),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Mulai Perjalanan di Peta (GPS)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001D0F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanTeknisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.handyman_outlined, color: darkGreen, size: 18),
              SizedBox(width: 8),
              Text(
                'Catatan Teknis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTechItem('Teknik', widget.technique),
          const SizedBox(height: 12),
          _buildTechItem('Tali Utama', widget.mainRope),
          const SizedBox(height: 12),
          _buildTechItem('Jenis Batuan', widget.rockType),
        ],
      ),
    );
  }

  Widget _buildTechItem(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: darkGreen,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildReviewsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ulasan Penjelajah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  _reviews.isEmpty ? 'Belum Ada Ulasan' : '${_averageRating.toStringAsFixed(1)}/5 (${_reviews.length} Ulasan)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_reviews.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewsPage(
                    initialReviews: _reviews,
                    spotId: widget.id,
                    destinationName: widget.title,
                    destinationImage: widget.headerImage,
                  ),
                ),
              ).then((_) => _loadReviews());
            },
            child: const Text(
              'Lihat Semua',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
      ],
    );
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<double>(0.0, (prev, r) => prev + r.rating);
    return sum / _reviews.length;
  }

  Widget _buildReviewPreviewCard(ReviewItem review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                child: Text(
                  review.name.isNotEmpty ? review.name[0] : 'U',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 13,
                      ),
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
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF616161),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyReviewsState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, color: Colors.grey.shade400, size: 36),
          const SizedBox(height: 10),
          const Text(
            'Belum Ada Ulasan Penjelajah',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          const Text(
            'Jadilah orang pertama yang mengulas dan membagikan pengalaman di sini!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToWriteReview(context),
              icon: const Icon(Icons.edit_note, size: 16),
              label: const Text('Tulis Ulasan Pertama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWriteReview(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TulisUlasanPage(
          spotId: widget.id,
          destinationName: widget.title,
          destinationImage: widget.headerImage,
        ),
      ),
    ).then((result) async {
      if (result != null && result is Map<String, dynamic>) {
        String authorName = 'Penjelajah NARA';
        String authorRole = 'Petualang';
        try {
          final activeUser = await DatabaseHelper.instance.userDao.getLatestUser();
          if (activeUser != null) {
            authorName = activeUser.nama;
            authorRole = activeUser.rolePetualang ?? 'Petualang';
          }
        } catch (_) {}

        await ReviewSyncService.instance.submitReview(
          spotId: widget.id,
          destinationName: widget.title,
          userName: authorName,
          userRole: authorRole,
          rating: (result['rating'] as int).toDouble(),
          comment: result['comment'] as String,
          photos: result['photos'] as List<String>,
        );
        _loadReviews();
      }
    });
  }
}

// =========================================================================
// 2. HALAMAN DETAIL BERITA ACARA (TEBING CITATAH 125)
// =========================================================================
class DetailBeritaAcaraPage extends StatefulWidget {
  final String title;
  final String location;
  final String rating;
  final String category;
  final String headerImage;
  final String basecampImage;

  const DetailBeritaAcaraPage({
    super.key,
    this.title = 'Tebing Citatah\n125',
    this.location = 'Padalarang, Bandung Barat',
    this.rating = '4.8',
    this.category = 'Rock Climbing',
    this.headerImage = 'assets/images/citatah_header.jpg',
    this.basecampImage = 'assets/images/basecamp.jpg',
  });

  @override
  State<DetailBeritaAcaraPage> createState() => _DetailBeritaAcaraPageState();
}

class _DetailBeritaAcaraPageState extends State<DetailBeritaAcaraPage> {
  static const Color darkGreen = Color(0xFF143023);
  static const Color cardCream = Color(0xFFF5F2EB);

  // List Review Global State di Halaman Ini
  List<ReviewItem> reviews = [
    ReviewItem(
      name: 'Farhiyah',
      time: '2 hari yang lalu',
      rating: 5.0,
      comment:
          'Jalurnya sangat menantang dan view dari atas luar biasa! Pastikan bawa kapur yang cukup.',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    ),
    ReviewItem(
      name: 'Alex Rivers',
      time: '1 minggu yang lalu',
      rating: 4.0,
      comment:
          'Basecamp sangat ramah dan informasinya akurat. Cocok untuk latihan weekend.',
      avatarUrl:
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    ),
    ReviewItem(
      name: 'Sarah Chen',
      time: '2 minggu yang lalu',
      rating: 5.0,
      comment: 'Pengalaman yang sangat berkesan. Pemandangannya tiada duanya.',
      avatarUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
    ),
  ];

  Widget _buildAdaptiveImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    if (path.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade400,
        child: const Icon(Icons.terrain, color: Colors.white70),
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade400,
          child: const Icon(Icons.terrain, color: Colors.white70),
        ),
      );
    } else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade400,
          child: const Icon(Icons.terrain, color: Colors.white70),
        ),
      );
    } else {
      final file = File(path);
      return Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade400,
          child: const Icon(Icons.terrain, color: Colors.white70),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildFixedHeroHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTechnicalSpecificationsCard(),
                      const SizedBox(height: 24),
                      const Text(
                        'Informasi Basecamp',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildBasecampCard(),
                      const SizedBox(height: 24),
                      _buildReviewsHeader(context),
                      const SizedBox(height: 12),
                      _buildReviewPreviewCard(reviews.first),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PetaInteraktifPage(
                          initialSpotName: widget.title,
                          initialCoordinates: '6°50\'25.8"S 107°27\'06.5"E',
                          autoStartNavigation: true,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.navigation_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'Rute Navigasi Ekspedisi (GPS)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedHeroHeader(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(36),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 310,
            child: _buildAdaptiveImage(
              widget.headerImage,
              width: double.infinity,
              height: 310,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(36),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.85),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: Colors.black87,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.location,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.rating,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.landscape_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildTechnicalSpecificationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecTile(
            icon: Icons.layers_outlined,
            title: 'Jenis Batuan',
            value: 'Andesit & Limestone',
          ),
          const SizedBox(height: 12),
          _buildSpecTile(
            icon: Icons.crop_16_9_rounded,
            title: 'Ketinggian',
            value: '125 Meter',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardCream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Color(0xFFC48B27),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Teknis & Kesulitan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF757575),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Grade 5.9 - 5.11 (Yosemite Decimal System)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildGradeBullet(
                  'Kelas 5.9',
                  'Menengah. Menantang bagi pemula, butuh pijakan kaki kuat.',
                ),
                const SizedBox(height: 8),
                _buildGradeBullet(
                  'Kelas 5.10',
                  'Lanjutan. Membutuhkan kekuatan fisik dan gerakan spesifik.',
                ),
                const SizedBox(height: 8),
                _buildGradeBullet(
                  'Kelas 5.11',
                  'Ahli. Sangat teknis dengan urutan pegangan yang kompleks.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF757575)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradeBullet(String grade, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFFC48B27),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.black87,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$grade: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasecampCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: _buildAdaptiveImage(
                    widget.basecampImage,
                    width: 54,
                    height: 54,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basecamp Citatah Palmpuran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '0812-3456-7890',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'Hubungi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ulasan Penjelajah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                  '4.8/5 (${reviews.length + 125} Ulasan)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Tombol Lihat Semua -> Membuka Halaman ReviewsPage
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReviewsPage(initialReviews: reviews),
              ),
            );
          },
          child: const Text(
            'Lihat Semua',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewPreviewCard(ReviewItem review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                child: Text(
                  review.name.isNotEmpty ? review.name[0] : 'U',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 13,
                      ),
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
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF616161),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. HALAMAN DAFTAR ULASAN (REVIEWS PAGE)
// =========================================================================
class ReviewsPage extends StatefulWidget {
  final List<ReviewItem> initialReviews;
  final String? spotId;
  final String destinationName;
  final String? destinationImage;

  const ReviewsPage({
    super.key,
    required this.initialReviews,
    this.spotId,
    this.destinationName = 'Citatah Ekspedisi',
    this.destinationImage,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  late List<ReviewItem> _reviewsList;
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Terbaru', 'Rating Tertinggi', 'Dengan Foto'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _reviewsList = List.from(widget.initialReviews);
    _loadSyncedReviews();
  }

  Future<void> _loadSyncedReviews() async {
    setState(() => _isLoading = true);
    try {
      final cleanSpotId = widget.spotId ?? widget.destinationName;
      final synced = await ReviewSyncService.instance.getReviewsForSpot(
        spotId: cleanSpotId,
        destinationName: widget.destinationName,
        fetchFromCloud: true,
      );

      if (synced.isNotEmpty && mounted) {
        setState(() {
          _reviewsList = synced.map((m) => ReviewItem.fromModel(m)).toList();
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<ReviewItem> get _filteredReviews {
    List<ReviewItem> list = List.from(_reviewsList);
    if (_selectedFilterIndex == 0) {
      // Terbaru (Newest first based on upload time)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedFilterIndex == 1) {
      // Rating Tertinggi
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedFilterIndex == 2) {
      // Dengan Foto
      list = list.where((r) => r.imageUrl != null && r.imageUrl!.isNotEmpty).toList();
    }
    return list;
  }

  double get _averageRating {
    if (_reviewsList.isEmpty) return 0.0;
    final sum = _reviewsList.fold<double>(0.0, (prev, r) => prev + r.rating);
    return sum / _reviewsList.length;
  }

  @override
  Widget build(BuildContext context) {
    final displayReviews = _filteredReviews;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _reviewsList);
        }
      },
      child: Scaffold(
        backgroundColor: context.themeBg,
        appBar: AppBar(
          backgroundColor: context.themeBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.themePrimary),
            onPressed: () => Navigator.pop(context, _reviewsList),
          ),
          title: Text(
            'Ulasan Penjelajah',
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
                context.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                color: context.isDarkMode ? AppTheme.goldAccentDark : context.themePrimary,
                size: 22,
              ),
              tooltip: context.isDarkMode ? 'Beralih ke Mode Terang' : 'Beralih ke Mode Gelap',
              onPressed: () => ThemeController.instance.toggleTheme(context),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _loadSyncedReviews,
              color: context.themePrimary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                children: [
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          color: context.themePrimary,
                          backgroundColor: context.themeSurface,
                        ),
                      ),
                    ),
                  // 1. Kartu Rating Rangkuman
                  _buildRatingSummaryCard(),
                  const SizedBox(height: 20),

                  // 2. Filter Bar (Terbaru, Rating Tertinggi, Dengan Foto)
                  _buildFilterChips(),
                  const SizedBox(height: 20),

                  // 3. Daftar Kartu Ulasan / Empty State
                  if (displayReviews.isEmpty)
                    _buildEmptyReviewsCard()
                  else
                    ...displayReviews.map((review) => _buildReviewCardItem(review)),
                ],
              ),
            ),

            // Tombol Melayang "Tulis Ulasan"
            Positioned(
              right: 20,
              bottom: 24,
              child: SafeArea(
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    final newReview = await Navigator.push<ReviewItem>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TulisUlasanPage(
                          spotId: widget.spotId ?? widget.destinationName,
                          destinationName: widget.destinationName,
                          destinationImage: widget.destinationImage,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    if (newReview != null) {
                      final primaryColor = this.context.themePrimary;
                      setState(() {
                        _reviewsList.insert(0, newReview);
                      });
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text('Ulasan untuk ${widget.destinationName} berhasil ditambahkan!'),
                          backgroundColor: primaryColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  backgroundColor: context.themePrimary,
                  elevation: 4,
                  icon: Icon(
                    Icons.edit_outlined,
                    color: context.isDarkMode ? const Color(0xFF0F1713) : Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'Tulis Ulasan',
                    style: TextStyle(
                      color: context.isDarkMode ? const Color(0xFF0F1713) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReviewsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.themePrimaryFixed.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.rate_review_outlined,
              size: 38,
              color: context.themePrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Ulasan Penjelajah',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.themeText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jadilah orang pertama yang mengulas dan membagikan pengalaman di ${widget.destinationName}!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.themeTextSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummaryCard() {
    final avg = _averageRating;
    final total = _reviewsList.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            total > 0 ? avg.toStringAsFixed(1) : '0.0',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: context.themePrimary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                index < avg.floor()
                    ? Icons.star
                    : (index < avg ? Icons.star_half_rounded : Icons.star_border),
                color: AppTheme.goldAccentDark,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total > 0 ? '$total Ulasan Penjelajah' : 'Belum ada ulasan',
            style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
          ),
          if (total > 0) ...[
            const SizedBox(height: 20),
            _buildRatingBarRow(5, _calcRatingRatio(5)),
            const SizedBox(height: 6),
            _buildRatingBarRow(4, _calcRatingRatio(4)),
            const SizedBox(height: 6),
            _buildRatingBarRow(3, _calcRatingRatio(3)),
            const SizedBox(height: 6),
            _buildRatingBarRow(2, _calcRatingRatio(2)),
            const SizedBox(height: 6),
            _buildRatingBarRow(1, _calcRatingRatio(1)),
          ],
        ],
      ),
    );
  }

  double _calcRatingRatio(int star) {
    if (_reviewsList.isEmpty) return 0.0;
    final count = _reviewsList.where((r) => r.rating.round() == star).length;
    return count / _reviewsList.length;
  }

  Widget _buildRatingBarRow(int starCount, double progress) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(
            '$starCount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.themeText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.themeSurface,
              valueColor: AlwaysStoppedAnimation<Color>(context.themePrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.asMap().entries.map((entry) {
          final int idx = entry.key;
          final String title = entry.value;
          final bool isSelected = _selectedFilterIndex == idx;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? (context.isDarkMode ? const Color(0xFF0F1713) : Colors.white)
                      : context.themeText,
                ),
              ),
              selected: isSelected,
              selectedColor: context.themePrimary,
              backgroundColor: context.themeSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              showCheckmark: false,
              onSelected: (bool selected) {
                setState(() {
                  _selectedFilterIndex = idx;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewCardItem(ReviewItem review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: context.themePrimaryFixed,
                backgroundImage: review.avatarUrl != null && review.avatarUrl!.isNotEmpty
                    ? NetworkImage(review.avatarUrl!)
                    : null,
                child: (review.avatarUrl == null || review.avatarUrl!.isEmpty)
                    ? Text(
                        review.name.isNotEmpty ? review.name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.themePrimary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.goldAccentDark,
                          size: 14,
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
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review.uploadTimeFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 13,
              color: context.themeTextSecondary,
              height: 1.45,
            ),
          ),
          if (review.imageUrl != null && review.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child:
                  review.imageUrl!.startsWith('http://') ||
                      review.imageUrl!.startsWith('https://')
                  ? Image.network(
                      review.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Image.file(
                      File(review.imageUrl!),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 140,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

// =========================================================================
// 4. HALAMAN TULIS ULASAN (TULIS ULASAN BARU & VALIDASI)
// =========================================================================
class TulisUlasanPage extends StatefulWidget {
  final String? spotId;
  final String destinationName;
  final String? destinationImage;

  const TulisUlasanPage({
    super.key,
    this.spotId,
    this.destinationName = 'Citatah Ekspedisi',
    this.destinationImage,
  });

  @override
  State<TulisUlasanPage> createState() => _TulisUlasanPageState();
}

class _TulisUlasanPageState extends State<TulisUlasanPage> {
  static const Color darkGreen = Color(0xFF0F3223);
  static const Color bgCream = Color(0xFFF9F7F2);

  double _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // List foto yang dipilih pengguna
  final List<File> _selectedFiles = [];
  bool _isPicking = false;
  bool _isSubmitting = false;

  // Dialog / BottomSheet untuk memilih sumber foto (Kamera atau Galeri)
  void _showImageSourceDialog() {
    if (_selectedFiles.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 5 foto yang dapat diunggah.'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: darkGreen),
                  title: const Text('Ambil Foto dari Kamera', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: darkGreen),
                  title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (_isPicking) return;

    setState(() => _isPicking = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        requestFullMetadata: false,
      );

      if (pickedFile != null) {
        setState(() {
          if (_selectedFiles.length < 5) {
            _selectedFiles.add(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  // Fungsi memilih multiple image dari galeri
  Future<void> _pickMultiImageFromGallery() async {
    if (_isPicking) return;

    setState(() => _isPicking = true);

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
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_isSubmitting) return;

    // 1. Validasi Bintang Rating
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap berikan penilaian bintang terlebih dahulu!'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    // 2. Validasi Teks Ulasan
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap ceritakan pengalamanmu pada kolom teks!'),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Ambil nama pengguna yang sedang aktif dari database
    String reviewerName = 'Penjelajah NARA';
    String? reviewerRole;
    String? reviewerAvatar;
    try {
      final user = await DatabaseHelper.instance.getLatestUser();
      if (user != null && user.nama.isNotEmpty) {
        reviewerName = user.nama;
        reviewerRole = user.rolePetualang;
        reviewerAvatar = user.fotoProfil;
      }
    } catch (_) {}

    final cleanSpotId = widget.spotId ?? widget.destinationName;
    final createdReview = await ReviewSyncService.instance.submitReview(
      spotId: cleanSpotId,
      destinationName: widget.destinationName,
      userName: reviewerName,
      userRole: reviewerRole,
      userAvatar: reviewerAvatar,
      rating: _selectedRating,
      comment: _commentController.text.trim(),
      photos: _selectedFiles.map((f) => f.path).toList(),
    );

    final reviewItem = ReviewItem.fromModel(createdReview);

    if (!mounted) return;
    Navigator.pop(context, reviewItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reviews',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Info Ekspedisi Card
            _buildExpeditionHeaderCard(),
            const SizedBox(height: 30),

            // 2. Judul Pertanyaan
            const Center(
              child: Text(
                'Bagaimana pengalaman\nAnda?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 3. Bintang Penilaian Interaktif
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final int starVal = index + 1;
                  return IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      setState(() {
                        _selectedRating = starVal.toDouble();
                      });
                    },
                    icon: Icon(
                      starVal <= _selectedRating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: starVal <= _selectedRating
                          ? Colors.amber
                          : const Color(0xFF9E9E9E),
                      size: 42,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 30),

            // 4. Input Teks Cerita Pengalaman
            const Text(
              'Ceritakan pengalamanmu',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD7CCC8)),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 5,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                decoration: const InputDecoration(
                  hintText: 'Ceritakan lebih detail pengalamanmu...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 5. Tambahkan Foto
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambahkan Foto${_selectedFiles.isNotEmpty ? ' (${_selectedFiles.length}/5)' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'Opsional',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  // Tombol Upload Foto
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isPicking ? null : _showImageSourceDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2EFE9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDDD7CC)),
                        ),
                        child: _isPicking
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: darkGreen,
                                  ),
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: Color(0xFF616161),
                                    size: 26,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Upload',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF616161),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Daftar Foto yang Berhasil Dipilih
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

            // 6. Tombol Kirim Ulasan
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Kirim Ulasan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExpeditionHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.destinationImage != null && widget.destinationImage!.isNotEmpty
                ? (widget.destinationImage!.startsWith('http')
                    ? Image.network(
                        widget.destinationImage!,
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 55,
                          height: 55,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.terrain, color: Colors.grey),
                        ),
                      )
                    : Image.file(
                        File(widget.destinationImage!),
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 55,
                          height: 55,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.terrain, color: Colors.grey),
                        ),
                      ))
                : Image.network(
                    'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=200',
                    width: 55,
                    height: 55,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 55,
                      height: 55,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.terrain, color: Colors.grey),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destinationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Color(0xFF757575),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Hari ini',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
