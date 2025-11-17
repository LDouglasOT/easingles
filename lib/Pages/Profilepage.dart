import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easingles/Components/AppButton.dart';
import 'package:easingles/Components/Gallery.dart';
import 'package:easingles/Components/PostItems.dart';
import 'package:easingles/Components/Profile.dart';
import 'package:easingles/Components/Profile_images.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Pages/Login_page.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    // Handle like action without showing SnackBar
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // String? id = prefs.getString("id");
    // print("making that request");
    // var response = await http.post(Uri.parse('${AppUrls.production}/api/like'),
    //     body: {
    //       "userId": id.toString(),
    //       "likedId": profile['id'].toString(),
    //       "super": "0"
    //     });
    // if (!(response.statusCode == 200)) {
    //   var response = await http.post(Uri.parse('${AppUrls.production}/api/like'),
    //       body: {
    //         "userId": id.toString(),
    //         "likedId": profile['id'].toString(),
    //         "super": "0"
    //       });
    // }
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
                fontSize: 16.0, // Adjust the font size
                fontWeight: FontWeight.normal, // Adjust the font weight
                color: Colors.white, // Adjust the text color
                // Add more style properties as needed
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
                fontSize: 16.0, // Adjust the font size
                fontWeight: FontWeight.normal, // Adjust the font weight
                color: Colors.white, // Adjust the text color
                // Add more style properties as needed
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
        title: "Profile ${userlist.length.toString()}",
        background: Color.fromARGB(255, 97, 119, 161),
        actions: [
          PopupMenuButton(itemBuilder: (context) {
            onSelected:
            (value) async {
              switch (value) {
                case Popmenuaction.edit:
                  print("Logging out section 1");
                  break;
                case Popmenuaction.logout:
                  break;
                default:
              }
            };
            return [
              PopupMenuItem(
                onTap: () {
                  Navigator.of(context).pushNamed('/edit');
                },
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(
                      width: 10,
                    ),
                    Text("Edit"),
                  ],
                ),
                value: Popmenuaction.edit,
              ),
              PopupMenuItem(
                onTap: () async {
                  print("Tapped this");
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Login_page()),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(
                      width: 10,
                    ),
                    Text("logout"),
                  ],
                ),
                value: Popmenuaction.logout,
              )
            ];
          })
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
                              .cover, // You can add this line to ensure the image covers the entire space
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
                          8.0, // Adjust the spacing between items as needed
                      runSpacing: 8.0, // Adjust the run spacing as needed
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
  DateTime? day; // You may adjust the type based on the actual data
  DateTime? month; // You may adjust the type based on the actual data
  DateTime? year;
  String? country;
  String? district;
  String? village; // You may adjust the type based on the actual data
  String? profilePic;
  bool? online; // You may adjust the type based on the actual data
  String gender;
  String? hopes; // You may adjust the type based on the actual data
  String? religion; // You may adjust the type based on the actual data
  String? imgx; // You may adjust the type based on the actual data
  String? imgxx; // You may adjust the type based on the actual data
  String? imgxxx; // You may adjust the type based on the actual data
  String? imgxxxx; // You may adjust the type based on the actual data
  String? referralCode; // You may adjust the type based on the actual data
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
      userinterests; // You may adjust the type based on the actual data

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
