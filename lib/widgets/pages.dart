import 'dart:core';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'dart:collection';

import '../providers/file_contents.dart';

Color pageBackgroundColor = Colors.transparent;

//These are variables we'll use in all pages
List<String> fileAsList = [];
List<FileContents> originalFileContents = [];
List<FileContents> newFileContents = [];
List<FileContents> menuItemsToTransliterate = [];
String menuItemsToTransliterateAsString = '';
String menuItemsTransliteratedAsString = '';
List<String> menuItemsTransliteratedAsList = [];
List<String> menuItems = []; //the section headers
String textFile = ''; //The whole text file
String source = ''; //The source lang code
String dest = ''; //destination lang code
bool replaceExistingTransliterations = false;

//Page one
class LoadTranslations extends StatefulWidget {
  final VoidCallback pageForward;
  const LoadTranslations({super.key, required this.pageForward});

  @override
  State<LoadTranslations> createState() => _LoadTranslationsState();
}

class _LoadTranslationsState extends State<LoadTranslations> {
  bool acceptDrop = true;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: pageBackgroundColor,
      child: DropRegion(
          // Formats this region can accept.
          formats: const [Formats.plainTextFile],
          hitTestBehavior: HitTestBehavior.opaque,
          onDropOver: (event) {
            // You can inspect local data here, as well as formats of each item.
            // However on certain platforms (mobile / web) the actual data is
            // only available when the drop is accepted (onPerformDrop).
            final item = event.session.items.first;
            if (item.localData is Map) {
              // This is a drag within the app and has custom local data set.
            }
            if (item.canProvide(Formats.plainText)) {
              // this item contains plain text.
              debugPrint('yes to plain text in dropover from onDropOver');
              final item = event.session.items.first;
              if (item.canProvide(Formats.plainText)) {
                // this item contains plain text.
                setState(() {
                  pageBackgroundColor =
                      Theme.of(context).colorScheme.primaryContainer;
                });
              }
            } else {
              setState(() {
                pageBackgroundColor =
                    Theme.of(context).colorScheme.errorContainer;
              });
            }
            // This drop region only supports copy operation.
            if (event.session.allowedOperations.contains(DropOperation.copy)) {
              return DropOperation.copy;
            } else {
              return DropOperation.none;
            }
          },
          // onDropEnter: (event) {
          //   // This is called when region first accepts a drag. You can use this
          //   // to display a visual indicator that the drop is allowed.
          //   if (event.session.items.first.dataReader != null) {
          //     print('tnering if');
          //     final dataReader = event.session.items.first.dataReader!;
          //     if (!dataReader.canProvide(Formats.plainTextFile)) {
          //       print('file type no good');
          //

          //       return;
          //     } else {
          //       print('loooks like were good to go');
          //       dataReader.getFile(Formats.plainTextFile, (value) async {
          //         final mydata = utf8.decode(await value.readAll());
          //       });
          //     }
          //   }
          // },
          onDropLeave: (event) {
            // Called when drag leaves the region. Will also be called after
            // drag completion.
            // This is a good place to remove any visual indicators.
            setState(() {
              pageBackgroundColor = Colors.transparent;
            });
          },
          onPerformDrop: (event) async {
            // Called when user dropped the item. You can now request the data.
            // Note that data must be requested before the performDrop callback
            // is over.

            //The drag and drop fires multiple times for some reason. The acceptDrop bool
            //with the brief timer reset below lets the first one through and ignores
            //all other requests for that amount of time.
            if (acceptDrop) {
              debugPrint('drop accepted');
              final item = event.session.items.first;

              // data reader is available now
              final reader = item.dataReader!;
              if (reader.canProvide(Formats.plainText)) {
                reader.getValue<String>(Formats.plainText, (value) {
                  // You can access values through the `value` property.
                  if (value != null) {
                    textFile = value;
                    fileAsList = value.split('\n');
                    //Feedback
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          Future.delayed(Durations.extralong2,
                              () => Navigator.of(context).pop());

                          return Center(
                              child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.0),
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                  ),
                                  height: 80,
                                  width: 128,
                                  child: const Icon(Icons.check)));
                        });

                    widget.pageForward();
                  }
                }, onError: (error) {
                  debugPrint('Error reading value $error');
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unsupported File Type')));
                return;
              }
            }

            acceptDrop = false;
            //this resets the acceptDrop after a set time period.
            Future.delayed((Durations.long4), () {
              acceptDrop = true;
            });
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 80, color: Theme.of(context).colorScheme.primary),
              const SizedBox(
                height: 20,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.0),
                child: Text(
                    'Drag and drop your exported menu translations from SAB or click below to choose the file or paste the contents'),
              ),
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.file_open),
                      label: const Text('Choose file')),
                  const SizedBox(
                    width: 20,
                  ),
                  FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.paste),
                      label: const Text('Paste contents')),
                  const SizedBox(
                    width: 20,
                  ),
                  FilledButton.icon(
                      onPressed: () {
                        // widget.pageForward();
                      },
                      icon: const Icon(Icons.question_mark),
                      label: const Text('Test')),
                ],
              )
            ],
          )),
    );
  }
}

