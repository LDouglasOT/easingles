import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mazale/Components/AppButton.dart';
import 'package:mazale/Components/Gallery.dart';
import 'package:mazale/Components/PostItems.dart';
import 'package:mazale/Components/Profile.dart';
import 'package:mazale/Components/Profile_images.dart';
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/Pages/Login_page.dart';
import 'package:mazale/Provider/SocketProvider.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum Popmenuaction {
  edit,
  logout,
}

class Profilepage extends StatefulWidget {
  Profilepage({super.key});

  @override
  State<Profilepage> createState() => _ProfilepageState();
}

class _ProfilepageState extends State<Profilepage> {
  List<UserData> userlist = [];
  List<MomentData> moments = [];

  void initState() {
    super.initState();
    getProfile();
    getMoments();
  }

  void getProfile() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? id = pref.getString("id");
    String? token = pref.getString("token");
    var url = Uri.parse("${AppUrls.production}/api/currentuser/${id}");
    var response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        UserData useritem = UserData.fromJson(jsonResponse);
        setState(() => userlist.add(useritem));
        break;
      case 500:
        print(response.body);
        break;
      default:
    }
  }

  void getMoments() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? id = pref.getString("id");
    String? token = pref.getString('token');
    var url = Uri.parse(
      "${AppUrls.production}/api/personalmoments/${id}",
    );
    var response =
        await http.get(url, headers: {'Authorization': 'Bearer $token'});
    print(response.body);
    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> moment = jsonResponse['data'];
        List<MomentData> momentstore = [];
        for (var m in moment) {
          MomentData momentitem = MomentData.fromJson(m);
          momentstore.add(momentitem);
        }
        setState(() => moments = momentstore);
        break;
      case 500:
        print(response.body);
        break;
      default:
    }
  }

  void Likeuser() async {
  }

  Future<void> _handleLogout() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
    );

    try {
      // Disconnect socket first
      Provider.of<SocketProvider>(context, listen: false).disconnect();
      
      // Get stored credentials
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? loginId = prefs.getString('id');
      String? token = prefs.getString('token');
      
      // Call backend logout endpoint to invalidate tokens
      if (loginId != null && token != null) {
        try {
          var logoutUrl = Uri.parse('${AppUrls.production}/api/auth/logout');
          await http.post(
            logoutUrl,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token'
            },
            body: jsonEncode({'loginId': loginId}),
          );
        } catch (e) {
          // Continue with logout even if backend call fails
          print('Backend logout error: $e');
        }
      }
      
      // Sign out from Firebase (for Google login users)
      try {
        await GoogleSignIn.instance.signOut();
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        // Continue with logout even if Firebase sign-out fails
        print('Firebase sign-out error: $e');
      }
      
      // Clear all SharedPreferences
      await prefs.clear();
      
      // Close the loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      // Navigate to login page and remove all previous routes
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Login_page()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Close the loading dialog on error
      if (mounted) {
        Navigator.of(context).pop();
      }
      print('Logout error: $e');
      
      // Still clear local data and navigate to login
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => Login_page()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  List<Widget> mymoments() {
    List<Widget> momentez = [];
    for (var mom in moments) {
      momentez.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(mom.imageOne),
                ),
                SizedBox(width: 10),
                Row(
                  children: [
                    Text(mom.firstName, style: AppText.subtitle3),
                    const SizedBox(width: 5),
                    Text(mom.lastName, style: AppText.subtitle3),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 450,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child: Image.network(
                  mom.imageOne,
                  height: 400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                mom.tagLine,
                style: AppText.subtitle3,
              ),
            ),
          ],
        ),
      ));
    }
    return momentez;
  }

  List<Widget> myinterests() {
    List<Widget> hopes = [];

    for (var i = 0; i < userlist[0].userinterests.length; i++) {
      hopes.add(
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.lighter,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(
              userlist[0].userinterests[i].toString() ?? "No interests,",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    if (userlist[0].userinterests.length == 0) {
      hopes.add(
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.lighter,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            child: Text(
              "No interests,",
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return hopes;
  }

  String calculateAge(String dateString) {
    DateTime birthDate = DateTime.parse(dateString);
    DateTime currentDate = DateTime.now();
    Duration ageDifference = currentDate.difference(birthDate);
    int ageInYears = (ageDifference.inDays / 365).floor();
    return ageInYears.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
        title: "Profile",
        background: Color.fromARGB(255, 97, 119, 161),
        actions: [
          PopupMenuButton<Popmenuaction>(
            onSelected: (value) async {
              switch (value) {
                case Popmenuaction.edit:
                  Navigator.of(context).pushNamed('/edit');
                  break;
                case Popmenuaction.logout:
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Edit Profile", style: TextStyle(color: Colors.white)),
                  ],
                ),
                value: Popmenuaction.edit,
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
                value: Popmenuaction.logout,
              )
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (userlist.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                        child: Image.network(
                          userlist[0].profilePic ??
                              "https://img.icons8.com/deco/48/no-camera.png",
                          height: 150,
                          width: 150,
                          fit: BoxFit
                              .cover,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${userlist[0].firstName} ${userlist[0].lastName}, ",
                        style: AppText.subtitle1,
                      ),
                      Text(
                        calculateAge(userlist[0].year.toString()),
                        style: AppText.subtitle1,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AppButton(textString: 'Like', pressed: () {}),
                    const SizedBox(
                      width: 10,
                    ),
                    AppButton(textString: 'message', pressed: () {}),
                    const SizedBox(
                      width: 10,
                    ),
                    AppButton(textString: 'Gift', pressed: () {}),
                  ]),
                  const SizedBox(height: 10),
                  const Text(
                    "Interests",
                    style: AppText.header3,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Wrap(
                      spacing:
                          8.0,
                      runSpacing: 8.0,
                      children: [...myinterests()],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${userlist[0].firstName}'s Photos",
                    style: AppText.header3,
                  ),
                  const SizedBox(height: 10),
                  Image_gallery(listImages: [
                    userlist[0].profilePic,
                    ...userlist[0].userimages
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    "${moments.length.toString()} Recent Posts",
                    style: AppText.header3,
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [],
                  )
                ],
              ),
            const SizedBox(height: 10),
            if (moments.isNotEmpty)
              Column(
                children: [...mymoments()],
              )
          ],
        ),
      ),
    );
  }
}

class UserData {
  int id;
  String firstName;
  String lastName;
  DateTime? day;
  DateTime? month;
  DateTime? year;
  String? country;
  String? district;
  String? village;
  String? profilePic;
  bool? online;
  String gender;
  String? hopes;
  String? religion;
  String? imgx;
  String? imgxx;
  String? imgxxx;
  String? imgxxxx;
  String? referralCode;
  int loginId;
  String? contact;
  String? twitter;
  String? instagram;
  String? facebook;
  String? email;
  String? about;
  bool? promoted;
  String? subscription;
  String? endSubscription;
  int? totalShows;
  String? promoterUrl;
  List<dynamic> userimages;
  List<dynamic>
      userinterests;

  UserData(
      {required this.id,
      required this.firstName,
      required this.lastName,
      this.day,
      this.month,
      this.year,
      this.country,
      this.district,
      this.village,
      this.profilePic,
      this.online,
      required this.gender,
      this.hopes,
      this.religion,
      this.imgx,
      this.imgxx,
      this.imgxxx,
      this.imgxxxx,
      this.referralCode,
      required this.loginId,
      this.contact,
      this.twitter,
      this.instagram,
      this.facebook,
      this.email,
      this.about,
      this.promoted,
      this.subscription,
      this.endSubscription,
      this.totalShows,
      this.promoterUrl,
      required this.userimages,
      required this.userinterests});

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
        id: json['id'] as int,
        firstName: json['FirstName'] as String,
        lastName: json['LastName'] as String,
        day: json['day'] != null ? DateTime.parse(json['day']) : null,
        month: json['month'] != null ? DateTime.parse(json['month']) : null,
        year: DateTime.parse(json['year']),
        country: json['Country'] as String?,
        district: json['District'] as String?,
        village: json['Village'] as String?,
        profilePic: json['Profilepic'] as String,
        online: json['online'] as bool?,
        gender: json['Gender'] as String,
        hopes: json['hopes'] as String?,
        religion: json['religion'] as String?,
        imgx: json['imgx'] as String?,
        imgxx: json['imgxx'] as String?,
        imgxxx: json['imgxxx'] as String?,
        imgxxxx: json['imgxxxx'] as String?,
        referralCode: json['referalCode'] as String?,
        loginId: json['loginId'] as int,
        contact: json['contact'] as String?,
        twitter: json['twitter'] as String?,
        instagram: json['instagram'] as String?,
        facebook: json['facebook'] as String?,
        email: json['email'] as String?,
        about: json['about'] as String?,
        promoted: json['promoted'] as bool?,
        subscription: json['subscription'] as String?,
        endSubscription: json['endsubscription'] as String?,
        totalShows: json['totalshows'] as int?,
        promoterUrl: json['promoterurl'] as String?,
        userimages: json['userImages'] as List<dynamic>,
        userinterests: json['userInterests'] as List<dynamic>);
  }
}

