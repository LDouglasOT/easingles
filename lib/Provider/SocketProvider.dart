import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:mazale/assets/urlconfig.dart';

class SocketProvider extends ChangeNotifier {
  IO.Socket? _socket;
  String? _userId;
  String? _token;
  List<dynamic> _userIds = [];
  bool _isConnected = false;
  bool _isInChat = false;
  Timer? _reconnectionTimer;
  Timer? _typingDebounceTimer;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  // Getters
  IO.Socket? get socket => _socket;
  List<dynamic> get userIds => _userIds;
  bool get isConnected => _isConnected;
  bool get isInChat => _isInChat;
  String? get userId => _userId;

  SocketProvider() {
    // Don't auto-initialize - wait for explicit init
  }

  /// Initialize socket connection - call this after login
  Future<void> initialize() async {
    await _initializeSocket();
  }

  Future<void> _initializeSocket() async {
      print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('id');
      _token = prefs.getString('token');

      if (_userId == null || _token == null) {
        debugPrint('User ID or token not found, cannot initialize socket');
        return;
      }

      // Initialize local notifications
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      _createSocket();
      _setupSocketListeners();
      connectsocket();
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

void _createSocket() {

  print("connecting to socket...");
  _socket = IO.io(
    'https://sugarmummiesug.online', // Use HTTPS
    IO.OptionBuilder()
        .setTransports(['websocket', 'polling']) // Allow fallback to polling
        .setPath('/nodeapp/socket.io') // CRITICAL: Nginx routes /nodeapp/ here
        .disableAutoConnect() // Disable auto connect, we'll connect manually
        .enableReconnection()
        .setReconnectionAttempts(5)
        .setReconnectionDelay(2000)
        .setReconnectionDelayMax(10000)
        .setAuth({'token': _token})
        .build(),
  );
}

  void _setupSocketListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      debugPrint('Socket connected successfully');
      _isConnected = true;
      _cancelReconnectionTimer();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
            print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      debugPrint('Socket disconnected');
      _isConnected = false;
      notifyListeners();
      _scheduleReconnection();
    });

    _socket!.onConnectError((error) {
            print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      debugPrint('Socket connection error: $error');
      _isConnected = false;
      notifyListeners();
    });

    _socket!.onError((error) {
            print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      print('............................................');
      debugPrint('Socket error: $error');
      _scheduleReconnection();
    });

    _socket!.on('user:online', (data) {
      debugPrint('User online: $data');
      final userId = data['userId'];
      if (!_userIds.any((u) => u['userId'] == userId)) {
        _userIds.add({'userId': userId});
        notifyListeners();
      }
    });

    _socket!.on('user:offline', (data) {
      debugPrint('User offline: $data');
      final userId = data['userId'];
      _userIds.removeWhere((u) => u['userId'] == userId);
      notifyListeners();
    });

    _socket!.on('users:online:status', (data) {
      debugPrint('Bulk online status: $data');
      _userIds = data.entries.map((e) => {'userId': e.key, 'online': e.value}).toList();
      notifyListeners();
    });

    _socket!.on('message:new', (data) async {
      if (!_isInChat) {
        const AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'message_channel',
          'Messages',
          channelDescription: 'Notifications for new messages',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );
        const NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        await _flutterLocalNotificationsPlugin.show(
          0,
          'New message from ${data['sender_name']}',
          data['sms'],
          platformChannelSpecifics,
        );
      }
    });

    _socket!.on('connect_timeout', (_) {
      debugPrint('Socket connection timeout');
      _scheduleReconnection();
    });
  }

  void connectsocket() {
    if (_socket == null) {
      _createSocket();
      _setupSocketListeners();
    }

    debugPrint('Attempting to connect socket...');
    debugPrint('Socket instance: $_socket');
    debugPrint('Token: ${_token?.substring(0, 20)}...'); // Log first 20 chars of token
    debugPrint('User ID: $_userId');
    
    if (!_socket!.connected) {
      _socket!.connect();
    } else {
      debugPrint('Socket already connected');
    }
  }

  void _scheduleReconnection() {
    _cancelReconnectionTimer();
    
    _reconnectionTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        debugPrint('Attempting reconnection...');
        connectsocket();
      }
    });
  }

  void _cancelReconnectionTimer() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
  }

  /// Show typing indicator
  void showtyping(String receiverId, String senderId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit("typing:start", {
        "receiverId": receiverId,
      });
      debugPrint('Emitted typing:start to: $receiverId');
    }
  }

  /// Stop typing indicator with debounce
  void stoptyping(String receiverId, String senderId) {
    _typingDebounceTimer?.cancel();

    _typingDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (_socket != null && _socket!.connected) {
        _socket!.emit("typing:stop", {
          "receiverId": receiverId,
        });
        debugPrint('Emitted typing:stop to: $receiverId');
      }
    });
  }

  /// Check if a specific user is online
  bool isUserOnline(String userId) {
    return _userIds.any((user) => user["userId"].toString() == userId);
  }

  /// Set if user is in chat
  set isInChat(bool value) {
    _isInChat = value;
  }

  /// Get count of online users
  int get onlineUserCount => _userIds.length;

  /// Force reconnection
  Future<void> forceReconnect() async {
    debugPrint('Forcing socket reconnection...');
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    connectsocket();
  }

  /// Disconnect socket
  void disconnect() {
    _cancelReconnectionTimer();
    _typingDebounceTimer?.cancel();
    
    if (_socket != null) {
      _socket!.disconnect();
      _isConnected = false;
      notifyListeners();
      debugPrint('Socket disconnected manually');
    }
  }

  /// Emit custom event
  void emitEvent(String event, dynamic data) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit(event, data);
      debugPrint('Emitted event: $event with data: $data');
    } else {
      debugPrint('Cannot emit event - socket not connected');
    }
  }

  /// Listen to custom event
  void listenToEvent(String event, Function(dynamic) callback) {
    if (_socket != null) {
      _socket!.off(event); // Remove existing listeners
      _socket!.on(event, callback);
      debugPrint('Listening to event: $event');
    }
  }

  /// Remove event listener
  void removeEventListener(String event) {
    if (_socket != null) {
      _socket!.off(event);
      debugPrint('Removed listener for event: $event');
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing SocketProvider');
    _cancelReconnectionTimer();
    _typingDebounceTimer?.cancel();
    disconnect();
    _socket?.dispose();
    super.dispose();
  }
}