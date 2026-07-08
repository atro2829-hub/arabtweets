import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../data/models/tweet_model.dart';
import '../providers/feed_provider.dart';
import '../widgets/tweet_card.dart';
import '../widgets/compose_tweet_sheet.dart';

// ─── Home Feed Screen ────────────────────────────────────────────────────────

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Detect near-bottom scroll for infinite loading.
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_hasScrolledToBottom) {
      _hasScrolledToBottom = true;
      _loadMore();
    }
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 400) {
      _hasScrolledToBottom = false;
    }
  }

  Future<void> _loadMore() async {
    final notifier = ref.read(feedProvider.notifier);
    if (!notifier.hasMore || notifier.isLoadingMore) return;
    await notifier.loadMore();
  }

  Future<void> _onRefresh() async {
    try {
      await ref.read(feedProvider.notifier).refresh();
      _refreshController.refreshCompleted();
    } catch (e) {
      _refreshController.refreshFailed();
    }
  }

  Future<void> _openComposeSheet() async {
    await ComposeTweetSheet.show(context: context);
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;

    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(theme, isDark),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(theme, isDark),

          // Feed content
          Expanded(
            child: feedAsync.when(
              loading: () => _buildShimmerLoading(isDark),
              error: (error, stack) => _buildErrorState(error, isDark),
              data: (tweets) {
                if (tweets.isEmpty) {
                  return _buildEmptyState(theme, isDark);
                }
                return _buildFeedList(tweets, isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      title: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Arabtweets icon/logo on the right (RTL)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'عرب تغريدات',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
        ],
      ),
      actions: [
        // Star/flash icon for "للأعلى" tab on the left (RTL)
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () {
              // Navigate to "for you" or trending
            },
            icon: const Icon(Icons.star_outline, size: 24),
          ),
        ),
      ],
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        unselectedLabelColor: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'لك'),
          Tab(text: 'الأحدث'),
        ],
      ),
    );
  }

  // ── Feed List ──────────────────────────────────────────────────────────

  Widget _buildFeedList(List<TweetModel> tweets, bool isDark) {
    final notifier = ref.read(feedProvider.notifier);

    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      onRefresh: _onRefresh,
      header: CustomHeader(
        height: 60,
        builder: (context, mode) {
          return Container(
            height: 60,
            alignment: Alignment.center,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          );
        },
      ),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: tweets.length + (notifier.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading more indicator at the bottom
          if (index >= tweets.length) {
            return _buildLoadingMoreIndicator();
          }

          final tweet = tweets[index];
          return TweetCard(
            tweet: tweet,
            index: index,
            onLike: (id) => ref.read(feedProvider.notifier).toggleLike(id),
            onRetweet: (id) =>
                ref.read(feedProvider.notifier).toggleRetweet(id),
            onReply: (id) {
              ComposeTweetSheet.show(context: context, parentId: id);
            },
            onBookmark: (id) =>
                ref.read(feedProvider.notifier).toggleBookmark(id),
            onDelete: (id) => ref.invalidate(feedProvider),
            onTap: () {
              // Navigate to tweet detail
              context.push('/tweet/${tweet.id}');
            },
          );
        },
      ),
    );
  }

  // ── Skeleton Loading ───────────────────────────────────────────────────

  Widget _buildShimmerLoading(bool isDark) {
    return Skeletonizer(
      enableSwitchAnimation: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) => _buildShimmerSkeletonItem(isDark),
      ),
    );
  }

  Widget _buildShimmerSkeletonItem(bool isDark) {
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final boneColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightSurface;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              // Avatar placeholder
              CircleAvatar(radius: 22, backgroundColor: boneColor),
              const SizedBox(width: 12),

              // Content placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    // Name row
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(height: 14, width: 80, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 8),
                        Container(height: 14, width: 60, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Content lines
                    Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.4,
                      decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 14),
                    // Media placeholder
                    Container(height: 180, width: double.infinity, decoration: BoxDecoration(color: boneColor, borderRadius: const BorderRadius.all(Radius.circular(16)))),
                    const SizedBox(height: 12),
                    // Actions row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (_) => Container(width: 50, height: 20, decoration: BoxDecoration(color: boneColor, borderRadius: const BorderRadius.all(Radius.circular(4)))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 0.5, thickness: 0.5, color: dividerColor),
      ],
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    final textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.feed_outlined,
            size: 64,
            color: textColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد تغريدات بعد',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تابع أشخاصًا لرؤية تغريداتهم هنا',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openComposeSheet,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('اكتب تغريدة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  // ── Error State ────────────────────────────────────────────────────────

  Widget _buildErrorState(Object error, bool isDark) {
    final textColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ أثناء تحميل التغريدات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(feedProvider);
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة المحاولة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  // ── Loading More Indicator ─────────────────────────────────────────────

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ── FAB ────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _openComposeSheet,
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.edit, size: 24, color: Colors.white),
    ).animate().scale(duration: 300.ms, curve: Curves.elasticOut);
  }
}