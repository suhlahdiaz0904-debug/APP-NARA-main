import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/gear/screens/gear_manager_screen.dart';
import 'package:flutter_application_1/features/gear/screens/maintenance_guide_screen.dart';
import 'package:flutter_application_1/features/gear/screens/clothing_recommendation_screen.dart';

class PeriksaGearPage extends StatefulWidget {
  final bool showAppBar;
  final bool showBackButton;

  const PeriksaGearPage({
    super.key,
    this.showAppBar = true,
    this.showBackButton = true,
  });

  @override
  State<PeriksaGearPage> createState() => _PeriksaGearPageState();
}

class _PeriksaGearPageState extends State<PeriksaGearPage> {
  static const Color darkGreen = Color(0xFF1E382B); // Deep Forest Moss
  static const Color alertRed = Color(0xFFD94A3D); // Warm Burnt Crimson
  static const Color readyGreen = Color(0xFF386641); // Forest Moss Green

  late GearManager _gearManager;
  String _selectedGearFilter = 'Semua';

  final List<Map<String, dynamic>> _gearFilterCategories = [
    {
      'name': 'Semua',
      'label': 'Semua Gear',
      'icon': Icons.auto_awesome_rounded,
      'gradient': [Color(0xFF143023), Color(0xFF2E7D32)],
      'accentColor': Color(0xFF4CAF78),
      'unselectedBg': Color(0xFFE8F5E9),
      'unselectedIcon': Color(0xFF2E7D32),
    },
    {
      'name': 'Tebing',
      'label': 'Panjat Tebing',
      'icon': Icons.terrain_rounded,
      'gradient': [Color(0xFFD84315), Color(0xFFFF6E40)],
      'accentColor': Color(0xFFFFAB91),
      'unselectedBg': Color(0xFFFBE9E7),
      'unselectedIcon': Color(0xFFD84315),
    },
    {
      'name': 'Goa',
      'label': 'Susur Goa',
      'icon': Icons.dark_mode_rounded,
      'gradient': [Color(0xFF4527A0), Color(0xFF7C4DFF)],
      'accentColor': Color(0xFFB388FF),
      'unselectedBg': Color(0xFFEDE7F6),
      'unselectedIcon': Color(0xFF512DA8),
    },
    {
      'name': 'Perawatan',
      'label': 'Panduan Perawatan',
      'icon': Icons.menu_book_rounded,
      'gradient': [Color(0xFF00695C), Color(0xFF00BFA5)],
      'accentColor': Color(0xFFA7FFEB),
      'unselectedBg': Color(0xFFE0F2F1),
      'unselectedIcon': Color(0xFF00796B),
    },
    {
      'name': 'Pakaian',
      'label': 'Rekomendasi Pakaian',
      'icon': Icons.checkroom_rounded,
      'gradient': [Color(0xFF0277BD), Color(0xFF00B0FF)],
      'accentColor': Color(0xFF80D8FF),
      'unselectedBg': Color(0xFFE1F5FE),
      'unselectedIcon': Color(0xFF0288D1),
    },
  ];

  List<GearCategory> get _filteredCategories {
    if (_selectedGearFilter == 'Semua' ||
        _selectedGearFilter == 'Perawatan' ||
        _selectedGearFilter == 'Pakaian') {
      return _gearManager.categories;
    }
    if (_selectedGearFilter == 'Tebing') {
      return _gearManager.categories.where((cat) {
        final title = cat.title.toLowerCase();
        return title.contains('tebing') ||
            title.contains('panjat') ||
            title.contains('climb') ||
            title.contains('umum') ||
            title.contains('dasar');
      }).toList();
    }
    if (_selectedGearFilter == 'Goa') {
      return _gearManager.categories.where((cat) {
        final title = cat.title.toLowerCase();
        return title.contains('goa') ||
            title.contains('caving') ||
            title.contains('karst') ||
            title.contains('umum') ||
            title.contains('dasar');
      }).toList();
    }
    return _gearManager.categories;
  }

  @override
  void initState() {
    super.initState();
    _gearManager = GearManager.instance;
    _gearManager.addListener(_onGearDataChanged);
  }

  @override
  void dispose() {
    _gearManager.removeListener(_onGearDataChanged);
    super.dispose();
  }

  void _onGearDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ================= LOGIKA VALIDASI REAL-TIME =================

