import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  
  factory LanguageService() {
    return _instance;
  }
  
  LanguageService._internal();

  final ValueNotifier<String> _currentLanguage = ValueNotifier<String>('en');

  ValueNotifier<String> get currentLanguage => _currentLanguage;

  String get languageCode => _currentLanguage.value;

  static const Map<String, String> languageCodes = {
    'English': 'en',
    'हिंदी': 'hi',
    'ગુજરાતી': 'gu',
    'मराठी': 'mr',
    'తెలుగు': 'te',
    'தமிழ்': 'ta',
    'ಕನ್ನಡ': 'kn',
    'മലയാളം': 'ml',
  };

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('app_language') ?? 'English';
      final code = languageCodes[savedLanguage] ?? 'en';
      _currentLanguage.value = code;
      debugPrint('✅ Language initialized: $code');
    } catch (e) {
      debugPrint('❌ Error initializing language: $e');
      _currentLanguage.value = 'en';
    }
  }

  Future<void> setLanguage(String languageName) async {
    try {
      final code = languageCodes[languageName] ?? 'en';
      _currentLanguage.value = code;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', languageName);
      
      debugPrint('✅ Language changed to: $languageName ($code)');
    } catch (e) {
      debugPrint('❌ Error setting language: $e');
    }
  }

  void dispose() {
    _currentLanguage.dispose();
  }
}
