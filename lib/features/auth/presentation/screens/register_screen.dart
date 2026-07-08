import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

// ─── Username Availability ──────────────────────────────────────────────────

enum UsernameAvailability {
  unknown,
  checking,
  available,
  taken,
}

// ─── Password Strength ──────────────────────────────────────────────────────

enum PasswordStrength { weak, medium, strong }

PasswordStrength _evaluatePasswordStrength(String password) {
  if (password.length < 6) return PasswordStrength.weak;

  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[a-z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[^a-zA-Z0-9]').hasMatch(password)) score++;

  if (score <= 2) return PasswordStrength.weak;
  if (score <= 4) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

// ─── Register Screen ────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  UsernameAvailability _usernameAvailability = UsernameAvailability.unknown;
  Timer? _usernameDebounce;
  String _lastCheckedUsername = '';

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  // ── Username Availability Check ──────────────────────────────────────

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();

    if (value.isEmpty || value.length < 3) {
      setState(() => _usernameAvailability = UsernameAvailability.unknown);
      return;
    }

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      setState(() => _usernameAvailability = UsernameAvailability.taken);
      return;
    }

    if (value == _lastCheckedUsername) return;

    setState(() => _usernameAvailability = UsernameAvailability.checking);

    _usernameDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      try {
        final supabase = Supabase.instance.client;
        final result = await supabase
            .from('profiles')
            .select('id')
            .eq('username', value.trim())
            .maybeSingle();

        if (!mounted) return;
        _lastCheckedUsername = value.trim();
        setState(() {
          _usernameAvailability =
              result == null ? UsernameAvailability.available : UsernameAvailability.taken;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _usernameAvailability = UsernameAvailability.unknown);
      }
    });
  }

  // ── Submit ──────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Ensure username is available before submission
    if (_usernameAvailability != UsernameAvailability.available) {
      _showErrorSnackBar('اسم المستخدم غير متاح');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          displayName: _displayNameController.text.trim(),
        );
  }

  void _listenAuthState() {
    final auth = ref.watch(authProvider);

    if (auth.state == AuthStatus.authenticated) {
      context.go('/home');
      return;
    }

    if (auth.state == AuthStatus.error && auth.errorMessage != null) {
      _showErrorSnackBar(auth.errorMessage!);
      ref.read(authProvider.notifier).clearError();
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            message,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFF4212E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _listenAuthState();
    final isLoading = ref.watch(authProvider).state == AuthStatus.loading;
    final password = _passwordController.text;
    final strength = _evaluatePasswordStrength(password);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Back Button (top-right in RTL) ──────────────────────
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: IconButton(
                    onPressed: () => context.go('/welcome'),
                    icon: const Icon(Icons.arrow_forward, size: 24),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F8FA),
                      shape: const CircleBorder(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Title ───────────────────────────────────────────────
                Text(
                  'إنشاء حسابك في Arabtweets',
                  style: GoogleFonts.cairo(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F1419),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms),

                const SizedBox(height: 8),

                Text(
                  'انضم لملايين المستخدمين وابدأ التغريد',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: const Color(0xFF536471),
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 28),

                // ── Form ────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Display Name
                      _buildTextFormField(
                        controller: _displayNameController,
                        label: 'الاسم المعروض',
                        hint: 'مثال: أحمد محمد',
                        prefixIcon: Icons.person_outline,
                        validator: AppValidators.validateDisplayName,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 80.ms)
                          .slideY(begin: 0.12, end: 0, duration: 400.ms, delay: 80.ms),

                      const SizedBox(height: 18),

                      // Username
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اسم المستخدم',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F1419),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _usernameController,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            keyboardType: TextInputType.text,
                            onChanged: _onUsernameChanged,
                            validator: (v) {
                              final base = AppValidators.validateUsername(v);
                              if (base != null) return base;
                              if (_usernameAvailability == UsernameAvailability.taken) {
                                return 'اسم المستخدم مستخدم بالفعل';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '@username',
                              hintStyle: GoogleFonts.cairo(
                                fontSize: 14,
                                color: const Color(0xFF536471).withOpacity(0.6),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F8FA),
                              prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFF536471), size: 20),
                              suffixIcon: _buildUsernameStatusIcon(),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFF1DA1F2), width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFF4212E), width: 1.5),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: Color(0xFFF4212E), width: 1.5),
                              ),
                              errorStyle: GoogleFonts.cairo(
                                fontSize: 12,
                                color: const Color(0xFFF4212E),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 160.ms)
                          .slideY(begin: 0.12, end: 0, duration: 400.ms, delay: 160.ms),

                      const SizedBox(height: 18),

                      // Email
                      _buildTextFormField(
                        controller: _emailController,
                        label: 'البريد الإلكتروني',
                        hint: 'example@email.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: AppValidators.validateEmail,
                        textDirection: TextDirection.ltr,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 240.ms)
                          .slideY(begin: 0.12, end: 0, duration: 400.ms, delay: 240.ms),

                      const SizedBox(height: 18),

                      // Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextFormField(
                            controller: _passwordController,
                            label: 'كلمة المرور',
                            hint: '••••••••',
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF536471),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: AppValidators.validatePassword,
                            textDirection: TextDirection.ltr,
                            onChanged: (_) => setState(() {}),
                          ),
                          if (password.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildPasswordStrengthIndicator(strength),
                          ],
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 320.ms)
                          .slideY(begin: 0.12, end: 0, duration: 400.ms, delay: 320.ms),

                      const SizedBox(height: 18),

                      // Confirm Password
                      _buildTextFormField(
                        controller: _confirmPasswordController,
                        label: 'تأكيد كلمة المرور',
                        hint: '••••••••',
                        obscureText: _obscureConfirm,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF536471),
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'تأكيد كلمة المرور مطلوب';
                          if (v != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
                          return null;
                        },
                        textDirection: TextDirection.ltr,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 400.ms)
                          .slideY(begin: 0.12, end: 0, duration: 400.ms, delay: 400.ms),

                      const SizedBox(height: 28),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DA1F2),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF1DA1F2).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'إنشاء الحساب',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 480.ms)
                          .slideY(begin: 0.15, end: 0, duration: 400.ms, delay: 480.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Login Link ───────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'لديك حساب بالفعل؟',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: const Color(0xFF536471),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'سجل الدخول',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1DA1F2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 550.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────

  Widget _buildUsernameStatusIcon() {
    switch (_usernameAvailability) {
      case UsernameAvailability.checking:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case UsernameAvailability.available:
        return const Icon(Icons.check_circle, color: Color(0xFF00BA7C), size: 20);
      case UsernameAvailability.taken:
        return const Icon(Icons.cancel, color: Color(0xFFF4212E), size: 20);
      case UsernameAvailability.unknown:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPasswordStrengthIndicator(PasswordStrength strength) {
    final (label, color, fraction) = switch (strength) {
      PasswordStrength.weak => ('ضعيفة', const Color(0xFFF4212E), 0.33),
      PasswordStrength.medium => ('متوسطة', const Color(0xFFFFAD1F), 0.66),
      PasswordStrength.strong => ('قوية', const Color(0xFF00BA7C), 1.0),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: const Color(0xFFEFF3F4),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    IconData? prefixIcon,
    Widget? suffixIcon,
    TextDirection? textDirection,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F1419),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          textDirection: textDirection,
          textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
              fontSize: 14,
              color: const Color(0xFF536471).withOpacity(0.6),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F8FA),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: const Color(0xFF536471), size: 20)
                : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF1DA1F2), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFF4212E), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFF4212E), width: 1.5),
            ),
            errorStyle: GoogleFonts.cairo(
              fontSize: 12,
              color: const Color(0xFFF4212E),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}