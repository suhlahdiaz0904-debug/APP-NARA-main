import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_application_1/core/theme/theme_provider.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Cuaca',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const WeatherScreen(),
    );
  }
}

// ==========================================
// 1. MODEL DATA CUACA
// ==========================================
class WeatherModel {
  final double latitude;
  final double longitude;
  final String locationName;
  final String village;
  final String kabupaten;
  final String negara;
  final String currentTemp;
  final String condition;
  final String highLow;
  final String humidity;
  final String wind;
  final String uvIndex;
  final String visibility;
  final List<Map<String, dynamic>> hourly;
  final List<Map<String, dynamic>> daily;
  final bool isDefaultLocation;

  WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.village = '',
    this.kabupaten = '',
    this.negara = 'Indonesia',
    required this.currentTemp,
    required this.condition,
    required this.highLow,
    required this.humidity,
    required this.wind,
    required this.uvIndex,
    required this.visibility,
    required this.hourly,
    required this.daily,
    this.isDefaultLocation = false,
  });
}

// ==========================================
// 2. SERVICE API & LOKASI
// ==========================================
class WeatherService {
  static Future<Position?> determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        try {
          return await Geolocator.getLastKnownPosition();
        } catch (_) {}
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          try {
            return await Geolocator.getLastKnownPosition();
          } catch (_) {}
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        try {
          return await Geolocator.getLastKnownPosition();
        } catch (_) {}
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (_) {
        return await Geolocator.getLastKnownPosition();
      }
    } catch (_) {
      return null;
    }
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
        'color': Colors.amber.shade200,
      };
    } else if (code == 45 || code == 48) {
      return {
        'desc': 'Kabut Tebal',
        'icon': Icons.cloud_queue_rounded,
        'color': Colors.grey.shade400,
      };
    } else if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return {
        'desc': 'Hujan Rintik/Sedang',
        'icon': Icons.grain_rounded,
        'color': Colors.lightBlueAccent,
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
      'color': Colors.blueGrey.shade200,
    };
  }

  /// Reverse geocoding presisi tinggi untuk mendapatkan Desa, Kabupaten/Kota, dan Negara
  static Future<Map<String, String>> reverseGeocodeDetail(double lat, double lon) async {
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
            final String desc = (admin['description'] as String?)?.toLowerCase() ?? '';

            if (village.isEmpty && (order >= 7 || desc.contains('desa') || desc.contains('kelurahan') || desc.contains('village'))) {
              village = name;
            }
            if (kabupaten.isEmpty && (order == 5 || desc.contains('kabupaten') || desc.contains('kota') || desc.contains('regency'))) {
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
        final nomRes = await http.get(nomUrl, headers: {
          'User-Agent': 'NARA_Outdoor_App/1.0',
        }).timeout(const Duration(seconds: 4));
        if (nomRes.statusCode == 200) {
          final nomData = json.decode(nomRes.body);
          final addr = nomData['address'] as Map<String, dynamic>?;
          if (addr != null) {
            if (village.isEmpty) {
              village = (addr['village'] ??
                  addr['suburb'] ??
                  addr['hamlet'] ??
                  addr['quarter'] ??
                  addr['neighbourhood'] ??
                  addr['town'] ??
                  '').toString().trim();
            }
            if (kabupaten.isEmpty) {
              kabupaten = (addr['county'] ??
                  addr['city'] ??
                  addr['municipality'] ??
                  addr['regency'] ??
                  addr['state_district'] ??
                  '').toString().trim();
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
    final bool isDefaultLoc = (position == null);
    final double lat = position?.latitude ?? -6.1754;
    final double lon = position?.longitude ?? 106.8272;

    // Mendapatkan Desa, Kabupaten, dan Negara
    Map<String, String> locDetail = {};
    try {
      locDetail = await reverseGeocodeDetail(lat, lon);
    } catch (_) {}

    String locationName = locDetail['formatted'] ?? '';
    if (locationName.isEmpty || locationName.startsWith('Koordinat')) {
      locationName = isDefaultLoc ? 'Jakarta Pusat, DKI Jakarta' : 'Lokasi Terdeteksi';
    }
    final String village = locDetail['village'] ?? (isDefaultLoc ? 'Gambir' : '');
    final String kabupaten = locDetail['kabupaten'] ?? (isDefaultLoc ? 'Jakarta Pusat' : '');
    final String negara = locDetail['negara'] ?? 'Indonesia';

    // Panggil API Open-Meteo
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

    // Data Per Jam (6 Jam Kedepan)
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
          'temp': '${((temps[idx] as num?) ?? 0).round()}°',
          'isCurrent': i == 0,
          'rainProb': pop > 0 ? '$pop%' : null,
        });
      }
    }

    // Data 5 Hari Kedepan
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
      village: village,
      kabupaten: kabupaten,
      negara: negara,
      currentTemp: '${curTemp.round()}°C',
      condition: currentParsed['desc'],
      highLow: 'H: ${maxTemp.round()}°C  L: ${minTemp.round()}°C',
      humidity: '${current['relative_humidity_2m'] ?? 0}%',
      wind: '${current['wind_speed_10m'] ?? 0} km/h',
      uvIndex: '${uvMax.round()} (${uvMax > 5 ? "Tinggi" : "Sedang"})',
      visibility: '${visibilityKm.round()} km',
      hourly: hourly,
      daily: daily,
      isDefaultLocation: isDefaultLoc,
    );
  }
}