//Page 2
class ChooseLanguages extends StatefulWidget {
  const ChooseLanguages({super.key});

  @override
  State<ChooseLanguages> createState() => _ChooseLanguagesState();
}

class _ChooseLanguagesState extends State<ChooseLanguages> {
  TextEditingController newLangController = TextEditingController();
  TextEditingController sourceController = TextEditingController();
  TextEditingController destController = TextEditingController();
  Set languages = {};
  Set languagesActive = {};

  late Future langinit;

  Future getLanguages() async {
    List<String> langCodesList = [];
    String currentSection = 'header';

    for (String line in fileAsList) {
      final RegExpMatch? match = RegExp(r'(^)(\w+)(: )(.*)').firstMatch(line);
      String? langCodeToAdd;
      String contentsToAdd = '';

      if (match != null) {
        //get lang codes
        if (match.group(2) != null) {
          langCodesList.add(match.group(2)!);
        }
        langCodeToAdd = match.group(2)!;
        contentsToAdd = match.group(4)!;
      } else if (line.startsWith('\$')) {
        //Create the list of menuItems like
        //$ Menu_Bible
        //$ Menu_Contents
        currentSection = line;
        menuItems.add(currentSection);
        langCodeToAdd = null;
        contentsToAdd = line;
      } else {
        langCodeToAdd = null;
        contentsToAdd = line;
      }

      originalFileContents.add(FileContents(
          key: UniqueKey(),
          langCode: langCodeToAdd,
          contents: contentsToAdd,
          section: currentSection));
    }

    //get langs to unique values
    Set<String> langCodesSet = langCodesList.toSet();
    languages = SplayTreeSet<String>.from(langCodesSet);

    return;
  }

  @override
  void initState() {
    langinit = getLanguages();
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
    return FutureBuilder(
        future: langinit,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            print('building under FB');
            languagesActive = languages;
            languagesActive.removeWhere((element) =>
                element == sourceController.text ||
                element == destController.text);

            List<DropdownMenuEntry<String>> dropdownMenuEntries() {
              print('building dropdownMenuEntries');
              List<DropdownMenuEntry<String>> entries = [];
              for (String language in languagesActive) {
                DropdownMenuEntry<String> entry =
                    DropdownMenuEntry(value: language, label: language);
                entries.add(entry);
              }
              return entries;
            }

            bool hasLanguages = languagesActive.isNotEmpty;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Choose the source and the destination language. '),
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
                      initialSelection: source,
                      dropdownMenuEntries: dropdownMenuEntries(),
                      onSelected: (value) {
                        source = value!;
                        setState(() {});
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
                      initialSelection: dest,
                      dropdownMenuEntries: dropdownMenuEntries(),
                      onSelected: (value) {
                        dest = value!;
                        setState(() {});
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
                                                  textCapitalization:
                                                      TextCapitalization.none,
                                                  autocorrect: false,
                                                  decoration:
                                                      const InputDecoration(
                                                    filled: true,
                                                    hintText: 'new lang code',
                                                  ),
                                                  controller: newLangController,
                                                  // The validator receives the text that the user has entered.
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter some text';
                                                    } else {
                                                      return null;
                                                    }
                                                  },
                                                ),
                                                const SizedBox(
                                                  height: 20,
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            destController
                                                                    .text =
                                                                newLangController
                                                                    .text;
                                                            dest =
                                                                newLangController
                                                                    .text;
                                                          });
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child:
                                                            const Text('OK')),
                                                    const SizedBox(
                                                      width: 20,
                                                    ),
                                                    ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
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
                          value: replaceExistingTransliterations,
                          onChanged: (value) {
                            setState(() {
                              replaceExistingTransliterations = value;
                            });
                          })
                    ],
                  ),
                ),
              ],
            );
          }
        });
  }
}

class GetStrings extends StatefulWidget {
  const GetStrings({super.key});

  @override
  State<GetStrings> createState() => _GetStringsState();
}

