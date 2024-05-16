import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:collection';

import 'package:file_saver/file_saver.dart';
import 'package:xml/xml.dart';

// all the logic for dealing with the data
class Transliteration {
  Key key;
  String translation;
  String? transliteration;

  Transliteration({
    required this.key,
    required this.translation,
    this.transliteration,
  });
}

class Logic extends ChangeNotifier {
  //These are variables we'll use in all pages
  String originalFileName = '';
  // make sure you keep the original app def rather than altering it
  // and you have a working copy
  XmlDocument origAppDef =
      XmlDocument.parse('<?xml version="1.0" encoding="UTF-8"?><root></root>');
  XmlDocument workingAppDef =
      XmlDocument.parse('<?xml version="1.0" encoding="UTF-8"?><root></root>');
  // all languages
  Set languages = {};
  // the active ones in the dropdownboxes
  Set languagesActive = {};
  // list of all transliterations
  List<Transliteration> listTransliterations = [];
  // and the list of the menu items to transliterate for display
  String menuItemsToTransliterateAsString = '';
  // and the transliterated items simple list of bare transliterations
  List<String> listTransliterationStrings = [];
  String source = ''; //The source lang code
  String dest = ''; //destination lang code
  bool newLanguage = false; //if this is a user-entered new language code
  // whether we're replacing all or just the ones that are not existant yet
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

  resetListTransliterationStrings() {
    listTransliterationStrings = [];
  }

  setReplaceExistingTransliterations(bool bool) {
    replaceExistingTransliterations = bool;
    notifyListeners();
  }

  // initial load of new appDef file
  checkAndReadFile<bool>(
      BuildContext context, String fileName, Uint8List fileAsBytes) {
    //in case we're doing multiple files in one session, reset all data if dropping a new file in
    originalFileName = '';
    origAppDef = XmlDocument.parse(
        '<?xml version="1.0" encoding="UTF-8"?><root></root>');
    workingAppDef = XmlDocument.parse(
        '<?xml version="1.0" encoding="UTF-8"?><root></root>');
    listTransliterations = [];
    source = ''; //The source lang code
    dest = ''; //destination lang code
    replaceExistingTransliterations = false;
    menuItemsToTransliterateAsString = '';

    // helper function to get the extension
    String getFileExtension(String fileName) {
      if (fileName.contains('.')) {
        String extension = fileName.split('.').last;

        originalFileName =
            fileName.substring(0, fileName.length - extension.length - 1);
        return extension;
      }
      return ''; // Return an empty string if there is no extension
    }

    // if appDef file, continue, but if not, halt.
    final String ext = getFileExtension(fileName);
    if (ext == 'appDef') {
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
      // Get our data ready to go as XML
      String fileAsString = utf8.decode(fileAsBytes);
      origAppDef = XmlDocument.parse(fileAsString);

      return true;
    } else {
      // If the file is not appDef, give user feedback
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unsupported File Type - import a SAB appDef file')));
      return false;
    }
  }

  // get the active languages from the appDef
  Future parseXMLLangs() async {
    List<String> langCodesList = [];

    Iterable<XmlElement> xmlLangs = origAppDef
        .getElement('app-definition')!
        .getElement('interface-languages')!
        .getElement('writing-systems')!
        .findAllElements('writing-system');

    //Loop through langs gathering info about each
    for (var lang in xmlLangs) {
      String? enabled = lang.getAttribute('enabled')?.toString();

      if (enabled != 'false') {
        String langCode = lang.getAttribute('code').toString();
        langCodesList.add(langCode);
      }
    }

    //get langs to unique values
    Set<String> langCodesSet = langCodesList.toSet();
    languages = SplayTreeSet<String>.from(langCodesSet);

    return;
  }

  chooseActiveLanguages(
      String sourceControllerText, String destControllerText) {
    languagesActive = {};
    languagesActive.addAll(languages);
    languagesActive.removeWhere((element) =>
        element == sourceControllerText || element == destControllerText);
  }

  // if there is a new language that the appDef doesn't have in it yet
  addNewLanguage(String newLang) {
    newLanguage = true;
    dest = newLang;
    notifyListeners();
  }

