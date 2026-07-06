import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens lifted directly from the web app's production CSS bundle
/// (flame-frontend-blond.vercel.app) so the mobile app matches it exactly.
///
class AppColors {
  AppColors._();

  static const bg = _darkBg;
  static const surface = _darkSurface;
  static const surface2 = _darkSurface2;
  static const border = _darkBorder;
  static const borderHi = _darkBorderHi;
  static const text1 = _darkText1;
  static const text2 = _darkText2;
  static const text3 = _darkText3;
  static const amber = _darkAmber;
  static const amberSoft = _darkAmberSoft;
  static const error = Color(0xFFEF4444);

  static const _darkBg = Color(0xFF1A1C1C);
  static const _darkSurface = Color(0xFF121414);
  static const _darkSurface2 = Color(0xFF1E2020);
  static const _darkBorder = Color(0xFF333535);
  static const _darkBorderHi = Color(0xFF5B4039);
  static const _darkText1 = Color(0xFFE2E2E2);
  static const _darkText2 = Color(0xFFB7B5B4);
  static const _darkText3 = Color(0xFF929090);
  static const _darkAmber = Color(0xFFFF5722);
  static const _darkAmberSoft = Color(0xFFFFB5A0);

  /// Listings palette (Events/Workshops screens): the same warm peach +
  /// deep orange duo used as the accent, now over whichever base
  /// surfaces are active for the current mode.
  static const listingInk = Colors.white;
  static const listingAccent = lightAccent;
  static const listingAccentSoft = lightAccentSoft;
  static const listingBg = bg;
  static const listingHeaderBg = surface;
  static const listingCard = Color(0xFF232525);
  static const listingCardBorder = Color(0x1FFFFFFF);
  static const listingTextMuted = text2;

  static const listingAccentGradient = LinearGradient(
    colors: [listingAccent, Color(0xFFE8853F)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const shadowCard = [
    BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 8)),
  ];

  static const accentGradient = LinearGradient(
    colors: [amber, amberSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Web's `.glass-panel`: `background:#121212cc` + `backdrop-filter:blur(20px)`.
  static const glassPanel = Color(0xCC121212);
  static const glassBlur = 20.0;

  // Corner radii lifted from the web app's Tailwind scale / component CSS.
  static const double cardRadius = 16; // rounded-2xl
  static const double cardRadiusLg = 24; // rounded-3xl
  static const double buttonRadius = 12; // .epm-save-btn
  static const double inputRadius = 12; // standard form inputs
  static const double searchRadius = 22; // pill-shaped search-style inputs
  static const double pillRadius = 999; // rounded-full (chips/badges)

  /// Shared decorative header background used behind profile screens
  /// throughout the app (was an off-brand brown/orange/black gradient;
  /// now built from the real palette).
  static const profileHeaderGradient = [amber, surface2, bg];

  // ─── Light mode palette (user-supplied brand colors) ──────────────────────
  static const lightBg = Color(0xFFFFF5E7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFFFEEDA);
  static const lightBorder = Color(0xFFEBD9BE);
  static const lightBorderHi = Color(0xFFE0A970);
  static const lightAccent = Color(0xFFD7640C);
  static const lightAccentSoft = Color(0xFFFBBE89);
  static const lightText1 = Color(0xFF2A2118);
  static const lightText2 = Color(0xFF6B5D4D);
  static const lightText3 = Color(0xFF9C8F7C);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme)
        .merge(
          TextTheme(
            displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            displayMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            displaySmall: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            headlineLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            headlineMedium: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
            ),
            headlineSmall: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
        )
        .apply(bodyColor: AppColors.text1, displayColor: AppColors.text1);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.amber,
      brightness: Brightness.dark,
      primary: AppColors.amber,
      secondary: AppColors.amberSoft,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.bg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text1,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: AppColors.text1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      iconTheme: IconThemeData(color: AppColors.text1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        hintStyle: GoogleFonts.inter(color: AppColors.text3),
        labelStyle: GoogleFonts.inter(color: AppColors.text2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.amber, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.amber,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text1,
          side: BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.amber,
        unselectedItemColor: AppColors.text3,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surface2,
        labelStyle: GoogleFonts.inter(color: AppColors.text1),
        side: BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface2,
        contentTextStyle: GoogleFonts.inter(color: AppColors.text1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.amber,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  /// Light theme using the user-supplied palette (`#FFF5E7` / `#FBBE89` /
  /// `#D7640C`). Note: most existing screens read colors directly from the
  /// [AppColors] dark constants rather than `Theme.of(context)` (a
  /// pre-existing pattern from early in the project, not introduced here),
  /// so switching to light mode changes default/theme-driven chrome (app
  /// bar, inputs, buttons, dialogs, new screens) but won't yet re-color
  /// every existing screen — that would mean touching each one individually.
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    final textTheme = GoogleFonts.interTextTheme(base.textTheme)
        .merge(
          TextTheme(
            displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            displayMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            displaySmall: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            headlineLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            headlineSmall: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
            titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
        )
        .apply(bodyColor: AppColors.lightText1, displayColor: AppColors.lightText1);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.lightAccent,
      brightness: Brightness.light,
      primary: AppColors.lightAccent,
      secondary: AppColors.lightAccentSoft,
      surface: AppColors.lightSurface,
      error: AppColors.error,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: AppColors.lightText1,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: AppColors.lightText1,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1),
      iconTheme: const IconThemeData(color: AppColors.lightText1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface2,
        hintStyle: GoogleFonts.inter(color: AppColors.lightText3),
        labelStyle: GoogleFonts.inter(color: AppColors.lightText2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightAccent,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightText1,
          side: const BorderSide(color: AppColors.lightBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBg,
        selectedItemColor: AppColors.lightAccent,
        unselectedItemColor: AppColors.lightText3,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.lightSurface2,
        labelStyle: GoogleFonts.inter(color: AppColors.lightText1),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightText1,
        contentTextStyle: GoogleFonts.inter(color: AppColors.lightBg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.lightAccent),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}

/// Persists and broadcasts the user's light/dark mode choice. A plain
/// [ValueNotifier] (no state-management package in this project) that
/// [MyApp] listens to directly.
class ThemeController {
  ThemeController._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.dark);

  static Future<void> load() async {
    try {
      final saved = await _storage.read(key: _key);
      if (saved == 'light') {
        mode.value = ThemeMode.light;
      } else if (saved == 'dark') {
        mode.value = ThemeMode.dark;
      }
    } catch (_) {
      // Keep the default (dark) if secure storage isn't available.
    }
  }

  static Future<void> setLight(bool light) async {
    mode.value = light ? ThemeMode.light : ThemeMode.dark;
    try {
      await _storage.write(key: _key, value: light ? 'light' : 'dark');
    } catch (_) {}
  }
}
