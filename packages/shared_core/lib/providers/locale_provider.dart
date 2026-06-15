import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/app_strings.dart';

final localeProvider = NotifierProvider<LocaleNotifier, AppLanguage>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.english;

  void setLocale(AppLanguage lang) {
    state = lang;
  }
}
