import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_tab_screen.dart';
import 'screens/assessment_session_screen.dart';
import 'screens/feasibility_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/feasibility',
        builder: (context, state) {
          final setup = state.extra as ClassSetup;
          return FeasibilityScreen(initialSetup: setup);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final forceReset = state.extra == true;
          return MainTabScreen(key: forceReset ? UniqueKey() : null);
        },
      ),
      GoRoute(
        path: '/assessment',
        builder: (context, state) => const AssessmentSessionScreen(),
      ),
    ],
  );
});
