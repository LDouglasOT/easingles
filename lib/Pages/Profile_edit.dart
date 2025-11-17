import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:easingles/Components/Profile.dart';
import 'package:easingles/Components/Text_input.dart';
import 'package:easingles/Components/Toolbar.dart';
import 'package:easingles/Pages/Profilepage.dart';
import 'package:easingles/assets/app.colors.dart';
import 'package:easingles/assets/urlconfig.dart';
import 'package:easingles/styles/app.text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Profile_edit extends StatefulWidget {
  Profile_edit({super.key});

  @override
  State<Profile_edit> createState() => _Profile_editState();
}

class _Profile_editState extends State<Profile_edit> {
  List<UserData> mainUser= [];
  List<String> selectedFilterChips = [];
  final firstname = TextEditingController();

  final lastname = TextEditingController();

  final email = TextEditingController();

  final whatsappnum = TextEditingController();

  final District = TextEditingController();

  final religion = TextEditingController();

  final referalCode = TextEditingController();

  final instagram = TextEditingController();

  final twitter = TextEditingController();

  final facebook = TextEditingController();

  final about = TextEditingController();

  bool _isLoading = false;

  void initState() {
    super.initState();
    getProfile();
  }

  void getProfile() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? id = pref.getString("id");
    String? token = pref.getString('token');
    var url = Uri.parse("${AppUrls.production}/api/currentuser/${id}");
    var response = await http.get(url,headers: {'Authorization': 'Bearer $token'});

    switch (response.statusCode) {
      case 200:
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        UserData useritem = UserData.fromJson(jsonResponse);
        setState(() {
          mainUser.add(useritem);
          firstname.text =
              useritem.firstName != "Not set" ? useritem.firstName ?? "" : "";
          lastname.text =
              useritem.lastName != "Not set" ? useritem.lastName ?? "" : "";
          email.text = useritem.email != "Not set" ? useritem.email ?? "" : "";
          whatsappnum.text =
              useritem.contact != "Not set" ? useritem.contact ?? "" : "";
          District.text =
              useritem.district != "Not set" ? useritem.district ?? "" : "";
          religion.text =
              useritem.religion != "Not set" ? useritem.religion ?? "" : "";
          referalCode.text = useritem.referralCode != "Not set"
              ? useritem.referralCode ?? ""
              : "";
          instagram.text =
              useritem.instagram != "Not set" ? useritem.instagram ?? "" : "";
          twitter.text =
              useritem.twitter != "Not set" ? useritem.twitter ?? "" : "";
          facebook.text =
              useritem.facebook != "Not set" ? useritem.facebook ?? "" : "";
          about.text = useritem.about != "Not set" ? useritem.about ?? "" : "";
        });
        break;
      case 500:
        print(response.body);
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Toolbar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: 'Edit Profile',
        background: AppColors.background,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Column(
                          children: [
                            if(mainUser.length > 0)
                            Image.network(
                              mainUser[0].profilePic ?? "https://via.placeholder.com/150",
                              height: 150,
                              width: 150,
                              fit: BoxFit
                                  .cover, // You can add this line to ensure the image covers the entire space
                            )
                            else
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text_input(
                    label: "FirstName",
                    controller: firstname,
                  ),
                  const SizedBox(height: 20),
                  Text_input(label: "LastName", controller: lastname),
                  const SizedBox(height: 20),
                  Text_input(label: "Email address", controller: email),
                  const SizedBox(height: 20),
                  Text_input(label: "Whatsapp Number", controller: whatsappnum),
                  const SizedBox(height: 20),
                  Text_input(label: "district", controller: District),
                  const SizedBox(height: 20),
                  Text_input(label: "religion", controller: religion),
                  const SizedBox(height: 20),
                  Text_input(label: "district", controller: instagram),
                  const SizedBox(height: 20),
                  TextField(
                    controller: about,
                    minLines: 2,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: "About me",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text_input(label: "facebook handle", controller: facebook),
                  const SizedBox(height: 20),
                  Text_input(label: "twitter handle", controller: twitter),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Interest ${selectedFilterChips.length.toString()}",
                      style: AppText.header2,
                    )
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      FilterChip(
                        label: Text('Outdoor activities'),
                        selected: selectedFilterChips.contains('Outdoor activities'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Outdoor activities');
                            } else {
                              selectedFilterChips.remove('Outdoor activities');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Sports'),
                        selected: selectedFilterChips.contains('Sports'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Sports');
                            } else {
                              selectedFilterChips.remove('Sports');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Music'),
                        selected: selectedFilterChips.contains('Music'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Music');
                            } else {
                              selectedFilterChips.remove('Music');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Art and Creativity'),
                        selected: selectedFilterChips.contains('Art and Creativity'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Art and Creativity');
                            } else {
                              selectedFilterChips.remove('Art and Creativity');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Food'),
                        selected: selectedFilterChips.contains('Food'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Food');
                            } else {
                              selectedFilterChips.remove('Food');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Travel'),
                        selected: selectedFilterChips.contains('Travel'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Travel');
                            } else {
                              selectedFilterChips.remove('Travel');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Gaming'),
                        selected: selectedFilterChips.contains('Gaming'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Gaming');
                            } else {
                              selectedFilterChips.remove('Gaming');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Books'),
                        selected: selectedFilterChips.contains('Books'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Books');
                            } else {
                              selectedFilterChips.remove('Books');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Fitness'),
                        selected: selectedFilterChips.contains('Fitness'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Fitness');
                            } else {
                              selectedFilterChips.remove('Fitness');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Wellness'),
                        selected: selectedFilterChips.contains('Wellness'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Wellness');
                            } else {
                              selectedFilterChips.remove('Wellness');
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: Text('Social Causes'),
                        selected: selectedFilterChips.contains('Social Causes'),
                        onSelected: (bool value) {
                          setState(() {
                            if (value) {
                              selectedFilterChips.add('Social Causes');
                            } else {
                              selectedFilterChips.remove('Social Causes');
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text_input(label: "Referral Code", controller: referalCode),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      onPressed: _isLoading ? null : () async {
                        setState(() {
                          _isLoading = true;
                        });
                        var body = {
                          "firstname": firstname.text,
                          "lastname": lastname.text,
                          "email": email.text,
                          "whatsappnum": whatsappnum.text,
                          "District": District.text,
                          "religion": religion.text,
                          "referalCode": referalCode.text,
                          "instagram": instagram.text,
                          "twitter": twitter.text,
                          "facebook": facebook.text,
                          "about": about.text,
                        };
                        SharedPreferences pref =
                            await SharedPreferences.getInstance();
                        String? id = pref.getString("id");
                        String? token = pref.getString('token');
                        var url = Uri.parse(
                            "${AppUrls.production}/api/updateuser/$id");
                        var response = await http.post(url,headers: {'Authorization': 'Bearer $token'}, body: body);
                        setState(() {
                          _isLoading = false;
                        });
                        switch (response.statusCode) {
                          case 200:
                            Future.delayed(const Duration(seconds: 1), () {
                              Navigator.of(context).pop();
                            });
                            break;
                          default:
                            const snackBar = SnackBar(
                              content: Text('Something went wrong, please try again.'),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      },
                      child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
