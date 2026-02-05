import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mazale/Components/Liked.dart';
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/Pages/Chats.dart';
import 'package:mazale/Pages/Dating.dart';
import 'package:mazale/Pages/GiftsPager.dart';
import 'package:mazale/Pages/Likes.dart';
import 'package:mazale/Pages/Moments.dart';
import 'package:mazale/Pages/PeopleAroundMapPage.dart';
import 'package:mazale/Pages/Profilepage.dart';
import 'package:mazale/Pages/home_page.dart';
import 'package:mazale/Provider/SocketProvider.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
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
    handShake();
    // Initialize socket immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SocketProvider>(context, listen: false).initialize();
    });
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
    MomentsPage(),
    PeopleAroundMapPage(),
  ];
  
  Future<void> handShake() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    var postUrl = Uri.parse('${AppUrls.production}/api/chat/handshake/');
    http.post(postUrl, headers: {'Authorization': 'Bearer $token'}).then((response) {
      if (response.statusCode == 200) {
        debugPrint('Handshake successful');
      } else {
         handShake();
      }
    });
  }
}
