import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mazale/Components/AppButton.dart';
import 'package:mazale/Components/Gallery.dart';
import 'package:mazale/Components/PostItems.dart';
import 'package:mazale/Components/Profile.dart';
import 'package:mazale/Components/Profile_images.dart';
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/Models/Authmodel.dart';
import 'package:mazale/Pages/Login_page.dart';
import 'package:mazale/Pages/Profilepage.dart';
import 'package:mazale/Pages/ChatScreen.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Popmenuaction {
  edit,
  logout,
}

class Userprofile extends StatefulWidget {
  final String userId;
  const Userprofile({super.key, required this.userId});

  @override
  State<Userprofile> createState() => _UserprofileState();
}

class _UserprofileState extends State<Userprofile> with SingleTickerProviderStateMixin {
  DjangoAuthUser? myProfile;
  List<MomentData> moments = [];
  bool isLoadingProfile = true;
  bool isLoadingMoments = true;
  String? profileError;
  String? momentsError;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      getProfile(),
      getMoments(),
    ]);
  }

  Future<void> getProfile() async {
    setState(() {
      isLoadingProfile = true;
      profileError = null;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      var url = Uri.parse("${AppUrls.production}/api/profile/${widget.userId}");
      var response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        DjangoAuthUser useritem = DjangoAuthUser.fromJson(jsonResponse);
        setState(() {
          myProfile = useritem;
          isLoadingProfile = false;
        });
      } else {
        setState(() {
          profileError = 'Failed to load profile';
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        profileError = 'Network error: ${e.toString()}';
        isLoadingProfile = false;
      });
    }
  }

  Future<void> getMoments() async {
    setState(() {
      isLoadingMoments = true;
      momentsError = null;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      var url = Uri.parse("${AppUrls.production}/api/personalmoments/${widget.userId}");
      var response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> moment = jsonResponse['data'];
        List<MomentData> momentstore = moment
            .map((m) => MomentData.fromJson(m))
            .toList();
        setState(() {
          moments = momentstore;
          isLoadingMoments = false;
        });
      } else {
        setState(() {
          momentsError = 'Failed to load moments';
          isLoadingMoments = false;
        });
      }
    } catch (e) {
      setState(() {
        momentsError = 'Network error: ${e.toString()}';
        isLoadingMoments = false;
      });
    }
  }

  Future<void> likeUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString("id");
      String? token = prefs.getString("token");
      
      var response = await http.post(
        Uri.parse('${AppUrls.production}/api/like'),
        headers: {'Authorization': 'Bearer $token'},
        body: {"userId": id.toString(), "likedId": widget.userId, "super": "0"},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liked! ❤️'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send like'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String calculateAge(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      DateTime birthDate = DateTime.parse(dateString);
      DateTime currentDate = DateTime.now();
      Duration ageDifference = currentDate.difference(birthDate);
      int ageInYears = (ageDifference.inDays / 365).floor();
      return ageInYears.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  // Helper method to parse user images
  List<String> getUserImages() {
    if (myProfile?.userImages == null) return [];
    
    if (myProfile!.userImages is List) {
      return (myProfile!.userImages as List)
          .map((e) => e.toString())
          .where((img) => img.isNotEmpty)
          .toList();
    } else if (myProfile!.userImages is String) {
      String imagesStr = myProfile!.userImages as String;
      if (imagesStr.isEmpty) return [];
      
      // Try to parse as JSON array
      try {
        List<dynamic> parsed = jsonDecode(imagesStr);
        return parsed.map((e) => e.toString()).where((img) => img.isNotEmpty).toList();
      } catch (e) {
        // If not JSON, treat as comma-separated string
        return imagesStr
            .split(',')
            .map((s) => s.trim())
            .where((img) => img.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  // Helper method to parse user interests
  List<String> getUserInterests() {
    if (myProfile?.userInterests == null) return [];
    
    if (myProfile!.userInterests is List) {
      return (myProfile!.userInterests as List)
          .map((e) => e.toString())
          .where((interest) => interest.isNotEmpty)
          .toList();
    } else if (myProfile!.userInterests is String) {
      String interestsStr = myProfile!.userInterests as String;
      if (interestsStr.isEmpty) return [];
      
      // Try to parse as JSON array
      try {
        List<dynamic> parsed = jsonDecode(interestsStr);
        return parsed.map((e) => e.toString()).where((interest) => interest.isNotEmpty).toList();
      } catch (e) {
        // If not JSON, treat as comma-separated string
        return interestsStr
            .split(',')
            .map((s) => s.trim())
            .where((interest) => interest.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  Widget _buildActionButton({
    required String emoji,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInterestChip(String interest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lighter.withOpacity(0.7),
            AppColors.lighter.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        interest.trim(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required Widget child,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppText.header3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            error,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userImages = getUserImages();
    final userInterests = getUserInterests();
    
    return Scaffold(
      appBar: Toolbar(
        title: myProfile != null ? "${myProfile!.firstName}'s Profile" : "Profile",
        background: const Color.fromARGB(255, 97, 119, 161),
        actions: [
          PopupMenuButton<Popmenuaction>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            onSelected: (value) async {
              switch (value) {
                case Popmenuaction.edit:
                  Navigator.of(context).pushNamed('/edit');
                  break;
                case Popmenuaction.logout:
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login_page()),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: Popmenuaction.edit,
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 10),
                    Text("Edit Profile"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: Popmenuaction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
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
              const Color(0xFF1a1a2e),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: Colors.amber,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  if (isLoadingProfile)
                    const Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(
                        color: Colors.amber,
                        strokeWidth: 3,
                      ),
                    )
                  else if (profileError != null)
                    _buildErrorWidget(profileError!, getProfile)
                  else if (myProfile != null)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          // Profile Picture with Glow Effect
                          Hero(
                            tag: 'profile_${widget.userId}',
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.amber.withOpacity(0.3),
                                    Colors.orange.withOpacity(0.3)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(70),
                                  child: Image.network(
                                    myProfile!.profilePic ?? '',
                                    height: 140,
                                    width: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      height: 140,
                                      width: 140,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.person,
                                        size: 70,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name and Age
                          Text(
                            "${myProfile!.firstName ?? 'Unknown'} ${myProfile!.lastName ?? ''}",
                            style: AppText.subtitle1.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.withOpacity(0.3),
                                  Colors.orange.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${calculateAge(myProfile!.day)} years old",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Bio - now using 'hopes' field
                          if (myProfile!.hopes != null && myProfile!.hopes!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Text(
                                myProfile!.hopes!,
                                style: AppText.body2.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Row(
                            children: [
                              _buildActionButton(
                                emoji: '❤️',
                                label: 'Like',
                                onPressed: likeUser,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              _buildActionButton(
                                emoji: '💬',
                                label: 'Message',
                                onPressed: () async {
                                  SharedPreferences prefs = await SharedPreferences.getInstance();
                                  String? currentUserId = prefs.getString('id') ?? '';
                                  String? currentUsername = prefs.getString('username') ?? '';
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        valueToPass: widget.userId,
                                        profile: myProfile?.profilePic ?? "",
                                        names: '${myProfile?.firstName ?? 'User'} ${myProfile?.lastName ?? ''}',
                                        userId: currentUserId,
                                        username: currentUsername,
                                      ),
                                    ),
                                  );
                                },
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              _buildActionButton(
                                emoji: '🎁',
                                label: 'Gift',
                                onPressed: () {},
                                color: Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Interests Section
                          if (userInterests.isNotEmpty)
                            _buildSectionContainer(
                              title: 'Interests',
                              gradientColors: [
                                AppColors.lighter.withOpacity(0.2),
                                AppColors.lighter.withOpacity(0.1),
                              ],
                              child: Wrap(
                                spacing: 10.0,
                                runSpacing: 10.0,
                                children: userInterests
                                    .map((interest) => _buildInterestChip(interest))
                                    .toList(),
                              ),
                            ),

                          // Gallery Section
                          if (userImages.isNotEmpty)
                            _buildSectionContainer(
                              title: "${myProfile!.firstName}'s Photos",
                              gradientColors: [
                                Colors.purple.withOpacity(0.2),
                                Colors.blue.withOpacity(0.2),
                              ],
                              child: Image_gallery(
                                listImages: [
                                  if (myProfile!.profilePic != null) myProfile!.profilePic!,
                                  ...userImages
                                ],
                              ),
                            ),

                          // Moments Section
                          if (isLoadingMoments)
                            const Padding(
                              padding: EdgeInsets.all(50.0),
                              child: CircularProgressIndicator(
                                color: Colors.amber,
                                strokeWidth: 3,
                              ),
                            )
                          else if (momentsError != null)
                            _buildErrorWidget(momentsError!, getMoments)
                          else
                            _buildSectionContainer(
                              title: "${moments.length} Recent Posts",
                              gradientColors: [
                                Colors.deepPurple.withOpacity(0.2),
                                Colors.indigo.withOpacity(0.2),
                              ],
                              child: moments.isNotEmpty
                                  ? Column(
                                      children: moments
                                          .map((mom) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 16),
                                                child: PostItem(user: mom),
                                              ))
                                          .toList(),
                                    )
                                  : const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(30.0),
                                        child: Text(
                                          "No moments posted yet.",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Data Models remain the same
class MomentData {
  int id;
  int likes;
  int ownerId;
  String hashTag;
  String tagLine;
  String imageOne;
  String imageTwo;
  String imageThree;
  String firstName;
  String lastName;
  DateTime date;
  List<CommentData> comments;

  MomentData({
    required this.id,
    required this.likes,
    required this.ownerId,
    required this.hashTag,
    required this.tagLine,
    required this.imageOne,
    required this.imageTwo,
    required this.imageThree,
    required this.firstName,
    required this.lastName,
    required this.date,
    required this.comments,
  });

  factory MomentData.fromJson(Map<String, dynamic> json) {
    List<CommentData> commentsList = [];
    if (json['comments'] != null) {
      for (var commentJson in json['comments']) {
        commentsList.add(CommentData.fromJson(commentJson));
      }
    }

    return MomentData(
      id: json['id'] as int,
      likes: json['Likes'] as int,
      ownerId: json['owenId'] as int,
      hashTag: json['HashTag'] as String,
      tagLine: json['TagLine'] as String,
      imageOne: json['imageOne'] as String,
      imageTwo: json['imageTwo'] as String,
      imageThree: json['imageThree'] as String,
      firstName: json['FirstName'] as String,
      lastName: json['LastName'] as String,
      date: DateTime.parse(json['date'] as String),
      comments: commentsList,
    );
  }
}

class CommentData {
  int id;
  int? momentId;
  String names;
  String df;
  String imageOne;
  DateTime date;

  CommentData({
    required this.id,
    required this.momentId,
    required this.names,
    required this.df,
    required this.imageOne,
    required this.date,
  });

  factory CommentData.fromJson(Map<String, dynamic> json) {
    return CommentData(
      id: json['id'] as int,
      momentId: json['momentId'] as int?,
      names: json['Names'] as String,
      df: json['df'] as String,
      imageOne: json['imageOne'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}