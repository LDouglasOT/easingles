import 'dart:convert';
import 'dart:math';
import 'package:bottom_sheet_scaffold/bottom_sheet_scaffold.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:flutter_toastify/components/enums.dart';
import 'package:flutter_toastify/flutter_toastify.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Models/GiftsMode.dart';
import 'package:easingles/Models/models.dart';
import 'package:easingles/Pages/ChatScreen.dart';
import 'package:easingles/Pages/Profilepage.dart';
import 'package:easingles/Pages/Userprofile.dart';
import 'package:easingles/Provider/SocketProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:http/http.dart' as http;
import 'package:loading_indicator/loading_indicator.dart';
import 'package:optimized_image_loader/optimized_image_loader.dart';

class Content {
  final String text;
  final Color color;

  Content({required this.text, required this.color});
}

enum interoptions { Like, Nope, Superlike }

class Dating extends StatefulWidget {
  const Dating({Key? key}) : super(key: key);

  @override
  _DatingState createState() => _DatingState();
}

class _DatingState extends State<Dating> {
  MatchEngine _matchEngine = MatchEngine();
  bool showprofile = false;
  bool showloader = true;
  bool showReloadButton = false;
  late String userId;
  late String username;
  late userlist currentUser;

  dynamic recieverId = {"userId": "0", "Names": "None", "profile": "None"};

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  List<SwipeItem> _swipeItems = [];
  List<userlist> allcards = [];
  List<String> _names = ["Red", "Blue", "Green", "Yellow", "Orange"];
  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
  ];

  final List<Color> _newColors = [
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.brown,
    const Color.fromRGBO(63, 81, 181, 1),
  ];

  String calculateAge(String birthDateString) {
    DateTime currentDate = DateTime.now();
    DateTime birthDate = DateTime.parse(birthDateString);
    int age = currentDate.year - birthDate.year;

    // Check if the birthday has occurred this year
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }

    return age.toString();
  }

  @override
  void initState() {
    super.initState();

    _loadMoreItems();
    fetchMyGifts();
  }

  late List<GiftsModel> myGifts = [];
  bool giftLoaderStatus = true;
  Future<void> _loadMoreItems() async {
    // Make API call to http://10.0.2.2/api/matches

    setState(() {
      showprofile = false;
      showloader = true;
      showReloadButton = false;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? gender = prefs.getString("gender");
      String? id = prefs.getString("id");
      userId = id ?? "0";
      username = prefs.getString("username") ?? "You";
      String? token = prefs.getString("token");
      var response = await http.post(
          Uri.parse('${AppUrls.production}/api/matches'),
          headers: {'Authorization': 'Bearer $token'},
          body: {"id": id});
      if (response.statusCode == 200) {
        // Parse the API response
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Check if the 'data' field exists and is a list
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          final List<dynamic> profiles = jsonResponse['data'];
          setState(() {
          allcards.clear();
          _swipeItems.clear();
          });
        
          for (var profile in profiles) {
            userlist user = userlist.fromJson(profile);

            allcards.add(user);
            _swipeItems.add(SwipeItem(
              content: Content(
                text: user.firstName,
                color: Colors.purple, // Set your color logic here
              ),
              likeAction: () async {
                // Handle like action without showing SnackBar
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? id = prefs.getString("id");
                String? token = prefs.getString('token');
                var response = await http
                    .post(Uri.parse('${AppUrls.production}/api/like'),headers: {'Authorization': 'Bearer $token'}, body: {
                  "userId": id.toString(),
                  "likedId": user.id.toString(),
                  "super": "0"
                });

                if (!(response.statusCode == 200)) {
                  var response = await http
                      .post(Uri.parse('${AppUrls.production}/api/like'),headers: {'Authorization': 'Bearer $token'}, body: {
                    "userId": id.toString(),
                    "likedId": user.id.toString(),
                    "super": "0"
                  });
                }
              },
              nopeAction: () {
                // Handle nope action without showing SnackBar
              },
              superlikeAction: () {
                // Handle superlike action without showing SnackBar
              },
            ));
          }
          setState((){
          currentUser = allcards[0];
          });
          
          _matchEngine = MatchEngine(swipeItems: _swipeItems);
          setState(() {
            showprofile = true;
            showloader = false;
            showReloadButton = false;
          });
        } else {}
      } else if (response.statusCode == 401) {
        // Handle API error
        setState(() {
          showloader = false;
          showprofile = false;
          showReloadButton = false;
        });
        print('API call failed with status code: ${response.statusCode}');
      }else if(response.statusCode == 201){
           setState(() {
          showloader = false;
          showprofile = false;
          showReloadButton = false;
        });
        Navigator.of(context).pushNamed("/purchase");
      }else {
        setState(() {
          showloader = false;
          showprofile = false;
          showReloadButton = true;
        });
      }
    } catch (err) {
      setState(() {
        showloader = false;
        showprofile = false;
        showReloadButton = true;
      });
    }
  }

  Future<List<GiftsModel>> fetchMyGifts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString("id");
      String? token = prefs.getString("token");
      var response = await http
          .get(Uri.parse("${AppUrls.production}/api/getusergifts/$id"),headers: {'Authorization': 'Bearer $token'});

      switch (response.statusCode) {
        case 200:
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          if (jsonResponse.containsKey('data') &&
              jsonResponse['data'] is List) {
            List<dynamic> giftsList = jsonResponse['data'];
            List<GiftsModel> gifts =
                giftsList.map((item) => GiftsModel.fromJson(item)).toList();
            myGifts.clear();
            setState(() {
              myGifts.addAll(gifts);
            });
            // You can return the gifts list or handle it in some way
            return gifts;
          } else {
            // Handle the case where the response does not contain a 'data' key or it's not a list
            return [];
          }
          break;
        default:
          // Handle other status codes if needed
          return [];
      }
    } catch (error) {
      return [];
    }
  }

  void sendGift(GiftsModel gift) async {
    try{

    setState(() {
      giftLoaderStatus = false;
    });
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? currentUsers = pref.getString("id");
    String? token=pref.getString("token");
    var body = {
      "myid": currentUsers ?? "0",
      "user": currentUser.id ?? "0",
      "img": gift.image,
      "name": gift.name,
      "qty": "1",
      "conversationId": "HOME",
      "momentId": currentUser.id 
    };
    print(body.toString());
    var response = await http.post(
      Uri.parse(
        '${AppUrls.production}/api/giftpeople',
      ),
      headers: {'Authorization': 'Bearer $token'},
      body: body,
    );
    switch (response.statusCode) {
      case 200:
        try {
          setState(() {
            giftLoaderStatus = true;
          });
          FlutterToastify.success(
            background: AppColors.background,
            width: 360,
            notificationPosition: NotificationPosition.topLeft,
            animation: AnimationType.fromTop,
            title: Container(
                child: Row(
              children: [
                Image.network(
                  gift.image ?? "",
                  height: 20,
                  width: 20,
                ),
                Text(
                  gift.name ?? "",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            )),
            description: Text(
              'You have gifted 1 ${gift.name} to ${recieverId['Names']}',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
            ),
            onDismiss: () {},
          ).show(context);
        } catch (e) {
          print(e.toString());
        }
        break;
      case 400:
        var snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: FlutterSnackbarContent(
            message:
                'Insufficient 1 ${gift.name} to gift ${recieverId['Names']}',
            contentType: ContentType.success,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        break;
      case 404:
        var snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: FlutterSnackbarContent(
            message: 'Insufficient ${gift.name} to ${recieverId['Names']}',
            contentType: ContentType.warning,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        setState(() {
          giftLoaderStatus = true;
        });
      case 500:
        var snackBar = const SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: FlutterSnackbarContent(
            message: 'Something went wrong',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        break;
      default:
        var snackBar = const SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: FlutterSnackbarContent(
            message: 'Something went wrong',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        setState(() {
          giftLoaderStatus = true;
        });
    }
    setState(() {
      giftLoaderStatus = true;
    });
      }catch(err){
      print(err.toString());
       var snackBar = const SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: FlutterSnackbarContent(
            message: 'Something went wrong',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      setState(() {
      giftLoaderStatus = true;
    });
    }
    fetchMyGifts();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      bottomSheet: DraggableBottomSheet(
          animationDuration: const Duration(milliseconds: 200),
          body: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
            ),
            width: double.infinity,
            height: 500,
            alignment: Alignment.center,
            child: Column(
              children: [
                IconButton(
                    onPressed: () {
                      BottomSheetPanel.close();
                    },
                    icon: Icon(Icons.arrow_drop_down)),
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
                              color: AppColors.background,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                  child: Image.network(
                                    gift.image ?? "",
                                    height: 100,
                                    width: 100,
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${gift.quantity}",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "${gift.name}s" ?? "",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "left",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => {sendGift(gift)},
                                  child: Column(
                                    children: [
                                      Visibility(
                                          visible: giftLoaderStatus,
                                          child: Text("send")),
                                      Visibility(
                                          visible: !giftLoaderStatus,
                                          child: CircularProgressIndicator(
                                            color: AppColors.lighter,
                                          )),
                                    ],
                                  ),
                                  style: ElevatedButton.styleFrom(
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
                        return SizedBox(
                          width: 24,
                        );
                      },
                    ),
                  ),
              ],
            ),
          )),
      key: _scaffoldKey,
      appBar: Toolbar(
        leading: IconButton(
          onPressed: () => {Navigator.of(context).pushNamed('/gifts')},
          icon: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                  color: AppColors.lighter,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(
                Icons.card_giftcard,
                size: 30,
              )),
          color: Colors.white,
        ),
        background: Colors.white,
        title: "YoDate",
        actions: [
          Stack(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                    color: AppColors.lighter,
                    borderRadius: BorderRadius.circular(8)),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/notifications');
                  },
                  icon: Icon(Icons.notifications, size: 30),
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: Container(
                  height:7,
                  width:7,
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    // Set the badge background color
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '', // Set your counter value here
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: 10,
          ),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
                color: AppColors.lighter,
                borderRadius: BorderRadius.circular(8)),
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pushNamed("/purchase");
              },
              icon: Icon(Icons.shopping_cart, size: 30),
              color: Colors.white,
            ),
          ),
          SizedBox(
            width: 10,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          child: Column(
            children: [
              Visibility(
                visible: showloader,
                child: Container(
                  height: 250,
                  child: Container(
                    height: 200,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 100,
                          child: LoadingIndicator(
                              indicatorType: Indicator.ballRotateChase,
                              colors: [
                                Color.fromARGB(255, 255, 255, 255),
                                Color.fromARGB(255, 255, 254, 252),
                                Color.fromARGB(255, 255, 255, 255),
                                Color.fromARGB(255, 255, 255, 255),
                                Color.fromARGB(255, 255, 255, 255),
                                Color.fromARGB(255, 255, 255, 255),
                              ],
                              strokeWidth: 2,
                              // backgroundColor: Colors.black,
                              pathBackgroundColor: Colors.black),
                        ),
                        Text("Loading more, please wait")
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: showprofile,
                child: Container(
                  height: MediaQuery.of(context).size.height *
                      0.6, // 60% of screen height
                  width: MediaQuery.of(context).size.width *
                      0.8, // 80% of screen width
                  child: SwipeCards(
                    matchEngine: _matchEngine,
                    itemBuilder: (BuildContext context, int index) {
                      // Ensure that index is within the bounds of _swipeItems
                      if (index >= 0 && index < _swipeItems.length) {
                        Content content = _swipeItems[index].content;
                        SwipeItem swipeitems = _swipeItems[index];
                        return Center(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height *
                                0.55, // 55% of screen height
                            width: MediaQuery.of(context).size.width *
                                0.7, // 70% of screen width
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              child: Stack(children: [
                                GestureDetector(
                                  onTap: () => {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) => Userprofile(
                                                userId: allcards[index]
                                                    .id
                                                    .toString())))
                                  },
                                  child: OptimizedImageLoader(
                                    url: allcards[index].profilePic ?? "",
                                    imageHeight:
                                        MediaQuery.of(context).size.height *
                                            0.55,
                                    imageWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                    spinnerHeight: 25,
                                    spinnerWidth: 25,
                                    loadingIndicator: Container(
                                      height:
                                          MediaQuery.of(context).size.height,
                                      width: MediaQuery.of(context).size.width,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                    errorContainerDecoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    errorContainerChild: Image.asset(
                                        "lib/assets/images/404.png"),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 16,
                                            color: Colors.lightGreen,
                                          ),
                                          Text(
                                            content.text,
                                            style: AppText.header3,
                                          ),
                                          Text(
                                            ', ',
                                            style: AppText.subtitle1,
                                          ),
                                          Text(
                                            calculateAge(allcards[index]
                                                .year
                                                .toString()),
                                            style: AppText.body1,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 15,
                                            color: Colors.lightGreen,
                                          ),
                                          Text(
                                            allcards[index].district ??
                                                "Uganda",
                                            style: AppText.body1,
                                          ),
                                        ],
                                      ),
                                      Row(children: [
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          context
                                                  .watch<SocketProvider>()
                                                  .userIds
                                                  .any((user) =>
                                                      user["userId"]
                                                          .toString() ==
                                                      allcards[index]
                                                          .id
                                                          .toString())
                                              ? "online"
                                              : "",
                                          style: TextStyle(
                                              color: context
                                                      .watch<SocketProvider>()
                                                      .userIds
                                                      .any((user) =>
                                                          user["userId"]
                                                              .toString() ==
                                                          allcards[index]
                                                              .id
                                                              .toString())
                                                  ? Colors.green
                                                  : Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ]),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (context) => FirebaseChatScreen(
                                            // valueToPass:
                                            //     " ${allcards[index].id.toString()}",
                                            // names:
                                            //     "${allcards[index].firstName} ${allcards[index].lastName}",
                                            // profile:
                                            //     allcards[index].profilePic ??
                                            //         "",
                                            // userId: userId,
                                            // username: username,
                                            // socket: context
                                            //     .read<SocketProvider>()
                                                // .socket,
                                                 otherUserId: '', otherUserName: '',otherUserProfile: '',currentUserId: '', currentUserName: '',),
                                      ));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors
                                          .lightGreen, // Set button background color to light green
                                    ),
                                    child: Icon(
                                      Icons
                                          .chat, // Use a chat icon instead of the generic message icon
                                      color: Colors
                                          .white, // Set icon color to white
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      } else {
                        // Handle index out of bounds, return an empty container or another widget
                        return Container();
                      }
                    },
                    onStackFinished: () {
                      _loadMoreItems();
                    },
                    itemChanged: (SwipeItem item, int index) {
                      setState(() {
                        currentUser = allcards[index];
                      });
                    },
                    upSwipeAllowed: true,
                    fillSpace: true,
                  ),
                ),
              ),
              Visibility(
                visible: showReloadButton,
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    Text("Something we wrong", style: AppText.header1),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Colors.amber)),
                      onPressed: () {
                        // Call _loadMoreItems again when reload button is pressed
                        _loadMoreItems();
                      },
                      child: Text(
                        'Reload',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _matchEngine.currentItem?.nope();
                    },
                    icon: Icon(Icons.thumb_down, size: 24),
                    label: Text(""),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      backgroundColor: Colors.red,
                    ),
                  ),
                  SizedBox(width: 10),
                  InkResponse(
                    onTap: () {
                      if (BottomSheetPanel.isOpen) {
                        setState(() {
                          recieverId = {};
                        });

                        BottomSheetPanel.close();
                      } else {
                        setState(() {
                          recieverId = {
                            "userId": currentUser.id.toString().toString(),
                            "Names": currentUser.firstName.toString() +
                                " " +
                                currentUser.lastName.toString(),
                            "profile": currentUser.profilePic.toString(),
                            "momentId": currentUser.country
                          };
                        });
                        BottomSheetPanel.open();
                      }
                      ;
                    },
                    radius: 10.0,
                    splashColor: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 4, 4, 4).withAlpha(255),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Icon(Icons.star, color: Colors.white, size: 24),
                    ),
                  ),
                  SizedBox(width: 15),
                  InkResponse(
                    onTap: () {
                      _matchEngine.currentItem?.like();
                    },
                    radius: 10.0,
                    splashColor:
                        Color.fromARGB(255, 80, 253, 41).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.lighter,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child:
                          Icon(Icons.thumb_up, color: Colors.white, size: 24),
                    ),
                  ),
                  SizedBox(width: 5),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class userlist {
  final String id;
  final String firstName;
  final String lastName;
  final String? day;
  final String? month;
  final String year;
  final String? country;
  final String? district;
  final String? village;
  final String profilePic;
  final String? online;
  final String gender;
  final String? hopes;
  final String? religion;
  final String? imgx;
  final String? imgxx;
  final String? imgxxx;
  final String? imgxxxx;
  final String? referalCode;
  final String loginId;
  final String contact;
  final String twitter;
  final String instagram;
  final String facebook;
  final String email;
  final String about;
  final bool promoted;
  final String subscription;
  final String endSubscription;
  final int totalShows;
  final String? promoterUrl;
  final List<String> userImages;

  userlist({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.day,
    this.month,
    required this.year,
    this.country,
    this.district,
    this.village,
    required this.profilePic,
    this.online,
    required this.gender,
    this.hopes,
    this.religion,
    this.imgx,
    this.imgxx,
    this.imgxxx,
    this.imgxxxx,
    this.referalCode,
    required this.loginId,
    required this.contact,
    required this.twitter,
    required this.instagram,
    required this.facebook,
    required this.email,
    required this.about,
    required this.promoted,
    required this.subscription,
    required this.endSubscription,
    required this.totalShows,
    this.promoterUrl,
    required this.userImages,
  });

  factory userlist.fromJson(Map<String, dynamic> json) {
    return userlist(
      id: json['id'].toString(),
      firstName: json['FirstName'],
      lastName: json['LastName'],
      day: json['day'],
      month: json['month'],
      year: json['year'],
      country: json['Country'],
      district: json['District'] ?? "Uganda",
      village: json['Village'],
      profilePic: json['Profilepic'],
      online: json['online'],
      gender: json['Gender'],
      hopes: json['hopes'],
      religion: json['religion'],
      imgx: json['imgx'],
      imgxx: json['imgxx'],
      imgxxx: json['imgxxx'],
      imgxxxx: json['imgxxxx'],
      referalCode: json['referalCode'],
      loginId: json['loginId'].toString(),
      contact: json['contact'],
      twitter: json['twitter'],
      instagram: json['instagram'],
      facebook: json['facebook'],
      email: json['email'],
      about: json['about'],
      promoted: json['promoted'],
      subscription: json['subscription'],
      endSubscription: json['endsubscription'],
      totalShows: json['totalshows'],
      promoterUrl: json['promoterurl'],
      userImages: List<String>.from(json['userImages'] ?? []),
    );
  }
}
