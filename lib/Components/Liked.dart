import 'package:flutter/material.dart';
import 'package:easingles/Pages/ChatScreen.dart';
import 'package:easingles/Pages/Profilepage.dart';
import 'package:easingles/Pages/Userprofile.dart';
import 'package:easingles/Provider/SocketProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:provider/provider.dart';

class Liked extends StatefulWidget {
  final List<UserData> likes;
  final String name;
  final String userId;

  const Liked(
      {Key? key, required this.likes, required this.name, required this.userId})
      : super(key: key);

  @override
  State<Liked> createState() =>
      _LikedState(likes: likes, name: name, userId: userId);
}

class _LikedState extends State<Liked> {
  final List<UserData> likes;
  final String name;
  final String userId;

  _LikedState({required this.likes, required this.name, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (likes.isEmpty)
              Center(
                child: Text(
                  "No $name yet",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (likes.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: likes.length,
                itemBuilder: (BuildContext context, int index) {
                  var like = likes[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () => {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                Userprofile(userId: like.id.toString())))
                      },
                      child: Container(
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          color: AppColors.lighter,
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  like.profilePic ?? 'Unknown',
                                  height: 130,
                                  width: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${like.firstName} ${like.lastName}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 8,
                                        backgroundColor: context
                                                .watch<SocketProvider>()
                                                .userIds
                                                .any((user) =>
                                                    user["userId"].toString() ==
                                                    like.id)
                                            ? const Color.fromARGB(
                                                255, 0, 255, 8)
                                            : Color.fromARGB(255, 32, 32, 32),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        context
                                                .watch<SocketProvider>()
                                                .userIds
                                                .any((user) =>
                                                    user["userId"].toString() ==
                                                    like.id)
                                            ? "online"
                                            : "offline",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: context
                                                  .watch<SocketProvider>()
                                                  .userIds
                                                  .any((user) =>
                                                      user["userId"]
                                                          .toString() ==
                                                      like.id)
                                              ? const Color.fromARGB(
                                                  255, 0, 255, 8)
                                              : Color.fromARGB(255, 32, 32, 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => FirebaseChatScreen(otherUserId: '', otherUserName: '', otherUserProfile: '', currentUserId: '', currentUserName: '',
                                    // valueToPass: "${like.id}",
                                    // names: "${like.firstName} ${like.lastName}",
                                    // profile: like.profilePic ?? "",
                                    // userId: userId,
                                    // username: "You",
                                    // socket:
                                    //     context.read<SocketProvider>().socket,
                                  ),
                                ));
                              },
                              icon: Icon(Icons.sms_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
