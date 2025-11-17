import 'package:flutter/material.dart';

class AppProfile extends StatefulWidget {
  final String profileimg;
  const AppProfile({super.key, required this.profileimg});
  
  @override
  State<AppProfile> createState() => _AppProfileState(profileimg: '');
}

class _AppProfileState extends State<AppProfile> {
  final String profileimg;

  _AppProfileState({required this.profileimg});

  @override
  Widget build(BuildContext context) {
    return  ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: Image.network(profileimg,
          height: 100,
          width: 100,
          fit: BoxFit.cover, // You can add this line to ensure the image covers the entire space
          ),
        );
  }
}