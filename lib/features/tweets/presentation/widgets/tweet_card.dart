import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../../app/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/tweet_model.dart';

// ─── Callbacks ───────────────────────────────────────────────────────────────

typedef TweetActionCallback = void Function(int tweetId);

// ─── Tweet Card Widget ───────────────────────────────────────────────────────

class TweetCard extends StatefulWidget {
  final TweetModel tweet;
  final int index;
  final TweetActionCallback? onLike;
  final TweetActionCallback? onRetweet;
  final TweetActionCallback? onReply;
  final TweetActionCallback? onBookmark;
  final TweetActionCallback? onDelete;
  final VoidCallback? onTap;

  const TweetCard({
    super.key,
    required this.tweet,
    this.index = 0,
    this.onLike,
    this.onRetweet,
    this.onReply,
    this.onBookmark,
    this.onDelete,
    this.onTap,
  });

  @override
  State<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends State<TweetCard> {
  /// Track local animation keys for like/retweet toggle effects.
  bool _showLikeAnimation = false;
  bool _showRetweetAnimation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tweet = widget.tweet;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor =
        isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  // ── Avatar ──────────────────────────────────────────
                  _buildAvatar(tweet, theme),
                  const SizedBox(width: 12),

                  // ── Content Column ──────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        // Top row: name, username, time, more button
                        _buildHeader(tweet, theme, textSecondary, context),
                        const SizedBox(height: 4),

                        // Tweet text content with hashtag/mention highlighting
                        if (tweet.content.isNotEmpty)
                          _buildContent(tweet, theme),

                        // Quote tweet preview
                        if (tweet.isQuote && tweet.quoteTweet != null) ...[
                          const SizedBox(height: 8),
                          _buildQuotePreview(tweet.quoteTweet!, theme, isDark),
                        ],

                        // Media section
                        if (tweet.mediaUrls.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildMediaGrid(tweet, isDark),
                        ],

                        const SizedBox(height: 8),

                        // Action buttons row
                        _buildActions(tweet, textSecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 0.5, thickness: 0.5, color: dividerColor),
          ],
        ),
      ),
    )
        .animate(delay: (widget.index * 50).ms)
        .fadeIn(duration: 300.ms, curve: Curves.easeOut)
        .slideX(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  // ── Avatar ─────────────────────────────────────────────────────────────

  Widget _buildAvatar(TweetModel tweet, ThemeData theme) {
    final hasAvatar = tweet.fullAvatarUrl.isNotEmpty;
    final firstLetter =
        tweet.displayName.isNotEmpty ? tweet.displayName[0] : '?';

    return GestureDetector(
      onTap: () {
        context.push('/profile/${tweet.userId}');
      },
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primaryLight,
        backgroundImage:
            hasAvatar ? CachedNetworkImageProvider(tweet.fullAvatarUrl) : null,
        child: !hasAvatar
            ? Text(
                firstLetter,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              )
            : null,
      ),
    );
  }

  // ── Header (name, username, time, more) ───────────────────────────────

  Widget _buildHeader(
      TweetModel tweet, ThemeData theme, Color textSecondary, BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        // Display name
        Flexible(
          child: GestureDetector(
            onTap: () => context.push('/profile/${tweet.userId}'),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Flexible(
                  child: Text(
                    tweet.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (tweet.isVerified) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.verified,
                    size: 18,
                    color: AppColors.verified,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Username
        GestureDetector(
          onTap: () => context.push('/profile/${tweet.userId}'),
          child: Text(
            '@${tweet.username}',
            style: TextStyle(fontSize: 13, color: textSecondary),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 6),

        // Dot separator
        Text(
          '·',
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        const SizedBox(width: 6),

        // Time ago
        Text(
          AppFormatters.formatTimeAgo(tweet.createdAt),
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),

        const Spacer(),

        // More button
        InkWell(
          onTap: () => _showMoreOptions(context, tweet),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.more_horiz,
              size: 20,
              color: textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Content with hashtag & mention highlighting ───────────────────────

  Widget _buildContent(TweetModel tweet, ThemeData theme) {
    final content = tweet.content;

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: theme.colorScheme.onSurface,
          fontFamily: 'Cairo',
        ),
        children: _buildTextSpans(content, theme),
      ),
    );
  }

  List<TextSpan> _buildTextSpans(String text, ThemeData theme) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'(#\S+|@\S+)');
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final matchedText = match.group(0)!;

      spans.add(TextSpan(
        text: matchedText,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 15,
          height: 1.5,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }

  // ── Quote Tweet Preview ───────────────────────────────────────────────

  Widget _buildQuotePreview(TweetModel quote, ThemeData theme, bool isDark) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          // Author row
          Row(
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: quote.fullAvatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(quote.fullAvatarUrl)
                    : null,
                child: quote.fullAvatarUrl.isEmpty
                    ? Text(
                        quote.displayName.isNotEmpty
                            ? quote.displayName[0]
                            : '?',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Flexible(
                      child: Text(
                        quote.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (quote.isVerified) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.verified, size: 14, color: AppColors.verified),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '@${quote.username}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Content preview
          Text(
            quote.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ── Media Grid ────────────────────────────────────────────────────────

  Widget _buildMediaGrid(TweetModel tweet, bool isDark) {
    final urls = tweet.fullMediaUrls;
    final count = urls.length;

    if (count == 1) {
      return _buildMediaItem(
        url: urls[0],
        index: 0,
        urls: urls,
        borderRadius: BorderRadius.circular(16),
        height: 200,
      );
    }

    if (count == 2) {
      return SizedBox(
        height: 180,
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: _buildMediaItem(
                url: urls[0],
                index: 0,
                urls: urls,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16),
                  left: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _buildMediaItem(
                url: urls[1],
                index: 1,
                urls: urls,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                  left: Radius.circular(16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3 or 4 images in a 2x2 grid
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _buildMediaItem(
                    url: urls[0],
                    index: 0,
                    urls: urls,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      topLeft: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildMediaItem(
                    url: urls[1],
                    index: 1,
                    urls: urls,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (count == 3)
            Expanded(
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildMediaItem(
                      url: urls[2],
                      index: 2,
                      urls: urls,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildMediaItem(
                      url: urls[2],
                      index: 2,
                      urls: urls,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildMediaItem(
                      url: urls[3],
                      index: 3,
                      urls: urls,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaItem({
    required String url,
    required int index,
    required List<String> urls,
    required BorderRadius borderRadius,
    double? height,
  }) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: GestureDetector(
        onTap: () => _openFullScreenImages(urls, index),
        child: CachedNetworkImage(
          imageUrl: url,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
          ),
        ),
      ),
    );
  }

  // ── Full Screen Image Viewer ──────────────────────────────────────────

  void _openFullScreenImages(List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenGallery(
            imageUrls: urls,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────

  Widget _buildActions(TweetModel tweet, Color textSecondary) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        // Reply
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble_outline,
          count: tweet.replyCount,
          activeColor: AppColors.primary,
          inactiveColor: textSecondary,
          isActive: false,
          onTap: () => widget.onReply?.call(tweet.id),
          label: 'رد',
        ),

        // Retweet
        _ActionButton(
          icon: Icons.repeat,
          activeIcon: Icons.repeat,
          count: tweet.retweetCount,
          activeColor: AppColors.retweet,
          inactiveColor: textSecondary,
          activeBackgroundColor: AppColors.retweetBackground,
          isActive: tweet.isRetweeted,
          onTap: () {
            setState(() => _showRetweetAnimation = true);
            widget.onRetweet?.call(tweet.id);
            Future.delayed(400.ms, () {
              if (mounted) setState(() => _showRetweetAnimation = false);
            });
          },
          showAnimation: _showRetweetAnimation,
          label: 'إعادة تغريد',
        ),

        // Like
        _ActionButton(
          icon: Icons.favorite_border,
          activeIcon: Icons.favorite,
          count: tweet.likeCount,
          activeColor: AppColors.like,
          inactiveColor: textSecondary,
          activeBackgroundColor: AppColors.likeBackground,
          isActive: tweet.isLiked,
          onTap: () {
            setState(() => _showLikeAnimation = true);
            widget.onLike?.call(tweet.id);
            Future.delayed(400.ms, () {
              if (mounted) setState(() => _showLikeAnimation = false);
            });
          },
          showAnimation: _showLikeAnimation,
          label: 'إعجاب',
          animateScale: true,
        ),

        // Bookmark
        _ActionButton(
          icon: Icons.bookmark_border,
          activeIcon: Icons.bookmark,
          count: 0,
          showCount: false,
          activeColor: AppColors.primary,
          inactiveColor: textSecondary,
          isActive: tweet.isBookmarked,
          onTap: () => widget.onBookmark?.call(tweet.id),
          label: 'حفظ',
        ),
      ],
    );
  }

  // ── More Options Sheet ────────────────────────────────────────────────

  void _showMoreOptions(BuildContext context, TweetModel tweet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.primary),
                title: const Text('نسخ رابط التغريدة'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'https://buvcyaxgxrbjdikefsyq.supabase.co/tweet/${widget.tweet.id}'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ الرابط'), duration: Duration(seconds: 2)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: AppColors.primary),
                title: const Text('مشاركة'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.volume_off, color: AppColors.primary),
                title: const Text('كتم المستخدم'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (widget.tweet.userId == Supabase.instance.client.auth.currentUser?.id)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text(
                    'حذف التغريدة',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await Supabase.instance.client.from('tweets').delete().eq('id', widget.tweet.id);
                      widget.onDelete?.call(widget.tweet.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حذف التغريدة'), duration: Duration(seconds: 2)),
                        );
                      }
                    } catch (_) {}
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ─── Action Button Widget ────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int count;
  final bool showCount;
  final Color activeColor;
  final Color inactiveColor;
  final Color? activeBackgroundColor;
  final bool isActive;
  final VoidCallback onTap;
  final String label;
  final bool showAnimation;
  final bool animateScale;

  const _ActionButton({
    required this.icon,
    required this.activeIcon,
    required this.onTap,
    this.count = 0,
    this.showCount = true,
    this.activeColor = AppColors.primary,
    this.inactiveColor = AppColors.lightTextSecondary,
    this.activeBackgroundColor,
    this.isActive = false,
    this.label = '',
    this.showAnimation = false,
    this.animateScale = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    Widget iconWidget = Icon(
      isActive ? activeIcon : icon,
      size: 18,
      color: color,
    );

    if (animateScale && showAnimation) {
      iconWidget = iconWidget.animate(
        key: ValueKey(showAnimation),
      ).scale(
        begin: const Offset(1, 1),
        end: const Offset(1.3, 1.3),
        duration: 200.ms,
        curve: Curves.easeOut,
      ).then().scale(
        begin: const Offset(1.3, 1.3),
        end: const Offset(1, 1),
        duration: 200.ms,
        curve: Curves.easeIn,
      );
    }

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: (isActive && activeBackgroundColor != null)
                ? activeBackgroundColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              if (showCount && count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  AppFormatters.formatCount(count),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Full Screen Gallery ─────────────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenGallery({
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Gallery
          PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(
                  widget.imageUrls[index],
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(
                  tag: widget.imageUrls[index],
                ),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),

          // Close button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),

          // Page indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

