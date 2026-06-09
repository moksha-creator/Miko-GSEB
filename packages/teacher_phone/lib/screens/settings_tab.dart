import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import '../providers/planner_state_provider.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Class Settings'),
          ListTile(
            leading: const Icon(Icons.class_, color: AppColors.primary),
            title: const Text('Class Profile'),
            subtitle: const Text('Grade 5 · Section B · 40 Students'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: AppColors.accent),
            title: const Text('Class Pacing Planner', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Calculate buffers and teaching schedules'),
            trailing: const Icon(Icons.chevron_right, color: AppColors.accent),
            onTap: () {
              context.push('/onboarding');
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Period Length'),
            subtitle: const Text('45 minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('School Calendar'),
            subtitle: const Text('Synced (9 holidays)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildSectionTitle('App Settings'),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            trailing: Switch(value: true, onChanged: (v) {}),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English (Demo)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(height: 32),
          _buildSectionTitle('Developer Demo'),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Reset Demo Data', style: TextStyle(color: AppColors.accent)),
            onTap: () {
              ref.read(classSetupProvider.notifier).reset();
              ref.read(plannerStateProvider.notifier).reset();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo data reset. Returning to start.')));
              context.go('/');
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
