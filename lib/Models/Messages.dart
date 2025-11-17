import 'package:easingles/Models/models.dart';

class Message {
  int id;
  String sms;
  Conversation conversation;
  int conversationId;
  int sender;
  int reciever;
  bool seen;
  DateTime createAt;
  bool gift;
  String? giftImage;
  int? price;
  int? quantity;

  Message({
    required this.id,
    required this.sms,
    required this.conversation,
    required this.conversationId,
    required this.sender,
    required this.reciever,
    required this.seen,
    required this.createAt,
    required this.gift,
    required this.giftImage,
    required this.price,
    required this.quantity,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json["id"],
        sms: json["sms"],
        conversation: Conversation.fromJson(json["conversation"]),
        conversationId: json["conversationId"],
        sender: json["sender"],
        reciever: json["reciever"],
        seen: json["seen"],
        createAt: DateTime.parse(json["createAt"]),
        gift: json["gift"],
        giftImage: json["giftImage"],
        price: json["price"],
        quantity: json["quantity"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "sms": sms,
        "conversation": conversation.toJson(),
        "conversationId": conversationId,
        "sender": sender,
        "reciever": reciever,
        "seen": seen,
        "createAt": createAt.toIso8601String(),
        "gift": gift,
        "giftImage": giftImage,
        "price": price,
        "quantity": quantity,
      };
}
