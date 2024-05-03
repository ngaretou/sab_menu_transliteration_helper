import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
// import 'package:feedback/feedback.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart';
import '../theme.dart';
import '../widgets/help_pane.dart';
import '../providers/nav_controller.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
        // padding: EdgeInsets.all(20),
        width: 250,
        color: Theme.of(context).colorScheme.surface,
        child: Column(children: [
          const Expanded(
              child: SizedBox(
            height: 20,
          )),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            trailing: Switch(
                value: Theme.of(context).brightness == Brightness.dark
                    ? true
                    : false,
                onChanged: (bool newValue) {
                  final brightness = Theme.of(context).brightness;
                  ThemeProvider themeProvider =
                      Provider.of<ThemeProvider>(context, listen: false);
                  if (brightness == Brightness.dark) {
                    userPrefsBox.put('theme', 'light');
                    themeProvider.setTheme(ThemeData.light());
                  } else {
                    userPrefsBox.put('theme', 'dark');
                    themeProvider.setTheme(ThemeData.dark());
                  }
                }),
          ),
          const Divider(),
          ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help'),
              onTap: () {
                HelpPaneController helpPane =
                    Provider.of<HelpPaneController>(context, listen: false);
                if (helpPane.activeWidgets.isEmpty) {
                  helpPane.setActiveWidget(context, [const HelpText()]);
                } else {
                  helpPane.closeHelpPane();
                }
              }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () => showAbout(context),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            onTap: () async {
              const url =
                  'https://github.com/ngaretou/sab_menu_transliteration_helper';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.platformDefault);
              } else {
                throw 'Could not launch $url';
              }
            },
          ),
          const SizedBox(
            height: 20,
          )
        ]));
  }
}

void showAbout(BuildContext context) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: Text(packageInfo.appName),
          content: SingleChildScrollView(
              child: ListBody(children: [
            Row(
              children: [
                Container(
                  // child: Image.asset('assets/icons/icon.png'),
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/icons/icon.png"),
                    ),
                    // color: Colors.transparent,
                    // borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        'SAB menu helper',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                        'Version ${packageInfo.version} (${packageInfo.buildNumber})'),
                    const Text('© 2024 Foundational'),
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  const url = 'https://software.sil.org/scriptureappbuilder/';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.platformDefault);
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: RichText(
                    text: TextSpan(
                  children: [
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge,
                      text: 'For more see ',
                    ),
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.primary),
                      text: 'Scripture App Builder',
                    ),
                  ],
                )),
              ),
            ),
          ])),
          actions: <Widget>[
            // OutlinedButton(
            //   child: const Text('Copyrights'),
            //   onPressed: () {
            //     Navigator.of(context).pushNamed(AboutScreen.routeName);
            //   },
            // ),
            OutlinedButton(
              child: const Text('Licenses'),
              onPressed: () {
                // Navigator.of(context).pop();
                showLicenses(context,
                    appName: packageInfo.appName,
                    appVersion:
                        '${packageInfo.version} (${packageInfo.buildNumber})');
              },
            ),
            OutlinedButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      });
}

void showLicenses(BuildContext context, {String? appName, String? appVersion}) {
  void showLicensePage({
    required BuildContext context,
    String? applicationName,
    String? applicationVersion,
    Widget? applicationIcon,
    String? applicationLegalese,
    bool useRootNavigator = false,
  }) {
    // assert(context != null);
    // assert(useRootNavigator != null);
    Navigator.of(context, rootNavigator: useRootNavigator)
        .push(MaterialPageRoute<void>(
      builder: (BuildContext context) => LicensePage(
        applicationName: applicationName,
        applicationVersion: applicationVersion,
        applicationIcon: applicationIcon,
        applicationLegalese: applicationLegalese,
      ),
    ));
  }

  showLicensePage(
      context: context,
      applicationVersion: appVersion,
      applicationName: appName,
      useRootNavigator: true);
}
