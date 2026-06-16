import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_core/shared_core.dart';
import 'screens/student_profiles_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/transition_screens.dart';
import 'screens/onboarding_screen.dart';
import 'screens/feasibility_screen.dart';
import 'providers/planner_state_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final setup = ref.read(classSetupProvider);
      final isSetupComplete = setup != null;
      final isGoingToSetup = state.matchedLocation == '/setup' || state.matchedLocation == '/feasibility';

      if (!isSetupComplete && !isGoingToSetup) {
        return '/setup';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const StudentProfilesScreen(),
      ),
      GoRoute(
        path: '/setup',
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
        path: '/be-ready',
        builder: (context, state) => const BeReadyScreen(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/next-student-transition',
        builder: (context, state) => const NextStudentTransitionScreen(),
      ),
    ],
  );
});
