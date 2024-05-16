import 'package:flutter/material.dart';

//Provider for listening to the help pane
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

//Provider for listening to the status of the arrow buttons on each page
class NavController extends ChangeNotifier {
  bool enabled = false;

  void setEnabledAndNotify(bool incoming) {
    enabled = incoming;
    notifyListeners();
  }
}

class PageTracker extends ChangeNotifier {
  int currentPage = 0;
  setPage(int incoming) {
    currentPage = incoming;
    notifyListeners();
  }
}
