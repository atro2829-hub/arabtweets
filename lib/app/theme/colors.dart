import 'dart:ui';

/// AdenTweet monochrome design system.
/// Inspired by X/Twitter: black, white, and grays only.
/// Action colors (like=red, retweet=green) are only used for action buttons.
class AppColors {
  AppColors._();

  // ─── Brand ─────────────────────────────────────────────────
  // In B&W theme, primary is used for buttons (white in dark, black in light)
  // The theme system handles the actual button color, so primary here
  // is kept for backward compatibility in screens not yet refactored.
  static const primary = Color(0xFF000000);
  static const primaryDark = Color(0xFF000000);
  static const primaryLight = Color(0xFFF7F9F9);

  // Backward compat aliases
  static const lightBackground = Color(0xFFFFFFFF);
  static const darkSurfaceDark = Color(0xFF1D1F23);

  // ─── Action Colors (only for action buttons, not themes) ────────
  static const like = Color(0xFFF91880);
  static const likeBackground = Color(0x1AF91880);
  static const retweet = Color(0xFF00BA7C);
  static const retweetBackground = Color(0x1A00BA7C);

  // ─── Light Theme ────────────────────────────────────────────────
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF7F9F9);
  static const lightTextPrimary = Color(0xFF000000);
  static const lightTextSecondary = Color(0xFF536471);
  static const lightTextTertiary = Color(0xFF8B98A5);
  static const lightBorder = Color(0xFFEFF3F4);
  static const lightDivider = Color(0xFFEFF3F4);
  static const lightHover = Color(0xFFF7F9F9);
  static const lightPressed = Color(0xFFE8E8E8);

  // ─── Dark Theme ──────────────────────────────────────────────────
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF16181C);
  static const darkCard = Color(0xFF1D1F23);
  static const darkTextPrimary = Color(0xFFE7E9EA);
  static const darkTextSecondary = Color(0xFF71767B);
  static const darkTextTertiary = Color(0xFF536471);
  static const darkBorder = Color(0xFF2F3336);
  static const darkDivider = Color(0xFF2F3336);
  static const darkHover = Color(0xFF080808);
  static const darkPressed = Color(0xFF1D1F23);

  // ─── Status ──────────────────────────────────────────────────────
  static const success = Color(0xFF00BA7C);
  static const warning = Color(0xFFFFAD1F);
  static const error = Color(0xFFF4212E);
  static const info = Color(0xFF536471);
  static const message = Color(0xFF000000); // alias

  // ─── Verified ───────────────────────────────────────────────────
  static const verified = Color(0xFF1D9BF0);

  // ─── Helper: get colors based on brightness ─────────────────────
  static Color background(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color card(bool isDark) => isDark ? darkCard : lightCard;
  static Color textPrimary(bool isDark) => isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) => isDark ? darkTextSecondary : lightTextSecondary;
  static Color textTertiary(bool isDark) => isDark ? darkTextTertiary : lightTextTertiary;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color divider(bool isDark) => isDark ? darkDivider : lightDivider;
  static Color hover(bool isDark) => isDark ? darkHover : lightHover;
}