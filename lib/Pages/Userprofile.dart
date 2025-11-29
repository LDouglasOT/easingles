import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easingles/Components/AppButton.dart';
import 'package:easingles/Components/Gallery.dart';
import 'package:easingles/Components/PostItems.dart'; // Assuming this is a proper post widget
import 'package:easingles/Components/Profile.dart';
import 'package:easingles/Components/Profile_images.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Pages/Login_page.dart';
import 'package:easingles/Pages/Profilepage.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Popmenuaction {
  edit,
  logout,
}

class Userprofile extends StatefulWidget {
  final String userId;
  Userprofile({super.key, required this.userId});

  @override
  State<Userprofile> createState() => _UserprofileState(UserId: userId);
}

class _UserprofileState extends State<Userprofile> {
  List<UserData> userlist = [];
  List<MomentData> moments = [];
  final String UserId;

  _UserprofileState({required this.UserId});

  @override
  void initState() {
    super.initState();
    getProfile();
    getMoments();
  }

  // --- Data Fetching Methods (Kept Original) ---

  void reportuser() {}
  void getProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    var url = Uri.parse("${AppUrls.production}/api/currentuser/${UserId}");
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    var url = Uri.parse("${AppUrls.production}/api/personalmoments/${UserId}");
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString("id");
    String? token = prefs.getString("token");
    print("making that request");
    var response = await http.post(Uri.parse('${AppUrls.production}/api/like'),
        headers: {'Authorization': 'Bearer $token'},
        body: {"userId": id.toString(), "likedId": UserId, "super": "0"});
    if (!(response.statusCode == 200)) {
      var response = await http.post(
          Uri.parse('${AppUrls.production}/api/like'),
          headers: {'Authorization': 'Bearer $token'},
          body: {"userId": id.toString(), "likedId": UserId, "super": "0"});
    }
  }

  // --- Visuals Refactored ---

  // Use the imported PostItems component for cleaner rendering
  List<Widget> mymoments() {
    return moments.map((mom) {
      // **Assumption:** The imported PostItems is a widget that takes MomentData.
      // If PostItems does not exist, or takes different params, this needs adjustment.
      return PostItem(
        user: mom, // Passing the entire MomentData object
      );
    }).toList();
  }

  List<Widget> myinterests() {
    List<String> interests = userlist.isNotEmpty && userlist[0].userinterests.isNotEmpty
        ? List<String>.from(userlist[0].userinterests)
        : ["No interests"];

    return interests.map((interest) {
      return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Chip(
          label: Text(
            interest,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.lighter, // Use your app's lighter color
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }).toList();
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
    final bool hasProfile = userlist.isNotEmpty;
    final String firstName = hasProfile ? userlist[0].firstName : "User";
    final String profilePicUrl = hasProfile
        ? (userlist[0].profilePic ??
            "https://img.icons8.com/deco/48/no-camera.png")
        : "https://img.icons8.com/deco/48/no-camera.png";
    final String age = hasProfile ? calculateAge(userlist[0].year.toString()) : "";

    return Scaffold(
      appBar: Toolbar(
        title: "$firstName's Profile",
        background: const Color.fromARGB(255, 97, 119, 161),
        actions: [
          PopupMenuButton<Popmenuaction>(
            onSelected: (value) async {
              switch (value) {
                case Popmenuaction.edit:
                  Navigator.of(context).pushNamed('/edit');
                  break;
                case Popmenuaction.logout:
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Login_page()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Popmenuaction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 10),
                    Text("Edit Profile"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Popmenuaction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 10),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (hasProfile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- Profile Picture ---
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.lighter.withOpacity(0.5),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60), // Half of height/width
                        child: Image.network(
                          profilePicUrl,
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 120, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- Name and Age ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$firstName ${userlist[0].lastName}, ",
                          style: AppText.subtitle1.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          age,
                          style: AppText.subtitle1.copyWith(fontSize: 24, fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      userlist[0].about ?? "Say something about yourself!",
                      style: AppText.body2.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 25),

                    // --- Action Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppButton(textString: '❤️ Like', pressed: Likeuser),
                        const SizedBox(width: 15),
                        AppButton(textString: '💬 Message', pressed: () {}),
                        const SizedBox(width: 15),
                        AppButton(textString: '🎁 Gift', pressed: () {}),
                      ],
                    ),

                    const SizedBox(height: 30),
                    
                    // --- Interests Section ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Interests", style: AppText.header3),
                    ),
                    const Divider(height: 10, thickness: 1, color: Colors.grey),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: myinterests(),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- Gallery Section ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "$firstName's Photos",
                        style: AppText.header3,
                      ),
                    ),
                    const Divider(height: 10, thickness: 1, color: Colors.grey),
                    const SizedBox(height: 10),
                    Image_gallery(listImages: [
                      userlist[0].profilePic,
                      ...userlist[0].userimages
                    ]),
                  ],
                ),
              ),
            
            // --- Moments/Posts Section ---
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${moments.length} Recent Posts",
                  style: AppText.header3,
                ),
              ),
            ),
            const Divider(height: 10, thickness: 1, color: Colors.grey),
            const SizedBox(height: 10),
            if (moments.isNotEmpty)
              Column(
                children: mymoments(),
              )
            else
              const Padding(
                padding: EdgeInsets.all(30.0),
                child: Text("No moments posted yet."),
              ),
            const SizedBox(height: 50), // Extra space at the bottom
          ],
        ),
      ),
    );
  }
}

// --- Data Models (Kept Original) ---

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
// Note: UserData is assumed to be defined in 'package:easingles/Components/Profile.dart'