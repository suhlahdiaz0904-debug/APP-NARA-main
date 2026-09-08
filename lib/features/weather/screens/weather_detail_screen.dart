import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/weather/screens/weather_screen.dart';

class CuacaDetailPage extends StatefulWidget {
  const CuacaDetailPage({super.key});

  @override
  State<CuacaDetailPage> createState() => _CuacaDetailPageState();
}

class _CuacaDetailPageState extends State<CuacaDetailPage> {
  late Future<WeatherModel> _weatherFuture;

  @override
  void initState() {
    super.initState();
    _weatherFuture = WeatherService.fetchRealtimeWeather();
  }

  void _refreshWeather() {
    setState(() {
      _weatherFuture = WeatherService.fetchRealtimeWeather();
    });
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
          'Cuaca Real-Time',
          style: TextStyle(
            color: context.themePrimary,
            fontWeight: FontWeight.w600,
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
            icon: Icon(Icons.refresh, color: context.themePrimary),
            tooltip: 'Segarkan Cuaca',
            onPressed: _refreshWeather,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FutureBuilder<WeatherModel>(
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
                    'Mendeteksi Koordinat GPS & Cuaca...',
                    style: TextStyle(color: context.themeTextSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 54,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.themeText,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshWeather,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themePrimary,
                        foregroundColor: isDark ? const Color(0xFF0F1713) : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final weather = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Kartu Utama Cuaca & Titik Koordinat GPS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: context.themeCard,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: context.themeBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: context.themePrimary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              weather.locationName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: context.themeText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (weather.village.isNotEmpty || weather.kabupaten.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: [
                            if (weather.village.isNotEmpty)
                              _buildLocationBadge('Kelurahan: ${weather.village}', context),
                            if (weather.kabupaten.isNotEmpty)
                              _buildLocationBadge('Kabupaten: ${weather.kabupaten}', context),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      // BADGE TITIK KOORDINAT GPS
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.themePrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'KOORDINAT: ${weather.latitude.toStringAsFixed(4)}, ${weather.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.themePrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 54,
                            color: AppTheme.goldAccentDark,
                          ),
                          const SizedBox(width: 14),
                          Text(
                            weather.currentTemp,
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.bold,
                              color: context.themePrimary,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        weather.condition,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.themeText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weather.highLow,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Grid 4 Kartu Parameter Cuaca Real-Time
                Row(
                  children: [
                    Expanded(
                      child: _buildParamCard(
                        icon: Icons.water_drop_outlined,
                        iconColor: AppTheme.terracottaSoft,
                        label: 'Kelembapan',
                        value: weather.humidity,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildParamCard(
                        icon: Icons.air_rounded,
                        iconColor: context.themePrimary,
                        label: 'Angin',
                        value: weather.wind,
                        context: context,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildParamCard(
                        icon: Icons.wb_sunny_outlined,
                        iconColor: AppTheme.goldAccentDark,
                        label: 'UV Index',
                        value: weather.uvIndex,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildParamCard(
                        icon: Icons.visibility_outlined,
                        iconColor: context.themeTextSecondary,
                        label: 'Jarak Pandang',
                        value: weather.visibility,
                        context: context,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // 3. Perkiraan Per Jam
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.themeCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.themeBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perkiraan Per Jam',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: context.themeText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: weather.hourly.map<Widget>((h) {
                            final bool isCurrent = h['isCurrent'] ?? false;
                            final String? rainProb = h['rainProb'];

                            return Container(
                              width: 76,
                              height: 140,
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? context.themePrimary.withValues(alpha: isDark ? 0.25 : 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(18),
                                border: isCurrent
                                    ? Border.all(
                                        color: context.themePrimary,
                                        width: 1.2,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    h['time'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? context.themePrimary
                                          : context.themeTextSecondary,
                                    ),
                                  ),
                                  Icon(
                                    h['icon'] as IconData,
                                    color: isCurrent
                                        ? AppTheme.goldAccentDark
                                        : (h['iconColor'] as Color),
                                    size: 26,
                                  ),
                                  Text(
                                    h['temp'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: context.themeText,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 16,
                                    child: rainProb != null
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.water_drop,
                                                size: 10,
                                                color: context.themePrimary,
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                rainProb,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: context.themePrimary,
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 4. Kartu 7 Hari Kedepan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.themeCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.themeBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '7 Hari Kedepan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: context.themeText,
                            ),
                          ),
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 20,
                            color: context.themeTextSecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(height: 1, color: context.themeBorder),
                      const SizedBox(height: 10),
                      ...weather.daily.map((d) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  d['day'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.themeText,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Icon(
                                  d['icon'] as IconData,
                                  size: 20,
                                  color: AppTheme.goldAccentDark,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${d['min']}   ${d['max']}',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: context.themeText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationBadge(String text, BuildContext context) {
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

  Widget _buildParamCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.themeTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.themeText,
            ),
          ),
        ],
      ),
    );
  }
}
