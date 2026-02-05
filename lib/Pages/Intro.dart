import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Intro extends StatefulWidget {
  const Intro({Key? key}) : super(key: key);

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  Widget _buildPage({
    required String gifPath,
    required String title,
    required bool isLastPage,
  }) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // GIF Section
                        GifView.asset(
                          gifPath,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.45,
                          frameRate: 30,
                        ),

                        // Title Section
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 20.0,
                            ),
                            child: Center(
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.06,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lighter,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Navigation Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 20.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _currentPageIndex == 0
                                    ? null
                                    : () {
                                        _pageController.animateToPage(
                                          _currentPageIndex - 1,
                                          duration: Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                child: Text(
                                  "Prev",
                                  style: TextStyle(
                                    color: _currentPageIndex == 0
                                        ? AppColors.lighter.withOpacity(0.3)
                                        : AppColors.lighter,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  if (isLastPage) {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.setString('intro', "intro");
                                    Navigator.of(context)
                                        .pushReplacementNamed('/login');
                                  } else {
                                    _pageController.animateToPage(
                                      _currentPageIndex + 1,
                                      duration: Duration(milliseconds: 400),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                                child: Text(
                                  isLastPage ? "Finish" : "Next",
                                  style: TextStyle(
                                    color: AppColors.lighter,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget FirstPage() {
    return _buildPage(
      gifPath: 'lib/assets/images/Onlinedating-animated.gif',
      title: "Welcome to Mazale\nUganda's #1 premier dating app",
      isLastPage: false,
    );
  }

  Widget SecondPage() {
    return _buildPage(
      gifPath: 'lib/assets/images/meet.gif',
      title: "Meet New People near you or globally instantly",
      isLastPage: false,
    );
  }

  Widget ThirdPage() {
    return _buildPage(
      gifPath: 'lib/assets/images/Onlinedating-animated-xx.gif',
      title: "Share your love and gifts redeemable via mobile money",
      isLastPage: false,
    );
  }

  Widget FourthPage() {
    return _buildPage(
      gifPath: 'lib/assets/images/Onlinedating-animated-x.gif',
      title: "Share your love, feeling and chat with potential partners",
      isLastPage: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        children: [
          FirstPage(),
          SecondPage(),
          ThirdPage(),
          FourthPage(),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 4,
                  effect: ScrollingDotsEffect(
                    activeDotColor: Colors.amber,
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}