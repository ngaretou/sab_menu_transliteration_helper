import 'dart:core';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:collection';

import '../providers/file_contents.dart';
import '../providers/nav_controller.dart';

Color pageBackgroundColor = Colors.transparent;

//These are variables we'll use in all pages
List<String> fileAsList = [];
List<FileContents> originalFileContents = [];
List<FileContents> menuItemsToTransliterate = [];
String menuItemsToTransliterateAsString = '';
String menuItemsTransliteratedAsString = '';
List<String> menuItemsTransliteratedAsList = [];
List<String> menuItems = []; //the section headers
String textFile = ''; //The whole text file
String source = ''; //The source lang code
String dest = ''; //destination lang code
bool newLanguage = false; //if this is a user-entered new language code
bool replaceExistingTransliterations = false;

//Page 1
class LoadTranslations extends StatefulWidget {
  final VoidCallback pageForward;
  const LoadTranslations({super.key, required this.pageForward});

  @override
  State<LoadTranslations> createState() => _LoadTranslationsState();
}

class _LoadTranslationsState extends State<LoadTranslations> {
  bool acceptDrop = true;

  resetData() {
    fileAsList = [];
    originalFileContents = [];
    menuItemsToTransliterate = [];
    menuItemsToTransliterateAsString = '';
    menuItemsTransliteratedAsString = '';
    menuItemsTransliteratedAsList = [];
    menuItems = []; //the section headers
    textFile = ''; //The whole text file
    source = ''; //The source lang code
    dest = ''; //destination lang code
    replaceExistingTransliterations = false;
  }

  @override
  Widget build(BuildContext context) {
    NavController navButtons =
        Provider.of<NavController>(context, listen: false);
    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: false);
    print('page 1 build');
    //This is for the nav buttons
    Provider.of<PageTracker>(context, listen: true).addListener(() {
      print('listener in page 1');

      if (pageTracker.currentPage == 0) {
        if (fileAsList.isNotEmpty) {
          navButtons.setEnabledAndNotify(true);
        } else {
          navButtons.setEnabledAndNotify(false);
        }
      }
    });

