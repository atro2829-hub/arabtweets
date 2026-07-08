import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

// ─── Edit Profile Screen ──────────────────────────────────────────────────────

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  File? _avatarFile;
  File? _coverFile;
  String? _avatarPreviewUrl;
  String? _coverPreviewUrl;

  bool _avatarUploading = false;
  bool _coverUploading = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _initFields() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.displayName;
      _usernameController.text = user.username;
      _bioController.text = user.bio;
      _locationController.text = user.location;
      _websiteController.text = user.website;
      _avatarPreviewUrl = user.fullAvatarUrl;
      _coverPreviewUrl = user.fullCoverUrl;
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _avatarFile = File(image.path);
        _avatarPreviewUrl = null;
      });
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _coverFile = File(image.path);
        _coverPreviewUrl = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _saving = true);

    final success = await ref.read(editProfileProvider.notifier).updateProfile(
          displayName: _nameController.text,
          username: _usernameController.text,
          bio: _bioController.text,
          location: _locationController.text,
          website: _websiteController.text,
          avatarFile: _avatarFile,
          coverFile: _coverFile,
          currentAvatarPath: user.avatarUrl,
          currentCoverPath: user.coverUrl,
        );

    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      context.pop();
    } else {
      final editState = ref.read(editProfileProvider);
      if (editState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(editState.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    // Initialize text fields from current user
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser != null &&
        _nameController.text.isEmpty &&
        _usernameController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initFields());
    }

    final editState = ref.watch(editProfileProvider);
    final isLoading = _saving || editState.status == EditProfileStatus.loading;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            size: 24,
            color: textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'تعديل الملف الشخصي',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: ElevatedButton(
              onPressed: isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'حفظ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              // Cover image area
              _buildCoverImage(isDark),
              const SizedBox(height: 40),

              // Avatar section
              _buildAvatarSection(isDark, textSecondary),
              const SizedBox(height: 24),

              // Form fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'الاسم',
                      hint: 'الاسم المعروض',
                      maxLength: ApiConstants.maxDisplayNameLength,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'الاسم مطلوب';
                        }
                        if (value.trim().length < 2) {
                          return 'الاسم قصير جدًا';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _usernameController,
                      label: 'اسم المستخدم',
                      hint: '@username',
                      maxLength: ApiConstants.maxUsernameLength,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                      prefixText: '@',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اسم المستخدم مطلوب';
                        }
                        if (value.trim().length < 3) {
                          return 'اسم المستخدم قصير جدًا';
                        }
                        final regex = RegExp(r'^[a-zA-Z0-9_]+$');
                        if (!regex.hasMatch(value.trim())) {
                          return 'يُسمح فقط بالحروف الإنجليزية والأرقام والشرطة السفلية';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildBioField(textPrimary, textSecondary, isDark),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _locationController,
                      label: 'الموقع',
                      hint: 'مثال: الرياض، السعودية',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _websiteController,
                      label: 'الموقع الإلكتروني',
                      hint: 'https://example.com',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Cover Image ─────────────────────────────────────────────────────────

  Widget _buildCoverImage(bool isDark) {
    return GestureDetector(
      onTap: _pickCover,
      child: Stack(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            color: isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground,
            child: _coverFile != null
                ? Image.file(
                    _coverFile!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 150,
                  )
                : _coverPreviewUrl != null && _coverPreviewUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _coverPreviewUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 150,
                        placeholder: (context, url) => Container(
                          color: isDark
                              ? AppColors.darkSurfaceDark
                              : AppColors.lightBackground,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark
                              ? AppColors.darkSurfaceDark
                              : AppColors.lightBackground,
                          child: Icon(
                            Icons.image,
                            size: 40,
                            color: AppColors.lightTextSecondary
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary)
                              .withValues(alpha: 0.5),
                        ),
                      ),
          ),
          if (_coverUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'تغيير الغلاف',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Avatar Section ──────────────────────────────────────────────────────

  Widget _buildAvatarSection(bool isDark, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: ClipOval(
                    child: _avatarFile != null
                        ? Image.file(
                            _avatarFile!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                          )
                        : _avatarPreviewUrl != null &&
                                _avatarPreviewUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _avatarPreviewUrl!,
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                placeholder: (context, url) => Container(
                                  width: 80,
                                  height: 80,
                                  color: isDark
                                      ? AppColors.darkSurfaceDark
                                      : AppColors.lightBackground,
                                  child: const Icon(Icons.person, size: 32),
                                ),
                                errorWidget: (context, url, error) =>
                                    Container(
                                  width: 80,
                                  height: 80,
                                  color: isDark
                                      ? AppColors.darkSurfaceDark
                                      : AppColors.lightBackground,
                                  child: const Icon(Icons.person, size: 32),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: isDark
                                    ? AppColors.darkSurfaceDark
                                    : AppColors.lightBackground,
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 28,
                                  color: textSecondary.withValues(alpha: 0.5),
                                ),
                              ),
                  ),
                ),
                if (_avatarUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black38,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'تغيير الصورة الشخصية',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
    );
  }

  // ─── Text Field ──────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLength,
    String? prefixText,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final fillColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextFormField(
            controller: controller,
            maxLength: maxLength,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: 16,
              color: textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: textSecondary, fontSize: 14),
              filled: true,
              fillColor: fillColor,
              prefixIcon: prefixText != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, top: 14),
                      child: Text(
                        prefixText,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              counterStyle: TextStyle(
                color: textSecondary,
                fontSize: 12,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Bio Field with Counter ──────────────────────────────────────────────

  Widget _buildBioField(
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final fillColor = isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground;
    final remaining = ApiConstants.maxBioLength - _bioController.text.length;
    final isOver = remaining < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'نبذة',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.rtl,
          child: TextFormField(
            controller: _bioController,
            maxLength: ApiConstants.maxBioLength,
            maxLines: 4,
            minLines: 3,
            style: TextStyle(
              fontSize: 16,
              color: textPrimary,
              height: 1.4,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'أخبرنا قليلاً عن نفسك...',
              hintStyle: TextStyle(color: textSecondary, fontSize: 14),
              filled: true,
              fillColor: fillColor,
              alignLabelWithHint: true,
              counterStyle: TextStyle(
                color: isOver ? AppColors.error : textSecondary,
                fontSize: 12,
              ),
              counterText: '$remaining متبقي',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}