  /* 
  At this point, all we have is the source and dest languages. 
  Make a new list of the Transliteration class that has the data we need 
  and along the way put bookmarks in our in-memory copy of the appDef so we can go back to them later.
  */
  Future initializeTransliterationList() async {
    List<XmlElement> xmlSourceTranslations = [];

    // reset if coming back for another pass after the initial time through
    menuItemsToTransliterateAsString = '';
    listTransliterations = [];
    workingAppDef = XmlDocument.parse(origAppDef.toXmlString());

    // Two cases - one where we're redoing all the transliterations,
    // one where we're leaving the translations that are done already.
    // if we do not want to replace any existing translations,
    // then get the ones that already contain dest

    if (!replaceExistingTransliterations) {
      xmlSourceTranslations = workingAppDef
          .findAllElements('translation')
          .where((element) =>
              // lang is the source
              (element.getAttribute('lang') == source) &&
              // and innertext is not empty
              element.innerText != '' &&
              // all the sibling elements
              (element.siblingElements.every((element) {
                //either 1) don't have the dest lang code
                return (element.getAttribute('lang') != dest ||
                    //or 2) have the lang code but the content is empty
                    element.getAttribute('lang') == dest &&
                        element.innerText == '');
              })))
          .toList();
    } else {
      // if we do want to replace all, just keep going.
      // These are all the XML nodes that have source lang AND are not empty
      xmlSourceTranslations = workingAppDef
          .findAllElements('translation')
          .where((element) =>
              (element.getAttribute('lang') == source) &&
              element.innerText != '')
          .toList();
    }

    // Now deal with the resulting list of XmlElements
    for (XmlElement translation in xmlSourceTranslations) {
      Key key = UniqueKey();
      /*
      First get those XmlElements into the main working list. This will leave the whole
      transliterations 'column' empty. 
      */
      listTransliterations
          .add(Transliteration(key: key, translation: translation.innerText));

      // Also get those transliterations into a displayable String
      String carriage = '\n';

      if (menuItemsToTransliterateAsString == '') {
        menuItemsToTransliterateAsString = translation.innerText;
      } else {
        menuItemsToTransliterateAsString =
            '$menuItemsToTransliterateAsString$carriage${translation.innerText}';
      }

      // And leave those bookmarks that we will come back to; this will look like
      // <translation lang="(dest)">[the unique key]</translation>
      // so later on all we have to do is look for that key when adding in the transliterations

      if (translation.siblings
          .any((element) => element.getAttribute('lang') == dest)) {
        // this is the case where the dest does already exist - just add the
        // key 'bookmark' in the inner text of that tag
        try {
          final target = translation.siblings
              .firstWhere((element) => element.getAttribute('lang') == dest);
          target.innerText = key.toString();
        } catch (e) {
          debugPrint(e.toString());
        }
      } else {
        // of if it doesn't already exist, then add in an xmlnode with the bookmark key
        final builder = XmlBuilder();
        builder.element('translation', nest: () {
          builder.attribute('lang', dest);
          builder.text(key.toString());
        });
        translation.siblings.add(builder.buildFragment());
      }
    }
    return;
  }

  updateTransliterationStrings(String incoming) {
    listTransliterationStrings = incoming.split('\n');
  }

  String listTransliterationsToString() {
    String carriage = '\n';
    String returnme = '';
    for (var transliteration in listTransliterationStrings) {
      if (returnme == '') {
        returnme = transliteration;
      } else {
        returnme = '$returnme$carriage$transliteration';
      }
    }

    return returnme;
  }

  // this gets the tranlisterations into the in-memory copy of the appDef file,
  //
  Future<String> createNewFile() async {
    // get the xmldoc into a simple string for faster manipulation at this point
    String fileContents = workingAppDef.toXmlString(pretty: true);

    // get the keys column from the main list into a list of strings
    List<String> listOfTransliterationKeys = listTransliterations
        .map((transliteration) => transliteration.key.toString())
        .toList();

    // so we can now get keys and transliterations into a map
    Map<String, String> map = Map.fromIterables(
        listOfTransliterationKeys, listTransliterationStrings);

    // This fold command is a bit too compact to understand at first glance
    //but basically takes a Map<String, String> map of keys and values
    //and replaces *key with *value throughout the whole String fileContents
    String result = map.entries
        .fold(fileContents, (prev, e) => prev.replaceAll(e.key, e.value));

    return result;
  }

  Future saveFile(BuildContext context, String fileContents) async {
    // this takes the result of createFile and saves it to a new file
    final DateTime now = DateTime.now();
    final String formattedDate = formatDate(now);
    final String filename = '$originalFileName $formattedDate';

    //data
    final List<int> utf8Bytes = utf8.encode(fileContents).toList();
    final Uint8List utf8list = Uint8List.fromList(utf8Bytes);

    await FileSaver.instance.saveFile(
        name: filename,
        ext: 'appDef',
        bytes: utf8list,
        mimeType: MimeType.text);
  }

  // I just have this here so I don't have to load the whole intl package
  String formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$month $day $year';
  }
}
