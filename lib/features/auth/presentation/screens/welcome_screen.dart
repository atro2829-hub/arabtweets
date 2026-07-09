import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_icons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const Spacer(flex: 3),

                // App Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(begin: const Offset(0.6, 0.6), end: const Offset(1, 1), duration: 600.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 28),

                // Title
                Text(
                  'AdenTweet',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 200.ms),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'منصة التغريد',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? const Color(0xFF71767B) : const Color(0xFF536471),
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 350.ms).slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 350.ms),

                const Spacer(flex: 2),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildButton(
                        context,
                        label: 'تسجيل حساب جديد',
                        backgroundColor: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
                        textColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
                        borderColor: Colors.transparent,
                        delay: 500.ms,
                        onTap: () => context.go('/register'),
                      ),
                      const SizedBox(height: 14),
                      _buildButton(
                        context,
                        label: 'تسجيل الدخول',
                        backgroundColor: Colors.transparent,
                        textColor: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000),
                        borderColor: isDark ? const Color(0xFF536471) : const Color(0xFF536471),
                        delay: 650.ms,
                        onTap: () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required Duration delay,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: delay).slideY(begin: 0.4, end: 0, duration: 500.ms, delay: delay);
  }
}