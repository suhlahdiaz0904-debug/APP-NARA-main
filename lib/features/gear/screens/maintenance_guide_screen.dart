import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/gear/screens/gear_manager_screen.dart';

// =========================================================================
// HALAMAN PANDUAN PERAWATAN ALAT (GOA & TEBING) - NARA OUTDOOR
// Desain Terintegrasi Stitch Design System (Screen: Panduan Perawatan ID)
// =========================================================================

class PanduanPerawatanPage extends StatefulWidget {
  final String? initialGearId;

  const PanduanPerawatanPage({super.key, this.initialGearId});

  @override
  State<PanduanPerawatanPage> createState() => _PanduanPerawatanPageState();
}

class _PanduanPerawatanPageState extends State<PanduanPerawatanPage> {
  // Palet Warna Sesuai Design System NARA Earth Tone
  static const Color darkGreen = Color(0xFF1E382B); // Deep Forest Moss
  static const Color primaryFixed = Color(0xFFCFE3D5); // Soft Sage Meadow
  static const Color bgCream = Color(0xFFF6F3EC); // Sandstone Linen
  static const Color terracottaSoft = Color(
    0xFFE28C72,
  ); // Warm Desert Terracotta
  static const Color roseAccent = Color(0xFFB8786B); // Dusty Clay Rose
  static const Color readyGreen = Color(0xFF386641); // Forest Moss Green
  static const Color errorRed = Color(0xFFD94A3D); // Warm Burnt Crimson
  static const Color textMuted = Color(0xFF7A7065); // Warm Driftwood Stone

  late GearManager _gearManager;
  GearItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    _gearManager = GearManager.instance;
    _gearManager.addListener(_onGearManagerUpdated);

