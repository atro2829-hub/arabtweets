import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1DA1F2), Color(0xFF0ABDE3)],
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── App Icon ──────────────────────────────────────────────
                Image.asset(
                  'assets/icons/app_icon.png',
                  width: 140,
                  height: 140,
                  errorBuilder: (_, __, ___) => Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      end: const Offset(1, 1),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 24),

                // ── Title ─────────────────────────────────────────────────
                Text(
                  'Arabtweets',
                  style: GoogleFonts.cairo(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 200.ms),

                const SizedBox(height: 8),

                // ── Subtitle ──────────────────────────────────────────────
                Text(
                  'تغريد بالعربية',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 350.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 350.ms),

                const Spacer(flex: 2),

                // ── Buttons ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      // Register Button
                      _buildButton(
                        context,
                        label: 'تسجيل حساب جديد',
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF1DA1F2),
                        borderColor: Colors.transparent,
                        delay: 500.ms,
                        onTap: () => context.go('/register'),
                      ),
                      const SizedBox(height: 16),
                      // Login Button
                      _buildButton(
                        context,
                        label: 'تسجيل الدخول',
                        backgroundColor: Colors.transparent,
                        textColor: Colors.white,
                        borderColor: Colors.white,
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

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required Duration delay,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: delay, curve: Curves.easeOut)
        .slideY(begin: 0.4, end: 0, duration: 500.ms, delay: delay, curve: Curves.easeOutCubic);
  }
}