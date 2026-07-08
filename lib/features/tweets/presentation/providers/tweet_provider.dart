import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../data/models/tweet_model.dart';

// ─── Tweet Detail State ──────────────────────────────────────────────────────

class TweetDetailState {
  final TweetModel? tweet;
  final List<TweetModel> replies;
  final bool hasMore;
  final bool isLoadingMoreReplies;

  const TweetDetailState({
    this.tweet,
    this.replies = const [],
    this.hasMore = true,
    this.isLoadingMoreReplies = false,
  });

  TweetDetailState copyWith({
    TweetModel? tweet,
    List<TweetModel>? replies,
    bool? hasMore,
    bool? isLoadingMoreReplies,
  }) {
    return TweetDetailState(
      tweet: tweet ?? this.tweet,
      replies: replies ?? this.replies,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMoreReplies:
          isLoadingMoreReplies ?? this.isLoadingMoreReplies,
    );
  }
}

// ─── Tweet Detail Notifier ───────────────────────────────────────────────────

class TweetDetailNotifier extends AsyncNotifier<TweetDetailState> {
  final _supabase = Supabase.instance.client;
  int _repliesOffset = 0;
  bool _hasMoreReplies = true;
  bool _isLoadingMoreReplies = false;
  int tweetId = 0;

  @override
  Future<TweetDetailState> build() async {
    _repliesOffset = 0;
    _hasMoreReplies = true;
    _isLoadingMoreReplies = false;

    final tweet = await _fetchTweet(tweetId);
    final replies = await _fetchReplies(tweetId: tweetId, offset: 0);

    if (replies.length < ApiConstants.tweetsPerPage) {
      _hasMoreReplies = false;
    }

    return TweetDetailState(
      tweet: tweet,
      replies: replies,
      hasMore: _hasMoreReplies,
    );
  }

  /// Fetch a single tweet by ID with author profile data.
  Future<TweetModel> _fetchTweet(int tweetId) async {
    try {
      final response = await _supabase
          .from('tweets')
          .select('*, profiles!tweets_user_id_fkey(username, display_name, avatar_url, is_verified)')
          .eq('id', tweetId)
          .single();

      // Flatten the nested profiles data into the tweet map
      final profile = response['profiles'] as Map<String, dynamic>? ?? {};
      final flatMap = <String, dynamic>{
        ...response,
        'username': profile['username'] as String? ?? '',
        'display_name': profile['display_name'] as String? ?? '',
        'avatar_url': profile['avatar_url'] as String? ?? '',
        'is_verified': profile['is_verified'] as bool? ?? false,
      };
      flatMap.remove('profiles');

      return TweetModel.fromJson(flatMap);
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل التغريدة: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل التغريدة');
    }
  }

  /// Fetch replies for a tweet via RPC.
  Future<List<TweetModel>> _fetchReplies({
    required int tweetId,
    required int offset,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_tweet_replies',
        params: {
          'p_tweet_id': tweetId,
          'p_user_id': userId,
          'p_limit': ApiConstants.tweetsPerPage,
          'p_offset': offset,
        },
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];

      return data
          .map((item) => TweetModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Load more replies and append to the existing list.
  Future<void> loadMoreReplies() async {
    if (_isLoadingMoreReplies || !_hasMoreReplies) return;

    _isLoadingMoreReplies = true;
    final currentState = state.value;
    if (currentState == null) return;

    try {
      _repliesOffset += ApiConstants.tweetsPerPage;
      final newReplies = await _fetchReplies(
        tweetId: tweetId,
        offset: _repliesOffset,
      );

      if (newReplies.length < ApiConstants.tweetsPerPage) {
        _hasMoreReplies = false;
      }

      state = AsyncData(currentState.copyWith(
        replies: [...currentState.replies, ...newReplies],
        hasMore: _hasMoreReplies,
      ));
    } catch (e) {
      _repliesOffset -= ApiConstants.tweetsPerPage;
    } finally {
      _isLoadingMoreReplies = false;
    }
  }

  /// Whether we are currently loading more replies.
  bool get isLoadingMoreReplies => _isLoadingMoreReplies;

  /// Whether there are more replies to load.
  bool get hasMoreReplies => _hasMoreReplies;

  /// Toggle like on the main tweet.
  Future<void> toggleLike() async {
    final currentState = state.value;
    if (currentState?.tweet == null) return;

    final tweet = currentState!.tweet!;
    final wasLiked = tweet.isLiked;
    final newLikeCount = wasLiked ? tweet.likeCount - 1 : tweet.likeCount + 1;

    // Optimistic update
    state = AsyncData(currentState.copyWith(
      tweet: tweet.copyWith(
        isLiked: !wasLiked,
        likeCount: newLikeCount,
      ),
    ));

    try {
      await _supabase.rpc('toggle_like', params: {
        'p_tweet_id': tweet.id,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      // Revert on error
      state = AsyncData(currentState);
    }
  }

  /// Toggle retweet on the main tweet.
  Future<void> toggleRetweet() async {
    final currentState = state.value;
    if (currentState?.tweet == null) return;

    final tweet = currentState!.tweet!;
    final wasRetweeted = tweet.isRetweeted;
    final newRetweetCount =
        wasRetweeted ? tweet.retweetCount - 1 : tweet.retweetCount + 1;

    // Optimistic update
    state = AsyncData(currentState.copyWith(
      tweet: tweet.copyWith(
        isRetweeted: !wasRetweeted,
        retweetCount: newRetweetCount,
      ),
    ));

    try {
      await _supabase.rpc('toggle_retweet', params: {
        'p_tweet_id': tweet.id,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      // Revert on error
      state = AsyncData(currentState);
    }
  }

  /// Toggle bookmark on the main tweet.
  Future<void> toggleBookmark() async {
    final currentState = state.value;
    if (currentState?.tweet == null) return;

    final tweet = currentState!.tweet!;
    final wasBookmarked = tweet.isBookmarked;
    final newBookmarkCount =
        wasBookmarked ? tweet.bookmarkCount - 1 : tweet.bookmarkCount + 1;

    // Optimistic update
    state = AsyncData(currentState.copyWith(
      tweet: tweet.copyWith(
        isBookmarked: !wasBookmarked,
        bookmarkCount: newBookmarkCount,
      ),
    ));

    try {
      await _supabase.rpc('toggle_bookmark', params: {
        'p_tweet_id': tweet.id,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      // Revert on error
      state = AsyncData(currentState);
    }
  }

  /// Add a reply to the tweet and prepend it to the replies list.
  Future<void> addReply(String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final currentState = state.value;
    if (currentState == null) return;

    try {
      final response = await _supabase.rpc('create_tweet', params: {
        'p_user_id': userId,
        'p_content': content,
        'p_media_urls': <String>[],
        'p_parent_id': tweetId,
        'p_quote_tweet_id': null,
      });

      final newReplyData = response as Map<String, dynamic>;
      final newReply = TweetModel.fromJson(newReplyData);

      // Update the parent tweet's reply count optimistically
      final updatedTweet = currentState.tweet?.copyWith(
        replyCount: currentState.tweet!.replyCount + 1,
      );

      state = AsyncData(currentState.copyWith(
        tweet: updatedTweet,
        replies: [newReply, ...currentState.replies],
      ));
    } catch (e) {
      rethrow;
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Tweet detail provider – loads a tweet and its replies by tweet ID.
final tweetDetailProvider = AsyncNotifierProvider.autoDispose.family<
    TweetDetailNotifier, TweetDetailState, int>(
  (arg) => TweetDetailNotifier()..tweetId = arg,
);