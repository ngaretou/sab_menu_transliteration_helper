import 'package:flutter/material.dart';
import 'dart:core';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/nav_controller.dart';
import '../providers/logic.dart';

class GetStrings extends StatefulWidget {
  const GetStrings({super.key});

  @override
  State<GetStrings> createState() => _GetStringsState();
}

class _GetStringsState extends State<GetStrings> {
  TextEditingController transliterationsController = TextEditingController();
  bool showCopyHelper =
      false; // this is whether or not the color overlay with icon is shown
  Icon hoveringIcon =
      const Icon(Icons.copy); // initially copy but after copy is a check mark
  late Future init;

  @override
  void initState() {
    Logic logic = Provider.of<Logic>(context, listen: false);
    //
    init = logic.initializeTransliterationList();
    //
    if (logic.listTransliterationStrings.isNotEmpty) {
      // getting displayable list
      transliterationsController.text = logic.listTransliterationsToString();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Logic logic = Provider.of<Logic>(context, listen: false);

    NavController navButtons =
        Provider.of<NavController>(context, listen: false);
    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: false);

    //This is for the nav buttons
    checkEnabling() {
      if (pageTracker.currentPage == 2) {
        if (transliterationsController.text != '') {
          navButtons.setEnabledAndNotify(true);
        } else {
          navButtons.setEnabledAndNotify(false);
        }
      }
    }

    Provider.of<PageTracker>(context, listen: true).addListener(() {
      checkEnabling();
    });

    int minLines = 50;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    //copy to clipboard
                    Clipboard.setData(
                      ClipboardData(
                        text: logic.menuItemsToTransliterateAsString,
                      ),
                    );
                    setState(() {
                      hoveringIcon = const Icon(Icons.check);
                    });
                  },
                  child: MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        showCopyHelper = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        showCopyHelper = false;
                        hoveringIcon = const Icon(Icons.copy);
                      });
                    },
                    child: Stack(children: [
                      Opacity(
                          opacity: showCopyHelper ? .5 : 0,
                          child: Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Center(child: hoveringIcon))),
                      FutureBuilder(
                        future: init,
                        builder: (ctx, snapshot) => snapshot.connectionState ==
                                ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : TextFormField(
                                enabled: false,
                                // readOnly: true,
                                minLines: minLines,
                                maxLines: minLines,
                                textCapitalization: TextCapitalization.none,
                                autocorrect: false,
                                initialValue: logic
                                        .menuItemsToTransliterateAsString
                                        .isNotEmpty
                                    ? logic.menuItemsToTransliterateAsString
                                    : "No menu translations to transliterate.\n\nUsually this is because there are no untransliterated strings and you haven't checked the 'replace existing transliterations' option. ",
                                decoration: const InputDecoration(
                                  filled: true,
                                ),
                              ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Expanded(
                child: TextFormField(
                  controller: transliterationsController,
                  onChanged: (value) {
                    logic.updateTransliterationStrings(
                        transliterationsController.text);
                    checkEnabling();
                  },

                  minLines: minLines,
                  maxLines: minLines,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      filled: true,
                      hintText:
                          'Copy the menu translations at left and paste the transliterated menus here'),

                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    } else {
                      return null;
                    }
                  },
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
