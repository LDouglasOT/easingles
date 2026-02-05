import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/Models/GiftsMode.dart';
import 'package:mazale/Pages/Buy.dart';
import 'package:mazale/Pages/Confirmwithdraw.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Giftsdetails {
  String giftname;
  String path;
  int price;
  Giftsdetails({required this.giftname, required this.path, required this.price});
}

class Withdraw extends StatefulWidget {
  Withdraw({Key? key});

  @override
  State<Withdraw> createState() => _WithdrawState();
}

class _WithdrawState extends State<Withdraw> {
  List<Giftsdetails> users = [];

  late List<GiftsModel> myGifts = [];

  @override
  void initState() {
    super.initState();
    fetchMyGifts();
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
  
  void withdraw_gifts(){
    try{
      
    }catch(err){

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
        title: 'Gifts Withdraw',
        background: AppColors.background,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          if (myGifts.isNotEmpty)
            Text(
              "Your Gifts(${myGifts.length})",
              style: AppText.subtitle1,
            ),
         const Text(
            "Your Gifts",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),


          const SizedBox(height: 10),
          if (myGifts.isNotEmpty)
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemBuilder: (context, index) {
                  var gift = myGifts[index];
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
                                "${gift.quantity} USh ${gift.value!*(gift.quantity ?? 0)}",
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
                                  builder: (context) => Confirmwithdraw(giftName: gift),
                                ),
                              );
                            },
                            child: Text(
                              "redeem",
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
                itemCount: myGifts.length,
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(width: 24);
                },
              ),
            ),
          if (myGifts.isEmpty) Text("No gifts found")
        ],
      ),
    );
  }
}
