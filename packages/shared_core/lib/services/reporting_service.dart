import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reporting_models.dart';

class ReportingService {
  final SharedPreferences _prefs;
  static const String _storageKey = 'miko_reporting_log';

  ReportingService(this._prefs);

  Future<void> saveResponse(QuizResponse response) async {
    final List<String> currentLogs = _prefs.getStringList(_storageKey) ?? [];
    currentLogs.add(jsonEncode(response.toJson()));
    await _prefs.setStringList(_storageKey, currentLogs);
  }

  List<QuizResponse> getAllResponses() {
    final List<String> currentLogs = _prefs.getStringList(_storageKey) ?? [];
    return currentLogs.map((log) => QuizResponse.fromJson(jsonDecode(log))).toList();
  }

  Future<void> clearData() async {
    await _prefs.remove(_storageKey);
  }
}

// We need to inject shared_preferences via ProviderScope in main
final reportingSharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('reportingSharedPreferencesProvider must be overridden');
});

final reportingServiceProvider = Provider<ReportingService>((ref) {
  final prefs = ref.watch(reportingSharedPreferencesProvider);
  return ReportingService(prefs);
});
