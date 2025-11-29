import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easingles/Components/Chatpill.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Provider/FirebaseChatProvider.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  late FirebaseChatProvider _chatProvider;
  late Stream<QuerySnapshot> _conversationsStream;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('id');
    
    if (currentUserId != null) {
      _chatProvider = Provider.of<FirebaseChatProvider>(context, listen: false);
      _conversationsStream = _chatProvider.getConversationsStream();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(title: "Messages", background: AppColors.lighter),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            child: currentUserId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _conversationsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return const Center(child: Text("Error loading conversations"));
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No conversations available"));
                      }
                      
                      final conversations = snapshot.data!.docs;
                      
                      return ListView.builder(
                        itemCount: conversations.length,
                        itemBuilder: (BuildContext context, int index) {
                          final doc = conversations[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final participants = data['participants'] as List<dynamic>;
                          final participantDetails = data['participantDetails'] as Map<String, dynamic>? ?? {};
                          
                          // Find the other participant (not current user)
                          String? otherUserId;
                          Map<String, dynamic>? otherUserDetails;
                          
                          for (var participantId in participants) {
                            if (participantId != currentUserId) {
                              otherUserId = participantId.toString();
                              otherUserDetails = participantDetails[otherUserId] as Map<String, dynamic>?;
                              break;
                            }
                          }
                          
                          if (otherUserId == null) {
                            return const SizedBox.shrink();
                          }
                        
                          final otherUserName = otherUserDetails?['name'] ?? 'Unknown User';
                          final otherUserProfile = otherUserDetails?['profilePic'] ?? '';
                          final lastMessage = data['lastMessage'] ?? '';
                          final lastMessageTime = data['lastMessageTime'] as Timestamp?;
                          final lastSeen = otherUserDetails?['lastSeen'] as Timestamp?;
                          
                          // Calculate unread count by querying messages
                          return FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('conversations')
                                .doc(doc.id)
                                .collection('messages')
                                .where('senderId', isEqualTo: otherUserId)
                                .where('readBy.$currentUserId', isNull: true)
                                .get(),
                            builder: (context, unreadSnapshot) {
                              int unreadCount = 0;
                              if (unreadSnapshot.hasData) {
                                unreadCount = unreadSnapshot.data!.docs.length;
                              }
                              
                              return Column(
                                children: [
                                  Chatpill(
                                    messages: lastMessage.isNotEmpty 
                                        ? lastMessage 
                                        : 'No messages yet',
                                    avatar: otherUserProfile.isNotEmpty 
                                        ? otherUserProfile 
                                        : 'https://via.placeholder.com/150',
                                    names: otherUserName,
                                    newvcount: unreadCount.toString(),
                                    status: lastSeen != null 
                                        ? DateTime.now().difference(lastSeen.toDate()).inMinutes < 5
                                        : false,
                                    cuid: otherUserId!, // Fixed null safety
                                  ),
                                  const SizedBox(height: 2),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
