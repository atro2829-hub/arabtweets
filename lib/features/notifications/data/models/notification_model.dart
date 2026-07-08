import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestMap;

class NotificationModel {
  final int id;
  final String fromUserId;
  final String type;
  final int? tweetId;
  final bool isRead;
  final DateTime createdAt;
  final String fromUsername;
  final String fromDisplayName;
  final String fromAvatarUrl;
  final String? tweetContent;

  const NotificationModel({
    required this.id,
    required this.fromUserId,
    required this.type,
    this.tweetId,
    required this.isRead,
    required this.createdAt,
    required this.fromUsername,
    required this.fromDisplayName,
    required this.fromAvatarUrl,
    this.tweetContent,
  });

  factory NotificationModel.fromJson(PostgrestMap json) {
    return NotificationModel(
      id: json['id'] as int,
      fromUserId: json['from_user_id'] as String,
      type: json['type'] as String,
      tweetId: json['tweet_id'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      fromUsername: json['from_username'] as String? ?? '',
      fromDisplayName: json['from_display_name'] as String? ?? '',
      fromAvatarUrl: json['from_avatar_url'] as String? ?? '',
      tweetContent: json['tweet_content'] as String?,
    );
  }

  String get fullAvatarUrl {
    if (fromAvatarUrl.isEmpty) return '';
    if (fromAvatarUrl.startsWith('http')) return fromAvatarUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$fromAvatarUrl';
  }

  String get typeText {
    switch (type) {
      case 'like': return 'أعجب ب تغريدتك';
      case 'retweet': return 'أعاد تغريدك';
      case 'follow': return 'بدأ بمتابعتك';
      case 'reply': return 'رد على تغريدتك';
      case 'mention': return 'أشار إليك';
      case 'message': return 'أرسل لك رسالة';
      default: return '';
    }
  }
}