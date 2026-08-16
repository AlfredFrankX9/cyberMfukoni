import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  String _locale = 'en';

  String get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('app_language_code') ?? 'en';
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    if (_locale == languageCode) return;
    _locale = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', languageCode);
    
    // Also save the display name for backwards compatibility in SettingsScreen
    final displayName = languageCode == 'sw' ? 'Kiswahili' : 'English';
    await prefs.setString('app_language', displayName);
    
    notifyListeners();
  }
}
