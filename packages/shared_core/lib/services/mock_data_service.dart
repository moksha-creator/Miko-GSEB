import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

import '../models/class_profile.dart';
import '../models/student.dart';
import '../models/session.dart';
import '../models/quiz_models.dart';
import '../localization/app_strings.dart';
import '../providers/locale_provider.dart';

final mockDataServiceProvider = Provider<MockDataService>((ref) {
  final lang = ref.watch(localeProvider);
  return MockDataService(lang);
});

class MockDataService {
  final AppLanguage language;
  MockDataService(this.language);

  Future<ClassProfile> loadClassSample() async {
    final String response = await rootBundle.loadString('packages/shared_core/assets/mock/class_sample.json');
    final data = json.decode(response);
    final baseProfile = ClassProfile.fromJson(data);

    final namesEn = [
      'Aarav Patel', 'Diya Shah', 'Krish Mehta', 'Ananya Joshi', 'Rohan Desai',
      'Priya Trivedi', 'Arjun Dave', 'Mira Parmar', 'Dev Gandhi', 'Kavya Raval',
      'Sneha Rao', 'Karan Patel', 'Ravi Joshi', 'Neha Desai', 'Arpan Shah',
      'Nikhil Mehta', 'Tanvi Dave', 'Sameer Vyas', 'Aditi Shah', 'Ishaan Parmar',
      'Nisha Joshi', 'Raj Patel', 'Pooja Desai', 'Yash Trivedi', 'Riddhi Dave',
      'Manan Parmar', 'Shreya Gandhi', 'Pranav Raval', 'Meera Rao', 'Rahul Patel',
      'Simran Shah', 'Varun Mehta', 'Kirti Joshi', 'Kabir Desai', 'Tina Trivedi',
      'Sagar Vyas', 'Anjali Patel', 'Rohit Shah', 'Shikha Dave', 'Jay Mehta'
    ];
    final namesGu = ['આરવ પટેલ', 'દિયા શાહ', 'ક્રિશ મહેતા', 'અનન્યા જોશી', 'રોહન દેસાઈ', 'પ્રિયા ત્રિવેદી', 'અર્જુન દવે', 'મીરા પરમાર', 'દેવ ગાંધી', 'કાવ્યા રાવલ', 'સ્નેહા રાવ', 'કરણ પટેલ', 'રવિ જોશી', 'નેહા દેસાઈ', 'અર્પણ શાહ', 'નિખિલ મહેતા', 'તાન્વી દવે', 'સમીર વ્યાસ', 'અદિતિ શાહ', 'ઈશાન પરમાર', 'નિશા જોશી', 'રાજ પટેલ', 'પૂજા દેસાઈ', 'યશ ત્રિવેદી', 'રિદ્ધિ દવે', 'મનન પરમાર', 'શ્રેયા ગાંધી', 'પ્રણવ રાવલ', 'મીરા રાવ', 'રાહુલ પટેલ', 'સિમરન શાહ', 'વરુણ મહેતા', 'કીર્તિ જોશી', 'કબીર દેસાઈ', 'ટીના ત્રિવેદી', 'સાગર વ્યાસ', 'અંજલિ પટેલ', 'રોહિત શાહ', 'શિખા દવે', 'જય મહેતા'];
    final activeNames = language == AppLanguage.gujarati ? namesGu : namesEn;

    for (int i = 0; i < baseProfile.students.length; i++) {
      if (i < activeNames.length) {
        baseProfile.students[i] = Student(
          id: baseProfile.students[i].id,
          name: activeNames[i],
          rollNo: baseProfile.students[i].rollNo,
          avatarColor: baseProfile.students[i].avatarColor,
          avatarAsset: baseProfile.students[i].avatarAsset,
          currentLevels: baseProfile.students[i].currentLevels,
          flaggedConcepts: baseProfile.students[i].flaggedConcepts,
          recentSessions: baseProfile.students[i].recentSessions,
        );
      }
    }

    if (kIsWeb) {
      try {
        final setupStr = html.window.localStorage['miko_class_setup'];
          if (setupStr != null) {
            final setup = json.decode(setupStr) as Map<String, dynamic>;
            final int? studentCount = setup['studentCount'] as int?;
            final List<dynamic>? activeSubjectsList = setup['activeSubjects'] as List<dynamic>?;

            if (studentCount != null) {
              final activeSubjects = activeSubjectsList?.cast<String>().toSet() ?? {'math', 'sci', 'lang', 'soc'};
              final List<Student> customStudents = [];
              final coreStudents = baseProfile.students;
              final coreCount = coreStudents.length;

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
                    avatarAsset: 'assets/avatars/${coreStudent.name.toLowerCase().split(' ')[0]}.png',
                    currentLevels: filteredLevels,
                    flaggedConcepts: coreStudent.flaggedConcepts,
                    recentSessions: coreStudent.recentSessions,
                  ));
                } else {
                  final name = activeNames[i % activeNames.length] + (i >= activeNames.length ? ' ${i ~/ activeNames.length + 1}' : '');
                  final avatarColor = colors[i % colors.length];
                  final baseName = activeNames[i % activeNames.length].toLowerCase().split(' ')[0];
                  final hasAvatarAsset = ['aarav', 'ananya', 'arjun', 'dev', 'diya', 'kavya', 'krish', 'mira', 'priya', 'rohan'].contains(baseName);
                  
                  final filteredLevels = <String, int>{};
                  for (final activeId in activeSubjects) {
                    final stdName = subjMap[activeId];
                    if (stdName != null) {
                      filteredLevels[stdName] = 1; // Basic level for generated students
                    }
                  }

                  customStudents.add(Student(
                    id: 's${(i + 1).toString().padLeft(3, '0')}',
                    rollNo: i + 1,
                    name: name,
                    avatarColor: avatarColor,
                    avatarAsset: hasAvatarAsset ? 'assets/avatars/$baseName.png' : '',
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

  Future<Map<String, dynamic>> loadCurriculum() async {
    final String response = await rootBundle.loadString('packages/shared_core/assets/mock/curriculum_full.json');
    return await json.decode(response);
  }

  Future<List<dynamic>> loadSimulatedDialogue() async {
    final String response = await rootBundle.loadString('packages/shared_core/assets/mock/simulated_session_dialogue.json');
    return await json.decode(response);
  }

  Future<List<QuizQuestion>> loadQuestionsForSubject(String subject, {int lesson = 1}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (subject == 'Social Studies') {
      try {
        final String response = await rootBundle.loadString('packages/shared_core/assets/mock/questions.json');
        final List<dynamic> data = json.decode(response);
        return data.map((q) {
          final template = q['template'] as String;
          
          QuestionType type = QuestionType.verbal;
          List<QuestionOption> options = [];
          List<MatchingPair> matchingPairs = [];
          List<String> sortedOrder = [];
          List<String> correctAnswers = [];
          
          if (template == 'TEXT_CHOICE_4_IMAGE_QUESTION') {
            type = QuestionType.mcq;
            final opts = q['options'] as List<dynamic>? ?? [];
            for (var o in opts) {
              final text = o['text'] as String;
              options.add(QuestionOption(label: '', value: text));
              if (o['isCorrect'] == true) {
                correctAnswers.add(text);
              }
            }
          } else if (template == 'MATCHING_PAIRS') {
            type = QuestionType.matching;
            final pairs = q['pairs'] as List<dynamic>? ?? [];
            for (var p in pairs) {
              final left = p['left'] as Map<String, dynamic>;
              final right = p['right'] as Map<String, dynamic>;
              matchingPairs.add(MatchingPair(
                itemA: left['image'] as String,
                itemABrief: left['imageBrief'] as String,
                itemB: right['image'] as String,
                itemBBrief: right['imageBrief'] as String,
              ));
            }
          } else if (template == 'SEQUENCE') {
            type = QuestionType.sorting;
            final items = q['items'] as List<dynamic>? ?? [];
            // Sort them correctly based on correctOrder
            items.sort((a, b) => (a['correctOrder'] as int).compareTo(b['correctOrder'] as int));
            sortedOrder = items.map((e) => e['text'] as String).toList();
          }

          return QuizQuestion(
            id: q['id'] as String,
            subject: q['subject'] as String,
            text: q['questionText'] as String? ?? '',
            type: type,
            options: options,
            correctAnswers: correctAnswers,
            matchingPairs: matchingPairs,
            sortedOrder: sortedOrder,
            instruction: q['instruction'] as String?,
            expectedAnswer: q['expectedAnswer'] as String?,
            acceptableAnswers: (q['acceptableAnswers'] as List<dynamic>?)?.cast<String>() ?? [],
            explanation: q['explanation'] as String?,
            questionImage: q['questionImage'] as String?,
            questionImageBrief: q['questionImageBrief'] as String?,
            visualAid: template == 'TEXT_CHOICE_4_IMAGE_QUESTION' ? 'text_choice_image' 
                     : template == 'MATCHING_PAIRS' ? 'match_pairs_images'
                     : template == 'SEQUENCE' ? 'sequence_text' : 'voice_response',
          );
        }).toList();
      } catch (e) {
        debugPrint('Error loading questions.json: $e');
        return [];
      }
    }

    final lowerSubject = subject.toLowerCase();
    final List<QuizQuestion> questions = [];
    
    
    for (int i = 0; i < 5; i++) {
      final qId = '${subject}_l${lesson}_q${i+1}';
      
      if (i == 0) {
        questions.add(QuizQuestion(
          id: qId,
          subject: subject,
          text: lowerSubject.contains('math') ? 'What is 8 x 7?'
              : lowerSubject.contains('sci') ? 'Which gas do plants absorb from the atmosphere?' 
              : 'Which of the following is a noun?',
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
      } else if (i == 1) {
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
            const QuestionOption(label: 'C', value: '⚪'),
            const QuestionOption(label: 'D', value: '⭐'),
          ] : lowerSubject.contains('sci') ? [
            const QuestionOption(label: 'A', value: '🦅'),
            const QuestionOption(label: 'B', value: '🐟'),
            const QuestionOption(label: 'C', value: '🐶'),
            const QuestionOption(label: 'D', value: '🦎'),
          ] : [
            const QuestionOption(label: 'A', value: '🥦'),
            const QuestionOption(label: 'B', value: '🍎'),
            const QuestionOption(label: 'C', value: '🥕'),
            const QuestionOption(label: 'D', value: '🍞'),
          ],
          correctAnswers: lowerSubject.contains('math') ? ['🔺'] : lowerSubject.contains('sci') ? ['🐶'] : ['🍎'],
          visualAid: 'image_choice',
        ));
      } else if (i == 2) {
        questions.add(QuizQuestion(
          id: qId,
          subject: subject,
          text: lowerSubject.contains('math') ? 'Sort into Odd and Even'
              : lowerSubject.contains('sci') ? 'Sort into Herbivore and Carnivore'
              : 'Sort into Vowels and Consonants',
          type: QuestionType.sorting,
          matchingPairs: lowerSubject.contains('math') ? [
            const MatchingPair(itemA: '1', itemB: 'Odd'),
            const MatchingPair(itemA: '3', itemB: 'Odd'),
            const MatchingPair(itemA: '4', itemB: 'Even'),
            const MatchingPair(itemA: '6', itemB: 'Even'),
          ] : lowerSubject.contains('sci') ? [
            const MatchingPair(itemA: '🐄', itemB: 'Herbivore'),
            const MatchingPair(itemA: '🐎', itemB: 'Herbivore'),
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
      } else if (i == 3) {
        questions.add(QuizQuestion(
          id: qId,
          subject: subject,
          text: 'Match the related pairs',
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
      } else if (i == 4) {
        questions.add(QuizQuestion(
          id: qId,
          subject: subject,
          text: lowerSubject.contains('math') ? 'Order these numbers from smallest to largest'
              : lowerSubject.contains('sci') ? 'Order the butterfly life cycle'
              : 'Order these letters alphabetically',
          type: QuestionType.sorting,
          sortedOrder: lowerSubject.contains('math') ? ['0.25', '1.5', '3.0', '10.5']
              : lowerSubject.contains('sci') ? ['Egg 🥚', 'Caterpillar 🐛', 'Chrysalis 🪹', 'Butterfly 🦋']
              : ['A', 'F', 'M', 'Z'],
          visualAid: 'sequence',
        ));
      }
    }

    return questions;
  }
}
