import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/Models/Authmodel.dart';
import 'package:mazale/Models/GiftsMode.dart';
import 'package:mazale/Pages/Buy.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Gifts {
  int id;
  String name;
  String image;
  int value;

  Gifts({required this.id, required this.name, required this.image, required this.value});

  factory Gifts.fromJson(Map<String, dynamic> json) {
    return Gifts(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Gift',
      image: json['image'] ?? '',
      value: json['value'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'image': image, 'value': value,
  };
}

class UserGifts {
  int id;
  int userId; // "user": 3 in your JSON
  int giftId; // "gift": 1 in your JSON
  int quantity;
  Gifts giftDetails; // Changed from 'gifts' to 'giftDetails'
  DateTime purchasedAt;

  UserGifts({
    required this.id,
    required this.userId,
    required this.giftId,
    required this.quantity,
    required this.giftDetails,
    required this.purchasedAt,
  });

  factory UserGifts.fromJson(Map<String, dynamic> json) {
    return UserGifts(
      id: json['id'] ?? 0,
      userId: json['user'] ?? 0,
      giftId: json['gift'] ?? 0,
      quantity: json['quantity'] ?? 0,
      // FIX: Use 'gift_details' instead of 'gifts'
      giftDetails: json['gift_details'] != null 
          ? Gifts.fromJson(json['gift_details']) 
          : Gifts(id: 0, name: 'Missing', image: '', value: 0),
      purchasedAt: json['purchased_at'] != null 
          ? DateTime.parse(json['purchased_at']) 
          : DateTime.now(),
    );
  }
}


class GiftsPage extends StatefulWidget {
  GiftsPage({Key? key});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> with SingleTickerProviderStateMixin {
  late List<Gifts> giftslist = [];
  late List<UserGifts> myGifts = [];
  bool isLoadingGifts = true;
  bool isLoadingMyGifts = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    fetchGifts();
    fetchMyGifts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> fetchGifts() async {
    setState(() {
      isLoadingGifts = true;
    });
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString('token');
      var response = await http.get(
        Uri.parse("${AppUrls.production}/api/gifts"),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(response.body);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          giftslist = (data as List).map((e) => Gifts.fromJson(e)).toList();
          isLoadingGifts = false;
        });
        print(giftslist);
      } 
    } catch (error) {
      print("Error fetching gifts: $error");
      setState(() {
        isLoadingGifts = false;
      });
    }
  }

  Future<void> fetchMyGifts() async {
    setState(() {
      isLoadingMyGifts = true;
    });
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString('token');
      var response = await http.get(
        Uri.parse("${AppUrls.production}/api/user-gifts"),
        headers: {'Authorization': 'Bearer $token'},
      );
      print("My user object gifts response:");
      print(response.body);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          myGifts = (data as List).map((e) => UserGifts.fromJson(e)).toList();
          isLoadingMyGifts = false;
        });
        print(myGifts);
      } 
    } catch (error) {
      print("Error fetching gifts: $error");
      setState(() {
        isLoadingMyGifts = false;
      });
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
        title: '🎁 Gift Shop',
        background: AppColors.background,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/withdraw');
              },
              icon: Icon(Icons.wallet, color: Colors.amber, size: 18),
              label: Text(
                "Withdraw",
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.amber.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.background.withOpacity(0.8),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([fetchGifts(), fetchMyGifts()]);
          },
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // My Gifts Section
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purple.withOpacity(0.3),
                        Colors.blue.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
                              SizedBox(width: 8),
                              Text(
                                "Your Collection",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (!isLoadingMyGifts && myGifts.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${myGifts.length}",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        height: 130,
                        child: isLoadingMyGifts
                            ? _buildShimmerLoader(3)
                            : myGifts.isEmpty
                                ? _buildEmptyMyGifts()
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemBuilder: (context, index) {
                                      var gift = myGifts[index];
                                      return _buildMyGiftCard(gift);
                                    },
                                    itemCount: myGifts.length,
                                    separatorBuilder: (context, index) => SizedBox(width: 12),
                                  ),
                      ),
                    ],
                  ),
                ),

                // Shop Section Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.store, color: Colors.amber, size: 24),
                              SizedBox(width: 8),
                              Text(
                                "Gift Shop",
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Send joy with special gifts",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      if (!isLoadingGifts)
                        ScaleTransition(
                          scale: Tween(begin: 0.95, end: 1.05).animate(
                            CurvedAnimation(
                              parent: _pulseController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.amber, Colors.orange],
                              ),
                            ),
                            child: Icon(Icons.local_fire_department, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),

                // Gifts Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isLoadingGifts
                      ? _buildGiftsShimmerLoader()
                      : giftslist.isEmpty
                          ? _buildEmptyGiftsShop()
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                var gift = giftslist[index];
                                return _buildGiftCard(gift, index);
                              },
                              itemCount: giftslist.length,
                              separatorBuilder: (context, index) => SizedBox(height: 12),
                            ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildMyGiftCard(UserGifts userGift) {
  // Extract the actual gift data from the details object
  final giftInfo = userGift.giftDetails;

  return Container(
    width: 110,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                giftInfo.image, // Use nested info
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                child: Text(
                  "${userGift.quantity}", // Quantity is in UserGifts
                  style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          giftInfo.name, // Use nested info
          style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}


  Widget _buildGiftCard(Gifts gift, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.lighter,
                    AppColors.lighter.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Buy(giftName: gift),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Gift Image with highlight
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              gift.image ?? "",
                              height: 90,
                              width: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        // Gift Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gift.name ?? "",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.sell, color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    "UGX ${gift.value}",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 14),
                                  Icon(Icons.star, color: Colors.amber, size: 14),
                                  Icon(Icons.star, color: Colors.amber, size: 14),
                                  Icon(Icons.star, color: Colors.amber, size: 14),
                                  Icon(Icons.star_half, color: Colors.amber, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "4.5",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Buy Button
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Buy(giftName: gift),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shopping_bag, color: Colors.black, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  "Buy",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyMyGifts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_outlined, size: 40, color: Colors.white38),
          SizedBox(height: 8),
          Text(
            "No gifts yet",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Start shopping below!",
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGiftsShop() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.storefront_outlined, size: 60, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            "No gifts available",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: fetchGifts,
            icon: Icon(Icons.refresh),
            label: Text('Reload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(int count) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: count,
      separatorBuilder: (context, index) => SizedBox(width: 12),
      itemBuilder: (context, index) {
        return Container(
          width: 110,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGiftsShimmerLoader() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 114,
          decoration: BoxDecoration(
            color: AppColors.lighter,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 20,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Container(
                height: 44,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}