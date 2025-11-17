import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:bottom_sheet_scaffold/bottom_sheet_scaffold.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet.dart';
import 'package:bottom_sheet_scaffold/views/bottom_sheet_scaffold.dart';
import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_toastify/components/enums.dart';
import 'package:flutter_toastify/flutter_toastify.dart';
import 'package:easingles/Models/GiftsMode.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'dart:convert';

class FirebaseChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserProfile;
  final String currentUserId;
  final String currentUserName;

  const FirebaseChatScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserProfile,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  State<FirebaseChatScreen> createState() => _FirebaseChatScreenState();
}

class _FirebaseChatScreenState extends State<FirebaseChatScreen> {
  late ChatController _chatController;
  late ChatUser _currentUser;
  late ChatUser _otherUser;
  late String _conversationId;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<GiftsModel> _myGifts = [];
  bool _giftLoaderStatus = true;
  bool _isOtherUserOnline = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeUsers();
    _initializeChat();
    _fetchMyGifts();
    _listenToOnlineStatus();
    _listenToTypingStatus();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeUsers() {
    _currentUser = ChatUser(
      id: widget.currentUserId,
      name: widget.currentUserName,
    );

    _otherUser = ChatUser(
      id: widget.otherUserId,
      name: widget.otherUserName,
      profilePhoto: widget.otherUserProfile,
    );

    _conversationId = _generateConversationId(
      widget.currentUserId,
      widget.otherUserId,
    );

    _chatController = ChatController(
      initialMessageList: [],
      scrollController: ScrollController(),
      currentUser: _currentUser,
      otherUsers: [_otherUser],
    );
  }

