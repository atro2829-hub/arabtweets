import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../providers/tweet_provider.dart';
import '../widgets/tweet_card.dart';
import '../widgets/compose_tweet_sheet.dart';

/// Screen that shows a single tweet and its replies.
class TweetDetailScreen extends ConsumerStatefulWidget {
  final int tweetId;

  const TweetDetailScreen({super.key, required this.tweetId});

  @override
  ConsumerState<TweetDetailScreen> createState() => _TweetDetailScreenState();
}

class _TweetDetailScreenState extends ConsumerState<TweetDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReplies();
    }
  }

  void _loadMoreReplies() {
    final notifier = ref.read(tweetDetailProvider(widget.tweetId).notifier);
    if (!notifier.hasMoreReplies || notifier.isLoadingMoreReplies) return;
    notifier.loadMoreReplies();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final detailAsync = ref.watch(tweetDetailProvider(widget.tweetId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('التغريدة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(error.toString(), style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(tweetDetailProvider(widget.tweetId)),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (detail) {
          return ListView(
            controller: _scrollController,
            children: [
              // Main tweet
              if (detail.tweet != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: TweetCard(
                    tweet: detail.tweet!,
                    index: 0,
                    onLike: (_) => ref.read(tweetDetailProvider(widget.tweetId).notifier).toggleLike(),
                    onRetweet: (_) => ref.read(tweetDetailProvider(widget.tweetId).notifier).toggleRetweet(),
                    onReply: (id) {
                      ComposeTweetSheet.show(context: context, parentId: id);
                    },
                    onBookmark: (_) => ref.read(tweetDetailProvider(widget.tweetId).notifier).toggleBookmark(),
                  ),
                ),

              // Replies header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'الردود (${detail.tweet?.replyCount ?? 0})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),

              // Replies list
              if (detail.replies.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'لا توجد ردود بعد',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ...detail.replies.asMap().entries.map((entry) {
                  final reply = entry.value;
                  return TweetCard(
                    tweet: reply,
                    index: entry.key,
                    onLike: (_) {},
                    onRetweet: (_) {},
                    onReply: (id) {
                      ComposeTweetSheet.show(context: context, parentId: id);
                    },
                    onBookmark: (_) {},
                  );
                }),

              // Loading more
              if (ref.read(tweetDetailProvider(widget.tweetId).notifier).isLoadingMoreReplies)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}