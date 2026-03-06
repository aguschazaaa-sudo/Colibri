import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/auth/forgot_password_page.dart';
import 'package:cobrador/presentation/auth/login_page.dart';
import 'package:cobrador/presentation/auth/register_page.dart';
import 'package:cobrador/presentation/finances/finances_page.dart';
import 'package:cobrador/presentation/home/home_page.dart';
import 'package:cobrador/presentation/landing/landing_page.dart';
import 'package:cobrador/presentation/patients/patient_detail_page.dart';
import 'package:cobrador/presentation/patients/patients_page.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/presentation/reminders/reminders_page.dart';
import 'package:cobrador/presentation/settings/settings_page.dart';
import 'package:cobrador/presentation/settings/non_working_days_page.dart';
import 'package:cobrador/presentation/splash/splash_page.dart';
import 'package:cobrador/presentation/subscription/subscription_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Application router with auth-aware redirects.
///
/// - `/splash` : Splash screen (entry point)
/// - `/` : Landing page (public)
/// - `/login`, `/register`, `/forgot-password` : Auth pages (redirect to /home if logged in)
/// - `/home` : Dashboard (redirect to /login if not logged in)
/// - `/subscription` : Subscription gateway (redirects to /home if active, blocks core app if inactive)

/// Provider to track if the splash screen has been shown successfully.
final splashShownProvider = StateProvider<bool>((ref) => false);

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final refreshListenable = ref.watch(authStateListenableProvider);
  final hasShownSplash = ref.watch(splashShownProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final isLoggedIn = authState.asData?.value != null;
      final currentPath = state.matchedLocation;

      // Force splash screen to show first, ignoring any initial URLs
      if (!hasShownSplash && currentPath != '/splash') {
        return '/splash';
      }

      const authPaths = ['/login', '/register', '/forgot-password'];
      final isOnAuthPage = authPaths.contains(currentPath);
      final isLandingPage = currentPath == '/';
      final isOnHomePage =
          currentPath.startsWith('/home') ||
          currentPath.startsWith('/patients') ||
          currentPath.startsWith('/finances') ||
          currentPath.startsWith('/reminders') ||
          currentPath.startsWith('/settings');

      final isOnSubscriptionPage = currentPath == '/subscription';

      if (isLoggedIn) {
        final hasActivePlan = authState.asData!.value!.hasActivePlan;

        if (!hasActivePlan) {
          // If no active plan, block from core pages and landing/auth, redirect to subscription.
          if (isOnHomePage || isOnAuthPage || isLandingPage) {
            return '/subscription';
          }
        } else {
          // If has active plan and visits subscription, auth pages, or landing, redirect to home.
          if (isOnSubscriptionPage || isOnAuthPage || isLandingPage) {
            return '/home';
          }
        }
      } else {
        // If not logged in and trying to access protected pages (including subscription) → go to landing
        if (isOnHomePage || isOnSubscriptionPage) return '/';
      }

      // No redirect
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
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
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/patients',
        builder: (context, state) => const PatientsPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              // The extra object might be null if navigated via URL directly.
              final patientObj = state.extra as Patient?;
              return PatientDetailPage(patientId: id, patientObj: patientObj);
            },
          ),
        ],
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
        routes: [
          GoRoute(
            path: 'non-working-days',
            builder: (context, state) => const NonWorkingDaysPage(),
          ),
        ],
      ),
    ],
  );
});
