import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestMap;

class ConversationModel {
  final String conversationId;
  final String otherUserId;
  final String otherUsername;
  final String otherDisplayName;
  final String otherAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherDisplayName,
    required this.otherAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(PostgrestMap json) {
    return ConversationModel(
      conversationId: json['conversation_id'] as String,
      otherUserId: json['other_user_id'] as String,
      otherUsername: json['other_username'] as String? ?? '',
      otherDisplayName: json['other_display_name'] as String? ?? '',
      otherAvatarUrl: json['other_avatar_url'] as String? ?? '',
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  String get fullAvatarUrl {
    if (otherAvatarUrl.isEmpty) return '';
    if (otherAvatarUrl.startsWith('http')) return otherAvatarUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$otherAvatarUrl';
  }
}