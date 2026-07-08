import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/api_constants.dart';
import '../../data/models/tweet_model.dart';

// ─── Feed State ──────────────────────────────────────────────────────────────

class FeedState {
  final List<TweetModel> tweets;
  final int offset;
  final bool isLoadingMore;
  final bool hasMore;

  const FeedState({
    this.tweets = const [],
    this.offset = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  FeedState copyWith({
    List<TweetModel>? tweets,
    int? offset,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return FeedState(
      tweets: tweets ?? this.tweets,
      offset: offset ?? this.offset,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// ─── Feed Notifier ───────────────────────────────────────────────────────────

class FeedNotifier extends AsyncNotifier<List<TweetModel>> {
  final _supabase = Supabase.instance.client;
  int _currentOffset = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<TweetModel>> build() async {
    _currentOffset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchFeed(offset: 0);
  }

  Future<List<TweetModel>> _fetchFeed({required int offset}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_feed',
        params: {
          'p_user_id': userId,
          'p_limit': ApiConstants.tweetsPerPage,
          'p_offset': offset,
        },
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];

      if (data.length < ApiConstants.tweetsPerPage) {
        _hasMore = false;
      }

      final tweets = data
          .map((item) => TweetModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return tweets;
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل التغريدات: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل التغريدات');
    }
  }

  /// Load the next page of tweets and append to the existing list.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;

    try {
      final current = state.value ?? [];
      _currentOffset += ApiConstants.tweetsPerPage;

      final newTweets = await _fetchFeed(offset: _currentOffset);

      state = AsyncData([...current, ...newTweets]);
    } catch (e) {
      _currentOffset -= ApiConstants.tweetsPerPage;
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Whether we are currently loading more tweets (for UI indicator).
  bool get isLoadingMore => _isLoadingMore;

  /// Whether there are more tweets to load.
  bool get hasMore => _hasMore;

  /// Reset and reload the entire feed.
  Future<void> refresh() async {
    _currentOffset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    state = const AsyncLoading();
    state = AsyncData(await _fetchFeed(offset: 0));
  }

  /// Toggle like on a tweet and update local state optimistically.
  Future<void> toggleLike(int tweetId) async {
    final currentTweets = state.value;
    if (currentTweets == null) return;

    final tweetIndex = currentTweets.indexWhere((t) => t.id == tweetId);
    if (tweetIndex == -1) return;

    final tweet = currentTweets[tweetIndex];
    final wasLiked = tweet.isLiked;
    final newLikeCount = wasLiked ? tweet.likeCount - 1 : tweet.likeCount + 1;

    // Optimistic update
    final updatedTweets = List<TweetModel>.from(currentTweets);
    updatedTweets[tweetIndex] = tweet.copyWith(
      isLiked: !wasLiked,
      likeCount: newLikeCount,
    );
    state = AsyncData(updatedTweets);

    try {
      await _supabase.rpc('toggle_like', params: {
        'p_tweet_id': tweetId,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      // Revert on error
      final revertedTweets = List<TweetModel>.from(currentTweets);
      revertedTweets[tweetIndex] = tweet;
      state = AsyncData(revertedTweets);
    }
  }

  /// Toggle retweet on a tweet and update local state optimistically.
  Future<void> toggleRetweet(int tweetId) async {
    final currentTweets = state.value;
    if (currentTweets == null) return;

    final tweetIndex = currentTweets.indexWhere((t) => t.id == tweetId);
    if (tweetIndex == -1) return;

    final tweet = currentTweets[tweetIndex];
    final wasRetweeted = tweet.isRetweeted;
    final newRetweetCount =
        wasRetweeted ? tweet.retweetCount - 1 : tweet.retweetCount + 1;

    // Optimistic update
    final updatedTweets = List<TweetModel>.from(currentTweets);
    updatedTweets[tweetIndex] = tweet.copyWith(
      isRetweeted: !wasRetweeted,
      retweetCount: newRetweetCount,
    );
    state = AsyncData(updatedTweets);

    try {
      await _supabase.rpc('toggle_retweet', params: {
        'p_tweet_id': tweetId,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      // Revert on error
      final revertedTweets = List<TweetModel>.from(currentTweets);
      revertedTweets[tweetIndex] = tweet;
      state = AsyncData(revertedTweets);
    }
  }

  /// Toggle bookmark on a tweet and update local state optimistically.
  Future<void> toggleBookmark(int tweetId) async {
    final currentTweets = state.value;
    if (currentTweets == null) return;

    final tweetIndex = currentTweets.indexWhere((t) => t.id == tweetId);
    if (tweetIndex == -1) return;

    final tweet = currentTweets[tweetIndex];
    final wasBookmarked = tweet.isBookmarked;
    final newBookmarkCount =
        wasBookmarked ? tweet.bookmarkCount - 1 : tweet.bookmarkCount + 1;

    // Optimistic update
    final updatedTweets = List<TweetModel>.from(currentTweets);
    updatedTweets[tweetIndex] = tweet.copyWith(
      isBookmarked: !wasBookmarked,
      bookmarkCount: newBookmarkCount,
    );
    state = AsyncData(updatedTweets);

    try {
      await _supabase.rpc('toggle_bookmark', params: {
        'p_tweet_id': tweetId,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      // Revert on error
      final revertedTweets = List<TweetModel>.from(currentTweets);
      revertedTweets[tweetIndex] = tweet;
      state = AsyncData(revertedTweets);
    }
  }

  /// Create a new tweet and prepend it to the feed list.
  Future<void> createTweet({
    required String content,
    List<String> mediaUrls = const [],
    int? parentId,
    int? quoteTweetId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase.rpc('create_tweet', params: {
        'p_user_id': userId,
        'p_content': content,
        'p_media_urls': mediaUrls,
        'p_parent_id': parentId,
        'p_quote_tweet_id': quoteTweetId,
      });

      final newTweetData = response as Map<String, dynamic>;
      final newTweet = TweetModel.fromJson(newTweetData);

      final currentTweets = state.value ?? [];
      state = AsyncData([newTweet, ...currentTweets]);
    } catch (e) {
      rethrow;
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Primary feed provider – watches the list of tweets for the home feed.
final feedProvider =
    AsyncNotifierProvider.autoDispose<FeedNotifier, List<TweetModel>>(
  FeedNotifier.new,
);