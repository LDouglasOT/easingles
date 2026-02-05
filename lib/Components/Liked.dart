import 'package:mazale/Pages/Moments.dart';
import 'package:flutter/material.dart';
import 'package:mazale/Pages/ChatScreen.dart';
import 'package:mazale/Pages/Profilepage.dart';
import 'package:mazale/Pages/Userprofile.dart';
import 'package:mazale/Provider/SocketProvider.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/Models/Authmodel.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

// Placeholder image URL for invalid/missing profile pics
const String _kPlaceholderImage = 'https://img.icons8.com/deco/48/no-camera.png';

class Liked extends StatefulWidget {
  final List<DjangoAuthUser> likes;
  final String name;
  final String userId;
  final List<String>? matchIds;

  const Liked(
      {Key? key, required this.likes, required this.name, required this.userId, this.matchIds})
      : super(key: key);

  @override
  State<Liked> createState() =>
      _LikedState(likes: likes, name: name, userId: userId);
}

class _LikedState extends State<Liked> with SingleTickerProviderStateMixin {
  final List<DjangoAuthUser> likes;
  final String name;
  final String userId;
  final List<String>? matchIds;
  late AnimationController _animationController;

  _LikedState({required this.likes, required this.name, required this.userId, this.matchIds});

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> markMatchSeen(String matchId) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');
    var response = await http.post(
      Uri.parse('${AppUrls.production}/api/matches/$matchId/mark-seen/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    // Optionally handle response
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lighter,
      body: likes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      name == "Matches"
                          ? Icons.favorite_border
                          : name == "Liked By"
                              ? Icons.visibility_outlined
                              : Icons.thumb_up_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No $name Yet",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      name == "Matches"
                          ? "Start swiping to find your perfect match!"
                          : name == "Liked By"
                              ? "People who like you will appear here"
                              : "Profiles you like will appear here",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: likes.length,
              itemBuilder: (BuildContext context, int index) {
                var like = likes[index];
                return FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        (index / likes.length) * 0.5,
                        ((index + 1) / likes.length) * 0.5 + 0.5,
                        curve: Curves.easeOut,
                      ),
                    ),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          (index / likes.length) * 0.5,
                          ((index + 1) / likes.length) * 0.5 + 0.5,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () => {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  Userprofile(userId: like.id.toString())))
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => Userprofile(
                                          userId: like.id.toString())))
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Profile Image with gradient border
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF6B9D),
                                              Color(0xFFFFA06B)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                like.profilePic?.isNotEmpty == true 
                                                    ? like.profilePic! 
                                                    : _kPlaceholderImage,
                                                height: 100,
                                                width: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Image.network(_kPlaceholderImage, height: 100, width: 100, fit: BoxFit.cover),
                                              ),
                                            ),
                                            // Online indicator
                                            if (like.online)
                                              Positioned(
                                                bottom: 4,
                                                right: 4,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Container(
                                                    width: 12,
                                                    height: 12,
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF00FF08),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // User Info
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${like.firstName} ${like.lastName}",
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: like.online
                                                        ? const Color(0xFF00FF08)
                                                        : Colors.grey[400],
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  like.online
                                                      ? "Online"
                                                      : "Offline",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: like.online
                                                        ? const Color(0xFF00FF08)
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                       
                                            if (name == "Matches")
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [
                                                      Color(0xFFFF6B9D),
                                                      Color(0xFFFFA06B)
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.favorite,
                                                      size: 12,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      "Match",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Message Button
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF6B9D),
                                              Color(0xFFFFA06B)
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF6B9D)
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () async {
                                              if (name == "Matches" && matchIds != null) {
                                                await markMatchSeen(matchIds![index]);
                                              }
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) => ChatScreen(
                                                    valueToPass: like.id.toString(),
                                                    profile: like.profilePic ?? "",
                                                    names: '${like.firstName} ${like.lastName}',
                                                    userId: userId,
                                                    username: '',
                                                  ),
                                                ),
                                              );
                                            },
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Icon(
                                                Icons.chat_bubble_outline,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
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
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
