import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Centralized SVG icon paths and helper widgets for AdenTweet.
/// All icons are monochrome (currentColor) and scale perfectly.
class AppIcons {
  AppIcons._();

  // ─── Navigation ──────────────────────────────────────────────────
  static const String home = 'assets/icons/svg/home.svg';
  static const String homeFilled = 'assets/icons/svg/home_filled.svg';
  static const String search = 'assets/icons/svg/search.svg';
  static const String searchFilled = 'assets/icons/svg/search_filled.svg';
  static const String notifications = 'assets/icons/svg/notifications.svg';
  static const String notificationsFilled = 'assets/icons/svg/notifications_filled.svg';
  static const String mail = 'assets/icons/svg/mail.svg';
  static const String mailFilled = 'assets/icons/svg/mail_filled.svg';
  static const String reels = 'assets/icons/svg/reels.svg';
  static const String reelsFilled = 'assets/icons/svg/reels_filled.svg';
  static const String profile = 'assets/icons/svg/profile.svg';

  // ─── Actions ─────────────────────────────────────────────────────
  static const String compose = 'assets/icons/svg/compose.svg';
  static const String like = 'assets/icons/svg/like.svg';
  static const String likeFilled = 'assets/icons/svg/like_filled.svg';
  static const String retweet = 'assets/icons/svg/retweet.svg';
  static const String retweetFilled = 'assets/icons/svg/retweet_filled.svg';
  static const String reply = 'assets/icons/svg/reply.svg';
  static const String share = 'assets/icons/svg/share.svg';
  static const String bookmark = 'assets/icons/svg/bookmark.svg';
  static const String bookmarkFilled = 'assets/icons/svg/bookmark_filled.svg';

  // ─── Brand ────────────────────────────────────────────────────────
  static const String logo = 'assets/icons/svg/logo.svg';
  static const String logoTransparent = 'assets/icons/svg/logo_transparent.svg';
  static const String verifiedBadge = 'assets/icons/svg/verified_badge.svg';
  static const String verifiedGold = 'assets/icons/svg/verified_gold.svg';

  // ─── UI ───────────────────────────────────────────────────────────
  static const String more = 'assets/icons/svg/more.svg';
  static const String settings = 'assets/icons/svg/settings_gear.svg';
  static const String backArrow = 'assets/icons/svg/back_arrow.svg';
  static const String close = 'assets/icons/svg/close.svg';
  static const String camera = 'assets/icons/svg/camera.svg';
  static const String imageGallery = 'assets/icons/svg/image_gallery.svg';
  static const String gif = 'assets/icons/svg/gif.svg';
  static const String emoji = 'assets/icons/svg/emoji.svg';
  static const String poll = 'assets/icons/svg/poll.svg';
  static const String location = 'assets/icons/svg/location.svg';
  static const String link = 'assets/icons/svg/link.svg';
}

/// Helper to build an SVG icon with consistent sizing and color.
class AppIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;

  const AppIcon(
    this.assetPath, {
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// Custom verified badge widget with blue checkmark.
class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool isGold;

  const VerifiedBadge({super.key, this.size = 18, this.isGold = false});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      isGold ? AppIcons.verifiedGold : AppIcons.verifiedBadge,
      width: size,
      height: size,
    );
  }
}