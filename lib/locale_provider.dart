import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale; // Null means use system locale initially

  Locale? get locale => _locale;

  /// Sets the new locale for the application.
  /// If null, the system locale will be used.
  void setLocale(Locale? newLocale) {
    if (_locale != newLocale) { // Only update if it's actually different
      _locale = newLocale;
      notifyListeners(); // Notify all listening widgets to rebuild
    }
  }

  /// Helper to get the display name for a locale
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ms':
        return 'Bahasa Melayu';
    // Add more cases for other supported languages
      default:
        return locale.languageCode; // Fallback to language code
    }
  }

/// Persist locale selection (Optional, but recommended)
/// You'd use shared_preferences or similar here
// Future<void> loadLocale() async {
//   final prefs = await SharedPreferences.getInstance();
//   final languageCode = prefs.getString('selectedLanguageCode');
//   if (languageCode != null) {
//     _locale = Locale(languageCode);
//     notifyListeners();
//   }
// }
//
// Future<void> saveLocale(Locale? locale) async {
//   final prefs = await SharedPreferences.getInstance();
//   if (locale != null) {
//     await prefs.setString('selectedLanguageCode', locale.languageCode);
//   } else {
//     await prefs.remove('selectedLanguageCode');
//   }
// }
}