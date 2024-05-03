import 'package:flutter/material.dart';
import 'dart:collection';

import 'file_contents.dart';

class Logic extends ChangeNotifier {
//These are variables we'll use in all pages
  List<String> fileAsList = [];
  List<FileContents> originalFileContents = [];
  Set languages = {};
  Set languagesActive = {};
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

  setSource(String incomingSource) {
    source = incomingSource;
    notifyListeners();
  }

  setDest(String incomingDest, bool isNewLanguage) {
    dest = incomingDest;
    newLanguage = isNewLanguage;
    notifyListeners();
  }

  setReplaceExistingTransliterations(bool bool) {
    replaceExistingTransliterations = bool;
    notifyListeners();
  }

  setMenuItemsTransliteratedAsString(String incoming) {
    menuItemsTransliteratedAsString = incoming;
  }

  //

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

  readInData<bool>(BuildContext context, String fileAsString) {
    //in case we're doing multiple files, reset all data if dropping a new file in

    resetData();
    textFile = fileAsString;

    //TODO check if the file is giving the right kind of content before returning true
    //if (right kind of content) {do what's here} else {Are you sure?}
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
    return true;
  }

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

  chooseActiveLanguages(
      String sourceControllerText, String destControllerText) {
    languagesActive = languages;
    languagesActive.removeWhere((element) =>
        element == sourceControllerText || element == destControllerText);
  }

  addNewLanguage(String newLang) {
    newLanguage = true;
    dest = newLang;
    notifyListeners();
  }

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

  splitMenuItemsString() {
    menuItemsTransliteratedAsList = menuItemsTransliteratedAsString.split('\n');
  }

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
}
