import 'package:mazale/Provider/SocketProvider.dart';
import 'package:mazale/Provider/ProfileProvider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:mazale/Models/model.dart';
import 'package:mazale/Pages/ChatScreen.dart';
import 'package:mazale/Pages/Chats.dart';
import 'package:mazale/Pages/Dating.dart';
import 'package:mazale/Pages/ForgotPass.dart';
import 'package:mazale/Pages/GiftsPager.dart';
import 'package:mazale/Pages/Confirmwithdraw.dart';
import 'package:mazale/Pages/Intro.dart';
import 'package:mazale/Pages/Likes.dart';
import 'package:mazale/Pages/Login_page.dart';
import 'package:mazale/Pages/Moments.dart';
import 'package:mazale/Pages/Notifications.dart';
import 'package:mazale/Pages/PostMoment.dart';
import 'package:mazale/Pages/Profile_edit.dart';
import 'package:mazale/Pages/Purchase.dart';
import 'package:mazale/Pages/Register.dart';
import 'package:mazale/Pages/Withdraw.dart';
import 'package:mazale/Pages/home_page.dart';
import 'package:mazale/Pages/MainPage.dart';
import 'package:mazale/Provider/LoginProvider.dart';
import 'package:mazale/Provider/RegisterProvider.dart';
import 'package:mazale/Provider/BackendChatProvider.dart';
import 'package:mazale/assets/app.colors.dart';
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
try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully!");
  } catch (e) {
    print("❌ Firebase initialization FAILED: $e");
  }
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
        ChangeNotifierProvider(create: (context) => BackendChatProvider()),
        ChangeNotifierProvider(create: (context) => SocketProvider()),
        ChangeNotifierProvider(create: (context) => ProfileProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            fontFamily: "MTNBrighterSans",
            scaffoldBackgroundColor: AppColors.background,
            brightness: Brightness.dark),
        initialRoute: '/',
        routes: {
          
        '/': (context) => _defaultHome,
          '/purchase': (context) => Purchase(),
          '/main': (context) => MainPage(),
          '/moments': (context) => MomentsPage(),
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
