import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../messages/data/models/conversation_model.dart';
import '../../../messages/data/models/message_model.dart';
import '../../../../core/constants/api_constants.dart';

// ─── Conversations Notifier ───────────────────────────────────────────────────

class ConversationsNotifier extends AsyncNotifier<List<ConversationModel>> {
  final _supabase = Supabase.instance.client;

  @override
  Future<List<ConversationModel>> build() async {
    return _fetchConversations();
  }

  Future<List<ConversationModel>> _fetchConversations() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_user_conversations',
        params: {'p_user_id': userId},
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];

      return data
          .map((item) =>
              ConversationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل المحادثات: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل المحادثات');
    }
  }

  /// Refresh conversations list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchConversations());
  }
}

// ─── Messages Notifier ─────────────────────────────────────────────────────────

class MessagesNotifier extends AsyncNotifier<List<MessageModel>> {
  final _supabase = Supabase.instance.client;
  String conversationId = '';

  @override
  Future<List<MessageModel>> build() async {
    return _fetchMessages(conversationId);
  }

  Future<List<MessageModel>> _fetchMessages(String conversationId) async {
    try {
      final response = await _supabase.rpc(
        'get_conversation_messages',
        params: {
          'p_conversation_id': conversationId,
          'p_limit': ApiConstants.messagesPerPage,
          'p_offset': 0,
        },
      );

      final List<dynamic> data = response as List<dynamic>? ?? [];

      return data
          .map((item) =>
              MessageModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('فشل في تحميل الرسائل: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء تحميل الرسائل');
    }
  }

  /// Send a new message to this conversation.
  Future<void> sendMessage(String content) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Insert the message
      final response = await _supabase.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content.trim(),
        'is_read': false,
      }).select('''
        id,
        sender_id,
        content,
        media_url,
        is_read,
        created_at,
        profiles!messages_sender_id_fkey(
          username,
          avatar_url
        )
      ''').single();

      final messageMap = Map<String, dynamic>.from(
          response as Map<String, dynamic>);
      final profile =
          messageMap.remove('profiles') as Map<String, dynamic>? ?? {};
      messageMap['sender_username'] = profile['username'] as String? ?? '';
      messageMap['sender_avatar_url'] = profile['avatar_url'] as String? ?? '';

      final newMessage = MessageModel.fromJson(messageMap);

      // Append to current list
      final current = state.value ?? [];
      state = AsyncData([...current, newMessage]);

      // Update conversation's updated_at
      await _supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
    } catch (e) {
      rethrow;
    }
  }

  /// Add a message from an external source (e.g., realtime subscription).
  void addExternalMessage(MessageModel message) {
    final current = state.value ?? [];
    state = AsyncData([...current, message]);
  }

  /// Mark messages as read for this conversation.
  Future<void> markAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('conversation_participants')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      // Silently fail
    }
  }

  /// Send a new message with an attached media URL.
  Future<void> sendMessageWithMedia({
    required String content,
    required String mediaUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final insertMap = <String, dynamic>{
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content.trim(),
        'media_url': mediaUrl,
        'is_read': false,
      };

      final response = await _supabase.from('messages').insert(insertMap).select('''
        id,
        sender_id,
        content,
        media_url,
        is_read,
        created_at,
        profiles!messages_sender_id_fkey(
          username,
          avatar_url
        )
      ''').single();

      final messageMap = Map<String, dynamic>.from(
          response as Map<String, dynamic>);
      final profile =
          messageMap.remove('profiles') as Map<String, dynamic>? ?? {};
      messageMap['sender_username'] = profile['username'] as String? ?? '';
      messageMap['sender_avatar_url'] = profile['avatar_url'] as String? ?? '';

      final newMessage = MessageModel.fromJson(messageMap);

      final current = state.value ?? [];
      state = AsyncData([...current, newMessage]);

      await _supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh messages list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _fetchMessages(conversationId));
  }
}

// ─── Create Or Get Conversation ───────────────────────────────────────────────

class CreateConversationNotifier extends AsyncNotifier<String?> {
  final _supabase = Supabase.instance.client;

  @override
  Future<String?> build() async {
    return null;
  }

  /// Check if a conversation exists between the current user and another user.
  /// If not, create one. Returns the conversation ID.
  Future<String> createOrGetConversation(String otherUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('لم يتم تسجيل الدخول');

    try {
      // Check if a conversation already exists between these two users
      final existing = await _supabase
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      final List<dynamic> myConversations = existing as List<dynamic>;
      for (final conv in myConversations) {
        final convId = conv['conversation_id'] as String;
        final otherParticipant = await _supabase
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', convId)
            .neq('user_id', userId)
            .maybeSingle();

        if (otherParticipant != null &&
            otherParticipant['user_id'] == otherUserId) {
          return convId;
        }
      }

      // Create new conversation
      final newConvResponse = await _supabase
          .from('conversations')
          .insert({'updated_at': DateTime.now().toIso8601String()})
          .select('id')
          .single();

      final conversationId = newConvResponse['id'] as String;

      // Add both participants
      await _supabase.from('conversation_participants').insert([
        {
          'conversation_id': conversationId,
          'user_id': userId,
          'last_read_at': DateTime.now().toIso8601String(),
        },
        {
          'conversation_id': conversationId,
          'user_id': otherUserId,
          'last_read_at': DateTime.now().toIso8601String(),
        },
      ]);

      return conversationId;
    } on PostgrestException catch (e) {
      throw Exception('فشل في إنشاء المحادثة: ${e.message}');
    } catch (e) {
      throw Exception('حدث خطأ أثناء إنشاء المحادثة');
    }
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────

/// User's conversations list provider.
final conversationsProvider = AsyncNotifierProvider.autoDispose<
    ConversationsNotifier, List<ConversationModel>>(
  ConversationsNotifier.new,
);

/// Messages in a conversation, keyed by conversationId.
final messagesProvider = AsyncNotifierProvider.autoDispose.family<
    MessagesNotifier, List<MessageModel>, String>(
  (arg) => MessagesNotifier()..conversationId = arg,
);

/// Create or get conversation provider.
final createConversationProvider = AsyncNotifierProvider.autoDispose<
    CreateConversationNotifier, String?>(
  CreateConversationNotifier.new,
);

// ─── Top-level convenience functions ───────────────────────────────────────────

/// Send a message to a conversation and optionally invalidate conversations list.
Future<void> sendMessage(Ref ref, {
  required String conversationId,
  required String content,
}) async {
  await ref.read(messagesProvider(conversationId).notifier).sendMessage(content);
  // Refresh conversations to update last message preview
  ref.invalidate(conversationsProvider);
}

/// Create or get a conversation with another user. Returns conversation ID.
Future<String> createOrGetConversation(Ref ref, String otherUserId) async {
  return ref
      .read(createConversationProvider.notifier)
      .createOrGetConversation(otherUserId);
}