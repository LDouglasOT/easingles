import 'dart:async';
import 'package:chatview/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseChatProvider extends ChangeNotifier {
  late SharedPreferences prefs;
  late String? userId;
  late String? userName;
  late String? userProfilePic;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User online status tracking
  bool _isOnline = false;
  bool get isOnline => _isOnline;
  
  // List of online users (you might want to track this separately)
  List<String> _onlineUserIds = [];
  List<String> get onlineUserIds => _onlineUserIds;
  
  // Typing status tracking
  Map<String, bool> _typingUsers = {};
  Map<String, bool> get typingUsers => _typingUsers;

  FirebaseChatProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('id');
    userName = prefs.getString('name') ?? 'User';
    userProfilePic = prefs.getString('profilePic') ?? '';
    
    if (userId != null) {
      _setUserOnlineStatus(true);
      _listenToUserStatus();
    }
  }

  // Set user online status in Firestore
  Future<void> _setUserOnlineStatus(bool isOnline) async {
    if (userId == null) return;
    
    await _firestore.collection('users').doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'name': userName,
      'profilePic': userProfilePic,
    }, SetOptions(merge: true));
    
    _isOnline = isOnline;
    notifyListeners();
  }

  // Listen to user online status changes
  void _listenToUserStatus() {
    if (userId == null) return;
    
    // Listen to all other users' online status
    _firestore.collection('users').snapshots().listen((snapshot) {
      List<String> onlineIds = [];
      for (var doc in snapshot.docs) {
        if (doc.id != userId) {
          final data = doc.data();
          if (data['isOnline'] == true) {
            onlineIds.add(doc.id);
          }
        }
      }
      _onlineUserIds = onlineIds;
      notifyListeners();
    });
  }

  // Generate conversation ID based on two user IDs
  String getConversationId(String otherUserId) {
    if (userId == null) return '';
    final sortedIds = [userId!, otherUserId]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Get or create conversation
  Future<DocumentReference> getOrCreateConversation(String otherUserId) async {
    final conversationId = getConversationId(otherUserId);
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    
    final doc = await conversationRef.get();
    if (!doc.exists) {
      await conversationRef.set({
        'participants': [userId, otherUserId],
        'participantDetails': {
          userId: {
            'name': userName,
            'profilePic': userProfilePic,
            'lastSeen': FieldValue.serverTimestamp(),
          },
          otherUserId: {
            'lastSeen': FieldValue.serverTimestamp(),
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
    
    return conversationRef;
  }

  // Listen to conversation updates (typing, etc.)
  StreamSubscription<DocumentSnapshot>? _conversationListener;

  void listenToConversation(String otherUserId, Function(Map<String, dynamic>) onUpdate) {
    if (userId == null) return;
    
    final conversationId = getConversationId(otherUserId);
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    
    _conversationListener?.cancel();
    _conversationListener = conversationRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final typingData = data['typing'] as Map<String, dynamic>?;
        
        Map<String, bool> currentTyping = {};
        if (typingData != null) {
          typingData.forEach((key, value) {
            if (key != userId) {
              currentTyping[key] = value ?? false;
            }
          });
        }
        
        _typingUsers = currentTyping;
        onUpdate(data);
        notifyListeners();
      }
    });
  }

  // Update typing status
  Future<void> updateTypingStatus(String otherUserId, bool isTyping) async {
    if (userId == null) return;
    
    final conversationId = getConversationId(otherUserId);
    await _firestore.collection('conversations').doc(conversationId).update({
      'typing.$userId': isTyping,
    });
  }

  // Send message
  Future<void> sendMessage({
    required String receiverId,
    required String message,
    required MessageType messageType,
    String? replyToMessageId,
    String? mediaUrl,
    int? voiceDuration,
  }) async {
    if (userId == null) return;
    
    final conversationRef = await getOrCreateConversation(receiverId);
    final messagesRef = conversationRef.collection('messages');
    
    final messageData = {
      'senderId': userId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isText': messageType.isText,
      'isImage': messageType.isImage,
      'isVoice': messageType.isVoice,
      'replyToMessageId': replyToMessageId,
      'mediaUrl': mediaUrl,
      'voiceDuration': voiceDuration,
      'readBy': {userId: FieldValue.serverTimestamp()},
    };
    
    await messagesRef.add(messageData);
    
    // Update conversation metadata
    await conversationRef.update({
      'lastMessage': messageType.isText ? message : 'Media message',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': userId,
    });
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId, String conversationId) async {
    if (userId == null) return;
    
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy.$userId': FieldValue.serverTimestamp(),
    });
  }

  // Get messages stream for a conversation
  Stream<QuerySnapshot> getMessagesStream(String otherUserId) {
    final conversationId = getConversationId(otherUserId);
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get all conversations for current user
  Stream<QuerySnapshot> getConversationsStream() {
    if (userId == null) return const Stream.empty();
    
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Check if user is typing to another user
  bool isUserTyping(String userId) {
    return _typingUsers[userId] ?? false;
  }

  // Check if any user is typing
  bool get isAnyUserTyping {
    return _typingUsers.values.any((typing) => typing);
  }

  @override
  void dispose() {
    _conversationListener?.cancel();
    if (userId != null) {
      _setUserOnlineStatus(false);
    }
    super.dispose();
  }
}