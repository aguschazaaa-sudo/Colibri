import 'package:cobrador/domain/appointment.dart';
import 'package:cobrador/domain/patient.dart';
import 'package:cobrador/presentation/appointments/appointment_detail_page.dart';
import 'package:cobrador/presentation/auth/forgot_password_page.dart';
import 'package:cobrador/presentation/auth/login_page.dart';
import 'package:cobrador/presentation/auth/register_page.dart';
import 'package:cobrador/presentation/finances/finances_page.dart';
import 'package:cobrador/presentation/home/home_page.dart';
import 'package:cobrador/presentation/landing/landing_page.dart';
import 'package:cobrador/presentation/landing/reportar_error_page.dart';
import 'package:cobrador/presentation/landing/terms_page.dart';
import 'package:cobrador/presentation/landing/privacy_page.dart';
import 'package:cobrador/presentation/patients/patient_detail_page.dart';
import 'package:cobrador/presentation/patients/patients_page.dart';
import 'package:cobrador/providers/auth_providers.dart';
import 'package:cobrador/presentation/reminders/reminders_page.dart';
import 'package:cobrador/presentation/settings/settings_page.dart';
import 'package:cobrador/presentation/settings/non_working_days_page.dart';
import 'package:cobrador/presentation/settings/notifications_settings_page.dart';
import 'package:cobrador/presentation/settings/profile_page.dart';
import 'package:cobrador/presentation/splash/splash_page.dart';
import 'package:cobrador/presentation/subscription/subscription_page.dart';
import 'package:cobrador/presentation/widgets/app_shell.dart';
import 'package:cobrador/router/route_transitions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Application router with auth-aware redirects.
///
/// - `/splash` : Splash screen (entry point)
/// - `/` : Landing page (public)
/// - `/login`, `/register`, `/forgot-password` : Auth pages (redirect to /home if logged in)
/// - `/home` : Dashboard (redirect to /login if not logged in)
/// - `/subscription` : Subscription gateway (redirects to /home if active, blocks core app if inactive)
///
/// The 5 main app sections (/home, /patients, /finances, /reminders, /settings)
/// are wrapped in a [ShellRoute] that renders [AppShell] persistently.
/// The sidebar inside AppShell NEVER animates during navigation between them.

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(authStateListenableProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      // Read (not watch) inside the closure — refreshListenable already
      // triggers redirect re-evaluation when these change.
      final authState = ref.read(authStateProvider);
      final hasShownSplash = ref.read(splashShownProvider);
      final isLoggedIn = authState.asData?.value != null;
      final currentPath = state.matchedLocation;

      // Force splash screen to show first, preserving the intended destination
      if (!hasShownSplash && currentPath != '/splash') {
        if (currentPath != '/') {
          Future.microtask(() {
            ref.read(preSplashDestinationProvider.notifier).state = currentPath;
          });
        }
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
          // If has active plan and visits auth pages, or landing, redirect to home.
          if (isOnAuthPage || isLandingPage) {
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
      GoRoute(path: '/terms', builder: (context, state) => const TermsPage()),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/reportar-error',
        builder: (context, state) => const ReportarErrorPage(),
      ),
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
      GoRoute(
        path: '/appointments/:id',
        builder: (context, state) {
          final appointment = state.extra as Appointment;
          return AppointmentDetailPage(appointment: appointment);
        },
      ),

      // ─── Persistent Shell ────────────────────────────────────────────────
      // All routes inside this ShellRoute share the AppShell (with its sidebar).
      // The shell is never destroyed or animated when navigating between them.
      ShellRoute(
        pageBuilder:
            (context, state, child) =>
                NoTransitionPage(child: AppShell(child: child)),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder:
                (context, state) =>
                    contentTransitionPage(state: state, child: const HomePage()),
          ),
          GoRoute(
            path: '/patients',
            pageBuilder:
                (context, state) => contentTransitionPage(
                  state: state,
                  child: const PatientsPage(),
                ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final patientObj = state.extra as Patient?;
                  return contentTransitionPage(
                    state: state,
                    child: PatientDetailPage(
                      patientId: id,
                      patientObj: patientObj,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/finances',
            pageBuilder:
                (context, state) => contentTransitionPage(
                  state: state,
                  child: const FinancesPage(),
                ),
          ),
          GoRoute(
            path: '/reminders',
            pageBuilder:
                (context, state) => contentTransitionPage(
                  state: state,
                  child: const RemindersPage(),
                ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder:
                (context, state) => contentTransitionPage(
                  state: state,
                  child: const SettingsPage(),
                ),
            routes: [
              GoRoute(
                path: 'non-working-days',
                pageBuilder:
                    (context, state) => contentTransitionPage(
                      state: state,
                      child: const NonWorkingDaysPage(),
                    ),
              ),
              GoRoute(
                path: 'profile',
                pageBuilder:
                    (context, state) => contentTransitionPage(
                      state: state,
                      child: const ProfilePage(),
                    ),
              ),
              GoRoute(
                path: 'notifications',
                pageBuilder:
                    (context, state) => contentTransitionPage(
                      state: state,
                      child: const NotificationsSettingsPage(),
                    ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

