// To parse this JSON data, do
//
//     final photos = photosFromJson(jsonString);

import 'dart:convert';

Photo photosFromJson(String str) => Photo.fromJson(json.decode(str));

String photosToJson(Photo data) => json.encode(data.toJson());

class Photo {
    int id;
    int loginId;
    String uri;
    String createdAt;

    Photo({
        required this.id,
        required this.loginId,
        required this.uri,
        required this.createdAt,
    });

    factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: json["id"],
        loginId: json["loginId"],
        uri: json["uri"],
        createdAt: json["createdAt:"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "loginId": loginId,
        "uri": uri,
        "createdAt:": createdAt,
    };
}
