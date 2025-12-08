
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:easingles/Models/Authmodel.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

class LoginProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late String apikey;
  late String firstname;
  late String lastName;
  late String username;
  late String password;


  Future<bool> loginWithEmail(String email, String password, BuildContext context) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Text(
            'Success! Authenticated via Firebase. Logging you in...',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('firebase_uid', userCredential.user!.uid);
      await prefs.setString('id', userCredential.user!.uid);

      return true;

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Invalid login credentials. Please check your email and password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This user account has been disabled.';
      } else {
        errorMessage = 'Login failed: ${e.message ?? 'An unknown Firebase error occurred.'}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text(
            'An unexpected error occurred: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return false;
    }
  }
  
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
          final User finalData = User.fromJson(data);
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', finalData.token);
          await prefs.setString('gender', finalData.gender);
          await prefs.setString('id', finalData.id);

          return true;
        } catch (e) {
          print("Error during login (JSON parsing/Storage): $e");
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
        debugPrint("Login failed (401): ${response.statusCode}");
        return false;
      } else if (response.statusCode == 400) {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text(
            'User does not exist',
            style: TextStyle(color: Colors.white),
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        debugPrint("Login failed (400): ${response.statusCode}");
        return false;
      } else {
        const snackBar = SnackBar(
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
      debugPrint("Error during login (Network/Other): $e");
      return false;
    }
  }
}