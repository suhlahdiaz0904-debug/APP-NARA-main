import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/features/profile/screens/expedition_log_detail_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/profile/models/expedition_log_model.dart';
import 'package:flutter_application_1/features/map/screens/offline_map_screen.dart';
import 'package:flutter_application_1/features/map/screens/download_map_screen.dart';
import 'package:flutter_application_1/data/cave_data.dart';

// =========================================================================
// ENUM & MODEL DATA TITIK TEBING & GOA SE-INDONESIA
// =========================================================================
enum SpotType { tebing, goa }

class OutdoorSpot {
  final String id;
  final String name;
  final SpotType type;
  final String region;
  final String coordinatesText;
  final LatLng location;
  final String elevation; // misal: '125 mdpl' atau 'Kedalaman 60m'
  final String rockType;
  final String grade;
  final String description;
  final double rating;
  final String imageUrl;
  final List<LatLng> trailPoints;

  const OutdoorSpot({
    required this.id,
    required this.name,
    required this.type,
    required this.region,
    required this.coordinatesText,
    required this.location,
    required this.elevation,
    required this.rockType,
    required this.grade,
    required this.description,
    required this.rating,
    required this.imageUrl,
    required this.trailPoints,
  });

  String get typeLabel => type == SpotType.tebing ? 'Tebing' : 'Goa';
  IconData get iconData =>
      type == SpotType.tebing ? Icons.terrain_rounded : Icons.landscape_rounded;
  Color get badgeColor => type == SpotType.tebing
      ? const Color(0xFFC48B27)
      : const Color(0xFF2E7D32);
}

// Model Petunjuk Arah Langkah-demi-Langkah (Turn-by-Turn Directions)
class NavigationStep {
  final IconData icon;
  final String instruction;
  final String distance;
  final String hint;

  const NavigationStep({
    required this.icon,
    required this.instruction,
    required this.distance,
    required this.hint,
  });
}

// =========================================================================
// HALAMAN PETA INTERAKTIF (GOOGLE MAPS STYLE ENGINE + GPS REAL-TIME TRACKING)
// =========================================================================
class PetaInteraktifPage extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialSpotId;
  final String? initialCoordinates;
  final String? initialSpotName;
  final bool autoStartNavigation;

  const PetaInteraktifPage({
    super.key,
    this.onBack,
    this.initialSpotId,
    this.initialCoordinates,
    this.initialSpotName,
    this.autoStartNavigation = false,
  });

  // Parser Titik Koordinat DMS (contoh: 6°50'25.8"S 107°27'06.5"E) maupun Desimal (-6.8396, 107.4524)
  static LatLng? parseCoordinateString(String input) {
    if (input.trim().isEmpty) return null;
    final clean = input.trim();

    // 1. Format Desimal: "-6.8396, 107.4524" atau "-6.8396 107.4524"
    final decRegex = RegExp(r'([+-]?\d+\.?\d+)\s*[,|\s]\s*([+-]?\d+\.?\d+)');
    final decMatch = decRegex.firstMatch(clean);
    if (decMatch != null) {
      final lat = double.tryParse(decMatch.group(1)!);
      final lng = double.tryParse(decMatch.group(2)!);
      if (lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180) {
        return LatLng(lat, lng);
      }
    }

    // 2. Format DMS: 6°50'25.8"S 107°27'06.5"E
    final dmsRegex = RegExp(
      r'(\d+)[°\s]+(\d+)[\x27\x22\s]+([\d\.]+)\s*[\x22\x27]?\s*([NSns])\s*[,|\s]?\s*(\d+)[°\s]+(\d+)[\x27\x22\s]+([\d\.]+)\s*[\x22\x27]?\s*([EWew])',
    );
    final dmsMatch = dmsRegex.firstMatch(clean);
    if (dmsMatch != null) {
      try {
        double latDeg = double.parse(dmsMatch.group(1)!);
        double latMin = double.parse(dmsMatch.group(2)!);
        double latSec = double.parse(dmsMatch.group(3)!);
        String latDir = dmsMatch.group(4)!.toUpperCase();

        double lngDeg = double.parse(dmsMatch.group(5)!);
        double lngMin = double.parse(dmsMatch.group(6)!);
        double lngSec = double.parse(dmsMatch.group(7)!);
        String lngDir = dmsMatch.group(8)!.toUpperCase();

        double lat = latDeg + (latMin / 60.0) + (latSec / 3600.0);
        if (latDir == 'S') lat = -lat;

        double lng = lngDeg + (lngMin / 60.0) + (lngSec / 3600.0);
        if (lngDir == 'W') lng = -lng;

        return LatLng(lat, lng);
      } catch (_) {}
    }

    return null;
  }

  @override
  State<PetaInteraktifPage> createState() => _PetaInteraktifPageState();
}

