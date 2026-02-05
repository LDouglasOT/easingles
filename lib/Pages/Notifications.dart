import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


class Notifications extends StatefulWidget {
  const Notifications({Key? key}) : super(key: key);

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<Notification_profile> notification = [];

  void initState(){
    super.initState();
    getNotifications();
  }
  void getNotifications() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? id = pref.getString('id');
    String? token = pref.getString('token');  
    var url = Uri.parse('${AppUrls.production}/api/notifications/${id}');
    var response = await http.get(url,
      headers: {'Authorization': 'Bearer $token'},
      ); 
    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> notifications = jsonResponse['data'];
          List<Notification_profile> notify = notifications.map((e) => Notification_profile.fromJson(e)).toList();
          setState(() {
            notification = notify;
          });
        }
        break;
      case 404:
        print('Not Found');
        break;
      default:
        print('error');
    }

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(onPressed: (){
          Navigator.of(context).pop();
        }, icon: Icon(Icons.arrow_back)),
        title: Text('${notification.length} New Notifications'),
        backgroundColor: AppColors.lighter,
      ),
      body: Column(
        children: [
          
          if(notification.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: notification.length, // Change this to the number of notifications
              itemBuilder: (BuildContext context, int index) {
                Notification_profile notifiy = notification[index ];
                return NotificationCard(
                  title: notifiy.header ?? '',
                  content: notifiy.message,
                  time: notifiy.timeAgo(), // Replace with the actual timestamp
                );
              },
            ),
          ),
        if(notification.isEmpty)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 100),
                  Text('No Notifications'),
                  SizedBox(height: 10),
                  ElevatedButton(onPressed: (){
                    getNotifications();
                  }, child: Text('Refresh'))
                ],
              ),)
        ],
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String content;
  final String time;

  NotificationCard({
    required this.title,
    required this.content,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.lighter,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(color: Colors.amber),
            ),
            SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.notifications),
        onTap: () {
          // Handle notification tap
        },
      ),
    );
  }
}


class Notification_profile {
  final int id;
  final String message;
  final String? header;
  final bool global;
  final String userId;
  final DateTime date;
  final bool seen;

  Notification_profile({
    required this.id,
    required this.message,
    this.header,
    required this.global,
    required this.userId,
    required this.date,
    required this.seen,
  });

  factory Notification_profile.fromJson(Map<String, dynamic> json) {
    return Notification_profile(
      id: json['id'] as int,
      message: json['message'] as String,
      header: json['header'] as String?,
      global: json['global'] as bool,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      seen: json['seen'] as bool,
    );
  }

  String timeAgo() {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}
