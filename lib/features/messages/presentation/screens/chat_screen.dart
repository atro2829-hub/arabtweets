import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/message_model.dart';
import '../providers/messages_provider.dart';

// ─── Chat Screen ─────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUsername;
  final String otherDisplayName;
  final String otherAvatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherDisplayName,
    required this.otherAvatarUrl,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  RealtimeChannel? _realtimeChannel;
  bool _sending = false;
  Timer? _debounce;

  String get _currentUserId => Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _subscribeToMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _realtimeChannel?.unsubscribe();
    _debounce?.cancel();
    super.dispose();
  }

  // ─── Realtime Subscription ─────────────────────────────────────────────────

  void _subscribeToMessages() {
    _realtimeChannel = Supabase.instance.client
        .channel('chat:${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final newMap = Map<String, dynamic>.from(payload.newRecord);
            // Only add if not from current user (our own send already adds it)
            if (newMap['sender_id'] != _currentUserId) {
              final profile =
                  newMap.remove('profiles') as Map<String, dynamic>? ?? {};
              newMap['sender_username'] = profile['username'] as String? ?? '';
              newMap['sender_avatar_url'] =
                  profile['avatar_url'] as String? ?? '';

              final newMessage = MessageModel.fromJson(newMap);
              ref.read(messagesProvider(widget.conversationId).notifier).addExternalMessage(newMessage);

              _scrollToBottom();
              _markAsRead();
            }
          },
        )
        .subscribe();
  }

  // ─── Mark as Read ──────────────────────────────────────────────────────────

  void _markAsRead() {
    ref
        .read(messagesProvider(widget.conversationId).notifier)
        .markAsRead();
  }

  // ─── Send Message ──────────────────────────────────────────────────────────

  Future<void> _sendMessage({String? mediaPath}) async {
    final content = _messageController.text.trim();
    if (content.isEmpty && mediaPath == null) return;
    if (_sending) return;

    setState(() => _sending = true);

    try {
      if (mediaPath != null) {
        // Upload image first
        final supabase = Supabase.instance.client;
        final ext = mediaPath.contains('.') ? '.${mediaPath.split('.').last}' : '';
        final fileName =
            '$_currentUserId/${const Uuid().v4()}$ext';

        await supabase.storage
            .from(ApiConstants.storageBucketMedia)
            .upload(fileName, File(mediaPath));

        final publicUrl =
            supabase.storage.from(ApiConstants.storageBucketMedia).getPublicUrl(fileName);

        await ref
            .read(messagesProvider(widget.conversationId).notifier)
            .sendMessageWithMedia(content: content, mediaUrl: publicUrl);
      } else {
        await ref
            .read(messagesProvider(widget.conversationId).notifier)
            .sendMessage(content);
      }

      // Invalidate conversations to update last message preview
      ref.invalidate(conversationsProvider);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('فشل إرسال الرسالة'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ─── Pick Image ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        await _sendMessage(mediaPath: image.path);
      }
    } catch (_) {}
  }

  // ─── Scroll to Bottom ──────────────────────────────────────────────────────

  void _scrollToBottom() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bubbleReceived =
        isDark ? AppColors.darkSurfaceDark : AppColors.lightSurface;

    final messagesAsync =
        ref.watch(messagesProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          textDirection: TextDirection.rtl,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor:
                  isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground,
              backgroundImage: widget.otherAvatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(widget.otherAvatarUrl)
                  : null,
              child: widget.otherAvatarUrl.isEmpty
                  ? Icon(Icons.person, size: 18, color: textSecondary)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    widget.otherDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    '@${widget.otherUsername}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'فشل في تحميل الرسائل',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(
                          messagesProvider(widget.conversationId)),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('إعادة المحاولة'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 64,
                          color: textSecondary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ابدأ المحادثة الآن',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'أرسل رسالتك الأولى إلى @${widget.otherUsername}',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 400.ms,
                        );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // reverse list so index 0 is newest
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == _currentUserId;
                    final showTail = index == messages.length - 1 ||
                        messages[messages.length - 1 - (index + 1)].senderId !=
                            message.senderId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: _buildMessageBubble(
                        message: message,
                        isMe: isMe,
                        showTail: showTail,
                        isDark: isDark,
                        bubbleReceived: bubbleReceived,
                        textSecondary: textSecondary,
                        textPrimary: textPrimary,
                        animIndex: index,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          _buildInputArea(isDark, surfaceColor, textPrimary, textSecondary),
        ],
      ),
    );
  }

  // ─── Message Bubble ────────────────────────────────────────────────────────

  Widget _buildMessageBubble({
    required MessageModel message,
    required bool isMe,
    required bool showTail,
    required bool isDark,
    required Color bubbleReceived,
    required Color textSecondary,
    required Color textPrimary,
    required int animIndex,
  }) {
    final timeText =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    // In RTL: sent (isMe) aligns to the right/end, received aligns to left/start
    return Align(
      alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMe ? 8 : 0,
          right: isMe ? 0 : 8,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          children: [
            // Media image
            if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : (showTail ? const Radius.circular(4) : const Radius.circular(16)),
                  bottomRight: isMe
                      ? (showTail ? const Radius.circular(4) : const Radius.circular(16))
                      : const Radius.circular(16),
                ),
                child: CachedNetworkImage(
                  imageUrl: message.fullMediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    width: double.infinity,
                    color: (isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground)
                        .withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 120,
                    width: double.infinity,
                    color: (isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground)
                        .withValues(alpha: 0.5),
                    child: const Icon(Icons.broken_image, size: 32),
                  ),
                ),
              ),

            // Text bubble
            if (message.content.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.only(
                  top: message.mediaUrl != null && message.mediaUrl!.isNotEmpty ? 0 : 10,
                  bottom: 6,
                  left: 14,
                  right: 14,
                ),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : bubbleReceived,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    // Sharp corner at the tail side
                    bottomLeft: isMe
                        ? const Radius.circular(16)
                        : (showTail
                            ? const Radius.circular(4)
                            : const Radius.circular(16)),
                    bottomRight: isMe
                        ? (showTail
                            ? const Radius.circular(4)
                            : const Radius.circular(16))
                        : const Radius.circular(16),
                  ),
                  // Subtle shadow for received
                  boxShadow: isMe
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    // Message text
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: isMe ? Colors.white : textPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),

                    const SizedBox(height: 4),

                    // Time + read indicator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.ltr,
                      children: [
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.7)
                                : textSecondary,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 14,
                            color: message.isRead
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty) ...[
              // Only media, no text - show time below image
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.ltr,
                  children: [
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 14,
                        color: message.isRead
                            ? AppColors.primary
                            : textSecondary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(
        delay: Duration(milliseconds: (animIndex < 5 ? animIndex : 5) * 50),
        duration: 250.ms,
      ).slideY(
        begin: 0.15,
        end: 0,
        duration: 250.ms,
      );
  }

  // ─── Input Area ────────────────────────────────────────────────────────────

  Widget _buildInputArea(
    bool isDark,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final fillColor =
        isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: borderColor, width: 0.5),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Image attach button
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: _sending ? null : _pickImage,
              icon: Icon(
                Icons.image_outlined,
                size: 22,
                color: AppColors.primary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),

          const SizedBox(width: 4),

          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _messageController,
                textDirection: TextDirection.rtl,
                maxLines: null,
                enabled: !_sending,
                style: TextStyle(
                  fontSize: 15,
                  color: textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                  ),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _sending
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: _sending
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => _sendMessage(),
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
          ),
        ],
      ),
    );
  }
}