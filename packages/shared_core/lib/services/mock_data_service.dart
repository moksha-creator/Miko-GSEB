import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;

import '../models/class_profile.dart';
import '../models/student.dart';
import '../models/session.dart';
import '../models/quiz_models.dart';

final mockDataServiceProvider = Provider<MockDataService>((ref) {
  return MockDataService();
});

class MockDataService {
  Future<ClassProfile> loadClassSample() async {
    final String response = await rootBundle.loadString('packages/shared_core/assets/mock/class_sample.json');
    final data = json.decode(response);
    final baseProfile = ClassProfile.fromJson(data);

    if (kIsWeb) {
      try {
        final hasSetup = js.context.hasProperty('localStorage') && js.context['localStorage'].hasProperty('getItem');
        if (hasSetup) {
          final setupStr = js.context['localStorage'].callMethod('getItem', ['miko_class_setup']);
          if (setupStr != null) {
            final setup = json.decode(setupStr) as Map<String, dynamic>;
            final int? studentCount = setup['studentCount'] as int?;
            final List<dynamic>? activeSubjectsList = setup['activeSubjects'] as List<dynamic>?;

            if (studentCount != null) {
              final activeSubjects = activeSubjectsList?.cast<String>().toSet() ?? {'math', 'sci', 'lang', 'soc'};
              final List<Student> customStudents = [];
              final coreStudents = baseProfile.students;
              final coreCount = coreStudents.length;

              final names = [
                'Aarav Patel', 'Diya Shah', 'Krish Mehta', 'Ananya Joshi', 'Rohan Desai',
                'Priya Trivedi', 'Arjun Dave', 'Mira Parmar', 'Dev Gandhi', 'Kavya Raval',
                'Sneha Rao', 'Karan Patel', 'Ravi Joshi', 'Neha Desai', 'Arpan Shah',
                'Nikhil Mehta', 'Tanvi Dave', 'Sameer Vyas', 'Aditi Shah', 'Ishaan Parmar',
                'Nisha Joshi', 'Raj Patel', 'Pooja Desai', 'Yash Trivedi', 'Riddhi Dave',
                'Manan Parmar', 'Shreya Gandhi', 'Pranav Raval', 'Meera Rao', 'Rahul Patel',
                'Simran Shah', 'Varun Mehta', 'Kirti Joshi', 'Kabir Desai', 'Tina Trivedi',
                'Siddharth Dave', 'Riya Parmar', 'Gaurav Gandhi', 'Shalini Raval', 'Amit Rao'
              ];

              final colors = [
                '#E85D55', '#4A3FB7', '#1D9E75', '#EF9F27', '#E85D55',
                '#4A3FB7', '#1D9E75', '#EF9F27', '#E85D55', '#4A3FB7'
              ];

              final Map<String, String> subjMap = {
                'math': 'Mathematics',
                'sci': 'Science',
                'lang': 'Language',
                'soc': 'Social Studies'
              };

              for (int i = 0; i < studentCount; i++) {
                if (i < coreCount) {
                  final coreStudent = coreStudents[i];
                  final filteredLevels = <String, int>{};
                  for (final entry in coreStudent.currentLevels.entries) {
                    final plannerKey = subjMap.entries.firstWhere(
                      (e) => e.value == entry.key,
                      orElse: () => const MapEntry('', '')
                    ).key;
                    if (plannerKey.isNotEmpty && activeSubjects.contains(plannerKey)) {
                      filteredLevels[entry.key] = entry.value;
                    }
                  }
                  
                  customStudents.add(Student(
                    id: coreStudent.id,
                    rollNo: i + 1,
                    name: coreStudent.name,
                    avatarColor: coreStudent.avatarColor,
                    currentLevels: filteredLevels,
                    flaggedConcepts: coreStudent.flaggedConcepts,
                    recentSessions: coreStudent.recentSessions,
                  ));
                } else {
                  final name = names[i % names.length] + (i >= names.length ? ' ${i ~/ names.length + 1}' : '');
                  final avatarColor = colors[i % colors.length];
                  
                  final filteredLevels = <String, int>{};
                  for (final activeId in activeSubjects) {
                    final stdName = subjMap[activeId];
                    if (stdName != null) {
                      filteredLevels[stdName] = 1 + (i % 4);
                    }
                  }

                  customStudents.add(Student(
                    id: 's${(i + 1).toString().padLeft(3, '0')}',
                    rollNo: i + 1,
                    name: name,
                    avatarColor: avatarColor,
                    currentLevels: filteredLevels,
                    flaggedConcepts: [],
                    recentSessions: [],
                  ));
                }
              }

              return ClassProfile(
                grade: baseProfile.grade,
                section: baseProfile.section,
                students: customStudents,
              );
            }
          }
        }
      } catch (e) {
        // Fallback
      }
    }

    return baseProfile;
  }

