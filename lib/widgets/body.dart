import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'pages.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  PageController pageController = PageController();
  int currentIndex = 0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    programmaticPageForward() {
      pageController.animateToPage(currentIndex + 1,
          duration: Durations.medium4, curve: Curves.decelerate);
    }

    List<Widget> pages = [
      LoadTranslations(
        pageForward: programmaticPageForward,
      ),
      const ChooseLanguages(),
      const GetStrings(),
      const VerifyStrings(),
      const VerifyTransliteration()
    ];

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
                      physics: const ClampingScrollPhysics(),
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
                              onPressed: () {
                                int currentIndex =
                                    (pageController.page!).toInt();
                                if (currentIndex != 0) {
                                  pageController.animateToPage(currentIndex - 1,
                                      duration: Durations.medium4,
                                      curve: Curves.decelerate);
                                }
                              },
                              icon: const Icon(Icons.arrow_back)),
                          SmoothPageIndicator(
                              controller: pageController, // PageController
                              count: pages.length,
                              effect:
                                  const WormEffect(), // your preferred effect
                              onDotClicked: (index) {
                                pageController.animateToPage(index,
                                    duration: Durations.medium4,
                                    curve: Curves.decelerate);
                              }),
                          IconButton.filled(
                              onPressed: () {
                                int currentIndex =
                                    (pageController.page!).toInt();
                                if (pages.length > currentIndex + 1) {
                                  pageController.animateToPage(currentIndex + 1,
                                      duration: Durations.medium4,
                                      curve: Curves.decelerate);
                                } else {
                                  pageController.animateToPage(0,
                                      duration: Durations.medium4,
                                      curve: Curves.decelerate);
                                }
                              },
                              icon: const Icon(Icons.arrow_forward)),
                        ],
                      ),
                    ),
                  )
                ],
              ))),
    );
  }
}
