import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Models/GiftsMode.dart';
import 'package:easingles/Pages/Buy.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Giftsdetails {
  String giftname;
  String path;
  int price;
  Giftsdetails({required this.giftname, required this.path, required this.price});
}

class GiftsPage extends StatefulWidget {
  GiftsPage({Key? key});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  List<Giftsdetails> users = [];
  late List<GiftsModel> giftslist = [];
  late List<GiftsModel> myGifts = [];

  @override
  void initState() {
    super.initState();
    fetchGifts();
    fetchMyGifts();
  }

  Future<void> fetchGifts() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString('token');
      var response = await http.get(Uri.parse("${AppUrls.production}/api/getgifts"),headers: {'Authorization': 'Bearer $token'},);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> giftsList = jsonResponse['data'];
          List<GiftsModel> gifts = giftsList.map((item) => GiftsModel.fromJson(item)).toList();
          setState(() {
            giftslist = gifts;
          });
        }
      } else {
        print("Failed to fetch gifts: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching gifts: $error");
    }
  }

  Future<void> fetchMyGifts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString("id");
      String? token = prefs.getString("token");
      var response = await http.get(Uri.parse("${AppUrls.production}/api/getusergifts/$id"),headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> giftsList = jsonResponse['data'];
          List<GiftsModel> gifts = giftsList.map((item) => GiftsModel.fromJson(item)).toList();
          setState(() {
            myGifts = gifts;
          });
        }
      } else {
        print("Failed to fetch user gifts: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching user gifts: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: 'Gifts Shop',
        background: AppColors.background,
        actions: [
          TextButton(onPressed: (){
            Navigator.of(context).pushNamed('/withdraw');
          }, child: Text("withdraw",style: TextStyle(color: Colors.amber),))
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          if (myGifts.isNotEmpty)
            Text(
              "Your Gifts(${myGifts.length})",
              style: AppText.subtitle1,
            ),
          SizedBox(
            height: 150,
            child: Column(
              children: [
                if (myGifts.isEmpty)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "You have no gifts",
                        style: AppText.subtitle2,
                      ),
                      ElevatedButton(
                        onPressed: fetchMyGifts,
                        child: Text('Reload', style: AppText.subtitle3),
                      )
                    ],
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        var gift = myGifts[index];
                        return GestureDetector(
                          onTap: () {},
                          child: Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(
                                  gift.image ?? "",
                                  height: 100,
                                  width: 100,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      gift.quantity.toString() ?? "",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 10,),
                                    Text(
                                      gift.name ?? "",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      itemCount: myGifts.length,
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(width: 24);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Gifts Shop",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (giftslist.isNotEmpty)
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  var gift = giftslist[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.lighter,
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                            child: Image.network(
                              gift.image ?? "",
                              height: 100,
                              width: 100,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gift.name ?? "",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${gift.quantity}@USh ${gift.value}",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Buy(giftName: gift),
                                ),
                              );
                            },
                            child: Text(
                              "Buy",
                              style: TextStyle(color: Colors.black),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: giftslist.length,
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(width: 24);
                },
              ),
            ),
          if (giftslist.isEmpty) Text("No items found")
        ],
      ),
    );
  }
}
