import 'dart:convert';
import 'package:mazale/Components/Toolbar.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:flutter/material.dart';
import 'package:mazale/Components/Chatpill.dart';
import 'package:mazale/Pages/ChatScreen.dart';
import 'package:mazale/Pages/Userprofile.dart';
import 'package:mazale/Helpers/ChatDatabaseHelper.dart';
import 'package:http/http.dart' as http;
import 'package:mazale/assets/urlconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mazale/Provider/SocketProvider.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  List<ChatInfo> _chats = [];
  String? _errorMessage;
  late AnimationController _fabController;
  late AnimationController _listController;
  int? _currentUserId;
  String? _currentUserName;
  
  // Offline database helper
  final ChatDatabaseHelper _dbHelper = ChatDatabaseHelper();
  
  // Track which conversations are syncing
  Map<String, bool> _syncingConversations = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadCurrentUser();
    _loadChatsWithOfflineFirst();
    _setupRefreshTimer();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _setupRefreshTimer() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _syncAllConversations();
        _setupRefreshTimer();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = int.parse(prefs.getString('id') ?? '0');
    _currentUserName = prefs.getString('username') ?? '';
  }

  /// Load conversations from offline database first, then sync with server
  Future<void> _loadChatsWithOfflineFirst() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // First, load from offline database
      final offlineConversations = await _dbHelper.getConversations();
      
      if (offlineConversations.isNotEmpty) {
        // Convert offline data to ChatInfo objects
        final offlineChats = offlineConversations.map((conv) {
          final participantId = conv['participant_id'] is String 
              ? int.parse(conv['participant_id'])
              : conv['participant_id'] as int;
          final conversationId = conv['id'] is String 
              ? int.parse(conv['id'])
              : conv['id'] as int;
          final lastMessageTime = conv['last_message_time'] != null 
              ? DateTime.parse(conv['last_message_time'])
              : DateTime.now();
          final lastMessage = conv['last_message'] != null && conv['last_message'].isNotEmpty
              ? Message(
                  id: 0,
                  sms: conv['last_message'],
                  sender: 0,
                  receiver: _currentUserId ?? 0,
                  seen: true,
                  createdAt: lastMessageTime,
                )
              : null;
          
          return ChatInfo(
            id: conversationId,
            participants: [
              User(
                id: participantId,
                firstName: conv['participant_name']?.split(' ').first ?? '',
                lastName: conv['participant_name']?.split(' ').skip(1).join(' ') ?? '',
                profilePic: conv['participant_profile'],
              ),
            ],
            participantsIds: [participantId],
            updatedAt: DateTime.parse(conv['updated_at'] ?? DateTime.now().toIso8601String()),
            messages: lastMessage != null ? [lastMessage] : [],
            lastMessage: lastMessage,
            unreadCount: conv['unread_count'] is String 
                ? int.tryParse(conv['unread_count']) ?? 0 
                : (conv['unread_count'] as int?) ?? 0,
            isOffline: true,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _chats = offlineChats;
            _isLoading = false;
          });
          _listController.forward(from: 0);
        }

        // Now sync each conversation with server
        _syncAllConversations();
      } else {
        // No offline data, load from server
        await _loadChatsFromServer();
      }
    } catch (e) {
      debugPrint('Error loading offline chats: $e');
      // Fallback to server
      await _loadChatsFromServer();
    }
  }

  /// Sync all conversations with server
  Future<void> _syncAllConversations() async {
    // Mark all as syncing
    for (var chat in _chats) {
      setState(() {
        _syncingConversations[chat.id.toString()] = true;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http
          .get(
            Uri.parse('${AppUrls.production}/api/conversations/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      print(response.body);
      print("system calls");
      print(".............................................");
      print(".............................................");
      print(".............................................");
      print(".............................................");
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        final serverChats = jsonResponse.map((chat) => ChatInfo.fromJson(chat, currentUserId: _currentUserId ?? 0)).toList();
        print(serverChats[0].lastMessage);
        // Save to offline database and update UI
        for (var chat in serverChats) {
          await _saveConversationToOffline(chat);
          
          // Update syncing status with small delay for visual effect
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            setState(() {
              _syncingConversations[chat.id.toString()] = false;
            });
          }
        }

        if (mounted) {
          setState(() {
            _chats = serverChats;
            _hasError = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error syncing conversations: $e');
    } finally {
      // Clear all syncing states
      if (mounted) {
        setState(() {
          _syncingConversations.clear();
        });
      }
    }
  }

  /// Save conversation to offline database
  Future<void> _saveConversationToOffline(ChatInfo chat) async {
    try {
      final otherUser = chat.participants.firstWhere(
        (user) => user.id != _currentUserId,
        orElse: () => chat.participants.isNotEmpty ? chat.participants[0] : User(id: 0, firstName: '', lastName: ''),
      );

      final lastMessage = chat.messages.isNotEmpty ? chat.messages.last : null;

      await _dbHelper.insertConversation({
        'id': chat.id.toString(),
        'participant_id': otherUser.id.toString(),
        'participant_name': '${otherUser.firstName} ${otherUser.lastName}'.trim(),
        'participant_profile': otherUser.profilePic ?? '',
        'last_message': lastMessage?.sms ?? '',
        'last_message_time': lastMessage?.createdAt.toIso8601String() ?? DateTime.now().toIso8601String(),
        'unread_count': chat.messages.where((m) => !m.seen && m.receiver == _currentUserId).length,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': chat.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving conversation to offline: $e');
    }
  }

  Future<void> _loadChatsFromServer({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http
          .get(
            Uri.parse('${AppUrls.production}/api/conversations/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);

        if (mounted) {
          final serverChats = jsonResponse.map((chat) => ChatInfo.fromJson(chat, currentUserId: _currentUserId ?? 0)).toList();
          
          // Save all to offline database
          for (var chat in serverChats) {
            await _saveConversationToOffline(chat);
          }

          setState(() {
            _chats = serverChats;
            _isLoading = false;
            _hasError = false;
          });
          _listController.forward(from: 0);
        }
      } else if (response.statusCode == 404) {
        if (mounted) {
          setState(() {
            _chats = [];
            _isLoading = false;
            _hasError = false;
          });
          _fabController.forward();
        }
      } else {
        throw Exception('Failed to load chats');
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = _chats.isEmpty; // Only show error if no offline data
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadChats({bool silent = false}) async {
    await _loadChatsWithOfflineFirst();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Toolbar(
        title: "Messages",
        background: AppColors.lighter,
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadChats(),
        color: Colors.amber,
        backgroundColor: AppColors.background,
        strokeWidth: 3,
        child: _buildBody(),
      ),
      floatingActionButton: _chats.isNotEmpty || _hasError
          ? ScaleTransition(
              scale: CurvedAnimation(
                parent: _fabController,
                curve: Curves.elasticOut,
              ),
              child: FloatingActionButton(
                onPressed: () {
                  // Navigate to new chat or contacts
                },
                backgroundColor: Colors.amber,
                elevation: 8,
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading && _chats.isEmpty) {
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
              'Loading conversations...',
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

    if (_hasError && _chats.isEmpty) {
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
                  Icons.cloud_off_rounded,
                  size: 64,
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t load your conversations',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loadChats,
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

    if (_chats.isEmpty) {
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
                        Icons.chat_bubble_outline_rounded,
                        size: 80,
                        color: Colors.amber.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  children: [
                    const Text(
                      'No Messages Yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Start a conversation and connect\nwith people around you',
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
                        // Navigate to contacts or start new chat
                      },
                      icon: const Icon(Icons.add_rounded, size: 24),
                      label: const Text(
                        'Start Chatting',
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
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          itemCount: _chats.length,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final chat = _chats[index];
            final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _listController,
                curve: Interval(
                  (index / _chats.length) * 0.5,
                  ((index + 1) / _chats.length) * 0.5 + 0.5,
                  curve: Curves.easeOutCubic,
                ),
              ),
            );

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.3, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: _buildChatItem(chat, index),
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildChatItem(ChatInfo chat, int index) {
    // 1. Safety check: Ensure we actually have participants and messages
    if (chat.participants.isEmpty || _currentUserId == null) {
      return const SizedBox.shrink();
    }

    final otherUser = chat.participants.firstWhere(
      (user) => user.id != _currentUserId,
      orElse: () => chat.participants[0], // Fallback if it's a chat with yourself
    );

    // 3. Extract display data
    final lastMessage = chat.lastMessage;

    final unreadCount = chat.unreadCount;

    final isOnline = context.watch<SocketProvider>().isUserOnline(otherUser.id.toString());
    
    final isSyncing = _syncingConversations[chat.id.toString()] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lighter.withOpacity(0.5),
            AppColors.lighter.withOpacity(0.2),
          ],
        ),
        boxShadow: unreadCount > 0
            ? [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Chatpill(
                messages: lastMessage?.sms ?? 'No messages yet',
                avatar: otherUser.profilePic ?? '',
                names: "${otherUser.firstName} ${otherUser.lastName}".trim(),
                newvcount: unreadCount > 0 ? unreadCount.toString() : "0",
                status: isOnline,
                cuid: otherUser.id.toString(),
                timestamp: lastMessage?.createdAt,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        valueToPass: otherUser.id.toString(),
                        names: '${otherUser.firstName} ${otherUser.lastName}',
                        profile: otherUser.profilePic ?? '',
                        userId: _currentUserId.toString(),
                        username: _currentUserName ?? '',
                      ),
                    ),
                  );
                },
                onAvatarTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Userprofile(userId: otherUser.id.toString()),
                    ),
                  );
                },
              ),
            ),
          ),
          // Syncing indicator
          if (isSyncing)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Syncing',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatInfo {
  final int id;
  final List<User> participants;
  final List<int> participantsIds;
  final DateTime updatedAt;
  final List<Message> messages;
  final Message? lastMessage;
  final int unreadCount;
  final bool isOffline;

  ChatInfo({
    required this.id,
    required this.participants,
    required this.participantsIds,
    required this.updatedAt,
    required this.messages,
    this.lastMessage,
    this.unreadCount = 0,
    this.isOffline = false,
  });

  factory ChatInfo.fromJson(Map<String, dynamic> json, {int currentUserId = 0}) {
    final messagesList = (json['messages'] as List?)
            ?.map((message) => Message.fromJson(message))
            .toList() 
        ?? [];
    
    final unreadCount = messagesList.where((m) => !m.seen && m.receiver == currentUserId).length;
    
    return ChatInfo(
      id: json['id'] ?? 0,
      participants: (json['participants_details'] as List?)
              ?.map((user) => User.fromJson(user))
              .toList() 
          ?? [],
      participantsIds: (json['participants'] as List?)
              ?.map((id) => id as int)
              .toList() 
          ?? [],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      messages: messagesList,
      lastMessage: messagesList.isNotEmpty ? messagesList.last : null,
      unreadCount: json['unread_count'] ?? unreadCount,
      isOffline: false,
    );
  }
}

class User {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePic;
  final String? gender;
  final String? about;
  final String? hopes;
  final String? religion;
  final List<String>? userImages;
  final List<dynamic>? userInterests;
  final bool? online;
  final bool? promoted;
  final int? momentsCount;
  final int? matchesCount;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePic,
    this.gender,
    this.about,
    this.hopes,
    this.religion,
    this.userImages,
    this.userInterests,
    this.online,
    this.promoted,
    this.momentsCount,
    this.matchesCount,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      profilePic: json['profile_pic'],
      gender: json['gender'],
      about: json['about'],
      hopes: json['hopes']?.toString(),
      religion: json['religion'],
      userImages: json['user_images'] != null 
          ? List<String>.from(json['user_images']) 
          : null,
      userInterests: json['user_interests'],
      online: json['online'] ?? false,
      promoted: json['promoted'] ?? false,
      momentsCount: json['moments_count'] ?? 0,
      matchesCount: json['matches_count'] ?? 0,
    );
  }
}

class Message {
  final int id;
  final String sms;
  final int sender;
  final int receiver;
  final bool seen;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.sms,
    required this.sender,
    required this.receiver,
    required this.seen,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? 0,
      sms: json['sms'] ?? '',
      sender: json['sender'] ?? 0,
      receiver: json['receiver'] ?? 0,
      seen: json['seen'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
