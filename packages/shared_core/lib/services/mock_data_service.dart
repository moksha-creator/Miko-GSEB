import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
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
      final templateIdx = i % 6;
      final qId = '${subject}_l${lesson}_q${i+1}';
      
      switch (templateIdx) {
        case 0:
          // TEXT CHOICE
          questions.add(QuizQuestion(
            id: qId,
            subject: subject,
            text: lowerSubject.contains('math') ? AppStrings.t('what_is_8x7', language)
                : lowerSubject.contains('sci') ? 'Which gas do plants absorb from the atmosphere?' 
                : 'Which is a noun?',
            type: QuestionType.mcq,
            options: lowerSubject.contains('math') ? [
              QuestionOption(label: 'A', value: '54'),
              QuestionOption(label: 'B', value: '56'),
              QuestionOption(label: 'C', value: '64'),
              QuestionOption(label: 'D', value: '48'),
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
            text: lowerSubject.contains('math') ? AppStrings.t('sort_odd_even', language)
                : lowerSubject.contains('sci') ? AppStrings.t('sort_herb_carn', language)
                : AppStrings.t('sort_vow_cons', language),
            type: QuestionType.sorting,
            matchingPairs: lowerSubject.contains('math') ? [
              MatchingPair(itemA: '1', itemB: AppStrings.t('odd', language)),
              MatchingPair(itemA: '3', itemB: AppStrings.t('odd', language)),
              MatchingPair(itemA: '4', itemB: AppStrings.t('even', language)),
              MatchingPair(itemA: '6', itemB: AppStrings.t('even', language)),
            ] : lowerSubject.contains('sci') ? [
              MatchingPair(itemA: '🐄', itemB: AppStrings.t('herbivore', language)),
              MatchingPair(itemA: '🐇', itemB: AppStrings.t('herbivore', language)),
              MatchingPair(itemA: '🐅', itemB: AppStrings.t('carnivore', language)),
              MatchingPair(itemA: '🐺', itemB: AppStrings.t('carnivore', language)),
            ] : [
              MatchingPair(itemA: 'A', itemB: AppStrings.t('vowels', language)),
              MatchingPair(itemA: 'E', itemB: AppStrings.t('vowels', language)),
              MatchingPair(itemA: 'B', itemB: AppStrings.t('consonants', language)),
              MatchingPair(itemA: 'C', itemB: AppStrings.t('consonants', language)),
            ],
            visualAid: 'two_bucket_sort',
          ));
          break;
        case 3:
          // MATCH PAIRS
          questions.add(QuizQuestion(
            id: qId,
            subject: subject,
            text: AppStrings.t('match_concepts', language),
            type: QuestionType.matching,
            matchingPairs: lowerSubject.contains('math') ? [
              const MatchingPair(itemA: '5 + 5', itemB: '10'),
              const MatchingPair(itemA: '4 x 3', itemB: '12'),
              const MatchingPair(itemA: '20 / 4', itemB: '5'),
            ] : lowerSubject.contains('sci') ? [
              MatchingPair(itemA: AppStrings.t('sun', language), itemB: AppStrings.t('star', language)),
              MatchingPair(itemA: AppStrings.t('earth', language), itemB: AppStrings.t('planet', language)),
              MatchingPair(itemA: AppStrings.t('moon', language), itemB: AppStrings.t('satellite', language)),
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
            text: lowerSubject.contains('math') ? AppStrings.t('order_fractions', language)
                : lowerSubject.contains('sci') ? AppStrings.t('order_planets', language)
                : AppStrings.t('order_alphabet', language),
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
            text: lowerSubject.contains('math') ? AppStrings.t('read_aloud_frac', language)
                : lowerSubject.contains('sci') ? AppStrings.t('read_aloud_photo', language)
                : AppStrings.t('read_aloud_cat', language),
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
