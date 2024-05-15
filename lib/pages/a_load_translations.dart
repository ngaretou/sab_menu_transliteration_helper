import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:core';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../providers/nav_controller.dart';
import '../providers/logic.dart';

class LoadTranslations extends StatefulWidget {
  final VoidCallback pageForward;
  const LoadTranslations({super.key, required this.pageForward});

  @override
  State<LoadTranslations> createState() => _LoadTranslationsState();
}

class _LoadTranslationsState extends State<LoadTranslations> {
  Color pageBackgroundColor = Colors.transparent;
  bool acceptDrop = true;

  @override
  Widget build(BuildContext context) {
    Logic logic = Provider.of<Logic>(context, listen: false);

    NavController navButtons =
        Provider.of<NavController>(context, listen: false);
    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: false);

    //This is for the nav buttons
    Provider.of<PageTracker>(context, listen: true).addListener(() {
      if (pageTracker.currentPage == 0) {
        if (logic.origAppDef.rootElement.children.isNotEmpty) {
          navButtons.setEnabledAndNotify(true);
        } else {
          navButtons.setEnabledAndNotify(false);
        }
      }
    });

    late DropzoneViewController controller;

    return Container(
      color: pageBackgroundColor,
      child: Stack(
        children: [
          DropzoneView(
            operation: DragOperation.copy,
            onCreated: (DropzoneViewController ctrl) => controller = ctrl,
            onError: (String? ev) => debugPrint('Error: $ev'),
            onHover: () {
              setState(() {
                pageBackgroundColor =
                    Theme.of(context).colorScheme.primaryContainer;
              });
            },
            onDrop: (dynamic ev) async {
              final Uint8List fileData = await controller.getFileData(ev);
              final String fileName = await controller.getFilename(ev);
              if (!context.mounted) return;
              bool goAhead =
                  logic.checkAndReadFile(context, fileName, fileData);
              if (goAhead) {
                Future.delayed(Durations.long1, () => widget.pageForward());
              }

              setState(() {
                pageBackgroundColor = Colors.transparent;
              });
            },
            onLeave: () => setState(() {
              pageBackgroundColor = Colors.transparent;
            }),
          ),
          Column(
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
                    'After closing SAB, drag and drop the appDef of your SAB project or click below to choose the file.'),
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
                            final Uint8List fileData = file.bytes!;
                            final String fileName = file.name;
                            if (!context.mounted) return;
                            logic.checkAndReadFile(context, fileName, fileData);
                          } else {
                            debugPrint('No data found');
                          }
                        } else {
                          // User canceled the picker
                        }
                      },
                      icon: const Icon(Icons.file_open),
                      label: const Text('Choose file')),
                  //
                  // const SizedBox(
                  //   width: 20,
                  // ),
                  // FilledButton.icon(
                  //     onPressed: () =>
                  //         logic.insertTranslationToAppDef('Corey', 'Katie'),
                  //     icon: const Icon(Icons.paste),
                  //     label: const Text('Insert element')),
                  // const SizedBox(
                  //   width: 20,
                  // ),
                  // FilledButton.icon(
                  //     onPressed: () => logic.changeAppDef(),
                  //     icon: const Icon(Icons.question_mark),
                  //     label: const Text('Change element')),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
