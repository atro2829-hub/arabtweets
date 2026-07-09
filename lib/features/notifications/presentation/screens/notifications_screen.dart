import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/notification_model.dart';
import '../providers/notifications_provider.dart';

// ─── Notifications Screen ─────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Auto mark as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).markAsRead();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text(
          'الإشعارات',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: _buildTabBar(isDark),
      ),
      body: notificationsAsync.when(
        loading: () => _buildShimmerLoading(isDark),
        error: (error, _) => _buildErrorState(error, isDark),
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(
                notifications: notifications,
                isDark: isDark,
                surfaceColor: surfaceColor,
              ),
              _buildNotificationList(
                notifications: notifications
                    .where((n) =>
                        n.type == AppConstants.notifMention ||
                        n.type == AppConstants.notifReply)
                    .toList(),
                isDark: isDark,
                surfaceColor: surfaceColor,
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildTabBar(bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightDivider;

    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.textPrimary(isDark),
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
      dividerColor: dividerColor,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: const [
        Tab(text: 'الكل'),
        Tab(text: 'الإشارات'),
      ],
    );
  }

  // ─── Notification List ───────────────────────────────────────────────────

  Widget _buildNotificationList({
    required List<NotificationModel> notifications,
    required bool isDark,
    required Color surfaceColor,
  }) {
    if (notifications.isEmpty) {
      return _buildEmptyState(isDark);
    }

    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (_, __) => Divider(
        height: 0.5,
        thickness: 0.5,
        color: dividerColor,
        indent: 68,
      ),
      itemBuilder: (context, index) {
        final notif = notifications[index];
        return _buildNotificationTile(
          notif: notif,
          isDark: isDark,
          surfaceColor: surfaceColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          index: index,
        );
      },
    );
  }

  // ─── Notification Tile ───────────────────────────────────────────────────

  Widget _buildNotificationTile({
    required NotificationModel notif,
    required bool isDark,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required int index,
  }) {
    final iconData = _getNotificationIcon(notif.type);
    final iconColor = _getNotificationColor(notif.type);
    final timeText = AppFormatters.formatTimeAgo(notif.createdAt);

    return InkWell(
      onTap: () {
        if (notif.tweetId != null) {
          context.push('/tweet/${notif.tweetId}');
        } else if (notif.type == AppConstants.notifFollow) {
          context.push('/profile/${notif.fromUserId}');
        }
      },
      child: Container(
        color: notif.isRead
            ? Colors.transparent
            : (isDark
                ? AppColors.textPrimary(isDark).withValues(alpha: 0.05)
                : AppColors.textPrimary(isDark).withValues(alpha: 0.05)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar with unread indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Type icon background circle
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Avatar
                ClipOval(
                  child: notif.fullAvatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: notif.fullAvatarUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 36,
                            height: 36,
                            color: isDark
                                ? AppColors.darkSurfaceDark
                                : AppColors.lightBackground,
                            child: const Icon(Icons.person, size: 16),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 36,
                            height: 36,
                            color: isDark
                                ? AppColors.darkSurfaceDark
                                : AppColors.lightBackground,
                            child: const Icon(Icons.person, size: 16),
                          ),
                        )
                      : Container(
                          width: 36,
                          height: 36,
                          color: isDark
                              ? AppColors.darkSurfaceDark
                              : AppColors.lightBackground,
                          child: Icon(
                            Icons.person,
                            size: 18,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                ),

                // Unread blue dot
                if (!notif.isRead)
                  Positioned(
                    bottom: -1,
                    left: -1,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary(isDark),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: surfaceColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Notification text + tweet preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  // Main text
                  RichText(
                    textDirection: TextDirection.rtl,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: textPrimary,
                        height: 1.35,
                      ),
                      children: [
                        // Icon for type
                        WidgetSpan(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Icon(
                              iconData,
                              size: 16,
                              color: iconColor,
                            ),
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 4)),
                        // Username in blue bold
                        TextSpan(
                          text: '@${notif.fromUsername}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary(isDark),
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 4)),
                        // Action text
                        TextSpan(
                          text: notif.typeText,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Time ago
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),

                  // Tweet content preview
                  if (notif.tweetContent != null &&
                      notif.tweetContent!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceDark
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        notif.tweetContent!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                          height: 1.3,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ],
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

  // ─── Notification Icon & Color ───────────────────────────────────────────

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case AppConstants.notifLike:
        return Icons.favorite;
      case AppConstants.notifRetweet:
        return Icons.repeat;
      case AppConstants.notifFollow:
        return Icons.person_add;
      case AppConstants.notifReply:
        return Icons.chat_bubble_outline;
      case AppConstants.notifMention:
        return Icons.alternate_email;
      case AppConstants.notifMessage:
        return Icons.mail_outline;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case AppConstants.notifLike:
        return AppColors.like;
      case AppConstants.notifRetweet:
        return AppColors.retweet;
      case AppConstants.notifFollow:
        return AppColors.primary;
      case AppConstants.notifReply:
        return AppColors.primary;
      case AppConstants.notifMention:
        return AppColors.primary;
      case AppConstants.notifMessage:
        return AppColors.message;
      default:
        return AppColors.primary;
    }
  }

  // ─── Shimmer Loading ─────────────────────────────────────────────────────

  Widget _buildShimmerLoading(bool isDark) {
    final boneColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightSurface;
    return Skeletonizer(
      enableSwitchAnimation: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(radius: 18, backgroundColor: boneColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(height: 14, width: 200, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(height: 14, width: 80, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
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

  // ─── Empty State ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'ليس لديك إشعارات بعد',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'عندما يتفاعل الأشخاص مع تغريداتك، ستظهر الإشعارات هنا',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms);
  }

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildErrorState(Object error, bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Center(
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
            'حدث خطأ أثناء تحميل الإشعارات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(notificationsProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary(isDark),
              side: BorderSide(color: AppColors.textPrimary(isDark)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}