    // Set item awal berdasarkan parameter atau item pertama yang tersedia
    if (widget.initialGearId != null) {
      _selectedItem = _gearManager.findItemById(widget.initialGearId!);
    }
    if (_selectedItem == null && _gearManager.categories.isNotEmpty) {
      for (var cat in _gearManager.categories) {
        if (cat.items.isNotEmpty) {
          _selectedItem = cat.items.first;
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _gearManager.removeListener(_onGearManagerUpdated);
    super.dispose();
  }

  void _onGearManagerUpdated() {
    if (mounted) {
      setState(() {
        if (_selectedItem != null) {
          _selectedItem =
              _gearManager.findItemById(_selectedItem!.id) ?? _selectedItem;
        }
      });
    }
  }

  void _showGearSelectorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Alat / Gear',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih alat untuk melihat panduan perawatannya',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _gearManager.categories.length,
                    itemBuilder: (context, catIdx) {
                      final cat = _gearManager.categories[catIdx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(cat.icon, size: 16, color: darkGreen),
                                const SizedBox(width: 8),
                                Text(
                                  cat.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${cat.items.length} alat',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...cat.items.map((item) {
                            final isSelected = _selectedItem?.id == item.id;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryFixed.withValues(alpha: 0.35)
                                    : bgCream,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? darkGreen
                                      : Colors.transparent,
                                  width: 1.2,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 18,
                                    color: darkGreen,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: item.isReady ? readyGreen : errorRed,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: darkGreen,
                                        size: 20,
                                      )
                                    : const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.black38,
                                        size: 20,
                                      ),
                                onTap: () {
                                  setState(() {
                                    _selectedItem = item;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMaintenanceDialog() {
    if (_selectedItem == null) return;
    final noteController = TextEditingController(
      text:
          'Pembersihan lumpur selesai, pengeringan teduh, dan lolos uji taktil.',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryFixed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cleaning_services_rounded,
                  color: darkGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Catat Log Perawatan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Alat: ${_selectedItem!.title}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Catatan Perawatan / Hasil Inspeksi',
                  hintText: 'Tuliskan kondisi alat setelah dirawat...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDCD6CA)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _gearManager.recordMaintenance(
                  _selectedItem!.id,
                  note: noteController.text.trim().isEmpty
                      ? 'Pembersihan & inspeksi berkala selesai dilakukan.'
                      : noteController.text.trim(),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Perawatan ${_selectedItem!.title} berhasil dicatat & Siap Digunakan!',
                    ),
                    backgroundColor: readyGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Simpan & Tandai Siap',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    if (_selectedItem == null) {
      return Scaffold(
        backgroundColor: context.themeBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: context.themePrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Panduan Perawatan',
            style: TextStyle(
              color: context.themePrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Belum ada alat yang dipilih atau tersedia.',
            style: TextStyle(color: context.themeTextSecondary),
          ),
        ),
      );
    }

    final careGuide = _gearManager.getCareGuideForItem(_selectedItem!);

    return Scaffold(
      backgroundColor: context.themeBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Glassmorphism TopAppBar
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
              'Panduan Perawatan',
              style: TextStyle(
                color: context.themePrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: true,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: context.themeBg.withValues(alpha: 0.85),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                  color: isDark
                      ? AppTheme.goldAccentDark
                      : context.themePrimary,
                  size: 22,
                ),
                tooltip: isDark
                    ? 'Beralih ke Mode Terang'
                    : 'Beralih ke Mode Gelap',
                onPressed: () => ThemeController.instance.toggleTheme(context),
              ),
              IconButton(
                tooltip: 'Pilih Alat Lain',
                icon: Icon(
                  Icons.swap_horiz_rounded,
                  color: context.themePrimary,
                ),
                onPressed: _showGearSelectorSheet,
              ),
              const SizedBox(width: 6),
            ],
          ),

          // 2. Konten Utama
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Selector Bar
                _buildQuickGearSwitcher(),
                const SizedBox(height: 18),

                // Hero Section
                _buildHeroSection(careGuide),
                const SizedBox(height: 24),

                // Bento Grid Perawatan Harian
                _buildDailyCareSection(careGuide),
                const SizedBox(height: 24),

                // Storage Section (Penyimpanan Ideal)
                _buildStorageSection(careGuide),
                const SizedBox(height: 24),

                // Safety Inspection & Retirement Alert Box
                _buildSafetyInspectionSection(careGuide),
                const SizedBox(height: 24),

                // Log Perawatan & Action Box
                _buildMaintenanceActionBox(),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Bar Pemilih Alat Cepat di Bagian Atas
  Widget _buildQuickGearSwitcher() {
    return GestureDetector(
      onTap: _showGearSelectorSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _selectedItem!.icon,
                size: 18,
                color: context.themePrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peralatan yang Ditampilkan:',
                    style: TextStyle(
                      fontSize: 10,
                      color: context.themeTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _selectedItem!.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.themePrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ganti',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.isDarkMode
                          ? const Color(0xFF0F1713)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 14,
                    color: context.isDarkMode
                        ? const Color(0xFF0F1713)
                        : Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hero Section Sesuai Desain Stitch
  Widget _buildHeroSection(CareGuideModel guide) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              guide.heroImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: darkGreen,
                  child: const Center(
                    child: Icon(
                      Icons.terrain_rounded,
                      size: 64,
                      color: primaryFixed,
                    ),
                  ),
                );
              },
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _selectedItem!.title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    guide.heroTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    guide.heroSubtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bento Grid Perawatan Harian
  Widget _buildDailyCareSection(CareGuideModel guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.water_drop_rounded,
              size: 20,
              color: terracottaSoft,
            ),
            const SizedBox(width: 8),
            Text(
              'Perawatan Harian',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.themePrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Bento Cards
        Column(
          children: [
            _buildBentoCard(
              icon: Icons.cleaning_services_rounded,
              title: guide.cleaningTitle,
              desc: guide.cleaningDesc,
              accentColor: context.themePrimary,
              blurColor: context.themePrimaryFixed.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 12),
            _buildBentoCard(
              icon: Icons.air_rounded,
              title: guide.dryingTitle,
              desc: guide.dryingDesc,
              accentColor: context.themePrimary,
              blurColor: const Color(0xFFFDDD7C).withValues(alpha: 0.3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color accentColor,
    required Color blurColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blurColor,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.themeText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Storage Section (Penyimpanan Ideal)
  Widget _buildStorageSection(CareGuideModel guide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.backpack_rounded, size: 20, color: roseAccent),
              const SizedBox(width: 8),
              Text(
                'Penyimpanan Ideal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.themePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            guide.storageDesc,
            style: TextStyle(
              fontSize: 12,
              color: context.themeTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ...guide.storageRules.map((rule) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: context.themePrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rule,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeText,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // Storage Illustration Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: Image.network(
                guide.storageImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: context.themeSurface,
                    child: Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: context.themePrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Safety Inspection & Retirement Alert Box Sesuai Stitch
  Widget _buildSafetyInspectionSection(CareGuideModel guide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 20, color: errorRed),
            const SizedBox(width: 8),
            Text(
              'Inspeksi Keamanan & Kriteria Pensiun',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.themePrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: errorRed.withValues(alpha: context.isDarkMode ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: errorRed.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                guide.safetyDesc,
                style: TextStyle(
                  fontSize: 12,
                  color: context.themeText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // 2x2 Bento Cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                ),
                itemCount: guide.retirementCriteria.length,
                itemBuilder: (context, idx) {
                  final crit = guide.retirementCriteria[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.themeCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.themeBorder),
                      boxShadow: [
                        BoxShadow(
                          color: errorRed.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(crit.icon, size: 20, color: errorRed),
                        const SizedBox(height: 6),
                        Text(
                          crit.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.themeText,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Box Aksi & Status Perawatan Real-time
  Widget _buildMaintenanceActionBox() {
    final item = _selectedItem!;
    final lastDate = item.lastMaintenanceDate;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Kesiapan Alat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.themeText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: item.isReady
                      ? context.themePrimaryFixed
                      : errorRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.isReady
                          ? Icons.check_circle_rounded
                          : Icons.pending_rounded,
                      size: 14,
                      color: item.isReady ? context.themePrimary : errorRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.isReady ? 'Siap Digunakan' : 'Perlu Diperiksa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.isReady ? context.themePrimary : errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lastDate != null
                ? 'Terakhir dirawat: ${_gearManager.getCareGuideForItem(item).cleaningTitle} (${lastDate.day}/${lastDate.month}/${lastDate.year})\nCatatan: ${item.lastMaintenanceNote ?? item.subtitle}'
                : 'Belum ada riwayat catatan perawatan terdaftar untuk alat ini.',
            style: TextStyle(
              fontSize: 11,
              color: context.themeTextSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _gearManager.toggleItemStatus(item.id);
                  },
                  icon: Icon(
                    item.isReady ? Icons.refresh_rounded : Icons.check_rounded,
                    size: 16,
                    color: context.themePrimary,
                  ),
                  label: Text(
                    item.isReady ? 'Ubah Status' : 'Tandai Siap',
                    style: TextStyle(
                      color: context.themePrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.themePrimary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _showMaintenanceDialog,
                  icon: Icon(
                    Icons.cleaning_services_rounded,
                    size: 16,
                    color: context.isDarkMode
                        ? const Color(0xFF0F1713)
                        : Colors.white,
                  ),
                  label: Text(
                    'Catat Perawatan Selesai',
                    style: TextStyle(
                      color: context.isDarkMode
                          ? const Color(0xFF0F1713)
                          : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.themePrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
