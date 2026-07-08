import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tweets/presentation/widgets/tweet_card.dart';
import '../providers/profile_provider.dart';

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _bioExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String? _resolvedUserId;

  String get _effectiveUserId => _resolvedUserId ?? widget.userId;

  bool get _isOwnProfile {
    final current = ref.read(currentUserProvider);
    return current?.id == _effectiveUserId;
  }

  @override
  Widget build(BuildContext context) {
    // Resolve 'me' to actual user ID
    final resolvedUserId = widget.userId == 'me'
        ? (ref.read(currentUserProvider)?.id ?? '')
        : widget.userId;
    _resolvedUserId = resolvedUserId;

    if (resolvedUserId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final profileAsync = ref.watch(profileProvider(resolvedUserId));

    return Scaffold(
      backgroundColor: backgroundColor,
      body: profileAsync.when(
        loading: () => _buildShimmerLoading(isDark, surfaceColor),
        error: (error, stack) => _buildErrorState(error, isDark, surfaceColor),
        data: (profile) => _buildProfileContent(profile, isDark, surfaceColor, theme),
      ),
    );
  }

  // ─── Profile Content ─────────────────────────────────────────────────────

  Widget _buildProfileContent(
    UserModel profile,
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // SliverAppBar with cover image
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            elevation: 0,
            backgroundColor: surfaceColor,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCoverImage(profile, isDark),
            ),
          ),

          // Profile header content
          SliverToBoxAdapter(
            child: _buildProfileHeader(profile, isDark, surfaceColor, theme),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: _buildStatsRow(profile, isDark, theme),
          ),

          // Action buttons
          SliverToBoxAdapter(
            child: _buildActionButtons(profile, isDark, surfaceColor, theme),
          ),

          // Tab bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileTabBarDelegate(
              tabController: _tabController,
              isDark: isDark,
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTweetsTab(isDark),
          _buildRepliesTab(isDark),
          _buildLikesTab(isDark),
          _buildMediaTab(isDark),
        ],
      ),
    );
  }

  // ─── Cover Image ─────────────────────────────────────────────────────────

  Widget _buildCoverImage(UserModel profile, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (profile.fullCoverUrl.isNotEmpty)
          CachedNetworkImage(
            imageUrl: profile.fullCoverUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            ),
            errorWidget: (context, url, error) => Container(
              color: isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground,
            ),
          )
        else
          Container(
            color: isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground,
            child: Center(
              child: Icon(
                Icons.image,
                size: 40,
                color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                    .withValues(alpha: 0.3),
              ),
            ),
          ),

        // Bottom gradient overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  isDark
                      ? AppColors.darkSurface.withValues(alpha: 0.8)
                      : AppColors.lightSurface.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Profile Header ──────────────────────────────────────────────────────

  Widget _buildProfileHeader(
    UserModel profile,
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          // Avatar positioned to overlap the cover
          Transform.translate(
            offset: const Offset(0, -35),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: surfaceColor, width: 4),
                  ),
                  child: ClipOval(
                    child: profile.fullAvatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: profile.fullAvatarUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 70,
                              height: 70,
                              color: isDark
                                  ? AppColors.darkSurfaceDark
                                  : AppColors.lightBackground,
                              child: const Icon(Icons.person, size: 30,
                                  color: AppColors.lightTextSecondary),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 70,
                              height: 70,
                              color: isDark
                                  ? AppColors.darkSurfaceDark
                                  : AppColors.lightBackground,
                              child: const Icon(Icons.person, size: 30,
                                  color: AppColors.lightTextSecondary),
                            ),
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            color: isDark
                                ? AppColors.darkSurfaceDark
                                : AppColors.lightBackground,
                            child: Icon(
                              Icons.person,
                              size: 34,
                              color: textSecondary.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Name + verified badge
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Flexible(
                child: Text(
                  profile.displayName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.verified,
                  color: AppColors.verified,
                  size: 22,
                ),
              ],
            ],
          ),

          const SizedBox(height: 4),

          // @username
          Text(
            '@${profile.username}',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),

          // Bio
          if (profile.bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildBio(profile.bio, textPrimary, textSecondary),
          ],

          const SizedBox(height: 10),

          // Location / Website / Join date
          _buildMetaInfo(profile, textSecondary, isDark),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  // ─── Bio with expansion ──────────────────────────────────────────────────

  Widget _buildBio(String bio, Color textPrimary, Color textSecondary) {
    if (bio.length <= 80 || _bioExpanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bio,
            style: TextStyle(
              fontSize: 15,
              color: textPrimary,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          if (bio.length > 80)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _bioExpanded = false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.only(top: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'أقل',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _bioExpanded = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bio,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              color: textPrimary,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          Text(
            'المزيد',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Meta Info (location, website, join date) ────────────────────────────

  Widget _buildMetaInfo(UserModel profile, Color textSecondary, bool isDark) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      textDirection: TextDirection.rtl,
      children: [
        // Location
        if (profile.location.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: textSecondary),
              const SizedBox(width: 4),
              Text(profile.location,
                  style: TextStyle(fontSize: 14, color: textSecondary)),
            ],
          ),

        // Website
        if (profile.website.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.link, size: 16, color: textSecondary),
              const SizedBox(width: 4),
              Text(
                profile.website,
                style: TextStyle(fontSize: 14, color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

        // Join date
        Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(Icons.calendar_today, size: 14, color: textSecondary),
            const SizedBox(width: 4),
            Text(
              'انضم في شهر ${months[profile.createdAt.month - 1]} ${profile.createdAt.year}',
              style: TextStyle(fontSize: 14, color: textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Stats Row ───────────────────────────────────────────────────────────

  Widget _buildStatsRow(UserModel profile, bool isDark, ThemeData theme) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _buildStatItem(
            label: 'المتابَعين',
            value: AppFormatters.formatCount(profile.followersCount),
            valueColor: textPrimary,
            labelColor: textSecondary,
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            label: 'يتابع',
            value: AppFormatters.formatCount(profile.followingCount),
            valueColor: textPrimary,
            labelColor: textSecondary,
          ),
          const SizedBox(width: 20),
          _buildStatItem(
            label: 'التغريدات',
            value: AppFormatters.formatCount(profile.tweetsCount),
            valueColor: textPrimary,
            labelColor: textSecondary,
          ),
        ],
      ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color valueColor,
    required Color labelColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  // ─── Action Buttons ──────────────────────────────────────────────────────

  Widget _buildActionButtons(
    UserModel profile,
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    return Container(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: _isOwnProfile
          ? _buildOwnProfileButtons(isDark, surfaceColor, theme)
          : _buildOtherProfileButtons(profile, isDark, surfaceColor, theme),
    ).animate().fadeIn(delay: 250.ms, duration: 300.ms);
  }

  Widget _buildOwnProfileButtons(
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => context.push('/edit-profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              side: BorderSide(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'تعديل الملف الشخصي',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherProfileButtons(
    UserModel profile,
    bool isDark,
    Color surfaceColor,
    ThemeData theme,
  ) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        // Follow / Unfollow button
        Expanded(
          child: profile.isFollowing
              ? OutlinedButton(
                  onPressed: () {
                    ref
                        .read(profileProvider(_effectiveUserId).notifier)
                        .toggleFollow();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'إلغاء المتابعة',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                )
              : ElevatedButton(
                  onPressed: () {
                    ref
                        .read(profileProvider(_effectiveUserId).notifier)
                        .toggleFollow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'متابعة',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        // Message button
        SizedBox(
          width: 40,
          height: 40,
          child: OutlinedButton(
            onPressed: () {
              context.push('/messages/$_effectiveUserId');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              side: BorderSide(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                width: 1,
              ),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              minimumSize: Size.zero,
            ),
            child: const Icon(Icons.mail_outline, size: 18),
          ),
        ),
      ],
    );
  }

  // ─── Tab Views ───────────────────────────────────────────────────────────

  Widget _buildTweetsTab(bool isDark) {
    final tweetsAsync = ref.watch(userTweetsProvider(_effectiveUserId));

    return tweetsAsync.when(
      loading: () => _buildTabShimmer(isDark),
      error: (e, _) => _buildTabError(e, isDark),
      data: (tweets) {
        if (tweets.isEmpty) {
          return _buildTabEmpty(isDark, 'لم ينشر أي تغريدات بعد');
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: tweets.length,
          itemBuilder: (context, index) {
            final tweet = tweets[index];
            return TweetCard(
              tweet: tweet,
              index: index,
              onTap: () => context.push('/tweet/${tweet.id}'),
              onDelete: (id) => ref.invalidate(userTweetsProvider(_effectiveUserId)),
            );
          },
        );
      },
    );
  }

  Widget _buildRepliesTab(bool isDark) {
    final repliesAsync = ref.watch(userRepliesProvider(_effectiveUserId));

    return repliesAsync.when(
      loading: () => _buildTabShimmer(isDark),
      error: (e, _) => _buildTabError(e, isDark),
      data: (tweets) {
        if (tweets.isEmpty) {
          return _buildTabEmpty(isDark, 'لم يرد على أي تغريدات بعد');
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: tweets.length,
          itemBuilder: (context, index) {
            final tweet = tweets[index];
            return TweetCard(
              tweet: tweet,
              index: index,
              onTap: () => context.push('/tweet/${tweet.id}'),
              onDelete: (id) => ref.invalidate(userRepliesProvider(_effectiveUserId)),
            );
          },
        );
      },
    );
  }

  Widget _buildLikesTab(bool isDark) {
    final likesAsync = ref.watch(userLikesProvider(_effectiveUserId));

    return likesAsync.when(
      loading: () => _buildTabShimmer(isDark),
      error: (e, _) => _buildTabError(e, isDark),
      data: (tweets) {
        if (tweets.isEmpty) {
          return _buildTabEmpty(isDark, 'لا توجد إعجابات بعد');
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: tweets.length,
          itemBuilder: (context, index) {
            final tweet = tweets[index];
            return TweetCard(
              tweet: tweet,
              index: index,
              onTap: () => context.push('/tweet/${tweet.id}'),
              onDelete: (id) => ref.invalidate(userLikesProvider(_effectiveUserId)),
            );
          },
        );
      },
    );
  }

  Widget _buildMediaTab(bool isDark) {
    final mediaAsync = ref.watch(userMediaProvider(_effectiveUserId));

    return mediaAsync.when(
      loading: () => _buildTabShimmer(isDark),
      error: (e, _) => _buildTabError(e, isDark),
      data: (tweets) {
        if (tweets.isEmpty) {
          return _buildTabEmpty(isDark, 'لا توجد وسائط بعد');
        }

        // Grid of media thumbnails
        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: tweets.length,
          itemBuilder: (context, index) {
            final tweet = tweets[index];
            if (tweet.fullMediaUrls.isEmpty) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => context.push('/tweet/${tweet.id}'),
              child: CachedNetworkImage(
                imageUrl: tweet.fullMediaUrls.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark
                      ? AppColors.darkSurfaceDark
                      : AppColors.lightBackground,
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark
                      ? AppColors.darkSurfaceDark
                      : AppColors.lightBackground,
                  child: const Icon(Icons.broken_image, size: 30,
                      color: AppColors.lightTextSecondary),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Tab Shimmer ─────────────────────────────────────────────────────────

  Widget _buildTabShimmer(bool isDark) {
    final boneColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightSurface;
    return Skeletonizer(
      enableSwitchAnimation: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(radius: 22, backgroundColor: boneColor),
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
                      Container(height: 14, width: MediaQuery.of(context).size.width * 0.6, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
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

  Widget _buildTabEmpty(bool isDark, String message) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.article_outlined,
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

  Widget _buildTabError(Object error, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 15,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ref.invalidate(userTweetsProvider(_effectiveUserId));
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  // ─── Shimmer Loading ─────────────────────────────────────────────────────

  Widget _buildShimmerLoading(bool isDark, Color surfaceColor) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 150,
          pinned: true,
          backgroundColor: surfaceColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: Skeletonizer(
            enableSwitchAnimation: true,
            child: Container(color: Colors.white),
          ),
        ),
        SliverToBoxAdapter(
          child: Skeletonizer(
            enableSwitchAnimation: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  // Avatar placeholder
                  Align(
                    alignment: Alignment.centerRight,
                    child: CircleAvatar(radius: 35, backgroundColor: surfaceColor),
                  ),
                  const SizedBox(height: 12),
                  // Name
                  Container(width: 150, height: 22, decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  // Username
                  Container(height: 14, width: 100, decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 10),
                  // Bio lines
                  Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 200, decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 16),
                  // Stats
                  Row(
                    children: List.generate(
                      3,
                      (_) => Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(height: 14, width: 40, decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 4),
                            Container(height: 14, width: 60, decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Button placeholder
                  Container(width: double.infinity, height: 40, decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(24))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState(Object error, bool isDark, Color surfaceColor) {
    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
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
              'حدث خطأ أثناء تحميل الملف الشخصي',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(profileProvider(_effectiveUserId));
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('إعادة المحاولة'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Bar Delegate ─────────────────────────────────────────────────────────

class _ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final bool isDark;

  _ProfileTabBarDelegate({
    required this.tabController,
    required this.isDark,
  });

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      color: surfaceColor,
      child: TabBar(
        controller: tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor:
            isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        unselectedLabelColor:
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        labelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        dividerColor: isDark ? AppColors.darkBorder : AppColors.lightDivider,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(text: 'التغريدات'),
          Tab(text: 'الردود'),
          Tab(text: 'الإعجابات'),
          Tab(text: 'الوسائط'),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_ProfileTabBarDelegate oldDelegate) {
    return oldDelegate.tabController != tabController ||
        oldDelegate.isDark != isDark;
  }
}