class _GetStringsState extends State<GetStrings> {
  late Future<String> stringInit;
  TextEditingController sourceController = TextEditingController();
  TextEditingController destController = TextEditingController();
  bool showCopyHelper = false;
  Icon hoveringIcon = const Icon(Icons.copy);

  Future<String> getStringsToTranslate() async {
    //Two cases - one where we're redoing all the transliterations, one where we're leaving the ones that are done already.
    if (replaceExistingTransliterations) {
      //If we're replacing all, go ahead and get rid of the old ones in the main list.
      originalFileContents.removeWhere((element) => element.langCode == dest);

      //And add all the source menuitems.
      menuItemsToTransliterate.addAll(
          originalFileContents.where((element) => element.langCode == source));
    } else {
      //If we're just transliterating the ones where there is no current transliteration....
      //first grab the menuitems section by section
      for (String menuItem in menuItems) {
        List<FileContents> currentSection = originalFileContents
            .where((element) => element.section == menuItem)
            .toList();

        //Does it have the source lang code?
        bool containsSource =
            currentSection.any((element) => element.langCode!.contains(source));

        //Does it have the dest lang code?
        bool containsDest =
            currentSection.any((element) => element.langCode!.contains(dest));

        //If it has the source but not the destination, add it to strings to translate
        if (containsSource && !containsDest) {
          menuItemsToTransliterate.add(currentSection
              .firstWhere((element) => element.langCode!.contains(source)));
        }
      }
    }

    //cleanup - if it's just the label with no actual text
    menuItemsToTransliterate.removeWhere((element) => element.contents == '');

    //now get the contents into a String
    for (FileContents item in menuItemsToTransliterate) {
      String carriage = '\n';

      //Note well this is RegExp with variable
      // RegExp regExp = RegExp(r'(' + searchStringForSource + r')' + r'(.*)');

      //this is the first one only
      if (menuItemsToTransliterateAsString == '') {
        menuItemsToTransliterateAsString = item.contents;
      } else {
        menuItemsToTransliterateAsString =
            '$menuItemsToTransliterateAsString$carriage${item.contents}';
      }
    }

    return menuItemsToTransliterateAsString;
  }

  @override
  void initState() {
    stringInit = getStringsToTranslate();
    super.initState();
  }

  @override
  void dispose() {
    sourceController.dispose();
    destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int minLines = 50;
    return FutureBuilder(
        future: stringInit,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                //copy to clipboard
                                Clipboard.setData(
                                  ClipboardData(
                                    text: snapshot.data!,
                                  ),
                                );
                                setState(() {
                                  hoveringIcon = const Icon(Icons.check);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Contents copied')));
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
                                  TextFormField(
                                    enabled: false,
                                    // readOnly: true,
                                    minLines: minLines,
                                    maxLines: minLines,
                                    textCapitalization: TextCapitalization.none,
                                    autocorrect: false,
                                    initialValue: snapshot.data,
                                    decoration: const InputDecoration(
                                      filled: true,
                                    ),
                                    // controller: sourceController,
                                    // The validator receives the text that the user has entered.
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter some text';
                                      } else {
                                        return null;
                                      }
                                    },
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
                              onChanged: (value) =>
                                  menuItemsTransliteratedAsString = value,
                              minLines: minLines,
                              maxLines: minLines,
                              textCapitalization: TextCapitalization.none,
                              autocorrect: false,
                              decoration: const InputDecoration(
                                  filled: true,
                                  hintText:
                                      'Copy the menu translations at left and paste the transliterated menus here'),
                              controller: destController,
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
        });
  }
}

class VerifyStrings extends StatefulWidget {
  const VerifyStrings({super.key});

  @override
  State<VerifyStrings> createState() => _VerifyStringsState();
}

class _VerifyStringsState extends State<VerifyStrings> {
  @override
  Widget build(BuildContext context) {
    Widget listItem(String orig, String trans) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              orig,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          Expanded(
            child: Text(
              trans,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      );
    }

    menuItemsTransliteratedAsList = menuItemsTransliteratedAsString.split('\n');

    if (menuItemsToTransliterate.length ==
        menuItemsTransliteratedAsList.length) {
      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: menuItemsToTransliterate.length,
        itemBuilder: (context, index) {
          return listItem(menuItemsToTransliterate[index].contents,
              menuItemsTransliteratedAsList[index]);
        },
      );
    } else {
      return const Center(
        child: Text('something went wrong'),
      );
    }
  }
}

class VerifyTransliteration extends StatelessWidget {
  const VerifyTransliteration({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
