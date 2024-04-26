import 'package:flutter/material.dart';

class HelpPaneController extends ChangeNotifier {
  List<Widget> activeWidgets = [];

  void closeHelpPane({bool refresh = true}) {
    activeWidgets = [];
    if (refresh == true) {
      notifyListeners();
    }
  }

  void setActiveWidget(BuildContext context, List<Widget> widgets) {
    List<Widget> widgetList = [
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        IconButton(
          onPressed: () => closeHelpPane(),
          icon: const Icon(Icons.close),
        ),
      ]),
    ];

    widgetList.addAll(widgets);

    activeWidgets = widgetList;

    notifyListeners();
  }
}