class MomentData {
  int id;
  int likes;
  int ownerId;
  String hashTag;
  String tagLine;
  String imageOne;
  String imageTwo;
  String imageThree;
  String firstName;
  String lastName;
  DateTime date;
  List<CommentData> comments;

  MomentData({
    required this.id,
    required this.likes,
    required this.ownerId,
    required this.hashTag,
    required this.tagLine,
    required this.imageOne,
    required this.imageTwo,
    required this.imageThree,
    required this.firstName,
    required this.lastName,
    required this.date,
    required this.comments,
  });

  factory MomentData.fromJson(Map<String, dynamic> json) {
    List<CommentData> commentsList = [];
    if (json['comments'] != null) {
      for (var commentJson in json['comments']) {
        commentsList.add(CommentData.fromJson(commentJson));
      }
    }

    return MomentData(
      id: json['id'] as int,
      likes: json['Likes'] as int,
      ownerId: json['owenId'] as int,
      hashTag: json['HashTag'] as String,
      tagLine: json['TagLine'] as String,
      imageOne: json['imageOne'] as String,
      imageTwo: json['imageTwo'] as String,
      imageThree: json['imageThree'] as String,
      firstName: json['FirstName'] as String,
      lastName: json['LastName'] as String,
      date: DateTime.parse(json['date'] as String),
      comments: commentsList,
    );
  }
}

class CommentData {
  int id;
  int? momentId;
  String names;
  String df;
  String imageOne;
  DateTime date;

  CommentData({
    required this.id,
    required this.momentId,
    required this.names,
    required this.df,
    required this.imageOne,
    required this.date,
  });

  factory CommentData.fromJson(Map<String, dynamic> json) {
    return CommentData(
      id: json['id'] as int,
      momentId: json['momentId'] as int?,
      names: json['Names'] as String,
      df: json['df'] as String,
      imageOne: json['imageOne'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
