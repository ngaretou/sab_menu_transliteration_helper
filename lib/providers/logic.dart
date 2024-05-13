import 'package:flutter/material.dart';
import 'dart:core';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:collection';

import 'package:file_saver/file_saver.dart';
import 'package:xml/xml.dart';

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
  XmlDocument appDef =
      XmlDocument.parse('<?xml version="1.0" encoding="UTF-8"?><root></root>');
  Set languages = {};
  Set languagesActive = {};
  List<Transliteration> listTransliterations = [];
  String menuItemsToTransliterateAsString = '';

  List<String> listTransliterationStrings =
      []; // simple list of bare transliterations
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

  checkAndReadFile<bool>(
      BuildContext context, String fileName, Uint8List fileAsBytes) {
    //in case we're doing multiple files, reset all data if dropping a new file in

    // reset all data if dropping a new file in
    originalFileName = '';
    appDef = XmlDocument.parse(
        '<?xml version="1.0" encoding="UTF-8"?><root></root>');
    listTransliterations = [];
    source = ''; //The source lang code
    dest = ''; //destination lang code
    replaceExistingTransliterations = false;

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
      appDef = XmlDocument.parse(fileAsString);

      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unsupported File Type - import a SAB appDef file')));
      return false;
    }
  }

  Future parseXMLLangs() async {
    List<String> langCodesList = [];

    Iterable<XmlElement> xmlLangs = appDef
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
    languagesActive = languages;
    languagesActive.removeWhere((element) =>
        element == sourceControllerText || element == destControllerText);
  }

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
    // Two cases - one where we're redoing all the transliterations,
    // one where we're leaving the translations that are done already.
    // if we do not want to replace any existing translations,
    // then get the ones that already contain dest

    if (!replaceExistingTransliterations) {
      xmlSourceTranslations = appDef
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
      xmlSourceTranslations = appDef
          .findAllElements('translation')
          .where((element) =>
              (element.getAttribute('lang') == source) &&
              element.innerText != '')
          .toList();
    }

    for (XmlElement translation in xmlSourceTranslations) {
      Key key = UniqueKey();
      /*
    Now get those XmlElements into the main working list. This will leave the whole
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

      // And leave those bookmarks; this will look like
      // <translation lang="(dest)">(the unique key)</translation>
      // so later on all we have to do is look for that key when adding in the transliterations

      if (translation.siblings
          .any((element) => element.getAttribute('lang') == dest)) {
        try {
          final target = translation.siblings
              .firstWhere((element) => element.getAttribute('lang') == dest);
          target.innerText = key.toString();
        } catch (e) {
          debugPrint(e.toString());
        }
      } else {
        final builder = XmlBuilder();
        builder.element('translation', nest: () {
          builder.attribute('lang', dest);
          builder.text(key.toString());
        });
        translation.siblings.add(builder.buildFragment());
      }
    }
  }

  updateTransliterationStrings(String incoming) {
    listTransliterationStrings = incoming.split('\n');
  }

  Future<String> createNewFile() async {
    String fileContents = appDef.toXmlString(pretty: true);

    // for (var i = 0; i < listTransliterations.length; i++) {
    List<String> listOfTransliterations = listTransliterations
        .map((transliteration) => transliteration.key.toString())
        .toList();

    Map<String, String> map =
        Map.fromIterables(listOfTransliterations, listTransliterationStrings);

    String result = map.entries
        .fold(fileContents, (prev, e) => prev.replaceAll(e.key, e.value));

    return result;
  }

  Future saveFile(BuildContext context, String fileContents) async {
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

  String formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$month $day $year';
  }
}
