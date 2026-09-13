import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/core/theme/theme_provider.dart';

// Import Halaman Pendukung
import 'package:flutter_application_1/features/map/screens/offline_map_screen.dart';
import 'package:flutter_application_1/features/map/screens/interactive_map_screen.dart';
import 'package:flutter_application_1/features/map/screens/spot_detail_screen.dart';
import 'package:flutter_application_1/data/cave_data.dart';
import 'package:flutter_application_1/features/gear/screens/gear_screen.dart';
import 'package:flutter_application_1/features/gear/screens/gear_manager_screen.dart';
import 'package:flutter_application_1/features/gear/screens/maintenance_guide_screen.dart';
import 'package:flutter_application_1/features/safety/screens/safety_screen.dart';
import 'package:flutter_application_1/features/profile/screens/profile_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/auth/models/user_model.dart';

// Import Halaman Berita & Laporan
import 'package:flutter_application_1/features/news/screens/news_screen.dart';
import 'package:flutter_application_1/features/news/models/news_model.dart';
import 'package:flutter_application_1/features/news/screens/add_news_screen.dart';
import 'package:flutter_application_1/features/gear/screens/clothing_recommendation_screen.dart';
import 'package:flutter_application_1/features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.init();
  runApp(const NaraApp());
}

// ==========================================
// 2. MODEL & SERVICE CUACA REAL-TIME GPS
// ==========================================
class WeatherModel {
  final double latitude;
  final double longitude;
  final String locationName;
  final String currentTemp;
  final String condition;
  final String highLow;
  final String humidity;
  final String wind;
  final String uvIndex;
  final String visibility;
  final List<Map<String, dynamic>> hourly;
  final List<Map<String, dynamic>> daily;

  WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.currentTemp,
    required this.condition,
    required this.highLow,
    required this.humidity,
    required this.wind,
    required this.uvIndex,
    required this.visibility,
    required this.hourly,
    required this.daily,
  });
}