    readInData(String fileAsString) {
      //in case we're doing multiple files, reset all data if dropping a new file in
      resetData();
      textFile = fileAsString;
      fileAsList = fileAsString.split('\n');

      //Brief check mark feedback for user
      showDialog(
          barrierDismissible: true,
          context: context,
          builder: (BuildContext context) {
            Future.delayed(
                Durations.extralong2, () => Navigator.of(context).pop());

            return Center(
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    height: 80,
                    width: 128,
                    child: const Icon(Icons.check)));
          });
      Future.delayed(Durations.long1, () => widget.pageForward());
    }

    return Container(
      color: pageBackgroundColor,
      child: DropRegion(
          // Formats this region can accept.
          formats: const [Formats.plainTextFile],
          hitTestBehavior: HitTestBehavior.opaque,
          onDropOver: (event) {
            print('ondropover');
            // // You can inspect local data here, as well as formats of each item.
            // // However on certain platforms (mobile / web) the actual data is
            // // only available when the drop is accepted (onPerformDrop).

            // This drop region only supports copy operation.
            if (event.session.allowedOperations.contains(DropOperation.copy)) {
              return DropOperation.copy;
            } else {
              return DropOperation.none;
            }
          },
          onDropEnter: (event) {
            final item = event.session.items.first;
            // if (item.localData is Map) {
            //   // This is a drag within the app and has custom local data set.
            // }
            if (item.canProvide(Formats.plainText)) {
              // this item contains plain text.
              debugPrint('yes to plain text in dropover from onDropEnter');
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
          },
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
                    readInData(value);
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
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles();

                        if (result != null) {
                          PlatformFile file = result.files.first;

                          if (file.bytes != null) {
                            // Decode the bytes into a string
                            final fileContent =
                                utf8.decode((file.bytes)!.toList()).toString();
                            readInData(fileContent);
                          } else {
                            print('No data found');
                          }
                        } else {
                          // User canceled the picker
                        }
                      },
                      icon: const Icon(Icons.file_open),
                      label: const Text('Choose file')),
                  // const SizedBox(
                  //   width: 20,
                  // ),
                  // FilledButton.icon(
                  //     onPressed: () {},
                  //     icon: const Icon(Icons.paste),
                  //     label: const Text('Paste contents')),
                  // const SizedBox(
                  //   width: 20,
                  // ),
                  // FilledButton.icon(
                  //     onPressed: () {},
                  //     icon: const Icon(Icons.question_mark),
                  //     label: const Text('Test')),
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

  Future parseStringFile() async {
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
    langinit = parseStringFile();
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
    print('page 2 biuld');
    NavController navButtons =
        Provider.of<NavController>(context, listen: false);
    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: false);

    checkForNavEnabling() {
      if (pageTracker.currentPage == 1) {
        if (source != '' && dest != '') {
          navButtons.setEnabledAndNotify(true);
        } else {
          navButtons.setEnabledAndNotify(false);
        }
      }
    }

    //This is for the nav buttons
    Provider.of<PageTracker>(context, listen: true).addListener(() {
      print('listener in page 2');
      checkForNavEnabling();
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   print('callback in page two');
    //   NavController navButtons =
    //       Provider.of<NavController>(context, listen: false);
    //   PageTracker pageTracker =
    //       Provider.of<PageTracker>(context, listen: false);
    //   if (pageTracker.currentPage == 1) {
    //     if (source != '' && dest != '') {
    //       navButtons.setEnabledAndNotify(true);
    //     } else {
    //       navButtons.setEnabledAndNotify(false);
    //     }
    //   }
    // });

    return FutureBuilder(
        future: langinit,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            print('building under FutureBuilder page 2');
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
                        initialSelection: source,
                        dropdownMenuEntries: dropdownMenuEntries(),
                        onSelected: (value) {
                          setState(() {
                            source = value!;
                          });
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
                        initialSelection: dest,
                        dropdownMenuEntries: dropdownMenuEntries(),
                        onSelected: (value) {
                          setState(() {
                            newLanguage = false;
                            dest = value!;
                          });

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
                                      setState(() {
                                        newLanguage = true;
                                        destController.text =
                                            newLangController.text;
                                        dest = newLangController.text;
                                        newLangController.text = '';
                                      });
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
              ),
            );
          }
        });
  }
}

//Page 3
class GetStrings extends StatefulWidget {
  const GetStrings({super.key});

  @override
  State<GetStrings> createState() => _GetStringsState();
}

class _GetStringsState extends State<GetStrings> {
  late Future stringInit;
  bool showCopyHelper = false;
  Icon hoveringIcon = const Icon(Icons.copy);

