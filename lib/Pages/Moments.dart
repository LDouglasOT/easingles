import 'dart:convert';
import 'dart:io';
import 'package:bottom_sheet_scaffold/bottom_sheet_scaffold.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:flutter_toastify/components/enums.dart';
import 'package:flutter_toastify/flutter_toastify.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easingles/Components/PostItems.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Models/GiftsMode.dart';
import 'package:easingles/Pages/ChatScreen.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:http/http.dart' as http;
import 'package:like_button/like_button.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easingles/Provider/SocketProvider.dart';

class Moments extends StatefulWidget {
  Moments({Key? key}) : super(key: key);

  @override
  State<Moments> createState() => _MomentsState();
}

class _MomentsState extends State<Moments> {
  bool showprofile = false;
  bool showloader = true;
  dynamic recieverId = {"userId": "0", "Names": "None", "profile": "None"};
  List<dynamic> moments = [];

  didChangeDependencies() {
    super.didChangeDependencies();
    getmoments();
    fetchMyGifts();
  }

  List<File?> _selectedImages = [];
  late List<GiftsModel> myGifts = [];
  bool giftLoaderStatus = true;

  void getmoments() async {
    setState(() {
      showprofile = false;
      showloader = true;
    });

    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token= pref.getString('token');
    var skip = await pref.getInt('skip');

    var response =
        await http.get(Uri.parse('${AppUrls.production}/api/moments/0'),headers: {'Authorization': 'Bearer $token'},);

    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          final List<dynamic> mmt = jsonResponse['data'];
          for (var m in mmt) {
            print(m['FirstName']);
            print("total length ${mmt.length}");
            moments.add(m);
          }
          setState(() {
            showprofile = true;
            showloader = false;
          });
        }
        break;
      default:
    }
  }

  void onLikeButtonTapped(bool isLiked, userid) async {
    try {
      print("detected tapp event");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString('id');
      String? token = prefs.getString("token");
      var response = await http.post(
        Uri.parse('${AppUrls.production}/api/likemoment'),
        headers: {'Authorization': 'Bearer $token'},
        body: {"likedId": id!, "momentLiked": userid},
      );
    } catch (e) {
      print(e);
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

  Future<bool?> checkIfLiked(bool isLiked) async {
    return await !isLiked;
  }

  void sendGift(GiftsModel gift, String reciever, String Recievername) async {
    setState(() {
      giftLoaderStatus = false;
    });
    try{
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? currentUser = pref.getString("id");
    String? token = pref.getString("token");
    var body = {
      "myid": currentUser,
      "user": recieverId['userId'],
      "img": gift.image,
      "name": gift.name,
      "qty": "1",
      "conversationId": "NONE",
      "momentId":recieverId['momentId']
    };

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
              'You have gifted 1 ${gift.name} to ${Recievername}',
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
            message: 'Insufficient 1 ${gift.name} to gift ${recieverId['Names']}',
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
            contentType: ContentType.success,
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
            contentType: ContentType.success,
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
       setState(() {
      giftLoaderStatus = true;
    });
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
                                  onPressed: () => {
                                 

                                    sendGift(gift, moments[0]['owenId'].toString(),
                                        moments[0]['FirstName'] ?? "")
                                  },
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
                        return SizedBox(
                          width: 24,
                        );
                      },
                    ),
                  ),
              ],
            ),
          )),
      appBar: Toolbar(
        title: "Moments",
        background: AppColors.background,
        actions: [
          TextButton(
            onPressed: () {
              // Show the bottom sheet to post a new moment
              Navigator.of(context).pushNamed('/newmoment');
            },
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Post a moment",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: showloader,
            child: Center(
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
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(255, 255, 255, 255),
                          ],
                          strokeWidth: 2,
                          pathBackgroundColor: Colors.black,
                        ),
                      ),
                      Text("Loading more, please wait"),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Visibility(
              visible: showprofile,
              child: ListView.separated(
                itemBuilder: (context, index) {
                  var singleMoment = moments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.lighter,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      singleMoment["imageTwo"] ?? ""),
                                ),
                              ),
                              SizedBox(width: 10),
                              Row(
                                children: [
                                  Text(singleMoment['FirstName'] ?? "",
                                      style: AppText.subtitle3),
                                  const SizedBox(width: 5),
                                  Text(singleMoment['LastName'] ?? "",
                                      style: AppText.subtitle3),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                singleMoment['TagLine'] ?? "",
                                style: AppText.subtitle3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            height: 400,
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              child: Image.network(
                                singleMoment['imageOne'] ?? "",
                                height: 400,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    LikeButton(
                                      onTap: (isLiked) async {
                                        checkIfLiked(isLiked);
                                        onLikeButtonTapped(isLiked,
                                            singleMoment['id'].toString());
                                        return !isLiked;
                                      },
                                      size: 20,
                                      circleColor: CircleColor(
                                        start: Color(0xff00ddff),
                                        end: Color(0xff0099cc),
                                      ),
                                      bubblesColor: BubblesColor(
                                        dotPrimaryColor: Color(0xff33b5e5),
                                        dotSecondaryColor: Color(0xff0099cc),
                                      ),
                                      likeBuilder: (bool isLiked) {
                                        return Icon(
                                          Icons.favorite,
                                          color: isLiked
                                              ? Colors.pink
                                              : Colors.grey,
                                          size: 20,
                                        );
                                      },
                                      likeCount: singleMoment['Likes'] ?? 0,
                                      countBuilder: (int? count, bool isLiked,
                                          String text) {
                                        var color =
                                            isLiked ? Colors.pink : Colors.grey;
                                        Widget result;
                                        if (count == 0 || count == null) {
                                          result = Text(
                                            "love",
                                            style: TextStyle(color: color),
                                          );
                                        } else {
                                          result = Text(
                                            text,
                                            style: TextStyle(color: color),
                                          );
                                        }
                                        return result;
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      onPressed: () async {
                                        SharedPreferences pref =
                                            await SharedPreferences
                                                .getInstance();
                                        String id = pref.getString("id") ?? "0";
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(
                                          builder: (context) => FirebaseChatScreen(
                                              // valueToPass:
                                              //     " ${singleMoment['id'].toString()}",
                                              // names:
                                              //     "${singleMoment['FirstName']} ${singleMoment['LastName']}",
                                              // profile: singleMoment['imageTwo']
                                              //         .toString() ??
                                              //     "",
                                              // userId: id,
                                              // username: "You",
                                              // socket: context
                                              //     .read<SocketProvider>()
                                              //     .socket, 
                                                  otherUserId: '', otherUserName: '', otherUserProfile: '', currentUserId: '', currentUserName: '',),
                                        ));
                                      },
                                      icon: const Icon(Icons.comment),
                                    ),
                                    const SizedBox(width: 10),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            if (BottomSheetPanel.isOpen) {
                                               setState(() {
                                                recieverId = {};
                                              });
                                              
                                              BottomSheetPanel.close();
                                              getmoments();
                                            } else {
                                              setState(() {
                                                recieverId = {
                                                  "userId": singleMoment['owenId']
                                                      .toString(),
                                                  "Names": singleMoment['FirstName']
                                                          .toString() +
                                                      " " +
                                                      singleMoment['LastName']
                                                          .toString(),
                                                  "profile": singleMoment['imageTwo']
                                                      .toString(),
                                                  "momentId":singleMoment['id'].toString()
                                                };
                                              });
                                              BottomSheetPanel.open();
                                            }
                                            ;
                                          },
                                          icon: const Icon(
                                              Icons.card_giftcard_outlined),
                                        ),
                                        Text(singleMoment['totalgifts'].toString(),style: TextStyle(
                                          color: Colors.amber,
                                        ),)
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: moments.length,
                separatorBuilder: (BuildContext context, int index) {
                  return SizedBox(
                    height: 24,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
