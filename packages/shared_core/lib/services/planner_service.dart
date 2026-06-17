import 'dart:math' as math;
import '../models/class_setup.dart';
import '../models/planner_models.dart';
import '../models/student.dart';

class PlannerService {
  static const double MIN_S = 5.0;       
  static const double EMBED_PERCENTAGE = 0.22; 
  static const List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  int calculateThroughput(ClassSetup setup, {String? subjectId}) {
    if (setup.assessmentMode == 'ded') {
      int perSession = math.max(1, (setup.lectureLength / MIN_S).floor());
      return math.max(1, perSession * setup.sessionsPerWeek);
    } else {
      double embedTime = setup.lectureLength * EMBED_PERCENTAGE;
      int studentsPerLecture = (embedTime / MIN_S).floor();
      int lecturesPerWeek = (subjectId != null) 
          ? (setup.subjectLecturesPerWeek[subjectId] ?? 4) 
          : 4;
      return math.max(1, studentsPerLecture * lecturesPerWeek);
    }
  }

  int calculateWeeksNeeded(ClassSetup setup) {
    if (setup.assessmentMode == 'ded') {
      int throughput = calculateThroughput(setup);
      int weeksPerSubject = (setup.studentCount / throughput).ceil();
      return weeksPerSubject * setup.activeSubjects.length;
    } else {
      int maxWeeks = 0;
      for (String subjectId in setup.activeSubjects) {
        int throughput = calculateThroughput(setup, subjectId: subjectId);
        int weeksForSubject = (setup.studentCount / throughput).ceil();
        if (weeksForSubject > maxWeeks) maxWeeks = weeksForSubject;
      }
      return maxWeeks;
    }
  }

  String? getBottleneckSubject(ClassSetup setup) {
    if (setup.assessmentMode == 'ded') return null;
    int maxWeeks = 0;
    String? bottleneck;
    for (String subjectId in setup.activeSubjects) {
      int throughput = calculateThroughput(setup, subjectId: subjectId);
      int weeksForSubject = (setup.studentCount / throughput).ceil();
      if (weeksForSubject > maxWeeks) {
        maxWeeks = weeksForSubject;
        bottleneck = subjectId;
      }
    }
    return bottleneck;
  }

  bool isFeasible(ClassSetup setup) {
    return calculateWeeksNeeded(setup) <= setup.checkpointWindowWeeks;
  }

  PlannerState generate(ClassSetup setup, List<Student> students) {
    List<WeekPlan> weeklyPlan = [];

    if (setup.assessmentMode == 'ded') {
      int wkCap = calculateThroughput(setup);
      int wps = (setup.studentCount / wkCap).ceil();
      int globalWeek = 1;

      for (String subjectId in setup.activeSubjects) {
        String subjectName = _getSubjectName(subjectId);
        int studentIdx = 0;
        
        for (int w = 0; w < wps; w++) {
          List<RosterEntry> entries = [];
          int currentWeek = globalWeek + w;
          int sessions = setup.sessionsPerWeek;
          int perSession = math.max(1, (setup.lectureLength / MIN_S).floor());
          
          for (int s = 0; s < sessions; s++) {
            String dayName = daysOfWeek[s % daysOfWeek.length];
            for (int i = 0; i < perSession; i++) {
              if (studentIdx >= students.length || studentIdx >= setup.studentCount) break;
              var st = students[studentIdx];
              entries.add(RosterEntry(studentId: st.id, studentName: st.name, rollNumber: st.rollNo, subject: subjectName, week: currentWeek, day: dayName, level: 'L${st.currentLevels[subjectName] ?? 1}'));
              studentIdx++;
            }
            if (studentIdx >= setup.studentCount) break;
          }
          weeklyPlan.add(WeekPlan(weekNumber: currentWeek, subject: subjectName, entries: entries));
        }
        globalWeek += wps;
      }
    } else {
      // Parallel mode
      for (String subjectId in setup.activeSubjects) {
        String subjectName = _getSubjectName(subjectId);
        int wkCap = calculateThroughput(setup, subjectId: subjectId);
        int wps = (setup.studentCount / wkCap).ceil();
        int studentIdx = 0;
        
        for (int w = 0; w < wps; w++) {
          List<RosterEntry> entries = [];
          int currentWeek = 1 + w; // Start at week 1
          for (int d = 0; d < 4; d++) {
            String dayName = daysOfWeek[d];
            int dailyCap = (wkCap / 4).ceil();
            for (int i = 0; i < dailyCap; i++) {
              if (studentIdx >= students.length || studentIdx >= setup.studentCount) break;
              var st = students[studentIdx];
              entries.add(RosterEntry(studentId: st.id, studentName: st.name, rollNumber: st.rollNo, subject: subjectName, week: currentWeek, day: dayName, level: 'L${st.currentLevels[subjectName] ?? 1}'));
              studentIdx++;
            }
            if (studentIdx >= setup.studentCount) break;
          }
          weeklyPlan.add(WeekPlan(weekNumber: currentWeek, subject: subjectName, entries: entries));
        }
      }
    }

    return PlannerState(weeklyPlan: weeklyPlan);
  }

  String _getSubjectName(String id) {
    switch (id) {
      case 'math': return 'Mathematics';
      case 'sci': return 'Science';
      case 'lang': return 'Language';
      case 'soc': return 'Social Studies';
      default: return id;
    }
  }
}
