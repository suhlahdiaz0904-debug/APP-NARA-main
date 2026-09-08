import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/map/screens/interactive_map_screen.dart';
import 'package:flutter_application_1/features/map/screens/map_view_screen.dart';

// =========================================================================
// HALAMAN MANAJER PETA OFFLINE (TEBING & GOA SE-INDONESIA)
// =========================================================================
class PetaOfflinePage extends StatefulWidget {
  const PetaOfflinePage({super.key});

  @override
  State<PetaOfflinePage> createState() => _PetaOfflinePageState();
}

class _PetaOfflinePageState extends State<PetaOfflinePage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Timer> _activeDownloadTimers = {};

  int _selectedFilterIndex = 0;

  final List<Map<String, dynamic>> _mapFilterCategories = [
    {
      'name': 'Semua',
      'label': 'Semua Peta',
      'icon': Icons.auto_awesome_rounded,
      'gradient': [Color(0xFF143023), Color(0xFF2E7D32)],
      'accentColor': Color(0xFF4CAF78),
      'unselectedBg': Color(0xFFE8F5E9),
      'unselectedIcon': Color(0xFF2E7D32),
    },
    {
      'name': 'Tebing Panjat',
      'label': 'Tebing Panjat',
      'icon': Icons.terrain_rounded,
      'gradient': [Color(0xFFD84315), Color(0xFFFF6E40)],
      'accentColor': Color(0xFFFFAB91),
      'unselectedBg': Color(0xFFFBE9E7),
      'unselectedIcon': Color(0xFFD84315),
    },
    {
      'name': 'Goa Karst',
      'label': 'Goa Karst',
      'icon': Icons.dark_mode_rounded,
      'gradient': [Color(0xFF4527A0), Color(0xFF7C4DFF)],
      'accentColor': Color(0xFFB388FF),
      'unselectedBg': Color(0xFFEDE7F6),
      'unselectedIcon': Color(0xFF512DA8),
    },
    {
      'name': 'Terunduh',
      'label': 'Siap Offline',
      'icon': Icons.download_done_rounded,
      'gradient': [Color(0xFF00695C), Color(0xFF00BFA5)],
      'accentColor': Color(0xFFA7FFEB),
      'unselectedBg': Color(0xFFE0F2F1),
      'unselectedIcon': Color(0xFF00796B),
    },
  ];

  // Master Data 20+ Tebing & Goa Tersinkronisasi dengan Peta Interaktif
  final List<Map<String, dynamic>> _allMaps = [
    // --- TEBING PANJAT ALAM ---
    {
      'id': '1',
      'title': 'Tebing Citatah 125',
      'subtitle': '450 MB • Padalarang, Bandung Barat',
      'type': 'Tebing Panjat',
      'coordinates': '6°50\'25.8"S 107°27\'06.5"E',
      'elevation': '125 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=300',
      'status': 'completed',
    },
    {
      'id': '2',
      'title': 'Gunung Parang',
      'subtitle': '180 MB • Purwakarta, Jawa Barat',
      'type': 'Tebing Panjat',
      'coordinates': '6°35\'28.3"S 107°21\'04.3"E',
      'elevation': '963 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300',
      'status': 'completed',
    },
    {
      'id': '3',
      'title': 'Tebing Siung',
      'subtitle': '320 MB • Gunungkidul, D.I. Yogyakarta',
      'type': 'Tebing Panjat',
      'coordinates': '8°10\'54.8"S 110°41\'00.0"E',
      'elevation': '45 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300',
      'status': 'completed',
    },
    {
      'id': '4',
      'title': 'Tebing Lembah Harau',
      'subtitle': '500 MB • Lima Puluh Kota, Sumbar',
      'type': 'Tebing Panjat',
      'coordinates': '0°05\'55.3"S 100°39\'55.1"E',
      'elevation': '300 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '5',
      'title': 'Tebing Hawu',
      'subtitle': '210 MB • Padalarang, Bandung Barat',
      'type': 'Tebing Panjat',
      'coordinates': '6°49\'55.2"S 107°26\'49.2"E',
      'elevation': '80 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '6',
      'title': 'Tebing Citatah 90',
      'subtitle': '280 MB • Padalarang, Bandung Barat',
      'type': 'Tebing Panjat',
      'coordinates': '6°50\'16.1"S 107°27\'00.4"E',
      'elevation': '90 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '7',
      'title': 'Tebing Gunung Bongkok',
      'subtitle': '195 MB • Purwakarta, Jawa Barat',
      'type': 'Tebing Panjat',
      'coordinates': '6°36\'07.2"S 107°20\'31.2"E',
      'elevation': '975 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '8',
      'title': 'Tebing Kapur Ciampea',
      'subtitle': '160 MB • Bogor, Jawa Barat',
      'type': 'Tebing Panjat',
      'coordinates': '6°33\'14.4"S 106°41\'52.8"E',
      'elevation': '350 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '9',
      'title': 'Tebing Karang Uluwatu',
      'subtitle': '340 MB • Badung, Bali',
      'type': 'Tebing Panjat',
      'coordinates': '8°49\'44.4"S 115°05\'05.6"E',
      'elevation': '70 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '10',
      'title': 'Tebing Sepikul',
      'subtitle': '275 MB • Trenggalek, Jawa Timur',
      'type': 'Tebing Panjat',
      'coordinates': '8°09\'24.1"S 111°38\'31.6"E',
      'elevation': '250 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300',
      'status': 'not_downloaded',
    },

    // --- GOA KARST & CAVING ---
    {
      'id': '11',
      'title': 'Goa Jomblang',
      'subtitle': '250 MB • Gunungkidul, D.I. Yogyakarta',
      'type': 'Goa Karst',
      'coordinates': '8°01\'43.3"S 110°38\'18.2"E',
      'elevation': 'Vertikal 60m',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300',
      'status': 'completed',
    },
    {
      'id': '12',
      'title': 'Goa Pindul',
      'subtitle': '150 MB • Gunungkidul, D.I. Yogyakarta',
      'type': 'Goa Karst',
      'coordinates': '7°56\'04.9"S 110°38\'56.0"E',
      'elevation': 'Sungai 350m',
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300',
      'status': 'completed',
    },
    {
      'id': '13',
      'title': 'Karst Maros-Pangkep',
      'subtitle': '800 MB • Maros, Sulawesi Selatan',
      'type': 'Goa Karst',
      'coordinates': '4°59\'46.0"S 119°41\'00.0"E',
      'elevation': '450 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1508873696983-2df515122519?w=300',
      'status': 'downloading',
      'progress': 0.65,
      'percentage': '65%',
    },
    {
      'id': '14',
      'title': 'Goa Gong',
      'subtitle': '310 MB • Pacitan, Jawa Timur',
      'type': 'Goa Karst',
      'coordinates': '8°09\'47.9"S 110°58\'50.2"E',
      'elevation': 'Kedalaman 256m',
      'imageUrl':
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '15',
      'title': 'Goa Maharani',
      'subtitle': '210 MB • Lamongan, Jawa Timur',
      'type': 'Goa Karst',
      'coordinates': '6°51\'52.9"S 112°21\'29.5"E',
      'elevation': 'Kedalaman 25m',
      'imageUrl':
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '16',
      'title': 'Goa Petruk',
      'subtitle': '240 MB • Kebumen, Jawa Tengah',
      'type': 'Goa Karst',
      'coordinates': '7°41\'17.2"S 109°24\'45.0"E',
      'elevation': 'Panjang 2.000m',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '17',
      'title': 'Goa Barat',
      'subtitle': '220 MB • Kebumen, Jawa Tengah',
      'type': 'Goa Karst',
      'coordinates': '7°41\'06.0"S 109°24\'54.0"E',
      'elevation': 'Air Terjun 32m',
      'imageUrl':
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '18',
      'title': 'Goa Cerme',
      'subtitle': '190 MB • Bantul, D.I. Yogyakarta',
      'type': 'Goa Karst',
      'coordinates': '7°56\'21.1"S 110°23\'44.2"E',
      'elevation': 'Panjang 1.500m',
      'imageUrl':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '19',
      'title': 'Goa Pawon',
      'subtitle': '175 MB • Padalarang, Bandung Barat',
      'type': 'Goa Karst',
      'coordinates': '6°49\'43.0"S 107°26\'08.9"E',
      'elevation': '720 mdpl',
      'imageUrl':
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=300',
      'status': 'not_downloaded',
    },
    {
      'id': '20',
      'title': 'Goa Rangko',
      'subtitle': '290 MB • Labuan Bajo, NTT',
      'type': 'Goa Karst',
      'coordinates': '8°26\'30.8"S 119°55\'24.2"E',
      'elevation': 'Kolam Asin Alami',
      'imageUrl':
          'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300',
      'status': 'not_downloaded',
    },
  ];

  List<Map<String, dynamic>> _filteredMaps = [];

  @override
  void initState() {
    super.initState();
    _filterMaps();

    for (var map in _allMaps) {
      if (map['status'] == 'downloading') {
        _lanjutkanUnduhan(map);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var timer in _activeDownloadTimers.values) {
      timer.cancel();
    }
    _activeDownloadTimers.clear();
    super.dispose();
  }

  void _filterMaps() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.contains('goa') || query.contains('karst')) {
      _selectedFilterIndex = 2;
    } else if (query.contains('tebing') || query.contains('panjat')) {
      _selectedFilterIndex = 1;
    }

    final selectedCat = _mapFilterCategories[_selectedFilterIndex]['name'] as String;

    final cleanQuery = query
        .replaceAll('goa karst', '')
        .replaceAll('goa', '')
        .replaceAll('karst', '')
        .replaceAll('tebing panjat', '')
        .replaceAll('tebing', '')
        .trim();

    setState(() {
      _filteredMaps = _allMaps.where((map) {
        bool matchesCategory = true;
        if (selectedCat == 'Tebing Panjat') {
          matchesCategory = map['type'] == 'Tebing Panjat';
        } else if (selectedCat == 'Goa Karst') {
          matchesCategory = map['type'] == 'Goa Karst';
        } else if (selectedCat == 'Terunduh') {
          matchesCategory = map['status'] == 'completed';
        }

        if (cleanQuery.isEmpty) {
          return matchesCategory &&
              (map['status'] == 'completed' || map['status'] == 'downloading');
        }

        final title = map['title'].toString().toLowerCase();
        final subtitle = map['subtitle'].toString().toLowerCase();
        final coordinates = (map['coordinates'] ?? '').toString().toLowerCase();

        return matchesCategory &&
            (title.contains(cleanQuery) ||
                subtitle.contains(cleanQuery) ||
                coordinates.contains(cleanQuery));
      }).toList();
    });
  }

  void _mulaiUnduhPeta(Map<String, dynamic> map) {
    setState(() {
      map['status'] = 'downloading';
      map['progress'] = 0.0;
      map['percentage'] = '0%';
      final baseSize = map['subtitle'].toString().split('•')[0].trim();
      map['subtitle'] = '$baseSize • Mengunduh...';
    });

    _jalankanLoopTimer(map);
  }

  void _lanjutkanUnduhan(Map<String, dynamic> map) {
    _jalankanLoopTimer(map);
  }

  void _jalankanLoopTimer(Map<String, dynamic> map) {
    final String mapId = map['id'];
    _activeDownloadTimers[mapId]?.cancel();

    _activeDownloadTimers[mapId] = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          double currentProg = (map['progress'] ?? 0.0) as double;
          currentProg += 0.03;

          if (currentProg >= 1.0) {
            timer.cancel();
            _activeDownloadTimers.remove(mapId);

            map['status'] = 'completed';
            map['progress'] = 1.0;
            map['percentage'] = '100%';
            final baseSize = map['subtitle'].toString().split('•')[0].trim();
            map['subtitle'] = '$baseSize • Siap Offline';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Peta ${map['title']} siap digunakan! Ketuk untuk buka peta.',
                ),
                backgroundColor: const Color(0xFF2E7D32),
                duration: const Duration(seconds: 2),
              ),
            );

            _filterMaps();
          } else {
            map['progress'] = currentProg;
            map['percentage'] = '${(currentProg * 100).toInt()}%';
          }
        });
      },
    );
  }

  void _hentikanUnduhan(Map<String, dynamic> map) {
    final String mapId = map['id'];

    _activeDownloadTimers[mapId]?.cancel();
    _activeDownloadTimers.remove(mapId);

    setState(() {
      map['status'] = 'not_downloaded';
      map['progress'] = 0.0;
      map['percentage'] = '0%';

      final baseSize = map['subtitle'].toString().split('•')[0].trim();
      map['subtitle'] = '$baseSize • Dibatalkan';

      _filterMaps();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unduhan ${map['title']} dibatalkan.'),
        backgroundColor: const Color(0xFFC62828),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _navigateToPetaViewer(Map<String, dynamic> map) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetaViewerPage(
          areaName: map['title'],
          coordinates: map['coordinates'],
          region: map['subtitle'],
          elevation: map['elevation'],
          type: map['type'],
        ),
      ),
    );
  }

  void _navigateToPetaInteraktifLive(Map<String, dynamic> map) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetaInteraktifPage(
          initialSpotName: map['title'],
          initialCoordinates: map['coordinates'],
          autoStartNavigation: true,
        ),
      ),
    );
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
            tooltip: isDark ? 'Beralih ke Mode Terang' : 'Beralih ke Mode Gelap',
            onPressed: () => ThemeController.instance.toggleTheme(context),
          ),
          IconButton(
            icon: Icon(
              Icons.travel_explore_rounded,
              color: context.themePrimary,
              size: 24,
            ),
            tooltip: 'Buka Peta Interaktif (OpenStreetMap)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PetaInteraktifPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Peta Offline',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.themeText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Kelola peta tebing & goa yang diunduh untuk navigasi tanpa koneksi internet.',
              style: TextStyle(
                fontSize: 13,
                color: context.themeTextSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),

            // 1. Search Bar Interaktif
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.themeBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: context.themeTextSecondary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: context.themeText, fontSize: 14),
                      onChanged: (value) => _filterMaps(),
                      decoration: InputDecoration(
                        hintText: 'Cari tebing, goa, atau koordinat...',
                        hintStyle: TextStyle(
                          color: context.themeTextSecondary.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 18,
                                  color: context.themeTextSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterMaps();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Filter Chips Berwarna
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _mapFilterCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _mapFilterCategories[index];
                  final String label = cat['label'] as String;
                  final IconData icon = cat['icon'] as IconData;
                  final List<Color> gradient = cat['gradient'] as List<Color>;
                  final Color accentColor = cat['accentColor'] as Color;
                  final Color unselectedBg = cat['unselectedBg'] as Color;
                  final Color unselectedIcon = cat['unselectedIcon'] as Color;
                  final bool isSelected = _selectedFilterIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                      _filterMaps();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : (isDark
                                ? context.themeSurface
                                : unselectedBg.withValues(alpha: 0.85)),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.7)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : unselectedIcon.withValues(alpha: 0.3)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: gradient.last.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : (isDark
                                      ? unselectedIcon.withValues(alpha: 0.25)
                                      : Colors.white),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? accentColor : unselectedIcon),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? context.themeText : const Color(0xFF1E293B)),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 3. Header Peta Terunduh / Hasil Pencarian
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchController.text.isEmpty
                      ? 'PETA TERUNDUH'
                      : 'HASIL PENCARIAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.themePrimaryFixed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_filteredMaps.length} Area',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.themePrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Daftar Kartu Peta
            if (_filteredMaps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.themeCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: context.themeTextSecondary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _searchController.text.isEmpty
                          ? 'Belum ada peta terunduh di kategori ini'
                          : 'Area "${_searchController.text}" tidak ditemukan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.themeText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredMaps.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final map = _filteredMaps[index];
                  final status = map['status'];

                  if (status == 'completed') {
                    return _buildDownloadedMapItem(map: map);
                  } else if (status == 'downloading') {
                    return _buildDownloadingMapItem(map: map);
                  } else {
                    return _buildNotDownloadedMapItem(map: map);
                  }
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget Item Peta Selesai Diunduh
  Widget _buildDownloadedMapItem({required Map<String, dynamic> map}) {
    final bool isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
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
                child: Image.network(
                  map['imageUrl'],
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 54,
                    height: 54,
                    color: context.themeSurface,
                    child: Icon(Icons.terrain_rounded, color: context.themeTextSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      map['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      map['subtitle'],
                      style: TextStyle(
                        fontSize: 11,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    if (map['coordinates'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        map['coordinates'],
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: context.themeGold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.themePrimaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: context.themePrimary,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tombol Aksi: Buka Offline & Navigasi Live
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToPetaViewer(map),
                    icon: Icon(Icons.map_outlined, size: 15, color: context.themePrimary),
                    label: Text(
                      'Buka Offline',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: context.themePrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.themePrimary, width: 1.1),
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
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToPetaInteraktifLive(map),
                    icon: Icon(
                      Icons.near_me_rounded,
                      size: 15,
                      color: isDark ? const Color(0xFF0F1713) : Colors.white,
                    ),
                    label: Text(
                      'Navigasi Live',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF0F1713) : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.themePrimary,
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
    );
  }

  // Widget Item Peta Sedang Mengunduh
  Widget _buildDownloadingMapItem({required Map<String, dynamic> map}) {
    final bool isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
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
                child: Image.network(
                  map['imageUrl'],
                  width: 54,
                  height: 54,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 54,
                    height: 54,
                    color: context.themeSurface,
                    child: Icon(Icons.terrain_rounded, color: context.themeTextSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      map['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      map['subtitle'],
                      style: TextStyle(
                        fontSize: 11,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _hentikanUnduhan(map),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: context.themeText,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (map['progress'] ?? 0.0) as double,
                    backgroundColor: context.themeSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      context.themePrimary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                map['percentage'] ?? '0%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.themePrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Item Peta Belum Diunduh
  Widget _buildNotDownloadedMapItem({required Map<String, dynamic> map}) {
    final bool isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              map['imageUrl'],
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 54,
                height: 54,
                color: context.themeSurface,
                child: Icon(Icons.terrain_rounded, color: context.themeTextSecondary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  map['title'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  map['subtitle'],
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _mulaiUnduhPeta(map),
            icon: Icon(
              Icons.download_rounded,
              size: 14,
              color: isDark ? const Color(0xFF0F1713) : Colors.white,
            ),
            label: Text(
              'Unduh',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF0F1713) : Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
