import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/data/models/user_model.dart';
import '../../../tweets/data/models/tweet_model.dart';
import '../../../../core/constants/api_constants.dart';

// ─── Search Query Notifier ─────────────────────────────────────────────────────

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final searchQueryProvider =
    NotifierProvider.autoDispose<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// ─── Trending Hashtag Model ───────────────────────────────────────────────────

class TrendingHashtag {
  final int id;
  final String tag;
  final int tweetCount;

  const TrendingHashtag({
    required this.id,
    required this.tag,
    required this.tweetCount,
  });

  factory TrendingHashtag.fromJson(Map<String, dynamic> json) {
    return TrendingHashtag(
      id: json['id'] as int,
      tag: json['tag'] as String,
      tweetCount: json['tweet_count'] as int? ?? 0,
    );
  }
}

// ─── Trending Notifier ─────────────────────────────────────────────────────────

class TrendingNotifier extends AsyncNotifier<List<TrendingHashtag>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<TrendingHashtag>> build() async {
    return _fetchTrending();
  }

  Future<List<TrendingHashtag>> _fetchTrending() async {
    try {
      final response = await _supabase.rpc(
        'get_trending_hashtags',
        params: {'p_limit': 20},
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];

      return data
          .map((item) =>
              TrendingHashtag.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

// ─── Search Results Model ─────────────────────────────────────────────────────

class SearchResults {
  final List<UserModel> users;
  final List<TweetModel> tweets;

  const SearchResults({
    this.users = const [],
    this.tweets = const [],
  });

  SearchResults copyWith({
    List<UserModel>? users,
    List<TweetModel>? tweets,
  }) {
    return SearchResults(
      users: users ?? this.users,
      tweets: tweets ?? this.tweets,
    );
  }
}

// ─── Search Results Notifier ───────────────────────────────────────────────────

class SearchResultsNotifier
    extends AsyncNotifier<SearchResults> {
  final _supabase = Supabase.instance.client;
  Timer? _debounceTimer;

  @override
  Future<SearchResults> build() async {
    // Watch the query and re-run when it changes
    ref.listen(searchQueryProvider.select((s) => s), (previous, next) {
      _onQueryChanged(next);
    });

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return const SearchResults();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = const AsyncData(SearchResults());
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    // Set loading state for search
    state = AsyncData(state.value ?? const SearchResults());

    try {
      // Search users
      final usersResponse = await _supabase.rpc(
        'search_users_fn',
        params: {
          'p_query': query,
          'p_limit': ApiConstants.usersPerPage,
          'p_offset': 0,
        },
      );

      final List<dynamic> usersData = usersResponse as List<dynamic>? ?? [];
      final users = usersData
          .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Search tweets
      final tweetsResponse = await _supabase.rpc(
        'search_tweets_fn',
        params: {
          'p_query': query,
          'p_limit': ApiConstants.tweetsPerPage,
          'p_offset': 0,
        },
      );

      final List<dynamic> tweetsData = tweetsResponse as List<dynamic>? ?? [];
      final tweets = tweetsData
          .map((item) => TweetModel.fromJson(item as Map<String, dynamic>))
          .toList();

      state = AsyncData(SearchResults(users: users, tweets: tweets));
    } catch (e) {
      // Keep previous data if available, otherwise show empty
      final previous = state.value;
      state = AsyncData(previous ?? const SearchResults());
    }
  }

  /// Force search with the current query.
  Future<void> refresh() async {
    final query = ref.read(searchQueryProvider);
    if (query.trim().isNotEmpty) {
      await _performSearch(query.trim());
    }
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────

/// Trending hashtags provider.
final trendingProvider =
    AsyncNotifierProvider.autoDispose<TrendingNotifier, List<TrendingHashtag>>(
  TrendingNotifier.new,
);

/// Search results provider.
final searchResultsProvider =
    AsyncNotifierProvider.autoDispose<SearchResultsNotifier, SearchResults>(
  SearchResultsNotifier.new,
);