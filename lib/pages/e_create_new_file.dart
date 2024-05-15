import 'package:flutter/material.dart';
import 'dart:core';
import 'package:provider/provider.dart';
import '../providers/logic.dart';

class CreateNewFile extends StatefulWidget {
  const CreateNewFile({super.key});

  @override
  State<CreateNewFile> createState() => _CreateNewFileState();
}

class _CreateNewFileState extends State<CreateNewFile> {
  late Future<String> init;

  @override
  void initState() {
    init = Provider.of<Logic>(context, listen: false).createNewFile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Logic logic = Provider.of<Logic>(context, listen: false);

    return FutureBuilder(
        future: init,
        builder: (ctx, snapshot) =>
            snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Now download the new appDef file.\n'),
                      RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(children: [
                            TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium!,
                              text:
                                  'Move the new file to your project folder. \nRename your old appDef file ',
                            ),
                            TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(fontStyle: FontStyle.italic),
                              text: '"{yourprojectname}.appDef.old"\n',
                            ),
                            TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium!,
                              text: 'and rename the new file ',
                            ),
                            TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(fontStyle: FontStyle.italic),
                              text: '"{yourprojectname}.appDef".',
                            ),
                          ])),
                      const SizedBox(
                        height: 20,
                      ),
                      FilledButton.icon(
                          onPressed: () async {
                            logic.saveFile(context, snapshot.data!);
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Download new file")),
                      const SizedBox(
                        height: 20,
                      ),
                    ],
                  ));
  }
}
