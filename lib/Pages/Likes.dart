import 'dart:convert';

import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:easingles/Components/Liked.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Pages/Profilepage.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Likes extends StatefulWidget {
  const Likes({super.key});

  @override
  State<Likes> createState() => _LikesState();
}

class _LikesState extends State<Likes> {
  String header = "Likes";
  List<UserData> likes = [];
  List<UserData> liked = [];
  List<UserData> matches = [];
  String? userId = "0";
  @override
  void initState() {
    super.initState();
    getLikes();
    getMatches();
    getLiked();
  }

  void getLikes() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');
    var url = Uri.parse('${AppUrls.production}/api/mylikes');
    String? id = pref.getString('id');
    setState(() {
      userId = id;
    });

    var response = await http.post(url, headers: {
      'Authorization': 'Bearer $token'
    }, body: {
      "likeIded": id,
    });
    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> Likes_List = jsonResponse['data'];
          List<UserData> userlikes =
              Likes_List.map((e) => UserData.fromJson(e)).toList();
          setState(() {
            likes = userlikes;
          });
        }
        break;
      case 404:
        print('Not Found');
        break;
      default:
        print('error');
    }
  }

  void getLiked() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');
    var url = Uri.parse('${AppUrls.production}/api/likedprofiles');
    String? id = pref.getString('id');
    setState(() {
      userId = id;
    });

    var response = await http.post(url, headers: {
      'Authorization': 'Bearer $token'
    }, body: {
      "likeIded": id,
    });

    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> Likes_List = jsonResponse['data'];
          List<UserData> userlikes =
              Likes_List.map((e) => UserData.fromJson(e)).toList();
          setState(() {
            liked = userlikes;
          });
        }
        break;
      case 404:
        print('Not Found');
        break;
      default:
        print('error');
    }
  }

  void getMatches() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');
    var url = Uri.parse('${AppUrls.production}/api/matchedusers');
    String? id = pref.getString('id');
    setState(() {
      userId = id;
    });

    var response = await http.post(url, headers: {
      'Authorization': 'Bearer $token'
    }, body: {
      "id": id,
    });
    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          print(jsonResponse['data']);
          List<dynamic> Likes_List = jsonResponse['data'];
          print("${Likes_List.length}");
          List<UserData> userlikes =
              Likes_List.map((e) => UserData.fromJson(e)).toList();
          setState(() {
            matches = userlikes;
          });
        }
        break;
      case 404:
        print('Not Found');
        break;
      default:
        print('error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0, backgroundColor: AppColors.lighter),
      body: Container(
        color: AppColors.lighter,
        // padding: EdgeInsets.fromLTRB(15, 20, 15, 0),
        child: ContainedTabBarView(
          tabBarProperties: TabBarProperties(
              height: 60,
              width: double.infinity,
              background: Container(
                color: AppColors.lighter,
              ),
              position: TabBarPosition.top,
              alignment: TabBarAlignment.end),
          tabs: [
            Row(
              children: [
                Text('Liked',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: liked.isNotEmpty
                          ? Color.fromARGB(255, 255, 255, 255)
                          : Colors.black,
                    )),
                Visibility(
                  visible: likes.isNotEmpty,
                  child: Center(
                    child: Container(
                      height: 20,
                      width: 20,
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.amber,
                      ),
                      child: Center(
                        child: Text(likes.length.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text('Liked',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: liked.isNotEmpty
                          ? Color.fromARGB(255, 255, 255, 255)
                          : Colors.black,
                    )),
                Visibility(
                  visible: liked.isNotEmpty,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.amber,
                    ),
                    child: Center(
                      child: Text(liked.length.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text('Matches',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: matches.isNotEmpty
                          ? Color.fromARGB(255, 254, 255, 254)
                          : Colors.black,
                    )),
                Visibility(
                  visible: matches.isNotEmpty,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Colors.amber,
                    ),
                    height: 20,
                    width: 20,
                    child: Center(
                      child: Text(matches.length.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                    ),
                  ),
                ),
              ],
            ),
          ],
          views: [
            Liked(likes: likes, name: "Likes", userId: userId ?? "0"),
            Liked(
                likes: liked,
                name: "user has liked you",
                userId: userId ?? "0"),
            Liked(likes: matches, name: "Matches", userId: userId ?? "0")
          ],
          onChange: (index) => print(index),
        ),
      ),
    );
  }
}
