import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/models/tweet_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/feed_provider.dart';

class ComposeTweetSheet extends ConsumerStatefulWidget {
  final int? parentId;
  final TweetModel? quotedTweet;
  const ComposeTweetSheet({super.key, this.parentId, this.quotedTweet});

  static Future<bool?> show({required BuildContext context, int? parentId, TweetModel? quotedTweet}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => ComposeTweetSheet(parentId: parentId, quotedTweet: quotedTweet),
    );
  }

  @override
  ConsumerState<ComposeTweetSheet> createState() => _ComposeTweetSheetState();
}

class _ComposeTweetSheetState extends ConsumerState<ComposeTweetSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  int get _remainingChars => ApiConstants.maxTweetLength - _controller.text.length;
  bool get _canSubmit => _controller.text.trim().isNotEmpty && _controller.text.length <= ApiConstants.maxTweetLength && !_isSubmitting;

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= ApiConstants.maxMediaCount) {
      toastification.show(
        context: context,
        type: ToastificationType.warning,
        title: const Text('الحد الأقصى 4 صور'),
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }
    try {
      final pickedFile = await _imagePicker.pickImage(source: source, imageQuality: 80, maxWidth: 1080);
      if (pickedFile != null) setState(() => _selectedImages.add(File(pickedFile.path)));
    } catch (e) {
      if (mounted) {
        toastification.show(context: context, type: ToastificationType.error, title: const Text('فشل في اختيار الصورة'), autoCloseDuration: const Duration(seconds: 2));
      }
    }
  }

  void _removeImage(int index) => setState(() => _selectedImages.removeAt(index));

  Future<void> _submitTweet() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('لم يتم تسجيل الدخول');

      final List<String> mediaUrls = [];
      for (final imageFile in _selectedImages) {
        final ext = imageFile.path.split('.').last;
        final fileName = 'tweets/$userId/${DateTime.now().millisecondsSinceEpoch}_${mediaUrls.length}.$ext';
        await supabase.storage.from(ApiConstants.storageBucketMedia).upload(fileName, imageFile);
        mediaUrls.add(fileName);
      }

      await ref.read(feedProvider.notifier).createTweet(
            content: _controller.text.trim(),
            mediaUrls: mediaUrls,
            parentId: widget.parentId,
            quoteTweetId: widget.quotedTweet?.id,
          );

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.success,
          title: const Text('تم نشر التغريدة بنجاح'),
          autoCloseDuration: const Duration(seconds: 2),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        toastification.show(
          context: context,
          type: ToastificationType.error,
          title: Text('فشل في نشر التغريدة: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}'),
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final user = ref.watch(currentUserProvider);

    return Container(
      decoration: BoxDecoration(color: surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
          ),

          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  child: Text('إلغاء', style: TextStyle(fontSize: 15, color: textSecondary, fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _canSubmit ? AppColors.primary : AppColors.primary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _canSubmit ? _submitTweet : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('غرّد', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Reply indicator
          if (widget.parentId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(textDirection: TextDirection.rtl, children: [
                Icon(Icons.reply, size: 16, color: textSecondary),
                const SizedBox(width: 4),
                Text('الرد على التغريدة', style: TextStyle(fontSize: 13, color: textSecondary)),
              ]),
            ),

          const Divider(height: 1),

          // Content area with avatar
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      // Current user avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground,
                        backgroundImage: (user?.fullAvatarUrl ?? '').isNotEmpty ? CachedNetworkImageProvider(user!.fullAvatarUrl) : null,
                        child: (user?.fullAvatarUrl ?? '').isEmpty
                            ? Text(user?.displayName.isNotEmpty == true ? user!.displayName[0] : '?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: null,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.5, color: textPrimary),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'ماذا يحدث؟',
                            hintStyle: TextStyle(fontSize: 17, color: textSecondary),
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  // Selected images
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final file = _selectedImages[index];
                            return Stack(
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(file, width: 100, height: 100, fit: BoxFit.cover)),
                                Positioned(top: 4, left: 4, child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle),
                                    child: Icon(Icons.close, size: 16, color: textPrimary),
                                  ),
                                )),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5))),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                // Character counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _remainingChars < 0 ? AppColors.error.withValues(alpha: 0.1) : _remainingChars <= 20 ? AppColors.warning.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('$_remainingChars', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _remainingChars < 0 ? AppColors.error : _remainingChars <= 20 ? AppColors.warning : textSecondary)),
                ),
                const Spacer(),
                _buildActionIcon(Icons.image_outlined, () => _pickImage(ImageSource.gallery)),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.camera_alt_outlined, () => _pickImage(ImageSource.camera)),
                const SizedBox(width: 8),
                _buildActionIcon(Icons.emoji_emotions_outlined, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return IconButton(onPressed: onTap, icon: Icon(icon, color: AppColors.primary, size: 22), splashRadius: 24, constraints: const BoxConstraints(minWidth: 40, minHeight: 40), padding: EdgeInsets.zero);
  }
}