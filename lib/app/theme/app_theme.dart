import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AdenTweet theme — pure black & white, inspired by X/Twitter.
/// No blue, no colorful accents. Monochrome throughout.

ThemeData lightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final cairo = GoogleFonts.cairoTextTheme(base.textTheme);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: const Color(0xFFFFFFFF),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF000000),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF536471),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF000000),
      error: Color(0xFFF4212E),
      outline: Color(0xFFEFF3F4),
      outlineVariant: Color(0xFFEFF3F4),
    ),
    textTheme: cairo.copyWith(
      headlineLarge: cairo.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF000000)),
      headlineMedium: cairo.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF000000)),
      titleLarge: cairo.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF000000)),
      titleMedium: cairo.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF000000)),
      titleSmall: cairo.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF000000)),
      bodyLarge: cairo.bodyLarge?.copyWith(color: const Color(0xFF000000)),
      bodyMedium: cairo.bodyMedium?.copyWith(color: const Color(0xFF000000)),
      bodySmall: cairo.bodySmall?.copyWith(color: const Color(0xFF536471)),
      labelLarge: cairo.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF000000),
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w800, fontSize: 19, fontFamily: 'Cairo'),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      selectedItemColor: Color(0xFF000000),
      unselectedItemColor: Color(0xFF536471),
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFEFF3F4), thickness: 0.5, space: 0),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFEFF3F4), width: 0.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF000000),
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF000000),
        side: const BorderSide(color: Color(0xFF000000), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF000000),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF7F9F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF536471), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: Color(0xFF536471), fontFamily: 'Cairo'),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFFFFFFFF),
      elevation: 4,
      shape: CircleBorder(),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Color(0xFF000000),
      unselectedLabelColor: Color(0xFF536471),
      indicatorColor: Color(0xFF000000),
      dividerColor: Color(0xFFEFF3F4),
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 15),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Cairo', fontSize: 15),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

ThemeData darkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final cairo = GoogleFonts.cairoTextTheme(base.textTheme);
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Cairo',
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF000000),
      secondary: Color(0xFF71767B),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFE7E9EA),
      error: Color(0xFFF4212E),
      outline: Color(0xFF2F3336),
      outlineVariant: Color(0xFF2F3336),
    ),
    textTheme: cairo.copyWith(
      headlineLarge: cairo.headlineLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFFE7E9EA)),
      headlineMedium: cairo.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFE7E9EA)),
      titleLarge: cairo.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFFE7E9EA)),
      titleMedium: cairo.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFE7E9EA)),
      titleSmall: cairo.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFE7E9EA)),
      bodyLarge: cairo.bodyLarge?.copyWith(color: const Color(0xFFE7E9EA)),
      bodyMedium: cairo.bodyMedium?.copyWith(color: const Color(0xFFD6D9DB)),
      bodySmall: cairo.bodySmall?.copyWith(color: const Color(0xFF71767B)),
      labelLarge: cairo.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Color(0xFFE7E9EA),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: Color(0xFFE7E9EA), fontWeight: FontWeight.w800, fontSize: 19, fontFamily: 'Cairo'),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF000000),
      selectedItemColor: Color(0xFFFFFFFF),
      unselectedItemColor: Color(0xFF71767B),
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF2F3336), thickness: 0.5, space: 0),
    cardTheme: CardThemeData(
      color: const Color(0xFF16181C),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF2F3336), width: 0.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF000000),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFFFFFF),
        side: const BorderSide(color: Color(0xFF536471), width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFFFFFFF),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Cairo'),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF16181C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF536471), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: Color(0xFF536471), fontFamily: 'Cairo'),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF000000),
      elevation: 4,
      shape: CircleBorder(),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Color(0xFFFFFFFF),
      unselectedLabelColor: Color(0xFF71767B),
      indicatorColor: Color(0xFFFFFFFF),
      dividerColor: Color(0xFF2F3336),
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 15),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Cairo', fontSize: 15),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}