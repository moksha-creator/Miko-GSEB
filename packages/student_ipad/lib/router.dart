import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/student_profiles_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/transition_screens.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const StudentProfilesScreen(),
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
