import 'package:flutter/material.dart';
import 'dart:core';
import 'package:provider/provider.dart';
import '../providers/logic.dart';

class VerifyStrings extends StatefulWidget {
  const VerifyStrings({super.key});

  @override
  State<VerifyStrings> createState() => _VerifyStringsState();
}

class _VerifyStringsState extends State<VerifyStrings> {
  @override
  Widget build(BuildContext context) {
    Logic logic = Provider.of<Logic>(context, listen: false);

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

    bool equalNumber = logic.listTransliterations.length ==
        logic.listTransliterationStrings.length;

    if (equalNumber) {
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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: logic.listTransliterations.length,
                  itemBuilder: (context, index) {
                    return listItem(
                        logic.listTransliterations[index].translation,
                        // we already checked there are the
                        logic.listTransliterationStrings[index]);
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
