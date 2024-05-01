import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import '../providers/nav_controller.dart';

class HelpPane extends StatefulWidget {
  const HelpPane({super.key});

  @override
  State<HelpPane> createState() => _HelpPaneState();
}

class _HelpPaneState extends State<HelpPane> {
  Color draggablePaneColor = Colors.transparent;
  double helpPaneWidth = 365;

  @override
  Widget build(BuildContext context) {
    final infoPaneBackgroundColor =
        Theme.of(context).colorScheme.surfaceVariant;

    List<Widget> activeWidgets =
        Provider.of<HelpPaneController>(context, listen: true).activeWidgets;

    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //Grabber handle
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onTapDown: (_) {
                setState(() {
                  draggablePaneColor =
                      Theme.of(context).colorScheme.inversePrimary;
                });
              },
              onTapUp: (_) {
                setState(() {
                  draggablePaneColor = Colors.transparent;
                  // draggablePaneColor = infoPaneBackgroundColor;
                });
              },
              onTapCancel: () {
                setState(() {
                  draggablePaneColor = Colors.transparent;
                  // draggablePaneColor = infoPaneBackgroundColor;
                });
              },
              onHorizontalDragStart: (details) => setState(() {
                draggablePaneColor =
                    Theme.of(context).colorScheme.inversePrimary;
              }),
              onHorizontalDragEnd: (details) => setState(() {
                draggablePaneColor = Colors.transparent;
                // draggablePaneColor = infoPaneBackgroundColor;
              }),
              onHorizontalDragUpdate: (details) {
                if (300 < helpPaneWidth - details.delta.dx &&
                    helpPaneWidth - details.delta.dx < 850) {
                  setState(() {
                    helpPaneWidth = helpPaneWidth - details.delta.dx;
                  });
                }
              },
              child: Container(
                  color: draggablePaneColor,
                  width: activeWidgets.isEmpty ? 0 : 5,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.0),
                        color: Theme.of(context).colorScheme.inverseSurface,
                      ),
                      width: 2,
                      height: 24,
                    ),
                  )),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: activeWidgets.isEmpty
                  ? const EdgeInsets.all(0)
                  : const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 0),

              // version with all corners round and indented a bit
              // const EdgeInsets.only(
              // left: 0, right: 10, top: 10, bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                    // borderRadius: BorderRadius.circular(10),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0), //10 for curved
                      bottomLeft: Radius.circular(0),
                    ),
                    color: infoPaneBackgroundColor
                    // color: Colors.grey
                    ),
                //round corners all round
                // decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(10),
                //     color:
                //         Theme.of(context).colorScheme.surfaceVariant
                //     // color: Colors.grey
                //     ),
                width: activeWidgets.isEmpty ? 0 : helpPaneWidth,
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: activeWidgets,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpText extends StatelessWidget {
  const HelpText({super.key});

  @override
  Widget build(BuildContext context) {
    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: true);

    Widget htmlSection(Key key, String url) {
      //This is where we grab the HTML from the asset folder
      Future<String?> fetchHtmlSection(String url) async {
        String htmlSection =
            await DefaultAssetBundle.of(context).loadString(url);
        return htmlSection;
      }

      return FutureBuilder(
        future: fetchHtmlSection(url),
        builder: (ctx, snapshot) => snapshot.connectionState ==
                ConnectionState.waiting
            ? const Center(child: CircularProgressIndicator())
            //this is actually where the business happens; HTML just takes the data and renders it

            : html.Html(
                data: snapshot.data.toString(),
                onLinkTap: (String? url, Map<String, String> attributes,
                    element) async {
                  if (url != null) {
                    await canLaunchUrl(Uri.parse(url))
                        ? await launchUrl(Uri.parse(url))
                        : throw 'Could not launch $url';
                  }
                }),
      );
    }

    // return Text('help');

    return SingleChildScrollView(
      child: AnimatedSwitcher(
          duration: Durations.extralong4,
          child: htmlSection(
              UniqueKey(), "assets/html/${pageTracker.currentPage}.html")),
    );
  }
}
