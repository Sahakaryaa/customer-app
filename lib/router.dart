import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/worker_discovery/worker_list_screen.dart';
import 'screens/worker_discovery/worker_profile_screen.dart';
import 'screens/booking_flow/booking_flow_screen.dart';
import 'screens/live_tracking/tracking_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/rating/rating_screen.dart';
import 'screens/profile/history_screen.dart';
import 'screens/profile/profile_screen.dart';

/// App router with auth guard — unauthenticated users see onboarding/login.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/onboarding';

      // Still loading auth state — don't redirect
      if (authState.isLoading) return null;

      // Not authenticated → redirect to onboarding
      if (!isAuthenticated && !isAuthRoute) return '/onboarding';

      // Authenticated but on auth route → redirect to home
      if (isAuthenticated && isAuthRoute) return '/home';

      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onComplete: () => context.go('/login'),
        ),
      ),

      // Auth
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home (main screen)
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Worker discovery
      GoRoute(
        path: '/workers',
        builder: (context, state) {
          final service = state.uri.queryParameters['service'];
          final emergency = state.uri.queryParameters['emergency'] == 'true';
          final search = state.uri.queryParameters['search'];
          return WorkerListScreen(
            serviceType: service,
            isEmergency: emergency,
            searchQuery: search,
          );
        },
      ),
      GoRoute(
        path: '/workers/:id',
        builder: (context, state) => WorkerProfileScreen(
          workerId: state.pathParameters['id']!,
        ),
      ),

      // Booking flow
      GoRoute(
        path: '/booking/new',
        builder: (context, state) {
          final workerId = state.uri.queryParameters['worker'];
          return BookingFlowScreen(workerId: workerId);
        },
      ),

      // Live tracking
      GoRoute(
        path: '/booking/:id/tracking',
        builder: (context, state) => TrackingScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),

      // Payment
      GoRoute(
        path: '/booking/:id/payment',
        builder: (context, state) => PaymentScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),

      // Rating
      GoRoute(
        path: '/booking/:id/rate',
        builder: (context, state) => RatingScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),

      // History
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