class WeatherService {
  static Future<Position> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS nonaktif. Harap aktifkan lokasi di perangkat.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi GPS ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Buka pengaturan aplikasi.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  static Map<String, dynamic> parseWmoCode(int code) {
    if (code == 0) {
      return {
        'desc': 'Cerah Bersih',
        'icon': Icons.wb_sunny_outlined,
        'color': Colors.orangeAccent,
      };
    } else if (code >= 1 && code <= 3) {
      return {
        'desc': 'Cerah Berawan',
        'icon': Icons.cloud_outlined,
        'color': const Color(0xFF757575),
      };
    } else if (code == 45 || code == 48) {
      return {
        'desc': 'Kabut Tebal',
        'icon': Icons.cloud_queue_rounded,
        'color': Colors.grey.shade600,
      };
    } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return {
        'desc': 'Hujan Rintik/Sedang',
        'icon': Icons.grain_rounded,
        'color': const Color(0xFF29B6F6),
      };
    } else if (code >= 95 && code <= 99) {
      return {
        'desc': 'Badai Petir',
        'icon': Icons.thunderstorm_outlined,
        'color': Colors.deepPurpleAccent,
      };
    }
    return {
      'desc': 'Berawan Tebal',
      'icon': Icons.wb_cloudy_outlined,
      'color': const Color(0xFF757575),
    };
  }

  /// Reverse geocoding presisi tinggi untuk mendapatkan Desa, Kabupaten/Kota, dan Negara
  static Future<Map<String, String>> reverseGeocodeDetail(
    double lat,
    double lon,
  ) async {
    String village = '';
    String kabupaten = '';
    String country = 'Indonesia';

    // 1. BigDataCloud API
    try {
      final geoUrl = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=id',
      );
      final geoRes = await http.get(geoUrl).timeout(const Duration(seconds: 4));
      if (geoRes.statusCode == 200) {
        final geoData = json.decode(geoRes.body);
        village = (geoData['locality'] ?? '').toString().trim();
        kabupaten = (geoData['city'] ?? '').toString().trim();
        country = (geoData['countryName'] ?? 'Indonesia').toString().trim();

        final adminList = geoData['localityInfo']?['administrative'] as List?;
        if (adminList != null) {
          for (var admin in adminList) {
            final int order = (admin['order'] as num?)?.toInt() ?? 0;
            final String name = (admin['name'] as String?)?.trim() ?? '';
            final String desc =
                (admin['description'] as String?)?.toLowerCase() ?? '';

            if (village.isEmpty &&
                (order >= 7 ||
                    desc.contains('desa') ||
                    desc.contains('kelurahan') ||
                    desc.contains('village'))) {
              village = name;
            }
            if (kabupaten.isEmpty &&
                (order == 5 ||
                    desc.contains('kabupaten') ||
                    desc.contains('kota') ||
                    desc.contains('regency'))) {
              kabupaten = name;
            }
          }
        }
      }
    } catch (_) {}

    // 2. OpenStreetMap Nominatim Fallback
    if (village.isEmpty || kabupaten.isEmpty) {
      try {
        final nomUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1&accept-language=id',
        );
        final nomRes = await http
            .get(nomUrl, headers: {'User-Agent': 'NARA_Outdoor_App/1.0'})
            .timeout(const Duration(seconds: 4));
        if (nomRes.statusCode == 200) {
          final nomData = json.decode(nomRes.body);
          final addr = nomData['address'] as Map<String, dynamic>?;
          if (addr != null) {
            if (village.isEmpty) {
              village =
                  (addr['village'] ??
                          addr['suburb'] ??
                          addr['hamlet'] ??
                          addr['quarter'] ??
                          addr['neighbourhood'] ??
                          addr['town'] ??
                          '')
                      .toString()
                      .trim();
            }
            if (kabupaten.isEmpty) {
              kabupaten =
                  (addr['county'] ??
                          addr['city'] ??
                          addr['municipality'] ??
                          addr['regency'] ??
                          addr['state_district'] ??
                          '')
                      .toString()
                      .trim();
            }
            if (country.isEmpty || country == 'Indonesia') {
              country = (addr['country'] ?? 'Indonesia').toString().trim();
            }
          }
        }
      } catch (_) {}
    }

    final List<String> parts = [];
    if (village.isNotEmpty) parts.add(village);
    if (kabupaten.isNotEmpty) parts.add(kabupaten);

    final String formatted = parts.isNotEmpty
        ? parts.join(', ')
        : 'Koordinat (${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)})';

    return {
      'village': village,
      'kabupaten': kabupaten,
      'negara': country,
      'formatted': formatted,
    };
  }

  static Future<WeatherModel> fetchRealtimeWeather() async {
    final position = await determinePosition();
    final double lat = position.latitude;
    final double lon = position.longitude;

    // Mendapatkan Desa, Kabupaten, dan Negara
    final locDetail = await reverseGeocodeDetail(lat, lon);
    final String locationName = locDetail['formatted']!;

    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,visibility'
      '&hourly=temperature_2m,weather_code,precipitation_probability'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,uv_index_max'
      '&timezone=auto',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data cuaca dari satelit Open-Meteo.');
    }

    final data = json.decode(response.body);
    final current = data['current'];
    final hourlyData = data['hourly'];
    final dailyData = data['daily'];

    final int weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;
    final currentParsed = parseWmoCode(weatherCode);
    final double curTemp =
        (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
    final double maxTemp =
        (dailyData['temperature_2m_max']?[0] as num?)?.toDouble() ?? curTemp;
    final double minTemp =
        (dailyData['temperature_2m_min']?[0] as num?)?.toDouble() ?? curTemp;
    final double uvMax =
        (dailyData['uv_index_max']?[0] as num?)?.toDouble() ?? 0.0;
    final double visibilityKm =
        (((current['visibility'] as num?) ?? 10000) / 1000).toDouble();

    final List<Map<String, dynamic>> hourly = [];
    final List times = hourlyData['time'] ?? [];
    final List temps = hourlyData['temperature_2m'] ?? [];
    final List codes = hourlyData['weather_code'] ?? [];
    final List pops = hourlyData['precipitation_probability'] ?? [];

    final DateTime now = DateTime.now();
    int currentHourIndex = times.indexWhere((t) {
      final dt = DateTime.tryParse(t.toString());
      if (dt == null) return false;
      return dt.hour == now.hour && dt.day == now.day;
    });
    if (currentHourIndex == -1) currentHourIndex = 0;

    for (int i = 0; i < 6; i++) {
      int idx = currentHourIndex + i;
      if (idx < times.length) {
        final dt = DateTime.tryParse(times[idx].toString()) ?? now;
        final int code = (codes[idx] as num?)?.toInt() ?? 0;
        final parsed = parseWmoCode(code);
        final int pop = (pops.length > idx && pops[idx] != null)
            ? (pops[idx] as num).toInt()
            : 0;

        hourly.add({
          'time': i == 0
              ? 'Sekarang'
              : '${dt.hour.toString().padLeft(2, '0')}:00',
          'icon': parsed['icon'],
          'iconColor': parsed['color'],
          'temp': '${((temps[idx] as num?) ?? 0).round()}°C',
          'isCurrent': i == 0,
          'rainProb': pop > 0 ? '$pop%' : null,
        });
      }
    }

    final List<String> dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final List<Map<String, dynamic>> daily = [];
    final List dTimes = dailyData['time'] ?? [];
    final List dMax = dailyData['temperature_2m_max'] ?? [];
    final List dMin = dailyData['temperature_2m_min'] ?? [];
    final List dCodes = dailyData['weather_code'] ?? [];

    for (int i = 0; i < dTimes.length && i < 5; i++) {
      final dt = DateTime.tryParse(dTimes[i].toString()) ?? now;
      final String dayLabel = i == 0
          ? 'Hari Ini'
          : dayNames[(dt.weekday - 1) % 7];
      final int code = (dCodes.length > i && dCodes[i] != null)
          ? (dCodes[i] as num).toInt()
          : 0;
      final parsed = parseWmoCode(code);

      daily.add({
        'day': dayLabel,
        'icon': parsed['icon'],
        'min': '${((dMin[i] as num?) ?? 0).round()}°',
        'max': '${((dMax[i] as num?) ?? 0).round()}°',
      });
    }

    return WeatherModel(
      latitude: lat,
      longitude: lon,
      locationName: locationName,
      currentTemp: '${curTemp.round()}°C',
      condition: currentParsed['desc'],
      highLow: 'H: ${maxTemp.round()}°C  L: ${minTemp.round()}°C',
      humidity: '${current['relative_humidity_2m'] ?? 0}%',
      wind: '${current['wind_speed_10m'] ?? 0} km/h',
      uvIndex: '${uvMax.round()} (${uvMax > 5 ? "Tinggi" : "Sedang"})',
      visibility: '${visibilityKm.round()} km',
      hourly: hourly,
      daily: daily,
    );
  }
}

