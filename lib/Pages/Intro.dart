import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:easingles/assets/app.colors.dart';
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
    // _controllerx = FlutterGifController(vsync: this);
  }

  Widget FirstPage() {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Text(
                "Welcome to ..YoDate... Uganda's #1 premier dating app",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lighter),
              ),
            ),
            GifView.asset(
              'lib/assets/images/Onlinedating-animated.gif',
              width: MediaQuery.of(context)
                  .size
                  .width, // 90% of the device's width
              height: MediaQuery.of(context).size.height *
                  0.6, // 60% of the device's height

              frameRate: 30, // default is 15 FPS
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () {
                      _pageController.animateToPage(
                          _currentPageIndex == 0
                              ? _currentPageIndex
                              : _currentPageIndex - 1,
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    },
                    child: Text(
                      "Prev",
                      style: TextStyle(
                          color: AppColors.lighter,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    )),
                TextButton(
                  onPressed: () {
                    _pageController.animateToPage(_currentPageIndex + 1,
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeInOut);
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(
                        color: AppColors.lighter,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget SecondPage() {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Text(
                "Meet New People near you or globally instantly",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lighter),
              ),
            ),
            GifView.asset(
              'lib/assets/images/meet.gif',
              width: MediaQuery.of(context)
                  .size
                  .width, // 90% of the device's width
              height: MediaQuery.of(context).size.height *
                  0.6, // 60% of the device's height

              frameRate: 30, // default is 15 FPS
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () {
                      _pageController.animateToPage(
                          _currentPageIndex == 0
                              ? _currentPageIndex
                              : _currentPageIndex - 1,
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    },
                    child: Text(
                      "Prev",
                      style: TextStyle(
                          color: AppColors.lighter,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    )),
                TextButton(
                  onPressed: () {
                    _pageController.animateToPage(_currentPageIndex + 1,
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeInOut);
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(
                        color: AppColors.lighter,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

Widget ThirdPage() {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Text(
                "Share your love and gifts redeemable via mobile money",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lighter),
              ),
            ),
            GifView.asset(
              'lib/assets/images/Onlinedating-animated-xx.gif',
              width: MediaQuery.of(context)
                  .size
                  .width, // 90% of the device's width
              height: MediaQuery.of(context).size.height *
                  0.6, // 60% of the device's height

              frameRate: 30, // default is 15 FPS
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () {
                      _pageController.animateToPage(
                          _currentPageIndex == 0
                              ? _currentPageIndex
                              : _currentPageIndex - 1,
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    },
                    child: Text(
                      "Prev",
                      style: TextStyle(
                          color: AppColors.lighter,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    )),
                TextButton(
                  onPressed: () {
                    _pageController.animateToPage(_currentPageIndex + 1,
                        duration: Duration(milliseconds: 400),
                        curve: Curves.easeInOut);
                  },
                  child: Text(
                    "Next",
                    style: TextStyle(
                        color: AppColors.lighter,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

Widget FourthPage() {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: Text(
                "Share your love, feeling and chat with potential partners",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lighter),
              ),
            ),
            GifView.asset(
              'lib/assets/images/Onlinedating-animated-x.gif',
              width: MediaQuery.of(context)
                  .size
                  .width, // 90% of the device's width
              height: MediaQuery.of(context).size.height *
                  0.6, // 60% of the device's height

              frameRate: 30, // default is 15 FPS
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                    onPressed: () {
                      _pageController.animateToPage(
                          _currentPageIndex == 0
                              ? _currentPageIndex
                              : _currentPageIndex - 1,
                          duration: Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    },
                    child: Text(
                      "Prev",
                      style: TextStyle(
                          color: AppColors.lighter,
                          fontSize: 28,
                          fontWeight: FontWeight.bold),
                    )),
                TextButton(
                  onPressed: ()async {
                   SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString('intro', "intro");  
                  Navigator.of(context).pushReplacementNamed('/login');      
                  },
                  child: Text(
                    "Finish",
                    style: TextStyle(
                        color: AppColors.lighter,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
        backgroundColor: Colors.white,
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
          FourthPage()
        ],
      
      ),
      bottomNavigationBar: Container(
        color:Colors.white,
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
                    ),
                    
                  ),
            ],
          ),
        ),
      ), 
    );
  }
}


