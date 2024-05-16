import 'package:flutter/material.dart';
import 'package:sab_menu_transliteration_helper/pages/a_load_translations.dart';
import 'package:sab_menu_transliteration_helper/pages/b_choose_languages.dart';
import 'package:sab_menu_transliteration_helper/pages/c_get_strings.dart';
import 'package:sab_menu_transliteration_helper/pages/d_verify_strings.dart%20.dart';
import 'package:sab_menu_transliteration_helper/pages/e_create_new_file.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/nav_controller.dart';

// Main body view, mainly a pageview builder
class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  PageController pageController = PageController();
  int? currentIndex;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool enabled = true;

    pageForwardNoCheck() {
      int index = (pageController.page!).toInt();

      pageController.animateToPage(index + 1,
          duration: Durations.medium4, curve: Curves.decelerate);
    }

    List<Widget> pages = [
      LoadTranslations(
        pageForward: () => pageForwardNoCheck(),
      ),
      const ChooseLanguages(),
      const GetStrings(),
      const VerifyStrings(),
      const CreateNewFile()
    ];

    // programmatic page forward & back
    pageForward() {
      int index = (pageController.page!).toInt();
      // make sure we can move forward without error.
      if (pages.length > index + 1) {
        pageController.animateToPage(index + 1,
            duration: Durations.medium4, curve: Curves.decelerate);
      } else {
        // if we're at the end, scroll back to one.
        // This eventually got superseded by hiding the right arrow button on last page.
        pageController.animateToPage(0,
            duration: Durations.medium4, curve: Curves.decelerate);
      }
    }

    pageBack() {
      currentIndex = (pageController.page!).toInt();

      pageController.animateToPage(currentIndex! - 1,
          duration: Durations.medium4, curve: Curves.decelerate);
    }

    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: false);

    return Expanded(
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          // bottomLeft: Radius.circular(10),
        ),
        child: Container(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(.3),
          child: Column(
            children: [
              // In the column, first the pageview builder itself, taking up all the space it can
              Expanded(
                child: PageView.builder(
                  onPageChanged: (value) => pageTracker.setPage(value),
                  physics: const NeverScrollableScrollPhysics(),
                  controller: pageController,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return pages[index];
                  },
                ),
              ),
              // Then a fixed-height container containing the page view control row
              Container(
                height: 70,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(.5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // left arrow button
                      Consumer<PageTracker>(builder: (context, value, child) {
                        if (value.currentPage == 0) {
                          return const SizedBox(
                            width: 20,
                          );
                        } else {
                          return IconButton.filled(
                              onPressed: pageBack,
                              icon: const Icon(Icons.arrow_back));
                        }
                      }),
                      // page number indicator
                      SmoothPageIndicator(
                          controller: pageController, // PageController
                          count: pages.length,
                          effect: const WormEffect(), // your preferred effect
                          onDotClicked: (index) {
                            if (enabled) {
                              pageController.animateToPage(index,
                                  duration: Durations.medium4,
                                  curve: Curves.decelerate);
                            }
                          }),
                      // right arrow button
                      Consumer<NavController>(builder: (context, nav, child) {
                        final value = nav;
                        return Consumer<PageTracker>(
                            builder: (context, page, child) {
                          // if we're on page one (index 0) don't show it
                          if (page.currentPage == pages.length - 1) {
                            return const SizedBox(
                              width: 20,
                            );
                          } else {
                            return IconButton.filled(
                                onPressed:
                                    value.enabled ? () => pageForward() : null,
                                icon: const Icon(Icons.arrow_forward));
                          }
                        });
                      }),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
