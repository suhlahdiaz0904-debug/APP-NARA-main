import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =========================================================================
// CONTROLLER & PENGELOLA STATE TEMA NARA (PERSISTEN DENGAN SHARED PREFERENCES)
// =========================================================================

class ThemeController extends ChangeNotifier {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const String _prefKey = 'nara_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Memuat preferensi tema dari penyimpanan lokal saat aplikasi start
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedMode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
  }

  /// Menentukan apakah saat ini aplikasi sedang dalam tampilan gelap
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Mengatur mode tema secara eksplisit (system, light, dark)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      String val = 'system';
      if (mode == ThemeMode.light) val = 'light';
      if (mode == ThemeMode.dark) val = 'dark';
      await prefs.setString(_prefKey, val);
    } catch (_) {}
  }

  /// Toggle cepat antara mode terang dan gelap
  Future<void> toggleTheme(BuildContext context) async {
    if (isDarkMode(context)) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}

// =========================================================================
// DEFINISI PALET WARNA & THEMEDATA RESMI NARA (COLORFUL, VIBRANT & INTERAKTIF)
// =========================================================================

class AppTheme {
  // Palet Light Mode (Fresh Pine & Sandstone Emerald with Vibrant Accents)
  static const Color lightBg = Color(0xFFF4F7F5); // Fresh Crisp Off-White/Sage
  static const Color lightCard = Color(0xFFFFFFFF); // Pure White Card
  static const Color lightSurface = Color(0xFFE8EFEA); // Soft Forest Tint
  static const Color lightSurfaceHigh = Color(0xFFDCE6DF); // Elevated Mist
  static const Color lightPrimary = Color(0xFF1B4D3E); // Deep Vibrant Forest Emerald
  static const Color lightPrimaryFixed = Color(0xFFCFE3D5); // Soft Sage Meadow
  static const Color lightTextDark = Color(0xFF14221A); // Deep Obsidian Green-Black
  static const Color lightTextSecondary = Color(0xFF5A7264); // Slate Forest Lichen
  static const Color lightBorder = Color(0xFFD3E0D8); // Muted Sage Border

  // Palet Dark Mode (Deep Forest Obsidian & Luminous Cyber-Emerald)
  static const Color darkBg = Color(0xFF0A1410); // Deep Forest Night
  static const Color darkCard = Color(0xFF112219); // Frosted Forest Card
  static const Color darkSurface = Color(0xFF162D21); // Deep Woodland Surface
  static const Color darkSurfaceHigh = Color(0xFF1F3F2E); // Elevated Forest Earth
  static const Color darkPrimary = Color(0xFF4EBA7C); // Luminous Emerald Sage
  static const Color darkPrimaryFixed = Color(0xFF1A382A); // Deep Pine Bed
  static const Color darkTextLight = Color(0xFFF2F7F4); // Crisp Snow-White
  static const Color darkTextSecondary = Color(0xFF98ADA0); // Muted Mist Lichen
  static const Color darkBorder = Color(0xFF214231); // Deep Earth Stone Border

  // Aksen Colorful & Vibrant Earth-Neon (Light & Dark Mode)
  static const Color primaryGreen = Color(0xFF2E7D46);
  static const Color primaryGreenDark = Color(0xFF3DAF68);
  static const Color orangeAccent = Color(0xFFF4622A);
  static const Color tealDark = Color(0xFF1B6B5C);
  static const Color tealDarkBright = Color(0xFF2DAA8F);
  static const Color expeditionDarkBg = Color(0xFF1A3C2A);

  static const Color vibrantEmerald = Color(0xFF2E7D32); // Vivid Emerald Green
  static const Color vibrantEmeraldDark = Color(0xFF00E676); // Neon Emerald
  
  static const Color goldAccent = Color(0xFFF59E0B); // Vivid Sunset Amber
  static const Color goldAccentDark = Color(0xFFFFC107); // Luminous Amber Gold
  
  static const Color terracotta = Color(0xFFE65100); // Vivid Terracotta / Fire Orange
  static const Color terracottaSoft = Color(0xFFFF7043); // Luminous Coral Orange
  
  static const Color roseAccent = Color(0xFFE91E63); // Vivid Wild Berry Rose
  static const Color roseAccentDark = Color(0xFFFF4081); // Neon Pink/Rose
  
  static const Color oceanCyan = Color(0xFF0288D1); // Vibrant Ocean Blue
  static const Color oceanCyanDark = Color(0xFF00E5FF); // Neon Cyber Cyan
  
  static const Color electricViolet = Color(0xFF7C4DFF); // Vivid Mountain Twilight Violet
  static const Color electricVioletDark = Color(0xFFB388FF); // Neon Purple Lavender

  static const Color tealKarst = Color(0xFF00897B); // Deep Teal Karst
  static const Color tealKarstDark = Color(0xFF1DE9B6); // Luminous Aqua Mint
  
  static const Color earthBrown = Color(0xFF8D6E63); // Warm Cedar Bark Brown
  static const Color earthOlive = Color(0xFF689F38); // Lime Forest Olive
  static const Color errorRed = Color(0xFFE53935); // Vivid Crimson Emergency
  static const Color errorRedDark = Color(0xFFFF5252); // Luminous Neon Coral Red

  // Gradients Cantik & Colorful untuk Seluruh Komponen
  static const List<Color> gradientEmeraldLight = [Color(0xFF1B5E20), Color(0xFF43A047)];
  static const List<Color> gradientEmeraldDark = [Color(0xFF00796B), Color(0xFF00E676)];

