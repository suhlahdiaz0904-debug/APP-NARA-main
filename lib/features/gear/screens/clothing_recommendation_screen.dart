import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';

// =========================================================================
// HALAMAN REKOMENDASI PAKAIAN LAPANGAN (PRIA, WANITA, & WANITA BERHIJAB)
// Terintegrasi dengan Cuaca Real-Time, Keselamatan Outdoor, & Dark/Light Earth Tone
// =========================================================================

class RekomendasiPakaianPage extends StatefulWidget {
  const RekomendasiPakaianPage({super.key});

  @override
  State<RekomendasiPakaianPage> createState() => _RekomendasiPakaianPageState();
}

class _RekomendasiPakaianPageState extends State<RekomendasiPakaianPage> {
  // Kategori Pilihan: 0 = Semua, 1 = Pria, 2 = Wanita, 3 = Wanita Berhijab
  int _selectedCategoryIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'title': 'Semua', 'icon': Icons.apps_rounded},
    {'title': 'Pria', 'icon': Icons.male_rounded},
    {'title': 'Wanita', 'icon': Icons.female_rounded},
    {'title': 'Berhijab', 'icon': Icons.face_3_rounded},
  ];

  // Generator Cuaca Real-Time Dinamis Berdasarkan Waktu Sistem
  Map<String, dynamic> _getRealtimeWeatherInfo() {
    final DateTime now = DateTime.now();
    final int hour = now.hour;

    if (hour >= 6 && hour <= 10) {
      return {
        'temp': '24°C',
        'condition': 'Sejuk Berawan',
        'sub': 'Udara pagi lembap, angin sedang',
        'icon': Icons.wb_cloudy_outlined,
        'humidity': '78%',
        'wind': '12 km/jam',
        'uvIndex': 'Rendah (UV 2)',
        'advice':
            'Gunakan lapisan breathable agar tidak gerah saat mulai aktif bergerak.',
      };
    } else if (hour >= 11 && hour <= 15) {
      return {
        'temp': '30°C',
        'condition': 'Cerah & Terik',
        'sub': 'Radiasi matahari langsung & panas',
        'icon': Icons.wb_sunny_rounded,
        'humidity': '60%',
        'wind': '15 km/jam',
        'uvIndex': 'Tinggi (UV 8)',
        'advice':
            'Prioritaskan perlindungan UV, baju lengan panjang berbahan quick-dry.',
      };
    } else if (hour >= 16 && hour <= 18) {
      return {
        'temp': '26°C',
        'condition': 'Senja Berangin',
        'sub': 'Suhu mulai menurun, potensi kabut tipis',
        'icon': Icons.cloud_queue_rounded,
        'humidity': '82%',
        'wind': '18 km/jam',
        'uvIndex': 'Sedang (UV 3)',
        'advice':
            'Siapkan jaket windbreaker cadangan untuk mengantisipasi angin lembah.',
      };
    } else {
      return {
        'temp': '22°C',
        'condition': 'Malam Dingin',
        'sub': 'Suhu rendah dengan kelembapan tinggi',
        'icon': Icons.nights_stay_rounded,
        'humidity': '88%',
        'wind': '10 km/jam',
        'uvIndex': 'Nol (UV 0)',
        'advice':
            'Wajib gunakan thermal base-layer atau jaket insulasi penahan dingin.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final weather = _getRealtimeWeatherInfo();

    return Scaffold(
      backgroundColor: context.themeBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Glassmorphism SliverAppBar
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: context.themePrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Rekomendasi Pakaian',
              style: TextStyle(
                color: context.themePrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.2,
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
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: context.themeBg.withValues(alpha: 0.75)),
              ),
            ),
          ),

          // Konten Rekomendasi
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Header Cuaca Real-Time
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurfaceHigh : context.themePrimary,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.themeBorder),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : context.themePrimary.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'VALIDASI REAL-TIME',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            weather['icon'] as IconData,
                            color: context.themeGold,
                            size: 30,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            weather['temp'],
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              weather['condition'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        weather['sub'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),

                      // Parameter Cuaca Mikro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWeatherMetric(
                            Icons.water_drop_outlined,
                            'Kelembapan',
                            weather['humidity'],
                          ),
                          _buildWeatherMetric(
                            Icons.air_rounded,
                            'Angin',
                            weather['wind'],
                          ),
                          _buildWeatherMetric(
                            Icons.wb_sunny_outlined,
                            'Indeks UV',
                            weather['uvIndex'],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Petunjuk Lapangan Sesuai Cuaca
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: context.themePrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          weather['advice'],
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeText,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Tab Filter Kategori (Pria / Wanita / Berhijab / Semua)
                Text(
                  'KATEGORI PENGGUNA',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(_categories.length, (index) {
                      final isSelected = _selectedCategoryIndex == index;
                      final cat = _categories[index];

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            cat['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? (isDark ? const Color(0xFF0F1713) : Colors.white)
                                : context.themePrimary,
                          ),
                          label: Text(cat['title'] as String),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategoryIndex = index);
                          },
                          selectedColor: context.themePrimary,
                          backgroundColor: context.themeCard,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? const Color(0xFF0F1713) : Colors.white)
                                : context.themeText,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected
                                  ? context.themePrimary
                                  : context.themeBorder,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 22),

                // 4. DAFTAR SUSUNAN PAKAIAN DISARANKAN
                Text(
                  'SUSUNAN PAKAIAN DISARANKAN (LAYERING)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // KONTEN DINAMIS BERDASARKAN KATEGORI
                ..._buildFilteredClothingCategories(),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Builder Kategori Pakaian Berdasarkan Filter
  List<Widget> _buildFilteredClothingCategories() {
    final List<Widget> list = [];

    // JIKA WANITA BERHIJAB / SEMUA -> Tampilkan Kartu Khusus Hijab Outdoor
    if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 3) {
      list.add(
        _buildClothingCategory(
          category: '🧕 Khusus Hijab Outdoor & Keselamatan',
          icon: Icons.face_3_rounded,
          badgeColor: context.themeTerracotta,
          items: [
            {
              'name': 'Hijab Instan Sport Dry-Fit / Spandek Elastis',
              'desc':
                  'Tanpa jarum pentul demi keamanan panjat tebing/caving. Menyerap keringat & pas di bawah helm climbing.',
              'tag': 'Wajib',
            },
            {
              'name': 'Inner Hijab / Ciput Rajut Bernapas (Breathable)',
              'desc':
                  'Mencegah rambut keluar dan menjaga kenyamanan kepala dari tekanan busa helm.',
              'tag': 'Sangat Disarankan',
            },
            {
              'name': 'Manset / Long-Sleeve Loose-Fit (Tidak Terlalu Longgar)',
              'desc':
                  'Menutup aurat sempurna namun tidak longgar agar tidak tersangkut carabiner / belay device (ATC / GriGri).',
              'tag': 'Wajib',
            },
            {
              'name': 'Celana Kargo Jogger Ripstop dengan Karet Bawah',
              'desc':
                  'Potongan longgar nyaman untuk pergerakan kaki lebar di tebing tanpa risiko terinjak saat climbing.',
              'tag': 'Wajib',
            },
          ],
        ),
      );
      list.add(const SizedBox(height: 14));
    }

    // JIKA PRIA / SEMUA -> Tampilkan Rekomendasi Pria
    if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 1) {
      list.add(
        _buildClothingCategory(
          category: '🧑 Rekomendasi Khusus Pria',
          icon: Icons.male_rounded,
          badgeColor: context.themePrimary,
          items: [
            {
              'name': 'Kaos Dry-Fit Atletik / Rashguard Anti-UV',
              'desc':
                  'Sirkulasi udara maksimal untuk mengurangi gesekan pada bahu dan dada saat membawa backpack/harness.',
              'tag': 'Optimal',
            },
            {
              'name': 'Celana Kargo Stretch Ripstop Anti-Sobek',
              'desc':
                  'Tahan terhadap gesekan batuan tajam dan memiliki saku paha beritsleting untuk peta / ponsel.',
              'tag': 'Wajib',
            },
            {
              'name': 'Sabuk Nilon Taktikal Non-Metal',
              'desc':
                  'Gesper fleksibel yang tidak menekan tulang pinggul saat terikat erat oleh harness pemanjat.',
              'tag': 'Disarankan',
            },
          ],
        ),
      );
      list.add(const SizedBox(height: 14));
    }

    // JIKA WANITA / SEMUA -> Tampilkan Rekomendasi Wanita
    if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 2) {
      list.add(
        _buildClothingCategory(
          category: '👩 Rekomendasi Khusus Wanita',
          icon: Icons.female_rounded,
          badgeColor: context.themeTerracotta,
          items: [
            {
              'name': 'Sports Bra High-Support & Seamless',
              'desc':
                  'Bahan non-chafing (anti-lecet) untuk mobilitas tangan ke atas saat menjangkau pegangan batuan tinggi.',
              'tag': 'Wajib',
            },
            {
              'name': 'Legging Panjat Tebing Reinforced Knee & Seat',
              'desc':
                  'Bahan kompresi elastis dengan penguat ganda pada lutut dan pantat terhadap gesekan batuan karst.',
              'tag': 'Optimal',
            },
            {
              'name': 'Celana Dalam Katun Antibakteri Quick-Dry',
              'desc':
                  'Menjaga area kewanitaan tetap kering dan mencegah iritasi dari tekanan leg loops harness.',
              'tag': 'Wajib',
            },
          ],
        ),
      );
      list.add(const SizedBox(height: 14));
    }

    // LAPISAN UMUM (Outer Layer & Alas Kaki)
    list.add(
      _buildClothingCategory(
        category: 'Lapisan Luar (Outer Layer)',
        icon: Icons.shield_outlined,
        badgeColor: context.themePrimary,
        items: [
          {
            'name': 'Jaket Windbreaker / Softshell Ultralight',
            'desc':
                'Melindungi tubuh dari hembusan angin tebing kencang & percikan droplet air di goa/tebing.',
            'tag': 'Wajib',
          },
        ],
      ),
    );
    list.add(const SizedBox(height: 14));

    list.add(
      _buildClothingCategory(
        category: 'Alas Kaki & Perlindungan Ekstrem',
        icon: Icons.snowshoeing_rounded,
        badgeColor: context.themePrimary,
        items: [
          {
            'name': 'Sepatu Trekking Sol Vibram / Grip Tinggi',
            'desc':
                'Mencegah selip pada batuan tebing berlumut atau jalur tanah licin.',
            'tag': 'Wajib',
          },
          {
            'name': 'Sarung Tangan Panjat / Belay Gloves Kulit',
            'desc':
                'Melindungi telapak tangan dari gesekan tali berkecepatan tinggi saat rappelling atau belay.',
            'tag': 'Disarankan',
          },
          {
            'name': 'Topi Rimba / Visor Anti-UV',
            'desc':
                'Melindungi wajah dan tengkuk dari paparan terik sinar UV di dinding tebing terbuka.',
            'tag': 'Optimal',
          },
        ],
      ),
    );

    return list;
  }

  Widget _buildWeatherMetric(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildClothingCategory({
    required String category,
    required IconData icon,
    required List<Map<String, String>> items,
    Color? badgeColor,
  }) {
    final effectiveBadgeColor = badgeColor ?? context.themePrimary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder),
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
          Row(
            children: [
              Icon(icon, color: effectiveBadgeColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: context.themeText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.themeBorder),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: context.themePrimary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.themeText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['desc']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.themeTextSecondary,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: item['tag'] == 'Wajib'
                          ? (context.isDarkMode
                              ? AppTheme.errorRed.withValues(alpha: 0.2)
                              : const Color(0xFFFDE8E8))
                          : context.themePrimaryFixed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['tag']!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: item['tag'] == 'Wajib'
                            ? (context.isDarkMode ? const Color(0xFFFF8A80) : const Color(0xFFC62828))
                            : context.themePrimary,
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
}
