import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mazale/Models/Authmodel.dart';
import 'package:mazale/Models/models.dart';
import 'package:mazale/Helpers/ChatDatabaseHelper.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/Pages/Userprofile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:share_plus/share_plus.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  List<Moment> _moments = [];
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  
  // Offline database helper
  final ChatDatabaseHelper _dbHelper = ChatDatabaseHelper();
  bool _isSyncing = false;

  late AnimationController _refreshController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadMomentsWithOfflineFirst();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreMoments();
    }
  }

  /// Load moments from offline first, then sync with server
  Future<void> _loadMomentsWithOfflineFirst() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load from offline database first
      await _loadOfflineMoments();
      
      if (_moments.isNotEmpty) {
        setState(() {
          _isLoading = false;
        });
      }

      // Then sync with server
      await _syncMoments();
    } catch (e) {
      debugPrint('Error loading moments: $e');
      if (_moments.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadOfflineMoments() async {
    try {
      final offlineMoments = await _dbHelper.getMoments();
      
      if (offlineMoments.isNotEmpty) {
        setState(() {
          _moments = offlineMoments.map((m) => Moment(
            id: int.parse(m['id']),
            owner: DjangoAuthUser(
              id: m['owner_id'],
              firstName: m['owner_first_name'] ?? '',
              lastName: m['owner_last_name'] ?? '',
              profilePic: m['owner_profile_pic'] ?? '',
              gender: '',
              userImages: [],
              userInterests: [],
            ),
            hashtag: m['hashtag'],
            tagline: m['tagline'],
            images: m['images'] != null ? (m['images'] as String).split(',').where((s) => s.isNotEmpty).toList() : [],
            likesCount: m['likes_count'] ?? 0,
            totalGifts: m['total_gifts'] ?? 0,
            createdAt: DateTime.parse(m['created_at'] ?? DateTime.now().toIso8601String()),
            isLiked: m['is_liked'] == 1,
          )).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading offline moments: $e');
    }
  }

  Future<void> _syncMoments() async {
    setState(() => _isSyncing = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http
          .get(
            Uri.parse('${AppUrls.production}/api/moments'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        final newMoments = jsonResponse.map((m) => Moment.fromJson(m)).toList();

        // Save to offline database (max 50)
        final momentsToSave = newMoments.take(50).map((m) => {
          'id': m.id.toString(),
          'owner_id': m.owner.id.toString(),
          'owner_first_name': m.owner.firstName,
          'owner_last_name': m.owner.lastName,
          'owner_profile_pic': m.owner.profilePic ?? '',
          'hashtag': m.hashtag,
          'tagline': m.tagline,
          'images': m.images.join(','),
          'likes_count': m.likesCount,
          'total_gifts': m.totalGifts,
          'is_liked': m.isLiked ? 1 : 0,
          'created_at': m.createdAt.toIso8601String(),
        }).toList();
        
        await _dbHelper.insertMoments(momentsToSave);

        if (mounted) {
          setState(() {
            _moments = newMoments;
            _isLoading = false;
            _hasError = false;
            _hasMoreData = newMoments.length >= 10;
          });
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            if (_moments.isEmpty) {
              _moments = [];
            }
            _isLoading = false;
            _hasError = false;
            _hasMoreData = false;
          });
        }
      } else {
        throw Exception('Failed to load moments');
      }
    } catch (e) {
      debugPrint('Error syncing moments: $e');
      if (_moments.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _isLoading = false;
        });
      }
      _refreshController.stop();
      _refreshController.reset();
    }
  }

  Future<void> _loadMoments({bool refresh = false}) async {
    if (refresh) {
      _refreshController.repeat();
      _currentPage = 1;
      _hasMoreData = true;
      await _syncMoments();
    } else {
      await _loadMomentsWithOfflineFirst();
    }
  }

  Future<void> _loadMoreMoments() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http
          .get(
            Uri.parse('${AppUrls.production}/api/moments?page=$_currentPage'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['moments'] is List) {
          final momentsList = jsonResponse['moments'] as List;
          final newMoments =
              momentsList.map((m) => Moment.fromJson(m)).toList();

          if (mounted) {
            setState(() {
              _moments.addAll(newMoments);
              _isLoadingMore = false;
              _hasMoreData = newMoments.length >= 10;
            });
          }
        }
      } else {
        setState(() {
          _isLoadingMore = false;
          _hasMoreData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more moments: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _likeMoment(int momentId, int index) async {
    final isCurrentlyLiked = _moments[index].isLiked;
    
    // Optimistic update
    setState(() {
      _moments[index].isLiked = !isCurrentlyLiked;
      _moments[index].likesCount += isCurrentlyLiked ? -1 : 1;
    });
    
    // Update offline database
    await _dbHelper.updateMomentLike(
      momentId.toString(),
      !isCurrentlyLiked,
      _moments[index].likesCount,
    );
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final endpoint = isCurrentlyLiked ? 'unlike' : 'like';

      final response = await http.post(
        Uri.parse('${AppUrls.production}/api/moments/$momentId/$endpoint/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Revert on failure
        if (mounted) {
          setState(() {
            _moments[index].isLiked = isCurrentlyLiked;
            _moments[index].likesCount += isCurrentlyLiked ? 1 : -1;
          });
          await _dbHelper.updateMomentLike(
            momentId.toString(),
            isCurrentlyLiked,
            _moments[index].likesCount,
          );
        }
      }
    } catch (e) {
      debugPrint('Error ${isCurrentlyLiked ? 'unliking' : 'liking'} moment: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _moments[index].isLiked = isCurrentlyLiked;
          _moments[index].likesCount += isCurrentlyLiked ? 1 : -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => _loadMoments(refresh: true),
        color: Colors.amber,
        backgroundColor: AppColors.background,
        strokeWidth: 3,
        child: _buildBody(),
      ),
      floatingActionButton: _buildCreateMomentButton(),
    );
  }

  Widget _buildCreateMomentButton() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: FloatingActionButton.extended(
            onPressed: () {
             Navigator.of(context).pushNamed('/newmoment');
            },
            backgroundColor: Colors.amber,
            elevation: 8,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading && _moments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading moments...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError && _moments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t load moments',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadMoments,
                icon: const Icon(Icons.refresh_rounded, size: 22),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_moments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.withOpacity(0.2),
                            Colors.amber.withOpacity(0.05),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 80,
                        color: Colors.amber.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'No Moments Yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share your first moment\nand connect with others',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/newmoment');
                },
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text(
                  'Create Moment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  elevation: 6,
                  shadowColor: Colors.amber.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Syncing indicator
        if (_isSyncing)
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Syncing moments...',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < _moments.length) {
                  return _buildMomentCard(_moments[index], index);
                }
                return null;
              },
              childCount: _moments.length,
            ),
          ),
        ),
        if (_isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.amber),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMomentCard(Moment moment, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lighter.withOpacity(0.5),
              AppColors.lighter.withOpacity(0.3),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMomentHeader(moment),
            if (moment.images.isNotEmpty) _buildMomentImages(moment),
            _buildMomentContent(moment),
            _buildMomentActions(moment, index),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentHeader(Moment moment) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Userprofile(userId: moment.owner.id.toString()),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.amber, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.lighter,
                backgroundImage: moment.owner.profilePic != null && moment.owner.profilePic!.isNotEmpty
                    ? CachedNetworkImageProvider(moment.owner.profilePic!)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${moment.owner.firstName} ${moment.owner.lastName}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeago.format(moment.createdAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // Show more options
              },
              icon: Icon(
                Icons.more_vert_rounded,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMomentImages(Moment moment) {
    if (moment.images.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: CachedNetworkImage(
          imageUrl: moment.images[0],
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            height: 300,
            color: AppColors.lighter.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 300,
            color: AppColors.lighter.withOpacity(0.3),
            child: Icon(
              Icons.broken_image_rounded,
              size: 60,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: moment.images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: moment.images[index],
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.lighter.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.lighter.withOpacity(0.3),
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMomentContent(Moment moment) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (moment.hashtag != null && moment.hashtag!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '#${moment.hashtag}',
                style: TextStyle(
                  color: Colors.amber.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (moment.tagline != null && moment.tagline!.isNotEmpty)
            Text(
              moment.tagline!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMomentActions(Moment moment, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lighter.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: moment.isLiked ? Icons.favorite : Icons.favorite_border,
            label: moment.likesCount.toString(),
            color: moment.isLiked ? Colors.red : Colors.white,
            onTap: () => _likeMoment(moment.id, index),
          ),
          const SizedBox(width: 24),
          _buildActionButton(
            icon: Icons.card_giftcard_rounded,
            label: moment.totalGifts.toString(),
            color: Colors.amber,
            onTap: () {
              Navigator.of(context).pushNamed('/gifts');
            },
          ),
          const Spacer(),
          _buildActionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            color: Colors.white,
            onTap: () {
              final text = 'Check out this moment by ${moment.owner.firstName}: ${moment.tagline ?? ''}';
              final url = moment.images.isNotEmpty ? moment.images[0] : '';
              Share.share('$text\n$url');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Moment {
  final int id;
  final DjangoAuthUser owner;
  final String? hashtag;
  final String? tagline;
  final List<String> images;
  int likesCount;
  final int totalGifts;
  final DateTime createdAt;
  bool isLiked;

  Moment({
    required this.id,
    required this.owner,
    this.hashtag,
    this.tagline,
    required this.images,
    required this.likesCount,
    required this.totalGifts,
    required this.createdAt,
    this.isLiked = false,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'] ?? 0,
      owner: DjangoAuthUser.fromJson(json['owner_details'] ?? json['owner'] ?? {}),
      hashtag: json['hashtag'],
      tagline: json['tagline'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      likesCount: json['likes_count'] ?? 0,
      totalGifts: json['total_gifts'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isLiked: json['is_liked_by_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner': {
        'id': (owner.id is int) ? owner.id : null,
        'first_name': owner.firstName,
        'last_name': owner.lastName,
        'profilepic': owner.profilePic,
        'email': owner.email,
        'phone': owner.phoneNumber,
      },
      'hashtag': hashtag,
      'tagline': tagline,
      'images': images,
      'likes_count': likesCount,
      'total_gifts': totalGifts,
      'created_at': createdAt.toIso8601String(),
      'is_liked': isLiked,
    };
  }
}
