import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestMap;

class TweetModel {
  final int id;
  final String userId;
  final String content;
  final List<String> mediaUrls;
  final int? parentId;
  final bool isQuote;
  final int? quoteTweetId;
  final int replyCount;
  final int retweetCount;
  final int likeCount;
  final int viewCount;
  final int bookmarkCount;
  final DateTime createdAt;
  // Joined user data
  final String username;
  final String displayName;
  final String avatarUrl;
  final bool isVerified;
  // User interaction state
  final bool isLiked;
  final bool isRetweeted;
  final bool isBookmarked;
  final bool isFollowing;
  // Quote tweet data
  final TweetModel? quoteTweet;

  const TweetModel({
    required this.id,
    required this.userId,
    required this.content,
    this.mediaUrls = const [],
    this.parentId,
    this.isQuote = false,
    this.quoteTweetId,
    this.replyCount = 0,
    this.retweetCount = 0,
    this.likeCount = 0,
    this.viewCount = 0,
    this.bookmarkCount = 0,
    required this.createdAt,
    this.username = '',
    this.displayName = '',
    this.avatarUrl = '',
    this.isVerified = false,
    this.isLiked = false,
    this.isRetweeted = false,
    this.isBookmarked = false,
    this.isFollowing = false,
    this.quoteTweet,
  });

  factory TweetModel.fromJson(PostgrestMap json) {
    final mediaUrls = json['media_urls'];
    List<String> urls = [];
    if (mediaUrls != null) {
      if (mediaUrls is List) {
        urls = mediaUrls.map((e) => e.toString()).toList();
      }
    }

    return TweetModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      mediaUrls: urls,
      parentId: json['parent_id'] as int?,
      isQuote: json['is_quote'] as bool? ?? false,
      quoteTweetId: json['quote_tweet_id'] as int?,
      replyCount: json['reply_count'] as int? ?? 0,
      retweetCount: json['retweet_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      bookmarkCount: json['bookmark_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      isRetweeted: json['is_retweeted'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  TweetModel copyWith({
    int? replyCount,
    int? retweetCount,
    int? likeCount,
    int? viewCount,
    int? bookmarkCount,
    bool? isLiked,
    bool? isRetweeted,
    bool? isBookmarked,
    bool? isFollowing,
  }) {
    return TweetModel(
      id: id,
      userId: userId,
      content: content,
      mediaUrls: mediaUrls,
      parentId: parentId,
      isQuote: isQuote,
      quoteTweetId: quoteTweetId,
      replyCount: replyCount ?? this.replyCount,
      retweetCount: retweetCount ?? this.retweetCount,
      likeCount: likeCount ?? this.likeCount,
      viewCount: viewCount ?? this.viewCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      createdAt: createdAt,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      isVerified: isVerified,
      isLiked: isLiked ?? this.isLiked,
      isRetweeted: isRetweeted ?? this.isRetweeted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFollowing: isFollowing ?? this.isFollowing,
      quoteTweet: quoteTweet,
    );
  }

  String get fullAvatarUrl {
    if (avatarUrl.isEmpty) return '';
    if (avatarUrl.startsWith('http')) return avatarUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$avatarUrl';
  }

  List<String> get fullMediaUrls => mediaUrls.map((url) {
    if (url.startsWith('http')) return url;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$url';
  }).toList();
}