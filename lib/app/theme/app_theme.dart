import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData lightTheme() {
  final cairoText = GoogleFonts.cairoTextTheme(ThemeData.light().textTheme);
  return FlexThemeData.light(
    scheme: FlexScheme.blue,
    useMaterial3: true,
    fontFamily: 'Cairo',
    textTheme: cairoText,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1DA1F2),
      onPrimary: Colors.white,
      secondary: Color(0xFF1DA1F2),
      surface: Color(0xFFF5F8FA),
      onSurface: Color(0xFF0F1419),
      error: Color(0xFFF4212E),
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 4,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    swapLegacyOnMaterial3: true,
    cupertinoOverrideTheme: const CupertinoThemeData(brightness: Brightness.light),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

ThemeData darkTheme() {
  final cairoText = GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme);
  return FlexThemeData.dark(
    scheme: FlexScheme.blue,
    useMaterial3: true,
    fontFamily: 'Cairo',
    textTheme: cairoText,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1DA1F2),
      onPrimary: Colors.white,
      secondary: Color(0xFF1DA1F2),
      surface: Color(0xFF16181C),
      onSurface: Color(0xFFE7E9EA),
      error: Color(0xFFF4212E),
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 8,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    swapLegacyOnMaterial3: true,
    cupertinoOverrideTheme: const CupertinoThemeData(brightness: Brightness.dark),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}