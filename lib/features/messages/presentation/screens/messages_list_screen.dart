import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/models/conversation_model.dart';
import '../providers/messages_provider.dart';

// ─── Messages List Screen ──────────────────────────────────────────────────────

class MessagesListScreen extends ConsumerStatefulWidget {
  const MessagesListScreen({super.key});

  @override
  ConsumerState<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends ConsumerState<MessagesListScreen> {
  // Search state for new-message dialog
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      final response = await supabase
          .from('profiles')
          .select('id, username, display_name, avatar_url')
          .neq('id', currentUserId ?? '')
          .or('display_name.ilike.%$query%,username.ilike.%$query%')
          .limit(15);

      final List<dynamic> data = response as List<dynamic>? ?? [];

      if (!mounted) return;
      setState(() {
        _searchResults = data
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  Future<void> _startConversation(UserModel otherUser) async {
    Navigator.of(context).pop(); // close dialog

    try {
      final conversationId =
          await ref.read(createConversationProvider.notifier).createOrGetConversation(otherUser.id);
      if (!mounted) return;
      context.push('/messages/$conversationId', extra: {
        'otherUserId': otherUser.id,
        'otherUsername': otherUser.username,
        'otherDisplayName': otherUser.displayName,
        'otherAvatarUrl': otherUser.fullAvatarUrl,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في بدء المحادثة'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showNewMessageDialog() {
    _searchController.clear();
    _searchResults = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'رسالة جديدة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  onChanged: (value) {
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_searchController.text == value) {
                        _searchUsers(value);
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مستخدم...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurfaceDark
                        : AppColors.lightBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _isSearching
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _searchResults.isEmpty && _searchController.text.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'ابحث عن مستخدم لبدء محادثة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          )
                        : _searchResults.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'لا توجد نتائج',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 300),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  separatorBuilder: (_, _) => Divider(
                                    height: 0.5,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.darkDivider
                                        : AppColors.lightDivider,
                                  ),
                                  itemBuilder: (context, index) {
                                    final user = _searchResults[index];
                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.darkSurfaceDark
                                                : AppColors.lightBackground,
                                        backgroundImage:
                                            user.fullAvatarUrl.isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                    user.fullAvatarUrl)
                                                : null,
                                        child: user.fullAvatarUrl.isEmpty
                                            ? Icon(
                                                Icons.person,
                                                size: 20,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors
                                                        .lightTextSecondary,
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        user.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '@${user.username}',
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      onTap: () =>
                                          _startConversation(user),
                                    );
                                  },
                                ),
                              ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'إلغاء',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
    final dividerColor =
        isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: Text(
          'الرسائل',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              onPressed: _showNewMessageDialog,
              icon: Container(
                padding:
                    const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_square,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(conversationsProvider.notifier).refresh(),
        child: conversationsAsync.when(
          loading: () => _buildShimmerLoading(isDark),
          error: (error, _) => _buildErrorState(error, isDark),
          data: (conversations) {
            if (conversations.isEmpty) {
              return _buildEmptyState(isDark);
            }

            return ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: conversations.length,
              separatorBuilder: (_, _) => Divider(
                height: 0.5,
                thickness: 0.5,
                color: dividerColor,
                indent: 76,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _buildConversationTile(
                  conversation: conversation,
                  isDark: isDark,
                  surfaceColor: surfaceColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  index: index,
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ─── Conversation Tile ─────────────────────────────────────────────────────

  Widget _buildConversationTile({
    required ConversationModel conversation,
    required bool isDark,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required int index,
  }) {
    final timeText = conversation.lastMessageAt != null
        ? AppFormatters.formatTimeAgo(conversation.lastMessageAt!)
        : '';

    return InkWell(
      onTap: () {
        context.push('/messages/${conversation.conversationId}', extra: {
          'otherUserId': conversation.otherUserId,
          'otherUsername': conversation.otherUsername,
          'otherDisplayName': conversation.otherDisplayName,
          'otherAvatarUrl': conversation.fullAvatarUrl,
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground,
              backgroundImage: conversation.fullAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(conversation.fullAvatarUrl)
                  : null,
              child: conversation.fullAvatarUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 24,
                      color: textSecondary.withValues(alpha: 0.5),
                    )
                  : null,
            ),

            const SizedBox(width: 14),

            // Name + message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  // Name row
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Last message preview
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Center(
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
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

  // ─── Shimmer Loading ──────────────────────────────────────────────────────

  Widget _buildShimmerLoading(bool isDark) {
    final baseColor =
        isDark ? AppColors.darkSurfaceDark : Colors.grey[300]!;
    final highlightColor =
        isDark ? AppColors.darkSurface : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
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

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.darkSurfaceDark
                            : AppColors.lightBackground)
                        .withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mail_outline_rounded,
                    size: 56,
                    color: textSecondary.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ليس لديك رسائل بعد',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ابدأ محادثة جديدة بالضغط على زر الرسالة',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(
                begin: 0.1,
                end: 0,
                duration: 400.ms,
              ),
        ),
      ],
    );
  }

  // ─── Error State ──────────────────────────────────────────────────────────

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
            'حدث خطأ أثناء تحميل المحادثات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkTextSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(conversationsProvider),
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
    );
  }
}