  Future<TodaySession> loadTodaySession() async {
    final String response = await rootBundle.loadString('packages/shared_core/assets/mock/today_session.json');
    final data = await json.decode(response);
    return TodaySession.fromJson(data);
  }
  
  Future<Map<String, dynamic>> loadCheckpointReport() async {
    final String response = await rootBundle.loadString('packages/shared_core/assets/mock/checkpoint_report_cp2.json');
    return await json.decode(response);
  }

  Future<List<dynamic>> loadSimulatedDialogue() async {
    final String response = await rootBundle.loadString('packages/shared_core/assets/mock/simulated_session_dialogue.json');
    return await json.decode(response);
  }

  Future<List<QuizQuestion>> loadQuestionsForSubject(String subject, {int lesson = 1}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    final lowerSubject = subject.toLowerCase();
    final List<QuizQuestion> questions = [];
    
    for (int i = 0; i < 5; i++) {
      final templateIdx = i % 6;
      final qId = '${subject}_l${lesson}_q${i+1}';
      
      switch (templateIdx) {
        case 0:
          // TEXT CHOICE
          questions.add(QuizQuestion(
            id: qId,
            subject: subject,
            text: lowerSubject.contains('math') ? 'What is 8 x 7?' 
                : lowerSubject.contains('sci') ? 'Which gas do plants absorb from the atmosphere?' 
                : 'Which is a noun?',
            type: QuestionType.mcq,
            options: lowerSubject.contains('math') ? [
              const QuestionOption(label: 'A', value: '54'),
              const QuestionOption(label: 'B', value: '56'),
              const QuestionOption(label: 'C', value: '64'),
              const QuestionOption(label: 'D', value: '48'),
            ] : lowerSubject.contains('sci') ? [
              const QuestionOption(label: 'A', value: 'Oxygen'),
              const QuestionOption(label: 'B', value: 'Carbon Dioxide'),
              const QuestionOption(label: 'C', value: 'Nitrogen'),
              const QuestionOption(label: 'D', value: 'Hydrogen'),
            ] : [
              const QuestionOption(label: 'A', value: 'Run'),
              const QuestionOption(label: 'B', value: 'Beautiful'),
              const QuestionOption(label: 'C', value: 'Apple'),
              const QuestionOption(label: 'D', value: 'Quickly'),
            ],
            correctAnswers: lowerSubject.contains('math') ? ['56'] : lowerSubject.contains('sci') ? ['Carbon Dioxide'] : ['Apple'],
            visualAid: 'text_only',
          ));
          break;
        case 1:
          // IMAGE CHOICE (with emojis as images)
          questions.add(QuizQuestion(
            id: qId,
            subject: subject,
            text: lowerSubject.contains('math') ? 'Which shape has 3 sides?' 
                : lowerSubject.contains('sci') ? 'Which of these is a mammal?' 
                : 'Which of these is a fruit?',
            type: QuestionType.mcq,
            options: lowerSubject.contains('math') ? [
              const QuestionOption(label: 'A', value: '🔺'),
              const QuestionOption(label: 'B', value: '🟩'),
              const QuestionOption(label: 'C', value: '⭕'),
              const QuestionOption(label: 'D', value: '⭐'),
            ] : lowerSubject.contains('sci') ? [
              const QuestionOption(label: 'A', value: '🦅'),
              const QuestionOption(label: 'B', value: '🐟'),
              const QuestionOption(label: 'C', value: '🐘'),
              const QuestionOption(label: 'D', value: '🦎'),
            ] : [
              const QuestionOption(label: 'A', value: '🥦'),
              const QuestionOption(label: 'B', value: '🍎'),
              const QuestionOption(label: 'C', value: '🥕'),
              const QuestionOption(label: 'D', value: '🍞'),
            ],
            correctAnswers: lowerSubject.contains('math') ? ['🔺'] : lowerSubject.contains('sci') ? ['🐘'] : ['🍎'],
            visualAid: 'image_choice',
          ));
          break;
        case 2:
          // SORT (TWO BUCKET)
          questions.add(QuizQuestion(
            id: qId,
            subject: subject,
            text: lowerSubject.contains('math') ? 'Sort into Odd and Even numbers.'
                : lowerSubject.contains('sci') ? 'Sort into Herbivore and Carnivore.'
                : 'Sort into Vowels and Consonants.',
            type: QuestionType.sorting,
            matchingPairs: lowerSubject.contains('math') ? [
              const MatchingPair(itemA: '1', itemB: 'Odd'),
              const MatchingPair(itemA: '3', itemB: 'Odd'),
              const MatchingPair(itemA: '4', itemB: 'Even'),
              const MatchingPair(itemA: '6', itemB: 'Even'),
            ] : lowerSubject.contains('sci') ? [
              const MatchingPair(itemA: '🐄', itemB: 'Herbivore'),
              const MatchingPair(itemA: '🐇', itemB: 'Herbivore'),
              const MatchingPair(itemA: '🐅', itemB: 'Carnivore'),
              const MatchingPair(itemA: '🐺', itemB: 'Carnivore'),
            ] : [
              const MatchingPair(itemA: 'A', itemB: 'Vowels'),
              const MatchingPair(itemA: 'E', itemB: 'Vowels'),
              const MatchingPair(itemA: 'B', itemB: 'Consonants'),
              const MatchingPair(itemA: 'C', itemB: 'Consonants'),
            ],
            visualAid: 'two_bucket_sort',
          ));
          break;
        case 3:
          // MATCH PAIRS
          questions.add(QuizQuestion(
            id: qId,
            subject: subject,
            text: 'Match the related concepts.',
            type: QuestionType.matching,
            matchingPairs: lowerSubject.contains('math') ? [
              const MatchingPair(itemA: '5 + 5', itemB: '10'),
              const MatchingPair(itemA: '4 x 3', itemB: '12'),
              const MatchingPair(itemA: '20 / 4', itemB: '5'),
            ] : lowerSubject.contains('sci') ? [
              const MatchingPair(itemA: 'Sun', itemB: 'Star'),
              const MatchingPair(itemA: 'Earth', itemB: 'Planet'),
              const MatchingPair(itemA: 'Moon', itemB: 'Satellite'),
            ] : [
              const MatchingPair(itemA: 'Hot', itemB: 'Cold'),
              const MatchingPair(itemA: 'Fast', itemB: 'Slow'),
              const MatchingPair(itemA: 'Happy', itemB: 'Sad'),
            ],
            visualAid: 'match_pairs',
          ));
          break;
        case 4:
          // SEQUENCE
          questions.add(QuizQuestion(
            id: qId,
            subject: subject,
            text: lowerSubject.contains('math') ? 'Arrange these from smallest to largest.'
                : lowerSubject.contains('sci') ? 'Order the life cycle of a butterfly.'
                : 'Arrange the letters alphabetically.',
            type: QuestionType.sorting,
            sortedOrder: lowerSubject.contains('math') ? ['0.25', '1.5', '3.0', '10.5']
                : lowerSubject.contains('sci') ? ['Egg 🥚', 'Caterpillar 🐛', 'Chrysalis 🪴', 'Butterfly 🦋']
                : ['A', 'F', 'M', 'Z'],
            visualAid: 'sequence',
          ));
          break;
        case 5:
          // VOICE RESPONSE
          questions.add(QuizQuestion(
            id: qId,
            subject: subject,
            text: lowerSubject.contains('math') ? 'Say the answer to 12 + 15.'
                : lowerSubject.contains('sci') ? 'Name the force that pulls objects to Earth.'
                : 'Read this word out loud: "Photosynthesis"',
            type: QuestionType.verbal,
            correctAnswers: lowerSubject.contains('math') ? ['27']
                : lowerSubject.contains('sci') ? ['Gravity']
                : ['Photosynthesis'],
            visualAid: 'voice_response',
          ));
          break;
      }
    }
    
    return questions;
  }
}
