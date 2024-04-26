import 'dart:core';
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'dart:collection';

Color pageBackgroundColor = Colors.transparent;
List<String> translationAsList = [];
String source = '';
String dest = '';

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
                    translationAsList = value.split('\n');
                    //Feedback
                    showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          Future.delayed(Durations.extralong4,
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
  // String source = '';
  // String dest = '';
  TextEditingController newLangController = TextEditingController();
  TextEditingController sourceController = TextEditingController();
  TextEditingController destController = TextEditingController();

  @override
  void dispose() {
    newLangController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<SplayTreeSet<String>> languages() async {
      List<String> langCodesList = [];

      for (String line in translationAsList) {
        RegExpMatch? match = RegExp(r'(^)(\w+)(: )(.*)').firstMatch(line); // \s
        if (match != null) {
          if (match.group(2) != null) {
            langCodesList.add(match.group(2)!);
          }
        }
      }

      //get to unique values
      Set<String> langCodesSet = langCodesList.toSet();
      final sortedSet = SplayTreeSet<String>.from(langCodesSet);

      return sortedSet;
    }

    return FutureBuilder(
        future: languages(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            Set languages = {};
            if (snapshot.data != null) {
              languages = snapshot.data!.toSet();
            }

            List<DropdownMenuEntry<String>> dropdownMenuEntries() {
              List<DropdownMenuEntry<String>> entries = [];
              for (String language in languages) {
                DropdownMenuEntry<String> entry =
                    DropdownMenuEntry(value: language, label: language);
                entries.add(entry);
              }
              return entries;
            }

            bool hasLanguages = languages.isNotEmpty;

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
                      onSelected: (value) => source = value!,
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
                      onSelected: (value) => dest = value!,
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
                )
              ],
            );
          }
        });
  }
}

class GetStrings extends StatelessWidget {
  const GetStrings({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('please convert $source to $dest'));
  }
}

class PasteStrings extends StatefulWidget {
  const PasteStrings({super.key});

  @override
  State<PasteStrings> createState() => _PasteStringsState();
}

class _PasteStringsState extends State<PasteStrings> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class VerifyTransliteration extends StatelessWidget {
  const VerifyTransliteration({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
