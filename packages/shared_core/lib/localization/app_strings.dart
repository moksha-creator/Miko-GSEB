enum AppLanguage { english, gujarati }

class AppStrings {
  static const Map<String, Map<AppLanguage, String>> _translations = {
    // General
    'done': {AppLanguage.english: 'Done', AppLanguage.gujarati: 'થઈ ગયું'},
    'skip': {AppLanguage.english: 'Skip', AppLanguage.gujarati: 'છોડી દો'},
    'pause': {AppLanguage.english: 'Pause', AppLanguage.gujarati: 'થોભાવો'},
    'resume': {AppLanguage.english: 'Resume', AppLanguage.gujarati: 'ફરી શરૂ કરો'},
    'end': {AppLanguage.english: 'End', AppLanguage.gujarati: 'સમાપ્ત'},
    'listening': {AppLanguage.english: 'Listening...', AppLanguage.gujarati: 'સાંભળી રહ્યા છીએ...'},
    'tap_to_speak': {AppLanguage.english: 'Tap to speak', AppLanguage.gujarati: 'બોલવા માટે ટેપ કરો'},
    'no_questions': {AppLanguage.english: 'No questions available.', AppLanguage.gujarati: 'કોઈ પ્રશ્નો ઉપલબ્ધ નથી.'},
    

    // Student App additions
    'grade_5_b': {AppLanguage.english: 'Grade 5 B', AppLanguage.gujarati: 'ધોરણ 5 બ'},
    'mark_absent': {AppLanguage.english: 'Mark Absent', AppLanguage.gujarati: 'ગેરહાજર ચિહ્નિત કરો'},
    'session_complete': {AppLanguage.english: 'Session Complete', AppLanguage.gujarati: 'સત્ર પૂર્ણ'},
    'all_students_processed': {AppLanguage.english: 'All students have been processed.', AppLanguage.gujarati: 'બધા વિદ્યાર્થીઓની પ્રક્રિયા થઈ ગઈ છે.'},
    'call_child_to_board': {AppLanguage.english: 'Call the child to the board · tap Start session', AppLanguage.gujarati: 'બાળકને બોર્ડ પર બોલાવો · સત્ર શરૂ કરવા માટે ટેપ કરો'},
    'math': {AppLanguage.english: 'math', AppLanguage.gujarati: 'ગણિત'},
    'eng': {AppLanguage.english: 'eng', AppLanguage.gujarati: 'અંગ્રેજી'},
    'guj': {AppLanguage.english: 'guj', AppLanguage.gujarati: 'ગુજરાતી'},
    'evs': {AppLanguage.english: 'evs', AppLanguage.gujarati: 'પર્યાવરણ અભ્યાસ'},

    'good_morning_teacher': {AppLanguage.english: 'Good Morning, Teacher!', AppLanguage.gujarati: 'શુભ સવાર, શિક્ષક!'},
    'assessment_dashboard_today': {AppLanguage.english: "Here's your assessment dashboard for today.", AppLanguage.gujarati: 'અહીં તમારું આજના મૂલ્યાંકન ડેશબોર્ડ છે.'},
    'now_assessing': {AppLanguage.english: 'Now Assessing', AppLanguage.gujarati: 'હવે મૂલ્યાંકન થઈ રહ્યું છે'},

    'todays_session': {AppLanguage.english: "Today's Session", AppLanguage.gujarati: 'આજનું સત્ર'},
    'skipped_today': {AppLanguage.english: 'Skipped Today', AppLanguage.gujarati: 'આજે છોડેલા'},
    'dont_worry': {AppLanguage.english: "Don't worry!", AppLanguage.gujarati: 'ચિંતા કરશો નહીં!'},
    'try_again_tomorrow': {AppLanguage.english: 'They can try again tomorrow', AppLanguage.gujarati: 'તેઓ આવતીકાલે ફરી પ્રયાસ કરી શકે છે'},
    'no_skipped_children': {AppLanguage.english: 'No skipped children!', AppLanguage.gujarati: 'કોઈ બાળક છોડવામાં આવ્યું નથી!'},
    'all_evaluated': {AppLanguage.english: 'All Active Students Evaluated!', AppLanguage.gujarati: 'બધા સક્રિય વિદ્યાર્થીઓનું મૂલ્યાંકન પૂર્ણ થયું!'},
    'roll_no': {AppLanguage.english: 'Roll No.', AppLanguage.gujarati: 'રોલ નં.'},

    // Settings
    'settings': {AppLanguage.english: 'Settings', AppLanguage.gujarati: 'સેટિંગ્સ'},
    'class_settings': {AppLanguage.english: 'Class Settings', AppLanguage.gujarati: 'વર્ગ સેટિંગ્સ'},
    'class_profile': {AppLanguage.english: 'Class Profile', AppLanguage.gujarati: 'વર્ગ પ્રોફાઇલ'},
    'class_pacing_planner': {AppLanguage.english: 'Class Pacing Planner', AppLanguage.gujarati: 'વર્ગ ગતિ આયોજક'},
    'calculate_buffers': {AppLanguage.english: 'Calculate buffers and teaching schedules', AppLanguage.gujarati: 'બફર્સ અને શિક્ષણ સમયપત્રક ની ગણતરી કરો'},
    'period_length': {AppLanguage.english: 'Period Length', AppLanguage.gujarati: 'પીરિયડ લંબાઈ'},
    'school_calendar': {AppLanguage.english: 'School Calendar', AppLanguage.gujarati: 'શાળા કેલેન્ડર'},
    'app_settings': {AppLanguage.english: 'App Settings', AppLanguage.gujarati: 'એપ્લિકેશન સેટિંગ્સ'},
    'notifications': {AppLanguage.english: 'Notifications', AppLanguage.gujarati: 'સૂચનાઓ'},
    'language': {AppLanguage.english: 'Language', AppLanguage.gujarati: 'ભાષા'},
    'developer_demo': {AppLanguage.english: 'Developer Demo', AppLanguage.gujarati: 'ડેવલપર ડેમો'},
    'reset_demo_data': {AppLanguage.english: 'Reset Demo Data', AppLanguage.gujarati: 'ડેમો ડેટા રીસેટ કરો'},
    'demo_reset_msg': {AppLanguage.english: 'Demo data reset. Returning to start.', AppLanguage.gujarati: 'ડેમો ડેટા રીસેટ થયો. શરૂઆત પર પાછા ફરી રહ્યા છીએ.'},

    // Tabs
    'today': {AppLanguage.english: 'Today', AppLanguage.gujarati: 'આજે'},
    'class': {AppLanguage.english: 'Class', AppLanguage.gujarati: 'વર્ગ'},
    'reports': {AppLanguage.english: 'Reports', AppLanguage.gujarati: 'રિપોર્ટ્સ'},

    // Today Tab
    'hi_teacher': {AppLanguage.english: 'Hi, Teacher', AppLanguage.gujarati: 'નમસ્તે, શિક્ષક'},
    'up_next': {AppLanguage.english: 'UP NEXT', AppLanguage.gujarati: 'આગળ'},
    'grade_5_math': {AppLanguage.english: 'Grade 5 Math', AppLanguage.gujarati: 'ધોરણ 5 ગણિત'},
    'topic_fractions': {AppLanguage.english: 'Topic: Fractions', AppLanguage.gujarati: 'વિષય: અપૂર્ણાંક'},
    'start_assessment': {AppLanguage.english: 'Start Assessment', AppLanguage.gujarati: 'આકારણી શરૂ કરો'},
    'recent_activity': {AppLanguage.english: 'Recent Activity', AppLanguage.gujarati: 'તાજેતરની પ્રવૃત્તિ'},

    // Class Tab
    'students': {AppLanguage.english: 'Students', AppLanguage.gujarati: 'વિદ્યાર્થીઓ'},
    'avg_attendance': {AppLanguage.english: 'Avg Attendance', AppLanguage.gujarati: 'સરેરાશ હાજરી'},
    'at_risk': {AppLanguage.english: 'At Risk', AppLanguage.gujarati: 'જોખમમાં'},
    'student_roster': {AppLanguage.english: 'Student Roster', AppLanguage.gujarati: 'વિદ્યાર્થી રોસ્ટર'},

    // Reports Tab
    'class_performance': {AppLanguage.english: 'Class Performance', AppLanguage.gujarati: 'વર્ગ પ્રદર્શન'},
    'topic_mastery': {AppLanguage.english: 'Topic Mastery', AppLanguage.gujarati: 'વિષય નિપુણતા'},
    'needs_attention': {AppLanguage.english: 'Needs Attention', AppLanguage.gujarati: 'ધ્યાનની જરૂર છે'},

    // Questions / Mock
    'what_is_8x7': {AppLanguage.english: 'What is 8 x 7?', AppLanguage.gujarati: '8 x 7 શું છે?'},
    'sort_odd_even': {AppLanguage.english: 'Sort into Odd and Even numbers.', AppLanguage.gujarati: 'એકી અને બેકી સંખ્યાઓમાં સૉર્ટ કરો.'},
    'sort_herb_carn': {AppLanguage.english: 'Sort into Herbivore and Carnivore.', AppLanguage.gujarati: 'શાકાહારી અને માંસાહારીમાં સૉર્ટ કરો.'},
    'sort_vow_cons': {AppLanguage.english: 'Sort into Vowels and Consonants.', AppLanguage.gujarati: 'સ્વરો અને વ્યંજનોમાં સૉર્ટ કરો.'},
    'match_concepts': {AppLanguage.english: 'Match the related concepts.', AppLanguage.gujarati: 'સંબંધિત ખ્યાલોને જોડો.'},
    'order_fractions': {AppLanguage.english: 'Order these fractions from smallest to largest.', AppLanguage.gujarati: 'આ અપૂર્ણાંકોને નાનાથી મોટામાં ગોઠવો.'},
    'order_planets': {AppLanguage.english: 'Order the planets from the Sun.', AppLanguage.gujarati: 'ગ્રહોને સૂર્યથી અંતરના ક્રમમાં ગોઠવો.'},
    'order_alphabet': {AppLanguage.english: 'Alphabetical order.', AppLanguage.gujarati: 'મૂળાક્ષર ક્રમ.'},
    'read_aloud_frac': {AppLanguage.english: 'Read aloud: "Numerator and Denominator"', AppLanguage.gujarati: 'મોટેથી વાંચો: "અંશ અને છેદ"'},
    'read_aloud_photo': {AppLanguage.english: 'Read aloud: "Photosynthesis"', AppLanguage.gujarati: 'મોટેથી વાંચો: "પ્રકાશસંશ્લેષણ"'},
    'read_aloud_cat': {AppLanguage.english: 'Read aloud: "The cat sat on the mat."', AppLanguage.gujarati: 'મોટેથી વાંચો: "બિલાડી સાદડી પર બેઠી."'},

    // Buckets
    'odd': {AppLanguage.english: 'Odd', AppLanguage.gujarati: 'એકી'},
    'even': {AppLanguage.english: 'Even', AppLanguage.gujarati: 'બેકી'},
    'herbivore': {AppLanguage.english: 'Herbivore', AppLanguage.gujarati: 'શાકાહારી'},
    'carnivore': {AppLanguage.english: 'Carnivore', AppLanguage.gujarati: 'માંસાહારી'},
    'vowels': {AppLanguage.english: 'Vowels', AppLanguage.gujarati: 'સ્વરો'},
    'consonants': {AppLanguage.english: 'Consonants', AppLanguage.gujarati: 'વ્યંજનો'},

    // Misc Matching
    'sun': {AppLanguage.english: 'Sun', AppLanguage.gujarati: 'સૂર્ય'},
    'star': {AppLanguage.english: 'Star', AppLanguage.gujarati: 'તારો'},
    'earth': {AppLanguage.english: 'Earth', AppLanguage.gujarati: 'પૃથ્વી'},
    'planet': {AppLanguage.english: 'Planet', AppLanguage.gujarati: 'ગ્રહ'},
    'moon': {AppLanguage.english: 'Moon', AppLanguage.gujarati: 'ચંદ્ર'},
    'satellite': {AppLanguage.english: 'Satellite', AppLanguage.gujarati: 'ઉપગ્રહ'},
    'dog': {AppLanguage.english: 'Dog', AppLanguage.gujarati: 'કૂતરો'},
    'animal': {AppLanguage.english: 'Animal', AppLanguage.gujarati: 'પ્રાણી'},
    'classroom_orchestration': {AppLanguage.english: 'Classroom Orchestration', AppLanguage.gujarati: 'વર્ગખંડ ઓર્કેસ્ટ્રેશન'},
    'subject': {AppLanguage.english: 'Subject', AppLanguage.gujarati: 'વિષય'},
    'lesson': {AppLanguage.english: 'Lesson', AppLanguage.gujarati: 'પાઠ'},
    'start_session': {AppLanguage.english: 'Start Session', AppLanguage.gujarati: 'સત્ર શરૂ કરો'},
    'absent': {AppLanguage.english: 'Absent', AppLanguage.gujarati: 'ગેરહાજર'},
    'todays_roster': {AppLanguage.english: 'Today\'s Roster', AppLanguage.gujarati: 'આજનું રોસ્ટર'},
    'home_dashboard': {AppLanguage.english: 'Home Dashboard', AppLanguage.gujarati: 'હોમ ડેશબોર્ડ'},
    'miko_teacher_hub': {AppLanguage.english: 'Miko Teacher Hub', AppLanguage.gujarati: 'મિકો શિક્ષક હબ'},
    'manage_class': {AppLanguage.english: 'Manage Class', AppLanguage.gujarati: 'વર્ગ મેનેજ કરો'},
    'view_reports': {AppLanguage.english: 'View Reports', AppLanguage.gujarati: 'રિપોર્ટ્સ જુઓ'},
    'start_smart_board': {AppLanguage.english: 'Start Smart Board Session', AppLanguage.gujarati: 'સ્માર્ટ બોર્ડ સત્ર શરૂ કરો'},
    'q': {AppLanguage.english: 'Q', AppLanguage.gujarati: 'પ્રશ્ન'},
    'of': {AppLanguage.english: 'of', AppLanguage.gujarati: 'માં થી'},
    'school_syllabus': {AppLanguage.english: 'School Syllabus', AppLanguage.gujarati: 'શાળાનો અભ્યાસક્રમ'},
    'assess_upto': {AppLanguage.english: 'Assess upto...', AppLanguage.gujarati: 'સુધીનું મૂલ્યાંકન કરો...'},
    'concepts_to_cover': {AppLanguage.english: 'Concepts to Cover', AppLanguage.gujarati: 'આવરી લેવાના ખ્યાલો'},
    'sample_question': {AppLanguage.english: 'Sample Question', AppLanguage.gujarati: 'નમૂના પ્રશ્ન'},
    'expected_answer': {AppLanguage.english: 'Expected Answer', AppLanguage.gujarati: 'અપેક્ષિત જવાબ'},
    'grade': {AppLanguage.english: 'Grade', AppLanguage.gujarati: 'ધોરણ'},
    'chapter': {AppLanguage.english: 'Chapter', AppLanguage.gujarati: 'પ્રકરણ'},
    // Student Names
    'Aarav Patel': {AppLanguage.english: 'Aarav Patel', AppLanguage.gujarati: 'આરવ પટેલ'},
    'Diya Shah': {AppLanguage.english: 'Diya Shah', AppLanguage.gujarati: 'દિયા શાહ'},
    'Krish Mehta': {AppLanguage.english: 'Krish Mehta', AppLanguage.gujarati: 'ક્રિશ મહેતા'},
    'Ananya Joshi': {AppLanguage.english: 'Ananya Joshi', AppLanguage.gujarati: 'અનન્યા જોશી'},
    'Rohan Desai': {AppLanguage.english: 'Rohan Desai', AppLanguage.gujarati: 'રોહન દેસાઈ'},
    'Priya Trivedi': {AppLanguage.english: 'Priya Trivedi', AppLanguage.gujarati: 'પ્રિયા ત્રિવેદી'},
    'Arjun Dave': {AppLanguage.english: 'Arjun Dave', AppLanguage.gujarati: 'અર્જુન દવે'},
    'Mira Parmar': {AppLanguage.english: 'Mira Parmar', AppLanguage.gujarati: 'મીરા પરમાર'},
    'Dev Gandhi': {AppLanguage.english: 'Dev Gandhi', AppLanguage.gujarati: 'દેવ ગાંધી'},
    'Kavya Raval': {AppLanguage.english: 'Kavya Raval', AppLanguage.gujarati: 'કાવ્યા રાવલ'},
    'Sneha Rao': {AppLanguage.english: 'Sneha Rao', AppLanguage.gujarati: 'સ્નેહા રાવ'},
    'Karan Patel': {AppLanguage.english: 'Karan Patel', AppLanguage.gujarati: 'કરણ પટેલ'},
    'Ravi Joshi': {AppLanguage.english: 'Ravi Joshi', AppLanguage.gujarati: 'રવિ જોશી'},
    'Neha Desai': {AppLanguage.english: 'Neha Desai', AppLanguage.gujarati: 'નેહા દેસાઈ'},
    'Arpan Shah': {AppLanguage.english: 'Arpan Shah', AppLanguage.gujarati: 'અર્પણ શાહ'},
  };

  static String t(String key, AppLanguage lang) {
    return _translations[key]?[lang] ?? key;
  }
}
