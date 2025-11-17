import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easingles/Pages/Notifications.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketProvider extends ChangeNotifier {

  late String notificationsCounter;
  late String notificationsList;

    void getNotifications() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? id = pref.getString('id');
    String? token = pref.getString('token');
    var url = Uri.parse('${AppUrls.production}/api/notifications/${id}');
    var response = await http.get(url); 
    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> notifications = jsonResponse['data'];
          List<Notification_profile> notify = notifications.map((e) => Notification_profile.fromJson(e)).toList();
          // setState(() {
          //   notification = notify;
          // });
        }
        break;
      case 404:
        print('Not Found');
        break;
      default:
        print('error');
    }

  }



}
