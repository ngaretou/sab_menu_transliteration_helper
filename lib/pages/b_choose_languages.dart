import 'package:flutter/material.dart';
import 'dart:core';
import 'package:provider/provider.dart';
import '../providers/nav_controller.dart';
import '../providers/logic.dart';

class ChooseLanguages extends StatefulWidget {
  const ChooseLanguages({super.key});

  @override
  State<ChooseLanguages> createState() => _ChooseLanguagesState();
}

class _ChooseLanguagesState extends State<ChooseLanguages> {
  TextEditingController newLangController = TextEditingController();
  TextEditingController sourceController = TextEditingController();
  TextEditingController destController = TextEditingController();

  late Future langinit;

  @override
  void initState() {
    langinit = Provider.of<Logic>(context, listen: false).parseXMLLangs();
    super.initState();
  }

  @override
  void dispose() {
    newLangController.dispose();
    sourceController.dispose();
    destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Logic logic = Provider.of<Logic>(context, listen: false);
    Logic logicListener = Provider.of<Logic>(context, listen: true);

    NavController navButtons =
        Provider.of<NavController>(context, listen: false);
    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: false);

    checkForNavEnabling() {
      if (pageTracker.currentPage == 1) {
        if (logic.source != '' && logic.dest != '') {
          navButtons.setEnabledAndNotify(true);
        } else {
          navButtons.setEnabledAndNotify(false);
        }
      }
    }

    //This is for the nav buttons
    Provider.of<PageTracker>(context, listen: true).addListener(() {
      checkForNavEnabling();
    });

    return FutureBuilder(
        future: langinit,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            logic.chooseActiveLanguages(
                sourceController.text, destController.text);

            List<DropdownMenuEntry<String>> dropdownMenuEntries() {
              List<DropdownMenuEntry<String>> entries = [];
              for (String language in logic.languagesActive) {
                DropdownMenuEntry<String> entry =
                    DropdownMenuEntry(value: language, label: language);
                entries.add(entry);
              }
              return entries;
            }

            bool hasLanguages = logic.languagesActive.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                      'Choose the source and the destination language. '),
                  const Text(
                      'If you are adding a new script for the first time, click the plus to add the language abbreviation.'),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 100, child: Text('Source')),
                      const SizedBox(width: 100),
                      DropdownMenu(
                        enabled: hasLanguages,
                        controller: sourceController,
                        initialSelection: logicListener.source,
                        dropdownMenuEntries: dropdownMenuEntries(),
                        onSelected: (value) {
                          logic.setSource(value!);
                          checkForNavEnabling();
                        },
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      const SizedBox(
                        width: 40,
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 100, child: Text('Destination')),
                      const SizedBox(width: 100),
                      DropdownMenu(
                        enabled: hasLanguages,
                        controller: destController,
                        initialSelection: logic.dest,
                        dropdownMenuEntries: dropdownMenuEntries(),
                        onSelected: (value) {
                          logic.setDest(value!, false);
                          checkForNavEnabling();
                        },
                      ),
                      const SizedBox(
                        width: 20,
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton.filled(
                            onPressed: () {
                              showDialog(
                                  barrierDismissible: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    newLangSubmit() {
                                      logic.addNewLanguage(
                                          newLangController.text);
                                      destController.text =
                                          newLangController.text;
                                      newLangController.text = '';

                                      checkForNavEnabling();
                                      Navigator.of(context).pop();
                                    }

                                    return Center(
                                        child: Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondaryContainer,
                                            ),
                                            height: 200,
                                            width: 250,
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                      'Add a new language code here'),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  TextFormField(
                                                    autofocus: true,
                                                    textCapitalization:
                                                        TextCapitalization.none,
                                                    autocorrect: false,
                                                    decoration:
                                                        const InputDecoration(
                                                      filled: true,
                                                      hintText: 'new lang code',
                                                    ),
                                                    controller:
                                                        newLangController,
                                                    // The validator receives the text that the user has entered.
                                                    validator: (value) {
                                                      if (value == null ||
                                                          value.isEmpty) {
                                                        return 'Please enter some text';
                                                      } else {
                                                        return null;
                                                      }
                                                    },
                                                    onFieldSubmitted: (value) =>
                                                        newLangSubmit(),
                                                  ),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      ElevatedButton(
                                                          onPressed: () =>
                                                              newLangSubmit(),
                                                          child:
                                                              const Text('OK')),
                                                      const SizedBox(
                                                        width: 20,
                                                      ),
                                                      ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                              'Cancel')),
                                                    ],
                                                  ),
                                                ])));
                                  });
                            },
                            icon: const Icon(Icons.add)),
                      )
                    ],
                  ),
                  const SizedBox(
                    width: 400,
                    child: Divider(
                      height: 60,
                    ),
                  ),
                  SizedBox(
                    width: 374,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                            'Replace existing transliterations for destination'),
                        Switch(
                            value: logic.replaceExistingTransliterations,
                            onChanged: (value) {
                              logic.setReplaceExistingTransliterations(value);
                            })
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        });
  }
}
