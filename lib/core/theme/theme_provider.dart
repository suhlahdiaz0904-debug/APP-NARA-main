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
// DEFINISI PALET WARNA & THEMEDATA RESMI NARA (EARTH TONE & MIDNIGHT FOREST)
// =========================================================================

class AppTheme {
  // Palet Light Mode (Fresh Pine & Sandstone Emerald)
  static const Color lightBg = Color(0xFFF4F7F5); // Fresh Crisp Off-White/Sage
  static const Color lightCard = Color(0xFFFFFFFF); // Pure White Card
  static const Color lightSurface = Color(0xFFE8EFEA); // Soft Forest Tint
  static const Color lightSurfaceHigh = Color(0xFFDCE6DF); // Elevated Mist
  static const Color lightPrimary = Color(0xFF2D5A43); // Deep Forest Emerald (Warna Awal Login)
  static const Color lightPrimaryFixed = Color(0xFFCFE3D5); // Soft Sage Meadow
  static const Color lightTextDark = Color(0xFF1A241F); // Deep Obsidian Green-Black
  static const Color lightTextSecondary = Color(0xFF6B7D72); // Slate Forest Lichen
  static const Color lightBorder = Color(0xFFD3E0D8); // Muted Sage Border

  // Palet Dark Mode (Deep Forest Obsidian & Luminous Emerald Sage)
  static const Color darkBg = Color(0xFF0D1612); // Deep Forest Night
  static const Color darkCard = Color(0xFF14241C); // Frosted Forest Card (Warna Awal Login)
  static const Color darkSurface = Color(0xFF1B2E25); // Deep Woodland Surface
  static const Color darkSurfaceHigh = Color(0xFF243B30); // Elevated Forest Earth
  static const Color darkPrimary = Color(0xFF4CAF78); // Luminous Emerald Sage (Warna Awal Login)
  static const Color darkPrimaryFixed = Color(0xFF1A382A); // Deep Pine Bed
  static const Color darkTextLight = Color(0xFFF0F5F2); // Crisp Snow-White
  static const Color darkTextSecondary = Color(0xFF95A69B); // Muted Mist Lichen
  static const Color darkBorder = Color(0xFF233B2F); // Deep Earth Stone Border

  // Aksen Earth Tone & Alam Bersama
  static const Color goldAccent = Color(0xFFDDA15E); // Warm Sand Gold
  static const Color goldAccentDark = Color(0xFFE9C46A); // Luminous Amber Gold
  static const Color terracotta = Color(0xFFC46849); // Rustic Terracotta Clay
  static const Color terracottaSoft = Color(0xFFE28C72); // Soft Desert Terracotta
  static const Color roseAccent = Color(0xFFB8786B); // Earthy Dusty Rose Clay
  static const Color earthBrown = Color(0xFF734E35); // Cedar Bark Brown
  static const Color earthOlive = Color(0xFF586E53); // Olive Forest Green
  static const Color errorRed = Color(0xFFD94A3D); // Warm Burnt Crimson

  /// Tema Terang (Light Earth Tone Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: goldAccent,
        surface: lightCard,
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
        iconTheme: IconThemeData(color: lightPrimary),
        titleTextStyle: TextStyle(
          color: lightPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  /// Tema Gelap (Dark Midnight Forest Theme)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: goldAccentDark,
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
        iconTheme: IconThemeData(color: darkPrimary),
        titleTextStyle: TextStyle(
          color: darkTextLight,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          fontFamily: 'Inter',
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
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
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
// EXTENSION CONTEXT UNTUK MEMPERMUDAH AKSES WARNA DINAMIS DI SELURUH WIDGET
// =========================================================================

extension ThemeContextExtension on BuildContext {
  bool get isDarkMode {
    final theme = Theme.of(this);
    return theme.brightness == Brightness.dark;
  }

  Color get themeBg => isDarkMode ? AppTheme.darkBg : AppTheme.lightBg;
  Color get themeCard => isDarkMode ? AppTheme.darkCard : AppTheme.lightCard;
  Color get themeSurface => isDarkMode ? AppTheme.darkSurface : AppTheme.lightSurface;
  Color get themeSurfaceHigh => isDarkMode ? AppTheme.darkSurfaceHigh : AppTheme.lightSurfaceHigh;
  Color get themePrimary => isDarkMode ? AppTheme.darkPrimary : AppTheme.lightPrimary;
  Color get themePrimaryFixed => isDarkMode ? AppTheme.darkPrimaryFixed : AppTheme.lightPrimaryFixed;
  Color get themeText => isDarkMode ? AppTheme.darkTextLight : AppTheme.lightTextDark;
  Color get themeTextSecondary => isDarkMode ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get themeBorder => isDarkMode ? AppTheme.darkBorder : AppTheme.lightBorder;
  Color get themeGold => isDarkMode ? AppTheme.goldAccentDark : AppTheme.goldAccent;
  Color get themeTerracotta => isDarkMode ? AppTheme.terracottaSoft : AppTheme.terracotta;
  Color get themeOlive => AppTheme.earthOlive;
  Color get themeBrown => AppTheme.earthBrown;
}
