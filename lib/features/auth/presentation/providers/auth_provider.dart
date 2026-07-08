import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/user_model.dart';

// ─── Auth State ──────────────────────────────────────────────────────────────

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthNotifierState {
  final AuthStatus state;
  final UserModel? user;
  final String? errorMessage;

  const AuthNotifierState({
    this.state = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthNotifierState copyWith({
    AuthStatus? state,
    UserModel? user,
    String? errorMessage,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthNotifierState(
      state: state ?? this.state,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ─── Auth Notifier ───────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthNotifierState> {
  final _supabase = Supabase.instance.client;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  AuthNotifierState build() {
    // Listen to Supabase auth state changes
    _listenToAuthChanges();

    // Check for existing session on startup
    Future.microtask(() => _checkInitialSession());

    // Clean up subscription when notifier is disposed
    ref.onDispose(() {
      _authSubscription?.cancel();
    });

    return const AuthNotifierState(state: AuthStatus.initial);
  }

  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (authState) async {
        final event = authState.event;
        final session = authState.session;
        if (event == AuthChangeEvent.signedIn && session != null) {
          await _fetchUserProfile(session.user.id);
        } else if (event == AuthChangeEvent.signedOut) {
          state = state.copyWith(
            state: AuthStatus.unauthenticated,
            clearUser: true,
            clearError: true,
          );
        } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
          // Token was refreshed, re-fetch profile in case data changed
          if (state.state == AuthStatus.authenticated) {
            await _fetchUserProfile(session.user.id);
          }
        }
      },
    );
  }

  Future<void> _checkInitialSession() async {
    final currentSession = _supabase.auth.currentSession;
    if (currentSession != null) {
      await _fetchUserProfile(currentSession.user.id);
    } else {
      state = state.copyWith(state: AuthStatus.unauthenticated);
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      state = state.copyWith(state: AuthStatus.loading, clearError: true);

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final userModel = UserModel.fromJson(response);
        state = state.copyWith(
          state: AuthStatus.authenticated,
          user: userModel,
          clearError: true,
        );
      } else {
        // Session exists but no profile found — treat as unauthenticated
        await _supabase.auth.signOut();
        state = state.copyWith(
          state: AuthStatus.unauthenticated,
          clearUser: true,
          clearError: true,
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: 'فشل في جلب بيانات المستخدم: ${_friendlyError(e)}',
      );
    }
  }

  // ─── Public Methods ─────────────────────────────────────────────────────

  /// Sign in with email and password.
  Future<void> signIn({required String email, required String password}) async {
    try {
      state = state.copyWith(state: AuthStatus.loading, clearError: true);

      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      // The onAuthStateChange listener will handle fetching the profile
      // and updating the state to authenticated.
    } on AuthException catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: _authErrorMessage(e),
      );
    } on PostgrestException catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: _friendlyError(e),
      );
    } catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: 'حدث خطأ غير متوقع أثناء تسجيل الدخول',
      );
    }
  }

  /// Sign up with email, password, username, and display name.
  /// After successful registration, inserts a row into the `profiles` table.
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      state = state.copyWith(state: AuthStatus.loading, clearError: true);

      // 1. Create the auth user with metadata
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'username': username.trim(),
          'display_name': displayName.trim(),
        },
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw const AuthException('فشل إنشاء الحساب');
      }

      // 2. Insert profile record
      await _supabase.from('profiles').insert({
        'id': userId,
        'username': username.trim(),
        'display_name': displayName.trim(),
        'bio': '',
        'avatar_url': '',
        'cover_url': '',
        'location': '',
        'website': '',
        'is_verified': false,
      });

      // 3. First user ever = admin (one-time only)
      await _supabase.rpc('make_first_admin', params: {'p_user_id': userId});

      // The onAuthStateChange listener will handle the rest.
      // Email confirmation is disabled, so user goes directly to app.
    } on AuthException catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: _authErrorMessage(e),
      );
    } on PostgrestException catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: _friendlyError(e),
      );
    } catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: 'حدث خطأ غير متوقع أثناء إنشاء الحساب',
      );
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      // The listener handles state transition to unauthenticated.
    } catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: 'فشل تسجيل الخروج: ${_friendlyError(e)}',
      );
    }
  }

  /// Send a password-reset email.
  Future<void> resetPassword({required String email}) async {
    try {
      state = state.copyWith(state: AuthStatus.loading, clearError: true);

      await _supabase.auth.resetPasswordForEmail(email.trim());

      state = state.copyWith(
        state: AuthStatus.unauthenticated,
        clearError: true,
      );
    } on AuthException catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: _authErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: 'فشل إرسال رابط إعادة التعيين',
      );
    }
  }

  /// Convenience getter: fetch current user & profile if not already loaded.
  Future<UserModel?> getCurrentUser() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      if (response != null) {
        final userModel = UserModel.fromJson(response);
        state = state.copyWith(
          state: AuthStatus.authenticated,
          user: userModel,
          clearError: true,
        );
        return userModel;
      }
      return null;
    } catch (e) {
      state = state.copyWith(
        state: AuthStatus.error,
        errorMessage: 'فشل في جلب بيانات المستخدم: ${_friendlyError(e)}',
      );
      return null;
    }
  }

  /// Clear any error state (useful for dismissing error UI).
  void clearError() {
    state = state.copyWith(
      state: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      clearError: true,
    );
  }

  // ─── Error Helpers ──────────────────────────────────────────────────────

  String _authErrorMessage(AuthException e) {
    final code = e.message.toLowerCase();
    if (code.contains('invalid login') || code.contains('invalid credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
    }
    if (code.contains('email not confirmed')) {
      return 'يرجى تأكيد البريد الإلكتروني أولاً';
    }
    if (code.contains('user already registered') || code.contains('already registered')) {
      return 'البريد الإلكتروني مسجل مسبقاً';
    }
    if (code.contains('password')) {
      return 'كلمة المرور ضعيفة جدًا';
    }
    return e.message.isNotEmpty ? e.message : 'حدث خطأ في المصادقة';
  }

  String _friendlyError(dynamic e) {
    final msg = e.toString();
    if (msg.length > 100) return msg.substring(0, 100);
    return msg;
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

/// Primary auth state provider.
final authProvider =
    NotifierProvider.autoDispose<AuthNotifier, AuthNotifierState>(
  AuthNotifier.new,
);

/// Convenience: stream of [AuthStatus] only.
final authStateStreamProvider = StreamProvider<AuthStatus>((ref) {
  final supabase = Supabase.instance.client;
  return supabase.auth.onAuthStateChange.map((authState) {
    final session = supabase.auth.currentSession;
    if (session != null) return AuthStatus.authenticated;
    return AuthStatus.unauthenticated;
  });
});

/// Convenience: is the user currently authenticated?
final isAuthenticatedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  return auth.state == AuthStatus.authenticated && auth.user != null;
});

/// Convenience: the current [UserModel], if authenticated.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});