  static const List<Color> gradientSunsetLight = [Color(0xFFE65100), Color(0xFFFF9800)];
  static const List<Color> gradientSunsetDark = [Color(0xFFFF5722), Color(0xFFFFB300)];

  static const List<Color> gradientVioletLight = [Color(0xFF512DA8), Color(0xFF7C4DFF)];
  static const List<Color> gradientVioletDark = [Color(0xFF651FFF), Color(0xFFB388FF)];

  static const List<Color> gradientOceanLight = [Color(0xFF0277BD), Color(0xFF00B0FF)];
  static const List<Color> gradientOceanDark = [Color(0xFF0091EA), Color(0xFF00E5FF)];

  static const List<Color> gradientBerryLight = [Color(0xFFC2185B), Color(0xFFFF4081)];
  static const List<Color> gradientBerryDark = [Color(0xFFE91E63), Color(0xFFFF80AB)];

  static const List<Color> gradientTealLight = [Color(0xFF00695C), Color(0xFF26A69A)];
  static const List<Color> gradientTealDark = [Color(0xFF00897B), Color(0xFF64FFDA)];

  static const List<Color> gradientAmberLight = [Color(0xFFD97706), Color(0xFFFBBF24)];
  static const List<Color> gradientAmberDark = [Color(0xFFF59E0B), Color(0xFFFFD54F)];

  /// Tema Terang
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: orangeAccent,
        tertiary: tealDark,
        surface: Colors.white,
        surfaceContainer: lightSurface,
        surfaceContainerHigh: lightSurfaceHigh,
        onPrimary: Colors.white,
        onSurface: lightTextDark,
        outline: lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightTextDark),
        titleTextStyle: TextStyle(
          color: lightTextDark,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  /// Tema Gelap
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primaryGreenDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreenDark,
        secondary: orangeAccent,
        tertiary: tealDarkBright,
        surface: darkCard,
        surfaceContainer: darkSurface,
        surfaceContainerHigh: darkSurfaceHigh,
        onPrimary: Color(0xFF061E14),
        onSurface: darkTextLight,
        outline: darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextLight),
        titleTextStyle: TextStyle(
          color: darkTextLight,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

// =========================================================================
// EXTENSION CONTEXT UNTUK MEMPERMUDAH AKSES WARNA DINAMIS & COLORFUL DI SELURUH WIDGET
// =========================================================================

extension ThemeContextExtension on BuildContext {
  bool get isDarkMode {
    final theme = Theme.of(this);
    return theme.brightness == Brightness.dark;
  }

  Color get themeBg => isDarkMode ? AppTheme.darkBg : const Color(0xFFF0F4F1);
  Color get themeCard => isDarkMode ? AppTheme.darkCard : Colors.white;
  Color get themeSurface => isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface;
  Color get themeSurfaceHigh => isDarkMode ? AppTheme.darkSurfaceHigh : AppTheme.lightSurfaceHigh;
  Color get themePrimary => isDarkMode ? AppTheme.primaryGreenDark : AppTheme.primaryGreen;
  Color get themePrimaryFixed => isDarkMode ? AppTheme.darkPrimaryFixed : AppTheme.lightPrimaryFixed;
  Color get themeText => isDarkMode ? AppTheme.darkTextLight : AppTheme.lightTextDark;
  Color get themeTextSecondary => isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get themeBorder => isDarkMode ? AppTheme.darkBorder : AppTheme.lightBorder;
  Color get themeGold => isDarkMode ? AppTheme.goldAccentDark : AppTheme.goldAccent;
  Color get themeTerracotta => isDarkMode ? AppTheme.terracottaSoft : AppTheme.terracotta;
  Color get themeRose => isDarkMode ? AppTheme.roseAccentDark : AppTheme.roseAccent;
  Color get themeCyan => isDarkMode ? AppTheme.oceanCyanDark : AppTheme.oceanCyan;
  Color get themeViolet => isDarkMode ? AppTheme.electricVioletDark : AppTheme.electricViolet;
  Color get themeTeal => isDarkMode ? AppTheme.tealKarstDark : AppTheme.tealKarst;
  Color get themeEmerald => isDarkMode ? AppTheme.vibrantEmeraldDark : AppTheme.vibrantEmerald;
  Color get themeError => isDarkMode ? AppTheme.errorRedDark : AppTheme.errorRed;
  Color get themeOlive => AppTheme.earthOlive;
  Color get themeBrown => AppTheme.earthBrown;
  Color get themeOrange => AppTheme.orangeAccent;

  // Colorful Dynamic Gradients
  List<Color> get gradientEmerald => isDarkMode ? AppTheme.gradientEmeraldDark : AppTheme.gradientEmeraldLight;
  List<Color> get gradientSunset => isDarkMode ? AppTheme.gradientSunsetDark : AppTheme.gradientSunsetLight;
  List<Color> get gradientViolet => isDarkMode ? AppTheme.gradientVioletDark : AppTheme.gradientVioletLight;
  List<Color> get gradientOcean => isDarkMode ? AppTheme.gradientOceanDark : AppTheme.gradientOceanLight;
  List<Color> get gradientBerry => isDarkMode ? AppTheme.gradientBerryDark : AppTheme.gradientBerryLight;
  List<Color> get gradientTeal => isDarkMode ? AppTheme.gradientTealDark : AppTheme.gradientTealLight;
  List<Color> get gradientAmber => isDarkMode ? AppTheme.gradientAmberDark : AppTheme.gradientAmberLight;
}

