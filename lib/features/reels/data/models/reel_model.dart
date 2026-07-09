class ReelModel {
  final int id;
  final String userId;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final int duration;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;
  final String username;
  final String displayName;
  final String avatarUrl;
  final bool isVerified;
  bool isLiked;
  final bool isFollowing;

  ReelModel({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl = '',
    this.caption = '',
    this.duration = 0,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    required this.createdAt,
    this.username = '',
    this.displayName = '',
    this.avatarUrl = '',
    this.isVerified = false,
    this.isLiked = false,
    this.isFollowing = false,
  });

  factory ReelModel.fromJson(Map<String, dynamic> json) {
    return ReelModel(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  String get fullVideoUrl {
    if (videoUrl.startsWith('http')) return videoUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$videoUrl';
  }

  String get fullThumbnailUrl {
    if (thumbnailUrl.isEmpty) return '';
    if (thumbnailUrl.startsWith('http')) return thumbnailUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$thumbnailUrl';
  }

  String get fullAvatarUrl {
    if (avatarUrl.isEmpty) return '';
    if (avatarUrl.startsWith('http')) return avatarUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$avatarUrl';
  }

  ReelModel copyWith({bool? isLiked, int? likeCount}) {
    return ReelModel(
      id: id, userId: userId, videoUrl: videoUrl, thumbnailUrl: thumbnailUrl,
      caption: caption, duration: duration, viewCount: viewCount,
      likeCount: likeCount ?? this.likeCount, commentCount: commentCount,
      shareCount: shareCount, createdAt: createdAt, username: username,
      displayName: displayName, avatarUrl: avatarUrl, isVerified: isVerified,
      isLiked: isLiked ?? this.isLiked, isFollowing: isFollowing,
    );
  }
}