// ==========================================
// 3. HALAMAN BERANDA UTAMA (NaraHomePage)
// ==========================================
class NaraApp extends StatelessWidget {
  const NaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NARA',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeController.instance.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class NaraHomePage extends StatefulWidget {
  const NaraHomePage({super.key});

  @override
  State<NaraHomePage> createState() => _NaraHomePageState();
}

class _NaraHomePageState extends State<NaraHomePage> {
  int _selectedNavIndex = 0;
  late Future<WeatherModel> _weatherFuture;
  bool _isLoadingLocation = false;

  final List<Map<String, dynamic>> _expedisiList = [
    {
      'title': 'Tebing Citatah 125',
      'location': 'Padalarang, Bandung Barat',
      'lat': -6.8396,
      'lon': 107.4524,
      'coordinates': '6°50\'25.8"S 107°27\'06.5"E',
      'rating': '4.8',
      'type': 'Tebing Panjat',
      'elevation': '125 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=800',
    },
    {
      'title': 'Gunung Parang',
      'location': 'Purwakarta, Jawa Barat',
      'lat': -6.5912,
      'lon': 107.3512,
      'coordinates': '6°35\'28.3"S 107°21\'04.3"E',
      'rating': '4.9',
      'type': 'Via Ferrata & Tebing',
      'elevation': '963 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
    },
    {
      'title': 'Tebing Hawu',
      'location': 'Padalarang, Bandung Barat',
      'lat': -6.8320,
      'lon': 107.4470,
      'coordinates': '6°49\'55.2"S 107°26\'49.2"E',
      'rating': '4.8',
      'type': 'Karst Alami',
      'elevation': '80 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
    },
    {
      'title': 'Tebing Citatah 90',
      'location': 'Padalarang, Bandung Barat',
      'lat': -6.8378,
      'lon': 107.4501,
      'coordinates': '6°50\'16.1"S 107°27\'00.4"E',
      'rating': '4.7',
      'type': 'Tebing Panjat',
      'elevation': '90 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=800',
    },
    {
      'title': 'Tebing Gunung Bongkok',
      'location': 'Purwakarta, Jawa Barat',
      'lat': -6.6020,
      'lon': 107.3420,
      'coordinates': '6°36\'07.2"S 107°20\'31.2"E',
      'rating': '4.7',
      'type': 'Andesit Rock',
      'elevation': '975 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
    },
    {
      'title': 'Tebing Kapur Ciampea',
      'location': 'Bogor, Jawa Barat',
      'lat': -6.5540,
      'lon': 106.6980,
      'coordinates': '6°33\'14.4"S 106°41\'52.8"E',
      'rating': '4.6',
      'type': 'Batu Kapur',
      'elevation': '350 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=800',
    },
    {
      'title': 'Tebing Siung',
      'location': 'Gunungkidul, D.I. Yogyakarta',
      'lat': -8.1819,
      'lon': 110.6833,
      'coordinates': '8°10\'54.8"S 110°41\'00.0"E',
      'rating': '4.9',
      'type': 'Coastal Cliff',
      'elevation': '45 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
    },
    {
      'title': 'Goa Jomblang',
      'location': 'Gunungkidul, D.I. Yogyakarta',
      'lat': -8.0287,
      'lon': 110.6384,
      'coordinates': '8°01\'43.3"S 110°38\'18.2"E',
      'rating': '5.0',
      'type': 'Luweng Vertikal',
      'elevation': 'Kedalaman 60m',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
    },
    {
      'title': 'Goa Pindul',
      'location': 'Gunungkidul, D.I. Yogyakarta',
      'lat': -7.9347,
      'lon': 110.6489,
      'coordinates': '7°56\'04.9"S 110°38\'56.0"E',
      'rating': '4.8',
      'type': 'Cave Tubing',
      'elevation': 'Panjang 350m',
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
    },
    {
      'title': 'Tebing Lembah Harau',
      'location': 'Lima Puluh Kota, Sumatera Barat',
      'lat': -0.0987,
      'lon': 100.6653,
      'coordinates': '0°05\'55.3"S 100°39\'55.1"E',
      'rating': '5.0',
      'type': 'Ngarai Granit',
      'elevation': '300 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
    },
    {
      'title': 'Karst Maros-Pangkep',
      'location': 'Maros, Sulawesi Selatan',
      'lat': -4.9961,
      'lon': 119.6833,
      'coordinates': '4°59\'46.0"S 119°41\'00.0"E',
      'rating': '4.9',
      'type': 'Menara Karst Raksasa',
      'elevation': '450 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800',
    },
    {
      'title': 'Tebing Uluwatu',
      'location': 'Badung, Bali',
      'lat': -8.8290,
      'lon': 115.0849,
      'coordinates': '8°49\'44.4"S 115°05\'05.6"E',
      'rating': '4.8',
      'type': 'Limestone Pesisir',
      'elevation': '70 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800',
    },
    {
      'title': 'Tebing Sepikul',
      'location': 'Trenggalek, Jawa Timur',
      'lat': -8.1567,
      'lon': 111.6421,
      'coordinates': '8°09\'24.1"S 111°38\'31.6"E',
      'rating': '4.7',
      'type': 'Andesit Monolit',
      'elevation': '250 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
    },
  ];

