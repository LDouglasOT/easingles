import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:easingles/Components/Liked.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Pages/Chats.dart';
import 'package:easingles/Pages/Dating.dart';
import 'package:easingles/Pages/GiftsPager.dart';
import 'package:easingles/Pages/Likes.dart';
import 'package:easingles/Pages/Moments.dart';
import 'package:easingles/Pages/Profilepage.dart';
import 'package:easingles/Pages/home_page.dart';
import 'package:easingles/Provider/SocketProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int controller = 0;
  void initState() {
    super.initState();
    initializeOneSignal();
  }
  
  Future<void> initializeOneSignal() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var token = prefs.getString('id');
  if (token != null) {
   return;
  } else {

  }
}

  @override
  Widget build(BuildContext context) {
    void startserver() {
      context.read<SocketProvider>().initsocket();
    }
    startserver();
    return Scaffold(
      body: pages[controller],
      bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: AppColors.background,
          animationDuration: Duration(milliseconds: 300),
          color: AppColors.lighter,
          onTap: (index) {
            setState(() {
              controller = index;
              debugPrint('$index');
            });
          },
          items: [
            SvgPicture.asset(
              "lib/assets/svg/ic_home.svg",
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            SvgPicture.asset(
              "lib/assets/svg/ic_favorite.svg",
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            SvgPicture.asset(
              "lib/assets/svg/ic_messages.svg",
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            SvgPicture.asset(
              "lib/assets/svg/photo-camera-svgrepo-com.svg",
              width: 25,
              height:25,
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            SvgPicture.asset(
              "lib/assets/svg/ic_user.svg",
              colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
            )
          ]),
    );
  }

  final pages = [
    Dating(),
    Likes(),
    Chats(),
    Moments(),
    Profilepage(),
  ];
}
