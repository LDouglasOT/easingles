import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Models/GiftsMode.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Buy extends StatefulWidget {
  final GiftsModel giftName;
  Buy({required this.giftName});

  @override
  State<Buy> createState() => _BuyState();
}

class _BuyState extends State<Buy> {
  bool isloading = true;
  int counter = 0;
  int price = 0;
  increment(m) {
    print("Before setState: $counter");
    setState(() {
      counter = counter + 1;
      int value = m ?? 0;
      int new_value = counter * value;

      print(new_value);
      price = new_value;
    });
    print("After setState: $counter");
  }

  decrement(m) {
    print("Before setState: $counter");
    setState(() {
      if (counter == 0) return;
      counter = counter - 1;
      int value = m ?? 0;
      int new_value = counter * value;

      print(new_value);
      price = new_value;
    });
    print("After setState: $counter");
  }

  final phoneNumberController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
          title: "Buy ${widget.giftName.name}",
          background: AppColors.background),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            color: AppColors.lighter,
          ),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text(
                  'Gift Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Name: ',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.amber,
                        ),
                      ),
                      Text(
                        widget.giftName.name ?? "",
                        style: AppText.header2,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                  child: Row(
                    children: [
                      const Text(
                        'Price: ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.amber,
                        ),
                      ),
                      Text(
                        widget.giftName.value.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Image.network(
                  widget.giftName.image ?? "",
                  height: 100,
                  width: 100,
                ),
                const SizedBox(
                  height: 20,
                ),
                Column(
                  children: [
                    Text(
                      price.toString(),
                      style: AppText.subtitle3,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => decrement(widget.giftName.value),
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 10),
                        Text(counter.toString()),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => increment(widget.giftName.value),
                          child: const Icon(Icons.plus_one),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: "Enter number to pay",
                      filled: true,
                      fillColor: AppColors.background),
                ),
                const SizedBox(
                  height: 20,
                ),
                Visibility(
                  visible: !isloading,
                  child: CircularProgressIndicator(
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (phoneNumberController.text.isEmpty) {
                      var snackBar = SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: FlutterSnackbarContent(
                          message: 'Please enter a valid phone number.',
                          contentType: ContentType.failure,
                        ),
                      );
                  
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(snackBar);
                      return;
                    }
                    if (phoneNumberController.text.length != 10) {
                      var snackBar = SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: FlutterSnackbarContent(
                          message: 'Please enter a valid phone number.',
                          contentType: ContentType.failure,
                        ),
                      );
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(snackBar);
                      return;
                    }

                    try {
                      setState(() {
                        isloading = false;
                      });
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      var id = prefs.getString('id');
                      String? token = prefs.getString('token');
                      var data = {
                        "phone": phoneNumberController.text,
                        "name": widget.giftName.name,
                        "qty": counter.toString(),
                      };
                      var response = await http.post(
                        Uri.parse('${AppUrls.production}/api/buyingift'),
                        headers: {'Authorization': 'Bearer $token'},
                        body: {
                          "phone": phoneNumberController.text,
                          "name": widget.giftName.name,
                          "qty": counter.toString(),
                          "id": id.toString(),
                          "amount": price.toString(),
                          "reason":"gift purchase of ${widget.giftName.name} at ugsh $price at ${DateTime.now()} using phone number ${phoneNumberController.text}."
                        },
                      );

                      switch (response.statusCode) {
                        case 200:
                          var snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: FlutterSnackbarContent(
                              message:
                                  'Successfully purchased ${counter.toString()} ${widget.giftName.name}.',
                              contentType: ContentType.success,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                          setState(() {
                            isloading = !isloading;
                          });
                          Timer(Duration(seconds: 3), () {
                            Navigator.of(context).pop();
                          });
                          break;
                        case 400:
                          var snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: FlutterSnackbarContent(
                              message:
                                  'Something went wrong. Please try again.',
                              contentType: ContentType.failure,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                          setState(() {
                            isloading = !isloading;
                          });
                          break;
                        case 500:
                          var snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: FlutterSnackbarContent(
                              message:
                                  'Something went wrong. Please try again.',
                              contentType: ContentType.failure,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                          setState(() {
                            isloading = !isloading;
                          });
                        break;
                        default:
                          var snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: FlutterSnackbarContent(
                              message:
                                  'Something went wrong. Please try again.',
                              contentType: ContentType.failure,
                            ),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                          setState(() {
                            isloading = true;
                          });
                      }
                    } catch (err) {
                      var snackBar = SnackBar(
                        elevation: 0,
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: Colors.transparent,
                        content: FlutterSnackbarContent(
                          message: 'Something went wrong. Please try again.',
                          contentType: ContentType.failure,
                        ),
                      );
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(snackBar);
                      print(err.toString());
                      setState(() {
                        isloading = !isloading;
                      });
                    }
                  },
                  child: Text(
                    "Pay",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
