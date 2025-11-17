// To parse this JSON data, do
//
//     final giftsModel = giftsModelFromJson(jsonString);

import 'dart:convert';

GiftsModel giftsModelFromJson(String str) => GiftsModel.fromJson(json.decode(str));

String giftsModelToJson(GiftsModel data) => json.encode(data.toJson());

class GiftsModel {
    int id;
    int? giftId;
    int? value;
    int? quantity;
    String? name;
    String? image;

    GiftsModel({
        required this.id,
        this.giftId,
        this.value,
        this.quantity,
        this.name,
        this.image,
    });

    factory GiftsModel.fromJson(Map<String, dynamic> json) => GiftsModel(
        id: json["id"],
        giftId: json["giftId"],
        value: json["Value"],
        quantity: json["quantity"],
        name: json["Name"],
        image: json["Image"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "giftId": giftId,
        "Value": value,
        "quantity": quantity,
        "Name": name,
        "Image": image,
    };
}
