import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/profile/screens/expedition_log_detail_screen.dart';
import 'package:flutter_application_1/core/database/database_helper.dart';
import 'package:flutter_application_1/features/profile/models/expedition_log_model.dart';

// =========================================================================
// HALAMAN DAFTAR RIWAYAT LOG EKSPEDISI PETUALANG NARA (DARK & LIGHT EARTH TONE)
// Menampilkan seluruh ekspedisi yang telah selesai & tersinkronisasi SQLite
// =========================================================================

class RiwayatLogPage extends StatefulWidget {
  final int? userId;
  const RiwayatLogPage({super.key, this.userId});

  @override
  State<RiwayatLogPage> createState() => _RiwayatLogPageState();
}

class _RiwayatLogPageState extends State<RiwayatLogPage> {
  List<ExpeditionLog> _logs = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Tebing', 'Goa'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final results = await DatabaseHelper.instance.getUserExpeditionLogs(widget.userId);
    if (mounted) {
      setState(() {
        _logs = results;
        _isLoading = false;
      });
    }
  }

  List<ExpeditionLog> get _filteredLogs {
    if (_selectedFilter == 'Semua') return _logs;
    return _logs.where((log) {
      if (_selectedFilter == 'Tebing') {
        return log.spotType.toLowerCase().contains('climb') || log.spotType.toLowerCase().contains('tebing');
      } else if (_selectedFilter == 'Goa') {
        return log.spotType.toLowerCase().contains('caving') || log.spotType.toLowerCase().contains('goa');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Top Glassmorphism AppBar
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
              'Riwayat Log Ekspedisi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.themePrimary,
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
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: context.themePrimary),
                tooltip: 'Muat Ulang',
                onPressed: _loadLogs,
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(color: context.themeBg.withValues(alpha: 0.85)),
              ),
            ),
          ),

          // 2. Filter & Header
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catatan Ekspedisi Anda',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.themeText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Riwayat penjelajahan tebing dan goa yang telah Anda selesaikan di lapangan.',
                    style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
                  ),
                  const SizedBox(height: 14),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(filter),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF0F1713) : context.themePrimary)
                                  : context.themeText,
                            ),
                            backgroundColor: context.themeCard,
                            selectedColor: isDark ? AppTheme.darkPrimary : context.themePrimaryFixed,
                            checkmarkColor: isDark ? const Color(0xFF0F1713) : context.themePrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected ? context.themePrimary : context.themeBorder,
                              ),
                            ),
                            onSelected: (val) {
                              setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 3. List Item Ekspedisi
          _isLoading
              ? SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: context.themePrimary)),
                )
              : _filteredLogs.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.terrain_rounded, size: 64, color: context.themeTextSecondary),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada log ekspedisi.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: context.themeText),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gunakan Peta Navigasi untuk mulai menjelajah!',
                              style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = _filteredLogs[index];
                            return _buildLogCard(context, item);
                          },
                          childCount: _filteredLogs.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, ExpeditionLog item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailLogEkspedisiPage(log: item),
          ),
        ).then((_) => _loadLogs());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.themeCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.themeBorder, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image & Category
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    item.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: context.themeSurface,
                        child: Icon(Icons.terrain_rounded, size: 48, color: context.themePrimary),
                      );
                    },
                  ),
                ),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.spotType.toLowerCase().contains('goa') || item.spotType.toLowerCase().contains('caving')
                              ? Icons.landscape_rounded
                              : Icons.terrain_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.spotType,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    item.spotName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),

            // Info Detail & Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: context.themeTextSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.region,
                          style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.themePrimaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Selesai',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.themePrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: context.themeBorder),
                  const SizedBox(height: 12),

                  // Mini Bento Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat(Icons.timer_outlined, 'Durasi', item.duration),
                      _buildMiniStat(Icons.route_outlined, 'Jarak', '${item.distanceKm} km'),
                      _buildMiniStat(Icons.height_rounded, 'Elevasi', item.elevation),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.themePrimary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9.5, color: context.themeTextSecondary)),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.themePrimary),
            ),
          ],
        ),
      ],
    );
  }
}
