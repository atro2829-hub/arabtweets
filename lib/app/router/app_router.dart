import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/tweets/presentation/screens/home_feed_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/messages/presentation/screens/messages_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/terms_screen.dart';
import '../../features/settings/presentation/screens/privacy_screen.dart';
import '../../features/settings/presentation/screens/cookies_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/reels/presentation/screens/reels_screen.dart';
import '../../features/messages/presentation/screens/chat_screen.dart';
import '../../features/tweets/presentation/screens/tweet_detail_screen.dart';

// ─── Main Navigation Shell ──────────────────────────────────────────────────

class MainNavigationShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final theme = Theme.of(context);
    final unreadNotif = 0; // Will be connected to notifications provider

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              switch (index) {
                case 0: context.go('/home');
                case 1: context.go('/reels');
                case 2: context.go('/search');
                case 3: context.go('/notifications');
                case 4: context.go('/messages');
                case 5: context.go('/profile');
              }
            },
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  _currentIndex == 0 ? Icons.home_filled : Icons.home_outlined,
                  color: _currentIndex == 0 ? AppColors.primary : theme.iconTheme.color,
                  size: 28,
                ),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _currentIndex == 1 ? Icons.play_circle_filled : Icons.play_circle_outline,
                  color: _currentIndex == 1 ? AppColors.primary : theme.iconTheme.color,
                  size: 28,
                ),
                label: 'ريلز',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _currentIndex == 2 ? Icons.search_rounded : Icons.search_outlined,
                  color: _currentIndex == 2 ? AppColors.primary : theme.iconTheme.color,
                  size: 28,
                ),
                label: 'البحث',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      _currentIndex == 3
                          ? Icons.notifications_rounded
                          : Icons.notifications_outlined,
                      color: _currentIndex == 3 ? AppColors.primary : theme.iconTheme.color,
                      size: 28,
                    ),
                    if (unreadNotif > 0)
                      Positioned(
                        left: 4,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            unreadNotif > 9 ? '9+' : '$unreadNotif',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'الإشعارات',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  _currentIndex == 4 ? Icons.mail_rounded : Icons.mail_outline_rounded,
                  color: _currentIndex == 4 ? AppColors.primary : theme.iconTheme.color,
                  size: 28,
                ),
                label: 'الرسائل',
              ),
              BottomNavigationBarItem(
                icon: _buildProfileIcon(user, theme),
                label: 'الملف الشخصي',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileIcon(dynamic user, ThemeData theme) {
    if (user != null && user.avatarUrl.isNotEmpty) {
      return ClipOval(
        child: FadeInImage.assetNetwork(
          placeholder: 'assets/images/placeholder.png',
          image: user.fullAvatarUrl,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          imageErrorBuilder: (_, _, _) => _buildDefaultAvatar(user, theme),
        ),
      );
    }
    return _buildDefaultAvatar(user, theme);
  }

  Widget _buildDefaultAvatar(dynamic user, ThemeData theme) {
    final name = user?.displayName ?? user?.username ?? '?';
    return CircleAvatar(
      radius: 14,
      backgroundColor: _currentIndex == 5 ? AppColors.primary : theme.colorScheme.surface,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: _currentIndex == 5 ? Colors.white : theme.iconTheme.color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── App Router ──────────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/welcome',
  debugLogDiagnostics: true,
  redirect: (context, state) {
    // We let AuthGate handle navigation, so no redirect needed
    return null;
  },
  routes: [
    // ─── Auth Routes ──────────────────────────────────────────────────────
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // ─── Main App Routes (with bottom nav shell) ─────────────────────────
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeFeedScreen(),
          ),
        ),
            GoRoute(
          path: '/reels',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReelsScreen(),
          ),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchScreen(),
          ),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: NotificationsScreen(),
          ),
        ),
        GoRoute(
          path: '/messages',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MessagesListScreen(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(userId: 'me'),
          ),
        ),
      ],
    ),

    // ─── Detail Routes (no bottom nav shell) ────────────────────────────
    GoRoute(
      path: '/profile/:userId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfileScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/profile/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/tweet/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final tweetId = int.parse(state.pathParameters['id']!);
        return TweetDetailScreen(tweetId: tweetId);
      },
    ),
    GoRoute(
      path: '/chat/:conversationId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ChatScreen(
          conversationId: state.pathParameters['conversationId']!,
          otherUserId: extra?['otherUserId'] ?? '',
          otherUsername: extra?['otherUsername'] ?? '',
          otherDisplayName: extra?['otherDisplayName'] ?? '',
          otherAvatarUrl: extra?['otherAvatarUrl'] ?? '',
        );
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/about',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/terms',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/cookies',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CookiesScreen(),
    ),
    GoRoute(
      path: '/admin',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);

// ─── Auth Gate ──────────────────────────────────────────────────────────────

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    switch (auth.state) {
      case AuthStatus.initial:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      case AuthStatus.authenticated:
        return const HomeFeedScreen();
      case AuthStatus.unauthenticated:
        return const WelcomeScreen();
      case AuthStatus.error:
        // Show error then navigate to welcome
        Future.microtask(() {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(auth.errorMessage ?? 'حدث خطأ')),
            );
          }
        });
        return const WelcomeScreen();
    }
  }
}