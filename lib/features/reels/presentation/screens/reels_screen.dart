import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';
import '../../data/models/reel_model.dart';
import '../providers/reels_provider.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: reelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white54)),
        error: (_, __) => _buildEmptyState(isDark),
        data: (reels) {
          if (reels.isEmpty) return _buildEmptyState(isDark);
          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: reels.length,
                onPageChanged: (index) {
                  if (index >= reels.length - 2) {
                    ref.read(reelsProvider.notifier).loadMore();
                  }
                },
                itemBuilder: (context, index) {
                  return _ReelPage(
                    reel: reels[index],
                    formatCount: _formatCount,
                    onLike: () => ref.read(reelsProvider.notifier).toggleLike(reels[index].id),
                    onProfileTap: () => context.push('/profile/${reels[index].userId}'),
                  );
                },
              ),
              // Top bar
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'ريلز',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.textPrimary(isDark).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.video_library_outlined, size: 56, color: AppColors.textPrimary(isDark)),
          ),
          const SizedBox(height: 24),
          Text(
            'لا يوجد ريلز بعد',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'كن أول من ينشر ريلز على AdenTweet',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Open reel creation screen
            },
            icon: Icon(Icons.add, color: isDark ? Colors.black : Colors.white),
            label: Text('إنشاء ريلز', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelPage extends StatefulWidget {
  final ReelModel reel;
  final String Function(int) formatCount;
  final VoidCallback onLike;
  final VoidCallback onProfileTap;

  const _ReelPage({
    required this.reel,
    required this.formatCount,
    required this.onLike,
    required this.onProfileTap,
  });

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  bool _showHeart = false;

  void _onDoubleTap() {
    setState(() {
      _showHeart = true;
      if (!widget.reel.isLiked) widget.onLike();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final hasThumbnail = reel.fullThumbnailUrl.isNotEmpty;

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail/Video placeholder
            if (hasThumbnail)
              CachedNetworkImage(
                imageUrl: reel.fullThumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white38)),
                errorWidget: (_, __, ___) => _buildVideoPlaceholder(reel),
              )
            else
              _buildVideoPlaceholder(reel),

            // Double tap heart
            if (_showHeart)
              Center(
                child: Icon(Icons.favorite, color: Colors.white, size: 100)
                    .animate()
                    .scale(begin: const Offset(0.2, 0.2), end: const Offset(1.2, 1.2), duration: 300.ms, curve: Curves.easeOutBack)
                    .then()
                    .fadeOut(duration: 400.ms, delay: 200.ms),
              ),

            // Bottom gradient
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  ),
                ),
              ),
            ),

            // Right side action buttons
            Positioned(
              left: 12,
              bottom: 120,
              child: Column(
                children: [
                  _buildActionButton(
                    icon: reel.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: reel.isLiked ? AppColors.like : Colors.white,
                    count: widget.formatCount(reel.likeCount),
                    onTap: widget.onLike,
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.white,
                    count: widget.formatCount(reel.commentCount),
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.send_outlined,
                    color: Colors.white,
                    count: widget.formatCount(reel.shareCount),
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.remove_red_eye_outlined,
                    color: Colors.white.withValues(alpha: 0.8),
                    count: widget.formatCount(reel.viewCount),
                    onTap: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideX(begin: -0.2, end: 0, duration: 400.ms),
            ),

            // Bottom content
            Positioned(
              right: 16, left: 70, bottom: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                textDirection: TextDirection.rtl,
                children: [
                  // User info
                  GestureDetector(
                    onTap: widget.onProfileTap,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          backgroundImage: reel.fullAvatarUrl.isNotEmpty ? CachedNetworkImageProvider(reel.fullAvatarUrl) : null,
                          child: reel.fullAvatarUrl.isEmpty
                              ? Text(reel.displayName.isNotEmpty ? reel.displayName[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('@${reel.username}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                if (reel.isVerified) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.verified, color: AppColors.primary, size: 16),
                                ],
                              ],
                            ),
                            if (reel.isFollowing)
                              const SizedBox(height: 2),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (reel.caption.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      reel.caption,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.4,
                        shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.15, end: 0, duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder(ReelModel reel) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white24, Colors.black87],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white54, size: 64),
            const SizedBox(height: 8),
            Text(
              reel.caption.isNotEmpty ? reel.caption.substring(0, reel.caption.length > 40 ? 40 : null) : 'ريلز',
              style: const TextStyle(color: Colors.white54, fontSize: 16),
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String count,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        if (count.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}