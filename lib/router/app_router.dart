import 'package:cobrador/presentation/finances/finances_page.dart';
import 'package:cobrador/presentation/patients/patients_page.dart';
import 'package:cobrador/presentation/reminders/reminders_page.dart';
import 'package:cobrador/presentation/settings/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/presentation/landing/landing_page.dart';
import 'package:cobrador/presentation/auth/login_page.dart';
import 'package:cobrador/presentation/auth/register_page.dart';
import 'package:cobrador/presentation/auth/forgot_password_page.dart';
import 'package:cobrador/presentation/home/home_page.dart';

/// Application router with auth-aware redirects.
///
/// - `/` : Landing page (public)
/// - `/login`, `/register`, `/forgot-password` : Auth pages (redirect to /home if logged in)
/// - `/home` : Dashboard (redirect to /login if not logged in)
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final refreshListenable = ref.watch(authStateListenableProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final currentPath = state.matchedLocation;

      const authPaths = ['/login', '/register', '/forgot-password'];
      final isOnAuthPage = authPaths.contains(currentPath);
      final isOnHomePage =
          currentPath.startsWith('/home') ||
          currentPath.startsWith('/patients') ||
          currentPath.startsWith('/finances') ||
          currentPath.startsWith('/reminders') ||
          currentPath.startsWith('/settings');

      // If logged in and trying to access auth pages → go to /home
      if (isLoggedIn && isOnAuthPage) return '/home';

      // If not logged in and trying to access protected pages → go to /login
      if (!isLoggedIn && isOnHomePage) return '/login';

      // No redirect
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LandingPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/patients',
        builder: (context, state) => const PatientsPage(),
      ),
      GoRoute(
        path: '/finances',
        builder: (context, state) => const FinancesPage(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
