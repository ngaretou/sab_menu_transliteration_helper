import 'package:flutter/foundation.dart';

class FileContents {
  Key key;
  String? langCode;
  String contents;
  String section;

  FileContents({
    required this.key,
    this.langCode,
    required this.contents,
    required this.section,
  });
}
