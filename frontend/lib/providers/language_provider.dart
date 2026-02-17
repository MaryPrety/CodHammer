import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  bool _isEnglish = false;

  bool get isEnglish => _isEnglish;
  bool get isRussian => !_isEnglish;
  Locale get locale => _isEnglish ? const Locale('en', 'US') : const Locale('ru', 'RU');

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      _isEnglish = savedLanguage == 'en';
      notifyListeners();
    } catch (e) {
      // Используем значение по умолчанию (русский)
      _isEnglish = false;
    }
  }

  Future<void> toggleLanguage() async {
    _isEnglish = !_isEnglish;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _isEnglish ? 'en' : 'ru');
    } catch (e) {
      debugPrint('Ошибка сохранения языка: $e');
    }
  }

  void setLanguage(bool isEnglish) {
    if (_isEnglish != isEnglish) {
      _isEnglish = isEnglish;
      notifyListeners();
      _saveLanguage();
    }
  }

  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _isEnglish ? 'en' : 'ru');
    } catch (e) {
      debugPrint('Ошибка сохранения языка: $e');
    }
  }
}
