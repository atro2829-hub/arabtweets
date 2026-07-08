import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme get textTheme {
    final base = GoogleFonts.cairoTextTheme();
    return TextTheme(
      displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.bold),
      displayMedium: base.displayMedium?.copyWith(fontWeight: FontWeight.bold),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.bold),
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: base.labelSmall?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}