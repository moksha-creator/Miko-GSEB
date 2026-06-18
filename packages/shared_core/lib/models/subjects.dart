import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class Subjects {
  static const List<String> ids = ['math', 'eng', 'guj', 'evs'];

  static const Map<String, String> _names = {
    'math': 'Mathematics',
    'eng': 'English',
    'guj': 'Gujarati',
    'evs': 'EVS',
  };

  static const Map<String, Color> _colors = {
    'math': AppColors.primary,
    'eng': AppColors.success,
    'guj': AppColors.warning,
    'evs': AppColors.accent,
  };

  static const Map<String, IconData> _icons = {
    'math': Icons.calculate,
    'eng': Icons.menu_book,
    'guj': Icons.language,
    'evs': Icons.eco,
  };

  static const Map<String, int> _defaultLectures = {
    'math': 4,
    'eng': 4,
    'guj': 4,
    'evs': 4,
  };

  static List<String> get all => ids;

  static String name(String id) => _names[id] ?? id;
  static Color color(String id) => _colors[id] ?? AppColors.primary;
  static IconData icon(String id) => _icons[id] ?? Icons.book;
  static Map<String, int> defaultLectures() => Map.from(_defaultLectures);
}
