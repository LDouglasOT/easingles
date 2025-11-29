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
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      await getLikes();
      await getLiked();
      await getMatches();
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load data. Please try again.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getLikes() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');
    String? id = pref.getString('id');
    setState(() {
      userId = id;
    });

    var url = Uri.parse('${AppUrls.production}/api/mylikes');
    var response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
      body: {"likeIded": id},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
        List<dynamic> likesList = jsonResponse['data'];
        setState(() {
          likes = likesList.map((e) => UserData.fromJson(e)).toList();
        });
      }
    }
  }

  Future<void> getLiked() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');
    String? id = pref.getString('id');

    var url = Uri.parse('${AppUrls.production}/api/likedprofiles');
    var response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
      body: {"likeIded": id},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
        List<dynamic> likedList = jsonResponse['data'];
        setState(() {
          liked = likedList.map((e) => UserData.fromJson(e)).toList();
        });
      }
    }
  }

  Future<void> getMatches() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');
    String? id = pref.getString('id');

    var url = Uri.parse('${AppUrls.production}/api/matchedusers');
    var response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
      body: {"id": id},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
        List<dynamic> matchesList = jsonResponse['data'];
        setState(() {
          matches = matchesList.map((e) => UserData.fromJson(e)).toList();
        });
      }
    }
  }

  Widget _buildTab(String text, int count) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            height: 20,
            width: 20,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.amber,
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.lighter,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Container(
                  color: AppColors.lighter,
                  child: ContainedTabBarView(
                    tabBarProperties: TabBarProperties(
                      height: 60,
                      width: double.infinity,
                      background: Container(color: AppColors.lighter),
                      position: TabBarPosition.top,
                      alignment: TabBarAlignment.end,
                    ),
                    tabs: [
                      _buildTab("Likes", likes.length),
                      _buildTab("Liked By", liked.length),
                      _buildTab("Matches", matches.length),
                    ],
                    views: [
                      Liked(likes: likes, name: "Likes", userId: userId ?? "0"),
                      Liked(likes: liked, name: "Liked By", userId: userId ?? "0"),
                      Liked(likes: matches, name: "Matches", userId: userId ?? "0"),
                    ],
                    onChange: (index) => print(index),
                  ),
                ),
    );
  }
}
