import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostMoment extends StatefulWidget {
  PostMoment({super.key});

  @override
  State<PostMoment> createState() => _PostMomentState();
}

class _PostMomentState extends State<PostMoment> {
  String imageuri = "";
  bool selected = false;
  List<File?> _selectedImages = [];
  TextEditingController momentController = TextEditingController();
  bool isUploading = false;

  Future<String> uploadFile(
      String uploadUrl, List<File?> userImages, String fileType) async {
    var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
    List<List<int>> imageBytesList =
        await Future.wait(userImages.map((image) async {
      if (image != null) {
        return await image.readAsBytes();
      } else {
        // Handle the case when the file is null (optional)
        return <int>[];
      }
    }));
    for (int i = 0; i < imageBytesList.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'userImages',
          imageBytesList[i],
          filename: '$i.jpg',
        ),
      );
    }
    try {} catch (err) {
      var response = await request.send();

      if (response.statusCode == 200) {
        final responseJson = await utf8.decodeStream(response.stream);
        final decodedResponse = json.decode(responseJson);
        return decodedResponse['fileUrl'].last;
      }
    }
    return "https://storage.googleapis.com/flirtify-616c0.appspot.com/1704716782148-a690a210-931c-4077-b06c-e9d418433e841631404592671998134.jpg?GoogleAccessId=firebase-adminsdk-5ihbl%40flirtify-616c0.iam.gserviceaccount.com&Expires=4070898000&Signature=b4SrRrMN5YFn%2F%2FWJeWE4wFs1sU8z5KYo%2F3JTuLBJG1YksLeIu9fylvVC5A9JsL%2FbtlvK9DoAT8U3nfWYpc3DvaZxlkk1wDhy1Kf06jkOFx%2FrY32l9An7BKMpBIsW4w7zO48Lm07RYSkLbd8pG98moiGqk61i9RMrgqIL%2FAJyNuPpSw7VIH%2Bh4dnUy%2FE%2BHmDV1G%2BePOVba6uIKkZcSPqE71P39jd54o4nfDzbaYoljFXB7QSP%2FWlhJIW504b7nT5YiojI%2BNycPAH280gFgzBeTRn9xhtH3xy7TtBDXyJoY26mEeQ%2BUC6hkT5vwSleyn0kDKFKWwkAtJH8JzB%2BR%2F22Yw%3D%3D";
  }

  void postMoment() async {
    try {
      setState(() {
        isUploading = true;
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      // Assuming _selectedImages has only one image
      if (_selectedImages.isNotEmpty && _selectedImages[0] != null) {
        String uploadpath = "${AppUrls.production}/api/uploads";
        SharedPreferences pref = await SharedPreferences.getInstance();
        String? firstName = await pref.getString("FirstName");
        String? LastName = await pref.getString("LastName");
        String? id = await pref.getString("id");
        var response = http.MultipartRequest(
            'POST', Uri.parse("${AppUrls.production}/api/moments"));
    
        // var response = await http
        //     .post(Uri.parse("${AppUrls.production}/api/moments"), body: {
        //   "TagLine": momentController.text,
        //   "image": imageUrl,
        //   "firstName": firstName,
        //   "lastName": LastName,
        //   "owenId": LastName
        // });

        List<List<int>> imageBytesList =
            await Future.wait(_selectedImages.map((image) async {
          if (image != null) {
            return await image.readAsBytes();
          } else {
            // Handle the case when the file is null (optional)
            return <int>[];
          }
        }));
        response.headers['Authorization'] = 'Bearer $token'; 
        response.fields['TagLine'] = momentController.text;
        response.fields['firstName'] = firstName ?? "";
        response.fields['LastName'] = LastName ?? "";
        response.fields['owenId'] = id ?? "0";
        for (int i = 0; i < imageBytesList.length; i++) {
          response.files.add(
            http.MultipartFile.fromBytes(
              'userImages',
              imageBytesList[i],
              filename: '$firstName$LastName$i.jpg',
            ),
          );
        }
        var request = await response.send();

        // Check if the request was successful (status code 200-299)
        if (request.statusCode >= 200 && request.statusCode < 300) {
               setState(() {
        isUploading = false;
      });
        Navigator.of(context).pop();
        } else {
          // Handle error
           setState(() {
        isUploading = false;
      });
          print(
              'Failed to submit registration. Status code: ${request.statusCode}');
        }
      }
    } catch (err) {
      setState(() {
        isUploading = false;
      });
    }
    // Close the bottom sheet after posting
    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
        title: "Post New Moment",
        background: AppColors.background,
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedImages.isEmpty)
                    TextButton(
                      onPressed: () async {
                        List<XFile>? images =
                            await ImagePicker().pickMultiImage(
                          imageQuality: 85,
                          maxWidth: 800,
                        );

                        if (images != null) {
                          setState(() {
                            // Clear previous selection
                            _selectedImages.clear();

                            // Add the newly selected images
                            _selectedImages.addAll(
                              images.map((image) => File(image.path)),
                            );
                          });
                        }
                      },
                      child: Container(
                        height: 120,
                        width: 170,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.amber,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text('Moment Images'),
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 15,
                  ),
                  if (_selectedImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            child: Image.file(
                              _selectedImages[0]!,
                              height: 250,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: TextButton(
                              onPressed: () async {
                                setState(() {
                                  _selectedImages.clear();
                                });
                                List<XFile>? images =
                                    await ImagePicker().pickMultiImage(
                                  imageQuality: 85,
                                  maxWidth: 800,
                                );

                                if (images != null) {
                                  setState(() {
                                    // Clear previous selection
                                    _selectedImages.clear();

                                    // Add the newly selected images
                                    _selectedImages.addAll(
                                      images.map((image) => File(image.path)),
                                    );
                                  });
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.lighter,
                                  border: Border.all(
                                    color: Colors
                                        .black, //                   <--- border color
                                    width: 0.7,
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                                  child: Text(
                                    "change",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                ],
              ),
              TextField(
                controller: momentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe your moment.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(12),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => {postMoment()},
                child: isUploading
                    ? CircularProgressIndicator()
                    : Text("Post Moment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
