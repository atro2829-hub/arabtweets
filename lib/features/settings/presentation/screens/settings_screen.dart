import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─── Theme Provider (Riverpod Notifier with SharedPreferences) ──────────────────

class ThemeState {
  final bool isDarkMode;
  final double fontScale;

  const ThemeState({
    this.isDarkMode = false,
    this.fontScale = 1.0,
  });

  ThemeState copyWith({
    bool? isDarkMode,
    double? fontScale,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _darkModeKey = 'is_dark_mode';
  static const _fontScaleKey = 'font_scale';

  @override
  ThemeState build() {
    _loadPrefs();
    return const ThemeState();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_darkModeKey) ?? false;
      final scale = prefs.getDouble(_fontScaleKey) ?? 1.0;
      state = ThemeState(isDarkMode: isDark, fontScale: scale);
    } catch (_) {
      // Keep defaults
    }
  }

  Future<void> toggleDarkMode(bool value) async {
    state = state.copyWith(isDarkMode: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, value);
    } catch (_) {}
  }

  Future<void> setFontScale(double scale) async {
    state = state.copyWith(fontScale: scale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_fontScaleKey, scale);
    } catch (_) {}
  }
}

/// Global, non-auto-dispose provider so theme persists across screens.
final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);

// ─── Notification Settings Provider ─────────────────────────────────────────────

class NotificationSettings {
  final bool likes;
  final bool retweets;
  final bool follows;
  final bool replies;

  const NotificationSettings({
    this.likes = true,
    this.retweets = true,
    this.follows = true,
    this.replies = true,
  });

  NotificationSettings copyWith({
    bool? likes,
    bool? retweets,
    bool? follows,
    bool? replies,
  }) {
    return NotificationSettings(
      likes: likes ?? this.likes,
      retweets: retweets ?? this.retweets,
      follows: follows ?? this.follows,
      replies: replies ?? this.replies,
    );
  }
}

class NotificationSettingsNotifier
    extends Notifier<NotificationSettings> {
  static const _prefix = 'notif_';

  @override
  NotificationSettings build() {
    _loadPrefs();
    return const NotificationSettings();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = NotificationSettings(
        likes: prefs.getBool('${_prefix}likes') ?? true,
        retweets: prefs.getBool('${_prefix}retweets') ?? true,
        follows: prefs.getBool('${_prefix}follows') ?? true,
        replies: prefs.getBool('${_prefix}replies') ?? true,
      );
    } catch (_) {}
  }

  Future<void> _saveKey(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$key', value);
    } catch (_) {}
  }

  Future<void> setLikes(bool value) async {
    state = state.copyWith(likes: value);
    await _saveKey('likes', value);
  }

  Future<void> setRetweets(bool value) async {
    state = state.copyWith(retweets: value);
    await _saveKey('retweets', value);
  }

  Future<void> setFollows(bool value) async {
    state = state.copyWith(follows: value);
    await _saveKey('follows', value);
  }

  Future<void> setReplies(bool value) async {
    state = state.copyWith(replies: value);
    await _saveKey('replies', value);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);

// ─── Privacy Settings Provider ──────────────────────────────────────────────────

class PrivacySettings {
  final bool tweetsVisible;
  final bool protectAccount;

  const PrivacySettings({
    this.tweetsVisible = true,
    this.protectAccount = false,
  });

  PrivacySettings copyWith({
    bool? tweetsVisible,
    bool? protectAccount,
  }) {
    return PrivacySettings(
      tweetsVisible: tweetsVisible ?? this.tweetsVisible,
      protectAccount: protectAccount ?? this.protectAccount,
    );
  }
}

class PrivacySettingsNotifier extends Notifier<PrivacySettings> {
  static const _prefix = 'privacy_';

