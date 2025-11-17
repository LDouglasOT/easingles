class Messaging {
  String userId;
  String message;
  DateTime time; // Change type to DateTime
  bool? isText = false;
  bool? isImage = false;
  bool? isReply = false;
  String replyId;
  String reaction;
  String sendto;
  String? chatId;
  bool? isAudio = false;
  String? duration;

  Messaging({
    required this.userId,
    required this.message,
    required this.time,
    this.isText,
    this.isImage,
    this.isReply,
    required this.replyId,
    required this.reaction,
    required this.sendto,
    this.chatId,
    this.isAudio,
    this.duration,
  });

  factory Messaging.fromJson(Map<String, dynamic> json) => Messaging(
        userId: json["userId"],
        message: json["message"],
        time: DateTime.parse(json["time"]), // Parse string to DateTime
        isText: json["isText"],
        isImage: json["isImage"],
        isReply: json["isReply"],
        replyId: json["replyId"],
        reaction: json["reaction"],
        sendto: json["sendto"],
        chatId: json["chatId"],
        isAudio: json["isAudio"],
        duration: json["duration"],
      );

  Map<String, dynamic> toJson() => {
        "userId": userId,
        "message": message,
        "time": time.toIso8601String(), // Convert DateTime to string
        "isText": isText,
        "isImage": isImage,
        "isReply": isReply,
        "replyId": replyId,
        "reaction": reaction,
        "sendto": sendto,
        "chatId": chatId,
        "isAudio": isAudio,
        "duration": duration,
      };
}
