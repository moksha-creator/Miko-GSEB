import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'shared_drawer.dart';
import '../providers/planner_state_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(AppStrings.t('settings', lang), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(AppStrings.t('class_settings', lang)),
          ListTile(
            leading: const Icon(Icons.class_, color: AppColors.primary),
            title: Text(AppStrings.t('class_profile', lang)),
            subtitle: const Text('Grade 5 · Section B · 40 Students'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: AppColors.accent),
            title: Text(AppStrings.t('class_pacing_planner', lang), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(AppStrings.t('calculate_buffers', lang)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.accent),
            onTap: () {
              context.push('/onboarding');
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(AppStrings.t('period_length', lang)),
            subtitle: const Text('45 minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(AppStrings.t('school_calendar', lang)),
            subtitle: const Text('Synced (9 holidays)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildSectionTitle(AppStrings.t('app_settings', lang)),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(AppStrings.t('notifications', lang)),
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(AppStrings.t('language', lang)),
            subtitle: Text(lang == AppLanguage.english ? 'English' : 'ગુજરાતી'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Toggle language directly for simplicity
              ref.read(localeProvider.notifier).setLocale(
                  lang == AppLanguage.english ? AppLanguage.gujarati : AppLanguage.english);
            },
          ),
          const Divider(height: 32),
          _buildSectionTitle(AppStrings.t('developer_demo', lang)),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(AppStrings.t('reset_demo_data', lang), style: const TextStyle(color: AppColors.accent)),
            onTap: () {
              ref.read(classSetupProvider.notifier).reset();
              ref.read(plannerStateProvider.notifier).reset();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.t('demo_reset_msg', lang))));
              context.go('/onboarding');
            },
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text('Miko GSEB Demo v1.0.0', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
