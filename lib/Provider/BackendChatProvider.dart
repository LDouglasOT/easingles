import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mazale/assets/urlconfig.dart';

class BackendChatProvider extends ChangeNotifier {
  late SharedPreferences prefs;
  late String? userId;
  late String? userName;
  late String? userProfilePic;

  IO.Socket? socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // User online status tracking
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // List of online users
  List<Map<String, dynamic>> _onlineUsers = [];
  List<Map<String, dynamic>> get onlineUsers => _onlineUsers;

  // Typing status tracking
  Map<String, bool> _typingUsers = {};
  Map<String, bool> get typingUsers => _typingUsers;

  // Conversations
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> get conversations => _conversations;

  // Messages
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  BackendChatProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('id');
    userName = prefs.getString('name') ?? 'User';
    userProfilePic = prefs.getString('profilePic') ?? '';

    if (userId != null) {
      _connectToSocket();
      await _fetchConversations();
    }
  }

  void _connectToSocket() {
    try {
      // Connect to backend Socket.IO server
      socket = IO.io(AppUrls.production, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'query': {'userId': userId}
      });

      socket?.on('connect', (_) {
        _isConnected = true;
        _isOnline = true;
        notifyListeners();
        print('Connected to backend chat server');

        // Add user to online list
        socket?.emit('addUser', {'userId': userId});
      });

      socket?.on('disconnect', (_) {
        _isConnected = false;
        _isOnline = false;
        notifyListeners();
        print('Disconnected from backend chat server');
      });

      socket?.on('getUsers', (users) {
        _onlineUsers = List<Map<String, dynamic>>.from(users);
        notifyListeners();
      });

      socket?.on('getMessage', (message) {
        _messages.add(Map<String, dynamic>.from(message));
        notifyListeners();
      });

      socket?.on('typingIndicator', (data) {
        _typingUsers[data['from']] = true;
        notifyListeners();
      });

      socket?.on('stoptypingIndicator', (data) {
        _typingUsers[data['from']] = false;
        notifyListeners();
      });

      socket?.on('connect_error', (error) {
        print('Connection error: $error');
      });

    } catch (e) {
      print('Error connecting to socket: $e');
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final token = prefs.getString('token');
      if (token == null || userId == null) return;

      final response = await http.get(
        Uri.parse('${AppUrls.production}/api/conversation/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['conversations'] != null) {
          _conversations = List<Map<String, dynamic>>.from(data['conversations']);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error fetching conversations: $e');
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    try {
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AppUrls.production}/api/messages/$conversationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _messages = List<Map<String, dynamic>>.from(data);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Future<void> sendMessage({
    required String receiverId,
    required String message,
    required bool isText,
    bool isImage = false,
    String? mediaUrl,
  }) async {
    try {
      final token = prefs.getString('token');
      if (token == null || userId == null) return;

      // First, create conversation if it doesn't exist
      final conversationResponse = await http.post(
        Uri.parse('${AppUrls.production}/api/conversation'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'user1': userId,
          'user2': receiverId
        }),
      );

      if (conversationResponse.statusCode != 200 && conversationResponse.statusCode != 201) {
        print('Error creating conversation');
        return;
      }

      final conversationData = jsonDecode(conversationResponse.body);
      final conversationId = conversationData['id']?.toString() ?? '';

      // Send message via HTTP
      final messageResponse = await http.post(
        Uri.parse('${AppUrls.production}/api/messages/new'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'sender': userId,
          'reciever': receiverId,
          'sms': message,
          'conversationId': conversationId,
          'isText': isText.toString(),
          'isImage': isImage.toString()
        }),
      );

      if (messageResponse.statusCode == 200) {
        final messageData = jsonDecode(messageResponse.body)[0];
        _messages.add(Map<String, dynamic>.from(messageData));
        notifyListeners();

        // Also send via socket for real-time delivery
        socket?.emit('sendMessage', {
          'sms': {
            'sendto': receiverId,
            'message': message,
            'sender': userId,
            'conversationId': conversationId,
            'isText': isText,
            'isImage': isImage,
            'mediaUrl': mediaUrl
          }
        });
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> updateTypingStatus(String receiverId, bool isTyping) async {
    try {
      if (isTyping) {
        socket?.emit('typing', {
          'from': userId,
          'reciever': receiverId
        });
      } else {
        socket?.emit('stoptyping', {
          'from': userId,
          'reciever': receiverId
        });
      }
    } catch (e) {
      print('Error updating typing status: $e');
    }
  }

  Future<void> markMessagesAsRead(List<int> messageIds) async {
    try {
      final token = prefs.getString('token');
      if (token == null) return;

      await http.put(
        Uri.parse('${AppUrls.production}/api/messages/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'unreads': messageIds
        }),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  bool isUserTyping(String userId) {
    return _typingUsers[userId] ?? false;
  }

  bool get isAnyUserTyping {
    return _typingUsers.values.any((typing) => typing);
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }
}