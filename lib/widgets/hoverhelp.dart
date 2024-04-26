import 'package:flutter/material.dart';

class HoverHelp extends StatelessWidget {
  final String text;
  const HoverHelp({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: text, child: const Icon(Icons.help));
  }
}
