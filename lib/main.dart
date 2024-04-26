import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:feedback/feedback.dart';
import 'package:sab_menu_transliteration_helper/widgets/help_pane.dart';

import 'theme.dart';
import 'widgets/body.dart';
import 'widgets/nav.dart';
import 'providers/nav_controller.dart';

late Box userPrefsBox;

void main() async {
  await Hive.initFlutter();
  userPrefsBox = await Hive.openBox('userPrefs');
  runApp(
    BetterFeedback(
      child: MultiProvider(providers: [
        ChangeNotifierProvider(
          create: (ctx) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => HelpPaneController(),
        ),
      ], child: const MainApp()),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeProvider themeProvider =
        Provider.of<ThemeProvider>(context, listen: true);
    //
    themeProvider.themeInit();

    return MaterialApp(
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("SAB menu transliteration helper"),
          automaticallyImplyLeading: true,
        ),
        body: const Row(
          children: [NavBar(), Body(), HelpPane()],
        ),
      ),
    );
  }
}
