import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/admin_provider.dart';

// ─── Admin Dashboard Screen ────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final isAdminAsync = ref.watch(isAdminAsyncProvider);

    return isAdminAsync.when(
      loading: () => Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => Scaffold(
        backgroundColor: backgroundColor,
        body: _buildNoPermission(isDark, textPrimary, textSecondary),
      ),
      data: (isAdmin) {
        if (!isAdmin) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: _buildNoPermission(isDark, textPrimary, textSecondary),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: surfaceColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_forward, color: textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              'لوحة الإدارة',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: textPrimary,
              ),
            ),
            centerTitle: true,
            bottom: _buildTabBar(isDark, textPrimary, textSecondary),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersTab(isDark, surfaceColor, textPrimary, textSecondary),
              _buildTweetsTab(isDark, surfaceColor, textPrimary, textSecondary),
              _buildReportsTab(isDark, surfaceColor, textPrimary, textSecondary),
            ],
          ),
        );
      },
    );
  }

  // ─── No Permission ───────────────────────────────────────────────────────

  Widget _buildNoPermission(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.admin_panel_settings_outlined,
              size: 64, color: textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'ليس لديك صلاحية',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'هذه الصفحة متاحة للمسؤولين فقط',
            style: TextStyle(fontSize: 14, color: textSecondary),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildTabBar(
      bool isDark, Color textPrimary, Color textSecondary) {
    final dividerColor = isDark ? AppColors.darkBorder : AppColors.lightDivider;
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.primary,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: textPrimary,
      unselectedLabelColor: textSecondary,
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
      dividerColor: dividerColor,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      tabs: const [
        Tab(text: 'المستخدمين'),
        Tab(text: 'التغريدات'),
        Tab(text: 'البلاغات'),
      ],
    );
  }

  // ─── Users Tab ───────────────────────────────────────────────────────────

  Widget _buildUsersTab(bool isDark, Color surfaceColor, Color textPrimary,
      Color textSecondary) {
    final usersAsync = ref.watch(allUsersProvider);

    return usersAsync.when(
      loading: () => _buildShimmerLoading(isDark),
      error: (error, _) => _buildError(error, textPrimary, textSecondary),
      data: (users) {
        if (users.isEmpty) {
          return _buildEmpty('لا يوجد مستخدمين بعد', isDark, textSecondary);
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(allUsersProvider.notifier).refresh(),
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserTile(
                  user, isDark, surfaceColor, textPrimary, textSecondary, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, bool isDark,
      Color surfaceColor, Color textPrimary, Color textSecondary, int index) {
    final avatarUrl = user['avatar_url'] as String? ?? '';
    final displayName = user['display_name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final tweetsCount = user['tweets_count'] as int? ?? 0;
    final followersCount = user['followers_count'] as int? ?? 0;
    final isVerified = user['is_verified'] as bool? ?? false;
    final isAdmin = user['is_admin'] as bool? ?? false;
    final isBanned = user['is_banned'] as bool? ?? false;
    final userId = user['id'] as String;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final fullAvatar = avatarUrl.isEmpty
        ? ''
        : avatarUrl.startsWith('http')
            ? avatarUrl
            : 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$avatarUrl';

    return InkWell(
      onTap: () => context.push('/profile/$userId'),
      child: Container(
        color: surfaceColor,
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  // Avatar
                  ClipOval(
                    child: fullAvatar.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: fullAvatar,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 44,
                              height: 44,
                              color: isDark
                                  ? AppColors.darkSurfaceDark
                                  : AppColors.lightBackground,
                              child: Icon(Icons.person,
                                  size: 20, color: textSecondary),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: isDark
                                  ? AppColors.darkSurfaceDark
                                  : AppColors.lightBackground,
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 22,
                            backgroundColor: isDark
                                ? AppColors.darkSurfaceDark
                                : AppColors.lightBackground,
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Info
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
                                displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.verified,
                                  size: 16, color: AppColors.verified),
                            ],
                            if (isAdmin) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.shield,
                                  size: 16, color: AppColors.warning),
                            ],
                            if (isBanned) ...[
                              const SizedBox(width: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'محظور',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: TextStyle(
                              fontSize: 13, color: textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${AppFormatters.formatCount(tweetsCount)} تغريدة · ${AppFormatters.formatCount(followersCount)} متابع',
                          style: TextStyle(
                              fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Actions
                  _buildActionButtons(
                      userId, isVerified, isAdmin, isBanned, textSecondary),
                ],
              ),
            ),
            Divider(height: 0.5, thickness: 0.5, color: dividerColor),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 30), duration: 250.ms);
  }

  Widget _buildActionButtons(String userId, bool isVerified, bool isAdmin,
      bool isBanned, Color textSecondary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle verified
        IconButton(
          icon: Icon(
            isVerified ? Icons.verified : Icons.check_circle_outline,
            color: isVerified ? AppColors.verified : textSecondary,
            size: 20,
          ),
          onPressed: () => _showConfirmDialog(
            title: isVerified ? 'إزالة التحقق' : 'تفعيل التحقق',
            message: isVerified
                ? 'هل تريد إزالة علامة التحقق من هذا المستخدم؟'
                : 'هل تريد إضافة علامة التحقق لهذا المستخدم؟',
            onConfirm: () =>
                toggleVerified(ref, userId, !isVerified),
          ),
          splashRadius: 20,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip: 'تحقق',
        ),
        // Toggle admin
        IconButton(
          icon: Icon(
            Icons.shield,
            color: isAdmin ? AppColors.warning : textSecondary,
            size: 20,
          ),
          onPressed: () => _showConfirmDialog(
            title: isAdmin ? 'إزالة الإدارة' : 'تعيين كمدير',
            message: isAdmin
                ? 'هل تريد إزالة صلاحيات الإدارة من هذا المستخدم؟'
                : 'هل تريد تعيين هذا المستخدم كمدير؟',
            onConfirm: () => toggleAdmin(ref, userId, !isAdmin),
          ),
          splashRadius: 20,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip: 'إدارة',
        ),
        // Ban/Unban
        IconButton(
          icon: Icon(
            isBanned ? Icons.lock_open : Icons.block,
            color: isBanned ? AppColors.success : AppColors.error,
            size: 20,
          ),
          onPressed: () => _showConfirmDialog(
            title: isBanned ? 'إلغاء الحظر' : 'حظر المستخدم',
            message: isBanned
                ? 'هل تريد إلغاء حظر هذا المستخدم؟'
                : 'هل تريد حظر هذا المستخدم؟ لن يتمكن من تسجيل الدخول.',
            onConfirm: () => banUser(ref, userId),
          ),
          splashRadius: 20,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          padding: EdgeInsets.zero,
          tooltip: 'حظر',
        ),
      ],
    );
  }

  // ─── Tweets Tab ──────────────────────────────────────────────────────────

  Widget _buildTweetsTab(bool isDark, Color surfaceColor, Color textPrimary,
      Color textSecondary) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      loading: () => _buildShimmerLoading(isDark),
      error: (error, _) => _buildError(error, textPrimary, textSecondary),
      data: (stats) {
        final totalTweets = stats['total_tweets'] as int? ?? 0;
        return _buildEmpty(
            'إجمالي التغريدات: $totalTweets\nسيتم إضافة إدارة التغريدات قريباً',
            isDark,
            textSecondary);
      },
    );
  }

  // ─── Reports Tab ─────────────────────────────────────────────────────────

  Widget _buildReportsTab(bool isDark, Color surfaceColor, Color textPrimary,
      Color textSecondary) {
    final reportsAsync = ref.watch(allReportsProvider);

    return reportsAsync.when(
      loading: () => _buildShimmerLoading(isDark),
      error: (error, _) => _buildError(error, textPrimary, textSecondary),
      data: (reports) {
        if (reports.isEmpty) {
          return _buildEmpty('لا توجد بلاغات', isDark, textSecondary);
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(allReportsProvider.notifier).refresh(),
          child: ListView.separated(
            itemCount: reports.length,
            separatorBuilder: (_, __) => Divider(
              height: 0.5,
              thickness: 0.5,
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            ),
            itemBuilder: (context, index) {
              return _buildReportTile(
                  reports[index], isDark, surfaceColor, textPrimary, textSecondary, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildReportTile(Map<String, dynamic> report, bool isDark,
      Color surfaceColor, Color textPrimary, Color textSecondary, int index) {
    final reporterName = report['reporter_name'] as String? ?? 'مجهول';
    final reportedName = report['reported_name'] as String? ?? 'مجهول';
    final reason = report['reason'] as String? ?? '';
    final status = report['status'] as String? ?? 'pending';
    final reportId = report['id'] as int;
    final createdAt = report['created_at'] as String? ?? '';
    final tweetContent = report['tweet_content'] as String? ?? '';

    String statusText;
    Color statusColor;
    Color statusBg;

    switch (status) {
      case 'resolved':
        statusText = 'تم الحل';
        statusColor = AppColors.success;
        statusBg = AppColors.success.withValues(alpha: 0.1);
        break;
      case 'dismissed':
        statusText = 'مرفوض';
        statusColor = AppColors.darkTextSecondary;
        statusBg = AppColors.darkTextSecondary.withValues(alpha: 0.1);
        break;
      default:
        statusText = 'معلّق';
        statusColor = AppColors.warning;
        statusBg = AppColors.warning.withValues(alpha: 0.1);
    }

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: TextDirection.rtl,
        children: [
          // Header row
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'بلاغ من @$reporterName',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ضد @$reportedName',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reason
          if (reason.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceDark
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 13,
                  color: textPrimary,
                  height: 1.4,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          // Tweet content preview
          if (tweetContent.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'التغريدة: $tweetContent',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: textSecondary),
              textDirection: TextDirection.rtl,
            ),
          ],
          const SizedBox(height: 8),
          // Date
          if (createdAt.isNotEmpty)
            Text(
              createdAt,
              style: TextStyle(fontSize: 11, color: textSecondary),
              textDirection: TextDirection.ltr,
            ),
          const SizedBox(height: 8),
          // Action buttons
          if (status == 'pending')
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConfirmDialog(
                      title: 'حل البلاغ',
                      message: 'هل تريد حل هذا البلاغ؟',
                      onConfirm: () =>
                          updateReport(ref, reportId, 'resolved'),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('حل'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.success,
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConfirmDialog(
                      title: 'رفض البلاغ',
                      message: 'هل تريد رفض هذا البلاغ؟',
                      onConfirm: () =>
                          updateReport(ref, reportId, 'dismissed'),
                    ),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(
                          color: textSecondary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 40), duration: 250.ms);
  }

  // ─── Shimmer Loading ─────────────────────────────────────────────────────

  Widget _buildShimmerLoading(bool isDark) {
    final boneColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightSurface;
    return Skeletonizer(
      enableSwitchAnimation: true,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      Container(height: 14, width: 150, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(height: 14, width: 100, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(height: 14, width: 180, decoration: BoxDecoration(color: boneColor, borderRadius: BorderRadius.circular(4))),
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

  Widget _buildEmpty(String message, bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined,
              size: 56, color: textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 15, color: textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─── Error State ─────────────────────────────────────────────────────────

  Widget _buildError(Object error, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 56, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 13, color: textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ref.invalidate(adminStatsProvider);
              ref.invalidate(allUsersProvider);
              ref.invalidate(allReportsProvider);
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('إعادة المحاولة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Confirmation Dialog ─────────────────────────────────────────────────

  void _showConfirmDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: textPrimary,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(fontSize: 14, color: textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: Text(
                'تأكيد',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}