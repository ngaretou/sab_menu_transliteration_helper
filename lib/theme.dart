import 'package:flutter/material.dart';

import 'main.dart';

class ThemeProvider extends ChangeNotifier {
  late ThemeData currentTheme;

  themeInit() {
    String? storedBrightness = userPrefsBox.get('theme');
    switch (storedBrightness) {
      case null:
        currentTheme = ThemeData.dark();
        userPrefsBox.put('theme', 'dark');
        break;
      case 'dark':
        currentTheme = ThemeData.dark();
        break;
      case 'light':
        currentTheme = ThemeData.light();
        break;
      default:
    }
  }

  setTheme(ThemeData theme) {
    currentTheme = theme;
    notifyListeners();
  }
}
