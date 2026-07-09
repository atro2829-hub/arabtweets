import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../data/models/tweet_model.dart';
import '../providers/feed_provider.dart';
import '../widgets/tweet_card.dart';
import '../widgets/compose_tweet_sheet.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});
  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> with SingleTickerProviderStateMixin {
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

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_hasScrolledToBottom) {
      _hasScrolledToBottom = true;
      final notifier = ref.read(feedProvider.notifier);
      if (!notifier.hasMore || notifier.isLoadingMore) return;
      notifier.loadMore();
    }
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 400) _hasScrolledToBottom = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Row(
          textDirection: TextDirection.rtl,
          children: [
            SvgPicture.asset(AppIcons.logo, width: 30, height: 30),
            const SizedBox(width: 8),
            Text('AdenTweet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 19)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(AppIcons.compose, width: 24, height: 24, colorFilter: ColorFilter.mode(AppColors.textPrimary(isDark), BlendMode.srcIn)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: AppColors.background(isDark),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.textPrimary(isDark),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: 'لك'),
                Tab(text: 'الأحدث'),
              ],
            ),
          ),
          // Feed
          Expanded(
            child: feedAsync.when(
              loading: () => _buildShimmerLoading(isDark),
              error: (error, _) => _buildErrorState(error, isDark),
              data: (tweets) {
                if (tweets.isEmpty) return _buildEmptyState(isDark);
                return _buildFeedList(tweets, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedList(List<TweetModel> tweets, bool isDark) {
    final notifier = ref.read(feedProvider.notifier);
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: false,
      onRefresh: () async {
        try { await ref.read(feedProvider.notifier).refresh(); _refreshController.refreshCompleted(); }
        catch (_) { _refreshController.refreshFailed(); }
      },
      header: CustomHeader(
        height: 60,
        builder: (_, __) => Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textSecondary(isDark)))),
      ),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        itemCount: tweets.length + (notifier.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= tweets.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary(isDark)))),
            );
          }
          return TweetCard(
            tweet: tweets[index], index: index,
            onLike: (id) => ref.read(feedProvider.notifier).toggleLike(id),
            onRetweet: (id) => ref.read(feedProvider.notifier).toggleRetweet(id),
            onReply: (id) => ComposeTweetSheet.show(context: context, parentId: id),
            onBookmark: (id) => ref.read(feedProvider.notifier).toggleBookmark(id),
            onTap: () => context.push('/tweet/${tweets[index].id}'),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return Skeletonizer(
      enableSwitchAnimation: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(radius: 22, backgroundColor: AppColors.card(isDark)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Row(textDirection: TextDirection.rtl, children: [
                    Container(height: 14, width: 80, decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 8),
                    Container(height: 14, width: 60, decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(4))),
                  ]),
                  const SizedBox(height: 10),
                  Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(height: 14, width: MediaQuery.of(context).size.width * 0.7, decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Container(height: 180, width: double.infinity, decoration: BoxDecoration(color: AppColors.card(isDark), borderRadius: BorderRadius.circular(16))),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(AppIcons.compose, width: 56, height: 56, colorFilter: ColorFilter.mode(AppColors.textTertiary(isDark), BlendMode.srcIn)),
          const SizedBox(height: 20),
          Text('لا توجد تغريدات بعد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
          const SizedBox(height: 8),
          Text('تابع أشخاصًا لرؤية تغريداتهم هنا', style: TextStyle(fontSize: 14, color: AppColors.textSecondary(isDark))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ComposeTweetSheet.show(context: context),
            icon: SvgPicture.asset(AppIcons.compose, width: 18, height: 18, colorFilter: const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcIn)),
            label: const Text('اكتب تغريدة الأولى'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('غير متصل بالإنترنت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
            const SizedBox(height: 8),
            Text('يتم عرض البيانات المخزنة مؤقتًا', style: TextStyle(fontSize: 13, color: AppColors.textSecondary(isDark))),
          ],
        ),
      ),
    );
  }
}