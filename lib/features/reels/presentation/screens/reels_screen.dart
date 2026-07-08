import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/colors.dart';

// ─── Reel Data Model ──────────────────────────────────────────────────────────

class _ReelData {
  final String username;
  final String displayName;
  final String caption;
  final String avatarUrl;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final List<Color> gradientColors;

  const _ReelData({
    required this.username,
    required this.displayName,
    required this.caption,
    this.avatarUrl = '',
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.gradientColors,
  });
}

// ─── Sample Reels ─────────────────────────────────────────────────────────────

final List<_ReelData> _sampleReels = [
  _ReelData(
    username: 'ahmed_travels',
    displayName: 'أحمد المسافر',
    caption: 'غروب الشمس في مكة المكرمة 🌅 لا يوجد أجمل من هذا المنظر',
    likeCount: 15200,
    commentCount: 342,
    shareCount: 89,
    gradientColors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
  ),
  _ReelData(
    username: 'sara_cooks',
    displayName: 'سارة المطبخ',
    caption: 'وصفة الكنافة النابلسية الأصلية 🧁 جربوها وقولولي رأيكم',
    likeCount: 8400,
    commentCount: 512,
    shareCount: 234,
    gradientColors: [Color(0xFF2d1b69), Color(0xFF5c3d99), Color(0xFFe8a87c)],
  ),
  _ReelData(
    username: 'omar_tech',
    displayName: 'عمر التقني',
    caption: 'مراجعة أحدث هاتف ذكي 📱 المواصفات مذهلة والسعر مناسب',
    likeCount: 22000,
    commentCount: 1893,
    shareCount: 567,
    gradientColors: [Color(0xFF0c0c0c), Color(0xFF1a1a2e), Color(0xFFe94560)],
  ),
  _ReelData(
    username: 'layla_art',
    displayName: 'ليلى الفنانة',
    caption: 'رسم بالخط العربي على القماش 🎨 كل قطعة فنية تحكي قصة',
    likeCount: 31500,
    commentCount: 721,
    shareCount: 342,
    gradientColors: [Color(0xFF141E30), Color(0xFF243B55), Color(0xFF4a90d9)],
  ),
  _ReelData(
    username: 'khaled_sport',
    displayName: 'خالد الرياضي',
    caption: 'تمارين منزلية لمدة 10 دقائق 💪 بدون معدات فقط إرادتك',
    likeCount: 43000,
    commentCount: 2150,
    shareCount: 890,
    gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d), Color(0xFF0f3443)],
  ),
];

// ─── Reels Screen ─────────────────────────────────────────────────────────────

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _sampleReels.length,
            itemBuilder: (context, index) {
              return _ReelPage(
                reel: _sampleReels[index],
                index: index,
              );
            },
          ),

          // Top progress bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _buildProgressBar(),
          ),

          // Bottom navigation hint
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'اسحب للأعلى للمحتوى التالي',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress Bar ─────────────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _sampleReels.length,
        (index) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reel Page ────────────────────────────────────────────────────────────────

class _ReelPage extends StatefulWidget {
  final _ReelData reel;
  final int index;

  const _ReelPage({required this.reel, required this.index});

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage> {
  bool _isLiked = false;
  bool _isBookmarked = false;
  bool _showHeart = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.reel.likeCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  void _onDoubleTap() {
    setState(() {
      _showHeart = true;
      if (!_isLiked) {
        _isLiked = true;
        _likeCount++;
      }
    });

    // Hide heart after animation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: reel.gradientColors,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative circles (since we don't have real video)
            ..._buildDecorativeElements(reel.gradientColors),

            // Double tap heart animation
            if (_showHeart)
              Center(
                child: Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 100,
                ).animate().scale(
                      begin: const Offset(0.2, 0.2),
                      end: const Offset(1.2, 1.2),
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    ).then()
                      .fadeOut(duration: 400.ms, delay: 200.ms),
              ),

            // Bottom gradient overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
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
                  // Like
                  _buildActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? AppColors.like : Colors.white,
                    count: _formatCount(_likeCount),
                    onTap: _toggleLike,
                  ),
                  const SizedBox(height: 20),
                  // Comment
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    color: Colors.white,
                    count: _formatCount(reel.commentCount),
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  // Share
                  _buildActionButton(
                    icon: Icons.send_outlined,
                    color: Colors.white,
                    count: _formatCount(reel.shareCount),
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  // Bookmark
                  _buildActionButton(
                    icon: _isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: _isBookmarked ? AppColors.warning : Colors.white,
                    count: '',
                    onTap: () {
                      setState(() => _isBookmarked = !_isBookmarked);
                    },
                  ),
                ],
              ).animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideX(begin: -0.2, end: 0, duration: 400.ms),
            ),

            // Bottom content overlay
            Positioned(
              right: 16,
              left: 70,
              bottom: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                textDirection: TextDirection.rtl,
                children: [
                  // Username
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            reel.displayName.isNotEmpty
                                ? reel.displayName[0]
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '@${reel.username}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Caption
                  Text(
                    reel.caption,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.4,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ).animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms)
                  .slideY(begin: 0.15, end: 0, duration: 400.ms),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Action Button ───────────────────────────────────────────────────────

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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        if (count.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Decorative Elements ─────────────────────────────────────────────────

  List<Widget> _buildDecorativeElements(List<Color> colors) {
    return [
      // Large decorative circle
      Positioned(
        top: -50,
        right: -80,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[colors.length - 1].withValues(alpha: 0.15),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: 3000.ms,
            ),
      ),
      // Small decorative circle
      Positioned(
        bottom: 200,
        left: 80,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors[1].withValues(alpha: 0.12),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.15, 1.15),
              duration: 4000.ms,
            ),
      ),
      // Tiny accent dots
      Positioned(
        top: 150,
        left: 30,
        child: _buildDot(8, colors[0]).animate(
            onPlay: (c) => c.repeat()).fadeIn(duration: 1500.ms),
      ),
      Positioned(
        top: 250,
        left: 160,
        child: _buildDot(6, colors[1]).animate(
            onPlay: (c) => c.repeat(reverse: true)).scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.5, 1.5),
              duration: 2000.ms,
            ),
      ),
      Positioned(
        bottom: 350,
        right: 100,
        child: _buildDot(10, colors[2]).animate(
            onPlay: (c) => c.repeat()).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.2, 1.2),
              duration: 2500.ms,
            ),
      ),
      // Sample content label
      Positioned(
        top: MediaQuery.of(context).padding.top + 30,
        right: 16,
        child: Text(
          'Reels',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            shadows: const [
              Shadow(color: Colors.black54, blurRadius: 8),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
      ),
    ];
  }

  Widget _buildDot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.3),
      ),
    );
  }
}