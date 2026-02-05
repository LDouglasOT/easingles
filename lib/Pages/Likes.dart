import 'dart:convert';
import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
import 'package:flutter/material.dart';
import 'package:mazale/Components/Liked.dart';
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/Models/Authmodel.dart';
import 'package:mazale/Helpers/ChatDatabaseHelper.dart';
import 'package:mazale/Pages/Profilepage.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Likes extends StatefulWidget {
  const Likes({super.key});

  @override
  State<Likes> createState() => _LikesState();
}

class _LikesState extends State<Likes> with SingleTickerProviderStateMixin {
  String header = "Likes";
  List<DjangoAuthUser> likes = [];
  List<DjangoAuthUser> liked = [];
  List<Map<String, dynamic>> matchesData = [];
  String? userId = "0";
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Offline database helper
  final ChatDatabaseHelper _dbHelper = ChatDatabaseHelper();
  
  // Sync status for each tab
  bool _syncingLikes = false;
  bool _syncingLiked = false;
  bool _syncingMatches = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadDataWithOfflineFirst();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Load data from offline first, then sync with server
  Future<void> _loadDataWithOfflineFirst() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      userId = pref.getString('id');

      // Load from offline database first
      await _loadOfflineData();
      
      setState(() {
        isLoading = false;
      });
      _animationController.forward();