  @override
  PrivacySettings build() {
    _loadPrefs();
    return const PrivacySettings();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = PrivacySettings(
        tweetsVisible: prefs.getBool('${_prefix}tweets_visible') ?? true,
        protectAccount: prefs.getBool('${_prefix}protect') ?? false,
      );
    } catch (_) {}
  }

  Future<void> _saveKey(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$key', value);
    } catch (_) {}
  }

  Future<void> setTweetsVisible(bool value) async {
    state = state.copyWith(tweetsVisible: value);
    await _saveKey('tweets_visible', value);
  }

  Future<void> setProtectAccount(bool value) async {
    state = state.copyWith(protectAccount: value);
    await _saveKey('protect', value);
  }
}

final privacySettingsProvider =
    NotifierProvider<PrivacySettingsNotifier, PrivacySettings>(
  PrivacySettingsNotifier.new,
);

// ─── Settings Screen ────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final dividerColor =
        isDark ? AppColors.darkDivider : AppColors.lightDivider;

    final currentUser = ref.watch(currentUserProvider);
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'الإعدادات والخصوصية',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── حسابك ──
          _SectionHeader(
            title: 'حسابك',
            textSecondary: textSecondary,
          ),
          Container(
            color: surfaceColor,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.email_outlined,
                  iconColor: AppColors.primary,
                  title: 'البريد الإلكتروني',
                  subtitle: email,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Text(
                    email,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                    textDirection: TextDirection.ltr,
                    overflow: TextOverflow.ellipsis,
                  ),
                  dividerColor: dividerColor,
                  enabled: false,
                ),
                _SettingsTile(
                  icon: Icons.lock_outline,
                  iconColor: AppColors.primary,
                  title: 'تغيير كلمة المرور',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Icon(Icons.chevron_left, color: textSecondary, size: 20),
                  dividerColor: dividerColor,
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
                _SettingsTile(
                  icon: Icons.phone_outlined,
                  iconColor: AppColors.primary,
                  title: 'الهاتف',
                  subtitle: currentUser?.id != null ? 'غير محدد' : null,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'غير محدد',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_left, color: textSecondary, size: 20),
                    ],
                  ),
                  dividerColor: dividerColor,
                  enabled: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── المظهر والوصول ──
          _SectionHeader(
            title: 'المظهر والوصول',
            textSecondary: textSecondary,
          ),
          Container(
            color: surfaceColor,
            child: Column(
              children: [
                // Dark mode toggle
                SwitchListTile(
                  value: ref.watch(themeProvider).isDarkMode,
                  onChanged: (value) {
                    ref.read(themeProvider.notifier).toggleDarkMode(value);
                  },
                  secondary: Icon(
                    Icons.dark_mode_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'الوضع الداكن',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(),
                ),
                Divider(height: 0.5, thickness: 0.5, color: dividerColor, indent: 56, endIndent: 16),
                // Font size
                _SettingsTile(
                  icon: Icons.text_fields,
                  iconColor: AppColors.primary,
                  title: 'حجم الخط',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(ref.watch(themeProvider).fontScale * 100).round()}%',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_left, color: textSecondary, size: 20),
                    ],
                  ),
                  dividerColor: dividerColor,
                  onTap: () => _showFontSizeDialog(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── الخصوصية ──
          _SectionHeader(
            title: 'الخصوصية',
            textSecondary: textSecondary,
          ),
          Container(
            color: surfaceColor,
            child: Column(
              children: [
                SwitchListTile(
                  value: ref.watch(privacySettingsProvider).tweetsVisible,
                  onChanged: (value) {
                    ref.read(privacySettingsProvider.notifier).setTweetsVisible(value);
                  },
                  secondary: Icon(
                    Icons.public_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'من يمكنه رؤية تغريداتك',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Text(
                    ref.watch(privacySettingsProvider).tweetsVisible
                        ? 'الجميع'
                        : 'المتابعون فقط',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                    textDirection: TextDirection.rtl,
                  ),
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(),
                ),
                Divider(height: 0.5, thickness: 0.5, color: dividerColor, indent: 56, endIndent: 16),
                SwitchListTile(
                  value: ref.watch(privacySettingsProvider).protectAccount,
                  onChanged: (value) {
                    ref.read(privacySettingsProvider.notifier).setProtectAccount(value);
                  },
                  secondary: Icon(
                    Icons.shield_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'حماية حسابك',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Text(
                    ref.watch(privacySettingsProvider).protectAccount
                        ? 'حسابك محمي'
                        : 'حسابك عام',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                    textDirection: TextDirection.rtl,
                  ),
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── الإشعارات ──
          _SectionHeader(
            title: 'الإشعارات',
            textSecondary: textSecondary,
          ),
          Container(
            color: surfaceColor,
            child: Column(
              children: [
                SwitchListTile(
                  value: ref.watch(notificationSettingsProvider).likes,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).setLikes(value);
                  },
                  secondary: Icon(
                    Icons.favorite_outline,
                    color: AppColors.like,
                  ),
                  title: Text(
                    'إعجابات',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(),
                ),
                Divider(height: 0.5, thickness: 0.5, color: dividerColor, indent: 56, endIndent: 16),
                SwitchListTile(
                  value: ref.watch(notificationSettingsProvider).retweets,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).setRetweets(value);
                  },
                  secondary: Icon(
                    Icons.repeat,
                    color: AppColors.retweet,
                  ),
                  title: Text(
                    'ريتويتات',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(),
                ),
                Divider(height: 0.5, thickness: 0.5, color: dividerColor, indent: 56, endIndent: 16),
                SwitchListTile(
                  value: ref.watch(notificationSettingsProvider).follows,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).setFollows(value);
                  },
                  secondary: Icon(
                    Icons.person_add_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'متابعات',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(),
                ),
                Divider(height: 0.5, thickness: 0.5, color: dividerColor, indent: 56, endIndent: 16),
                SwitchListTile(
                  value: ref.watch(notificationSettingsProvider).replies,
                  onChanged: (value) {
                    ref.read(notificationSettingsProvider.notifier).setReplies(value);
                  },
                  secondary: Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'ردود',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: const RoundedRectangleBorder(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── حول ──
          _SectionHeader(
            title: 'حول',
            textSecondary: textSecondary,
          ),
          Container(
            color: surfaceColor,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: AppColors.primary,
                  title: 'نسخة التطبيق',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                  dividerColor: dividerColor,
                  enabled: false,
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.primary,
                  title: 'سياسة الخصوصية',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Icon(Icons.chevron_left, color: textSecondary, size: 20),
                  dividerColor: dividerColor,
                  onTap: () => context.push('/privacy'),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.primary,
                  title: 'شروط الخدمة',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Icon(Icons.chevron_left, color: textSecondary, size: 20),
                  dividerColor: dividerColor,
                  onTap: () => context.push('/terms'),
                ),
                _SettingsTile(
                  icon: Icons.cookie_outlined,
                  iconColor: AppColors.primary,
                  title: 'ملفات تعريف الارتباط',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Icon(Icons.chevron_left, color: textSecondary, size: 20),
                  dividerColor: dividerColor,
                  onTap: () => context.push('/cookies'),
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: AppColors.primary,
                  title: 'عن Arabtweets',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Icon(Icons.chevron_left, color: textSecondary, size: 20),
                  dividerColor: dividerColor,
                  onTap: () => context.push('/about'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Admin (only visible to admins) ──
          Builder(
            builder: (context) {
              final auth = ref.watch(authProvider);
              final isAdmin = auth.user?.isAdmin == true;
              if (!isAdmin) return const SizedBox.shrink();
              return Column(
                children: [
                  _SectionHeader(
                    title: 'الإدارة',
                    textSecondary: AppColors.warning,
                  ),
                  Container(
                    color: surfaceColor,
                    child: _SettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: AppColors.warning,
                      title: 'لوحة الإدارة',
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      trailing: Icon(Icons.chevron_left, color: textSecondary, size: 20),
                      dividerColor: dividerColor,
                      onTap: () => context.push('/admin'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

          // ── Danger Zone ──
          _SectionHeader(
            title: 'منطقة الخطر',
            textSecondary: AppColors.error,
          ),
          Container(
            color: surfaceColor,
            child: _SettingsTile(
              icon: Icons.delete_forever_outlined,
              iconColor: AppColors.error,
              title: 'حذف الحساب',
              textPrimary: AppColors.error,
              textSecondary: textSecondary,
              trailing: Icon(Icons.chevron_left, color: AppColors.error, size: 20),
              dividerColor: dividerColor,
              onTap: () => _showDeleteAccountDialog(context, ref),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────────────────

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text(
                  'تغيير كلمة المرور',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور الحالية',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'كلمة المرور الجديدة',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (v.length < 6) return 'الحد الأدنى 6 أحرف';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'تأكيد كلمة المرور الجديدة',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if (v != newController.text) {
                            return 'كلمات المرور غير متطابقة';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => loading = true);
                            try {
                              await Supabase.instance.client.auth
                                  .updateUser(
                                UserAttributes(
                                  password: newController.text.trim(),
                                ),
                              );
                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم تغيير كلمة المرور بنجاح'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } catch (e) {
                              if (!dialogContext.mounted) return;
                              setDialogState(() => loading = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('فشل تغيير كلمة المرور'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('تغيير'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    });
  }

  // ─── Font Size Dialog ──────────────────────────────────────────────────────

  void _showFontSizeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'حجم الخط',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                final currentScale =
                    ref.read(themeProvider).fontScale;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      value: currentScale,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      label: '${(currentScale * 100).round()}%',
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        ref
                            .read(themeProvider.notifier)
                            .setFontScale(value);
                        setDialogState(() {});
                      },
                    ),
                    Text(
                      '${(currentScale * 100).round()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkSurfaceDark
                                : AppColors.lightBackground)
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'تجربة النص',
                        style: TextStyle(
                          fontSize: 15 * currentScale,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'تم',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Delete Account Dialog ─────────────────────────────────────────────────

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final confirmController = TextEditingController();
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text(
                      'حذف الحساب',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سيتم حذف حسابك نهائيًا وجميع بياناتك. لا يمكن التراجع عن هذا الإجراء.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                        height: 1.5,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'اكتب "حذف" للتأكيد:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      textDirection: TextDirection.rtl,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'حذف',
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkSurfaceDark
                                : AppColors.lightBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('إلغاء'),
                  ),
                  ElevatedButton(
                    onPressed: (loading ||
                            confirmController.text.trim() != 'حذف')
                        ? null
                        : () async {
                            setDialogState(() => loading = true);
                            try {
                              final supabase = Supabase.instance.client;
                              final userId = supabase.auth.currentUser?.id;
                              if (userId != null) {
                                await supabase
                                    .from('profiles')
                                    .delete()
                                    .eq('id', userId);
                              }
                              await supabase.auth.signOut();
                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop();
                              if (!context.mounted) return;
                              context.go('/welcome');
                            } catch (e) {
                              if (!dialogContext.mounted) return;
                              setDialogState(() => loading = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('فشل حذف الحساب'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.error.withValues(alpha: 0.4),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('حذف نهائي'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      confirmController.dispose();
    });
  }
}

// ─── Reusable Widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color textSecondary;

  const _SectionHeader({
    required this.title,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 16, top: 12, bottom: 6),
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textSecondary.withValues(alpha: 0.8),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color textPrimary;
  final Color textSecondary;
  final Widget trailing;
  final Color dividerColor;
  final VoidCallback? onTap;
  final bool enabled;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
    required this.trailing,
    required this.dividerColor,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing,
                ],
              ),
            ),
            const Divider(height: 0.5, thickness: 0.5),
          ],
        ),
      ),
    );
  }
}