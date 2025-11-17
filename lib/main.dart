import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:easingles/Models/model.dart';
import 'package:easingles/Pages/ChatScreen.dart';
import 'package:easingles/Pages/Chats.dart';
import 'package:easingles/Pages/Dating.dart';
import 'package:easingles/Pages/ForgotPass.dart';
import 'package:easingles/Pages/GiftsPager.dart';
import 'package:easingles/Pages/Confirmwithdraw.dart';
import 'package:easingles/Pages/Intro.dart';
import 'package:easingles/Pages/Likes.dart';
import 'package:easingles/Pages/Login_page.dart';
import 'package:easingles/Pages/Moments.dart';
import 'package:easingles/Pages/Notifications.dart';
import 'package:easingles/Pages/PostMoment.dart';
import 'package:easingles/Pages/Profile_edit.dart';
import 'package:easingles/Pages/Purchase.dart';
import 'package:easingles/Pages/Register.dart';
import 'package:easingles/Pages/Withdraw.dart';
import 'package:easingles/Pages/home_page.dart';
import 'package:easingles/Pages/MainPage.dart';
import 'package:easingles/Provider/LoginProvider.dart';
import 'package:easingles/Provider/RegisterProvider.dart';
import 'package:easingles/Provider/SocketProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

Widget _defaultHome = Login_page();
void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  OneSignal.initialize("06016505-f0a1-4eec-bcf6-24ffd1b745f2");
  OneSignal.Notifications.requestPermission(false);
  String? userId = await OneSignal.User.getOnesignalId();
  print(userId);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // await Firebase.initializeApp();
  var token = prefs.getString('id');
  var intro = prefs.getString('intro');
  if (intro == null) {
    _defaultHome = Intro();
  }
  if (token != null && intro != null) {
    _defaultHome = MainPage();
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginProvider()),
        ChangeNotifierProvider(create: (context) => RegisterProvider()),
        ChangeNotifierProvider(create: (context) => SocketProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: "MTNBrighterSans",
            scaffoldBackgroundColor: AppColors.background,
            brightness: Brightness.dark),
        initialRoute: '/',
        routes: {
          '/': (context) => Intro(),
          '/purchase': (context) => Purchase(),
          '/main': (context) => MainPage(),
          '/moments': (context) => Moments(),
          "/newmoment": (context) => PostMoment(),
          '/home': (context) => Dating(),
          '/mainpage': (context) => Likes(),
          '/notifications': (context) => Notifications(),
          '/chats': (context) => Chats(),
          '/edit': (context) => Profile_edit(),
          '/gifts': (context) => GiftsPage(),
          '/register': (context) => Register(),
          '/forgot': (context) => ForgotPass(),
          '/withdraw': (context) => Withdraw(),
          '/login': (context) => Login_page(),
        },
      ),
    );
  }
}