  Map<String, dynamic> _getRealtimeWeather() {
    final int hour = DateTime.now().hour;
    if (hour >= 6 && hour <= 10) {
      return {
        'temp': '24°C',
        'condition': 'Sejuk',
        'desc': 'Sejuk Berawan',
        'sub': 'Udara pagi lembap, angin sedang',
        'icon': Icons.wb_cloudy_outlined,
        'humidity': '78%',
        'wind': '12 km/jam',
        'uvIndex': 'Rendah (UV 2)',
        'advice':
            'Gunakan pakaian berbahan breathable dan jaket windbreaker tipis.',
      };
    } else if (hour >= 11 && hour <= 15) {
      return {
        'temp': '30°C',
        'condition': 'Cerah',
        'desc': 'Cerah & Terik',
        'sub': 'Radiasi matahari langsung & suhu tinggi',
        'icon': Icons.wb_sunny_rounded,
        'humidity': '60%',
        'wind': '15 km/jam',
        'uvIndex': 'Tinggi (UV 8)',
        'advice':
            'Prioritaskan pakaian pelindung UV, lengan panjang quick-dry, dan hidrasi teratur.',
      };
    } else if (hour >= 16 && hour <= 18) {
      return {
        'temp': '26°C',
        'condition': 'Berawan',
        'desc': 'Senja Berangin',
        'sub': 'Suhu mulai menurun, potensi kabut tebing',
        'icon': Icons.cloud_queue_rounded,
        'humidity': '82%',
        'wind': '18 km/jam',
        'uvIndex': 'Sedang (UV 3)',
        'advice':
            'Gunakan jaket penahan angin (windbreaker) untuk mengantisipasi angin lembah.',
      };
    } else {
      return {
        'temp': '22°C',
        'condition': 'Malam',
        'desc': 'Malam Dingin',
        'sub': 'Suhu rendah dengan kelembapan tinggi',
        'icon': Icons.nights_stay_rounded,
        'humidity': '88%',
        'wind': '10 km/jam',
        'uvIndex': 'Nol (UV 0)',
        'advice':
            'Wajib kenakan pakaian lapis hangat (thermal base-layer) atau jaket insulasi.',
      };
    }
  }

