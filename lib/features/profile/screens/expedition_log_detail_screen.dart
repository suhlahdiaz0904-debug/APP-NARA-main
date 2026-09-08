import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/profile/screens/expedition_history_screen.dart';
import 'package:flutter_application_1/features/profile/models/expedition_log_model.dart';

// =========================================================================
// HALAMAN DETAIL LOG EKSPEDISI (DARK & LIGHT EARTH TONE)
// Layar: Detail Log Ekspedisi (ID)
// =========================================================================

class DetailLogEkspedisiPage extends StatelessWidget {
  final ExpeditionLog log;
  final bool isNewlyCompleted;

  const DetailLogEkspedisiPage({
    super.key,
    required this.log,
    this.isNewlyCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. TopAppBar Glassmorphism
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: context.themePrimary),
                  onPressed: () {
                    if (isNewlyCompleted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const RiwayatLogPage()),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                title: Text(
                  'Detail Ekspedisi',
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
                    icon: Icon(Icons.share_rounded, color: context.themePrimary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Membagikan catatan log "${log.spotName}"...'),
                          backgroundColor: context.themePrimary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
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

              // 2. Konten Utama
              SliverList(
                delegate: SliverChildListDelegate([
                  // Hero Section
                  _buildHeroSection(context),

                  // Container Konten
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Row (Duration, Distance, Elevation)
                        _buildStatsRow(context),
                        const SizedBox(height: 24),

                        // Track Overview (Topographical Map Snippet)
                        _buildTrackOverviewSection(context),
                        const SizedBox(height: 28),

                        // Expedition Notes Timeline
                        _buildExpeditionNotesTimeline(context),
                        const SizedBox(height: 100), // Padding untuk bottom bar
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),

          // 3. Bottom Contextual Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  decoration: BoxDecoration(
                    color: context.themeBg.withValues(alpha: 0.9),
                    border: Border(
                      top: BorderSide(color: context.themeBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tautan log ${log.spotName} disalin ke papan klip!'),
                                backgroundColor: context.themePrimary,
                              ),
                            );
                          },
                          icon: Icon(Icons.share_rounded, size: 18, color: context.themePrimary),
                          label: Text(
                            'Bagikan Log',
                            style: TextStyle(fontWeight: FontWeight.bold, color: context.themePrimary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: context.themePrimary, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const RiwayatLogPage()),
                            );
                          },
                          icon: Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFF0F1713) : Colors.white,
                          ),
                          label: Text(
                            'Riwayat Semua',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF0F1713) : Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.themePrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
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

  // Hero Section
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.themeSurface,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            log.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: context.themeSurface,
                child: Center(
                  child: Icon(Icons.terrain_rounded, size: 64, color: context.themePrimary),
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
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        log.spotType.toLowerCase().contains('goa') || log.spotType.toLowerCase().contains('caving')
                            ? Icons.landscape_rounded
                            : Icons.terrain_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        log.spotType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  log.spotName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      log.region,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
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

  // Stats Row Bento (Duration, Distance, Elevation)
  Widget _buildStatsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.themeBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Duration
          Expanded(
            child: Column(
              children: [
                Icon(Icons.timer_outlined, color: context.themePrimary, size: 20),
                const SizedBox(height: 6),
                Text(
                  'DURATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.duration,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.themePrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 36, width: 1, color: context.themeBorder),

          // Distance
          Expanded(
            child: Column(
              children: [
                Icon(Icons.route_outlined, color: context.themePrimary, size: 20),
                const SizedBox(height: 6),
                Text(
                  'DISTANCE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.distanceKm} km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.themePrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 36, width: 1, color: context.themeBorder),

          // Elevation
          Expanded(
            child: Column(
              children: [
                Icon(Icons.height_rounded, color: context.themePrimary, size: 20),
                const SizedBox(height: 6),
                Text(
                  'ELEVATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.elevation,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.themePrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Track Overview Map Snippet
  Widget _buildTrackOverviewSection(BuildContext context) {
    final mapUrl = log.trackMapUrl ??
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAnEHDBE6DIZfq8Nw0PVwRD-Kx6mLOb_9XA830LBcsK5SX998okFtMAsH-IvCY70At9Q_dYSXsX2abEuS1AgEl4UUq302VtIh5P4wradYGkbMwio7dL5cIOVGmJr8ROjABfDA7OC0AnCorbpJJqRJ3jG3psu0OoCBwOccK36ph8ipuNM379zmmWp1p3_Oj0bDTMgxWm11MMeLV2GzoaqO5Rg8xQMhW0pWkbQhz4qfcQ1sz0bahfr3iw';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Track Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.themeText,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.themeBorder),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  mapUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: context.themeSurface,
                      child: Center(
                        child: Icon(Icons.map_outlined, size: 48, color: context.themePrimary),
                      ),
                    );
                  },
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.themeCard.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(Icons.zoom_in_map_rounded, size: 18, color: context.themePrimary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Expedition Notes Timeline
  Widget _buildExpeditionNotesTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expedition Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.themeText,
          ),
        ),
        const SizedBox(height: 16),
        ...log.notes.asMap().entries.map((entry) {
          final idx = entry.key;
          final note = entry.value;
          final isLast = idx == log.notes.length - 1;

          IconData noteIcon = Icons.flag_rounded;
          if (note.iconType == 'hardware') noteIcon = Icons.handyman_rounded;
          if (note.iconType == 'photo_camera') noteIcon = Icons.photo_camera_rounded;
          if (note.iconType == 'check') noteIcon = Icons.check_circle_rounded;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Connector
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.themeCard,
                        border: Border.all(color: context.themePrimary, width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.themePrimary,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: context.themePrimary.withValues(alpha: 0.25),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // Note Bento Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.themeCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.themeBorder, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: context.isDarkMode
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: context.themePrimaryFixed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  note.time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: context.themePrimary,
                                  ),
                                ),
                              ),
                              Icon(
                                noteIcon,
                                size: 16,
                                color: note.iconType == 'hardware'
                                    ? context.themeTerracotta
                                    : context.themeTextSecondary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            note.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: context.themeText,
                            ),
                          ),
                          if (note.subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              note.subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.themeTextSecondary,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (note.photos.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: note.photos.map((photoUrl) {
                                return Expanded(
                                  child: Container(
                                    height: 90,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(photoUrl, fit: BoxFit.cover),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
