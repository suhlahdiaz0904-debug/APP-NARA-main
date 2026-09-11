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
// DEFINISI PALET WARNA & THEMEDATA RESMI NARA (SCREENSHOT STYLE)
// =========================================================================

class AppTheme {
  // Palet Light Mode
  static const Color lightBg = Color(0xFFF0F4F1);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFEAF1EC);
  static const Color lightSurfaceHigh = Color(0xFFDCE8DF);
  static const Color lightPrimary = Color(0xFF2E7D46);     // Vivid Forest Green
  static const Color lightPrimaryFixed = Color(0xFFCBE8D5);
  static const Color lightTextDark = Color(0xFF1A241F);
  static const Color lightTextSecondary = Color(0xFF6B7D72);
  static const Color lightBorder = Color(0xFFD0DDD4);

  // Palet Dark Mode
  static const Color darkBg = Color(0xFF0D1612);
  static const Color darkCard = Color(0xFF14241C);
  static const Color darkSurface = Color(0xFF1B2E25);
  static const Color darkSurfaceHigh = Color(0xFF243B30);
  static const Color darkPrimary = Color(0xFF3DAF68);      // Bright Emerald
  static const Color darkPrimaryFixed = Color(0xFF1A382A);
  static const Color darkTextLight = Color(0xFFF0F5F2);
  static const Color darkTextSecondary = Color(0xFF95A69B);
  static const Color darkBorder = Color(0xFF233B2F);

  // Aksen Warna Cerah (Screenshot Style)
  static const Color primaryGreen = Color(0xFF2E7D46);
  static const Color primaryGreenDark = Color(0xFF3DAF68);
  static const Color orangeAccent = Color(0xFFF4622A);     // Vivid Orange (Gear)
  static const Color tealDark = Color(0xFF1B6B5C);         // Deep Teal (Maintenance)
  static const Color tealDarkBright = Color(0xFF2DAA8F);   // Bright Teal (dark mode)
  static const Color goldAccent = Color(0xFFE9A000);
  static const Color goldAccentDark = Color(0xFFF5C842);
  static const Color terracotta = Color(0xFFC46849);
  static const Color terracottaSoft = Color(0xFFE28C72);
  static const Color roseAccent = Color(0xFFB8786B);
  static const Color earthBrown = Color(0xFF734E35);
  static const Color earthOlive = Color(0xFF586E53);
  static const Color errorRed = Color(0xFFD94A3D);
  static const Color expeditionDarkBg = Color(0xFF1A3C2A);

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
// EXTENSION CONTEXT UNTUK MEMPERMUDAH AKSES WARNA DINAMIS DI SELURUH WIDGET
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
  Color get themeOlive => AppTheme.earthOlive;
  Color get themeBrown => AppTheme.earthBrown;
  Color get themeOrange => AppTheme.orangeAccent;
  Color get themeTeal => isDarkMode ? AppTheme.tealDarkBright : AppTheme.tealDark;
}