// ==========================================
// 3. TAMPILAN UTAMA (UI)
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
          icon: Icon(Icons.arrow_back_rounded, color: context.themePrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Prakiraan Cuaca',
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
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.themePrimary),
            tooltip: 'Segarkan Cuaca',
            onPressed: _refreshWeather,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<WeatherModel>(
          future: _weatherFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: context.themePrimary),
                    const SizedBox(height: 16),
                    Text(
                      'Mendeteksi GPS & Mengambil Cuaca...',
                      style: TextStyle(color: context.themeTextSecondary),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              final errorStr = '${snapshot.error}'.replaceAll('Exception: ', '');
              final bool isPermissionPermanentlyDenied =
                  errorStr.toLowerCase().contains('permanen') ||
                  errorStr.toLowerCase().contains('manifest');
              final bool isGpsDisabled =
                  errorStr.toLowerCase().contains('gps') ||
                  errorStr.toLowerCase().contains('nonaktif');

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        size: 64,
                        color: AppTheme.goldAccentDark,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.themeText,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          if (isPermissionPermanentlyDenied)
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Geolocator.openAppSettings();
                              },
                              icon: const Icon(Icons.settings_rounded, size: 18),
                              label: const Text('Buka Pengaturan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.themePrimary,
                                side: BorderSide(color: context.themePrimary),
                              ),
                            ),
                          if (isGpsDisabled)
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Geolocator.openLocationSettings();
                              },
                              icon: const Icon(Icons.location_on_rounded, size: 18),
                              label: const Text('Aktifkan GPS'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: context.themePrimary,
                                side: BorderSide(color: context.themePrimary),
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: _refreshWeather,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Coba Lagi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.themePrimary,
                              foregroundColor:
                                  isDark ? const Color(0xFF0F1713) : Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            final weather = snapshot.data!;
            return RefreshIndicator(
              color: context.themePrimary,
              onRefresh: () async => _refreshWeather(),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildMainHeader(weather),
                  const SizedBox(height: 24),
                  _buildHourlySection(weather.hourly),
                  const SizedBox(height: 20),
                  _buildDailySection(weather.daily),
                  const SizedBox(height: 20),
                  _buildDetailGrid(weather),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainHeader(WeatherModel weather) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: context.themeCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.themeBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: context.themePrimary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  weather.locationName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (weather.village.isNotEmpty || weather.kabupaten.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              if (weather.village.isNotEmpty)
                _buildLocationPill('Kelurahan: ${weather.village}'),
              if (weather.kabupaten.isNotEmpty)
                _buildLocationPill('Kabupaten: ${weather.kabupaten}'),
            ],
          ),
        ],
        if (weather.isDefaultLocation) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              try {
                final perm = await Geolocator.checkPermission();
                if (perm == LocationPermission.deniedForever) {
                  await Geolocator.openAppSettings();
                } else {
                  final isGps = await Geolocator.isLocationServiceEnabled();
                  if (!isGps) {
                    await Geolocator.openLocationSettings();
                  } else {
                    await Geolocator.requestPermission();
                  }
                }
              } catch (_) {}
              _refreshWeather();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text(
                    'Lokasi Default (GPS nonaktif/izin ditolak) - Ketuk untuk aktifkan',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.isDarkMode
                          ? Colors.amber.shade200
                          : Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          weather.currentTemp,
          style: TextStyle(
            fontSize: 76,
            fontWeight: FontWeight.w200,
            color: context.themeText,
            letterSpacing: -2,
          ),
        ),
        Text(
          weather.condition,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: context.themeTextSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          weather.highLow,
          style: TextStyle(fontSize: 14, color: context.themeTextSecondary),
        ),
      ],
    );
  }

  Widget _buildLocationPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.themeBorder),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: context.themeTextSecondary,
        ),
      ),
    );
  }

  Widget _buildHourlySection(List<Map<String, dynamic>> hourly) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: context.themeTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'PRAKIRAAN TIAP JAM',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextSecondary,
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
                      style: TextStyle(
                        fontSize: 13,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    Icon(item['icon'], color: item['iconColor'], size: 28),
                    Text(
                      item['temp'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
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
        color: context.themeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: context.themeTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'PRAKIRAAN BEBERAPA HARI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.themeTextSecondary,
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: context.themeText,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Icon(
                      item['icon'],
                      color: AppTheme.goldAccentDark,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${item['min']}  /  ${item['max']}',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 15,
                        color: context.themeTextSecondary,
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
        color: context.themeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.themeTextSecondary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.themeTextSecondary,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: context.themeText,
            ),
          ),
        ],
      ),
    );
  }
}
