import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';

// ─── About Screen ──────────────────────────────────────────────────────────────

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
    final dividerColor =
        isDark ? AppColors.darkDivider : AppColors.lightDivider;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'عن التطبيق',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          children: [
            // ── App Icon ─────────────────────────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: 20),

            // ── App Name ─────────────────────────────────────────────────
            Text(
              'AdenTweet',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: textPrimary,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                  begin: 0.15,
                  end: 0,
                  duration: 400.ms,
                ),

            const SizedBox(height: 6),

            // ── Version ──────────────────────────────────────────────────
            Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 28),

            // ── Description Card ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Text(
                'منصة تواصل اجتماعي عربية تهدف لتوفير تجربة تغريد مميزة باللغة العربية. نؤمن بأن المحتوى العربي يستحق منصة مخصصة تلبي احتياجات المستخدم العرب وتوفر تجربة سلسة وممتعة.',
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  height: 1.7,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                ),

            const SizedBox(height: 24),

            // ── Developer Section ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'تطوير',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'مؤسسة QTBM',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'شركة متخصصة في تطوير الحلول التقنية والمنصات الرقمية المبتكرة',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                ),

            const SizedBox(height: 20),

            // ── Contact Email ───────────────────────────────────────────
            InkWell(
              onTap: () async {
                final uri = Uri.parse('mailto:m775371829@gmail.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mail_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'm775371829@gmail.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),

            const SizedBox(height: 28),

            // ── Divider ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Divider(
                thickness: 1,
                color: dividerColor,
              ),
            ),

            const SizedBox(height: 20),

            // ── Links Section ───────────────────────────────────────────
            _buildLinkTile(
              context: context,
              icon: Icons.description_outlined,
              title: 'شروط الاستخدام',
              onTap: () => context.push('/terms'),
              isDark: isDark,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dividerColor: dividerColor,
              delay: 700,
            ),
            _buildLinkTile(
              context: context,
              icon: Icons.privacy_tip_outlined,
              title: 'سياسة الخصوصية',
              onTap: () => context.push('/privacy'),
              isDark: isDark,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dividerColor: dividerColor,
              delay: 750,
              showDivider: true,
            ),
            _buildLinkTile(
              context: context,
              icon: Icons.cookie_outlined,
              title: 'سياسة ملفات تعريف الارتباط',
              onTap: () => context.push('/cookies'),
              isDark: isDark,
              surfaceColor: surfaceColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dividerColor: dividerColor,
              delay: 800,
            ),

            const SizedBox(height: 32),

            // ── Footer ──────────────────────────────────────────────────
            Text(
              '© 2025 مؤسسة QTBM. جميع الحقوق محفوظة.',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ).animate().fadeIn(delay: 900.ms, duration: 400.ms),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Link Tile ──────────────────────────────────────────────────────────

  Widget _buildLinkTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
    required Color surfaceColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color dividerColor,
    required int delay,
    bool showDivider = true,
  }) {
    final borderRadius = showDivider
        ? const BorderRadius.only(topLeft: Radius.circular(12))
        : const BorderRadius.only(bottomLeft: Radius.circular(12));

    return Column(
      children: [
        if (showDivider)
          Divider(height: 0.5, thickness: 0.5, color: dividerColor, indent: 50),
        InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                Icon(Icons.chevron_left, color: textSecondary, size: 20),
              ],
            ),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms),
        if (!showDivider)
          Divider(height: 0.5, thickness: 0.5, color: dividerColor, indent: 50),
      ],
    );
  }
}