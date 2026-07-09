import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/cache_service.dart';
import '../../data/models/tweet_model.dart';

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

    final online = await CacheService.isOnline();

    // If offline, load from cache
    if (!online) {
      final cached = await CacheService.instance.getFeed();
      if (cached.isNotEmpty) {
        return cached.map((e) => TweetModel.fromJson(e)).toList();
      }
      throw Exception('لا يوجد اتصال بالإنترنت');
    }

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
      if (data.length < ApiConstants.tweetsPerPage) _hasMore = false;

      final tweets = data.map((item) => TweetModel.fromJson(item as Map<String, dynamic>)).toList();

      // Cache the feed
      if (offset == 0) {
        await CacheService.instance.saveFeed(
          tweets.map((t) => {
            'id': t.id, 'user_id': t.userId, 'content': t.content,
            'media_urls': t.mediaUrls, 'parent_id': t.parentId,
            'is_quote': t.isQuote, 'quote_tweet_id': t.quoteTweetId,
            'reply_count': t.replyCount, 'retweet_count': t.retweetCount,
            'like_count': t.likeCount, 'view_count': t.viewCount,
            'bookmark_count': t.bookmarkCount, 'created_at': t.createdAt.toIso8601String(),
            'username': t.username, 'display_name': t.displayName,
            'avatar_url': t.avatarUrl, 'is_verified': t.isVerified,
            'is_liked': t.isLiked, 'is_retweeted': t.isRetweeted,
            'is_bookmarked': t.isBookmarked, 'is_following': t.isFollowing,
          }).toList(),
        );
      }

      return tweets;
    } on PostgrestException catch (e) {
      // On error, try cache
      final cached = await CacheService.instance.getFeed();
      if (cached.isNotEmpty) return cached.map((e) => TweetModel.fromJson(e)).toList();
      throw Exception('فشل في تحميل التغريدات: ${e.message}');
    } catch (e) {
      final cached = await CacheService.instance.getFeed();
      if (cached.isNotEmpty) return cached.map((e) => TweetModel.fromJson(e)).toList();
      throw Exception('حدث خطأ أثناء تحميل التغريدات');
    }
  }

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

  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  Future<void> refresh() async {
    _currentOffset = 0;
    _hasMore = true;
    _isLoadingMore = false;
    state = const AsyncLoading();
    state = AsyncData(await _fetchFeed(offset: 0));
  }

  Future<void> toggleLike(int tweetId) async {
    final currentTweets = state.value;
    if (currentTweets == null) return;
    final idx = currentTweets.indexWhere((t) => t.id == tweetId);
    if (idx == -1) return;
    final tweet = currentTweets[idx];
    final wasLiked = tweet.isLiked;
    final newLikeCount = wasLiked ? tweet.likeCount - 1 : tweet.likeCount + 1;

    final updatedTweets = List<TweetModel>.from(currentTweets);
    updatedTweets[idx] = tweet.copyWith(isLiked: !wasLiked, likeCount: newLikeCount);
    state = AsyncData(updatedTweets);

    try {
      await _supabase.rpc('toggle_like', params: {
        'p_tweet_id': tweetId,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      final revertedTweets = List<TweetModel>.from(currentTweets);
      revertedTweets[idx] = tweet;
      state = AsyncData(revertedTweets);
    }
  }

  Future<void> toggleRetweet(int tweetId) async {
    final currentTweets = state.value;
    if (currentTweets == null) return;
    final idx = currentTweets.indexWhere((t) => t.id == tweetId);
    if (idx == -1) return;
    final tweet = currentTweets[idx];
    final wasRetweeted = tweet.isRetweeted;
    final newRetweetCount = wasRetweeted ? tweet.retweetCount - 1 : tweet.retweetCount + 1;

    final updatedTweets = List<TweetModel>.from(currentTweets);
    updatedTweets[idx] = tweet.copyWith(isRetweeted: !wasRetweeted, retweetCount: newRetweetCount);
    state = AsyncData(updatedTweets);

    try {
      await _supabase.rpc('toggle_retweet', params: {
        'p_tweet_id': tweetId,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      final revertedTweets = List<TweetModel>.from(currentTweets);
      revertedTweets[idx] = tweet;
      state = AsyncData(revertedTweets);
    }
  }

  Future<void> toggleBookmark(int tweetId) async {
    final currentTweets = state.value;
    if (currentTweets == null) return;
    final idx = currentTweets.indexWhere((t) => t.id == tweetId);
    if (idx == -1) return;
    final tweet = currentTweets[idx];
    final wasBookmarked = tweet.isBookmarked;
    final newBookmarkCount = wasBookmarked ? tweet.bookmarkCount - 1 : tweet.bookmarkCount + 1;

    final updatedTweets = List<TweetModel>.from(currentTweets);
    updatedTweets[idx] = tweet.copyWith(isBookmarked: !wasBookmarked, bookmarkCount: newBookmarkCount);
    state = AsyncData(updatedTweets);

    try {
      await _supabase.rpc('toggle_bookmark', params: {
        'p_tweet_id': tweetId,
        'p_user_id': _supabase.auth.currentUser!.id,
      });
    } catch (e) {
      final revertedTweets = List<TweetModel>.from(currentTweets);
      revertedTweets[idx] = tweet;
      state = AsyncData(revertedTweets);
    }
  }

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

      final List<dynamic> data = response as List<dynamic>? ?? [];
      if (data.isNotEmpty) {
        final newTweet = TweetModel.fromJson(data[0] as Map<String, dynamic>);
        final currentTweets = state.value ?? [];
        state = AsyncData([newTweet, ...currentTweets]);
      }
    } catch (e) {
      rethrow;
    }
  }
}

final feedProvider = AsyncNotifierProvider.autoDispose<FeedNotifier, List<TweetModel>>(
  FeedNotifier.new,
);