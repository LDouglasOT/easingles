import 'dart:convert';
import 'dart:math';
import 'package:bottom_sheet_scaffold/bottom_sheet_scaffold.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet_scaffold.dart';
import 'package:mazale/Models/Authmodel.dart';
import 'package:mazale/Pages/GiftsPager.dart';
import 'package:mazale/Pages/Moments.dart' hide Toolbar;
import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:flutter_toastify/components/enums.dart';
import 'package:flutter_toastify/flutter_toastify.dart';
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/Models/GiftsMode.dart' hide GiftsModel;
import 'package:mazale/Models/models.dart';
import 'package:mazale/Pages/ChatScreen.dart';
import 'package:mazale/Pages/Profilepage.dart';
import 'package:mazale/Pages/Userprofile.dart';
import 'package:mazale/Provider/ProfileProvider.dart';
import 'package:mazale/Provider/SocketProvider.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:http/http.dart' as http;
import 'package:optimized_image_loader/optimized_image_loader.dart';
import 'package:geolocator/geolocator.dart';

class Content {
  final String text;
  final Color color;

  Content({required this.text, required this.color});
}

enum ViewMode { swipe, grid }

class Dating extends StatefulWidget {
  const Dating({Key? key}) : super(key: key);

  @override
  _DatingState createState() => _DatingState();
}

class _DatingState extends State<Dating> with SingleTickerProviderStateMixin {
  MatchEngine _matchEngine = MatchEngine();
  bool showprofile = false;
  bool showloader = true;
  bool showReloadButton = false;
  late String userId;
  late String username;
  late DjangoAuthUser currentUser;
  ViewMode _viewMode = ViewMode.swipe;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Position? currentPosition;

  dynamic recieverId = {"userId": "0", "Names": "None", "profile": "None"};

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  List<SwipeItem> _swipeItems = [];

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('id') ?? '0';
    username = prefs.getString('username') ?? '';
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // in kilometers
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  String _getDistanceText(DjangoAuthUser user) {
    if (currentPosition == null || user.latitude == null || user.longitude == null) {
      return user.latitude ?? "Unknown";
    }
    try {
      double userLat = double.parse(user.latitude!);
      double userLon = double.parse(user.longitude!);
      double distance = _calculateDistance(
        currentPosition!.latitude,
        currentPosition!.longitude,
        userLat,
        userLon,
      );
      if (distance < 1) {
        return "${(distance * 1000).round()}m away";
      } else {
        return "${distance.round()}km away";
      }
    } catch (e) {
      return user.latitude ?? "Unknown";
    }
  }