  void _toggleGearStatus(GearItem item) {
    _gearManager.toggleItemStatus(item.id);

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isReady
              ? '${item.title} ditandai Siap!'
              : '${item.title} perlu diperiksa kembali.',
        ),
        backgroundColor: item.isReady ? readyGreen : alertRed,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _navigateToCareGuide([String? gearId]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PanduanPerawatanPage(initialGearId: gearId),
      ),
    );
  }

  void _showTambahAlatDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    String selectedCategory = _gearManager.categories.first.title;
    bool initialReadyStatus = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tambah Alat Baru',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Alat / Gear',
                      hintText: 'Contoh: Descender Petzl Simple',
                      filled: true,
                      fillColor: const Color(0xFFF5F2EC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: 'Keterangan / Catatan',
                      hintText: 'Contoh: Siap digunakan di goa vertikal',
                      filled: true,
                      fillColor: const Color(0xFFF5F2EC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori Perlengkapan',
                      filled: true,
                      fillColor: const Color(0xFFF5F2EC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _gearManager.categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat.title,
                        child: Text(cat.title),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Tandai Langsung Siap Digunakan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: initialReadyStatus,
                    activeThumbColor: darkGreen,
                    onChanged: (val) {
                      setModalState(() => initialReadyStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isNotEmpty) {
                          _gearManager.addNewGear(
                            categoryId: selectedCategory,
                            title: nameController.text.trim(),
                            subtitle: noteController.text.trim(),
                            isReady: initialReadyStatus,
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Alat "${nameController.text.trim()}" berhasil ditambahkan dan panduan perawatan otomatis disinkronkan!',
                              ),
                              backgroundColor: readyGreen,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Simpan Alat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final realtimeWeather = _getRealtimeWeather();
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Glassmorphism AppBar (Blur saat scroll)
          if (widget.showAppBar)
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              leading: widget.showBackButton
                  ? IconButton(
                      icon: Icon(Icons.arrow_back, color: context.themePrimary),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    )
                  : null,
              title: Text(
                'NARA',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.isDarkMode ? AppTheme.darkPrimary : const Color(0xFF143023),
                ),
              ),
              centerTitle: true,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color: context.themeBg.withValues(alpha: 0.75),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_outlined,
                    color: isDark
                        ? AppTheme.goldAccentDark
                        : context.themePrimary,
                    size: 22,
                  ),
                  tooltip: isDark
                      ? 'Beralih ke Mode Terang'
                      : 'Beralih ke Mode Gelap',
                  onPressed: () =>
                      ThemeController.instance.toggleTheme(context),
                ),
                IconButton(
                  tooltip: 'Panduan Perawatan',
                  icon: Icon(
                    Icons.menu_book_rounded,
                    color: context.themePrimary,
                  ),
                  onPressed: () => _navigateToCareGuide(),
                ),
                const SizedBox(width: 8),
              ],
            ),

          // Konten Utama
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Periksa Gear Kamu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Verifikasi kelayakan alat ekspedisi goa dan panjat tebing secara berkala.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.themeTextSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Kategori Berwarna
                _buildGearFilterChips(),
                const SizedBox(height: 18),

                // 1. Status Pill Dinamis (X / Y Siap)
                _buildStatusSummaryCard(),
                const SizedBox(height: 16),

                // 2. Banner Baru: Panduan Perawatan Alat (Goa & Tebing)
                _buildCareGuideBannerCard(),
                const SizedBox(height: 16),

                // 3. Rekomendasi Pakaian dengan Cuaca Real-Time
                _buildClothingRecommendationCard(realtimeWeather),
                const SizedBox(height: 20),

                // 4. Kategori Gear & List Item Kebutuhan Goa & Tebing
                ..._filteredCategories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: _buildCategorySection(
                      icon: cat.icon,
                      title: cat.title,
                      itemCount: '${cat.items.length} Item',
                      items: cat.items.map<Widget>((item) {
                        return _buildGearItem(
                          item: item,
                          onActionTap: () => _toggleGearStatus(item),
                          onCareTap: () => _navigateToCareGuide(item.id),
                        );
                      }).toList(),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                // 5. Tombol Outlined Tambah Alat Baru
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _showTambahAlatDialog,
                    icon: Icon(
                      Icons.add,
                      color: context.themePrimary,
                      size: 20,
                    ),
                    label: Text(
                      'Tambah Alat Baru',
                      style: TextStyle(
                        color: context.themePrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.themeBorder, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 110),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGearFilterChips() {
    final bool isDark = context.isDarkMode;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _gearFilterCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _gearFilterCategories[index];
          final String name = cat['name'] as String;
          final String label = cat['label'] as String;
          final IconData icon = cat['icon'] as IconData;
          final List<Color> gradient = cat['gradient'] as List<Color>;
          final Color accentColor = cat['accentColor'] as Color;
          final Color unselectedBg = cat['unselectedBg'] as Color;
          final Color unselectedIcon = cat['unselectedIcon'] as Color;
          final bool isSelected = _selectedGearFilter == name;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedGearFilter = name;
              });
              if (name == 'Perawatan') {
                _navigateToCareGuide();
              } else if (name == 'Pakaian') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RekomendasiPakaianPage(),
                  ),
                );
              }
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
    );
  }

  // Card Ringkasan Status
  Widget _buildStatusSummaryCard() {
    final readyCount = _gearManager.readyGearCount;
    final totalCount = _gearManager.totalGearCount;
    final isAllReady = _gearManager.isAllGearReady;
    final bool isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isAllReady
                  ? context.themePrimary
                  : context.themeTerracotta,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAllReady
                      ? Icons.verified_rounded
                      : Icons.check_circle_rounded,
                  color: isDark ? const Color(0xFF0F1713) : Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '$readyCount/$totalCount\nSiap',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF0F1713) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAllReady
                      ? 'Semua Perlengkapan Siap!'
                      : '${totalCount - readyCount} alat belum siap',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isAllReady
                        ? context.themePrimary
                        : AppTheme.errorRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tekan tombol periksa untuk memverifikasi',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Banner Panduan Perawatan Alat Terintegrasi
  Widget _buildCareGuideBannerCard() {
    final bool isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themePrimary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: context.themePrimary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: isDark ? const Color(0xFF0F1713) : Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panduan Perawatan Alat',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF0F1713) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Prosedur cuci, pengeringan, & kriteria pensiun alat goa & tebing.',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF0F1713).withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _navigateToCareGuide(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF0F1713) : Colors.white,
              foregroundColor: isDark ? Colors.white : context.themePrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(60, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Buka',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Card Rekomendasi Pakaian dengan Data Real-Time
  Widget _buildClothingRecommendationCard(Map<String, dynamic> weather) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    color: context.themePrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rekomendasi\nPakaian',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      weather['icon'] as IconData,
                      size: 16,
                      color: context.themePrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${weather['temp']},\n${weather['condition']}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildClothingPill('Jaket Windbreaker'),
          const SizedBox(height: 8),
          _buildClothingPill('Celana Kargo'),
          const SizedBox(height: 8),
          _buildClothingPill('Sepatu Trekking'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RekomendasiPakaianPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.themePrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Lihat Detail',
                style: TextStyle(
                  color: context.isDarkMode
                      ? const Color(0xFF0F1713)
                      : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClothingPill(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: context.themePrimary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.themeText,
            ),
          ),
        ],
      ),
    );
  }

  // Section Kategori Gear
  Widget _buildCategorySection({
    required IconData icon,
    required String title,
    required String itemCount,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: context.themePrimary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                  ],
                ),
                Text(
                  itemCount,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  // Item List Gear dengan Akses Cepat ke Panduan Perawatan
  Widget _buildGearItem({
    required GearItem item,
    required VoidCallback onActionTap,
    required VoidCallback onCareTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.themeCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              color: item.isReady ? context.themePrimary : context.themeText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onCareTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: item.isReady
                          ? context.themeTextSecondary
                          : AppTheme.errorRed,
                      fontWeight: item.isReady
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tombol Info Panduan Perawatan
          IconButton(
            tooltip: 'Panduan Perawatan',
            icon: Icon(
              Icons.menu_book_outlined,
              size: 18,
              color: context.themePrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onCareTap,
          ),
          const SizedBox(width: 4),
          if (item.isReady)
            GestureDetector(
              onTap: onActionTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.themePrimaryFixed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: context.themePrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Siap',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.themePrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: onActionTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.themePrimary,
                foregroundColor: context.isDarkMode
                    ? const Color(0xFF0F1713)
                    : Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: const Size(60, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Periksa',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
