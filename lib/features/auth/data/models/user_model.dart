import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestMap;

class UserModel {
  final String id;
  final String username;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final String coverUrl;
  final String location;
  final String website;
  final bool isVerified;
  final bool isAdmin;
  final String theme;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int followersCount;
  final int followingCount;
  final int tweetsCount;
  final bool isFollowing;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.bio = '',
    this.avatarUrl = '',
    this.coverUrl = '',
    this.location = '',
    this.website = '',
    this.isVerified = false,
    this.isAdmin = false,
    this.theme = 'light',
    required this.createdAt,
    required this.updatedAt,
    this.followersCount = 0,
    this.followingCount = 0,
    this.tweetsCount = 0,
    this.isFollowing = false,
  });

  factory UserModel.fromJson(PostgrestMap json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      location: json['location'] as String? ?? '',
      website: json['website'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      isAdmin: json['is_admin'] as bool? ?? false,
      theme: json['theme'] as String? ?? 'light',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      tweetsCount: json['tweets_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'location': location,
      'website': website,
      'is_verified': isVerified,
      'theme': theme,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? location,
    String? website,
    bool? isVerified,
    bool? isAdmin,
    String? theme,
    int? followersCount,
    int? followingCount,
    int? tweetsCount,
    bool? isFollowing,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      location: location ?? this.location,
      website: website ?? this.website,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      theme: theme ?? this.theme,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      tweetsCount: tweetsCount ?? this.tweetsCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  String get fullAvatarUrl {
    if (avatarUrl.isEmpty) return '';
    if (avatarUrl.startsWith('http')) return avatarUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$avatarUrl';
  }

  String get fullCoverUrl {
    if (coverUrl.isEmpty) return '';
    if (coverUrl.startsWith('http')) return coverUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$coverUrl';
  }
}