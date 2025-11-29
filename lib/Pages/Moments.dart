import 'dart:convert';
import 'dart:io';
import 'package:bottom_sheet_scaffold/bottom_sheet_scaffold.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet_scaffold.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:flutter_toastify/components/enums.dart';
import 'package:flutter_toastify/flutter_toastify.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:like_button/like_button.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';



class AppText {
  static const TextStyle title = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.fontColor);
  static const TextStyle subtitle1 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.fontColor);
  static const TextStyle subtitle2 = TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.fontColor);
  static const TextStyle subtitle3 = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.disableFont);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.fontColor);
}

class GiftsModel {
  final String? image;
  final String? name;
  final int? quantity;
  GiftsModel.fromJson(Map<String, dynamic> json)
      : image = json['image'],
        name = json['name'],
        quantity = json['quantity'];
}

class Toolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color background;
  final List<Widget>? actions;
  const Toolbar({required this.title, required this.background, this.actions, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: AppText.title.copyWith(color: AppColors.primary)),
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class FirebaseChatScreen extends StatelessWidget {
  const FirebaseChatScreen({
    super.key,
    required String otherUserId,
    required String otherUserName,
    required String otherUserProfile,
    required String currentUserId,
    required String currentUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(child: Text('Chat Screen Placeholder')),
    );
  }
}


class Moments extends StatefulWidget {
  const Moments({Key? key}) : super(key: key);

  @override
  State<Moments> createState() => _MomentsState();
}

class _MomentsState extends State<Moments> {
  bool showprofile = false;
  bool showloader = true;
  dynamic recieverId = {"userId": "0", "Names": "None", "profile": "None"};
  List<dynamic> moments = [];
  late List<GiftsModel> myGifts = [];
  bool giftLoaderStatus = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getmoments();
      fetchMyGifts();
    });
  }

  void getmoments() async {
    setState(() {
      moments = [ ];
      showprofile = true;
      showloader = false;
    });
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
            return gifts;
          } else {
            return [];
          }
          break;
        default:
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


  Widget _buildMomentPost(dynamic singleMoment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lighter,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.background.withOpacity(0.8),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    backgroundImage: NetworkImage(
                        singleMoment["imageTwo"] ?? "https://via.placeholder.com/150"),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${singleMoment['FirstName'] ?? ""} ${singleMoment['LastName'] ?? ""}",
                        style: AppText.subtitle2.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        "Just now",
                        style: AppText.subtitle3,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                singleMoment['TagLine'] ?? "",
                style: AppText.body,
              ),
            ),

            SizedBox(
              height: 400,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  singleMoment['imageOne'] ?? "https://via.placeholder.com/400",
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                        strokeWidth: 2.0,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image, size: 50, color: AppColors.disableFont)),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      LikeButton(
                        onTap: (isLiked) async {
                          onLikeButtonTapped(isLiked, singleMoment['id'].toString());
                          return !isLiked;
                        },
                        size: 24,
                        circleColor: const CircleColor(start: Colors.pink, end: AppColors.primary),
                        bubblesColor: const BubblesColor(
                          dotPrimaryColor: Colors.pinkAccent,
                          dotSecondaryColor: Colors.red,
                        ),
                        likeBuilder: (bool isLiked) {
                          return Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.pinkAccent : AppColors.disableFont,
                            size: 24,
                          );
                        },
                        likeCount: singleMoment['Likes'] ?? 0,
                        countBuilder: (int? count, bool isLiked, String text) {
                          return Text(
                            count == 0 || count == null ? "Love" : text,
                            style: AppText.body.copyWith(color: isLiked ? Colors.pinkAccent : AppColors.disableFont),
                          );
                        },
                      ),
                    ],
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const FirebaseChatScreen(
                          otherUserId: '', otherUserName: '', otherUserProfile: '', currentUserId: '', currentUserName: '',
                        ),
                      ));
                    },
                    icon: const Icon(Icons.comment_outlined, color: AppColors.disableFont),
                  ),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (BottomSheetPanel.isOpen) {
                            setState(() {
                              recieverId = {};
                            });
                            BottomSheetPanel.close();
                          } else {
                            setState(() {
                              recieverId = {
                                "userId": singleMoment['owenId'].toString(),
                                "Names":
                                    "${singleMoment['FirstName'].toString()} ${singleMoment['LastName'].toString()}",
                                "profile": singleMoment['imageTwo'].toString(),
                                "momentId": singleMoment['id'].toString()
                              };
                            });
                            BottomSheetPanel.open();
                          }
                        },
                        icon: const Icon(Icons.card_giftcard, color: AppColors.primary),
                      ),
                      Text(
                        singleMoment['totalgifts'].toString(),
                        style: AppText.body.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DraggableBottomSheet _buildGiftBottomSheet() {
    return DraggableBottomSheet(
      animationDuration: const Duration(milliseconds: 300),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.lighter,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        width: double.infinity,
        padding: const EdgeInsets.only(top: 24, bottom: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Send a Gift to ${recieverId['Names'] ?? 'User'}",
                style: AppText.subtitle1.copyWith(color: AppColors.primary),
              ),
            ),
            const Divider(color: AppColors.background, height: 24, thickness: 2),
            if (myGifts.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    var gift = myGifts[index];
                    bool canSend = (gift.quantity ?? 0) > 0;

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  gift.image ?? "",
                                  height: 60,
                                  width: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gift.name ?? "",
                                    style: AppText.subtitle2.copyWith(color: AppColors.fontColor, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "Qty: ${gift.quantity ?? 0} left",
                                    style: AppText.body.copyWith(color: AppColors.disableFont),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 80,
                            child: ElevatedButton(
                              onPressed: canSend && giftLoaderStatus
                                  ? () {
                                      sendGift(gift, recieverId['userId'].toString(), recieverId['Names'] ?? "");
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canSend ? AppColors.primary : AppColors.disableButton,
                                foregroundColor: AppColors.fontColor2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                              child: giftLoaderStatus
                                  ? Text(
                                      canSend ? "Send" : "Empty",
                                      style: AppText.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.fontColor2),
                                    )
                                  : Center(
                                      child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.fontColor2,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  itemCount: myGifts.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 12);
                  },
                ),
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    "You have no gifts available to send.",
                    style: AppText.body.copyWith(color: AppColors.disableFont),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      bottomSheet: _buildGiftBottomSheet(),
      appBar: Toolbar(
        title: "Moments",
        background: AppColors.background,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {
                 Navigator.of(context).pushNamed('/newmoment');
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                "Post a moment",
                style: AppText.body.copyWith(color: AppColors.fontColor2, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            Visibility(
              visible: showloader,
              child: Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: LoadingIndicator(
                          indicatorType: Indicator.ballRotateChase,
                          colors: const [AppColors.primary, AppColors.fontColor, AppColors.lighter],
                          strokeWidth: 2,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text("Loading moments, please wait...", style: AppText.body.copyWith(color: AppColors.fontColor)),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: Visibility(
                visible: showprofile && moments.isNotEmpty,
                replacement: Visibility(
                  visible: showprofile && moments.isEmpty,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Text("No moments to display yet. Post your first!", style: AppText.body.copyWith(color: AppColors.disableFont)),
                    ),
                  ),
                ),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemBuilder: (context, index) {
                    return _buildMomentPost(moments[index]);
                  },
                  itemCount: moments.length,
                  separatorBuilder: (BuildContext context, int index) {
                    return const SizedBox(height: 24);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}