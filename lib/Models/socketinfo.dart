// To parse this JSON data, do
//
//     final socketinfo = socketinfoFromJson(jsonString);

import 'dart:convert';

Socketinfo socketinfoFromJson(String str) => Socketinfo.fromJson(json.decode(str));

String socketinfoToJson(Socketinfo data) => json.encode(data.toJson());

class Socketinfo {
    String userId;
    String socketId;

    Socketinfo({
        required this.userId,
        required this.socketId,
    });

    factory Socketinfo.fromJson(Map<String, dynamic> json) => Socketinfo(
        userId: json["userId"],
        socketId: json["socketId"],
    );

    Map<String, dynamic> toJson() => {
        "userId": userId,
        "socketId": socketId,
    };
}
