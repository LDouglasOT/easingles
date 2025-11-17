import 'dart:async';

import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:easingles/Models/Message.dart';
import 'package:easingles/Models/socketinfo.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketProvider extends ChangeNotifier {
  late SharedPreferences prefs;
  late String? userId;
  List<dynamic> userIds = [];

  List<Socketinfo> Onlineusers = [];
  late String onlinestatus;
  late IO.Socket socket = IO.io("${AppUrls.production}", <String, dynamic>{
    'transports': ['websocket'],
    'autoconnect': true,
    'reconnect': true,
  });
  void connectsocket() {
    print("socket reconnecting");
    if(!socket.connected){
    socket.connect();
    socket.onConnect((data) {
      runsocket(socket);
    });
    }
  }

  Future<bool> initsocket() async {
    try {
      connectsocket();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('id');
      String? token = prefs.getString("token");
      
      socket.connect();
      socket.onConnect((err) => {runsocket(socket), notifyListeners()});

      socket.onError((data) {
      
        Future.delayed(const Duration(seconds: 10), () {
          socket = IO.io("${AppUrls.production}", <String, dynamic>{
            'transports': ['websocket'],
            'autoconnect': true,
            'reconnect': true,
          });

          // Connect the new socket instance
          connectsocket();

          // Emit "addUser" after connecting
          socket.onConnect((data) {
            socket.emit("addUser", {"userId": userId});
          });
        });

      });

      socket.onDisconnect((data) async {
        print("socket disconnected");

        // Delay the reconnection for 10 seconds
      
        Future.delayed(const Duration(seconds: 10), () {
          socket = IO.io("${AppUrls.production}", <String, dynamic>{
            'transports': ['websocket'],
            'autoconnect': true,
            'reconnect': true,
          });

          // Connect the new socket instance
          connectsocket();

          // Emit "addUser" after connecting
          socket.onConnect((data) {
            socket.emit("addUser", {"userId": userId});
          });
        });
        // Recreate the socket instance
      });
      socket.on("getUsers", (data) {
        print(data);
        print("get users socket");
        userIds = data;
        ChangeNotifier();
      });
      return true;
    } catch (error) {
      print('Error during registration: $error');
    }
    return true;
  }

  Future<String?> getUserId() async {
    prefs = await SharedPreferences.getInstance();
    final String? id = prefs.getString('action');
    return id;
  }

  Future<void> runsocket(IO.Socket socket) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('id');
    this.userId = userId;
    socket.emit("addUser", {"userId": userId});
  }

  bool showtyping(id, idx) {
    try {
      socket.emit("typing", {"reciever": id, "from": idx});
      return false;
    } catch (data) {}
    return false;
  }

  bool stoptyping(
    id,
    idx,
  ) {
    Timer? _debounceTimer;
    // Cancel the previous timer if it exists
    _debounceTimer?.cancel();

    // Set a new timer to execute the stoptyping logic after a delay
    _debounceTimer = Timer(Duration(milliseconds: 800), () {
      try {
        socket.emit("stoptyping", {"reciever": id, "from": idx});
      } catch (error) {
        // Handle error if needed
        print("Error: $error");
      }
    });

    return false;
  }
}
