import 'package:flutter/material.dart';


class Text_input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  Text_input({super.key, required this.label,required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:controller,
      decoration: InputDecoration(
        hintText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
        ),
        filled: true,
        fillColor: const Color.fromARGB(255, 78, 78, 78).withOpacity(0.5),
      ),
    );;
  }
}