import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_snackbar_content/flutter_snackbar_content.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:http/http.dart' as http;

class RegisterProvider extends ChangeNotifier {
  late String phoneNumber;
  late String userId;
  late List<XFile> userImages;
  late String gender;
  late String firstname;
  late String lastname;
  late DateTime dateofbirth;
  late String decorder;
  late String accountpin;
  late String phoneAccount;
  late String passcode;

  Future<bool> sendotp(
      String phonenumber,
      BuildContext context) async {
    try {
      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/generateotp"),
        body: {"PhoneNumber": phonenumber},
      );
      print(response);
      switch (response.statusCode) {
        case 200:
          phoneNumber = phonenumber;
          // Decode the response body JSON
          Map<String, dynamic> responseBody = json.decode(response.body);
          String decorded = responseBody['decorder'];
          decorder = decorded;
          // Add your code here to handle the decorder if needed
          notifyListeners();
          return true;
          break;

        case 404:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message:
                  'A user registered with this phone number already exists.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
        case 500:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message:
                  'Something went wrong, check phone number and try again.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
        case 400:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Please check your phone number and try again.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
          break;
        default:
          print("Something bad happened");
          return false;
      }
    } catch (Error) {
      return false;
      print(Error);
    }
  }

  Future<bool> sendconfirmationotp(
      String phonenumber,
      BuildContext context) async {
    try {
      print("Engaging the current user");
      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/resetotp"),
        body: {"PhoneNumber": phonenumber},
      );
      print(response);
      switch (response.statusCode) {
        case 200:
          // Handle success
          phoneNumber = phonenumber;
          // Decode the response body JSON
          Map<String, dynamic> responseBody = json.decode(response.body);
          String decorded = responseBody['decorder'];
          decorder = decorded;
          // Add your code here to handle the decorder if needed
          notifyListeners();
          return true;
          break;
        case 404:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message:
                  'A user registered with this phone number doesnot exists.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
          break;
        case 400:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Please check your phone number and try again',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
          break;
        case 500:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Something went wrong, please try again.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
        default:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Please check your phone number and try again.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
      }
    } catch (Error) {
      print(Error);
      return false;
    }
  }

  Future<bool> verifyotp(String pin, BuildContext context) async {
    try {
      print(decorder);
      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/verifyotp"),
        body: {"PhoneNumber": phoneNumber, "token": pin, "decorder": decorder},
      );
      switch (response.statusCode) {
        case 200:
          accountpin = pin;
          notifyListeners();
          print("200 status code recieved");
          return true;
          break;
        case 400:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Wrong otp provided, please enter a correct otp.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
        default:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Something went wrong please try again.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
      }
    } catch (err) {
      print(err.toString());
      const snackBar = SnackBar(
        /// need to set following properties for best effect of flutter_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: FlutterSnackbarContent(
          message: 'Something went wrong please try again.',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return false;
    }
  }

  Future<bool> verifyconfirmationotp(String password, BuildContext context,
      String phonenumber) async {
    try {
      var response = await http.post(
        Uri.parse("${AppUrls.production}/api/verifyresetotp"),
        body: {
          "PhoneNumber": phoneNumber,
          "token": accountpin,
          "decorder": decorder,
          "password": password
        },
      );
      switch (response.statusCode) {
        case 200:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Success, proceed to login',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.success,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return true;
          break;
        default:
          const snackBar = SnackBar(
            /// need to set following properties for best effect of flutter_snackbar_content
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: FlutterSnackbarContent(
              message: 'Something went wrong please try again.',

              /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
              contentType: ContentType.failure,
            ),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
          return false;
      }
    } catch (err) {
      print(err.toString());
      const snackBar = SnackBar(
        /// need to set following properties for best effect of flutter_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: FlutterSnackbarContent(
          message: 'Something went wrong please try again.',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return false;
    }
  }

  Future<bool> registration(List<File?> userImages) async {
    // Convert XFile to List<int>
    List<List<int>> imageBytesList =
        await Future.wait(userImages.map((image) async {
      if (image != null) {
        return await image.readAsBytes();
      } else {
        // Handle the case when the file is null (optional)
        return <int>[];
      }
    }));
    // Create a multipart request
    var request = http.MultipartRequest(
        'POST', Uri.parse('${AppUrls.production}/api/uploadimages'));

    // Add fields
    request.fields['phoneNumber'] = this.phoneNumber;
    request.fields['gender'] = gender;
    request.fields['firstname'] = firstname;
    request.fields['lastname'] = lastname;
    request.fields['dateofbirth'] = dateofbirth.toIso8601String();
    request.fields['passcode'] = this.passcode;
    // Add images
    for (int i = 0; i < imageBytesList.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'userImages',
          imageBytesList[i],
          filename: '$firstname$lastname$i.jpg',
        ),
      );
    }

    try {
      // Send the request
      var response = await request.send();

      // Check if the request was successful (status code 200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Timer(Duration(seconds: 3), () {
        //       btnController.stop();
        // });
        return true;
      } else {
        // Handle error
        print(
            'Failed to submit registration. Status code: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      // Handle error
      print('Error during registration: $error');
      return false;
    }
  }

  bool phonenumberinput(String firstname, String lastname, BuildContext context) {
    if (firstname.isEmpty || lastname.isEmpty) {
      const snackBar = SnackBar(
        /// need to set following properties for best effect of flutter_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: FlutterSnackbarContent(
          message: 'Please provide your firstname and lastname above',

          /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return false;
    }
    this.firstname = firstname;
    this.lastname = lastname;
    notifyListeners();
    return true;
  }

  bool passwordInput(String firstname, String lastname, BuildContext context) {
    passcode = firstname;
    notifyListeners();
    print("returning the user");
    return true;
  }

  bool gender_age(String gender, DateTime birthday, BuildContext context) {
    debugPrint(gender);
    debugPrint(birthday.toString());
    print(gender);
    if (gender == "null") {
      const snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: FlutterSnackbarContent(
          message: 'Select your gender and try again.',
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return false;
    }

    if (((DateTime.now().difference(birthday).inDays) / 360) < 18) {
      const snackBar = SnackBar(
        /// need to set following properties for best effect of flutter_snackbar_content
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: FlutterSnackbarContent(
          message: 'You must be 18 years and above to register.',
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return false;
    }
    if (gender == "Gender.Male") {
      gender = "Male";
    } else if (gender == "Gender.Female") {
      gender = "Female";
    } else {
      gender = "other";
    }
    print(gender);
    this.gender = gender;
    this.dateofbirth = birthday;
    notifyListeners();
   
      return true;
  }
}
