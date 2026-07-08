import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../tweets/presentation/widgets/tweet_card.dart';
import '../providers/search_provider.dart';

// ─── Search Screen ────────────────────────────────────────────────────────────

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  late final TabController _tabController;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    ref.read(searchQueryProvider.notifier).updateQuery(query);

    final showResults = query.trim().isNotEmpty;
    if (showResults != _showResults) {
      setState(() => _showResults = showResults);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).updateQuery('');
    setState(() => _showResults = false);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(isDark, surfaceColor),

          // Content
          Expanded(
            child: _showResults
                ? _buildSearchResults(isDark, surfaceColor, theme)
                : _buildTrendingSection(isDark, surfaceColor, theme),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ──────────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark, Color surfaceColor) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final fillColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Container(
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, size: 20, color: textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontSize: 16,
                    color: textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث في عرب تغريدات',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (_) {
                    // Handled by listener
                  },
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: _clearSearch,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: textSecondary,
                  ),
                ),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  // ─── Trending Section ────────────────────────────────────────────────────

  Widget _buildTrendingSection(
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    final trendingAsync = ref.watch(trendingProvider);

    return Container(
      color: surfaceColor,
      child: trendingAsync.when(
        loading: () => _buildTrendingShimmer(isDark),
        error: (_, _) => _buildTrendingError(isDark),
        data: (hashtags) {
          if (hashtags.isEmpty) {
            return _buildTrendingEmpty(isDark);
          }
          return _buildTrendingList(hashtags, isDark, theme);
        },
      ),
    );
  }

  Widget _buildTrendingList(
    List<dynamic> hashtags,
    bool isDark,
    ThemeData theme,
  ) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return ListView.separated(
      itemCount: hashtags.length,
      separatorBuilder: (_, _) => Divider(
        height: 0.5,
        thickness: 0.5,
        color: dividerColor,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final tag = hashtags[index];
        return InkWell(
          onTap: () {
            _searchController.text = '#${tag.tag}';
            ref.read(searchQueryProvider.notifier).updateQuery('#${tag.tag}');
            setState(() => _showResults = true);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            '#${tag.tag}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.local_fire_department,
                            size: 20,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppFormatters.formatCount(tag.tweetCount)} تغريدة',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(
              delay: Duration(milliseconds: index * 50),
              duration: 300.ms,
            );
      },
    );
  }

  Widget _buildTrendingShimmer(bool isDark) {
    final boneColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightSurface;
    return Skeletonizer(
      enableSwitchAnimation: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Container(height: 14, width: 180, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(height: 14, width: 100, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingEmpty(bool isDark) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            size: 56,
            color: textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد وسوم رائجة حاليًا',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildTrendingError(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(trendingProvider),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // ─── Search Results ──────────────────────────────────────────────────────

  Widget _buildSearchResults(
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      children: [
        // Tab bar
        Container(
          color: surfaceColor,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: textPrimary,
            unselectedLabelColor: textSecondary,
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
            dividerColor:
                isDark ? AppColors.darkBorder : AppColors.lightDivider,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(text: 'الأشخاص'),
              Tab(text: 'التغريدات'),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPeopleResults(isDark, surfaceColor, theme),
              _buildTweetResults(isDark, surfaceColor, theme),
            ],
          ),
        ),
      ],
    );
  }

  // ─── People Results ──────────────────────────────────────────────────────

  Widget _buildPeopleResults(
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    final searchAsync = ref.watch(searchResultsProvider);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return searchAsync.when(
      data: (results) {
        if (results.users.isEmpty) {
          return _buildNoResults(isDark, 'لا توجد نتائج');
        }
        return ListView.separated(
          itemCount: results.users.length,
          separatorBuilder: (_, _) => Divider(
            height: 0.5,
            thickness: 0.5,
            color: dividerColor,
            indent: 80,
          ),
          itemBuilder: (context, index) {
            final user = results.users[index];
            return _buildPersonTile(
              user,
              isDark,
              textPrimary,
              textSecondary,
              surfaceColor,
              index,
            );
          },
        );
      },
      loading: () => _buildResultsShimmer(isDark),
      error: (_, _) => _buildNoResults(isDark, 'لا توجد نتائج'),
    );
  }

  Widget _buildPersonTile(
    UserModel user,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    int index,
  ) {
    return InkWell(
      onTap: () => context.push('/profile/${user.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Avatar
            ClipOval(
              child: user.fullAvatarUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.fullAvatarUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        color: isDark
                            ? AppColors.darkSurfaceDark
                            : AppColors.lightBackground,
                        child: const Icon(Icons.person, size: 22),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: isDark
                            ? AppColors.darkSurfaceDark
                            : AppColors.lightBackground,
                        child: const Icon(Icons.person, size: 22),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: isDark
                          ? AppColors.darkSurfaceDark
                          : AppColors.lightBackground,
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppColors.verified,
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        height: 1.3,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Follow button
            SizedBox(
              height: 34,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await Supabase.instance.client.rpc('toggle_follow', params: {
                      'p_follower_id': Supabase.instance.client.auth.currentUser!.id,
                      'p_following_id': user.id,
                    });
                    ref.invalidate(searchResultsProvider);
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.isFollowing
                      ? Colors.transparent
                      : AppColors.primary,
                  foregroundColor: user.isFollowing
                      ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)
                      : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: user.isFollowing
                        ? BorderSide(
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Text(
                  user.isFollowing ? 'يتابع' : 'متابعة',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: Duration(milliseconds: index * 40),
          duration: 250.ms,
        );
  }

  // ─── Tweet Results ───────────────────────────────────────────────────────

  Widget _buildTweetResults(
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    final searchAsync = ref.watch(searchResultsProvider);

    return searchAsync.when(
      data: (results) {
        if (results.tweets.isEmpty) {
          return _buildNoResults(isDark, 'لا توجد نتائج');
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: results.tweets.length,
          itemBuilder: (context, index) {
            final tweet = results.tweets[index];
            return TweetCard(
              tweet: tweet,
              index: index,
              onTap: () => context.push('/tweet/${tweet.id}'),
            );
          },
        );
      },
      loading: () => _buildResultsShimmer(isDark),
      error: (_, _) => _buildNoResults(isDark, 'لا توجد نتائج'),
    );
  }

  // ─── Shared Widgets ──────────────────────────────────────────────────────

  Widget _buildNoResults(bool isDark, String message) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 56,
            color: textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildResultsShimmer(bool isDark) {
    final boneColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightSurface;
    return Skeletonizer(
      enableSwitchAnimation: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(radius: 24, backgroundColor: boneColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(height: 14, width: 120, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(height: 14, width: MediaQuery.of(context).size.width * 0.5, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}