import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:provider/provider.dart';
import '../providers/nav_controller.dart';

import 'pages.dart';

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
    print('Body build');

    // bool enabled = Provider.of<NavController>(context, listen: false).enabled;
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
    pageForward() {
      int index = (pageController.page!).toInt();
      if (pages.length > index + 1) {
        pageController.animateToPage(index + 1,
            duration: Durations.medium4, curve: Curves.decelerate);
      } else {
        pageController.animateToPage(0,
            duration: Durations.medium4, curve: Curves.decelerate);
      }
    }

    pageBack() {
      currentIndex = (pageController.page!).toInt();

      pageController.animateToPage(currentIndex! - 1,
          duration: Durations.medium4, curve: Curves.decelerate);
    }

    // programmaticPageForward() {
    //   currentIndex = (pageController.page!).toInt();
    //   pageController.animateToPage(currentIndex! + 1,
    //       duration: Durations.medium4, curve: Curves.decelerate);
    // }

    PageTracker pageTracker = Provider.of<PageTracker>(context, listen: false);

    return Expanded(
      child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(10),
            // bottomLeft: Radius.circular(10),
          ),
          child: Container(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(.3),
              child: Column(
                children: [
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
                          IconButton.filled(
                              onPressed: pageBack,
                              icon: const Icon(Icons.arrow_back)),
                          SmoothPageIndicator(
                              controller: pageController, // PageController
                              count: pages.length,
                              effect:
                                  const WormEffect(), // your preferred effect
                              onDotClicked: (index) {
                                if (enabled) {
                                  pageController.animateToPage(index,
                                      duration: Durations.medium4,
                                      curve: Curves.decelerate);
                                }
                              }),
                          Consumer<NavController>(
                              builder: (context, value, child) {
                            return IconButton.filled(
                                onPressed:
                                    value.enabled ? () => pageForward() : null,
                                icon: const Icon(Icons.arrow_forward));
                          }),
                        ],
                      ),
                    ),
                  )
                ],
              ))),
    );
  }
}
