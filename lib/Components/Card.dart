import 'package:flutter/material.dart';

class Card extends StatelessWidget {
  const Card({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: Stack(
          children: [
            Image.asset(
              'lib/assets/images/user.jpeg',
              fit: BoxFit.cover,
            ),
            const Positioned(
              bottom: 4,
              left: 4,
              child: Column(
                children: [Text("Luzinda Douglas")],
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: ElevatedButton(
                onPressed: () {},
                child: Icon(Icons.message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
