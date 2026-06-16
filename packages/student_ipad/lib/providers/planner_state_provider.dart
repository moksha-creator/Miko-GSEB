import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main()');
});

final classSetupProvider = NotifierProvider<ClassSetupNotifier, ClassSetup?>(() {
  return ClassSetupNotifier();
});

class ClassSetupNotifier extends Notifier<ClassSetup?> {
  @override
  ClassSetup? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final str = prefs.getString('class_setup');
    if (str != null) {
      try {
        return ClassSetup.fromJson(jsonDecode(str));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> save(ClassSetup setup) async {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('class_setup', jsonEncode(setup.toJson()));
    state = setup;
    await ref.read(plannerStateProvider.notifier).generateFromSetup(setup);
    
    if (kIsWeb) {
       try {
          final encoded = '{"studentCount": ${setup.studentCount}, "activeSubjects": ${jsonEncode(setup.activeSubjects.toList())}}';
          js.context['localStorage'].callMethod('setItem', ['miko_class_setup', encoded]);
       } catch(e) {}
    }
  }

  void reset() {
    ref.read(sharedPreferencesProvider).remove('class_setup');
    state = null;
  }
}

final plannerStateProvider = NotifierProvider<PlannerStateNotifier, PlannerState?>(() {
  return PlannerStateNotifier();
});

class PlannerStateNotifier extends Notifier<PlannerState?> {
  @override
  PlannerState? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final str = prefs.getString('planner_state');
    if (str != null) {
      try {
        return PlannerState.fromJson(jsonDecode(str));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  void _save(PlannerState newState) {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('planner_state', jsonEncode(newState.toJson()));
    state = newState;
  }

  void reset() {
    ref.read(sharedPreferencesProvider).remove('planner_state');
    state = null;
  }

  Future<void> generateFromSetup(ClassSetup setup) async {
    final dataService = ref.read(mockDataServiceProvider);
    final profile = await dataService.loadClassSample();
    
    List<Student> studentsToUse = profile.students;
    if (setup.studentNames != null && setup.studentNames!.isNotEmpty) {
      studentsToUse = List.generate(setup.studentCount, (i) {
        String name = i < setup.studentNames!.length ? setup.studentNames![i] : 'Student ${i + 1}';
        if (name.trim().isEmpty) name = 'Student ${i + 1}';
        return Student(
          id: 'MANUAL_$i',
          name: name,
          rollNo: i + 1,
          avatarColor: '0xFFD97706',
          avatarAsset: '',
          currentLevels: {},
          flaggedConcepts: [],
          recentSessions: [],
        );
      });
    }

    final planner = PlannerService();
    final newState = planner.generate(setup, studentsToUse);
    _save(newState);
  }

  void markStatus(RosterEntry entry, RosterStatus status, {int? timeSpentSeconds, String? lastQuestion, String? level}) {
    if (state == null) return;
    
    List<WeekPlan> newWeeklyPlan = state!.weeklyPlan.map((w) {
      if (w.weekNumber != entry.week || w.subject != entry.subject) return w;
      
      List<RosterEntry> newEntries = w.entries.map((e) {
        if (e.studentId == entry.studentId && e.day == entry.day) {
          return e.copyWith(
            status: status,
            timeSpentSeconds: timeSpentSeconds ?? e.timeSpentSeconds,
            lastQuestion: lastQuestion ?? e.lastQuestion,
            level: level ?? e.level,
          );
        }
        return e;
      }).toList();
      
      return WeekPlan(weekNumber: w.weekNumber, subject: w.subject, entries: newEntries);
    }).toList();
    
    _save(PlannerState(
      weeklyPlan: newWeeklyPlan,
      currentWeek: state!.currentWeek,
      currentDay: state!.currentDay,
    ));
  }
}