  String _generateConversationId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  void _initializeChat() {
    // Listen to messages from Firestore
    _firestore
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _addMessageToChat(change.doc);
        }
      }
    });

    // Create conversation document if it doesn't exist
    _createConversationIfNeeded();
  }

  Future<void> _createConversationIfNeeded() async {
    final conversationRef = _firestore.collection('conversations').doc(_conversationId);
    final doc = await conversationRef.get();

    if (!doc.exists) {
      await conversationRef.set({
        'participants': [widget.currentUserId, widget.otherUserId],
        'participantDetails': {
          widget.currentUserId: {
            'name': widget.currentUserName,
            'lastSeen': FieldValue.serverTimestamp(),
          },
          widget.otherUserId: {
            'name': widget.otherUserName,
            'profilePhoto': widget.otherUserProfile,
            'lastSeen': FieldValue.serverTimestamp(),
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  void _addMessageToChat(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Skip if message is from current user (already added locally)
    if (data['senderId'] == widget.currentUserId) return;

    MessageType messageType = MessageType.text;
    if (data['isImage'] == true) {
      messageType = MessageType.image;
    } else if (data['isVoice'] == true) {
      messageType = MessageType.voice;
    }

    final message = Message(
      id: doc.id,
      message: data['message'] ?? '',
      createdAt: (data['timestamp'] as Timestamp).toDate(),
      sentBy: data['senderId'] ?? '',
      messageType: messageType,
      voiceMessageDuration: data['voiceDuration'] != null
          ? Duration(seconds: data['voiceDuration'])
          : null,
    );

    _chatController.addMessage(message);
    _markMessageAsRead(doc.id);
  }

  Future<void> _markMessageAsRead(String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(_conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'readBy.${widget.currentUserId}': FieldValue.serverTimestamp(),
    });
  }

  void _listenToOnlineStatus() {
    _firestore
        .collection('users')
        .doc(widget.otherUserId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          _isOtherUserOnline = data?['isOnline'] ?? false;
        });
      }
    });
  }

  void _listenToTypingStatus() {
    _firestore
        .collection('conversations')
        .doc(_conversationId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final typingData = data?['typing'] as Map<String, dynamic>?;
        
        setState(() {
          _isTyping = typingData?[widget.otherUserId] ?? false;
        });
        
        _chatController.setTypingIndicator = _isTyping;
      }
    });
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    await _firestore.collection('conversations').doc(_conversationId).update({
      'typing.${widget.currentUserId}': isTyping,
    });
  }

  Future<void> _fetchMyGifts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? id = prefs.getString("id");
      String? token = prefs.getString("token");
      
      var response = await http.get(
        Uri.parse("${AppUrls.production}/api/getusergifts/$id"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          List<dynamic> giftsList = jsonResponse['data'];
          setState(() {
            _myGifts = giftsList
                .map((item) => GiftsModel.fromJson(item))
                .toList();
          });
        }
      }
    } catch (error) {
      debugPrint('Error fetching gifts: $error');
    }
  }

  Future<void> _sendMessage(
    String message,
    ReplyMessage replyMessage,
    MessageType messageType,
  ) async {
    try {
      String finalMessage = message;
      Map<String, dynamic> messageData = {
        'senderId': widget.currentUserId,
        'receiverId': widget.otherUserId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isText': messageType.isText,
        'isImage': messageType.isImage,
        'isVoice': messageType.isVoice,
        'readBy': {widget.currentUserId: FieldValue.serverTimestamp()},
      };

      // Handle file uploads
      if (messageType.isImage) {
        finalMessage = await _uploadFile(message, 'images');
        messageData['message'] = finalMessage;
      } else if (messageType.isVoice) {
        final duration = await _audioPlayer.getDuration();
        finalMessage = await _uploadFile(message, 'audio');
        messageData['message'] = finalMessage;
        messageData['voiceDuration'] = duration?.inSeconds ?? 0;
      }

      // Add message to local chat immediately
      final localMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: finalMessage,
        createdAt: DateTime.now(),
        sentBy: widget.currentUserId,
        messageType: messageType,
        replyMessage: replyMessage,
      );
      _chatController.addMessage(localMessage);

      // Save to Firestore
      await _firestore
          .collection('conversations')
          .doc(_conversationId)
          .collection('messages')
          .add(messageData);

      // Update conversation metadata
      await _firestore.collection('conversations').doc(_conversationId).update({
        'lastMessage': messageType.isText ? message : 'Media',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': widget.currentUserId,
      });

    } catch (e) {
      debugPrint('Error sending message: $e');
      _showErrorSnackbar('Failed to send message');
    }
  }

  Future<String> _uploadFile(String filePath, String folder) async {
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final ref = _storage.ref().child('$folder/$_conversationId/$fileName');
      
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw Exception('Failed to upload file');
    }
  }

  Future<void> _sendGift(GiftsModel gift) async {
    setState(() => _giftLoaderStatus = false);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var body = {
        "myid": widget.currentUserId,
        "user": widget.otherUserId,
        "img": gift.image,
        "conversationId": _conversationId,
        "name": gift.name,
        "qty": "1"
      };

      var response = await http.post(
        Uri.parse('${AppUrls.production}/api/giftpeople'),
        headers: {'Authorization': 'Bearer $token'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Send gift message to Firestore
        await _firestore
            .collection('conversations')
            .doc(_conversationId)
            .collection('messages')
            .add({
          'senderId': widget.currentUserId,
          'receiverId': widget.otherUserId,
          'message': 'Sent a gift: ${gift.name}',
          'giftImage': gift.image,
          'giftValue': gift.value,
          'timestamp': FieldValue.serverTimestamp(),
          'isGift': true,
          'readBy': {widget.currentUserId: FieldValue.serverTimestamp()},
        });

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
            'You gifted ${gift.name} to ${widget.otherUserName}',
            style: const TextStyle(color: Colors.white),
          ),
          onDismiss: () {},
        ).show(context);

        await _fetchMyGifts();
      } else {
        _showErrorSnackbar('Failed to send gift');
      }
    } catch (e) {
      debugPrint('Error sending gift: $e');
      _showErrorSnackbar('Something went wrong');
    } finally {
      setState(() => _giftLoaderStatus = true);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffold(
      bottomSheet: DraggableBottomSheet(
        animationDuration: const Duration(milliseconds: 200),
        body: _buildGiftSheet(),
      ),
      body: ChatView(
        chatController: _chatController,
        onSendTap: _sendMessage,
        featureActiveConfig: const FeatureActiveConfig(
          lastSeenAgoBuilderVisibility: true,
          receiptsBuilderVisibility: true,
        ),
        chatViewState: ChatViewState.hasMessages,
        typeIndicatorConfig: const TypeIndicatorConfiguration(
          flashingCircleBrightColor: Colors.black,
          flashingCircleDarkColor: Colors.white,
        ),
        appBar: ChatViewAppBar(
          elevation: 4,
          backGroundColor: AppColors.lighter,
          profilePicture: widget.otherUserProfile,
          backArrowColor: Colors.white,
          chatTitle: widget.otherUserName,
          chatTitleTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.25,
          ),
          userStatus: _isOtherUserOnline ? "online" : "offline",
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
              _updateTypingStatus(status == TypeWriterStatus.typing);
            },
            compositionThresholdTime: const Duration(seconds: 1),
            textStyle: const TextStyle(color: Colors.white),
          ),
        ),
        chatBubbleConfig: ChatBubbleConfiguration(
          outgoingChatBubbleConfig: const ChatBubble(
            linkPreviewConfig: LinkPreviewConfiguration(
              backgroundColor: Colors.amber,
              bodyStyle: AppText.body1,
              titleStyle: AppText.header3,
            ),
            receiptsWidgetConfig: ReceiptsWidgetConfig(
              showReceiptsIn: ShowReceiptsIn.all,
            ),
            color: AppColors.background,
          ),
          inComingChatBubbleConfig: const ChatBubble(
            linkPreviewConfig: LinkPreviewConfiguration(
              linkStyle: TextStyle(
                color: Colors.amber,
                decoration: TextDecoration.underline,
              ),
              backgroundColor: AppColors.background,
              bodyStyle: AppText.body1,
              titleStyle: AppText.header3,
            ),
            textStyle: TextStyle(color: Colors.black),
            senderNameTextStyle: TextStyle(color: Colors.white),
            color: Color.fromARGB(255, 241, 177, 0),
          ),
        ),
        replyPopupConfig: const ReplyPopupConfiguration(
          backgroundColor: AppColors.background,
          buttonTextStyle: TextStyle(color: Color.fromARGB(255, 118, 97, 97)),
          topBorderColor: AppColors.lighter,
        ),
        reactionPopupConfig: const ReactionPopupConfiguration(
          shadow: BoxShadow(color: AppColors.lighter, blurRadius: 20),
          backgroundColor: AppColors.background,
        ),
        messageConfig: MessageConfiguration(
          messageReactionConfig: MessageReactionConfiguration(
            backgroundColor: AppColors.lighter,
            borderColor: AppColors.lighter,
            reactedUserCountTextStyle: const TextStyle(color: Colors.white),
            reactionCountTextStyle: const TextStyle(color: Colors.white),
            reactionsBottomSheetConfig: ReactionsBottomSheetConfiguration(
              backgroundColor: AppColors.background,
              reactedUserTextStyle: const TextStyle(color: Colors.white),
              reactionWidgetDecoration: BoxDecoration(
                color: Colors.amber,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.white,
                    offset: Offset(0, 20),
                    blurRadius: 40,
                  )
                ],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          imageMessageConfig: ImageMessageConfiguration(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            shareIconConfig: ShareIconConfiguration(
              defaultIconBackgroundColor: AppColors.background,
              defaultIconColor: Colors.white,
            ),
          ),
        ),
        repliedMessageConfig: RepliedMessageConfiguration(
          backgroundColor: AppColors.background,
          verticalBarColor: Colors.amber,
          repliedMsgAutoScrollConfig: RepliedMsgAutoScrollConfig(
            enableHighlightRepliedMsg: true,
            highlightColor: Colors.pinkAccent.shade100,
            highlightScale: 1.1,
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.25,
          ),
          replyTitleTextStyle: const TextStyle(color: Colors.white),
        ),
        swipeToReplyConfig: const SwipeToReplyConfiguration(
          replyIconColor: AppColors.background,
        ),
      ),
    );
  }

  Widget _buildGiftSheet() {
    return Container(
      decoration: BoxDecoration(color: AppColors.background),
      width: double.infinity,
      height: 500,
      child: _myGifts.isEmpty
          ? const Center(
              child: Text(
                'No gifts available',
                style: TextStyle(color: Colors.white),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: _myGifts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
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
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 15),
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
                            const SizedBox(height: 5),
                            Text(
                              '${gift.quantity} left',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _giftLoaderStatus
                            ? () => _sendGift(gift)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                        ),
                        child: _giftLoaderStatus
                            ? const Text('Send')
                            : const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}