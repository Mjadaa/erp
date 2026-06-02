import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);

  // Sidebar
  static const Color sidebarBg = Color(0xFF0F172A);
  static const Color sidebarActiveBg = Color(0xFF1E293B);
  static const Color sidebarAccent = Color(0xFF3B82F6);
  static const Color sidebarTextMuted = Color(0xFF64748B);
  static const Color sidebarText = Color(0xFF94A3B8);
  static const Color sidebarTextActive = Color(0xFFFFFFFF);
  static const Color sidebarDivider = Color(0xFF1E293B);

  // Content
  static const Color contentBg = Color(0xFFF1F5F9);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFDBEAFE);

  // KPI card gradient pairs
  static const List<Color> kpiRevenue = [Color(0xFF667EEA), Color(0xFF764BA2)];
  static const List<Color> kpiSales = [Color(0xFF11998E), Color(0xFF38EF7D)];
  static const List<Color> kpiCustomers = [Color(0xFFFC5C7D), Color(0xFF6A82FB)];
  static const List<Color> kpiStock = [Color(0xFFF7971E), Color(0xFFFFD200)];

  // Login branding gradient
  static const List<Color> loginGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E3A5F),
    Color(0xFF0F2044),
  ];
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(TextTheme base) =>
      GoogleFonts.cairoTextTheme(base);

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFDBEAFE),
        onPrimaryContainer: Color(0xFF1E3A8A),
        secondary: Color(0xFF7C3AED),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFEDE9FE),
        onSecondaryContainer: Color(0xFF4C1D95),
        tertiary: AppColors.success,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.successBg,
        onTertiaryContainer: Color(0xFF065F46),
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerBg,
        onErrorContainer: Color(0xFF7F1D1D),
        surface: AppColors.contentBg,
        onSurface: Color(0xFF0F172A),
        surfaceContainerHighest: Color(0xFFE2E8F0),
        onSurfaceVariant: Color(0xFF64748B),
        outline: Color(0xFFCBD5E1),
        outlineVariant: AppColors.cardBorder,
        shadow: Color(0xFF0F172A),
        scrim: Color(0xFF0F172A),
        inverseSurface: Color(0xFF1E293B),
        onInverseSurface: Color(0xFFF1F5F9),
        inversePrimary: Color(0xFF93C5FD),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.contentBg,
      textTheme: _textTheme(base.textTheme),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.sidebarTextMuted),
        prefixIconColor: AppColors.sidebarTextMuted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cardBorder,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
    );
    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
    );
  }
}
