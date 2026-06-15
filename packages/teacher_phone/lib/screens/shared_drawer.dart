import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final String currentRoute = GoRouterState.of(context).uri.toString();

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Text(
                  AppStrings.t('miko_teacher_hub', lang),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.home_rounded,
                  title: AppStrings.t('home_dashboard', lang),
                  route: '/home',
                  currentRoute: currentRoute,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.people_alt_rounded,
                  title: AppStrings.t('manage_class', lang),
                  route: '/class',
                  currentRoute: currentRoute,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.analytics_rounded,
                  title: AppStrings.t('view_reports', lang),
                  route: '/reports',
                  currentRoute: currentRoute,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.menu_book_rounded,
                  title: AppStrings.t('school_syllabus', lang),
                  route: '/syllabus',
                  currentRoute: currentRoute,
                ),
                const Divider(),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: AppStrings.t('settings', lang),
                  route: '/settings',
                  currentRoute: currentRoute,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required String currentRoute,
  }) {
    final bool isSelected = currentRoute.startsWith(route);
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        // Pop the drawer first
        Navigator.pop(context);
        if (!isSelected) {
          context.go(route);
        }
      },
    );
  }
}