  UserModel? _currentUser;
  List<Map<String, dynamic>> get _filteredExpeditions => _expedisiList;

  @override
  void initState() {
    super.initState();
    for (final c in KlapanunggalCavesData.caves) {
      _expedisiList.add(Map<String, dynamic>.from(c));
    }
    _weatherFuture = WeatherService.fetchRealtimeWeather();
    _initDeviceLocationAndSort();
    _loadRegisteredUser();
  }

  void _bukaInformasiTempat(Map<String, dynamic> exp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InformasiTempatPage(spotData: exp),
      ),
    );
  }

  Future<void> _loadRegisteredUser() async {
    try {
      final user = await DatabaseHelper.instance.getLatestUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (_) {}
  }

  Future<void> _initDeviceLocationAndSort() async {
    if (_isLoadingLocation) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await WeatherService.determinePosition();
      if (!mounted) return;

      setState(() {
        _sortExpeditionsByProximity(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Default fallback coordinates (Bandung Barat area) if GPS offline
      setState(() {
        _sortExpeditionsByProximity(-6.9175, 107.6191);
        _isLoadingLocation = false;
      });
    }
  }

  void _sortExpeditionsByProximity(double userLat, double userLon) {
    for (var exp in _expedisiList) {
      final double lat = (exp['lat'] as num).toDouble();
      final double lon = (exp['lon'] as num).toDouble();
      final double distanceMeters = Geolocator.distanceBetween(
        userLat,
        userLon,
        lat,
        lon,
      );
      exp['distanceKm'] = distanceMeters / 1000.0;
    }

    _expedisiList.sort((a, b) {
      final double distA = (a['distanceKm'] as num?)?.toDouble() ?? 99999.0;
      final double distB = (b['distanceKm'] as num?)?.toDouble() ?? 99999.0;
      return distA.compareTo(distB);
    });
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = WeatherService.fetchRealtimeWeather();
    });
    _initDeviceLocationAndSort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      extendBody: true,
      body: _buildSelectedPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSelectedPage() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const PeriksaGearPage(showBackButton: false);
      case 2:
        return PetaInteraktifPage(
          onBack: () => setState(() => _selectedNavIndex = 0),
        );
      case 3:
        return KeamananPage(
          onBack: () => setState(() => _selectedNavIndex = 0),
        );
      case 4:
        return ProfilePage(
          onBack: () {
            setState(() => _selectedNavIndex = 0);
            _loadRegisteredUser();
          },
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildMiniAvatar(String? path) {
    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return Image.network(
          path,
          key: ValueKey(path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, size: 18),
        );
      } else {
        final file = File(path);
        if (file.existsSync()) {
          return Image.file(
            file,
            key: ValueKey(path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.person, size: 18),
          );
        }
      }
    }
    return const Icon(Icons.person, size: 18);
  }

  Widget _buildHomeContent() {
    final int readyGearCount = GearManager.readyCount;
    final int totalGearCount = GearManager.totalCount;
    final bool isAllGearReady = GearManager.isAllReady;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: context.themeBg.withValues(alpha: 0.85)),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Text(
                'NARA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: context.isDarkMode
                      ? AppTheme.darkPrimary
                      : const Color(0xFF143023),
                ),
              ),
            ],
          ),
          actions: [
            // Quick Theme Mode Toggle Button
            IconButton(
              icon: Icon(
                ThemeController.instance.isDarkMode(context)
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_outlined,
                color: context.themeTextSecondary,
                size: 22,
              ),
              tooltip: ThemeController.instance.isDarkMode(context)
                  ? 'Beralih ke Mode Terang'
                  : 'Beralih ke Mode Gelap',
              onPressed: () => ThemeController.instance.toggleTheme(context),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedNavIndex = 4),
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.themePrimary,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildMiniAvatar(_currentUser?.fotoProfil),
                ),
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: context.isDarkMode
                            ? [const Color(0xFF00796B), const Color(0xFF00E676)]
                            : [const Color(0xFF1B5E20), const Color(0xFF43A047)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'PETUALANGAN ANDA DIMULAI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Halo ${_currentUser?.nama ?? "Farhiyah"}! 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.themeText,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),

              _buildMainActionCard(),
              const SizedBox(height: 12),

              // 1. Kartu Peta Offline (Tema Hijau Emerald)
              _buildInfoCard(
                icon: Icons.map_outlined,
                title: 'Peta Offline Saya',
                iconColor: Colors.white,
                iconBgGradient: context.isDarkMode
                    ? const [Color(0xFF00796B), Color(0xFF00E676)]
                    : const [Color(0xFF1B5E20), Color(0xFF43A047)],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PetaOfflinePage(),
                    ),
                  );
                },
                badge: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: context.isDarkMode
                          ? const Color(0xFF00E676)
                          : const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'UNDUHAN SIAP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode
                            ? const Color(0xFF00E676)
                            : const Color(0xFF2E7D32),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Kartu Periksa Gear (Tema Sunset Amber/Orange)
              _buildInfoCard(
                icon: Icons.checklist_rounded,
                title: 'Periksa Gear Kamu',
                iconColor: Colors.white,
                iconBgGradient: context.isDarkMode
                    ? const [Color(0xFFFF5722), Color(0xFFFFB300)]
                    : const [Color(0xFFE65100), Color(0xFFFF9800)],
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PeriksaGearPage(),
                    ),
                  );
                  setState(() {});
                },
                badge: Row(
                  children: [
                    if (isAllGearReady) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: context.isDarkMode
                            ? const Color(0xFF00E676)
                            : const Color(0xFF2E7D32),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '$readyGearCount/$totalGearCount SIAP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAllGearReady
                            ? (context.isDarkMode
                                ? const Color(0xFF00E676)
                                : const Color(0xFF2E7D32))
                            : (context.isDarkMode
                                ? const Color(0xFFFF5252)
                                : const Color(0xFFE53935)),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Kartu Panduan Perawatan Alat (Tema Teal Karst)
              _buildInfoCard(
                icon: Icons.menu_book_rounded,
                title: 'Panduan Perawatan Alat',
                iconColor: Colors.white,
                iconBgGradient: context.isDarkMode
                    ? const [Color(0xFF00897B), Color(0xFF64FFDA)]
                    : const [Color(0xFF00695C), Color(0xFF26A69A)],
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PanduanPerawatanPage(),
                    ),
                  );
                  setState(() {});
                },
                badge: Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 14,
                      color: context.isDarkMode
                          ? const Color(0xFF64FFDA)
                          : const Color(0xFF00695C),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GOA & TEBING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode
                            ? const Color(0xFF64FFDA)
                            : const Color(0xFF00695C),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Kartu Rekomendasi Pakaian (Tema Twilight Violet)
              _buildInfoCard(
                icon: Icons.checkroom_rounded,
                title: 'Rekomendasi Pakaian',
                iconColor: Colors.white,
                iconBgGradient: context.isDarkMode
                    ? const [Color(0xFF651FFF), Color(0xFFB388FF)]
                    : const [Color(0xFF512DA8), Color(0xFF7C4DFF)],
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RekomendasiPakaianPage(),
                    ),
                  );
                  setState(() {});
                },
                badge: Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      size: 14,
                      color: context.isDarkMode
                          ? const Color(0xFFB388FF)
                          : const Color(0xFF512DA8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'SESUAI CUACA & MEDAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.isDarkMode
                            ? const Color(0xFFB388FF)
                            : const Color(0xFF512DA8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. Header Cuaca Real-Time
              _buildSectionHeader(
                title: 'PERKIRAAN CUACA REAL-TIME',
                actionWidget: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WeatherScreen(),
                      ),
                    ).then((_) => _refreshWeather());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF143023),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Baris Kartu Cuaca Real-Time Berbasis GPS
              FutureBuilder<WeatherModel>(
                future: _weatherFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: List.generate(
                        3,
                        (index) => Expanded(
                          child: Container(
                            height: 110,
                            margin: EdgeInsets.only(
                              right: index < 2 ? 12.0 : 0.0,
                            ),
                            decoration: BoxDecoration(
                              color: context.themeSurface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.themePrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return GestureDetector(
                      onTap: _refreshWeather,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.themeSurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: context.themeTerracotta,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Ketuk untuk memuat cuaca GPS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.themeTerracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final weather = snapshot.data!;
                  final displayHourly = weather.hourly.take(3).toList();

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeatherScreen(),
                        ),
                      ).then((_) => _refreshWeather());
                    },
                    child: Row(
                      children: displayHourly.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final item = entry.value;

                        final List<List<Color>> hourGradientsLight = [
                          const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                          const [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                          const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                        ];
                        final List<List<Color>> hourGradientsDark = [
                          const [Color(0xFF231B10), Color(0xFF1B140B)],
                          const [Color(0xFF0B2233), Color(0xFF091A27)],
                          const [Color(0xFF1F1635), Color(0xFF161026)],
                        ];
                        final List<Color> borderColors = [
                          const Color(0xFFF59E0B).withValues(alpha: context.isDarkMode ? 0.4 : 0.35),
                          const Color(0xFF0284C7).withValues(alpha: context.isDarkMode ? 0.4 : 0.35),
                          const Color(0xFF8B5CF6).withValues(alpha: context.isDarkMode ? 0.4 : 0.35),
                        ];

                        final cardGrad = context.isDarkMode
                            ? hourGradientsDark[idx % 3]
                            : hourGradientsLight[idx % 3];
                        final borderCol = borderColors[idx % 3];

                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: idx < 2 ? 12.0 : 0.0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: cardGrad,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: borderCol, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: borderCol.withValues(alpha: context.isDarkMode ? 0.25 : 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  item['time'],
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: context.themeTextSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (item['iconColor'] as Color).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: item['iconColor'] as Color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item['temp'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: context.themeText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // 5. Section Laporan Terkini (Geser Horizontal)
              _buildSectionHeader(
                title: 'LAPORAN TERKINI',
                actionWidget: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuatBeritaAcaraPage(),
                        ),
                      );
                      if (result != null) {
                        setState(() {});
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? AppTheme.darkPrimary
                            : const Color(0xFF143023),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (context.isDarkMode
                                    ? AppTheme.darkPrimary
                                    : const Color(0xFF143023))
                                .withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: context.isDarkMode
                            ? const Color(0xFF0F1713)
                            : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 380,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: BeritaManager.daftarBerita.length,
                  itemBuilder: (context, index) {
                    final item = BeritaManager.daftarBerita[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < BeritaManager.daftarBerita.length - 1
                            ? 14.0
                            : 0.0,
                      ),
                      child: _buildExpandedNewsCard(
                        tag: item.category,
                        time: item.timeAgo,
                        title: item.title,
                        imageUrl: item.headerImage,
                        rockType: item.rockType,
                        grade: item.grade,
                        summary: item.description,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LaporanEkspedisiDetailPage(
                                id: item.id,
                                title: item.title,
                                location: item.location,
                                coordinates: item.coordinates,
                                rating: item.rating,
                                category: item.category,
                                headerImage: item.headerImage,
                                photos: item.photos,
                                date: item.formattedDate,
                                duration: item.duration,
                                team: item.team,
                                elevation: item.elevation,
                                description: item.description,
                                technique: item.technique,
                                mainRope: item.mainRope,
                                rockType: item.rockType,
                                status: item.status,
                                verifiedCount: item.verifiedCount,
                                hoaxCount: item.hoaxCount,
                                isAdminMode: false,
                                onStatusChanged: () {
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),

        // 6. Section Ekspedisi Disarankan (Full-Width Green Background)
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isDarkMode
                    ? const [
                        Color(0xFF0F261B),
                        Color(0xFF163E2D),
                      ]
                    : const [
                        Color(0xFF143023),
                        Color(0xFF1F4E3A),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF143023).withValues(
                    alpha: context.isDarkMode ? 0.35 : 0.15,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, -4),
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
                        Icon(
                          Icons.explore_rounded,
                          color: Color(0xFFFED65B),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'EKSPEDISI DISARANKAN',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _initDeviceLocationAndSort,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isLoadingLocation
                                  ? Icons.sync
                                  : Icons.my_location_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Lokasi Saya',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 320,
                  child: Builder(
                    builder: (context) {
                      final list = _filteredExpeditions;
                      if (list.isEmpty) {
                        return const Center(
                          child: Text(
                            'Tidak ada ekspedisi untuk kategori ini',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        itemCount: list.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final exp = list[index];
                          final double? dist =
                              exp['distanceKm'] as double?;
                          final String distText = dist != null
                              ? (dist < 1.0
                                    ? '${(dist * 1000).round()} m'
                                    : '${dist.toStringAsFixed(1)} km')
                              : 'Jarak GPS';
                          final bool isNearest =
                              index == 0 && dist != null;

                          return _buildExpeditionCard(
                            rating: exp['rating'] ?? '4.8',
                            title: exp['title'],
                            location: exp['location'],
                            imageUrl: exp['imageUrl'],
                            distanceText: distText,
                            category: exp['type'],
                            isNearest: isNearest,
                            onTap: () => _bukaInformasiTempat(exp),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildExpandedNewsCard({
    required String tag,
    required String time,
    required String title,
    required String imageUrl,
    required String rockType,
    required String grade,
    required String summary,
    required VoidCallback onTap,
  }) {
    final String upperTag = tag.toUpperCase();
    final List<Color> tagGradient = upperTag.contains('WASPADA') || upperTag.contains('BAHAYA')
        ? (context.isDarkMode ? const [Color(0xFFD32F2F), Color(0xFFFF5252)] : const [Color(0xFFC62828), Color(0xFFEF5350)])
        : upperTag.contains('PANJAT') || upperTag.contains('CLIMB')
            ? (context.isDarkMode ? const [Color(0xFFFF5722), Color(0xFFFFB300)] : const [Color(0xFFE65100), Color(0xFFFF9800)])
            : upperTag.contains('GOA') || upperTag.contains('SPELEO')
                ? (context.isDarkMode ? const [Color(0xFF651FFF), Color(0xFFB388FF)] : const [Color(0xFF512DA8), Color(0xFF7C4DFF)])
                : (context.isDarkMode ? const [Color(0xFF00796B), Color(0xFF00E676)] : const [Color(0xFF1B5E20), Color(0xFF43A047)]);
    final Color brandGreen = tagGradient.first;

    return Container(
      width: 295,
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.isDarkMode
              ? context.themeBorder.withValues(alpha: 0.8)
              : context.themeBorder,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Left accent indicator
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: tagGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: tagGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 115,
                    width: double.infinity,
                    child: _buildAdaptiveImage(imageUrl, height: 115),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF332616) : const Color(0xFFFBF1DE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rockType,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? const Color(0xFF142B28) : const Color(0xFFE2F4EF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            size: 14,
                            color: Color(0xFF0D9488),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            grade,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: context.themeTextSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'BACA SELENGKAPNYA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
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

  static Widget _buildAdaptiveImage(
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

  Widget _buildMainActionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.isDarkMode
              ? const Color(0xFF2D6A4F).withValues(alpha: 0.35)
              : context.themeBorder,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF143023).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedNavIndex = 2);
          },
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  top: -12,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E0D5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.themeCard,
                        width: 4,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/sula.jpeg'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: context.isDarkMode
                              ? const [Color(0xFFFF5722), Color(0xFFFFB300)]
                              : const [Color(0xFFE65100), Color(0xFFFF9800)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE65100).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rencanakan Petualangan Baru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Mulai rute ekspedisi Anda',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: context.themePrimary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget badge,
    Color? iconColor,
    List<Color>? iconBgGradient,
    VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.isDarkMode
              ? (iconBgGradient != null
                  ? iconBgGradient.last.withValues(alpha: 0.25)
                  : context.themeBorder)
              : context.themeBorder,
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    gradient: iconBgGradient != null
                        ? LinearGradient(
                            colors: iconBgGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: iconBgGradient == null
                        ? context.themeTerracotta.withValues(alpha: 0.14)
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: iconBgGradient != null
                        ? [
                            BoxShadow(
                              color: iconBgGradient.last.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: context.themeText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      badge,
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgGradient != null
                        ? iconBgGradient.first.withValues(alpha: 0.12)
                        : context.themePrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: iconBgGradient != null
                        ? iconBgGradient.first
                        : context.themePrimary,
                    size: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, Widget? actionWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: context.themeTextSecondary,
            letterSpacing: 0.8,
          ),
        ),
        ?actionWidget,
      ],
    );
  }

  Widget _buildExpeditionCard({
    required String rating,
    required String title,
    required String location,
    required String imageUrl,
    String? distanceText,
    String? category,
    bool isNearest = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildAdaptiveImage(
                  imageUrl,
                  height: double.infinity,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.88),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Rating Badge (Kiri Atas)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Distance / Nearest Badge (Kanan Atas)
              if (distanceText != null)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isNearest
                          ? const Color(0xFFFED65B)
                          : Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isNearest ? Icons.near_me_rounded : Icons.location_on,
                          size: 11,
                          color: isNearest
                              ? const Color(0xFF001D0F)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          distanceText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isNearest
                                ? const Color(0xFF001D0F)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Spot Info & Action Button (Bawah)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (category != null) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: category.toLowerCase().contains('goa')
                                          ? const [Color(0xFF0284C7), Color(0xFF06B6D4)]
                                          : category.toLowerCase().contains('tebing')
                                              ? const [Color(0xFFD97706), Color(0xFFF59E0B)]
                                              : const [Color(0xFF059669), Color(0xFF10B981)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white12, width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 12),
                                      SizedBox(width: 2),
                                      Text(
                                        '4.8',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                          ],
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.place_rounded,
                                color: Color(0xFF38BDF8),
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation_rounded,
                        color: Color(0xFF001D0F),
                        size: 16,
                      ),
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

  Widget _buildBottomNavigationBar() {
    final bool isDark = context.isDarkMode;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 78,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Bar Background
            Container(
              height: 62,
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
              decoration: BoxDecoration(
                color: context.themeCard.withValues(alpha: isDark ? 0.95 : 0.98),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFF143023).withValues(alpha: 0.1),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                  _buildNavItem(1, Icons.handyman_rounded, 'Alat'),
                  const Expanded(child: SizedBox()), // Ruang untuk tombol pop-up tengah
                  _buildNavItem(3, Icons.health_and_safety_rounded, 'Keamanan'),
                  _buildNavItem(4, Icons.person_rounded, 'Profil'),
                ],
              ),
            ),
            // Floating Pop-up Green Center Map Button
            Positioned(
              bottom: 14,
              child: _buildCenterNavItem(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedNavIndex == index;
    final List<Color> tabActiveColors = [
      context.isDarkMode ? const Color(0xFF00E676) : const Color(0xFF1B5E20), // Beranda: Emerald
      context.isDarkMode ? const Color(0xFFFFB300) : const Color(0xFFE65100), // Alat: Amber Orange
      context.isDarkMode ? const Color(0xFF00E5FF) : const Color(0xFF0288D1), // Peta
      context.isDarkMode ? const Color(0xFFFF5252) : const Color(0xFFE53935), // Keamanan: Crimson Coral
      context.isDarkMode ? const Color(0xFFB388FF) : const Color(0xFF512DA8), // Profil: Mountain Violet
    ];

    final Color activeColor = tabActiveColors[index % tabActiveColors.length];
    final Color inactiveColor = context.themeTextSecondary;
    final Color currentColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedNavIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(
                        alpha: context.isDarkMode ? 0.22 : 0.12,
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: currentColor, size: 21),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: currentColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    final bool isSelected = _selectedNavIndex == 2;
    final bool isDark = context.isDarkMode;
    final Color greenPrimary = isDark
        ? const Color(0xFF2D6A4F)
        : const Color(0xFF1B4332);
    final Color greenAccent = isDark
        ? const Color(0xFF52B788)
        : const Color(0xFF2D6A4F);

    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = 2),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutBack,
            width: isSelected ? 54 : 48,
            height: isSelected ? 54 : 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isSelected
                    ? [greenAccent, greenPrimary]
                    : [greenPrimary, const Color(0xFF143023)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: context.themeCard,
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: greenPrimary.withValues(
                    alpha: isSelected ? 0.55 : 0.35,
                  ),
                  blurRadius: isSelected ? 14 : 9,
                  spreadRadius: isSelected ? 1 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.map_rounded,
                color: Colors.white,
                size: isSelected ? 26 : 22,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Peta',
            maxLines: 1,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? (isDark ? AppTheme.darkPrimary : const Color(0xFF143023))
                  : context.themeTextSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 4. HALAMAN DETAIL CUACA (WeatherScreen)
// ==========================================
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<WeatherModel> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _refreshWeather();
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = WeatherService.fetchRealtimeWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<WeatherModel>(
            future: _weatherFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.lightBlueAccent),
                      SizedBox(height: 16),
                      Text(
                        'Mendeteksi GPS & Mengambil Cuaca...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          size: 64,
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${snapshot.error}'.replaceAll('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _refreshWeather,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final weather = snapshot.data!;
              return RefreshIndicator(
                color: Colors.blueAccent,
                onRefresh: () async => _refreshWeather(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    _buildMainHeader(weather),
                    const SizedBox(height: 28),
                    _buildHourlySection(weather.hourly),
                    const SizedBox(height: 24),
                    _buildDailySection(weather.daily),
                    const SizedBox(height: 24),
                    _buildDetailGrid(weather),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainHeader(WeatherModel weather) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: Colors.lightBlueAccent,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                weather.locationName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          weather.currentTemp,
          style: const TextStyle(
            fontSize: 76,
            fontWeight: FontWeight.w200,
            letterSpacing: -2,
            color: Colors.white,
          ),
        ),
        Text(
          weather.condition,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          weather.highLow,
          style: const TextStyle(fontSize: 14, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildHourlySection(List<Map<String, dynamic>> hourly) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: Colors.white60,
                ),
                SizedBox(width: 8),
                Text(
                  'PRAKIRAAN TIAP JAM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: hourly.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final item = hourly[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['time'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    Icon(item['icon'], color: item['iconColor'], size: 28),
                    Text(
                      item['temp'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildDailySection(List<Map<String, dynamic>> daily) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: Colors.white60,
              ),
              SizedBox(width: 8),
              Text(
                'PRAKIRAAN BEBERAPA HARI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...daily.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['day'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Icon(
                      item['icon'],
                      color: Colors.orangeAccent,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${item['min']}  /  ${item['max']}',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailGrid(WeatherModel weather) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          Icons.water_drop_outlined,
          'KELEMBAPAN',
          weather.humidity,
        ),
        _buildMetricCard(Icons.air_rounded, 'ANGIN', weather.wind),
        _buildMetricCard(Icons.wb_sunny_rounded, 'INDEKS UV', weather.uvIndex),
        _buildMetricCard(
          Icons.visibility_outlined,
          'JARAK PANDANG',
          weather.visibility,
        ),
      ],
    );
  }

  Widget _buildMetricCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white60),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