      // Then sync with server
      await _syncAllData();
    } catch (e) {
      print('Error in _loadDataWithOfflineFirst: $e');
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load data. Please try again.";
      });
    }
  }

  Future<void> _loadOfflineData() async {
    try {
      // Load likes
      final offlineLikes = await _dbHelper.getConnections('likes');
      if (offlineLikes.isNotEmpty) {
        setState(() {
          likes = offlineLikes.map((e) => DjangoAuthUser(
            id: e['user_id'],
            firstName: e['first_name'] ?? 'Unknown',
            lastName: e['last_name'] ?? '',
            profilePic: e['profile_pic'] ?? '',
            gender: '',
            userImages: [],
            userInterests: [],
          )).toList();
        });
      }

      // Load liked by
      final offlineLiked = await _dbHelper.getConnections('liked_by');
      if (offlineLiked.isNotEmpty) {
        setState(() {
          liked = offlineLiked.map((e) => DjangoAuthUser(
            id: e['user_id'],
            firstName: e['first_name'] ?? 'Unknown',
            lastName: e['last_name'] ?? '',
            profilePic: e['profile_pic'] ?? '',
            gender: '',
            userImages: [],
            userInterests: [],
          )).toList();
        });
      }

      // Load matches
      final offlineMatches = await _dbHelper.getConnections('matches');
      if (offlineMatches.isNotEmpty) {
        setState(() {
          matchesData = offlineMatches.map((e) => {
            'user': {
              'id': int.parse(e['user_id']),
              'first_name': e['first_name'],
              'last_name': e['last_name'],
              'profilepic': e['profile_pic'],
            },
            'id': e['match_id']
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading offline data: $e');
    }
  }

  Future<void> _syncAllData() async {
    await Future.wait([
      _syncLikes(),
      _syncLiked(),
      _syncMatches(),
    ]);
  }

  Future<void> _syncLikes() async {
    setState(() => _syncingLikes = true);
    
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString('token');

      var response = await http.get(
        Uri.parse('${AppUrls.production}/api/profile-likes/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> likesList = jsonDecode(response.body);
        
        // Save to offline database
        final connections = likesList.map((e) => {
          'id': 'like_${e['liked_user']}',
          'user_id': e['liked_user'].toString(),
          'first_name': e['liked_user_name']?.split(' ').first ?? 'Unknown',
          'last_name': e['liked_user_name']?.split(' ').skip(1).join(' ') ?? '',
          'profile_pic': '',
          'connection_type': 'likes',
          'match_id': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).toList();
        
        await _dbHelper.insertConnections(connections, 'likes');
        
        setState(() {
          likes = likesList.map((e) => DjangoAuthUser(
            id: e['liked_user'].toString(),
            firstName: e['liked_user_name'] ?? 'Unknown',
            lastName: '',
            profilePic: '',
            gender: '',
            userImages: [],
            userInterests: [],
          )).toList();
        });
      }
    } catch (e) {
      print('Error syncing likes: $e');
    } finally {
      setState(() => _syncingLikes = false);
    }
  }

  Future<void> _syncLiked() async {
    setState(() => _syncingLiked = true);
    
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString('token');

      var response = await http.get(
        Uri.parse('${AppUrls.production}/api/profile-likes/received/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> likedList = jsonDecode(response.body);
        
        // Save to offline database
        final connections = likedList.map((e) => {
          'id': 'liked_${e['liker']}',
          'user_id': e['liker'].toString(),
          'first_name': e['liker_name']?.split(' ').first ?? 'Unknown',
          'last_name': e['liker_name']?.split(' ').skip(1).join(' ') ?? '',
          'profile_pic': '',
          'connection_type': 'liked_by',
          'match_id': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).toList();
        
        await _dbHelper.insertConnections(connections, 'liked_by');
        
        setState(() {
          liked = likedList.map((e) => DjangoAuthUser(
            id: e['liker'].toString(),
            firstName: e['liker_name'] ?? 'Unknown',
            lastName: '',
            profilePic: '',
            gender: '',
            userImages: [],
            userInterests: [],
          )).toList();
        });
      }
    } catch (e) {
      print('Error syncing liked: $e');
    } finally {
      setState(() => _syncingLiked = false);
    }
  }

  Future<void> _syncMatches() async {
    setState(() => _syncingMatches = true);
    
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? token = pref.getString('token');

      var response = await http.get(
        Uri.parse('${AppUrls.production}/api/matches/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> matchesList = jsonDecode(response.body);
        
        final newMatchesData = matchesList.map((e) => {
          'user': e['user1']['id'].toString() == userId ? e['user2'] : e['user1'],
          'id': e['id']
        }).toList();
        
        // Save to offline database
        final connections = newMatchesData.map((e) {
          final user = e['user'];
          return {
            'id': 'match_${e['id']}',
            'user_id': user['id'].toString(),
            'first_name': user['first_name'] ?? '',
            'last_name': user['last_name'] ?? '',
            'profile_pic': user['profilepic'] ?? user['profile_pic'] ?? '',
            'connection_type': 'matches',
            'match_id': e['id'].toString(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          };
        }).toList();
        
        await _dbHelper.insertConnections(connections, 'matches');
        
        setState(() {
          matchesData = newMatchesData;
        });
      }
    } catch (e) {
      print('Error syncing matches: $e');
    } finally {
      setState(() => _syncingMatches = false);
    }
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await _loadDataWithOfflineFirst();
  }

  Widget _buildTab(String text, int count, bool isSyncing) {
    return Container(
      color: AppColors.lighter.withOpacity(0.8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (isSyncing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ] else if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFFFFA06B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        backgroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B9D)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Loading your connections...",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null && likes.isEmpty && liked.isEmpty && matchesData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: fetchData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B9D),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          "Try Again",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      // Modern Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        decoration: BoxDecoration(
                          color: AppColors.lighter,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Your Connections",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_syncingLikes || _syncingLiked || _syncingMatches) ...[
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${likes.length + liked.length + matchesData.length} total connections",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tab Bar View
                      Expanded(
                        child: ContainedTabBarView(
                          tabBarProperties: TabBarProperties(
                            height: 56,
                            width: double.infinity,
                            background: Container(
                              decoration: BoxDecoration(
                                color: AppColors.lighter,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            position: TabBarPosition.top,
                            alignment: TabBarAlignment.center,
                            indicatorColor: AppColors.primary,
                            indicatorWeight: 3,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.grey[600],
                          ),
                          tabs: [
                            _buildTab("Likes", likes.length, _syncingLikes),
                            _buildTab("Liked By", liked.length, _syncingLiked),
                            _buildTab("Matches", matchesData.length, _syncingMatches),
                          ],
                          views: [
                            Liked(likes: likes, name: "Likes", userId: userId ?? "0"),
                            Liked(likes: liked, name: "Liked By", userId: userId ?? "0"),
                            Liked(likes: matchesData.map((e) => DjangoAuthUser.fromJson(e['user'])).toList(), name: "Matches", userId: userId ?? "0", matchIds: matchesData.map((e) => e['id'].toString()).toList()),
                          ],
                          onChange: (index) => print(index),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
