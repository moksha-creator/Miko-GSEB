import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'reporting_view_student.dart';
import 'reporting_view_class.dart';
import 'reporting_view_log.dart';

class ReportingScreen extends StatelessWidget {
  const ReportingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Color(0xFF3B82F6)),
              const SizedBox(width: 12),
              const Text('Assessment Reports', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900)),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                context.go('/');
              },
              icon: const Icon(Icons.lock, color: Color(0xFF64748B), size: 18),
              label: const Text('Close & Lock', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF3B82F6),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF3B82F6),
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Student'),
              Tab(icon: Icon(Icons.groups), text: 'Class'),
              Tab(icon: Icon(Icons.list_alt), text: 'Response Log'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ReportingViewStudent(),
            ReportingViewClass(),
            ReportingViewLog(),
          ],
        ),
      ),
    );
  }
}
