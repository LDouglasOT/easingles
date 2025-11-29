import 'package:flutter/material.dart';
import 'package:easingles/Pages/ChatScreen.dart';
import 'package:easingles/Provider/FirebaseChatProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:optimized_image_loader/optimized_image_loader.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chatpill extends StatelessWidget {
  String messages;
  String avatar;
  String names;
  String newvcount;
  bool status;
  String cuid;
  Chatpill(
      {super.key,
      required this.messages,
      required this.avatar,
      required this.names,
      required this.newvcount,
      required this.status,
      required this.cuid});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: GestureDetector(
        onTap: () async {
          SharedPreferences pref = await SharedPreferences.getInstance();
          String? currentUserId = pref.getString("id") ?? "0";
          String? currentUserName = pref.getString("name") ?? "You";

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FirebaseChatScreen(
                otherUserId: cuid,
                otherUserName: names,
                otherUserProfile: avatar,
                currentUserId: currentUserId,
                currentUserName: currentUserName,
              ),
            ),
          );
        },
        child: Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0),
            ),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            height: 55,
                            width: 55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(150),
                              child: OptimizedImageLoader(
                                url: avatar,
                                imageHeight: 100,
                                imageWidth: 100,
                                spinnerHeight: 35,
                                spinnerWidth: 35,
                                loadingIndicator: const LoadingIndicator(
                                  indicatorType: Indicator.lineScaleParty,
                                ),
                                errorContainerDecoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(150),
                                ),
                                errorContainerChild: Image.network(avatar),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(names,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    )),
                                Text(
                                  messages,
                                  style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 15,
                                      color:
                                          Color.fromARGB(255, 221, 221, 221)),
                                )
                              ]),
                        ),
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 15, 4),
                        child: Text(
                          context.watch<FirebaseChatProvider>().onlineUserIds.contains(cuid)
                              ? "online"
                              : "offline",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                        child: Container(
                            height: 23,
                            width: 23,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: AppColors.lighter,
                            ),
                            child: Center(
                                child: Text(
                              "${newvcount}${newvcount == "15" ? "+" : ""}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ))),
                      ),
                    ],
                  ),
                )
              ],
            )),
      ),
    );
  }
}
