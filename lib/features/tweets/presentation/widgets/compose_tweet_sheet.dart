import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/tweet_model.dart';
import '../providers/feed_provider.dart';

// ─── Compose Tweet Sheet ─────────────────────────────────────────────────────

class ComposeTweetSheet extends ConsumerStatefulWidget {
  final int? parentId;
  final TweetModel? quotedTweet;

  const ComposeTweetSheet({
    super.key,
    this.parentId,
    this.quotedTweet,
  });

  /// Show the compose sheet as a modal bottom sheet.
  static Future<bool?> show({
    required BuildContext context,
    int? parentId,
    TweetModel? quotedTweet,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComposeTweetSheet(
        parentId: parentId,
        quotedTweet: quotedTweet,
      ),
    );
  }

  @override
  ConsumerState<ComposeTweetSheet> createState() => _ComposeTweetSheetState();
}

class _ComposeTweetSheetState extends ConsumerState<ComposeTweetSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _remainingChars => ApiConstants.maxTweetLength - _controller.text.length;
  bool get _canSubmit =>
      _controller.text.trim().isNotEmpty &&
      _controller.text.length <= ApiConstants.maxTweetLength &&
      !_isSubmitting;

  // ─── Image Picking ──────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= ApiConstants.maxMediaCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 4 صور')),
      );
      return;
    }

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في اختيار الصورة')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ─── Submit Tweet ──────────────────────────────────────────────────────

  Future<void> _submitTweet() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      // Upload images if any
      final List<String> mediaUrls = [];
      final supabase = Supabase.instance.client;

      for (final imageFile in _selectedImages) {
        final fileName =
            'tweets/${supabase.auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}_${mediaUrls.length}.jpg';
        await supabase.storage
            .from(ApiConstants.storageBucketMedia)
            .upload(fileName, imageFile);
        mediaUrls.add(fileName);
      }

      // Create the tweet via the feed provider
      await ref.read(feedProvider.notifier).createTweet(
            content: _controller.text.trim(),
            mediaUrls: mediaUrls,
            parentId: widget.parentId,
            quoteTweetId: widget.quotedTweet?.id,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في نشر التغريدة')),
        );
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ── Handle bar ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Top bar: Cancel & Tweet button ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Cancel button (right side in RTL)
                    TextButton(
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 15,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Tweet button (left side in RTL)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: _canSubmit
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _canSubmit ? _submitTweet : null,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'غرّد',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Reply indicator ──────────────────────────────────────
              if (widget.parentId != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'الرد على التغريدة',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Quoted tweet preview ────────────────────────────────
              if (widget.quotedTweet != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildQuotedTweetPreview(
                    widget.quotedTweet!,
                    theme,
                    isDark,
                  ),
                ),

              const Divider(height: 1),

              // ── Content area ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // TextField
                      TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 17,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'ماذا يحدث؟',
                          hintStyle: TextStyle(
                            fontSize: 17,
                            color: textSecondary,
                          ),
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      // Selected images thumbnails
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildImageThumbnails(isDark),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Bottom bar: character counter + action icons ────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Character counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _remainingChars < 0
                            ? AppColors.error.withValues(alpha: 0.1)
                            : _remainingChars <= 20
                                ? AppColors.warning.withValues(alpha: 0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '$_remainingChars',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _remainingChars < 0
                              ? AppColors.error
                              : _remainingChars <= 20
                                  ? AppColors.warning
                                  : textSecondary,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Gallery
                    _buildActionButton(
                      icon: Icons.image_outlined,
                      color: AppColors.primary,
                      onTap: _selectedImages.length >=
                              ApiConstants.maxMediaCount
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                    ),

                    const SizedBox(width: 8),

                    // Camera
                    _buildActionButton(
                      icon: Icons.camera_alt_outlined,
                      color: AppColors.primary,
                      onTap: _selectedImages.length >=
                              ApiConstants.maxMediaCount
                          ? null
                          : () => _pickImage(ImageSource.camera),
                    ),

                    const SizedBox(width: 8),

                    // Emoji placeholder
                    _buildActionButton(
                      icon: Icons.emoji_emotions_outlined,
                      color: AppColors.primary,
                      onTap: () {
                        // Emoji picker not yet implemented
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Action Button ──────────────────────────────────────────────────────

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 22),
      splashRadius: 24,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
    );
  }

  // ── Image Thumbnails ───────────────────────────────────────────────────

  Widget _buildImageThumbnails(bool isDark) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedImages.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final file = _selectedImages[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                // Remove button
                Positioned(
                  top: 4,
                  left: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Quoted Tweet Preview ───────────────────────────────────────────────

  Widget _buildQuotedTweetPreview(
      TweetModel tweet, ThemeData theme, bool isDark) {
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: tweet.fullAvatarUrl.isNotEmpty
                ? CachedNetworkImageProvider(tweet.fullAvatarUrl)
                : null,
            child: tweet.fullAvatarUrl.isEmpty
                ? Text(
                    tweet.displayName.isNotEmpty
                        ? tweet.displayName[0]
                        : '?',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      tweet.displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tweet.isVerified) ...[
                      const SizedBox(width: 3),
                      Icon(Icons.verified,
                          size: 14, color: AppColors.verified),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      '@${tweet.username}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tweet.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

