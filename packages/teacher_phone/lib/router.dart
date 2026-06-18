import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/today_tab.dart';
import 'screens/class_tab.dart';
import 'screens/reports_tab.dart';
import 'screens/school_tab.dart';
import 'screens/settings_tab.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const TodayTab(),
      ),
      GoRoute(
        path: '/class',
        builder: (context, state) => const ClassTab(),
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsTab(),
      ),
      GoRoute(
        path: '/syllabus',
        builder: (context, state) => const SchoolTab(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsTab(),
      ),

    ],
  );
});
