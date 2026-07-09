import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../tweets/data/models/tweet_model.dart';
import '../../../../core/constants/api_constants.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void updateQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider.autoDispose<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class TrendingHashtag {
  final int id;
  final String tag;
  final int tweetCount;
  const TrendingHashtag({required this.id, required this.tag, required this.tweetCount});
  factory TrendingHashtag.fromJson(Map<String, dynamic> json) => TrendingHashtag(
    id: json['id'] as int,
    tag: json['tag'] as String,
    tweetCount: json['tweet_count'] as int? ?? 0,
  );
}

class TrendingNotifier extends AsyncNotifier<List<TrendingHashtag>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<TrendingHashtag>> build() async {
    try {
      final response = await _supabase.rpc('get_trending_hashtags', params: {'p_limit': 20});
      final List<dynamic> data = response as List<dynamic>? ?? [];
      return data.map((item) => TrendingHashtag.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
}

class SearchResults {
  final List<UserModel> users;
  final List<TweetModel> tweets;
  const SearchResults({this.users = const [], this.tweets = const []});
  SearchResults copyWith({List<UserModel>? users, List<TweetModel>? tweets}) =>
      SearchResults(users: users ?? this.users, tweets: tweets ?? this.tweets);
}

class SearchResultsNotifier extends AsyncNotifier<SearchResults> {
  final _supabase = Supabase.instance.client;
  Timer? _debounceTimer;

  @override
  Future<SearchResults> build() async {
    ref.listen(searchQueryProvider.select((s) => s), (previous, next) => _onQueryChanged(next));
    ref.onDispose(() => _debounceTimer?.cancel());
    return const SearchResults();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      state = const AsyncData(SearchResults());
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 300), () => _performSearch(query.trim()));
  }

  Future<void> _performSearch(String query) async {
    state = AsyncData(state.value ?? const SearchResults());
    final currentUserId = _supabase.auth.currentUser?.id;

    try {
      final usersResponse = await _supabase.rpc('search_users_fn', params: {
        'p_query': query,
        'p_viewer_id': currentUserId,
        'p_limit': ApiConstants.usersPerPage,
        'p_offset': 0,
      });
      final List<dynamic> usersData = usersResponse as List<dynamic>? ?? [];
      final users = usersData.map((item) => UserModel.fromJson(item as Map<String, dynamic>)).toList();

      final tweetsResponse = await _supabase.rpc('search_tweets_fn', params: {
        'p_query': query,
        'p_user_id': currentUserId,
        'p_limit': ApiConstants.tweetsPerPage,
        'p_offset': 0,
      });
      final List<dynamic> tweetsData = tweetsResponse as List<dynamic>? ?? [];
      final tweets = tweetsData.map((item) => TweetModel.fromJson(item as Map<String, dynamic>)).toList();

      state = AsyncData(SearchResults(users: users, tweets: tweets));
    } catch (e) {
      final previous = state.value;
      state = AsyncData(previous ?? const SearchResults());
    }
  }

  Future<void> refresh() async {
    final query = ref.read(searchQueryProvider);
    if (query.trim().isNotEmpty) await _performSearch(query.trim());
  }
}

final trendingProvider = AsyncNotifierProvider.autoDispose<TrendingNotifier, List<TrendingHashtag>>(TrendingNotifier.new);
final searchResultsProvider = AsyncNotifierProvider.autoDispose<SearchResultsNotifier, SearchResults>(SearchResultsNotifier.new);