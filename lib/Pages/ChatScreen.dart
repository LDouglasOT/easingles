import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:bottom_sheet_scaffold/bottom_sheet_scaffold.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet_scaffold.dart';
import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:flutter_toastify/components/enums.dart';
import 'package:flutter_toastify/flutter_toastify.dart';
import 'package:mazale/Models/GiftsMode.dart';
import 'package:mazale/Models/Message.dart';
import 'package:mazale/Helpers/ChatDatabaseHelper.dart';
import 'package:mazale/Provider/SocketProvider.dart';
import 'package:mazale/assets/app.colors.dart';
import 'package:mazale/assets/urlconfig.dart';
import 'package:mazale/styles/app.text.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:math';


class ChatScreen extends StatefulWidget {
  final String valueToPass;
  final String names;
  final String profile;
  final String userId;
  final String username;

  const ChatScreen({
    Key? key,
    required this.valueToPass,
    required this.names,
    required this.profile,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late final ChatController _chatController;
  late final ChatUser _currentUser;
  late final ChatUser _otherUser;
  
  String? _conversationId;
  bool _isUserOnline = false;
  bool _giftLoaderStatus = true;
  bool _isLoading = true;
  bool _isSyncing = false;
  List<GiftsModel> _myGifts = [];

  // Offline database helper
  final ChatDatabaseHelper _dbHelper = ChatDatabaseHelper();

  late StreamSubscription<List<Map<String, dynamic>>> _messageSubscription;
  late final Stream<List<Map<String, dynamic>>> _messagesStream;
  
  final AudioPlayer _player = AudioPlayer();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<SocketProvider>().isInChat = true;
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<SocketProvider>().isInChat = false;
    _player.dispose();
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override


  void _initializeChat() {
    _currentUser = ChatUser(
      id: widget.userId,
      name: widget.username,
    );

    _otherUser = ChatUser(
      id: widget.valueToPass,
      name: widget.names,
      profilePhoto: widget.profile,
    );

    _chatController = ChatController(
      initialMessageList: [],
      scrollController: _scrollController,
      currentUser: _currentUser,
      otherUsers: [_otherUser],
    );

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // First load offline messages immediately
    await _loadOfflineMessagesFirst();
    
    // Then fetch gifts and sync with server
    await Future.wait([
      _syncConversation(),
      _fetchMyGifts(),
    ]);
  }

  /// Load offline messages first for instant display
  Future<void> _loadOfflineMessagesFirst() async {
    try {
      // Try to find existing conversation ID from offline storage
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('id');
      
      // Check if we have cached messages for this user pair
      final conversations = await _dbHelper.getConversations();
      final existingConv = conversations.firstWhere(
        (c) => c['participant_id'] == widget.valueToPass,
        orElse: () => {},
      );
      
      if (existingConv.isNotEmpty && existingConv['id'] != null) {
        _conversationId = existingConv['id'];
        
        // Load cached messages (up to 100)
        final cachedMessages = await _dbHelper.getMessages(_conversationId!, limit: 100);
        
        if (cachedMessages.isNotEmpty) {
          for (var m in cachedMessages.reversed) {
            _addMessageToController(
              message: m['message'],
              sendBy: m['sender_id'],
              isText: m['is_text'] == 1,
              createdAt: DateTime.parse(m['created_at']),
            );
          }
          
          // Show messages immediately, then sync
          setState(() {
            _isLoading = false;
            _isSyncing = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading offline messages: $e');
    }
  }

  /// Sync with server and update messages
  Future<void> _syncConversation() async {
    setState(() => _isSyncing = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('id');
      final token = prefs.getString('token');

      if (currentUserId == null || token == null) {
        _showError('User not authenticated');
        setState(() {
          _isLoading = false;
          _isSyncing = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse('${AppUrls.production}/api/conversations/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'participants': [int.parse(currentUserId), int.parse(widget.valueToPass)]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final conversation = jsonDecode(response.body);
        _conversationId = conversation['id'].toString();

        // Save conversation to offline database
        await _saveConversationToOffline();

        // Load and save messages from server
        if (conversation['messages'] != null) {
          final serverMessages = conversation['messages'] as List;
          
          // Prepare messages for offline storage
          final messagesToSave = serverMessages.take(100).map((m) => {
            'id': m['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'conversation_id': _conversationId!,
            'sender_id': m['sender'].toString(),
            'receiver_id': m['receiver']?.toString() ?? widget.valueToPass,
            'message': m['sms'],
            'is_text': (m['is_text'] ?? true) ? 1 : 0,
            'is_image': (m['is_text'] == false) ? 1 : 0,
            'is_audio': 0,
            'is_read': 1,
            'created_at': m['created_at'],
            'synced': 1,
          }).toList();
          
          // Save to offline database (replaces old messages)
          await _dbHelper.insertMessagesForConversation(_conversationId!, messagesToSave);
          
          // Clear and reload messages in controller
          _chatController.initialMessageList.clear();
          
          for (var m in serverMessages) {
            _addMessageToController(
              message: m['sms'],
              sendBy: m['sender'].toString(),
              isText: m['is_text'] ?? true,
              createdAt: DateTime.parse(m['created_at']),
            );
          }
        }

        // Initialize socket for this conversation
        _initializeSocketForChat();
        
        // Sync any unsynced messages
        await _syncUnsyncedMessages();
      } else {
        _showError('Failed to load conversation ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error syncing conversation: $e');
      // Don't show error if we have offline messages
      if (_chatController.initialMessageList.isEmpty) {
        _showError('Failed to load messages');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSyncing = false;
        });
      }
    }
  }

  /// Save message to offline database
  Future<void> _saveMessageToOffline({
    required String messageId,
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String message,
    required bool isText,
    required DateTime createdAt,
    bool synced = true,
  }) async {
    try {
      await _dbHelper.insertMessage({
        'id': messageId,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'is_text': isText ? 1 : 0,
        'is_image': !isText ? 1 : 0,
        'is_audio': 0,
        'is_read': 0,
        'created_at': createdAt.toIso8601String(),
        'synced': synced ? 1 : 0,
      });
    } catch (e) {
      debugPrint('Error saving message to offline: $e');
    }
  }

  /// Save conversation to offline database
  Future<void> _saveConversationToOffline() async {
    if (_conversationId == null) return;

    try {
      await _dbHelper.insertConversation({
        'id': _conversationId!,
        'participant_id': widget.valueToPass,
        'participant_name': widget.names,
        'participant_profile': widget.profile,
        'last_message': '',
        'last_message_time': DateTime.now().toIso8601String(),
        'unread_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving conversation to offline: $e');
    }
  }

  /// Sync unsynced messages when online
  Future<void> _syncUnsyncedMessages() async {
    try {
      final unsyncedMessages = await _dbHelper.getUnsyncedMessages();
      
      for (var message in unsyncedMessages) {
        final socket = context.read<SocketProvider>().socket;
        if (socket != null && socket.connected) {
          socket.emit('message:send', {
            'conversationId': message['conversation_id'],
            'receiverId': message['receiver_id'],
            'sms': message['message'],
            'isImage': message['is_image'] == 1,
            'gift': false,
            'giftData': null,
          });
          
          // Mark as synced
          await _dbHelper.markMessageAsSynced(message['id']);
        }
      }
    } catch (e) {
      debugPrint('Error syncing messages: $e');
    }
  }

  void _initializeSocketForChat() {
    final socket = context.read<SocketProvider>().socket;
    if (socket == null || !socket.connected) return;

    // Emit chat:init
    socket.emit('chat:init', {
      'conversationId': _conversationId,
      'otherUserId': widget.valueToPass,
    });

    // Listen for new messages
    socket.on('message:new', (data) async {
      if (!mounted) return;
      
      final messageId = data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final createdAt = DateTime.parse(data['timestamp']);
      
      _addMessageToController(
        message: data['sms'],
        sendBy: data['sender_id'].toString(),
        isText: data['is_text'] ?? true,
        createdAt: createdAt,
      );

      // Save incoming message to offline database
      if (_conversationId != null) {
        await _saveMessageToOffline(
          messageId: messageId,
          conversationId: _conversationId!,
          senderId: data['sender_id'].toString(),
          receiverId: widget.userId,
          message: data['sms'],
          isText: data['is_text'] ?? true,
          createdAt: createdAt,
          synced: true,
        );
      }
    });
  }

 
  void _addMessageToController({
    required String message,
    required String sendBy,
    required bool isText,
    required DateTime createdAt,
    ReplyMessage replyMessage = const ReplyMessage(),
  }) {
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    _chatController.addMessage(
      Message(
        id: messageId,
        message: message,
        createdAt: createdAt,
        sentBy: sendBy,
        replyMessage: replyMessage,
        messageType: isText ? MessageType.text : MessageType.image,
      ),
    );
  }

  Future<void> _downloadAndPlayAudio(Messaging messaging) async {
    try {
      final response = await http.get(Uri.parse(messaging.message));
      final documentsPath = await getApplicationDocumentsDirectory();
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999)}.m4a';
      final localFilePath = '${documentsPath.path}/$uniqueFileName';

      final file = File(localFilePath);
      await file.writeAsBytes(response.bodyBytes);

      _addMessageToController(
        message: localFilePath,
        sendBy: _otherUser.id,
        isText: false,
        createdAt: messaging.time,
      );
    } catch (e) {
      debugPrint('Error downloading audio: $e');
    }
  }

  Future<void> _fetchMyGifts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString("id");
      final token = prefs.getString("token");

      if (id == null || token == null) return;

      final response = await http.get(
        Uri.parse("${AppUrls.production}/api/getusergifts/$id"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] is List) {
          final giftsList = jsonResponse['data'] as List;
          if (mounted) {
            setState(() {
              _myGifts = giftsList
                  .map((item) => GiftsModel.fromJson(item))
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching gifts: $e');
    }
  }

  Future<void> _sendGift(GiftsModel gift) async {
    if (_conversationId == null) return;

    setState(() => _giftLoaderStatus = false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${AppUrls.production}/api/giftpeople'),
        headers: {'Authorization': 'Bearer $token'},
        body: {
          "myid": _currentUser.id,
          "user": widget.valueToPass,
          "img": gift.image,
          "conversationId": _conversationId!,
          "name": gift.name,
          "qty": "1"
        },
      );

      if (response.statusCode == 200) {
        _handleGiftSuccess(gift);
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        _showError('Insufficient ${gift.name}');
      } else {
        _showError('Failed to send gift');
      }
    } catch (e) {
      debugPrint('Error sending gift: $e');
      _showError('Something went wrong');
    } finally {
      if (mounted) {
        setState(() => _giftLoaderStatus = true);
        await _fetchMyGifts();
      }
    }
  }

  void _handleGiftSuccess(GiftsModel gift) {
    FlutterToastify.success(
      background: AppColors.background,
      width: 360,
      notificationPosition: NotificationPosition.topLeft,
      animation: AnimationType.fromTop,
      title: Row(
        children: [
          Image.network(gift.image ?? "", height: 20, width: 20),
          const SizedBox(width: 8),
          Text(
            gift.name ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      description: Text(
        'You have gifted 1 ${gift.name} to ${_otherUser.name}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.normal,
        ),
      ),
      onDismiss: () {},
    ).show(context);

    _addMessageToController(
      message: "You have gifted 1 ${gift.name} worth UGX ${gift.value}",
      sendBy: _currentUser.id,
      isText: true,
      createdAt: DateTime.now(),
    );

    final messaging = Messaging(
      userId: _currentUser.id,
      message: gift.image.toString(),
      time: DateTime.now(),
      replyId: '',
      reaction: '',
      isImage: true,
      sendto: _otherUser.id,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: FlutterSnackbarContent(
          message: message,
          contentType: ContentType.failure,
        ),
      ),
    );
  }

  Future<void> _onSendTap(
    String message,
    ReplyMessage replyMessage,
    MessageType messageType,
  ) async {
    if (_conversationId == null) return;

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = DateTime.now();

    _addMessageToController(
      message: message,
      sendBy: _currentUser.id,
      isText: messageType == MessageType.text,
      createdAt: createdAt,
    );

    // Save to offline database immediately (synced = false until confirmed)
    await _saveMessageToOffline(
      messageId: messageId,
      conversationId: _conversationId!,
      senderId: _currentUser.id,
      receiverId: widget.valueToPass,
      message: message,
      isText: messageType == MessageType.text,
      createdAt: createdAt,
      synced: false,
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_chatController.initialMessageList.isNotEmpty) {
        _chatController.initialMessageList.last.setStatus = MessageStatus.pending;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (_chatController.initialMessageList.isNotEmpty) {
        _chatController.initialMessageList.last.setStatus = MessageStatus.delivered;
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (messageType == MessageType.text) {
        await _sendTextMessage(message, token, messageId);
      } else if (messageType == MessageType.image) {
        await _sendImageMessage(message, token, messageId);
      } else if (messageType == MessageType.voice) {
        await _sendVoiceMessage(message, token, messageId);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      _showError('Failed to send message. Will retry when online.');
    }
  }

 Future<void> _sendTextMessage(String message, String? token, String messageId) async {
   final socket = context.read<SocketProvider>().socket;

   if (socket == null || !socket.connected || _conversationId == null) {
     // Message saved offline, will sync later
     return;
   }

   socket.emit('message:send', {
     'conversationId': _conversationId,
     'receiverId': widget.valueToPass,
     'sms': message,
     'isImage': false,
     'gift': false,
     'giftData': null,
   });

   // Mark as synced
   await _dbHelper.markMessageAsSynced(messageId);
 }

 Future<void> _sendImageMessage(String imagePath, String? token, String messageId) async {
   final socket = context.read<SocketProvider>().socket;

   if (socket == null || !socket.connected || _conversationId == null) {
     return;
   }

   try {
     final imageUrl = await _uploadFile(imagePath, "image");

     socket.emit('message:send', {
       'conversationId': _conversationId,
       'receiverId': widget.valueToPass,
       'sms': imageUrl,
       'isImage': true,
       'gift': false,
       'giftData': null,
     });

     await _dbHelper.markMessageAsSynced(messageId);
   } catch (e) {
     debugPrint('Error sending image: $e');
     _showError('Failed to send image');
   }
 }

Future<void> _sendVoiceMessage(String audioPath, String? token, String messageId) async {
  final socket = context.read<SocketProvider>().socket;

  if (socket == null || !socket.connected || _conversationId == null) {
    return;
  }

  try {
    final audioUrl = await _uploadFile(audioPath, "audio");

    socket.emit('message:send', {
      'conversationId': _conversationId,
      'receiverId': widget.valueToPass,
      'sms': audioUrl,
      'isImage': false,
      'gift': false,
      'giftData': null,
    });

    await _dbHelper.markMessageAsSynced(messageId);
  } catch (e) {
    debugPrint('Error sending voice message: $e');
    _showError('Failed to send voice message');
  }
}

  Future<String> _uploadFile(String filePath, String fileType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppUrls.production}/api/uploads'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('userImages', filePath));
      request.fields['fileType'] = fileType;

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseJson = await utf8.decodeStream(response.stream);
        final decodedResponse = json.decode(responseJson);
        return decodedResponse['fileUrl'].last;
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
    }

    return "https://storage.googleapis.com/flirtify-616c0.appspot.com/1704716782148-a690a210-931c-4077-b06c-e9d418433e841631404592671998134.jpg?GoogleAccessId=firebase-adminsdk-5ihbl%40flirtify-616c0.iam.gserviceaccount.com&Expires=4070898000&Signature=b4SrRrMN5YFn%2F%2FWJeWE4wFs1sU8z5KYo%2F3JTuLBJG1YksLeIu9fylvVC5A9JsL%2FbtlvK9DoAT8U3nfWYpc3DvaZxlkk1wDhy1Kf06jkOFx%2FrY32l9An7BKMpBIsW4w7zO48Lm07RYSkLbd8pG98moiGqk61i9RMrgqIL%2FAJyNuPpSw7VIH%2Bh4dnUy%2FE%2BHmDV1G%2BePOVba6uIKkZcSPqE71P39jd54o4nfDzbaYoljFXB7QSP%2FWlhJIW504b7nT5YiojI%2BNycPAH280gFgzBeTRn9xhtH3xy7TtBDXyJoY26mEeQ%2BUC6hkT5vwSleyn0kDKFKWwkAtJH8JzB%2BR%2F22Yw%3D%3D";
  }

  @override
  Widget build(BuildContext context) {
    _checkOnlineUsers();

    return BottomSheetScaffold(
      bottomSheet: DraggableBottomSheet(
        animationDuration: const Duration(milliseconds: 200),
        body: Container(
          decoration: BoxDecoration(color: AppColors.background),
          width: double.infinity,
          height: 500,
          child: _buildGiftsList(),
        ),
      ),
          body: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : Stack(
          children: [
            ChatView(
              chatController: _chatController,
              onSendTap: _onSendTap,
                  featureActiveConfig: const FeatureActiveConfig(
                    enableTextField: true,
                    enableSwipeToReply: true,
                    enableSwipeToSeeTime: true,
                  ),
                  chatViewState: ChatViewState.hasMessages,
                  chatViewStateConfig: ChatViewStateConfiguration(
                    loadingWidgetConfig: const ChatViewStateWidgetConfiguration(
                      loadingIndicatorColor: Colors.white,
                    ),
                    onReloadButtonTap: _syncConversation,
                  ),
                  typeIndicatorConfig: const TypeIndicatorConfiguration(
                    flashingCircleBrightColor: Colors.black,
                    flashingCircleDarkColor: Colors.white,
                  ),
                  appBar: ChatViewAppBar(
                    elevation: 4,
                    backGroundColor: AppColors.lighter,
                    profilePicture: _otherUser.profilePhoto,
                    backArrowColor: Colors.white,
                    chatTitle: _otherUser.name,
                    chatTitleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.25,
                    ),
                    userStatus: _isUserOnline ? "online" : "offline",
                    userStatusTextStyle: const TextStyle(color: Colors.white),
                    actions: [
                      IconButton(
                        onPressed: () {
                          if (BottomSheetPanel.isOpen) {
                            BottomSheetPanel.close();
                          } else {
                            BottomSheetPanel.open();
                          }
                        },
                        icon: const Icon(Icons.card_giftcard, color: Colors.white),
                      ),
                    ],
                  ),
                  chatBackgroundConfig: const ChatBackgroundConfiguration(
                    messageTimeIconColor: Colors.white,
                    messageTimeTextStyle: TextStyle(color: Colors.white),
                    defaultGroupSeparatorConfig: DefaultGroupSeparatorConfiguration(
                      textStyle: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    backgroundColor: AppColors.lighter,
                  ),
                  sendMessageConfig: SendMessageConfiguration(
                    imagePickerIconsConfig: const ImagePickerIconsConfiguration(
                      cameraIconColor: Colors.white,
                      galleryIconColor: Colors.white,
                    ),
                    replyMessageColor: Colors.white,
                    defaultSendButtonColor: Colors.white,
                    replyDialogColor: AppColors.lighter,
                    replyTitleColor: Colors.amber,
                    textFieldBackgroundColor: AppColors.background,
                    closeIconColor: Colors.white,
                    textFieldConfig: TextFieldConfiguration(
                      onMessageTyping: (status) {
                        if (status == TypeWriterStatus.typing) {
                          context.read<SocketProvider>().showtyping(
                                widget.valueToPass,
                                _currentUser.id,
                              );
                        } else {
                          context.read<SocketProvider>().stoptyping(
                                widget.valueToPass,
                                _currentUser.id,
                              );
                        }
                      },
                      compositionThresholdTime: const Duration(seconds: 1),
                      textStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                  chatBubbleConfig: ChatBubbleConfiguration(
                    outgoingChatBubbleConfig: const ChatBubble(
                      color: AppColors.background,
                    ),
                    inComingChatBubbleConfig: const ChatBubble(
                      textStyle: TextStyle(color: Colors.black),
                      color: Color.fromARGB(255, 241, 177, 0),
                    ),
                  ),
                  replyPopupConfig: const ReplyPopupConfiguration(
                    backgroundColor: AppColors.background,
                    buttonTextStyle: TextStyle(color: Colors.white),
                    topBorderColor: AppColors.lighter,
                  ),
                  reactionPopupConfig: const ReactionPopupConfiguration(
                    backgroundColor: AppColors.background,
                  ),
                  messageConfig: MessageConfiguration(
                    messageReactionConfig: MessageReactionConfiguration(
                      backgroundColor: AppColors.lighter,
                      borderColor: AppColors.lighter,
                    ),
                  ),
                  repliedMessageConfig: RepliedMessageConfiguration(
                    backgroundColor: AppColors.background,
                    verticalBarColor: Colors.amber,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    replyTitleTextStyle: const TextStyle(color: Colors.white),
                  ),
                  swipeToReplyConfig: const SwipeToReplyConfiguration(
                    replyIconColor: AppColors.background,
                  ),
                ),
            // Syncing indicator at top
            if (_isSyncing)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: AppColors.background.withOpacity(0.9),
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
                        'Syncing new messages...',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
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

  void _checkOnlineUsers() {
    final users = context.watch<SocketProvider>().userIds;
    final wasOnline = _isUserOnline;
    
    _isUserOnline = users.any(
      (user) => user["userId"].toString() == _otherUser.id,
    );

    if (wasOnline != _isUserOnline && mounted) {
      setState(() {});
    }
  }

  Widget _buildGiftsList() {
    if (_myGifts.isEmpty) {
      return const Center(
        child: Text(
          'No gifts available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: _myGifts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final gift = _myGifts[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  gift.image ?? "",
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    width: 80,
                    color: Colors.grey,
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift.name ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${gift.quantity} left",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _giftLoaderStatus ? () => _sendGift(gift) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: _giftLoaderStatus
                    ? const Text("Send")
                    : const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
