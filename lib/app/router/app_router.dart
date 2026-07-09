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

  int _getTabForLocation(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/reels')) return 1;
    if (location.startsWith('/search')) return 2;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/messages')) return 4;
    if (location.startsWith('/profile') && !location.contains('/profile/')) return 5;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final theme = Theme.of(context);

    // Update current index based on route
    final location = GoRouterState.of(context).matchedLocation;
    _currentIndex = _getTabForLocation(location);

    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightDivider,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_filled, 'الرئيسية', '/home'),
                _buildNavItem(1, Icons.play_circle_outline, Icons.play_circle_filled, 'ريلز', '/reels'),
                _buildNavItem(2, Icons.search_outlined, Icons.search_rounded, 'البحث', '/search'),
                _buildNavItem(3, Icons.notifications_outlined, Icons.notifications_rounded, 'إشعارات', '/notifications'),
                _buildNavItem(4, Icons.mail_outline_rounded, Icons.mail_rounded, 'رسائل', '/messages'),
                _buildProfileNavItem(5, user, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlinedIcon, IconData filledIcon, String label, String path) {
    final isActive = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isActive ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_currentIndex != index) context.go(path);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Icon(
          isActive ? filledIcon : outlinedIcon,
          color: color,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(int index, dynamic user, ThemeData theme) {
    final isActive = _currentIndex == index;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_currentIndex != index) context.go('/profile');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: isActive
            ? Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
                ),
                child: ClipOval(
                  child: _buildAvatarIcon(user, 22, theme),
                ),
              )
            : _buildAvatarIcon(user, 26, theme),
      ),
    );
  }

  Widget _buildAvatarIcon(dynamic user, double size, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (user != null && user.avatarUrl.isNotEmpty) {
      return FadeInImage.assetNetwork(
        placeholder: 'assets/images/placeholder.png',
        image: user.fullAvatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        imageErrorBuilder: (_, __, ___) => _buildDefaultAvatar(user, size, isDark),
      );
    }
    return _buildDefaultAvatar(user, size, isDark);
  }

  Widget _buildDefaultAvatar(dynamic user, double size, bool isDark) {
    final name = user?.displayName ?? user?.username ?? '?';
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: isDark ? AppColors.darkSurfaceDark : AppColors.lightBackground,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.45,
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
  debugLogDiagnostics: false,
  redirect: (context, state) {
    final authState = ProviderScope.containerOf(context).read(authProvider);
    final isAuth = authState.state == AuthStatus.authenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/welcome') ||
        state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register');

    // Redirect /edit-profile to /profile/edit
    if (state.matchedLocation == '/edit-profile') {
      return '/profile/edit';
    }

    if (!isAuth && !isAuthRoute) {
      return '/welcome';
    }
    if (isAuth && isAuthRoute) {
      return '/home';
    }
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
          pageBuilder: (context, state) => const NoTransitionPage(child: HomeFeedScreen()),
        ),
        GoRoute(
          path: '/reels',
          pageBuilder: (context, state) => const NoTransitionPage(child: ReelsScreen()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) => const NoTransitionPage(child: SearchScreen()),
        ),
        GoRoute(
          path: '/notifications',
          pageBuilder: (context, state) => const NoTransitionPage(child: NotificationsScreen()),
        ),
        GoRoute(
          path: '/messages',
          pageBuilder: (context, state) => const NoTransitionPage(child: MessagesListScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen(userId: 'me')),
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