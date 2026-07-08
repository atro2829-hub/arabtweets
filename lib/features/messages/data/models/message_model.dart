import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestMap;

class MessageModel {
  final int id;
  final String senderId;
  final String content;
  final String? mediaUrl;
  final bool isRead;
  final DateTime createdAt;
  final String senderUsername;
  final String senderAvatarUrl;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.mediaUrl,
    required this.isRead,
    required this.createdAt,
    required this.senderUsername,
    required this.senderAvatarUrl,
  });

  factory MessageModel.fromJson(PostgrestMap json) {
    return MessageModel(
      id: json['id'] as int,
      senderId: json['sender_id'] as String,
      content: json['content'] as String? ?? '',
      mediaUrl: json['media_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      senderUsername: json['sender_username'] as String? ?? '',
      senderAvatarUrl: json['sender_avatar_url'] as String? ?? '',
    );
  }

  String get fullAvatarUrl {
    if (senderAvatarUrl.isEmpty) return '';
    if (senderAvatarUrl.startsWith('http')) return senderAvatarUrl;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$senderAvatarUrl';
  }

  String get fullMediaUrl {
    if (mediaUrl == null || mediaUrl!.isEmpty) return '';
    if (mediaUrl!.startsWith('http')) return mediaUrl!;
    return 'https://buvcyaxgxrbjdikefsyq.supabase.co/storage/v1/object/public/$mediaUrl';
  }
}