  String calculateAge(String birthDateString) {
    try {
      DateTime currentDate = DateTime.now();
      DateTime birthDate = DateTime.parse(birthDateString);
      int age = currentDate.year - birthDate.year;

      if (currentDate.month < birthDate.month ||
          (currentDate.month == birthDate.month &&
              currentDate.day < birthDate.day)) {
        age--;
      }

      return age.toString();
    } catch (e) {
      return "25";
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _loadUserData();
    _getCurrentLocation();
    fetchMyGifts();
    _animationController.forward();
    
    // Load profiles using provider (only fetches if not already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProfiles();
    });
  }

  Future<void> _initializeProfiles() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    // Only fetch if not already initialized
    bool success = await profileProvider.fetchProfilesIfNeeded();
    
    if (success) {
      _buildSwipeItemsFromProvider();
    } else if (!profileProvider.hasError) {
      // Server returned 201 - subscription required
      Navigator.of(context).pushNamed("/purchase");
    }
  }

  void _buildSwipeItemsFromProvider() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final allcards = profileProvider.profiles;
    
    setState(() {
      _swipeItems.clear();
    });

    for (var user in allcards) {
      _swipeItems.add(
        SwipeItem(
          content: Content(
            text: user.firstName ?? "",
            color: Colors.purple,
          ),
          likeAction: () async {
            _onProfileSwiped();
            await _likeUser(user);
          },
          nopeAction: () {
            _onProfileSwiped();
          },
          superlikeAction: () {
            _onProfileSwiped();
          },
        ),
      );
    }

    if (allcards.isNotEmpty) {
      setState(() {
        currentUser = allcards[0];
      });
    }

    _matchEngine = MatchEngine(swipeItems: _swipeItems);
    setState(() {
      showprofile = allcards.isNotEmpty;
      showloader = false;
      showReloadButton = false;
    });
  }

  void _onProfileSwiped() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    profileProvider.onProfileSwiped();
    
    // Check if user has reached free limit
    if (profileProvider.hasReachedFreeLimit) {
      // TODO: Check if user has premium subscription
      // For now, navigate to subscription page
      Navigator.of(context).pushNamed("/purchase");
    }
  }

  Future<void> _likeUser(DjangoAuthUser user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    
    var response = await http.post(
      Uri.parse('${AppUrls.production}/api/profile-likes/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        "liked_user": int.parse(user.id.toString()),
        "superlike": false,
      }),
    );

    if (response.statusCode == 201) {
      var data = jsonDecode(response.body);
      if (data['is_match'] == true) {
        _showMatchDialog(user);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like profile: ${response.statusCode}')),
      );
    }
  }

  void _showMatchDialog(DjangoAuthUser user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                "It's a Match!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "You and ${user.firstName} liked each other!",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Keep Swiping",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            valueToPass: user.id.toString(),
                            profile: user.profilePic ?? "",
                            names: '${user.firstName} ${user.lastName}',
                            userId: user.id.toString(),
                            username: '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text("Send Message"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  late List<UserGifts> myGifts = [];
  bool giftLoaderStatus = true;

  Future<void> _loadMoreItems() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    
    setState(() {
      showprofile = false;
      showloader = true;
      showReloadButton = false;
    });
    
    // Force fetch new profiles when all are swiped
    bool success = await profileProvider.fetchNewProfiles();
    
    if (success) {
      _buildSwipeItemsFromProvider();
    } else if (profileProvider.hasError) {
      setState(() {
        showloader = false;
        showprofile = false;
        showReloadButton = true;
      });
    } else {
      // Server returned 201 - subscription required
      Navigator.of(context).pushNamed("/purchase");
    }
  }

  Future<List<UserGifts>> fetchMyGifts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      var response = await http.get(
        Uri.parse("${AppUrls.production}/api/user-gifts/"),
        headers: {'Authorization': 'Bearer $token'},
      );

      switch (response.statusCode) {
        case 200:
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          if (jsonResponse.containsKey('data') &&
              jsonResponse['data'] is List) {
            List<dynamic> giftsList = jsonResponse['data'];
            List<UserGifts> gifts = giftsList
                .map((item) => UserGifts.fromJson(item))
                .toList();
            myGifts.clear();
            setState(() {
              myGifts.addAll(gifts);
            });
            return gifts;
          } else {
            return [];
          }
        default:
          return [];
      }
    } catch (error) {
      return [];
    }
  }

  void sendGift(UserGifts gift) async {
    try {
      setState(() {
        giftLoaderStatus = false;
      });
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? currentUsers = pref.getString("id");
      String? token = pref.getString("token");
      var body = {
        "myid": currentUsers ?? "0",
        "user": currentUser.id ?? "0",
        "img": gift.giftDetails.image ?? "",
        "name": gift.giftDetails.name ?? "Gift",
        "qty": "1",
        "conversationId": "HOME",
        "momentId": currentUser.id,
      };
      var response = await http.post(
        Uri.parse('${AppUrls.production}/api/giftpeople'),
        headers: {'Authorization': 'Bearer $token'},
        body: body,
      );
      switch (response.statusCode) {
        case 200:
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
                  Image.network(gift.giftDetails.image ?? "", height: 20, width: 20),
                  SizedBox(width: 8),
                  Text(
                    gift.giftDetails.name ?? "",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            description: Text(
              'You have gifted 1 ${gift.giftDetails.name} to ${recieverId['Names']}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
              ),
            ),
            onDismiss: () {},
          ).show(context);
          BottomSheetPanel.close();
          break;
        case 400:
        case 404:
          var snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Insufficient ${gift.giftDetails.name} to gift',
              contentType: ContentType.warning,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          setState(() {
            giftLoaderStatus = true;
          });
          break;
        case 500:
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
    } catch (err) {
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

  Widget _buildProfileCard(
    DjangoAuthUser user,
    int index, {
    bool isGridMode = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Userprofile(userId: user.id.toString()),
                ),
              ),
              child: OptimizedImageLoader(
                url: user.profilePic ?? "",
                imageHeight: double.infinity,
                imageWidth: double.infinity,
                spinnerHeight: 25,
                spinnerWidth: 25,
                loadingIndicator: Container(
                  color: AppColors.background,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
                errorContainerDecoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                errorContainerChild: Center(
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
            // User info
            Positioned(
              bottom: isGridMode ? 8 : 16,
              left: isGridMode ? 8 : 16,
              right: isGridMode ? 8 : 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.firstName ?? "Unknown",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isGridMode ? 18 : 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        calculateAge(user.year.toString()),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isGridMode ? 16 : 24,
                          fontWeight: FontWeight.w400,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 6),
                      if (context.watch<SocketProvider>().userIds.any(
                        (socketUser) =>
                            socketUser["userId"].toString() ==
                            user.id.toString(),
                      ))
                        Container(
                          width: isGridMode ? 8 : 12,
                          height: isGridMode ? 8 : 12,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: isGridMode ? 4 : 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: isGridMode ? 14 : 18,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _getDistanceText(user),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isGridMode ? 12 : 16,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Positioned(
              bottom: isGridMode ? 8 : 16,
              right: isGridMode ? 8 : 16,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          valueToPass: user.id.toString(),
                          profile:
                              (user.userImages != null &&
                                  user.userImages!.isNotEmpty)
                              ? user.userImages![Random().nextInt(
                                  user.userImages!.length,
                                )]
                              : "",
                          names: '${user.firstName} ${user.lastName}',
                          userId: user.id.toString(),
                          username: username,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat, color: Colors.white, size: isGridMode ? 20 : 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final allcards = profileProvider.profiles;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: allcards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.white30),
                  SizedBox(height: 16),
                  Text(
                    "No profiles to show",
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: allcards.length,
              itemBuilder: (context, index) {
                return _buildProfileCard(
                  allcards[index],
                  index,
                  isGridMode: true,
                );
              },
            ),
    );
  }

  Widget _buildSwipeView() {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final allcards = profileProvider.profiles;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      width: MediaQuery.of(context).size.width * 0.9,
      child: SwipeCards(
        matchEngine: _matchEngine,
        itemBuilder: (BuildContext context, int index) {
          if (index >= 0 && index < _swipeItems.length) {
            return Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                width: MediaQuery.of(context).size.width * 0.85,
                child: _buildProfileCard(allcards[index], index),
              ),
            );
          } else {
            return Container();
          }
        },
        onStackFinished: () {
          _loadMoreItems();
        },
        itemChanged: (SwipeItem item, int index) {
          final allcards = Provider.of<ProfileProvider>(context, listen: false).profiles;
          if (index >= 0 && index < allcards.length) {
            setState(() {
              currentUser = allcards[index];
            });
          }
        },
        upSwipeAllowed: true,
        fillSpace: true,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close,
            color: Colors.red,
            size: 60,
            onTap: () {
              if (_matchEngine.currentItem != null) {
                _matchEngine.currentItem?.nope();
              }
            },
          ),
          _buildActionButton(
            icon: Icons.card_giftcard,
            color: Colors.amber,
            size: 50,
            onTap: () {
              final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
              final allcards = profileProvider.profiles;
              
              if (BottomSheetPanel.isOpen) {
                setState(() {
                  recieverId = {};
                });
                BottomSheetPanel.close();
              } else {
                if (allcards.isNotEmpty) {
                  setState(() {
                    recieverId = {
                      "userId": currentUser.id.toString(),
                      "Names":
                          "${currentUser.firstName} ${currentUser.lastName}",
                      "profile": currentUser.profilePic.toString(),
                      "momentId": currentUser.id.toString(),
                    };
                  });
                  BottomSheetPanel.open();
                }
              }
            },
          ),
          _buildActionButton(
            icon: Icons.favorite,
            color: AppColors.primary,
            size: 60,
            onTap: () {
              if (_matchEngine.currentItem != null) {
                _matchEngine.currentItem?.like();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: CircleBorder(),
          splashColor: color.withOpacity(0.3),
          child: Center(
            child: Icon(icon, color: color, size: size * 0.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final allcards = profileProvider.profiles;
    final isLoading = profileProvider.isLoading;
    final hasError = profileProvider.hasError;
    
    return BottomSheetScaffold(
      bottomSheet: DraggableBottomSheet(
        animationDuration: const Duration(milliseconds: 200),
        body: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          width: double.infinity,
          height: 500,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Send a Gift",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "to ${recieverId['Names'] ?? 'User'}",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 16),
              if (myGifts.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard_outlined,
                          size: 60,
                          color: Colors.white30,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No gifts available",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/gifts'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            "Buy Gifts",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (myGifts.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      var gift = myGifts[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.lighter.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.white.withOpacity(0.1),
                                child: Image.network(
                                  gift.giftDetails.image ?? "",
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 70,
                                      width: 70,
                                      color: Colors.grey,
                                      child: Icon(
                                        Icons.card_giftcard,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    gift.giftDetails.name ?? "Gift",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          "${gift.quantity} left",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: giftLoaderStatus
                                  ? () => sendGift(gift)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: AppColors.primary
                                    .withOpacity(0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: giftLoaderStatus
                                  ? Text(
                                      "Send",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                    itemCount: myGifts.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
      key: _scaffoldKey,
      appBar: Toolbar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/gifts'),
          icon: Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.lighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard, size: 28),
          ),
          color: Colors.white,
        ),
        background: Colors.white,
        title: "Mazale",
        actions: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: _viewMode == ViewMode.grid
                  ? AppColors.primary
                  : AppColors.lighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _viewMode = _viewMode == ViewMode.swipe
                      ? ViewMode.grid
                      : ViewMode.swipe;
                  _animationController.reset();
                  _animationController.forward();
                });
              },
              icon: Icon(
                _viewMode == ViewMode.swipe ? Icons.grid_view : Icons.layers,
                size: 28,
              ),
              color: Colors.white,
              tooltip: _viewMode == ViewMode.swipe
                  ? "Switch to Grid View"
                  : "Switch to Swipe View",
            ),
          ),
          SizedBox(width: 10),
          Stack(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: AppColors.lighter,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/notifications'),
                  icon: Icon(Icons.notifications, size: 28),
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(width: 10),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: AppColors.lighter,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pushNamed("/purchase"),
              icon: Icon(Icons.shopping_cart, size: 28),
              color: Colors.white,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: isLoading || showloader
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: LoadingIndicator(
                      indicatorType: Indicator.ballRotateChase,
                      colors: [Colors.white, Colors.white70, Colors.white60],
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Finding matches...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please wait",
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            )
          : hasError || showReloadButton
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Oops!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Something went wrong",
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Unable to load profiles. Please try again.",
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      onPressed: _loadMoreItems,
                      icon: Icon(Icons.refresh, size: 24),
                      label: Text(
                        'Reload',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : allcards.isNotEmpty
          ? _viewMode == ViewMode.swipe
                ? SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        _buildSwipeView(),
                        SizedBox(height: 20),
                        _buildActionButtons(),
                        SizedBox(height: 20),
                      ],
                    ),
                  )
                : Container(
                    height: MediaQuery.of(context).size.height - 120,
                    child: _buildGridView(),
                  )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.white30,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      "No profiles available",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Check back later for new matches",
                      style: TextStyle(color: Colors.white60, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _loadMoreItems,
                      icon: Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        'Refresh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
