import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easingles/Models/Authmodel.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// static const url="http:localhost:3000";
class LoginProvider extends ChangeNotifier {
  late String apikey;
  late String firstname;
  late String lastName;
  late String username;
  late String password;

  Future<bool> login(
      String username,
      String password,
      BuildContext context) async {
    if (username.isEmpty || password.isEmpty) {
      const snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        content: Text(
          'Please enter your phone number and password',
          style: TextStyle(color: Colors.white),
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return false;
    }

    try {

      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/login"),
        body: {"phoneNumber": username, "password": password},
      );
      print(response);

      if (response.statusCode == 200) {
        try {
          var data = jsonDecode(response.body);
          const snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            content: Text(
              'Success, we are logging you in',
              style: TextStyle(color: Colors.white),
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          // Extract user data from decoded JSON
          User finalData = User.fromJson(data);
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', finalData.token);
          await prefs.setString('gender', finalData.gender);
          await prefs.setString('id', finalData.id);

          return true;
        } catch (e) {
          // Handle any errors during the process
          print("Error during login:");
          return false;
        }
      } else if (response.statusCode == 401) {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'Wrong password, please correct it and try again',
            style: TextStyle(color: Colors.white),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        debugPrint("Login failed: ${response.statusCode}");
        return false;
      } else if (response.statusCode == 400) {
        const snackBar = SnackBar(
          /// need to set following properties for best effect of flutter_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'User doesnot exist',
            style: TextStyle(color: Colors.white),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        debugPrint("Login failed: ${response.statusCode}");
        return false;
      } else {
        const snackBar = SnackBar(
          /// need to set following properties for best effect of flutter_snackbar_content
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'Something went wrong, please try again',
            style: TextStyle(color: Colors.white),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        debugPrint("Login failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error during login: $e");
      return false;
    }
    return false;
  }
}