class _PetaInteraktifPageState extends State<PetaInteraktifPage>
    with SingleTickerProviderStateMixin {
  // Palet Warna
  static const Color darkGreen = Color(0xFF001D0F);
  static const Color bgCream = Color(0xFFFAF8F5);
  static const Color accentAmber = Color(0xFFFED65B);
  static const Color secondaryColor = Color(0xFF735C00);
  static const Color routeRed = Color(0xFFE53935);

  final MapController _mapController = MapController();
  late AnimationController _pulseController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Mode Navigasi, Rute Jalan & Tracking Gerak
  bool _isNavigating = false;
  bool _isLoadingRoute = false;
  bool _autoFollowUser = true;
  StreamSubscription<Position>? _positionStreamSubscription;

  List<LatLng> _activeRedRoute = [];
  List<NavigationStep> _navigationSteps = [];
  double _activeDistanceKm = 0.0;
  int _activeDurationMinutes = 0;

  // Master Data 20+ Titik Koordinat Tebing & Goa se-Indonesia
  final List<OutdoorSpot> _allSpots = [
    // --- TEBING PANJAT ALAM ---
    OutdoorSpot(
      id: 'citatah125',
      name: 'Tebing Citatah 125',
      type: SpotType.tebing,
      region: 'Padalarang, Bandung Barat, Jawa Barat',
      coordinatesText: '6°50\'25.8"S 107°27\'06.5"E',
      location: const LatLng(-6.8396, 107.4524),
      elevation: '125 mdpl',
      rockType: 'Andesit & Karst Padat',
      grade: 'Grade 5.9 - 5.11',
      description:
          'Pusat panjat tebing legendaris di Jawa Barat dengan batuan andesit keras dan rute multi-pitch yang menantang.',
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=600',
      trailPoints: const [
        LatLng(-6.8430, 107.4490),
        LatLng(-6.8415, 107.4510),
        LatLng(-6.8396, 107.4524),
        LatLng(-6.8380, 107.4540),
      ],
    ),
    OutdoorSpot(
      id: 'citatah90',
      name: 'Tebing Citatah 90',
      type: SpotType.tebing,
      region: 'Padalarang, Bandung Barat, Jawa Barat',
      coordinatesText: '6°50\'16.1"S 107°27\'00.4"E',
      location: const LatLng(-6.8378, 107.4501),
      elevation: '90 mdpl',
      rockType: 'Karst Kalsit Solid',
      grade: 'Grade 5.8 - 5.10b',
      description:
          'Sektor pemanjatan favorit untuk tingkat pemula hingga menengah dengan banyak jalur sport climbing siap pakai.',
      rating: 4.7,
      imageUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600',
      trailPoints: const [
        LatLng(-6.8400, 107.4480),
        LatLng(-6.8378, 107.4501),
        LatLng(-6.8360, 107.4520),
      ],
    ),
    OutdoorSpot(
      id: 'hawu',
      name: 'Tebing Hawu (Karst Hawu)',
      type: SpotType.tebing,
      region: 'Padalarang, Bandung Barat, Jawa Barat',
      coordinatesText: '6°49\'55.2"S 107°26\'49.2"E',
      location: const LatLng(-6.8320, 107.4470),
      elevation: '80 mdpl',
      rockType: 'Karst Berongga & Alami',
      grade: 'Grade 5.9 - 5.10c',
      description:
          'Tebing berlubang megah dengan pemandangan lembah karst dan spot hammock di ketinggian yang spektakuler.',
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      trailPoints: const [
        LatLng(-6.8340, 107.4450),
        LatLng(-6.8320, 107.4470),
        LatLng(-6.8300, 107.4490),
      ],
    ),
    OutdoorSpot(
      id: 'parang',
      name: 'Gunung Parang (Via Ferrata)',
      type: SpotType.tebing,
      region: 'Purwakarta, Jawa Barat',
      coordinatesText: '6°35\'28.3"S 107°21\'04.3"E',
      location: const LatLng(-6.5912, 107.3512),
      elevation: '963 mdpl',
      rockType: 'Monolit Andesit Masif',
      grade: 'Via Ferrata & Grade 5.10',
      description:
          'Tebing batu andesit monolit tertinggi di Indonesia dengan lintasan Via Ferrata dan hotel gantung di tebing.',
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=600',
      trailPoints: const [
        LatLng(-6.5960, 107.3480),
        LatLng(-6.5935, 107.3500),
        LatLng(-6.5912, 107.3512),
        LatLng(-6.5890, 107.3530),
      ],
    ),
    OutdoorSpot(
      id: 'bongkok',
      name: 'Tebing Gunung Bongkok',
      type: SpotType.tebing,
      region: 'Purwakarta, Jawa Barat',
      coordinatesText: '6°36\'07.2"S 107°20\'31.2"E',
      location: const LatLng(-6.6020, 107.3420),
      elevation: '975 mdpl',
      rockType: 'Andesit Berlapis',
      grade: 'Scrambling & Grade 5.8',
      description:
          'Spot panjat dan scrambling favorit dengan latar belakang panorama Waduk Jatiluhur dari puncak batu tumpuk.',
      rating: 4.6,
      imageUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600',
      trailPoints: const [LatLng(-6.6050, 107.3400), LatLng(-6.6020, 107.3420)],
    ),
    OutdoorSpot(
      id: 'ciampea',
      name: 'Tebing Kapur Ciampea',
      type: SpotType.tebing,
      region: 'Ciampea, Bogor, Jawa Barat',
      coordinatesText: '6°33\'14.4"S 106°41\'52.8"E',
      location: const LatLng(-6.5540, 106.6980),
      elevation: '350 mdpl',
      rockType: 'Batu Kapur Putih',
      grade: 'Grade 5.7 - 5.10a',
      description:
          'Dinding kapur putih di perbukitan Ciampea yang menjadi sarana latihan pemanjat tebing di Jabodetabek.',
      rating: 4.5,
      imageUrl:
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=600',
      trailPoints: const [LatLng(-6.5560, 106.6960), LatLng(-6.5540, 106.6980)],
    ),
    OutdoorSpot(
      id: 'siung',
      name: 'Tebing Pantai Siung',
      type: SpotType.tebing,
      region: 'Tepus, Gunungkidul, D.I. Yogyakarta',
      coordinatesText: '8°10\'54.8"S 110°41\'00.0"E',
      location: const LatLng(-8.1819, 110.6833),
      elevation: '45 mdpl (Tepi Laut)',
      rockType: 'Karst Karang Pesisir',
      grade: '50+ Jalur Panjat (5.8 - 5.12c)',
      description:
          'Situs pemanjatan tepi laut kelas internasional dengan 50 lebih rute panjat berlatar deburan ombak Samudra Hindia.',
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
      trailPoints: const [
        LatLng(-8.1840, 110.6810),
        LatLng(-8.1819, 110.6833),
        LatLng(-8.1800, 110.6850),
      ],
    ),
    OutdoorSpot(
      id: 'harau',
      name: 'Tebing Lembah Harau',
      type: SpotType.tebing,
      region: 'Lima Puluh Kota, Sumatera Barat',
      coordinatesText: '0°05\'55.3"S 100°39\'55.1"E',
      location: const LatLng(-0.0987, 100.6653),
      elevation: '300 mdpl',
      rockType: 'Dinding Granit Raksasa',
      grade: 'Big Wall & Trad (5.10 - 5.13)',
      description:
          'Yosemite-nya Indonesia dengan tebing tegak granit berwarna-warni setinggi 100-300 meter dan air terjun alami.',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=600',
      trailPoints: const [LatLng(-0.1010, 100.6630), LatLng(-0.0987, 100.6653)],
    ),
    OutdoorSpot(
      id: 'maros',
      name: 'Karst Maros-Pangkep',
      type: SpotType.tebing,
      region: 'Maros & Pangkep, Sulawesi Selatan',
      coordinatesText: '4°59\'46.0"S 119°41\'00.0"E',
      location: const LatLng(-4.9961, 119.6833),
      elevation: '450 mdpl',
      rockType: 'Menara Karst Terbesar ke-2 Dunia',
      grade: 'Bouldering & Sport Climbing',
      description:
          'Kawasan menara karst terluas kedua di dunia dengan ratusan tebing tegak dan lukisan prasejarah berusia 45.000 tahun.',
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      trailPoints: const [LatLng(-4.9990, 119.6800), LatLng(-4.9961, 119.6833)],
    ),
    OutdoorSpot(
      id: 'uluwatu',
      name: 'Tebing Karang Uluwatu',
      type: SpotType.tebing,
      region: 'Kuta Selatan, Badung, Bali',
      coordinatesText: '8°49\'44.4"S 115°05\'05.6"E',
      location: const LatLng(-8.8290, 115.0849),
      elevation: '70 mdpl (Cliff Edge)',
      rockType: 'Batu Gamping Samudra',
      grade: 'Grade 5.9 - 5.11',
      description:
          'Tebing terjal di ujung selatan Pulau Bali yang menyajikan pemandangan matahari terbenam dan panorama samudra lepas.',
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=600',
      trailPoints: const [LatLng(-8.8310, 115.0820), LatLng(-8.8290, 115.0849)],
    ),
    OutdoorSpot(
      id: 'sepikul',
      name: 'Tebing Sepikul',
      type: SpotType.tebing,
      region: 'Watulimo, Trenggalek, Jawa Timur',
      coordinatesText: '8°09\'24.1"S 111°38\'31.6"E',
      location: const LatLng(-8.1567, 111.6421),
      elevation: '250 mdpl',
      rockType: 'Andesit Monolitik',
      grade: 'Multi-pitch & Via Ferrata',
      description:
          'Tebing batu andesit tertinggi di Jawa Timur dengan rute pemanjatan teknis dan lintasan via ferrata menantang.',
      rating: 4.7,
      imageUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600',
      trailPoints: const [LatLng(-8.1590, 111.6400), LatLng(-8.1567, 111.6421)],
    ),

    // --- GOA KARST & CAVING ALAM ---
    OutdoorSpot(
      id: 'jomblang',
      name: 'Goa Jomblang (Cahaya Surga)',
      type: SpotType.goa,
      region: 'Semanu, Gunungkidul, D.I. Yogyakarta',
      coordinatesText: '8°01\'43.3"S 110°38\'18.2"E',
      location: const LatLng(-8.0287, 110.6384),
      elevation: 'Luweng Vertikal 60 Meter',
      rockType: 'Sinkhole Karst & Hutan Purba',
      grade: 'Single Rope Technique (SRT)',
      description:
          'Goa vertikal terkenal dengan fenomena "Ray of Light" (Cahaya Surga) dan hutan purba yang terisolasi di dasarnya.',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      trailPoints: const [LatLng(-8.0310, 110.6360), LatLng(-8.0287, 110.6384)],
    ),
    OutdoorSpot(
      id: 'pindul',
      name: 'Goa Pindul (Cave Tubing)',
      type: SpotType.goa,
      region: 'Karangmojo, Gunungkidul, D.I. Yogyakarta',
      coordinatesText: '7°56\'04.9"S 110°38\'56.0"E',
      location: const LatLng(-7.9347, 110.6489),
      elevation: 'Panjang Sungai 350 Meter',
      rockType: 'Karst Berair Alami',
      grade: 'Susur Goa Air Pemula',
      description:
          'Menyusuri sungai bawah tanah di dalam goa karst menggunakan ban pelampung dengan stalaktit kristal terbesar.',
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
      trailPoints: const [LatLng(-7.9370, 110.6460), LatLng(-7.9347, 110.6489)],
    ),
    OutdoorSpot(
      id: 'gong',
      name: 'Goa Gong',
      type: SpotType.goa,
      region: 'Punung, Pacitan, Jawa Timur',
      coordinatesText: '8°09\'47.9"S 110°58\'50.2"E',
      location: const LatLng(-8.1633, 110.9806),
      elevation: 'Kedalaman 256 Meter',
      rockType: 'Stalaktit & Stalagmit Bunyi',
      grade: 'Wisata Caving Terindah se-Asia',
      description:
          'Goa terindah se-Asia Tenggara dengan formasi stalaktit dan stalagmit raksasa yang berbunyi seperti gong saat dipukul.',
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=600',
      trailPoints: const [LatLng(-8.1650, 110.9780), LatLng(-8.1633, 110.9806)],
    ),
    OutdoorSpot(
      id: 'maharani',
      name: 'Goa Maharani',
      type: SpotType.goa,
      region: 'Paciran, Lamongan, Jawa Timur',
      coordinatesText: '6°51\'52.9"S 112°21\'29.5"E',
      location: const LatLng(-6.8647, 112.3582),
      elevation: 'Kedalaman 25 Meter',
      rockType: 'Kristal Kalsit Bersinar',
      grade: 'Susur Goa Keluarga',
      description:
          'Goa istana kristal dengan stalaktit dan stalagmit yang masih terus tumbuh serta memancarkan kilau saat tersorot cahaya.',
      rating: 4.7,
      imageUrl:
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=600',
      trailPoints: const [LatLng(-6.8660, 112.3560), LatLng(-6.8647, 112.3582)],
    ),
    OutdoorSpot(
      id: 'petruk',
      name: 'Goa Petruk',
      type: SpotType.goa,
      region: 'Ayah, Kebumen, Jawa Tengah',
      coordinatesText: '7°41\'17.2"S 109°24\'45.0"E',
      location: const LatLng(-7.6881, 109.4125),
      elevation: 'Panjang 2.000 Meter',
      rockType: 'Karst Gombong Selatan',
      grade: 'Susur Goa Petualangan',
      description:
          'Goa alami tanpa penerangan buatan di Kawasan Karst Gombong Selatan dengan tiga tingkat ruangan yang menakjubkan.',
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      trailPoints: const [LatLng(-7.6900, 109.4100), LatLng(-7.6881, 109.4125)],
    ),
    OutdoorSpot(
      id: 'barat',
      name: 'Goa Barat',
      type: SpotType.goa,
      region: 'Ayah, Kebumen, Jawa Tengah',
      coordinatesText: '7°41\'06.0"S 109°24\'54.0"E',
      location: const LatLng(-7.6850, 109.4150),
      elevation: 'Air Terjun Bawah Tanah 32m',
      rockType: 'Karst Aliran Deras',
      grade: 'Ekspedisi Caving Ekstrem',
      description:
          'Goa dengan hembusan angin kencang di mulutnya dan air terjun vertikal "Sister Falling Star" setinggi 32 meter di dalam goa.',
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600',
      trailPoints: const [LatLng(-7.6870, 109.4130), LatLng(-7.6850, 109.4150)],
    ),
    OutdoorSpot(
      id: 'cerme',
      name: 'Goa Cerme',
      type: SpotType.goa,
      region: 'Imogiri, Bantul, D.I. Yogyakarta',
      coordinatesText: '7°56\'21.1"S 110°23\'44.2"E',
      location: const LatLng(-7.9392, 110.3956),
      elevation: 'Panjang 1.500m Tembus Gunungkidul',
      rockType: 'Aliran Sungai Bawah Tanah',
      grade: 'Susur Goa Air Sedang',
      description:
          'Goa bersejarah peninggalan Wali Songo dengan rute susur sungai bawah tanah sepanjang 1,5 km dari Bantul tembus ke Gunungkidul.',
      rating: 4.7,
      imageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600',
      trailPoints: const [LatLng(-7.9410, 110.3930), LatLng(-7.9392, 110.3956)],
    ),
    OutdoorSpot(
      id: 'pawon',
      name: 'Goa Pawon',
      type: SpotType.goa,
      region: 'Padalarang, Bandung Barat, Jawa Barat',
      coordinatesText: '6°49\'43.0"S 107°26\'08.9"E',
      location: const LatLng(-6.8286, 107.4358),
      elevation: '720 mdpl',
      rockType: 'Karst Purba & Fosil Kerang',
      grade: 'Wisata Budaya & Geologi',
      description:
          'Situs purbakala ditemukannya fosil Manusia Purba Sunda dengan jendela alam di dinding tebing karst menghadap hamparan hijau.',
      rating: 4.8,
      imageUrl:
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=600',
      trailPoints: const [LatLng(-6.8300, 107.4330), LatLng(-6.8286, 107.4358)],
    ),
    OutdoorSpot(
      id: 'rangko',
      name: 'Goa Rangko (Gua Kolam Asin)',
      type: SpotType.goa,
      region: 'Labuan Bajo, Nusa Tenggara Timur',
      coordinatesText: '8°26\'30.8"S 119°55\'24.2"E',
      location: const LatLng(-8.4419, 119.9234),
      elevation: 'Permukaan Air Laut',
      rockType: 'Karst Pesisir Bening',
      grade: 'Berenang & Snorkeling Alami',
      description:
          'Kolam air asin alami di dalam goa yang airnya sangat jernih kebiruan saat tersinari matahari di siang hari.',
      rating: 4.9,
      imageUrl:
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=600',
      trailPoints: const [LatLng(-8.4440, 119.9210), LatLng(-8.4419, 119.9234)],
    ),
    OutdoorSpot(
      id: 'akbar',
      name: 'Goa Akbar',
      type: SpotType.goa,
      region: 'Tuban, Jawa Timur',
      coordinatesText: '6°53\'57.8"S 112°03\'15.1"E',
      location: const LatLng(-6.8994, 112.0542),
      elevation: 'Di Bawah Pasar Kota Tuban',
      rockType: 'Batuan Gamping Bersejarah',
      grade: 'Caving Wisata Religi',
      description:
          'Keunikan goa alam yang berada tepat di bawah pasar kota Tuban dengan stalaktit dan relief kaligrafi bersejarah.',
      rating: 4.6,
      imageUrl:
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=600',
      trailPoints: const [LatLng(-6.9010, 112.0520), LatLng(-6.8994, 112.0542)],
    ),
  ];

  late OutdoorSpot _selectedSpot;
  OutdoorSpot? _nearestSpot;
  bool _hasManuallySelectedSpot = false;

  // Filter Kategori: 'semua', 'tebing', 'goa', 'terdekat'
  String _selectedCategoryFilter = 'semua';
  String _searchQuery = '';
  bool _showSearchResults = false;

  // Pilihan Layer Map OpenStreetMap
  int _selectedLayerIndex = 0;
  final List<Map<String, String>> _mapLayers = [
    {
      'name': 'OpenStreetMap Standard',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      'subdomain': '',
      'desc': 'Peta umum OpenStreetMap dengan detail jalan & kontur',
    },
    {
      'name': 'OpenTopoMap (Topografi)',
      'url': 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
      'subdomain': '',
      'desc': 'Kontur ketinggian & relief topografi gunung & tebing',
    },
    {
      'name': 'CartoDB Voyager (Modern)',
      'url':
          'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      'subdomain': 'abcd',
      'desc': 'Tampilan modern, bersih, dan kontras tajam',
    },
    {
      'name': 'ESRI Satelit Topo',
      'url':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      'subdomain': '',
      'desc': 'Citra satelit resolusi tinggi permukaan bumi',
    },
  ];

  // User GPS & Status
  LatLng? _userLocation;
  double _gpsAccuracy = 12.0; // Akurasi radius GPS dalam meter
  bool _isLocating = false;
  bool _showSpotCard = true;
  String _gpsStatusMessage = 'Mendeteksi lokasi GPS presisi tinggi...';

  @override
  void initState() {
    // Add Klapanunggal caves dynamic data to _allSpots
    for (final c in KlapanunggalCavesData.caves) {
      _allSpots.add(
        OutdoorSpot(
          id: 'klapanunggal_${(c['title'] ?? '').toString().toLowerCase().replaceAll(' ', '_')}',
          name: c['title'] ?? 'Goa Klapanunggal',
          type: SpotType.goa,
          region: c['location'] ?? 'Klapanunggal, Bogor',
          coordinatesText: c['coordinates'] ?? '',
          location: LatLng(c['lat'] as double, c['lon'] as double),
          elevation: c['elevation'] ?? '150 mdpl',
          rockType: 'Karst Formasi Klapanunggal',
          grade: 'Susur Goa (Caving)',
          description: c['description'] ?? '',
          rating: double.tryParse(c['rating']?.toString() ?? '4.8') ?? 4.8,
          imageUrl:
              c['imageUrl'] ??
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
          trailPoints: [LatLng(c['lat'] as double, c['lon'] as double)],
        ),
      );
    }

    super.initState();
    _selectedSpot = _allSpots.first;

    if (widget.initialSpotId != null) {
      final found = _allSpots.firstWhere(
        (s) => s.id == widget.initialSpotId,
        orElse: () => _allSpots.first,
      );
      _selectedSpot = found;
      _hasManuallySelectedSpot = true;
    } else if (widget.initialSpotName != null ||
        widget.initialCoordinates != null) {
      OutdoorSpot? match;

      if (widget.initialSpotName != null) {
        final queryClean = widget.initialSpotName!
            .toLowerCase()
            .replaceAll('\n', ' ')
            .trim();
        try {
          match = _allSpots.firstWhere((s) {
            final sName = s.name.toLowerCase();
            return queryClean.contains(sName) ||
                sName.contains(queryClean) ||
                (queryClean.contains('citatah') && sName.contains('citatah')) ||
                (queryClean.contains('parang') && sName.contains('parang')) ||
                (queryClean.contains('siung') && sName.contains('siung')) ||
                (queryClean.contains('jomblang') &&
                    sName.contains('jomblang')) ||
                (queryClean.contains('maros') && sName.contains('maros'));
          });
        } catch (_) {}
      }

      if (match != null) {
        _selectedSpot = match;
        _hasManuallySelectedSpot = true;
      } else if (widget.initialCoordinates != null) {
        final parsedLoc = PetaInteraktifPage.parseCoordinateString(
          widget.initialCoordinates!,
        );
        if (parsedLoc != null) {
          final customSpot = OutdoorSpot(
            id: 'spot_target_custom',
            name:
                widget.initialSpotName?.replaceAll('\n', ' ') ??
                'Titik Koordinat Berita',
            type:
                (widget.initialSpotName?.toLowerCase().contains('goa') == true)
                ? SpotType.goa
                : SpotType.tebing,
            region: 'Destinasi Ekspedisi Berita',
            coordinatesText: widget.initialCoordinates!,
            location: parsedLoc,
            elevation: '125 mdpl',
            rockType: 'Andesit & Karst',
            grade: 'Grade 5.9 - 5.11',
            description:
                'Titik koordinat destinasi yang dipilih langsung dari Berita & Acara NARA.',
            rating: 4.9,
            imageUrl:
                'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=600',
            trailPoints: [
              LatLng(parsedLoc.latitude - 0.003, parsedLoc.longitude - 0.002),
              parsedLoc,
            ],
          );
          _allSpots.insert(0, customSpot);
          _selectedSpot = customSpot;
          _hasManuallySelectedSpot = true;
        }
      }
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Inisialisasi Lokasi GPS & Mulai Stream Gerakan Perangkat
    _initDeviceLocation();
    _startLivePositionStream();

    // Jika autoStartNavigation aktif, jalankan navigasi rute jalan langsung
    if (widget.autoStartNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startNavigation(_selectedSpot);
        }
      });
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _pulseController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Hitung jarak (dalam kilometer) antara posisi GPS user dan spot
  double? _getDistanceToSpot(OutdoorSpot spot) {
    if (_userLocation == null) return null;
    final double distanceInMeters = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      spot.location.latitude,
      spot.location.longitude,
    );
    return distanceInMeters / 1000.0;
  }

  // Translasi belokan OSRM
  static String _translateModifier(String modifier) {
    switch (modifier) {
      case 'slight right':
        return 'Sedikit serong kanan';
      case 'right':
        return 'Belok kanan';
      case 'sharp right':
        return 'Belok tajam ke kanan';
      case 'slight left':
        return 'Sedikit serong kiri';
      case 'left':
        return 'Belok kiri';
      case 'sharp left':
        return 'Belok tajam ke kiri';
      case 'uturn':
        return 'Putar balik (U-Turn)';
      case 'straight':
        return 'Terus lurus';
      default:
        return 'Ikuti jalur jalan';
    }
  }

  // Rekomendasi Rute Jalan Asli OSRM (Open Source Routing Machine)
  Future<Map<String, dynamic>?> _fetchRealRoadRoute(
    LatLng start,
    LatLng dest,
  ) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson&steps=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 'Ok' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          final List<LatLng> points = coordinates.map((c) {
            final num lng = c[0];
            final num lat = c[1];
            return LatLng(lat.toDouble(), lng.toDouble());
          }).toList();

          final double distanceMeters = (route['distance'] as num).toDouble();
          final double durationSeconds = (route['duration'] as num).toDouble();

          final List<NavigationStep> steps = [];
          final legs = route['legs'] as List;
          if (legs.isNotEmpty) {
            final legSteps = legs[0]['steps'] as List;
            for (var s in legSteps) {
              final maneuver = s['maneuver'] ?? {};
              final String type = maneuver['type'] ?? 'turn';
              final String modifier = maneuver['modifier'] ?? '';
              final String streetName = s['name'] ?? '';
              final double stepDist = (s['distance'] as num?)?.toDouble() ?? 0;

              IconData icon = Icons.straight_rounded;
              if (modifier.contains('right')) {
                icon = Icons.turn_right_rounded;
              } else if (modifier.contains('left')) {
                icon = Icons.turn_left_rounded;
              } else if (modifier.contains('uturn') ||
                  modifier.contains('u-turn')) {
                icon = Icons.u_turn_left_rounded;
              } else if (type == 'arrive') {
                icon = Icons.flag_rounded;
              }

              String instruction = '';
              if (type == 'depart') {
                instruction = 'Mulai perjalanan dari lokasi perangkat';
              } else if (type == 'arrive') {
                instruction = 'Tiba di kawasan tujuan ekspedisi';
              } else if (streetName.isNotEmpty) {
                instruction = '${_translateModifier(modifier)} ke $streetName';
              } else {
                instruction =
                    '${_translateModifier(modifier)} ikuti jalur utama';
              }

              final String distText = stepDist < 1000
                  ? '${stepDist.round()} m'
                  : '${(stepDist / 1000).toStringAsFixed(1)} km';

              steps.add(
                NavigationStep(
                  icon: icon,
                  instruction: instruction,
                  distance: distText,
                  hint:
                      'Rute jalan aspal dan akses tebing yang direkomendasikan',
                ),
              );
            }
          }

          return {
            'points': points,
            'distanceKm': distanceMeters / 1000.0,
            'durationMinutes': (durationSeconds / 60.0).round().clamp(5, 480),
            'steps': steps,
          };
        }
      }
    } catch (_) {}
    return null;
  }

  // Generator Rute Cadangan (Fallback jika OSRM timeout / offline)
  List<LatLng> _generateFallbackRoadRoute(LatLng start, LatLng dest) {
    final List<LatLng> points = [start];
    final double dLat = dest.latitude - start.latitude;
    final double dLng = dest.longitude - start.longitude;

    points.add(
      LatLng(
        start.latitude + (dLat * 0.20) + 0.0008,
        start.longitude + (dLng * 0.20) - 0.0006,
      ),
    );
    points.add(
      LatLng(
        start.latitude + (dLat * 0.50) - 0.0012,
        start.longitude + (dLng * 0.50) + 0.0010,
      ),
    );
    points.add(
      LatLng(
        start.latitude + (dLat * 0.75) + 0.0009,
        start.longitude + (dLng * 0.75) + 0.0004,
      ),
    );
    points.add(
      LatLng(
        start.latitude + (dLat * 0.90) - 0.0004,
        start.longitude + (dLng * 0.90) - 0.0003,
      ),
    );
    points.add(dest);

    return points;
  }

  // Petunjuk Arah Cadangan
  List<NavigationStep> _generateFallbackSteps(
    OutdoorSpot destination,
    double distanceKm,
  ) {
    final String spotName = destination.name;
    final String region = destination.region;
    final String distText = distanceKm < 1.0
        ? '${(distanceKm * 1000).round()} m'
        : '${distanceKm.toStringAsFixed(1)} km';

    return [
      NavigationStep(
        icon: Icons.my_location_rounded,
        instruction: 'Mulai perjalanan dari lokasi perangkat Anda',
        distance: '0 m',
        hint: 'Arahkan kendaraan/langkah menuju jalur keluar awal.',
      ),
      NavigationStep(
        icon: Icons.straight_rounded,
        instruction: 'Lurus ikuti rute jalan arteri utama menuju $region',
        distance: distanceKm > 2.0
            ? '${(distanceKm * 0.6).toStringAsFixed(1)} km'
            : '500 m',
        hint: 'Kondisi jalur beraspal dan dapat dilalui kendaraan.',
      ),
      NavigationStep(
        icon: Icons.turn_right_rounded,
        instruction: 'Belok kanan di Pos Gerbang Masuk & Registrasi $spotName',
        distance: distanceKm > 1.0
            ? '${(distanceKm * 0.3).toStringAsFixed(1)} km'
            : '250 m',
        hint: 'Lapor dan lakukan registrasi simaksi / tiket ekspedisi.',
      ),
      NavigationStep(
        icon: Icons.hiking_rounded,
        instruction:
            'Lanjutkan trekking setapak berbatu menuju Base Camp (Elevasi: ${destination.elevation})',
        distance: '350 m',
        hint: 'Gunakan sepatu trekking dan siapkan perlengkapan panjat/caving.',
      ),
      NavigationStep(
        icon: destination.iconData,
        instruction: 'Tiba di titik tujuan ekspedisi: $spotName',
        distance: distText,
        hint:
            'Koordinat GPS: ${destination.coordinatesText} • Siap memulai petualangan!',
      ),
    ];
  }

  // Inisialisasi Lokasi GPS
  Future<void> _initDeviceLocation() async {
    setState(() {
      _isLocating = true;
      _gpsStatusMessage = 'Memeriksa GPS perangkat...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsStatusMessage =
              'GPS nonaktif. Aktifkan lokasi di perangkat Anda.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsStatusMessage = 'Izin lokasi GPS tidak diberikan.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final currentLatLng = LatLng(position.latitude, position.longitude);
      final double accuracyMeters = position.accuracy;

      OutdoorSpot? closestSpot;
      double minDistance = double.infinity;

      for (var spot in _allSpots) {
        final dist = Geolocator.distanceBetween(
          currentLatLng.latitude,
          currentLatLng.longitude,
          spot.location.latitude,
          spot.location.longitude,
        );
        if (dist < minDistance) {
          minDistance = dist;
          closestSpot = spot;
        }
      }

      setState(() {
        _userLocation = currentLatLng;
        _gpsAccuracy = accuracyMeters > 0 ? accuracyMeters : 10.0;
        _nearestSpot = closestSpot;
        _gpsStatusMessage = closestSpot != null
            ? 'GPS Presisi (±${_gpsAccuracy.round()}m) • Terdekat: ${closestSpot.name} (${(minDistance / 1000).toStringAsFixed(1)} km)'
            : 'GPS Presisi (±${_gpsAccuracy.round()}m) Terhubung';

        if (!_hasManuallySelectedSpot && closestSpot != null) {
          _selectedSpot = closestSpot;
        }
      });

      if (!_hasManuallySelectedSpot && closestSpot != null) {
        _mapController.move(closestSpot.location, 13.5);
      } else {
        _mapController.move(_selectedSpot.location, 14.0);
      }
    } catch (e) {
      setState(() {
        _gpsStatusMessage = 'Gagal sinkronisasi GPS: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  // Stream Gerakan Perangkat GPS Real-Time (Device bergerak -> Peta ikut jalan dengan akurasi maksimal)
  void _startLivePositionStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter:
                1, // Update tiap 1 meter pergerakan untuk presisi tinggi
          ),
        ).listen((Position position) {
          if (!mounted) return;
          final newLatLng = LatLng(position.latitude, position.longitude);

          setState(() {
            _userLocation = newLatLng;
            if (position.accuracy > 0) {
              _gpsAccuracy = position.accuracy;
            }
          });

          // Jika sedang navigasi dan mode auto follow aktif, kamera peta ikut berjalan mengikuti user
          if (_isNavigating && _autoFollowUser) {
            _mapController.move(newLatLng, _mapController.camera.zoom);
          }
        });
  }

  // Memulai Navigasi Rute Jalan Seperti Google Maps
  Future<void> _startNavigation(OutdoorSpot spot) async {
    setState(() {
      _selectedSpot = spot;
      _hasManuallySelectedSpot = true;
      _isLoadingRoute = true;
      _isNavigating = true;
      _showSpotCard = false; // Sembunyikan spot card biasa saat navigasi aktif
      _showSearchResults = false;
      _searchFocusNode.unfocus();
    });

    final startPoint =
        _userLocation ??
        LatLng(spot.location.latitude - 0.025, spot.location.longitude - 0.018);

    // Ambil rute jalan asli dari OSRM
    final osrmResult = await _fetchRealRoadRoute(startPoint, spot.location);

    if (!mounted) return;

    if (osrmResult != null) {
      setState(() {
        _activeRedRoute = osrmResult['points'] as List<LatLng>;
        _activeDistanceKm = osrmResult['distanceKm'] as double;
        _activeDurationMinutes = osrmResult['durationMinutes'] as int;
        _navigationSteps = osrmResult['steps'] as List<NavigationStep>;
        _isLoadingRoute = false;
      });
    } else {
      // Fallback
      final fallbackRoute = _generateFallbackRoadRoute(
        startPoint,
        spot.location,
      );
      final double dist = _getDistanceToSpot(spot) ?? 4.2;
      final steps = _generateFallbackSteps(spot, dist);

      setState(() {
        _activeRedRoute = fallbackRoute;
        _activeDistanceKm = dist;
        _activeDurationMinutes = (dist * 2.5).round().clamp(5, 180);
        _navigationSteps = steps;
        _isLoadingRoute = false;
      });
    }

    // Posisikan kamera ke titik mulai / pengguna
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.5);
    } else {
      _mapController.move(spot.location, 14.5);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation_rounded, color: accentAmber, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Navigasi aktif menuju ${spot.name} (${_activeDistanceKm.toStringAsFixed(1)} km)!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: darkGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Menghentikan Navigasi / Menyelesaikan Ekspedisi
  void _stopNavigation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.flag_rounded, color: Color(0xFF113322)),
            SizedBox(width: 10),
            Text(
              'Selesaikan Navigasi?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda telah tiba di ${_selectedSpot.name}? Catat ekspedisi ini ke Riwayat Log Akun Anda.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF424843)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isNavigating = false;
                _autoFollowUser = true;
                _activeRedRoute = [];
                _showSpotCard = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Navigasi rute ditutup.'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Hanya Tutup Rute',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _finishAndSaveExpeditionLog();
            },
            icon: const Icon(
              Icons.bookmark_added_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: const Text('Selesai & Catat Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF113322),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Menyimpan Ekspedisi ke SQLite dan Membuka Halaman Detail Log Ekspedisi
  Future<void> _finishAndSaveExpeditionLog() async {
    final currentUser = await DatabaseHelper.instance.getLatestUser();
    final double dist = _activeDistanceKm > 0
        ? double.parse(_activeDistanceKm.toStringAsFixed(1))
        : 1.2;
    final int dur = _activeDurationMinutes > 0 ? _activeDurationMinutes : 45;

    final newLog = ExpeditionLog(
      userId: currentUser?.id,
      spotId: _selectedSpot.id,
      spotName: _selectedSpot.name,
      spotType: _selectedSpot.type == SpotType.tebing
          ? 'Rock Climbing'
          : 'Caving Speleologi',
      region: _selectedSpot.region,
      imageUrl: _selectedSpot.imageUrl,
      date: DateTime.now(),
      duration:
          '${(dur ~/ 60).toString().padLeft(2, '0')}h ${(dur % 60).toString().padLeft(2, '0')}m',
      distanceKm: dist,
      elevation: _selectedSpot.elevation,
      trackMapUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAnEHDBE6DIZfq8Nw0PVwRD-Kx6mLOb_9XA830LBcsK5SX998okFtMAsH-IvCY70At9Q_dYSXsX2abEuS1AgEl4UUq302VtIh5P4wradYGkbMwio7dL5cIOVGmJr8ROjABfDA7OC0AnCorbpJJqRJ3jG3psu0OoCBwOccK36ph8ipuNM379zmmWp1p3_Oj0bDTMgxWm11MMeLV2GzoaqO5Rg8xQMhW0pWkbQhz4qfcQ1sz0bahfr3iw',
      notes: [
        ExpeditionNoteItem(
          time: '08:30',
          title: 'Tiba di Lokasi ${_selectedSpot.name}',
          subtitle:
              'Kondisi cuaca cerah, rute penjelajahan sepanjang $dist km siap dijelajahi.',
          iconType: 'flag',
        ),
        ExpeditionNoteItem(
          time: '10:00',
          title: 'Memulai Jalur (${_selectedSpot.grade})',
          subtitle:
              'Karakteristik medan: ${_selectedSpot.rockType}. Pemasangan perlengkapan aman.',
          iconType: 'hardware',
        ),
        const ExpeditionNoteItem(
          time: '12:30',
          title: 'Mencapai Titik Target Ekspedisi',
          subtitle:
              'Navigasi sukses dan seluruh titik perhentian tercatat di NARA Outdoor.',
          iconType: 'photo_camera',
          photos: [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAW8iZ26KTJLVzh0H-zJLIWK2aMmB_MpfZeppATNtGzimrSeTQ4sgIzi_w8rFFWXpTewgyIAIzdLDUfvMcxdu0ehhprWOYuo32BDBZPh3tNYNblrGlt5_kkUrltt2zaVZvYBWvkw_VGotq2mXxWuBhGKPOpovnXamzkL697x0HBpKXt4Lsv4fyd7He2_Sa9Ve4N2Z1xDhTsxi45hCLTcfDe3m5BNkvmybm1NglIbQejpZB46Vys6Sa6',
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDoJFY6Ca2Pec3A5XBXkfUkzmQPDhFtoErjDAOI0Of780fDdC6NWKVmiYd_5_PU2pFci0Tl2U7wXd24aZ1RO6ioGV4f94BffL5jFrqgyopmu9veE4v8Aauxz5v3pAv_jxr0AUgMtlyfSVfRhRyiIbc_7XyZjLkSw84bFMe48tLpoSBgoUzBItIF_4f-9EVn5kHVGH7WU66cjlxxeZabs9Px22C1ykxEtYkgeqes_vfR8p6QosDzx5h3',
          ],
        ),
      ],
      photoGallery: const [
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAW8iZ26KTJLVzh0H-zJLIWK2aMmB_MpfZeppATNtGzimrSeTQ4sgIzi_w8rFFWXpTewgyIAIzdLDUfvMcxdu0ehhprWOYuo32BDBZPh3tNYNblrGlt5_kkUrltt2zaVZvYBWvkw_VGotq2mXxWuBhGKPOpovnXamzkL697x0HBpKXt4Lsv4fyd7He2_Sa9Ve4N2Z1xDhTsxi45hCLTcfDe3m5BNkvmybm1NglIbQejpZB46Vys6Sa6',
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDoJFY6Ca2Pec3A5XBXkfUkzmQPDhFtoErjDAOI0Of780fDdC6NWKVmiYd_5_PU2pFci0Tl2U7wXd24aZ1RO6ioGV4f94BffL5jFrqgyopmu9veE4v8Aauxz5v3pAv_jxr0AUgMtlyfSVfRhRyiIbc_7XyZjLkSw84bFMe48tLpoSBgoUzBItIF_4f-9EVn5kHVGH7WU66cjlxxeZabs9Px22C1ykxEtYkgeqes_vfR8p6QosDzx5h3',
      ],
      isCompleted: true,
    );

    await DatabaseHelper.instance.saveExpeditionLog(newLog);

    setState(() {
      _isNavigating = false;
      _activeRedRoute = [];
      _showSpotCard = true;
    });

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetailLogEkspedisiPage(log: newLog, isNewlyCompleted: true),
      ),
    );
  }

  // Pelacakan lokasi perangkat secara nyata menggunakan GPS device
  void _toggleRealGpsTracking() {
    setState(() {
      _autoFollowUser = !_autoFollowUser;
    });

    if (_autoFollowUser) {
      if (_userLocation != null) {
        _mapController.move(_userLocation!, 16.0);
      } else {
        _initDeviceLocation();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pelacakan GPS perangkat aktif. Device mengikuti lokasi nyata.',
          ),
          backgroundColor: darkGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pelacakan GPS perangkat dihentikan.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Re-center ke Lokasi GPS User
  Future<void> _recenterUserLocation() async {
    setState(() => _autoFollowUser = true);
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.5);
    } else {
      await _initDeviceLocation();
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
  }

  void _moveToSpot(OutdoorSpot spot) {
    setState(() {
      _selectedSpot = spot;
      _hasManuallySelectedSpot = true;
      _showSpotCard = true;
      _showSearchResults = false;
      _searchFocusNode.unfocus();
    });
    _startNavigation(spot);
  }

  // Dapatkan daftar spot terfilter
  List<OutdoorSpot> get _filteredSpots {
    List<OutdoorSpot> list = List.from(_allSpots);

    if (_selectedCategoryFilter == 'tebing') {
      list = list.where((s) => s.type == SpotType.tebing).toList();
    } else if (_selectedCategoryFilter == 'goa') {
      list = list.where((s) => s.type == SpotType.goa).toList();
    } else if (_selectedCategoryFilter == 'terdekat' && _userLocation != null) {
      list.sort((a, b) {
        final distA = _getDistanceToSpot(a) ?? double.infinity;
        final distB = _getDistanceToSpot(b) ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((s) {
        return s.name.toLowerCase().contains(q) ||
            s.region.toLowerCase().contains(q) ||
            s.typeLabel.toLowerCase().contains(q) ||
            s.rockType.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  // Modal Petunjuk Arah Lengkap (Turn-by-Turn Bottom Sheet)
  void _showDirectionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: routeRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alt_route_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rute ke ${_selectedSpot.name}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Jarak: ${_activeDistanceKm.toStringAsFixed(1)} km • Estimasi: $_activeDurationMinutes Menit',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF616161),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _navigationSteps.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 20, indent: 44),
                    itemBuilder: (context, index) {
                      final step = _navigationSteps[index];
                      final isFirst = index == 0;
                      final isLast = index == _navigationSteps.length - 1;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLast
                                  ? routeRed
                                  : (isFirst
                                        ? const Color(0xFF1E88E5)
                                        : darkGreen.withValues(alpha: 0.08)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              step.icon,
                              size: 16,
                              color: isLast || isFirst
                                  ? Colors.white
                                  : darkGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.instruction,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  step.hint,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            step.distance,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Kembali ke Peta Navigasi',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLayerSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Pilih Tipe Tampilan Peta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_mapLayers.length, (idx) {
                  final layer = _mapLayers[idx];
                  final isSelected = _selectedLayerIndex == idx;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? darkGreen.withValues(alpha: 0.08)
                          : const Color(0xFFF7F5F0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? darkGreen : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        idx == 1
                            ? Icons.terrain_rounded
                            : (idx == 3 ? Icons.satellite_alt : Icons.map),
                        color: isSelected ? darkGreen : Colors.black54,
                      ),
                      title: Text(
                        layer['name']!,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: darkGreen,
                        ),
                      ),
                      subtitle: Text(
                        layer['desc']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF616161),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: darkGreen)
                          : null,
                      onTap: () {
                        setState(() => _selectedLayerIndex = idx);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllSpotsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Tebing & Goa Indonesia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: darkGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_allSpots.length} Destinasi',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allSpots.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final spot = _allSpots[index];
                      final isSelected = _selectedSpot.id == spot.id;
                      final isNearest = _nearestSpot?.id == spot.id;
                      final distance = _getDistanceToSpot(spot);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? darkGreen.withValues(alpha: 0.08)
                              : const Color(0xFFF7F5F0),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? darkGreen : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              spot.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, _) => Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade300,
                                child: Icon(spot.iconData, color: Colors.grey),
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: spot.badgeColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  spot.typeLabel.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  spot.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: darkGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${spot.region} • ${spot.elevation}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF616161),
                                ),
                              ),
                              if (distance != null)
                                Text(
                                  isNearest
                                      ? '📍 Terdekat (${distance.toStringAsFixed(1)} km dari Anda)'
                                      : '📍 ${distance.toStringAsFixed(1)} km dari Anda',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: isNearest
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFF757575),
                                  ),
                                ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: darkGreen,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            _moveToSpot(spot);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLayer = _mapLayers[_selectedLayerIndex];
    final displaySpots = _filteredSpots;
    final selectedDistance = _getDistanceToSpot(_selectedSpot);
    final isCurrentSpotNearest = _nearestSpot?.id == _selectedSpot.id;

    // Rute Polylines yang akan digambar
    final List<Polyline> activePolylines = [];

    if (_isNavigating && _activeRedRoute.isNotEmpty) {
      // Outline Putih untuk kontras tajam
      activePolylines.add(
        Polyline(
          points: _activeRedRoute,
          strokeWidth: 8.0,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      );
      // Garis Merah Rute Navigasi
      activePolylines.add(
        Polyline(points: _activeRedRoute, strokeWidth: 5.2, color: routeRed),
      );
    }

    return Scaffold(
      backgroundColor: bgCream,
      body: Stack(
        children: [
          // ===================================================================
          // 1. ENGINE PETA OPENSTREETMAP INTERAKTIF
          // ===================================================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedSpot.location,
              initialZoom: 13.5,
              minZoom: 3.0,
              maxZoom: 19.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && _autoFollowUser) {
                  setState(() => _autoFollowUser = false);
                }
              },
              onTap: (tapPosition, point) {
                if (_showSearchResults) {
                  setState(() => _showSearchResults = false);
                  _searchFocusNode.unfocus();
                }
              },
            ),
            children: [
              // TILE LAYER DARI OPENSTREETMAP
              TileLayer(
                urlTemplate: activeLayer['url']!,
                userAgentPackageName: 'com.suhlah.nara',
                maxZoom: 19,
              ),

              // JALUR MERAH NAVIGASI JALAN (OSRM ROAD ROUTING)
              PolylineLayer(polylines: activePolylines),

              // JANGKAUAN RADIUS AKURASI TITIK GPS USER (ACCURACY HALO)
              if (_userLocation != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _userLocation!,
                      radius: _gpsAccuracy > 0 ? _gpsAccuracy : 12.0,
                      useRadiusInMeter: true,
                      color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                      borderColor: const Color(
                        0xFF1E88E5,
                      ).withValues(alpha: 0.50),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // MARKER TITIK TEBING, GOA, DAN POSISI GPS USER
              MarkerLayer(
                markers: [
                  // Marker Spot-Spot Outdoor Tebing & Goa
                  ...displaySpots.map((spot) {
                    final isSelected = _selectedSpot.id == spot.id;
                    final isNearest = _nearestSpot?.id == spot.id;

                    return Marker(
                      point: spot.location,
                      width: isSelected ? 130 : 44,
                      height: isSelected ? 76 : 44,
                      child: GestureDetector(
                        onTap: () => _moveToSpot(spot),
                        child: isSelected
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: darkGreen,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isNearest) ...[
                                          const Icon(
                                            Icons.star,
                                            color: accentAmber,
                                            size: 10,
                                          ),
                                          const SizedBox(width: 3),
                                        ],
                                        Flexible(
                                          child: Text(
                                            spot.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: spot.badgeColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      spot.iconData,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: spot.badgeColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  spot.iconData,
                                  color: spot.badgeColor,
                                  size: 18,
                                ),
                              ),
                      ),
                    );
                  }),

                  // Marker Posisi GPS Pengguna (Real-time Live Pulse)
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 48,
                      height: 48,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 26 + (_pulseController.value * 16),
                                height: 26 + (_pulseController.value * 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5).withValues(
                                    alpha: 0.35 * (1 - _pulseController.value),
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ===================================================================
          // 2. SEARCH BAR & FILTER (JIKA TIDAK SEDANG DALAM MODE NAVIGASI)
          // ===================================================================
          if (!_isNavigating)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 6,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    decoration: BoxDecoration(
                      color: bgCream.withValues(alpha: 0.92),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: darkGreen,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (widget.onBack != null) {
                                    widget.onBack!();
                                  } else if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0xFFDCD6CA),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText:
                                        'Cari tebing, goa, atau koordinat...',
                                    hintStyle: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: darkGreen,
                                      size: 20,
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 38,
                                      minHeight: 44,
                                    ),
                                    suffixIconConstraints: const BoxConstraints(
                                      minWidth: 38,
                                      minHeight: 44,
                                    ),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(
                                              Icons.clear,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() {
                                                _searchQuery = '';
                                                _showSearchResults = false;
                                              });
                                            },
                                          )
                                        : null,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _searchQuery = val;
                                      _showSearchResults = val
                                          .trim()
                                          .isNotEmpty;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.cloud_download_outlined,
                                color: darkGreen,
                                size: 24,
                              ),
                              tooltip: 'Peta Offline',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PetaOfflinePage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildFilterChip(
                                'semua',
                                'Semua (${_allSpots.length})',
                                Icons.explore_outlined,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'tebing',
                                '🧗 Tebing (${_allSpots.where((s) => s.type == SpotType.tebing).length})',
                                Icons.terrain_rounded,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'goa',
                                '🦇 Goa (${_allSpots.where((s) => s.type == SpotType.goa).length})',
                                Icons.landscape_rounded,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'terdekat',
                                '📍 Terdekat',
                                Icons.near_me_outlined,
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

          // ===================================================================
          // 3. GOOGLE MAPS STYLE TOP NAVIGATION BANNER (JIKA NAVIGASI AKTIF)
          // ===================================================================
          if (_isNavigating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: routeRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentAmber,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'RUTE REKOMENDASI (OSRM)',
                                      style: TextStyle(
                                        color: darkGreen,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${_activeDistanceKm.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isLoadingRoute
                                    ? 'Menghitung rute terbaik...'
                                    : (_navigationSteps.length > 1
                                          ? _navigationSteps[1].instruction
                                          : 'Menuju ${_selectedSpot.name}'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 22,
                          ),
                          onPressed: _stopNavigation,
                          tooltip: 'Keluar Navigasi',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: _showDirectionsBottomSheet,
                              icon: const Icon(
                                Icons.list_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Petunjuk Arah',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: ElevatedButton.icon(
                              onPressed: _toggleRealGpsTracking,
                              icon: Icon(
                                _autoFollowUser
                                    ? Icons.gps_fixed_rounded
                                    : Icons.gps_not_fixed_rounded,
                                size: 16,
                                color: darkGreen,
                              ),
                              label: Text(
                                _autoFollowUser ? 'Ikuti GPS' : 'Nyalakan GPS',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: darkGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentAmber,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ===================================================================
          // 4. DROPDOWN HASIL PENCARIAN
          // ===================================================================
          if (_showSearchResults &&
              _searchQuery.trim().isNotEmpty &&
              !_isNavigating)
            Positioned(
              top: MediaQuery.of(context).padding.top + 105,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Builder(
                  builder: (context) {
                    final parsedCoordinate =
                        PetaInteraktifPage.parseCoordinateString(_searchQuery);

                    if (displaySpots.isEmpty && parsedCoordinate == null) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'Tidak ditemukan tebing atau goa yang sesuai.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (parsedCoordinate != null)
                          Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: routeRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: routeRed.withValues(alpha: 0.4),
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: routeRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.pin_drop_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              title: const Text(
                                'Tuju Titik Koordinat GPS',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              subtitle: Text(
                                '${parsedCoordinate.latitude.toStringAsFixed(5)}, ${parsedCoordinate.longitude.toStringAsFixed(5)} • Mulai Rute',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: routeRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.navigation_rounded,
                                size: 18,
                                color: routeRed,
                              ),
                              onTap: () {
                                final customSpot = OutdoorSpot(
                                  id: 'spot_custom_${DateTime.now().millisecondsSinceEpoch}',
                                  name:
                                      'Titik Koordinat: ${_searchQuery.trim()}',
                                  type: SpotType.tebing,
                                  region: 'Koordinat GPS Custom',
                                  coordinatesText: _searchQuery.trim(),
                                  location: parsedCoordinate,
                                  elevation: 'Spot Ekspedisi',
                                  rockType: 'Formasi Batuan Alam',
                                  grade: 'Rute Langsung',
                                  description:
                                      'Navigasi langsung menuju titik koordinat tujuan yang diketik.',
                                  rating: 5.0,
                                  imageUrl:
                                      'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=600',
                                  trailPoints: [
                                    ...?(_userLocation == null
                                        ? null
                                        : [_userLocation!]),
                                    parsedCoordinate,
                                  ],
                                );
                                setState(() {
                                  _allSpots.insert(0, customSpot);
                                });
                                _moveToSpot(customSpot);
                              },
                            ),
                          ),
                        ...displaySpots.map((spot) {
                          final dist = _getDistanceToSpot(spot);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: spot.badgeColor.withValues(
                                alpha: 0.15,
                              ),
                              child: Icon(
                                spot.iconData,
                                color: spot.badgeColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              spot.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            subtitle: Text(
                              '${spot.region}${dist != null ? ' • ${dist.toStringAsFixed(1)} km' : ''}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF616161),
                              ),
                            ),
                            trailing: const Icon(
                              Icons.north_east_rounded,
                              size: 16,
                              color: darkGreen,
                            ),
                            onTap: () => _moveToSpot(spot),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),

          // ===================================================================
          // 5. MAP CONTROLS FLOATING (KANAN ATAS)
          // ===================================================================
          Positioned(
            right: 16,
            top:
                MediaQuery.of(context).padding.top +
                (_isNavigating ? 140 : 115),
            child: Column(
              children: [
                _buildFloatingGlassButton(
                  icon: Icons.layers_outlined,
                  tooltip: 'Ganti Layer Peta',
                  onTap: _showLayerSelector,
                ),
                const SizedBox(height: 10),
                _buildFloatingGlassButton(
                  icon: Icons.format_list_bulleted_rounded,
                  tooltip: 'Semua Spot Ekspedisi',
                  onTap: _showAllSpotsSheet,
                ),
                const SizedBox(height: 10),
                _buildFloatingGlassButton(
                  icon: _isLocating
                      ? Icons.hourglass_top_rounded
                      : (_autoFollowUser
                            ? Icons.my_location
                            : Icons.location_searching_rounded),
                  tooltip: 'Pusatkan ke Lokasi Device (Ikuti Gerak)',
                  iconColor: _autoFollowUser
                      ? const Color(0xFF1E88E5)
                      : Colors.black54,
                  onTap: _recenterUserLocation,
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: darkGreen, size: 20),
                        onPressed: _zoomIn,
                        tooltip: 'Zoom In',
                      ),
                      Container(
                        width: 24,
                        height: 1,
                        color: const Color(0xFFE0E0E0),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          color: darkGreen,
                          size: 20,
                        ),
                        onPressed: _zoomOut,
                        tooltip: 'Zoom Out',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 6. STATUS BANNER GPS & INFO TERDEKAT (PILL FLOATING)
          // ===================================================================
          if (!_isNavigating)
            Positioned(
              bottom: _showSpotCard ? 230 : 90,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: darkGreen.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _userLocation != null
                            ? Icons.gps_fixed_rounded
                            : Icons.gps_not_fixed_rounded,
                        color: _userLocation != null
                            ? const Color(0xFF4CAF50)
                            : accentAmber,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _gpsStatusMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ===================================================================
          // 7. GOOGLE MAPS STYLE BOTTOM BAR (SAAT NAVIGASI AKTIF)
          // ===================================================================
          if (_isNavigating)
            Positioned(
              bottom: 20,
              left: 14,
              right: 14,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_activeDurationMinutes\nmenit',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_activeDistanceKm.toStringAsFixed(1)} km • Tiba ${_formatEtaTime(_activeDurationMinutes)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Menuju ${_selectedSpot.name}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF616161),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _stopNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: routeRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ===================================================================
          // 8. BOTTOM SPOT DETAIL CARD (KETIKA TIDAK DALAM MODE NAVIGASI AKTIF)
          // ===================================================================
          if (_showSpotCard && !_isNavigating)
            Positioned(
              bottom: 20,
              left: 14,
              right: 14,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              _selectedSpot.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, _) => Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey.shade300,
                                child: Icon(
                                  _selectedSpot.iconData,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _selectedSpot.badgeColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _selectedSpot.typeLabel.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    if (isCurrentSpotNearest) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2E7D32),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.near_me_rounded,
                                              color: Colors.white,
                                              size: 10,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'TERDEKAT',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedSpot.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedSpot.region,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF616161),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedDistance != null
                                            ? '${_selectedSpot.coordinatesText} • ${selectedDistance.toStringAsFixed(1)} km'
                                            : _selectedSpot.coordinatesText,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() => _showSpotCard = false);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UnduhAreaBaruPage(
                                        initialAreaName: _selectedSpot.name,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.download_rounded,
                                  size: 16,
                                  color: darkGreen,
                                ),
                                label: const Text(
                                  'Unduh Peta',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: darkGreen,
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _startNavigation(_selectedSpot),
                                icon: const Icon(
                                  Icons.navigation_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Mulai Navigasi',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: routeRed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatEtaTime(int minutesToAdd) {
    final now = DateTime.now().add(Duration(minutes: minutesToAdd));
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildFilterChip(String key, String label, IconData icon) {
    final isSelected = _selectedCategoryFilter == key;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: darkGreen,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? darkGreen : const Color(0xFFDCD6CA),
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedCategoryFilter = key;
          if (key == 'terdekat' && _nearestSpot != null) {
            _selectedSpot = _nearestSpot!;
            _mapController.move(_nearestSpot!.location, 14.0);
          }
        });
      },
    );
  }

  Widget _buildFloatingGlassButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? darkGreen, size: 20),
        onPressed: onTap,
        tooltip: tooltip,
      ),
    );
  }
}