  Future getStringsToTranslate() async {
    if (menuItemsToTransliterate.isEmpty) {
      //Two cases - one where we're redoing all the transliterations, one where we're leaving the ones that are done already.
      if (replaceExistingTransliterations || newLanguage) {
        //If we're replacing all, go ahead and get rid of the old ones in the main list.
        originalFileContents.removeWhere((element) => element.langCode == dest);

        //And add all the source menuitems.
        menuItemsToTransliterate.addAll(originalFileContents
            .where((element) => element.langCode == source));
      } else {
        //If we're just transliterating the ones where there is no current transliteration....
        //first grab the menuitems section by section
        for (String menuItem in menuItems) {
          List<FileContents> currentSection = originalFileContents
              .where((element) => element.section == menuItem)
              .toList();

          //Does it have the source lang code?
          bool containsSource = currentSection
              .any((element) => element.langCode!.contains(source));

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
    }
  }

  @override
  void initState() {
    stringInit = getStringsToTranslate();
    super.initState();
  }

  //page 2

  @override
  Widget build(BuildContext context) {
    NavController navButtons =
        Provider.of<NavController>(context, listen: false);
    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: false);
    //This is for the nav buttons
    checkEnabling() {
      if (pageTracker.currentPage == 2) {
        if (menuItemsTransliteratedAsString != '') {
          navButtons.setEnabledAndNotify(true);
        } else {
          navButtons.setEnabledAndNotify(false);
        }
      }
    }

    Provider.of<PageTracker>(context, listen: true).addListener(() {
      print('listener in page 3');
      checkEnabling();
    });

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
                                    text: menuItemsToTransliterateAsString,
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
                                  TextFormField(
                                    enabled: false,
                                    // readOnly: true,
                                    minLines: minLines,
                                    maxLines: minLines,
                                    textCapitalization: TextCapitalization.none,
                                    autocorrect: false,
                                    initialValue: menuItemsToTransliterateAsString
                                            .isNotEmpty
                                        ? menuItemsToTransliterateAsString
                                        : "No menu translations to translitarate.\n\nUsually this is because there are no untransliterated strings and you haven't checked the 'replace existing transliterations' option. ",
                                    decoration: const InputDecoration(
                                      filled: true,
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
                              onChanged: (value) {
                                menuItemsTransliteratedAsString = value;
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
                              initialValue: menuItemsTransliteratedAsString,
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

//Page 4
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
      return Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          const Text(
              'Check out the results to make sure they are lining up correctly: '),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 10.0,
                left: 10,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.only(topLeft: Radius.circular(10)),
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: menuItemsToTransliterate.length,
                  itemBuilder: (context, index) {
                    return listItem(menuItemsToTransliterate[index].contents,
                        menuItemsTransliteratedAsList[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return const Center(
        child: Text(
            'something went wrong - go back and try again and make sure no extra lines get into the text'),
      );
    }
  }
}

class CreateNewFile extends StatefulWidget {
  const CreateNewFile({super.key});

  @override
  State<CreateNewFile> createState() => _CreateNewFileState();
}

class _CreateNewFileState extends State<CreateNewFile> {
  late Future initFile;
  Future<String> createNewFile() async {
    Future<List<FileContents>> transliterationsToBigList() async {
      List<FileContents> newFileContents = [];
      int num = menuItemsToTransliterate.length;
      newFileContents.addAll(originalFileContents);

      //put the transliterated menuItems in the big list
      for (var i = 0; i < num; i++) {
        int targetIndex = newFileContents.indexWhere(
            (element) => element.key == menuItemsToTransliterate[i].key);

        FileContents newEntry = FileContents(
            key: UniqueKey(),
            langCode: dest,
            contents: menuItemsTransliteratedAsList[i],
            section: menuItemsToTransliterate[i].section);

        newFileContents.insert(targetIndex + 1, newEntry);
      }
      return newFileContents;
    }

    Future<String> convertListToString(List<FileContents> input) async {
      String listContentsAsString = '';
      //Convert the big list to a string
      for (FileContents item in input) {
        String carriage = '\n';
        //this is the first one only
        if (listContentsAsString == '') {
          listContentsAsString = item.contents;
        } else {
          String line = '';

          if (item.langCode == null) {
            line = item.contents;
          } else {
            {
              line = '${item.langCode!}: ${item.contents}';
            }
          }

          listContentsAsString = '$listContentsAsString$carriage$line';
        }
      }

      return listContentsAsString;
    }

    return await convertListToString(await transliterationsToBigList());
  }

  @override
  void initState() {
    initFile = createNewFile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: initFile,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                    onPressed: () async {
                      //filename
                      final DateTime now = DateTime.now();
                      final String formattedDate = formatDate(now);
                      final String filename =
                          'exported SAB menu $formattedDate';

                      //data
                      final List<int> utf8Bytes =
                          utf8.encode(snapshot.data.toString()).toList();
                      final Uint8List utf8list = Uint8List.fromList(utf8Bytes);

                      await FileSaver.instance.saveFile(
                          name: filename,
                          ext: 'txt',
                          bytes: utf8list,
                          mimeType: MimeType.text);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Download new file")),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                    'Now download the new transliteration file and import it into SAB.'),
              ],
            );
          }
        });
  }
}

String formatDate(DateTime date) {
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');
  final String year = date.year.toString();
  return '$month $day $year';
}
