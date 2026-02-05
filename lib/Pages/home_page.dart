import 'package:flutter/material.dart';
import 'package:mazale/assets/app.colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Flutter learn",
          style: TextStyle(
            color: AppColors.fontColor,
          ),
        ),
        backgroundColor: AppColors.background,
        centerTitle: false,
        actions: [
          Icon(
            Icons.location_on_outlined,
            color: Colors.white,
          ),
        ],
      ),
      body: Center(
        child: Text("Hello this is the homepage"),
      ),
    );
  }
}
