import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easingles/Components/Chatpill.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Models/models.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:http/http.dart' as http;
import 'package:easingles/assets/urlconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> {
  bool isLoading = true;
  List<ChatInfo> chats = [];

  @override
  void initState() {
    super.initState();
    chats = [];
    getchats();
  }

  String? usergenerator(obj) {
    return "";
  }

  void getchats() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? id = pref.getString("id");
    String? token = pref.getString("token");
    var url = Uri.parse('${AppUrls.production}/api/conversation/${id}');
    var response = await http.get(url,headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case 200:
        print(response.body);
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print(jsonResponse['conversations']);
        print(jsonResponse['conversations'] is List);
        if (jsonResponse.containsKey('conversations') &&
            jsonResponse['conversations'] is List) {
          List<dynamic> conversationsList = jsonResponse['conversations'];
          for (var c in jsonResponse['conversations']) {
            ChatInfo chatInfo = ChatInfo.fromJson(c);
            chats.add(chatInfo);
          }
          setState(() {
            isLoading = false;
          });
        }
        ;
      case 404:
        print('Not Found');
        break;
      default:
        print('Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(title: "Messages", background: AppColors.lighter),
      body: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : chats.isEmpty
                    ? Center(child: Text("No conversations available"))
                    : ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (BuildContext context, int index) {
                          var singlechat = chats[index];
                          return Column(
                            children: [
                              Chatpill(
                                messages: singlechat.messages.isNotEmpty
                                    ? singlechat.messages[0].sms
                                    : 'No messages', // Replace with dynamic data from API
                                avatar: singlechat.chatUser.isNotEmpty
                                    ? singlechat.chatUser[0].profilePic
                                    : 'default_avatar_url', // Replace with a default avatar URL or handle accordingly
                                names:
                                    "${singlechat.chatUser.isNotEmpty ? singlechat.chatUser[0].firstName : 'Unknown'} ${singlechat.chatUser.isNotEmpty ? singlechat.chatUser[0].lastName : ''}",
                                newvcount: singlechat.messages
                                    .where((message) => !message.seen)
                                    .length
                                    .toString(),
                                status: true,
                                cuid: singlechat.chatUser.isNotEmpty
                                    ? singlechat.chatUser[0].id.toString()
                                    : '0', // Replace with a default value or handle accordingly
                              ),
                              SizedBox(
                                height: 2,
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class ChatInfo {
  int id;
  List<User> chatUser;
  DateTime createdAt;
  List<Message> messages;

  ChatInfo({
    required this.id,
    required this.chatUser,
    required this.createdAt,
    required this.messages,
  });

  factory ChatInfo.fromJson(Map<String, dynamic> json) {
    return ChatInfo(
      id: json['id'],
      chatUser:
          List<User>.from(json['chatUser'].map((user) => User.fromJson(user))),
      createdAt: DateTime.parse(json['createdAt']),
      messages: List<Message>.from(
          json['messages'].map((message) => Message.fromJson(message))),
    );
  }
}

class User {
  int id;
  String firstName;
  String lastName;
  String profilePic;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePic,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      profilePic: json['Profilepic'],
    );
  }
}

class Message {
  int id;
  String sms;
  int sender;
  int receiver;
  bool seen;
  DateTime createdAt;

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
      id: json['id'],
      sms: json['sms'],
      sender: json['sender'],
      receiver: json['reciever'],
      seen: json['seen'],
      createdAt: DateTime.parse(json['createAt']),
    );
  }
}
