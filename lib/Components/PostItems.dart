import 'package:flutter/material.dart';
import 'package:easingles/styles/app.text.dart';// Assuming you have a file named app_text.dart for AppText

class PostItem extends StatelessWidget {
  final dynamic user;

  const PostItem({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Image.network(user['imageOne'], width: 50, height: 40),
              SizedBox(width: 10),
              Row(
                children: [
                  // Text(user['FirstName'], style: AppText.subtitle3),
                  const SizedBox(width: 5),
                  // Text(user['LastName'], style: AppText.subtitle3),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            child: Image.network(user['postImageURL']), // Changed from Image.asset
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          const SizedBox(height: 12),
          const Text(
            "Lorem Duis dolore cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.🌟 🚀",
            style: AppText.subtitle3,
          )
        ],
      ),
    );
  }
}
