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
              final activeSubjects = activeSubjectsList?.cast<String>().toSet() ?? {'math', 'eng', 'guj', 'evs'};
              final List<Student> customStudents = [];
              final coreStudents = baseProfile.students;
              final coreCount = coreStudents.length;

              final colors = [
                '#E85D55', '#4A3FB7', '#1D9E75', '#EF9F27', '#E85D55',
                '#4A3FB7', '#1D9E75', '#EF9F27', '#E85D55', '#4A3FB7'
              ];

              final Map<String, String> subjMap = {
                'math': 'Mathematics',
                'eng': 'English',
                'guj': 'Gujarati',
                'evs': 'EVS'
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
    await Future.delayed(const Duration(milliseconds: 500));
    final lowerSubject = subject.toLowerCase();
    final List<QuizQuestion> questions = [];

    if (lowerSubject.contains('math')) {
      // 1. IMAGE_CHOICE_4_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'math_q1', subject: 'Mathematics', type: QuestionType.mcq,
        text: 'Which group has 3 balls?',
        options: [
          QuestionOption(label: 'A', value: 'assets/mock_images/math_2balls.png'),
          QuestionOption(label: 'B', value: 'assets/mock_images/math_3balls.png'),
          QuestionOption(label: 'C', value: 'assets/mock_images/math_4balls.png'),
          QuestionOption(label: 'D', value: 'assets/mock_images/math_5balls.png'),
        ],
        correctAnswers: ['assets/mock_images/math_3balls.png'],
        visualAid: 'image_choice',
      ));
      // 2. TEXT_CHOICE_4_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'math_q2', subject: 'Mathematics', type: QuestionType.mcq,
        text: 'What is 5 + 3?',
        options: [
          QuestionOption(label: 'A', value: '6'),
          QuestionOption(label: 'B', value: '7'),
          QuestionOption(label: 'C', value: '8'),
          QuestionOption(label: 'D', value: '9'),
        ],
        correctAnswers: ['8'],
        visualAid: 'text_only',
      ));
      // 3. SEQUENCE_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'math_q3', subject: 'Mathematics', type: QuestionType.sorting,
        text: 'Arrange from smallest to biggest.',
        sortedOrder: ['2', '4', '6', '9'],
        visualAid: 'sequence',
      ));
      // 4. THREE_BUCKET_SORT_IMAGE_QUESTION
      questions.add(const QuizQuestion(
        id: 'math_q4', subject: 'Mathematics', type: QuestionType.sorting,
        text: 'Sort the shapes.',
        matchingPairs: [
          MatchingPair(itemA: 'assets/mock_images/math_circle.png', itemB: 'Circle'),
          MatchingPair(itemA: 'assets/mock_images/math_square.png', itemB: 'Square'),
          MatchingPair(itemA: 'assets/mock_images/math_triangle.png', itemB: 'Triangle'),
          MatchingPair(itemA: 'assets/mock_images/math_circle.png', itemB: 'Circle'),
          MatchingPair(itemA: 'assets/mock_images/math_triangle.png', itemB: 'Triangle'),
        ],
        visualAid: 'two_bucket_sort',
      ));
      // 5. IMAGE_CHOICE_2_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'math_q5', subject: 'Mathematics', type: QuestionType.mcq,
        text: "Which clock shows 3 o'clock?",
        options: [
          QuestionOption(label: 'A', value: 'assets/mock_images/math_clock3.png'),
          QuestionOption(label: 'B', value: 'assets/mock_images/math_clock6.png'),
        ],
        correctAnswers: ['assets/mock_images/math_clock3.png'],
        visualAid: 'image_choice',
      ));

    } else if (lowerSubject.contains('eng')) {
      // 1. IMAGE_CHOICE_4_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'eng_q1', subject: 'English', type: QuestionType.mcq,
        text: 'Which one is an apple?',
        options: [
          QuestionOption(label: 'A', value: '🍎'),
          QuestionOption(label: 'B', value: '🍌'),
          QuestionOption(label: 'C', value: '🐱'),
          QuestionOption(label: 'D', value: '⚽'),
        ],
        correctAnswers: ['🍎'],
        visualAid: 'image_choice',
      ));
      // 2. TEXT_CHOICE_2_IMAGE_QUESTION
      questions.add(const QuizQuestion(
        id: 'eng_q2', subject: 'English', type: QuestionType.mcq,
        text: '🐱',
        options: [
          QuestionOption(label: 'A', value: 'Cat'),
          QuestionOption(label: 'B', value: 'Dog'),
        ],
        correctAnswers: ['Cat'],
        visualAid: 'text_choice_image',
      ));
      // 3. MATCH_PAIRS_TEXT_IMAGE_QUESTION
      questions.add(const QuizQuestion(
        id: 'eng_q3', subject: 'English', type: QuestionType.matching,
        text: 'Match each word to its picture.',
        matchingPairs: [
          MatchingPair(itemA: 'Sun', itemB: '🌞'),
          MatchingPair(itemA: 'Tree', itemB: '🌳'),
          MatchingPair(itemA: 'Fish', itemB: '🐟'),
        ],
        visualAid: 'match_pairs',
      ));
      // 4. SEQUENCE_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'eng_q4', subject: 'English', type: QuestionType.sorting,
        text: 'Put the letters in order.',
        sortedOrder: ['A', 'B', 'C', 'D'],
        visualAid: 'sequence',
      ));
      // 5. VOICE_RESPONSE_IMAGE_QUESTION
      questions.add(const QuizQuestion(
        id: 'eng_q5', subject: 'English', type: QuestionType.verbal,
        text: 'Say the name of this animal: 🐘',
        correctAnswers: ['elephant'],
        visualAid: 'voice_response',
      ));

    } else if (lowerSubject.contains('guj')) {
      // 1. IMAGE_CHOICE_4_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'guj_q1', subject: 'Gujarati', type: QuestionType.mcq,
        text: "કયું ચિત્ર 'કમળ' છે?",
        options: [
          QuestionOption(label: 'A', value: '🪷'),
          QuestionOption(label: 'B', value: '🌹'),
          QuestionOption(label: 'C', value: '🍌'),
          QuestionOption(label: 'D', value: '🥁'),
        ],
        correctAnswers: ['🪷'],
        visualAid: 'image_choice',
      ));
      // 2. TEXT_CHOICE_2_IMAGE_QUESTION
      questions.add(const QuizQuestion(
        id: 'guj_q2', subject: 'Gujarati', type: QuestionType.mcq,
        text: '🐄',
        options: [
          QuestionOption(label: 'A', value: 'ગાય'),
          QuestionOption(label: 'B', value: 'બકરી'),
        ],
        correctAnswers: ['ગાય'],
        visualAid: 'text_choice_image',
      ));
      // 3. MATCH_PAIRS_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'guj_q3', subject: 'Gujarati', type: QuestionType.matching,
        text: 'વિરુદ્ધાર્થી જોડો. (Match the opposites.)',
        matchingPairs: [
          MatchingPair(itemA: 'મોટું', itemB: 'નાનું'),
          MatchingPair(itemA: 'દિવસ', itemB: 'રાત'),
          MatchingPair(itemA: 'ઉપર', itemB: 'નીચે'),
        ],
        visualAid: 'match_pairs',
      ));
      // 4. SEQUENCE_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'guj_q4', subject: 'Gujarati', type: QuestionType.sorting,
        text: 'કક્કાના ક્રમમાં ગોઠવો.',
        sortedOrder: ['ક', 'ખ', 'ગ', 'ઘ'],
        visualAid: 'sequence',
      ));
      // 5. VOICE_RESPONSE_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'guj_q5', subject: 'Gujarati', type: QuestionType.verbal,
        text: "આ શબ્દ મોટેથી વાંચો: 'સૂરજ'",
        correctAnswers: ['સૂરજ'],
        visualAid: 'voice_response',
      ));

    } else if (lowerSubject.contains('evs')) {
      // 1. TWO_BUCKET_SORT_IMAGE_QUESTION
      questions.add(const QuizQuestion(
        id: 'evs_q1', subject: 'EVS', type: QuestionType.sorting,
        text: 'Sort into Animals and Plants.',
        matchingPairs: [
          MatchingPair(itemA: '🐄', itemB: 'Animals'),
          MatchingPair(itemA: '🌳', itemB: 'Plants'),
          MatchingPair(itemA: '🐶', itemB: 'Animals'),
          MatchingPair(itemA: '🌹', itemB: 'Plants'),
        ],
        visualAid: 'two_bucket_sort',
      ));
      // 2. IMAGE_CHOICE_2_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'evs_q2', subject: 'EVS', type: QuestionType.mcq,
        text: 'Which one do we drink water from?',
        options: [
          QuestionOption(label: 'A', value: '🥛'),
          QuestionOption(label: 'B', value: '👞'),
        ],
        correctAnswers: ['🥛'],
        visualAid: 'image_choice',
      ));
      // 3. THREE_BUCKET_SORT_TEXT_QUESTION
      questions.add(const QuizQuestion(
        id: 'evs_q3', subject: 'EVS', type: QuestionType.sorting,
        text: 'Sort by where they live.',
        matchingPairs: [
          MatchingPair(itemA: 'Cow', itemB: 'Land'),
          MatchingPair(itemA: 'Fish', itemB: 'Water'),
          MatchingPair(itemA: 'Crow', itemB: 'Sky'),
          MatchingPair(itemA: 'Tiger', itemB: 'Land'),
          MatchingPair(itemA: 'Lotus', itemB: 'Water'),
        ],
        visualAid: 'two_bucket_sort',
      ));
      // 4. MATCH_PAIRS_TEXT_IMAGE_QUESTION
      questions.add(const QuizQuestion(
        id: 'evs_q4', subject: 'EVS', type: QuestionType.matching,
        text: 'Match the animal to its home.',
        matchingPairs: [
          MatchingPair(itemA: '🐶', itemB: 'Kennel'),
          MatchingPair(itemA: '🐦', itemB: 'Nest'),
          MatchingPair(itemA: '🐄', itemB: 'Shed'),
        ],
        visualAid: 'match_pairs',
      ));
      // 5. IMAGE_CHOICE_4_IMAGE_QUESTION
      questions.add(const QuizQuestion(
        id: 'evs_q5', subject: 'EVS', type: QuestionType.mcq,
        text: 'Match clothes to the weather: 🌧️',
        options: [
          QuestionOption(label: 'A', value: '🧥'),
          QuestionOption(label: 'B', value: '🧣'),
          QuestionOption(label: 'C', value: '🩱'),
          QuestionOption(label: 'D', value: '🧢'),
        ],
        correctAnswers: ['🧥'],
        visualAid: 'image_choice',
      ));
    }

    return questions;
  }
}



